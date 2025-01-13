from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required  # noqa: F401
from flask_limiter import Limiter
from flask_cors import CORS
from flask_limiter.util import get_remote_address
import bcrypt
from utils import execute_query_with_logging

auth_bp = Blueprint('auth', __name__)
limiter = Limiter(key_func=get_remote_address)

# Enable CORS for all routes in this blueprint
CORS(auth_bp, resources={r"/*": {"origins": "*"}})

@auth_bp.route('/register', methods=['POST', 'GET'])
def register():
    data = request.json
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({"error": "All fields are required"}), 400

    hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
    query = """
        INSERT INTO users (email, password)
        VALUES (?, ?)
    """
    execute_query_with_logging(query, "primary", (email, hashed_password.decode('utf-8')))
    return jsonify({"message": "User registered successfully"}), 201

@auth_bp.route('/login', methods=['POST', 'GET'])
def login():
    if request.method == 'OPTIONS':
        # Handle CORS preflight request
        return jsonify({"message": "CORS preflight successful"}), 200

    # Handle POST login logic
    try:
        data = request.json
        email = data.get("email")
        password = data.get("password")

        if not email or not password:
            return jsonify({"error": "Email and password are required"}), 400

        # Verify credentials
        query = "SELECT password,email FROM users WHERE email = ?"
        rows = execute_query_with_logging(query, "primary", params=(email,), fetch=True)

        if rows:
            stored_hashed_password = rows[0][0][0]
            user_id = rows[0][0][1]
            if bcrypt.checkpw(password.encode('utf-8'), stored_hashed_password.encode('utf-8')):
                access_token = create_access_token(identity=email)
                return jsonify({"access_token": access_token, "user_id": user_id}), 200

        return jsonify({"error": "Invalid email or password"}), 401
    except Exception:
        return jsonify({"error": "An internal error has occurred!"}), 500