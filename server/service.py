from flask import Flask, jsonify, render_template, request
from flask_jwt_extended import JWTManager
from flask_limiter import Limiter
from flask_swagger_ui import get_swaggerui_blueprint
from cmd_gui_kit import CmdGUI
from flask_cors import CORS
from error_handling import log_error
import logging
from auth import auth_bp
from apps import apps_bp
from SpotifyMicroService.spotify import spotify_bp as SpotifyMicroService_bp
from spotify import spotify_bp
from dotenv import load_dotenv
import argparse
import os


gui = CmdGUI()

load_dotenv()
app = Flask(__name__)

app.config['JWT_SECRET_KEY'] = os.getenv("JWT_SECRET_KEY")
app.config['SWAGGER_URL'] = '/api/docs'
app.config['API_URL'] = '/static/swagger.json'

jwt = JWTManager(app)
limiter = Limiter(app)

CORS(app, resources={r"/*": {"origins": "*"}})

# Setup logging
LOG_FILE = "logs/service.log"

# Create a logger
logger = logging.getLogger("Service")
logger.setLevel(logging.DEBUG)

# Create file handler
file_handler = logging.FileHandler(LOG_FILE, encoding="utf-8")
file_handler.setLevel(logging.DEBUG)

# Create console handler
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.INFO)

# Create formatter and add it to the handlers
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
file_handler.setFormatter(formatter)

# Add handlers to the logger
logger.addHandler(file_handler)
logger.addHandler(console_handler)

logger.propagate = False

# Middleware to log all requests
def log_request():
    logger.info(f"Request received: {request.method} {request.url}")
app.before_request(log_request)

# Swagger documentation setup
swaggerui_blueprint = get_swaggerui_blueprint(
    app.config['SWAGGER_URL'],
    app.config['API_URL'],
    config={'app_name': "Micro Service"}
)

# Add /healthcheck to each blueprint
@auth_bp.before_request
def log_spotify_requests():
    logger.info("Spotify blueprint request received.")
    
# Add /healthcheck to each blueprint
@auth_bp.route("/healthcheck", methods=["GET"])
def auth_healthcheck():
    gui.log("Auth Service healthcheck requested")
    logger.info("Auth Service healthcheck requested")
    return jsonify({"status": "ok", "service": "Auth Service"}), 200

# Add /healthcheck to each blueprint
@apps_bp.before_request
def log_apps_requests():
    logger.info("Apps blueprint request received.")
    
# Add /healthcheck to each blueprint
@apps_bp.route("/healthcheck", methods=["GET"])
def apps_healthcheck():
    gui.log("Apps Service healthcheck requested")
    logger.info("Apps Service healthcheck requested")
    return jsonify({"status": "ok", "service": "Apps Service"}), 200

# Add /healthcheck to each blueprint
@SpotifyMicroService_bp.before_request
def log_spotify_micro_service_requests():  # noqa: F811
    logger.info("Spotify Micro Service blueprint request received.")
    
# Add /healthcheck to each blueprint
@SpotifyMicroService_bp.route("/healthcheck", methods=["GET"])
def spotify_micro_service_healthcheck():
    gui.log("Spotify Micro Service healthcheck requested")
    logger.info("Spotify Micro Service healthcheck requested")
    return jsonify({"status": "ok", "service": "Spotify Micro Service"}), 200

# Add /healthcheck to each blueprint
@spotify_bp.before_request
def log_spotify_requests():  # noqa: F811
    logger.info("Spotify blueprint request received.")
    
# Add /healthcheck to each blueprint
@spotify_bp.route("/healthcheck", methods=["GET"])
def spotify_healthcheck():
    gui.log("Spotify Service healthcheck requested")
    logger.info("Spotify Service healthcheck requested")
    return jsonify({"status": "ok", "service": "Spotify Service"}), 200

@app.route("/healthcheck", methods=['POST', 'GET'])
def app_healthcheck():
    #gui.log("App healthcheck requested")
    logger.info("App healthcheck requested")
    return jsonify({"status": "ok", "service": "App Service"}), 200


app.register_blueprint(auth_bp, url_prefix="/auth")
app.register_blueprint(apps_bp, url_prefix="/apps")
app.register_blueprint(spotify_bp, url_prefix="/spotify")
app.register_blueprint(SpotifyMicroService_bp, url_prefix="/spotify-micro-service")
app.register_blueprint(swaggerui_blueprint, url_prefix=app.config['SWAGGER_URL'])

# Dictionary to track how many times each error occurs
error_counts = {
    400: 0,
    401: 0,
    403: 0,
    404: 0,
    405: 0,
    408: 0,
    429: 0,
    500: 0
}

def increment_error_count(status_code):
    if status_code in error_counts:
        error_counts[status_code] += 1

# --------------------------------
# 400 Bad Request
# --------------------------------
@app.errorhandler(400)
def bad_request(e):
    increment_error_count(400)
    log_error(e)
    logger.error(f"400 Bad Request: {e}")
    return render_template(
        "error.html",
        error_message="Bad request. Please check your input.", error_code=400
    ), 400

# --------------------------------
# 401 Unauthorized
# --------------------------------
@app.errorhandler(401)
def unauthorized(e):
    increment_error_count(401)
    log_error(e)
    logger.error(f"401 Unauthorized: {e}")
    return render_template(
        "error.html",
        error_message="Unauthorized access.", error_code=401
    ), 401

# --------------------------------
# 403 Forbidden
# --------------------------------
@app.errorhandler(403)
def forbidden(e):
    increment_error_count(403)
    log_error(e)
    logger.error(f"403 Forbidden: {e}")
    return render_template(
        "error.html",
        error_message="Forbidden.", error_code=403
    ), 403

# --------------------------------
# 404 Not Found
# --------------------------------
@app.errorhandler(404)
def page_not_found(e):
    increment_error_count(404)
    log_error(e)
    logger.error(f"404 Not Found: {e}")
    return render_template(
        "error.html",
        error_message="The endpoint you are looking for does not exist.", error_code=404
    ), 404

# --------------------------------
# 405 Method Not Allowed
# --------------------------------
@app.errorhandler(405)
def method_not_allowed(e):
    increment_error_count(405)
    log_error(e)
    logger.error(f"405 Method Not Allowed: {e}")
    return render_template(
        "error.html",
        error_message="Method not allowed for this endpoint.", error_code=405
    ), 405

# --------------------------------
# 408 Request Timeout
# --------------------------------
@app.errorhandler(408)
def request_timeout(e):
    increment_error_count(408)
    log_error(e)
    logger.error(f"408 Request Timeout: {e}")
    return render_template(
        "error.html",
        error_message="Request timed out. Please try again.", error_code=408
    ), 408

# --------------------------------
# 429 Too Many Requests
# --------------------------------
@app.errorhandler(429)
def too_many_requests(e):
    increment_error_count(429)
    log_error(e)
    logger.error(f"429 Too Many Requests: {e}")
    return render_template(
        "error.html",
        error_message="You have sent too many requests in a given time.", error_code=429
    ), 429

# --------------------------------
# 500 Internal Server Error
# --------------------------------
@app.errorhandler(500)
def internal_server_error(e):
    increment_error_count(500)
    log_error(e)
    logger.error(f"500 Internal Server Error: {e}")
    return render_template(
        "error.html",
        error_message="An internal server error occurred. Please try again later.", error_code=500
    ), 500

# Example route to display current error counts (optional)
@app.route("/error_stats")
def show_error_stats():
    # You can return this data as JSON or render it in a template
    return jsonify(error_counts)

@jwt.unauthorized_loader
def unauthorized_loader(callback):
    return jsonify({"error": "Token missing or invalid", "message": callback}), 401

@jwt.expired_token_loader
def expired_token_callback(jwt_header, jwt_payload):
    return jsonify({"error": "Token expired"}), 401

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run Flask on a specific port.")
    parser.add_argument("--port", type=int, default=8080, help="Port to run the Flask app.")
    args = parser.parse_args()

    app.run(host="0.0.0.0", port=args.port)
