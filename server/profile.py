from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from utils import execute_query_with_logging
import logging

profile_bp = Blueprint('profile', __name__)

# Logging setup
LOG_DIR = "logs/profile.log"
logger = logging.getLogger("Profile")
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

@profile_bp.route('/view', methods=['GET'])
@jwt_required()
def view_profile():
    current_user = get_jwt_identity()
    print(current_user)
    
    query = "SELECT user_id FROM users WHERE email = ?"
    rows = execute_query_with_logging(query, "primary", params=(current_user), fetch=True)

    if rows:
        user_id = rows[0][0][0]
        
    print(user_id)
    
    query = """
        SELECT first_name, last_name, avatar_url, bio
        FROM UserProfiles
        WHERE user_id = ?
    """
    rows = execute_query_with_logging(query, "primary", (user_id), fetch=True)

    if rows[0] != []:
        user = rows[0][0]
        return jsonify({
            "first_name": user[0],
            "last_name": user[1],
            "avatar_url": user[2],
            "bio" : user[3],
        }), 200
    return jsonify({"error": "User not found"}), 404

