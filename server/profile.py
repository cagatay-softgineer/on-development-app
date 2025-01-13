from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from utils import execute_query_with_logging

profile_bp = Blueprint('profile', __name__)

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

