# errors.py
from flask import Blueprint, render_template, jsonify
from flask_cors import CORS
from util.logit import get_logger
from util.error_handling import log_error

errors_bp = Blueprint("errors", __name__)
CORS(errors_bp, resources={r"/*": {
        "origins": [
            "https://api-sync-branch.yggbranch.dev",
            "http://python-hello-world-911611650068.europe-west3.run.app"
        ]
    }})
logger = get_logger("logs", "AppErrors")

error_counts = {400: 0, 401: 0, 403: 0, 404: 0, 405: 0, 408: 0, 429: 0, 500: 0}


def increment_error_count(status_code):
    if status_code in error_counts:
        error_counts[status_code] += 1


@errors_bp.errorhandler(400)
def bad_request(e):
    increment_error_count(400)
    log_error(e)
    logger.error(f"400 Bad Request: {e}")
    return (
        render_template(
            "error.html",
            error_message="Bad request. Please check your input.",
            error_code=400,
        ),
        400,
    )


@errors_bp.errorhandler(401)
def unauthorized(e):
    increment_error_count(401)
    log_error(e)
    logger.error(f"401 Unauthorized: {e}")
    return (
        render_template(
            "error.html", error_message="Unauthorized access.", error_code=401
        ),
        401,
    )


@errors_bp.errorhandler(403)
def forbidden(e):
    increment_error_count(403)
    log_error(e)
    logger.error(f"403 Forbidden: {e}")
    return (
        render_template(
            "error.html",
            error_message="Forbidden.",
            error_code=403),
        403,
    )


@errors_bp.errorhandler(404)
def page_not_found(e):
    increment_error_count(404)
    log_error(e)
    logger.error(f"404 Not Found: {e}")
    return (
        render_template(
            "error.html",
            error_message="The endpoint you are looking for does not exist.",
            error_code=404,
        ),
        404,
    )


@errors_bp.errorhandler(405)
def method_not_allowed(e):
    increment_error_count(405)
    log_error(e)
    logger.error(f"405 Method Not Allowed: {e}")
    return (
        render_template(
            "error.html",
            error_message="Method not allowed for this endpoint.",
            error_code=405,
        ),
        405,
    )


@errors_bp.errorhandler(408)
def request_timeout(e):
    increment_error_count(408)
    log_error(e)
    logger.error(f"408 Request Timeout: {e}")
    return (
        render_template(
            "error.html",
            error_message="Request timed out. Please try again.",
            error_code=408,
        ),
        408,
    )


@errors_bp.errorhandler(429)
def too_many_requests(e):
    increment_error_count(429)
    log_error(e)
    logger.error(f"429 Too Many Requests: {e}")
    return (
        render_template(
            "error.html",
            error_message="You have sent too many requests in a given time.",
            error_code=429,
        ),
        429,
    )


@errors_bp.errorhandler(500)
def internal_server_error(e):
    increment_error_count(500)
    log_error(e)
    logger.error(f"500 Internal Server Error: {e}")
    return (
        render_template(
            "error.html",
            error_message="An internal server error occurred. Please try again later.",
            error_code=500,
        ),
        500,
    )


@errors_bp.route("/error_stats")
def show_error_stats():
    return jsonify(error_counts)


def init_app(app):
    # Register the blueprint for error routes
    app.register_blueprint(errors_bp, url_prefix="/")
    # Register global error handlers so they catch errors outside the
    # blueprint as well
    app.register_error_handler(400, bad_request)
    app.register_error_handler(401, unauthorized)
    app.register_error_handler(403, forbidden)
    app.register_error_handler(404, page_not_found)
    app.register_error_handler(405, method_not_allowed)
    app.register_error_handler(408, request_timeout)
    app.register_error_handler(429, too_many_requests)
    app.register_error_handler(500, internal_server_error)
