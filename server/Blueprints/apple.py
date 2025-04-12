from flask import Blueprint, request, jsonify, render_template
from flask_limiter import Limiter
from flask_jwt_extended import jwt_required
from flask_cors import CORS
from flask_limiter.util import get_remote_address
import secrets

from pydantic import ValidationError
from config.config import settings
from util.logit import get_logger
import database.firebase_operations as firebase_operations
from util.authlib import requires_scope
from util.models import UserEmailRequest

apple_bp = Blueprint("apple", __name__)
limiter = Limiter(key_func=get_remote_address)

# Enable CORS for all routes in this blueprint
CORS(apple_bp, resources={r"/*": {"origins": "*"}})

logger = get_logger("logs/apple_api.log", "Apple Music API")

# Load environment variables
# DEVELOPER_TOKEN is generated on your server (via JWT, etc.) and used by
# MusicKit JS.
DEVELOPER_TOKEN = settings.apple_developer_token
# REDIRECT_URI = settings.apple_auth_redirect_uri  # if needed

# Global variable to store the user ID (or email) during the auth flow
USER_ID_GLOBAL = ""


def generate_random_state(length=16):
    return secrets.token_hex(length)

@apple_bp.route("/healthcheck", methods=["GET"])
def apple_healthcheck():
    logger.info("Apple Service healthcheck requested")
    return jsonify({"status": "ok", "service": "Apple Service"}), 200

@apple_bp.route("/login/<user_id>", methods=["GET"])
@jwt_required()
@requires_scope("apple")
def login(user_id):
    """
    Initiates the Apple Music authentication process.

    Sets the global user identifier and renders a login page that loads MusicKit JS.
    The rendered page (apple_login.html) should use the provided developer token to initialize MusicKit
    and then trigger user authorization. Once the client obtains the Apple Music user token,
    it should call the /callback endpoint.
    """
    global USER_ID_GLOBAL
    USER_ID_GLOBAL = user_id

    # Render a template that includes MusicKit JS and triggers Apple Music authorization.
    # Pass the developer token and user ID to the client.
    return render_template(
        "apple_login.html", developer_token=DEVELOPER_TOKEN, user_id=user_id
    )


@apple_bp.route("/callback", methods=["GET"])
def callback():
    """
    Callback endpoint to handle the Apple Music user token.

    Expects a query parameter "user_token" provided by the client after MusicKit JS authorization.
    Once received, the user token is stored (e.g., in your Firebase database) for later use.
    """
    user_token = request.args.get("user_token")
    if not user_token:
        logger.error("User token not found in callback request.")
        return jsonify({"error": "User token not found"}), 400

    # Retrieve your user ID (or email) from the global variable.
    # In a real application, you might pass a state parameter to verify this.
    user_id = firebase_operations.get_user_id_by_email(USER_ID_GLOBAL)

    # Store the Apple Music user token in your database.
    # Here we assume app_id 2 represents Apple Music (distinct from Spotify's
    # 1).
    firebase_operations.if_not_exists_insert_userlinkedapps(
        user_id, 2, user_token, "", ""
    )

    logger.info("Successfully obtained and stored Apple Music user token.")
    return render_template("apple.html", success=True, user_id=user_id), 200


@apple_bp.route("/token", methods=["POST"])
@jwt_required()
@requires_scope("apple")
def get_token():
    """
    Retrieves the stored Apple Music user token for a given user.

    Expects a JSON payload containing "user_email".
    Returns the user token in JSON format.
    """
    try:
        payload = UserEmailRequest.parse_obj(request.get_json())
    except ValidationError as ve:
        return jsonify({"error": ve.errors()}), 400
    user_email = payload.user_email

    user_id = firebase_operations.get_user_id_by_email(user_email)
    response = firebase_operations.get_userlinkedapps_tokens(user_id, 2)

    access_tokens = response[0]["access_token"]
    return jsonify({"token": access_tokens}), 200


@apple_bp.route("/library", methods=["POST"])
@jwt_required()
@requires_scope("apple")
def get_library():
    """
    (Optional) Fetches the user's Apple Music library.

    Expects a JSON payload with "user_email" and uses the stored user token to call the Apple Music API.
    (You will need to implement fetch_user_library according to your application’s needs.)
    """
    try:
        payload = UserEmailRequest.parse_obj(request.get_json())
    except ValidationError as ve:
        return jsonify({"error": ve.errors()}), 400
    user_email = payload.user_email

    user_id = firebase_operations.get_user_id_by_email(user_email)
    response = firebase_operations.get_userlinkedapps_tokens(user_id, 2)

    access_tokens = response[0]["access_token"]
    library_json = fetch_user_library(user_id, access_tokens)
    return jsonify(library_json), 200


def fetch_user_library(user_id, user_token):
    """
    Placeholder function to fetch the user's Apple Music library.

    Use the developer token and user token to call Apple Music's API endpoints.
    Note: Apple Music’s API is typically accessed via MusicKit JS on the client-side.
    Implement this function as required for your use case.
    """
    # Example stub response.
    return {"message": "User library fetch not implemented."}
