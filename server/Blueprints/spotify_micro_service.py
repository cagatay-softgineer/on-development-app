from flask import Blueprint, request, jsonify
from util.utils import make_request, get_access_token_from_db
from util.error_handling import log_error
from config.config import settings
from util.models import PlaylistDurationRequest  # Import the model
import database.firebase_operations as firebase_operations
from pydantic import ValidationError
from cmd_gui_kit import CmdGUI
import logging
import sys

# Initialize CmdGUI for visual feedback
gui = CmdGUI()

LOG_FILE = "logs/spotify_micro_service.log"
logger = logging.getLogger("SpotifyMicroService")
logger.setLevel(logging.DEBUG)

# Create file handler
file_handler = logging.FileHandler(LOG_FILE, encoding="utf-8")
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

# Define the Blueprint
SpotifyMicroService_bp = Blueprint('api', __name__)

# Check if '--debug' is passed as a command-line argument
DEBUG_MODE = '--debug' in sys.argv
WARNING_MODE = '--warning' in sys.argv
ERROR_MODE = '--error' in sys.argv

DEBUG_MODE = settings.debug_mode
if DEBUG_MODE == "True":
    DEBUG_MODE = True
    

@SpotifyMicroService_bp.route("/playlist_duration", methods=["POST"])
def get_playlist_duration():
    try:
        payload = PlaylistDurationRequest.parse_obj(request.get_json())
    except ValidationError as ve:
        return jsonify({"error": ve.errors()}), 400
    
    user_email = payload.user_id
    playlist_id = payload.playlist_id
    # (The remainder of the logic remains similar.)
    url_template = "https://api.spotify.com/v1/playlists/{playlist_id}/tracks?limit=50&offset={offset}"
    offset = 0
    total_duration_ms = 0
    total_track_count = 0

    try:
        while True:
            url = url_template.format(playlist_id=playlist_id, offset=offset)
            user_id = firebase_operations.get_user_id_by_email(user_email)
            
            access_token, _ = get_access_token_from_db(user_id, app_id=1)
            response = make_request(url,access_token=access_token)
            if not response or response.status_code != 200:
                logging.error(f"Failed to fetch playlist tracks. Response: {response.text if response else 'None'}")
                return jsonify({"error": "Failed to fetch playlist tracks"}), 500

            data = response.json()
            items = data.get('items', [])
            if not items:
                break

            for item in items:
                track = item.get('track')
                if track and 'duration_ms' in track:
                    total_duration_ms += track['duration_ms']
                    total_track_count += 1

            if len(items) < 50:
                break
            offset += 50

        total_seconds = total_duration_ms // 1000
        hours = total_seconds // 3600
        minutes = (total_seconds % 3600) // 60
        seconds = total_seconds % 60
        formatted_duration = f"{hours:02}:{minutes:02}:{seconds:02}"

        return jsonify({
            "playlist_id": playlist_id,
            "total_duration_ms": total_duration_ms,
            "formatted_duration": formatted_duration,
            "total_track_count": total_track_count
        }), 200

    except Exception as e:
        log_error(e)
        logging.error(f"Error occurred while fetching playlist duration: {str(e)}")
        return jsonify({"error": "An internal error occurred"}), 500