#!/usr/bin/env python3
import sys
import signal
import queue
import threading
import time
import logging
import requests
from http.server import BaseHTTPRequestHandler
from socketserver import ThreadingMixIn, TCPServer
from concurrent.futures import ThreadPoolExecutor, as_completed

# -------------------------------------------------------------------------------
# CONFIGURATION CONSTANTS
# -------------------------------------------------------------------------------
LOG_FILE = "logs/load_balancer.log"
NUM_WORKERS = 10
REQUEST_TIMEOUT = 60  # seconds to wait for worker response
RETRY_INTERVAL = 30   # seconds until a backend is retried after failure
HEALTH_CHECK_INTERVAL = 10  # seconds between health check cycles
MAX_CONSECUTIVE_FAILURES = 3  # mark backend unhealthy after these many failures
MIN_CONSECUTIVE_SUCCESSES = 2  # mark backend healthy after these many successes

# -------------------------------------------------------------------------------
# LOGGING SETUP
# -------------------------------------------------------------------------------
logger = logging.getLogger("ImprovedLoadBalancer")
logger.setLevel(logging.DEBUG)

file_handler = logging.FileHandler(LOG_FILE, encoding="utf-8")
file_handler.setLevel(logging.DEBUG)
console_handler = logging.StreamHandler(sys.stdout)
console_handler.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
file_handler.setFormatter(formatter)
console_handler.setFormatter(formatter)
logger.addHandler(file_handler)
logger.addHandler(console_handler)
logger.propagate = False

# -------------------------------------------------------------------------------
# BACKEND CONFIGURATION
# -------------------------------------------------------------------------------
def generate_backends(start_port, end_port):
    """Generate a list of backend URLs skipping common service ports."""
    excluded_ports = {
        20, 21, 22, 23, 25, 53, 67, 68, 69, 80, 110, 123, 137, 138, 139, 143,
        161, 162, 179, 194, 389, 443, 445, 465, 514, 636, 989, 990, 993, 995,
        2049, 3306, 3389, 5040, 5432, 8080, 8443
    }
    return [f"http://127.0.0.1:{p}" for p in range(start_port, end_port + 1) if p not in excluded_ports]

BACKENDS = generate_backends(5501, 5508)
TOTAL_BACKENDS = len(BACKENDS)

# -------------------------------------------------------------------------------
# SHUTDOWN FLAG
# -------------------------------------------------------------------------------
shutdown_flag = threading.Event()
def signal_handler(signum, frame):
    logger.info(f"Received signal {signum}, shutting down gracefully...")
    shutdown_flag.set()

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

# -------------------------------------------------------------------------------
# BACKEND MANAGER (THREAD-SAFE)
# -------------------------------------------------------------------------------
class BackendManager:
    def __init__(self, backends):
        self.backends = backends
        self.healthy_backends = list(backends)  # start by assuming all are healthy
        self.excluded_backends = {}  # {backend_url: next_retry_timestamp}
        self.current_index = 0
        self.consecutive_failures = {b: 0 for b in backends}
        self.consecutive_successes = {b: 0 for b in backends}
        self.lock = threading.Lock()

    def update_health_status(self, backend, is_healthy):
        with self.lock:
            if is_healthy:
                self.consecutive_failures[backend] = 0
                self.consecutive_successes[backend] = self.consecutive_successes.get(backend, 0) + 1
                if self.consecutive_successes[backend] >= MIN_CONSECUTIVE_SUCCESSES:
                    if backend not in self.healthy_backends:
                        self.healthy_backends.append(backend)
                    if backend in self.excluded_backends:
                        del self.excluded_backends[backend]
            else:
                self.consecutive_successes[backend] = 0
                self.consecutive_failures[backend] = self.consecutive_failures.get(backend, 0) + 1
                if self.consecutive_failures[backend] >= MAX_CONSECUTIVE_FAILURES:
                    if backend in self.healthy_backends:
                        self.healthy_backends.remove(backend)
                    self.excluded_backends[backend] = time.time() + RETRY_INTERVAL

    def get_next_backend(self):
        with self.lock:
            if not self.healthy_backends:
                return None
            backend = self.healthy_backends[self.current_index % len(self.healthy_backends)]
            self.current_index = (self.current_index + 1) % len(self.healthy_backends)
            return backend

    def check_backend(self, backend):
        current_time = time.time()
        with self.lock:
            if backend in self.excluded_backends and current_time < self.excluded_backends[backend]:
                logger.debug(f"[HealthCheck] Skipping {backend} until retry time.")
                return backend, False
        try:
            resp = requests.get(f"{backend}/healthcheck", timeout=5)
            healthy = (resp.status_code == 200)
            return backend, healthy
        except requests.RequestException as e:
            logger.debug(f"[HealthCheck] Exception for {backend}: {e}")
            return backend, False

    def perform_health_checks(self):
        with ThreadPoolExecutor(max_workers=10) as executor:
            futures = [executor.submit(self.check_backend, b) for b in self.backends]
            for future in as_completed(futures):
                backend, is_healthy = future.result()
                self.update_health_status(backend, is_healthy)
        with self.lock:
            logger.info(f"[HealthCheck] {len(self.healthy_backends)}/{TOTAL_BACKENDS} healthy.")

# Create a global instance
backend_manager = BackendManager(BACKENDS)

def health_check_thread():
    """Continuously perform health checks at fixed intervals."""
    while not shutdown_flag.is_set():
        backend_manager.perform_health_checks()
        time.sleep(HEALTH_CHECK_INTERVAL)

# -------------------------------------------------------------------------------
# REQUEST MANAGER (FOR QUEUE AND RESPONSE MATCHING)
# -------------------------------------------------------------------------------
class RequestManager:
    def __init__(self, maxsize=1000):
        self.request_queue = queue.Queue(maxsize=maxsize)
        self.responses = {}  # Maps request_id to response data
        self.condition = threading.Condition()

    def store_response(self, request_id, status, content, headers):
        with self.condition:
            self.responses[request_id] = {
                "status": status,
                "content": content,
                "headers": headers
            }
            self.condition.notify_all()

    def get_response(self, request_id, timeout):
        start_time = time.time()
        with self.condition:
            while request_id not in self.responses:
                remaining = timeout - (time.time() - start_time)
                if remaining <= 0:
                    return None
                self.condition.wait(timeout=remaining)
            return self.responses.pop(request_id)

# Create a global instance
request_manager = RequestManager()

# -------------------------------------------------------------------------------
# WORKER THREAD FUNCTION
# -------------------------------------------------------------------------------
def worker_thread():
    """Continuously process requests from the queue and forward them to backends."""
    session = requests.Session()  # Reuse HTTP connections per worker
    while not shutdown_flag.is_set():
        try:
            request_id, method, path, headers, body = request_manager.request_queue.get(timeout=1)
        except queue.Empty:
            continue  # Loop again if no request is available

        backend_url = backend_manager.get_next_backend()
        if not backend_url:
            request_manager.store_response(
                request_id, 503, b"No healthy backends available", {}
            )
            request_manager.request_queue.task_done()
            continue

        target_url = backend_url + path
        try:
            if method == "GET":
                resp = session.get(target_url, headers=headers, timeout=10)
            elif method == "POST":
                resp = session.post(target_url, headers=headers, data=body, timeout=10)
            else:
                request_manager.store_response(
                    request_id, 405, b"Method Not Allowed", {}
                )
                request_manager.request_queue.task_done()
                continue

            request_manager.store_response(
                request_id, resp.status_code, resp.content, resp.headers
            )
        except requests.RequestException as e:
            logger.warning(f"[Worker] Request to {backend_url} failed: {e}")
            request_manager.store_response(
                request_id, 503, b"Service Unavailable: Could not reach backend.", {}
            )
        request_manager.request_queue.task_done()

# -------------------------------------------------------------------------------
# HTTP REQUEST HANDLER
# -------------------------------------------------------------------------------
class LoadBalancerHandler(BaseHTTPRequestHandler):
    def forward_to_queue(self, method):
        # Check for healthy backends before enqueuing
        if not backend_manager.healthy_backends:
            self.send_response(503)
            self.end_headers()
            self.wfile.write(b"No healthy backends available")
            return

        # Generate a unique request_id (using thread ident and current time)
        request_id = f"{threading.get_ident()}-{time.time()}"
        path = self.path
        headers = dict(self.headers)
        body = b""
        if method == "POST":
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length)

        # Enqueue the request
        try:
            request_manager.request_queue.put_nowait((request_id, method, path, headers, body))
        except queue.Full:
            logger.warning("[MainThread] Request queue is full. Rejecting request.")
            self.send_response(503)
            self.end_headers()
            self.wfile.write(b"Queue is full. Try again later.")
            return

        # Wait for the worker to process the request
        response_data = request_manager.get_response(request_id, REQUEST_TIMEOUT)
        if response_data is None:
            logger.warning("[MainThread] Timed out waiting for worker response.")
            self.send_response(504)
            self.end_headers()
            self.wfile.write(b"Gateway Timeout")
            return

        # Send the worker’s response
        self.send_response(response_data["status"])
        for h, v in response_data["headers"].items():
            if h.lower() not in ["transfer-encoding", "content-length", "content-encoding"]:
                self.send_header(h, v)
        self.end_headers()
        self.wfile.write(response_data["content"])

    def do_GET(self):
        self.forward_to_queue("GET")

    def do_POST(self):
        self.forward_to_queue("POST")

# -------------------------------------------------------------------------------
# MULTI-THREADED TCP SERVER
# -------------------------------------------------------------------------------
class ThreadedTCPServer(ThreadingMixIn, TCPServer):
    allow_reuse_address = True

# -------------------------------------------------------------------------------
# MAIN FUNCTION
# -------------------------------------------------------------------------------
def main():
    # Start the health check thread
    hc_thread = threading.Thread(target=health_check_thread, daemon=True)
    hc_thread.start()

    # Start worker threads
    workers = []
    for _ in range(NUM_WORKERS):
        t = threading.Thread(target=worker_thread, daemon=True)
        t.start()
        workers.append(t)

    # Start the threaded TCP server for handling HTTP requests
    PORT = 8080
    with ThreadedTCPServer(("", PORT), LoadBalancerHandler) as httpd:
        logger.info(f"Load balancer running on port {PORT}")
        try:
            httpd.serve_forever()
        except Exception as e:
            logger.error(f"Server error: {e}")
        finally:
            logger.info("Shutting down server...")
            shutdown_flag.set()
            httpd.shutdown()

    # Wait for threads to finish (with timeout safeguards)
    hc_thread.join(timeout=5)
    for w in workers:
        w.join(timeout=5)
    logger.info("Load balancer has stopped gracefully.")

if __name__ == "__main__":
    main()
