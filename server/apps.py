from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required  # noqa: F401
from flask_limiter import Limiter
from flask_cors import CORS
from flask_limiter.util import get_remote_address
from utils import execute_query_with_logging, get_current_user_profile

apps_bp = Blueprint('apps', __name__)
limiter = Limiter(key_func=get_remote_address)

# Enable CORS for all routes in this blueprint
CORS(apps_bp, resources={r"/*": {"origins": "*"}})

@apps_bp.route('/check_linked_app', methods=['POST', 'GET'])
def check_linked_app():
    data = request.json
    app_name = data.get('app_name')
    user_email = data.get('user_email')

    query = "SELECT user_id FROM users WHERE email = ?"
    rows = execute_query_with_logging(query, "primary", params=(user_email), fetch=True)

    if rows[0] != []:
        user_id = rows[0][0][0]
    else:
        user_id = False
    
    query = "SELECT app_id FROM Apps WHERE app_name = ?"
    rows = execute_query_with_logging(query, "primary", params=(app_name), fetch=True)

    if rows[0] != []:
        app_id = rows[0][0][0]
    else:
        app_id = False
        
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
    if rows[0] != []:
        user_linked = rows[0][0][0]  # First column is the count (user_linked)
        access_token = rows[0][0][1]  # Second column is the access_token

        if user_linked > 0:  # If count is greater than 0, user is linked
            user_profile = get_current_user_profile(access_token, user_id)
            return jsonify({
                "user_linked": True,
                "user_profile": user_profile
            }), 200

        # User is not linked, return only the user_linked status
        return jsonify({
            "user_linked": False,
            "user_profile": None
        }), 200

    # No rows found, return an appropriate error response
    return jsonify({
        "error": "User not linked or not found",
        "user_linked": False,
        "user_profile": None
    }), 404

@apps_bp.route('/unlink_app', methods=['POST', 'GET'])
def unlink_app():
    data = request.json
    app_name = data.get('app_name')
    user_email = data.get('user_email')

    query = "SELECT user_id FROM users WHERE email = ?"
    rows = execute_query_with_logging(query, "primary", params=(user_email), fetch=True)

    if rows:
        user_id = rows[0][0][0]
    
    query = "SELECT app_id FROM Apps WHERE app_name = ?"
    rows = execute_query_with_logging(query, "primary", params=(app_name), fetch=True)

    if rows:
        app_id = rows[0][0][0]
        
    if not app_id:
        return jsonify({"error": "All fields are required"}), 400

    query = "Delete FROM UserLinkedApps WHERE app_id = ? and user_id = ?"
    
    execute_query_with_logging(query, "primary", (app_id, user_id))

    return jsonify({"message": "App Unlinked!"}), 201
