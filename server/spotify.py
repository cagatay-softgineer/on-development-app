from flask import Blueprint, request, jsonify, redirect, render_template, escape
from flask_limiter import Limiter
from flask_cors import CORS
from flask_limiter.util import get_remote_address
from dotenv import load_dotenv
import requests
import os
from utils import execute_query_with_logging, get_user_profile, fetch_user_playlists, get_access_token_from_db, get_email_username
import secrets
import logging

spotify_bp = Blueprint('spotify', __name__)
limiter = Limiter(key_func=get_remote_address)

# Enable CORS for all routes in this blueprint
CORS(spotify_bp, resources={r"/*": {"origins": "*"}})

# Logging setup
LOG_DIR = "logs/spotify_api.log"
logger = logging.getLogger("SpotifyAPI")
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

# Load environment variables
load_dotenv()
CLIENT_ID = os.getenv("AUTH_CLIENT_ID")
CLIENT_SECRET = os.getenv("AUTH_CLIENT_SECRET")
REDIRECT_URI = os.getenv("AUTH_REDIRECT_URI")

USER_EMAIL = ""

# Setup logging
logger = logging.getLogger("SpotifyAuthService")
logger.setLevel(logging.DEBUG)

# Function to generate random state
def generate_random_state(length=16):
    return secrets.token_hex(length)

@spotify_bp.route('/login/<user_id>', methods=['GET'])
def login(user_id):
    global USER_EMAIL
    USER_EMAIL = user_id
    
    
    state = generate_random_state()
    scope = "user-read-recently-played user-read-private user-read-email playlist-read-private playlist-read-collaborative user-library-read user-top-read user-read-playback-state user-modify-playback-state user-read-currently-playing"

    auth_url = (
        f"https://accounts.spotify.com/authorize?"
        f"response_type=code&client_id={CLIENT_ID}"
        f"&redirect_uri={REDIRECT_URI}&scope={scope}&state={state}"
    )

    logger.info("Redirecting to Spotify authorization URL.")
    return redirect(auth_url)

# Example endpoint to fetch playlists
@spotify_bp.route('/user_profile', methods=['POST','GET'])
def get_user():
    data = request.json
    user_id = data.get('user_id')
    return get_user_profile(escape(user_id))
    

@spotify_bp.route('/playlists', methods=['POST','GET'])
def get_playlists():
    data = request.json
    user_email = data.get('user_email')
    query = "SELECT user_id FROM users WHERE email = ?"
    rows = execute_query_with_logging(query, "primary", params=(user_email), fetch=True)

    if rows:
        user_id = rows[0][0][0]
        
    
    playlists_json = fetch_user_playlists(user_id)
    return jsonify(playlists_json), 200


@spotify_bp.route('/token', methods=['POST','GET'])
def get_token():
    data = request.json
    user_email = data.get('user_email')
    query = "SELECT user_id FROM users WHERE email = ?"
    rows = execute_query_with_logging(query, "primary", params=(user_email), fetch=True)
    
    if rows:
        user_id = rows[0][0][0]

    token, _ = get_access_token_from_db(user_id)
    return jsonify({"token":token}), 200

@spotify_bp.route('/callback', methods=['GET'])
def callback():
    code = request.args.get("code")
    if not code:
        logger.error("Authorization code not found in callback request.")
        return jsonify({"error": "Authorization code not found"}), 400

    token_url = "https://accounts.spotify.com/api/token"
    token_data = {
        "grant_type": "authorization_code",
        "code": code,
        "redirect_uri": REDIRECT_URI,
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
    }
    token_headers = {"Content-Type": "application/x-www-form-urlencoded"}

    response = requests.post(token_url, data=token_data, headers=token_headers)

    if response.status_code == 200:
        token_info = response.json()
        access_token = token_info["access_token"]
        refresh_token = token_info.get("refresh_token")
        scope = token_info.get("scope")
        #expires_in = token_info.get("expires_in")
        #token_type = token_info.get("token_type")
        
        logger.info("Successfully obtained access token.")
        
        query = "SELECT user_id FROM users WHERE email = ?"
        rows = execute_query_with_logging(query, "primary", params=(USER_EMAIL), fetch=True)

        if rows:
            user_id = rows[0][0][0]
        
        query = """
        IF NOT EXISTS (
            SELECT 1
            FROM UserLinkedApps
            WHERE user_id = ? AND app_id = ?
        )
        BEGIN
            INSERT INTO UserLinkedApps (user_id, app_id, access_token, refresh_token, token_expires_at, scopes)
            VALUES (?, ?, ?, ?, DATEADD(HOUR, 1, GETDATE()), ?)
        END
        """
        execute_query_with_logging(query, "primary", (user_id, 1, user_id, 1, access_token, refresh_token, scope))
        
        return render_template(
        "message.html",
        success = True, user_id = get_email_username(USER_EMAIL)
    ), 200
    else:
        logger.error(f"Failed to obtain access token: {response.status_code} - {response.text}")
        return jsonify({"error": "Failed to obtain access token"}), 400
