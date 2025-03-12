from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token
from flask_limiter import Limiter
from flask_cors import CORS
from flask_limiter.util import get_remote_address
import bcrypt
import logging
import database.firebase_operations as firebase_operations
from util.models import RegisterRequest, LoginRequest  # Import models
from pydantic import ValidationError

auth_bp = Blueprint('auth', __name__)
limiter = Limiter(key_func=get_remote_address)

# Enable CORS for all routes in this blueprint
CORS(auth_bp, resources={r"/*": {"origins": "*"}})

LOG_DIR = "logs/auth.log"
logger = logging.getLogger("Auth")
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

@auth_bp.route('/register', methods=['POST'])
def register():
    try:
        payload = RegisterRequest.parse_obj(request.get_json())
    except ValidationError as ve:
        return jsonify({"error": ve.errors()}), 400

    # hashed_password = bcrypt.hashpw(payload.password.encode('utf-8'), bcrypt.gensalt())

    firebase_operations.insert_user(payload.email,payload.password)
    return jsonify({"message": "User registered successfully"}), 201

@auth_bp.route('/login', methods=['POST'])
def login():
    try:
        payload = LoginRequest.parse_obj(request.get_json())
    except ValidationError as ve:
        return jsonify({"error": ve.errors()}), 400

    result = firebase_operations.get_user_password_and_email(payload.email)[0]

    if result:
        user_id, stored_hashed_password = result["email"], result["password"]
        if bcrypt.checkpw(payload.password.encode('utf-8'), stored_hashed_password.encode('utf-8')):
            access_token = create_access_token(identity=payload.email)
            return jsonify({"access_token": access_token, "user_id": user_id}), 200

    return jsonify({"error": "Invalid email or password"}), 401