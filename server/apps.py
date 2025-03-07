from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required  # noqa: F401
from flask_limiter import Limiter
from flask_cors import CORS
from flask_limiter.util import get_remote_address
from utils import get_current_user_profile
import logging
from models import LinkedAppRequest  # Import the model
from pydantic import ValidationError
import firebase_operations

apps_bp = Blueprint('apps', __name__)
limiter = Limiter(key_func=get_remote_address)

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

@apps_bp.route('/check_linked_app', methods=['POST'])
def check_linked_app():
    try:
        payload = LinkedAppRequest.parse_obj(request.get_json())
    except ValidationError as ve:
        return jsonify({"error": ve.errors()}), 400 

    # Use validated data
    app_name = payload.app_name
    user_email = payload.user_email
    
    user_id = firebase_operations.get_user_id_by_email(user_email)[0]
    app_id = firebase_operations.get_app_id_by_name(app_name)[0]
        
    if not app_id:
        return jsonify({"error": "All fields are required",
                        "user_linked": False,
                        "user_profile": None}), 400
    access_token = firebase_operations.get_userlinkedapps_count_and_access_token(user_id, app_id)
    
    if access_token:
        user_linked, access_token = access_token[0], access_token[1][0]

        if user_linked > 0:
            user_profile = get_current_user_profile(access_token, user_id, app_id)
            return jsonify({
                "user_linked": True,
                "user_profile": user_profile
            }), 200

        return jsonify({
            "user_linked": False,
            "user_profile": None
        }), 200

    return jsonify({
        "error": "User not linked or not found",
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

    user_id = firebase_operations.get_user_id_by_email(user_email)[0]
    app_id = firebase_operations.get_app_id_by_name(app_name)[0]
        
    if not app_id:
        return jsonify({"error": "All fields are required"}), 400
    
    firebase_operations.delete_userlinkedapps(app_id, user_id)

    return jsonify({"message": "App Unlinked!"}), 201