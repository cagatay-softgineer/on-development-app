from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required  # noqa: F401
from flask_limiter import Limiter
from flask_cors import CORS
from flask_limiter.util import get_remote_address
from util.utils import get_current_user_profile
from Blueprints.google_api import get_google_profile
from util.models import LinkedAppRequest  # Import the model
import database.firebase_operations as firebase_operations
from pydantic import ValidationError
from config.config import settings
import logging

apps_bp = Blueprint('apps', __name__)
limiter = Limiter(key_func=get_remote_address)

OAUTHLIB_INSECURE_TRANSPORT=1
GOOGLE_CLIENT_SECRETS_FILE = settings.google_client_secret

# Enable CORS for all routes in this blueprint
CORS(apps_bp, resources={r"/*": {"origins": "*"}})

LOG_DIR = "logs/app_link.log"
logger = logging.getLogger("Apps")
logger.setLevel(logging.DEBUG)

# Create file handler
file_handler = logging.FileHandler(LOG_DIR, encoding="utf-8")
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

APP_ALIAS_TO_ID = {
    "Spotify": 1,
    "AppleMusic": 2,
    "YoutubeMusic": 3,
    "Google API": 4,
}

def get_app_id_by_alias(alias: str):
    app_id = APP_ALIAS_TO_ID.get(alias)
    if app_id is None:
        raise ValueError(f"App alias '{alias}' not configured.")
    return app_id


def get_app_name_by_alias(app_id: int):
    for alias, id_value in APP_ALIAS_TO_ID.items():
        if id_value == app_id:
            return alias
    raise ValueError(f"App ID '{app_id}' not found.")

@apps_bp.route('/check_linked_app', methods=['POST'])
def check_linked_app():
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
    
    firebase_operations.delete_userlinkedapps(user_id, app_id)

    return jsonify({"message": "App Unlinked!"}), 201