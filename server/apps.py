from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required  # noqa: F401
from flask_limiter import Limiter
from flask_cors import CORS
from flask_limiter.util import get_remote_address
from utils import execute_query_with_logging, get_current_user_profile
import logging
from models import LinkedAppRequest  # Import the model
from pydantic import ValidationError

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

    query = "SELECT user_id FROM users WHERE email = ?"
    rows = execute_query_with_logging(query, "primary", params=(user_email,), fetch=True)
    user_id = rows[0][0][0] if rows and rows[0] != [] else False

    query = "SELECT app_id FROM Apps WHERE app_name = ?"
    rows = execute_query_with_logging(query, "primary", params=(app_name,), fetch=True)
    app_id = rows[0][0][0] if rows and rows[0] != [] else False
        
    if not app_id:
        return jsonify({"error": "All fields are required",
                        "user_linked": False,
                        "user_profile": None}), 400

    query = """
        SELECT 
            (SELECT COUNT(*) 
             FROM UserLinkedApps 
             WHERE app_id = ? AND user_id = ?) AS user_linked, 
            access_token 
        FROM UserLinkedApps 
        WHERE app_id = ? AND user_id = ?
    """
    
    rows = execute_query_with_logging(query, "primary", (app_id, user_id, app_id, user_id), fetch=True)
    if rows and rows[0] != []:
        user_linked = rows[0][0][0]
        access_token = rows[0][0][1]

        if user_linked > 0:
            user_profile = get_current_user_profile(access_token, user_id)
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

    query = "SELECT user_id FROM users WHERE email = ?"
    rows = execute_query_with_logging(query, "primary", params=(user_email,), fetch=True)
    user_id = rows[0][0][0] if rows else None
    
    query = "SELECT app_id FROM Apps WHERE app_name = ?"
    rows = execute_query_with_logging(query, "primary", params=(app_name,), fetch=True)
    app_id = rows[0][0][0] if rows else None
        
    if not app_id:
        return jsonify({"error": "All fields are required"}), 400

    query = "DELETE FROM UserLinkedApps WHERE app_id = ? and user_id = ?"
    execute_query_with_logging(query, "primary", (app_id, user_id))
    return jsonify({"message": "App Unlinked!"}), 201