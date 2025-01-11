from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required  # noqa: F401
from flask_limiter import Limiter
from flask_cors import CORS
from flask_limiter.util import get_remote_address
from utils import execute_query_with_logging

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

    if rows:
        user_id = rows[0][0][0]
    
    query = "SELECT app_id FROM Apps WHERE app_name = ?"
    rows = execute_query_with_logging(query, "primary", params=(app_name), fetch=True)

    if rows:
        app_id = rows[0][0][0]
        
    if not app_id:
        return jsonify({"error": "All fields are required"}), 400

    query = "SELECT Count(*) FROM UserLinkedApps WHERE app_id = ? and user_id = ?"
    
    rows = execute_query_with_logging(query, "primary", (app_id, user_id), fetch=True)
    if rows:
        user_linked = rows[0][0][0]
    return jsonify({"user_linked": True if user_linked == 1 else False}), 201

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
