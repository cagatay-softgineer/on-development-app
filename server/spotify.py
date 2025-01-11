from flask import Blueprint, request, jsonify, redirect, render_template
from flask_limiter import Limiter
from flask_cors import CORS
from flask_limiter.util import get_remote_address
from dotenv import load_dotenv
import requests
import os
from utils import execute_query_with_logging
import base64
import secrets
import logging

spotify_bp = Blueprint('spotify', __name__)
limiter = Limiter(key_func=get_remote_address)

# Enable CORS for all routes in this blueprint
CORS(spotify_bp, resources={r"/*": {"origins": "*"}})

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

# Helper function to get Spotify user profile
def get_user_profile(access_token):
    url = "https://api.spotify.com/v1/me"
    headers = {"Authorization": f"Bearer {access_token}"}
    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        return response.json()
    else:
        logger.error(f"Failed to fetch user profile: {response.status_code} - {response.text}")
        return None

# Function to fetch playlists of the user
def fetch_user_playlists(user_id):
    # Query to get the access token for the user
    query = """
    SELECT access_token
    FROM UserLinkedApps
    WHERE user_id = ? AND app_id = ?
    """
    result = execute_query_with_logging(query, "primary", params=(user_id, 1), fetch=True)

    if not result:
        logger.error(f"Access token not found for user_id: {user_id}")
        return None

    access_token = result[0][0][0]
    print(access_token)

    # Spotify API endpoint for user playlists
    url = "https://api.spotify.com/v1/me/playlists"
    headers = {"Authorization": f"Bearer {access_token}"}

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        playlists_data = response.json()
        formatted_playlists = []
        
        for item in playlists_data.get("items", []):
            # Fetch track details for each playlist
            #tracks_url = item["tracks"]["href"]
            #tracks_response = requests.get(tracks_url, headers=headers)
            #
            #if tracks_response.status_code == 200:
            #    tracks_data = tracks_response.json()
            #    print(tracks_data)
            #    tracks = [
            #        {
            #            "track_name": track["track"]["name"],
            #            "artist_name": ", ".join(
            #                [artist["name"] for artist in track["track"]["artists"]]
            #            ),
            #            "track_id": track["track"]["id"],
            #            "track_images": track["track"]["album"]["images"][0]["url"]
            #            if track["track"]["album"]["images"]
            #            else "",
            #        }
            #        for track in tracks_data.get("items", [])
            #    ]
            #else:
            #    logger.error(f"Failed to fetch tracks for playlist {item['id']}.")
            #    tracks = []

            formatted_playlist = {
                "playlist_name": item["name"],
                "playlist_id": item["id"],
                "playlist_image": item["images"][0]["url"] if item["images"] else "",
                "tracks": [],
            }
            formatted_playlists.append(formatted_playlist)

        logger.info("Successfully fetched and formatted playlists.")
        return formatted_playlists
    else:
        logger.error(f"Failed to fetch playlists: {response.status_code} - {response.text}")
        return None


# Example endpoint to fetch playlists
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


# Function to refresh access token
def refresh_access_token_and_update_db(user_id, refresh_token):
    url = "https://accounts.spotify.com/api/token"
    auth_header = base64.b64encode(f"{CLIENT_ID}:{CLIENT_SECRET}".encode()).decode()

    headers = {
        "Authorization": f"Basic {auth_header}",
        "Content-Type": "application/x-www-form-urlencoded"
    }
    data = {
        "grant_type": "refresh_token",
        "refresh_token": refresh_token
    }

    response = requests.post(url, headers=headers, data=data)

    if response.status_code == 200:
        token_info = response.json()
        new_access_token = token_info.get("access_token")
        new_refresh_token = token_info.get("refresh_token", refresh_token)  # Use the new refresh token if provided, otherwise keep the old one
        expires_in = token_info.get("expires_in", 3600)  # Default to 1 hour if not provided

        logger.info("Successfully refreshed access token.")

        # Update tokens in the database
        query = """
        UPDATE UserLinkedApps
        SET access_token = ?,
            refresh_token = ?,
            token_expires_at = DATEADD(SECOND, ?, GETDATE())
        WHERE user_id = ? AND app_id = ?
        """

        execute_query_with_logging(query, "primary", (new_access_token, new_refresh_token, expires_in, user_id, 1))

        return new_access_token
    else:
        logger.error(f"Failed to refresh access token: {response.status_code} - {response.text}")
        return None

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
        success = True, access_token = access_token, refresh_token = refresh_token
    ), 200
    else:
        logger.error(f"Failed to obtain access token: {response.status_code} - {response.text}")
        return jsonify({"error": "Failed to obtain access token"}), 400
