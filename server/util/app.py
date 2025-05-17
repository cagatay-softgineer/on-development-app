from config.config import settings
from flask import Flask, render_template, request
from flask_talisman import Talisman
from flask_jwt_extended import JWTManager
from flask_limiter import Limiter
from flask_cors import CORS
from util.logit import get_logger
from util.blueprints import register_blueprints
from util.error_handlers import register_error_handlers


def create_app(app: Flask, testing=False):

    Talisman(app,
             strict_transport_security=True,
             strict_transport_security_max_age=31536000,
             strict_transport_security_include_subdomains=True,
             strict_transport_security_preload=True,
             content_security_policy=settings.csp_allow_all)

    jwt = JWTManager(app)  # noqa: F841
    limiter = Limiter(app)  # noqa: F841

    app.config["JWT_SECRET_KEY"] = settings.jwt_secret_key
    app.config["SWAGGER_URL"] = "/api/docs"
    app.config["API_URL"] = "/static/swagger.json"
    app.config["SECRET_KEY"] = settings.SECRET_KEY
    app.config["PREFERRED_URL_SCHEME"] = "https"
    app.config["TESTING"] = testing

    CORS(app, resources=settings.CORS_resource_allow_all)

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

    @app.route("/", methods=["GET"])
    def index():
        return render_template("index.html", user_id="pomodoro_enjoyer")

    @app.route("/open", methods=["GET"])
    def open():
        return render_template("open.html", user_id="pomodoro_enjoyer")

    app = register_blueprints(app)
    app = register_error_handlers(app)

    return app
