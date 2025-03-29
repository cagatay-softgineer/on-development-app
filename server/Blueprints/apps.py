from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required  # noqa: F401
from flask_limiter import Limiter
from flask_cors import CORS
from flask_limiter.util import get_remote_address
from util.spotify import get_current_user_profile
from Blueprints.google_api import get_google_profile
from util.models import LinkedAppRequest  # Import the model
from util.logit import get_logger
import database.firebase_operations as firebase_operations
from pydantic import ValidationError
from config.config import settings

apps_bp = Blueprint('apps', __name__)
limiter = Limiter(key_func=get_remote_address)

OAUTHLIB_INSECURE_TRANSPORT=1
GOOGLE_CLIENT_SECRETS_FILE = settings.google_client_secret

# Enable CORS for all routes in this blueprint
CORS(apps_bp, resources={r"/*": {"origins": "*"}})

logger = get_logger("logs/app_link.log", "Apps")

APP_ALIAS_TO_ID = {
    "Spotify": 1,
    "AppleMusic": 2,
    "YoutubeMusic": 3,
    "Google API": 4,
}

def get_app_id_by_alias(alias: str) -> int:
    """
    Retrieves the application ID based on the given application alias.

    Parameters:
    alias (str): The alias of the application. The alias should be one of the keys in the APP_ALIAS_TO_ID dictionary.

    Returns:
    int: The ID of the application corresponding to the given alias.
         Raises ValueError if the alias is not found in the APP_ALIAS_TO_ID dictionary.

    Raises:
    ValueError: If the alias is not found in the APP_ALIAS_TO_ID dictionary.
    """
    app_id = APP_ALIAS_TO_ID.get(alias)
    if app_id is None:
        raise ValueError(f"App alias '{alias}' not configured.")
    return app_id




def get_app_name_by_alias(app_id: int) -> str:
    """
    Retrieves the application name based on the given application ID.

    Parameters:
    app_id (int): The unique identifier of the application.

    Returns:
    str: The name of the application corresponding to the given ID.
         Raises ValueError if the application ID is not found.

    Raises:
    ValueError: If the application ID is not found in the APP_ALIAS_TO_ID dictionary.
    """
    for alias, id_value in APP_ALIAS_TO_ID.items():
        if id_value == app_id:
            return alias
    raise ValueError(f"App ID '{app_id}' not found.")

@apps_bp.route('/check_linked_app', methods=['POST'])
def check_linked_app():
    """
    This function checks if a user is linked to a specific application and retrieves the user's profile.

    Parameters:
    - request.get_json(): A JSON object containing the user's email and the application name.

    Returns:
    - jsonify({"error": "All required fields must be provided."}), 400: If the user email or application name is missing.
    - jsonify({"error": "Missing application or user identifier."}), 400: If the application or user identifier is not found.
    - jsonify({"user_linked": True, "user_profile": user_profile}), 200: If the user is linked to the application and the user profile is retrieved successfully.
    - jsonify({"user_linked": False, "user_profile": None}), 200: If the user is not linked to the application.
    - jsonify({"error": "Unable to verify user linkage."}), 404: If the user linkage cannot be verified.
    - jsonify({"error": "Unknown application"}), 400: If the application is not recognized.
    """
    try:
        payload = LinkedAppRequest.parse_obj(request.get_json())
    except ValidationError as ve:
        return jsonify({"error": ve.errors()}), 400 

    # Use validated data
    app_name = payload.app_name
    user_email = payload.user_email

    user_id = firebase_operations.get_user_id_by_email(user_email)
    app_id = firebase_operations.get_app_id_by_name(app_name)
    print(app_id, user_id, app_name, user_email)

    if not app_name or not user_email:
        return jsonify({
            "error": "All required fields must be provided.",
            "user_linked": False,
            "user_profile": None
        }), 400

    if not app_id or not user_id:
        return jsonify({
            "error": "Missing application or user identifier. This may indicate that the user is not linked, does not exist, or the application is unrecognized.",
            "user_linked": False,
            "user_profile": None
        }), 400

    response = firebase_operations.get_userlinkedapps_tokens(user_id, app_id)

    access_tokens = response[0]["access_token"]
    user_linked = response is not None
    print("User access_tokens", access_tokens)
    if access_tokens:
        access_token = access_tokens[0]

        if user_linked:

            linked_app = get_app_name_by_alias(app_id)

            if linked_app == "Spotify":

                user_profile = get_current_user_profile(access_token, user_id, app_id)
                return jsonify({
                    "user_linked": True,
                    "user_profile": user_profile
                }), 200

            elif linked_app == "AppleMusic":
                return jsonify({
                    "user_linked": True,
                    "user_profile": "Apple Music Not Implementated"
                }), 200
            elif linked_app == "YoutubeMusic":
                user_profile = get_google_profile(user_email)
                return jsonify({
                    "user_linked": True,
                    "user_profile": user_profile
                }), 200    
            elif linked_app == "Google API":
                return jsonify({
                    "user_linked": True,
                    "user_profile": "Google API Not Implementated"
                }), 200
            else:
                return jsonify({
                    "error": "Unknown application",
                    "user_linked": False,
                    "user_profile": None
                }), 400


        return jsonify({
            "user_linked": False,
            "user_profile": None
        }), 200

    return jsonify({
        "error": "Unable to verify user linkage; the user is either not linked or not found.",
        "user_linked": False,
        "user_profile": None
    }), 404


@apps_bp.route('/unlink_app', methods=['POST'])
def unlink_app():
    """
    Unlinks a user from a specific application.

    This function receives a POST request containing the user's email and the application name.
    It validates the request payload, retrieves the user ID and application ID from the database,
    and then deletes the user-application link from the database.
    If the application ID is 3 (Youtube Music), it also deletes the link with Google API.

    Parameters:
    - request.get_json(): A JSON object containing the user's email and the application name.

    Returns:
    - jsonify({"message": "App Unlinked!"}), 201: If the user-application link is successfully deleted.
    - jsonify({"error": "All fields are required"}), 400: If the request payload is missing any required fields.
    """
    try:
        payload = LinkedAppRequest.parse_obj(request.get_json())
    except ValidationError as ve:
        return jsonify({"error": ve.errors()}), 400

    app_name = payload.app_name
    user_email = payload.user_email

    user_id = firebase_operations.get_user_id_by_email(user_email)
    app_id = firebase_operations.get_app_id_by_name(app_name)

    if not app_id:
        return jsonify({"error": "All fields are required"}), 400
    if app_id == 3:
        firebase_operations.delete_userlinkedapps(user_id, 4)

    firebase_operations.delete_userlinkedapps(user_id, app_id)

    return jsonify({"message": "App Unlinked!"}), 201


@apps_bp.route('/get_all_apps_binding', methods=['POST'])
def get_all_apps_binding():
    """
    Retrieves the binding state for all available applications for a given user.

    Expects a JSON payload with:
        - user_email: The email address of the user.

    Returns a JSON response containing the user's email and a list of applications,
    each with its name, binding state (true/false), and user profile data if linked.
    
    Example Response:
    {
        "user_email": "user@example.com",
        "apps": [
            {
                "app_name": "Spotify",
                "user_linked": true,
                "user_profile": { ... }
            },
            {
                "app_name": "AppleMusic",
                "user_linked": false,
                "user_profile": null
            },
            ...
        ]
    }
    """
    try:
        # Validate and extract the JSON payload
        data = request.get_json()
        user_email = data.get("user_email")
        if not user_email:
            return jsonify({"error": "User email is required."}), 400
    except Exception:
        return jsonify({"error": "Invalid JSON payload."}), 400

    # Retrieve user ID using Firebase operations
    user_id = firebase_operations.get_user_id_by_email(user_email)
    if not user_id:
        return jsonify({"error": "User not found."}), 400

    apps_status = []
    # Iterate over all configured applications
    for app_name, app_id in APP_ALIAS_TO_ID.items():
        response = firebase_operations.get_userlinkedapps_tokens(user_id, app_id)
        # Check if the response exists and contains access tokens
        if response and response[0].get("access_token"):
            tokens = response[0]["access_token"]
            # Depending on the application, retrieve the user profile if linked
            if app_name == "Spotify":
                user_profile = get_current_user_profile(tokens[0], user_id, app_id)
            elif app_name == "AppleMusic":
                user_profile = "Apple Music Not Implementated"
            elif app_name == "YoutubeMusic":
                user_profile = get_google_profile(user_email)
            elif app_name == "Google API":
                user_profile = "Google API Not Implementated"
            else:
                user_profile = None
            apps_status.append({
                "app_name": app_name,
                "user_linked": True,
                "user_profile": user_profile
            })
        else:
            apps_status.append({
                "app_name": app_name,
                "user_linked": False,
                "user_profile": None
            })

    return jsonify({
        "user_email": user_email,
        "apps": apps_status
    }), 200