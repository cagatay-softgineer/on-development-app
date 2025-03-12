from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
import logging
import database.firebase_operations as firebase_operations

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
    
    user_id = firebase_operations.get_user_id_by_email(current_user)
    
    rows = firebase_operations.get_user_profile(user_id)
    print(rows)
    if rows[0] != []:
        user = rows[0]
        return jsonify({
            "first_name": user["first_name"],
            "last_name": user["last_name"],
            "avatar_url": user["avatar_url"],
            "bio" : user["bio"],
        }), 200
    return jsonify({"error": "User not found"}), 404

