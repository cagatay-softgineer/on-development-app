from datetime import timedelta
from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, create_refresh_token, get_jwt_identity, jwt_required
from flask_limiter import Limiter
from flask_cors import CORS
from flask_limiter.util import get_remote_address
import bcrypt
import database.firebase_operations as firebase_operations
from util.models import RegisterRequest, LoginRequest  # Import models
from util.logit import get_logger
from pydantic import ValidationError
from util.authlib import default_user


auth_bp = Blueprint('auth', __name__)
limiter = Limiter(key_func=get_remote_address)

# Enable CORS for all routes in this blueprint
CORS(auth_bp, resources={r"/*": {"origins": "*"}})
 
logger = get_logger("logs/auth.log","Auth")


# Add /healthcheck to each blueprint
@auth_bp.before_request
def log_spotify_requests():
    logger.info("Spotify blueprint request received.")
    
# Add /healthcheck to each blueprint
@auth_bp.route("/healthcheck", methods=["GET"])
def auth_healthcheck():
    logger.info("Auth Service healthcheck requested")
    return jsonify({"status": "ok", "service": "Auth Service"}), 200



@auth_bp.route('/register', methods=['POST'])
def register():
    """
    Registers a new user by validating the request payload, hashing the password, and storing it in the database.

    This function receives a POST request containing a JSON payload with the user's email and password.
    It validates the payload using the RegisterRequest model. If the payload is valid, it hashes the password
    using the bcrypt library and stores the user's email and hashed password in the database using the
    firebase_operations module. It then returns a JSON response indicating successful registration.

    Parameters:
    - request: A Flask request object containing the JSON payload with the user's email and password.

    Returns:
    - A Flask response object containing a JSON response with a "message" field indicating successful registration.
      If the payload is invalid, it returns a JSON response with an "error" field containing the validation errors.
      The HTTP status code is set to 400 in case of validation errors.
    """
    try:
        payload = RegisterRequest.parse_obj(request.get_json())
    except ValidationError as ve:
        return jsonify({"error": ve.errors()}), 400

    # hashed_password = bcrypt.hashpw(payload.password.encode('utf-8'), bcrypt.gensalt())

    firebase_operations.insert_user(payload.email,payload.password)
    return jsonify({"message": "User registered successfully"}), 201

@auth_bp.route('/login', methods=['POST'])
def login():
    """
    Authenticates a user by verifying the email and password.

    This function receives a POST request containing a JSON payload with the user's email and password.
    It validates the payload using the LoginRequest model. If the payload is valid, it retrieves the user's
    hashed password from the database using the provided email. If the password matches the stored hashed
    password, it generates an access token using the Flask-JWT-Extended library and returns it along with
    the user's ID in a JSON response. If the email or password is invalid, it returns an error message in
    a JSON response.

    Parameters:
    - request: A Flask request object containing the JSON payload with the user's email and password.

    Returns:
    - A Flask response object containing a JSON response with the access token and user's ID if the
      authentication is successful. If the authentication fails, it returns a JSON response with an error
      message.
    """
    try:
        payload = LoginRequest.parse_obj(request.get_json())
    except ValidationError as ve:
        return jsonify({"error": ve.errors()}), 400

    result = firebase_operations.get_user_password_and_email(payload.email)[0]

    if result:
        user_id, stored_hashed_password = result["email"], result["password"]
        if bcrypt.checkpw(payload.password.encode('utf-8'), stored_hashed_password.encode('utf-8')):
            additional_claims = {"scopes": default_user}
            access_token = create_access_token(identity=payload.email,expires_delta=timedelta(days=7), additional_claims=additional_claims)
            refresh_token = create_refresh_token(identity=payload.email,expires_delta=timedelta(days=30))
            return jsonify({
                "access_token": access_token,
                "refresh_token": refresh_token,
                "user_id": user_id
            }), 200

    return jsonify({"error": "Invalid email or password"}), 401

@auth_bp.route('/refresh', methods=['POST']) 
@jwt_required(refresh=True) 
def refresh(): 
    identity = get_jwt_identity() 
    new_access_token = create_access_token(identity=identity) 
    return jsonify({ "access_token": new_access_token }), 200