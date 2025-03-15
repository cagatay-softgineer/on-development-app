from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required  # noqa: F401
from flask_limiter import Limiter
from flask_cors import CORS
from flask_limiter.util import get_remote_address
from config.config import settings
import logging
import requests
from pydantic import ValidationError
import database.firebase_operations as firebase_operations
from util.utils import refresh_access_token_and_update_db_for_Google
from util.models import PlaylistItemsRequest, UserEmailRequest

OAUTHLIB_INSECURE_TRANSPORT = 1

youtubeMusic_bp = Blueprint('youtubeMusic', __name__)
limiter = Limiter(key_func=get_remote_address)
CORS(youtubeMusic_bp, resources={r"/*": {"origins": "*"}})

# Logger configuration
LOG_DIR = "logs/youtube_music.log"
logger = logging.getLogger("YoutubeMusic")
logger.setLevel(logging.DEBUG)
file_handler = logging.FileHandler(LOG_DIR, encoding="utf-8")
file_handler.setLevel(logging.DEBUG)
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)
logger.addHandler(console_handler)
logger.propagate = False

# Constants for Google OAuth (for YouTube Music)
GOOGLE_SCOPES = [
    "https://www.googleapis.com/auth/youtube.readonly",
    "https://www.googleapis.com/auth/iam.test",
    "https://www.googleapis.com/auth/youtube.download",
    "https://www.googleapis.com/auth/userinfo.email",
    "https://www.googleapis.com/auth/userinfo.profile",
    "https://www.googleapis.com/auth/youtubepartner-channel-audit",
    "https://www.googleapis.com/auth/youtubepartner",
    "https://www.googleapis.com/auth/youtube.upload",
    "https://www.googleapis.com/auth/youtube.third-party-link.creator",
    "https://www.googleapis.com/auth/youtube.force-ssl",
    "https://www.googleapis.com/auth/youtube.channel-memberships.creator",
    "https://www.googleapis.com/auth/youtube",
    "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/service.management",
    "openid"
]  # Adjust scopes as needed
GOOGLE_CLIENT_SECRETS_FILE = settings.google_client_secret  # Path to your downloaded client secrets file
# Ensure to set a secret key for Flask session management in your app configuration

@youtubeMusic_bp.route('/playlists', methods=['POST'])
def get_playlists():
    """
    Retrieve the current user's YouTube Music playlists along with each playlist's channel image.
    Expects a JSON payload with the user's email in the format:
        {"user_email": "user@example.com"}
    """
    try:
        payload = UserEmailRequest.parse_obj(request.get_json())
    except ValidationError as ve:
        return jsonify({"error": ve.errors()}), 400

    user_email = payload.user_email
    if not user_email:
        return jsonify({"error": "Missing user_email parameter."}), 400

    try:
        # Retrieve the user ID from Firebase based on the email
        user_id = firebase_operations.get_user_id_by_email(user_email)
        if not user_id:
            return jsonify({"error": "User not found."}), 404

        # Retrieve the YouTube Music app ID (assumed to be 3 for YouTube Music)
        app_id = 3
        if not app_id:
            return jsonify({"error": "YouTube Music app not configured."}), 400

        # Retrieve stored token details for the user
        result = firebase_operations.get_userlinkedapps_access_refresh(user_id, app_id)[0]
        access_token, refresh_token = result["access_token"], result["refresh_token"]
        print(access_token)
        print(refresh_token)
        
        # Refresh the access token if needed
        new_access_token = refresh_access_token_and_update_db_for_Google(user_id, refresh_token)
        if not new_access_token or not new_access_token[0]:
            return jsonify({"error": "No token found. Please bind your YouTube Music account first."}), 400

        access_token = new_access_token
        print(access_token, "Access")

        # Fetch playlists from the YouTube API
        url = "https://www.googleapis.com/youtube/v3/playlists"
        params = {
            "part": "snippet,contentDetails, id, localizations, player, status",
            "mine":"true",
            "client_id": settings.google_client_id,
            "maxResults": 50  # Optional: adjust as needed
        }
        headers = {
            "Authorization": f"Bearer {access_token}"
        }
        response = requests.get(url, headers=headers, params=params)
        if response.status_code != 200:
            logger.error("Error fetching playlists: %s", response.text)
            return jsonify({"error": "Failed to fetch playlists from YouTube Music API."}), response.status_code

        playlists_data = response.json()
        items = playlists_data.get("items", [])

        # Extract unique channel IDs from the playlist items
        channel_ids = {item.get("snippet", {}).get("channelId") for item in items if item.get("snippet", {}).get("channelId")}
        if channel_ids:
            # Fetch channel details to retrieve channel images
            channels_url = "https://www.googleapis.com/youtube/v3/channels"
            channels_params = {
                "part": "snippet",
                "id": ",".join(channel_ids),
                "client_id": settings.google_client_id,
                "maxResults": 50
            }
            channels_response = requests.get(channels_url, headers=headers, params=channels_params)
            if channels_response.status_code == 200:
                channels_data = channels_response.json()
                # Build a mapping from channelId to channel image URL
                channel_map = {}
                for channel in channels_data.get("items", []):
                    cid = channel.get("id")
                    snippet = channel.get("snippet", {})
                    thumbnails = snippet.get("thumbnails", {})
                    # Prefer high quality thumbnail if available
                    channel_image = ""
                    if thumbnails.get("high") and thumbnails["high"].get("url"):
                        channel_image = thumbnails["high"]["url"]
                    elif thumbnails.get("default") and thumbnails["default"].get("url"):
                        channel_image = thumbnails["default"]["url"]
                    channel_map[cid] = channel_image

                # Add the channel image URL to each playlist's snippet
                for item in items:
                    snippet = item.get("snippet", {})
                    cid = snippet.get("channelId")
                    if cid in channel_map:
                        snippet["channelImage"] = channel_map[cid]
            else:
                logger.error("Error fetching channel images: %s", channels_response.text)
                # Proceed without channel images if the channels API call fails

        logger.info("Successfully retrieved playlists for user: %s", user_email)
        return jsonify(playlists_data), 200

    except Exception as e:
        logger.error("Exception occurred while fetching playlists: %s", e)
        return jsonify({"error": "An error occurred while fetching playlists."}), 500

@youtubeMusic_bp.route("/fetch_first_video_id", methods=["POST"])
def fetch_first_video_id():
    try:
        payload = PlaylistItemsRequest.parse_obj(request.get_json())
    except ValidationError as ve:
        return jsonify({"error": ve.errors()}), 400

    user_email = payload.user_email
    playlist_id = payload.playlist_id
    if not user_email:
        return jsonify({"error": "Missing user_email parameter."}), 400

    try:
        # Retrieve the user ID from Firebase based on the email
        user_id = firebase_operations.get_user_id_by_email(user_email)
        if not user_id:
            return jsonify({"error": "User not found."}), 404

        # Retrieve the YouTube Music app ID (assumed to be 3 for YouTube Music)
        app_id = 3
        if not app_id:
            return jsonify({"error": "YouTube Music app not configured."}), 400

        # Retrieve stored token details for the user
        result = firebase_operations.get_userlinkedapps_access_refresh(user_id, app_id)[0]
        access_token, refresh_token = result["access_token"], result["refresh_token"]
        print(access_token)
        print(refresh_token)
        
        # Refresh the access token if needed
        new_access_token = refresh_access_token_and_update_db_for_Google(user_id, refresh_token)
        if not new_access_token or not new_access_token[0]:
            return jsonify({"error": "No token found. Please bind your YouTube Music account first."}), 400

        access_token = new_access_token
        print(access_token, "Access")
        
    except Exception as e:
        logger.error("Exception occurred while fetching playlists: %s", e)
        return jsonify({"error": "An error occurred while fetching playlists."}), 500
    
    if not playlist_id:
        return jsonify({"error": "Missing playlistId parameter"}), 400

    url = "https://www.googleapis.com/youtube/v3/playlistItems"
    params = {
        "part": "snippet",
        "playlistId": playlist_id,
        "maxResults": "1",
        "client_id": settings.google_client_id,
        }
    headers = {
        "Authorization": f"Bearer {access_token}"
    }
        
    try:
        response = requests.get(url, headers=headers, params=params)
        if response.status_code == 200:
            data = response.json()
            if data and "items" in data and len(data["items"]) > 0:
                video_id = data["items"][0]["snippet"]["resourceId"]["videoId"]
                return jsonify({"videoId": video_id}), 200
            else:
                return jsonify({"error": "No items found in playlist"}), 404
        else:
            return jsonify({"error": response.json()}), response.status_code
    except Exception as e:
        logging.error("Error fetching first video id: %s", e)
        return jsonify({"error": str(e)}), 500