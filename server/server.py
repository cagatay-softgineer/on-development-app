import util.setup  # noqa: F401
from config.config import settings
from flask import Flask, request
from flask_jwt_extended import JWTManager
from flask_limiter import Limiter
from flask_swagger_ui import get_swaggerui_blueprint
from cmd_gui_kit import CmdGUI
from flask_cors import CORS
from util.logit import get_logger
from Blueprints.auth import auth_bp
from Blueprints.error import (
    errors_bp,
    bad_request,
    unauthorized,
    forbidden,
    page_not_found,
    method_not_allowed,
    request_timeout,
    too_many_requests,
    internal_server_error,
)
from Blueprints.utilx import util_bp
from Blueprints.apps import apps_bp
from Blueprints.spotify import spotify_bp
from Blueprints.apple import apple_bp
from Blueprints.apple_music import appleMusic_bp
from Blueprints.user_profile import profile_bp
from Blueprints.google_api import google_bp
from Blueprints.spotify_micro_service import SpotifyMicroService_bp
from Blueprints.lyrics import lyrics_bp
from Blueprints.youtube_music import youtubeMusic_bp
import argparse


gui = CmdGUI()


def create_app(testing=False):

    app = Flask(__name__)

    jwt = JWTManager(app)  # noqa: F841
    limiter = Limiter(app)  # noqa: F841

    app.config["JWT_SECRET_KEY"] = settings.jwt_secret_key
    app.config["SWAGGER_URL"] = "/api/docs"
    app.config["API_URL"] = "/static/swagger.json"
    app.config["SECRET_KEY"] = settings.SECRET_KEY
    app.config["PREFERRED_URL_SCHEME"] = "https"
    app.config["TESTING"] = testing

    CORS(app, resources={r"/*": {"origins": "*"}})

    # Add logging to the root logger
    logger = get_logger("logs", "Service")

    # Middleware to log all requests

    def log_request():
        """
        Logs the incoming HTTP request.

        This function logs the HTTP method and URL of the incoming request using the Flask's `request` object.
        The log message is formatted as "Request received: <HTTP_METHOD> <REQUEST_URL>".

        Parameters:
        None

        Returns:
        None
        """
        logger.info(f"Request received: {request.method} {request.url}")

    app.before_request(log_request)

    # Swagger documentation setup
    swaggerui_blueprint = get_swaggerui_blueprint(
        app.config["SWAGGER_URL"],
        app.config["API_URL"],
        config={"app_name": "Micro Service"},
    )

    app.register_blueprint(auth_bp, url_prefix="/auth")
    app.register_blueprint(apps_bp, url_prefix="/apps")
    app.register_blueprint(spotify_bp, url_prefix="/spotify")
    app.register_blueprint(profile_bp, url_prefix="/profile")
    app.register_blueprint(
        SpotifyMicroService_bp,
        url_prefix="/spotify-micro-service")
    app.register_blueprint(lyrics_bp, url_prefix="/lyrics")
    app.register_blueprint(google_bp, url_prefix="/google")
    app.register_blueprint(youtubeMusic_bp, url_prefix="/youtube-music")
    app.register_blueprint(apple_bp, url_prefix="/apple")
    app.register_blueprint(appleMusic_bp, url_prefix="/apple-music")
    app.register_blueprint(
        swaggerui_blueprint,
        url_prefix=app.config["SWAGGER_URL"])

    app.register_blueprint(errors_bp, url_prefix="/")
    app.register_error_handler(400, bad_request)
    app.register_error_handler(401, unauthorized)
    app.register_error_handler(403, forbidden)
    app.register_error_handler(404, page_not_found)
    app.register_error_handler(405, method_not_allowed)
    app.register_error_handler(408, request_timeout)
    app.register_error_handler(429, too_many_requests)
    app.register_error_handler(500, internal_server_error)

    app.register_blueprint(util_bp, url_prefix="/")

    return app


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Run Flask on a specific port.")
    parser.add_argument(
        "--port", type=int, default=8080, help="Port to run the Flask app."
    )
    args = parser.parse_args()
    app = create_app()
    app.run(
        host="0.0.0.0", port=args.port, ssl_context=("keys/cert.pem", "keys/key.pem")
    )
