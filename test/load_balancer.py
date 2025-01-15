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

# ------------------------------------------------------------------------------
# LOGGING SETUP
# ------------------------------------------------------------------------------
LOG_FILE = "logs/load_balancer.log"
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

# ------------------------------------------------------------------------------
# BACKEND CONFIGURATION
# ------------------------------------------------------------------------------
def generate_backends(start_port, end_port):
    """Generate a list of backend URLs skipping common service ports."""
    excluded_ports = {
        20, 21, 22, 23, 25, 53, 67, 68, 69, 80, 110, 123, 137, 138, 139, 143,
        161, 162, 179, 194, 389, 443, 445, 465, 514, 636, 989, 990, 993, 995,
        2049, 3306, 3389, 5040, 5432, 8080, 8443
    }
    ports = range(start_port, end_port + 1)
    return [f"http://127.0.0.1:{p}" for p in ports if p not in excluded_ports]

BACKENDS = generate_backends(5501, 5508)
TOTAL_BACKENDS = len(BACKENDS)

# Round-robin index
current_backend_index = 0

# Health Tracking
HEALTHY_BACKENDS = []
EXCLUDED_BACKENDS = {}  # {backend_url: next_retry_timestamp}
RETRY_INTERVAL = 30
HEALTH_CHECK_INTERVAL = 10

# Track consecutive failures and successes
consecutive_failures = {}
consecutive_successes = {}
MAX_CONSECUTIVE_FAILURES = 3  # Mark backend unhealthy after this many fails
MIN_CONSECUTIVE_SUCCESSES = 2  # Mark backend healthy after this many successes

# ------------------------------------------------------------------------------
# REQUEST QUEUE & WORKER THREADS
# ------------------------------------------------------------------------------
REQUEST_QUEUE = queue.Queue(maxsize=1000)  # Adjust as needed
NUM_WORKERS = 10
REQUEST_TIMEOUT = 60  # seconds to wait for worker completion

# We store responses keyed by request ID
RESPONSES = {}
RESPONSES_LOCK = threading.Lock()

# A Condition to notify main thread when a worker has finished a response
RESPONSE_READY_CONDITION = threading.Condition(lock=RESPONSES_LOCK)

# ------------------------------------------------------------------------------
# SHUTDOWN FLAG
# ------------------------------------------------------------------------------
shutdown_flag = threading.Event()

def signal_handler(signum, frame):
    """Handle SIGINT/SIGTERM for graceful shutdown."""
    logger.info(f"Received signal {signum}, shutting down gracefully...")
    shutdown_flag.set()

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

# ------------------------------------------------------------------------------
# HEALTH CHECKS
# ------------------------------------------------------------------------------
def check_backend(backend):
    """
    Perform a single health check of the backend.
    Returns (backend, is_healthy).
    """
    # If excluded, skip unless we have passed the retry time
    current_time = time.time()
    if backend in EXCLUDED_BACKENDS and current_time < EXCLUDED_BACKENDS[backend]:
        logger.debug(f"[HealthCheck] Skipping {backend} until retry time.")
        return (backend, False)

    # Attempt to connect
    try:
        resp = requests.get(f"{backend}/healthcheck", timeout=5)
        if resp.status_code == 200:
            return (backend, True)
        else:
            logger.debug(f"[HealthCheck] {backend} returned {resp.status_code}")
            return (backend, False)
    except requests.RequestException as e:
        logger.debug(f"[HealthCheck] Exception for {backend}: {e}")
        return (backend, False)

def update_health_status(backend, is_healthy):
    """Update consecutive failures/successes, set healthy/unhealthy as needed."""
    global HEALTHY_BACKENDS

    if is_healthy:
        # Reset failures, increment successes
        consecutive_failures[backend] = 0
        consecutive_successes[backend] = consecutive_successes.get(backend, 0) + 1

        # Mark healthy if we pass the threshold
        if consecutive_successes[backend] >= MIN_CONSECUTIVE_SUCCESSES:
            if backend not in HEALTHY_BACKENDS:
                HEALTHY_BACKENDS.append(backend)
            if backend in EXCLUDED_BACKENDS:
                del EXCLUDED_BACKENDS[backend]
    else:
        # Reset successes, increment failures
        consecutive_successes[backend] = 0
        consecutive_failures[backend] = consecutive_failures.get(backend, 0) + 1

        if consecutive_failures[backend] >= MAX_CONSECUTIVE_FAILURES:
            # Mark as unhealthy
            if backend in HEALTHY_BACKENDS:
                HEALTHY_BACKENDS.remove(backend)
            EXCLUDED_BACKENDS[backend] = time.time() + RETRY_INTERVAL

def health_check():
    """Periodically check the health of all backends in parallel."""
    global HEALTHY_BACKENDS
    # Initialize everything as potentially healthy
    HEALTHY_BACKENDS = list(BACKENDS)

    with ThreadPoolExecutor(max_workers=10) as executor:
        while not shutdown_flag.is_set():
            futures = [executor.submit(check_backend, b) for b in BACKENDS]
            for f in as_completed(futures):
                if shutdown_flag.is_set():
                    return
                backend, is_healthy = f.result()
                update_health_status(backend, is_healthy)

            logger.info(f"[HealthCheck] {len(HEALTHY_BACKENDS)}/{TOTAL_BACKENDS} are healthy.")
            time.sleep(HEALTH_CHECK_INTERVAL)

# ------------------------------------------------------------------------------
# ROUND ROBIN FUNCTION
# ------------------------------------------------------------------------------
def get_next_backend():
    """Return the next healthy backend in a round-robin manner."""
    global current_backend_index
    if not HEALTHY_BACKENDS:
        return None

    backend = HEALTHY_BACKENDS[current_backend_index]
    current_backend_index = (current_backend_index + 1) % len(HEALTHY_BACKENDS)
    return backend

# ------------------------------------------------------------------------------
# STORE RESPONSES
# ------------------------------------------------------------------------------
def store_response(request_id, status_code, content, headers=None):
    """Store a response for retrieval by the main thread."""
    with RESPONSE_READY_CONDITION:
        RESPONSES[request_id] = {
            "status": status_code,
            "content": content,
            "headers": dict(headers) if headers else {}
        }
        RESPONSE_READY_CONDITION.notify_all()

# ------------------------------------------------------------------------------
# WORKER FUNCTION
# ------------------------------------------------------------------------------
def worker_thread():
    """
    Continuously pull requests from the queue and forward them to a backend.
    Each worker uses its own requests.Session to reuse HTTP connections.
    """
    session = requests.Session()  # Shared within this worker only

    while not shutdown_flag.is_set():
        try:
            request_id, method, path, headers, body = REQUEST_QUEUE.get(timeout=1)
        except queue.Empty:
            # No request in queue, check if we are shutting down
            continue

        backend_url = get_next_backend()
        if not backend_url:
            # No healthy backends
            store_response(request_id, 503, b"No healthy backends available")
            REQUEST_QUEUE.task_done()
            continue

        target_url = backend_url + path
        try:
            if method == "GET":
                resp = session.get(target_url, headers=headers, timeout=10)
            elif method == "POST":
                resp = session.post(target_url, headers=headers, data=body, timeout=10)
            else:
                # Extend to PUT, PATCH, DELETE as needed
                store_response(request_id, 405, b"Method Not Allowed")
                REQUEST_QUEUE.task_done()
                continue

            store_response(request_id, resp.status_code, resp.content, resp.headers)
        except requests.RequestException as e:
            logger.warning(f"[Worker] Request to {backend_url} failed: {e}")

            # Check if the error text contains 'WinError 10048'
            # This is just a string search – you could also look for the exact exception type.
            if "WinError 10048" in str(e):
                store_response(
                    request_id, 
                    503, 
                    b"Service Unavailable: Port or address in use (WinError 10048)."
                )
            else:
                store_response(
                    request_id, 
                    503, 
                    b"Service Unavailable: Could not reach backend."
                )


        REQUEST_QUEUE.task_done()

# ------------------------------------------------------------------------------
# MAIN REQUEST HANDLER
# ------------------------------------------------------------------------------
class LoadBalancerHandler(BaseHTTPRequestHandler):
    def forward_to_queue(self, method):
        """
        Put the request in the queue, then wait on a condition for the response.
        """
        # Quick check if no backends are healthy
        if not HEALTHY_BACKENDS:
            self.send_response(503)
            self.end_headers()
            self.wfile.write(b"No healthy backends available")
            return

        # Prepare request data
        request_id = threading.get_ident()  # unique ID for this request
        path = self.path
        headers = dict(self.headers)

        if method == "POST":
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length)
        else:
            body = None

        # Try to enqueue
        try:
            REQUEST_QUEUE.put_nowait((request_id, method, path, headers, body))
        except queue.Full:
            logger.warning("[MainThread] Request queue is full. Rejecting request.")
            self.send_response(503)
            self.end_headers()
            self.wfile.write(b"Queue is full. Try again later.")
            return

        # Wait for a response from the worker
        response_data = None
        start_time = time.time()

        with RESPONSE_READY_CONDITION:
            while True:
                # Check if the worker has produced a response
                if request_id in RESPONSES:
                    response_data = RESPONSES.pop(request_id)
                    break

                # Timeout check
                if time.time() - start_time > REQUEST_TIMEOUT:
                    logger.warning("[MainThread] Timed out waiting for worker response.")
                    self.send_response(504)
                    self.end_headers()
                    self.wfile.write(b"Gateway Timeout")
                    return

                # Wait to be notified when a worker calls store_response
                RESPONSE_READY_CONDITION.wait(timeout=1)
                if shutdown_flag.is_set():
                    # If shutting down, break early
                    return

        # Send the worker’s response
        status = response_data["status"]
        content = response_data["content"]
        resp_headers = response_data["headers"]

        self.send_response(status)
        # Forward permissible headers
        for h, v in resp_headers.items():
            # Omit hop-by-hop headers like Transfer-Encoding, Content-Length, etc.
            if h.lower() not in ["transfer-encoding", "content-length", "content-encoding"]:
                self.send_header(h, v)
        self.end_headers()
        self.wfile.write(content)

    def do_GET(self):
        self.forward_to_queue("GET")

    def do_POST(self):
        self.forward_to_queue("POST")

class ThreadedTCPServer(ThreadingMixIn, TCPServer):
    allow_reuse_address = True

# ------------------------------------------------------------------------------
# MAIN ENTRY POINT
# ------------------------------------------------------------------------------
def main():
    # Start Health Check Thread
    hc_thread = threading.Thread(target=health_check, daemon=True)
    hc_thread.start()

    # Start Worker Threads
    workers = []
    for _ in range(NUM_WORKERS):
        t = threading.Thread(target=worker_thread, daemon=True)
        t.start()
        workers.append(t)

    # Start the Multi-threaded TCP server
    PORT = 8080
    with ThreadedTCPServer(("", PORT), LoadBalancerHandler) as httpd:
        logger.info(f"Load balancer running on port {PORT}")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass
        finally:
            logger.info("Shutting down server...")

    shutdown_flag.set()
    # Wait for health check thread to finish
    hc_thread.join()

    # Wait for workers to finish
    for w in workers:
        w.join(timeout=2)

    logger.info("Load balancer has stopped gracefully.")

if __name__ == "__main__":
    main()
