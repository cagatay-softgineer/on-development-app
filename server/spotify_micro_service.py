from flask import Blueprint, request, jsonify
from utils import make_request
from error_handling import log_error
from dotenv import load_dotenv
import os
import logging
from cmd_gui_kit import CmdGUI
import sys

# Initialize CmdGUI for visual feedback
gui = CmdGUI()

load_dotenv()

LOG_FILE = "logs/spotifymicroservice.log"
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

load_dotenv()

DEBUG_MODE = os.getenv("DEBUG_MODE")
if DEBUG_MODE == "True":
    DEBUG_MODE = True
    

@SpotifyMicroService_bp.route("/playlist_duration", methods=["POST","GET"])
def get_playlist_duration():
    """
    Returns the total duration of the specified playlist directly from the Spotify API.
    Example usage: GET /playlist_duration?playlist_id=123
    """
    # Extract playlist ID from request
    data = request.json
    playlist_id = data.get('playlist_id')
    if not playlist_id:
        return jsonify({"error": "Missing playlist_id"}), 400

    # Fetch playlist tracks from Spotify API
    url_template = "https://api.spotify.com/v1/playlists/{playlist_id}/tracks?limit=50&offset={offset}"
    offset = 0
    total_duration_ms = 0

    try:
        while True:
            # Request tracks in batches
            url = url_template.format(playlist_id=playlist_id, offset=offset)
            response = make_request(url)

            if not response or response.status_code != 200:
                logger.error(f"Failed to fetch playlist tracks. Response: {response.text if response else 'None'}")
                return jsonify({"error": "Failed to fetch playlist tracks"}), 500

            # Parse response
            data = response.json()
            items = data.get('items', [])
            if not items:
                break  # No more tracks to process

            # Sum the duration of all tracks in the current batch
            for item in items:
                track = item.get('track')
                if track and 'duration_ms' in track:
                    total_duration_ms += track['duration_ms']

            # Check if there are more tracks
            if len(items) < 50:
                break  # No more tracks to fetch
            offset += 50

        # Convert total duration to hours, minutes, and seconds
        total_seconds = total_duration_ms // 1000
        hours = total_seconds // 3600
        minutes = (total_seconds % 3600) // 60
        seconds = total_seconds % 60
        formatted_duration = f"{hours:02}:{minutes:02}:{seconds:02}"

        return jsonify({
            "playlist_id": playlist_id,
            "total_duration_ms": total_duration_ms,
            "formatted_duration": formatted_duration
        }), 200

    except Exception as e:
        log_error(e)
        logger.error(f"Error occurred while fetching playlist duration: {str(e)}")
        return jsonify({"error": "An internal error occurred"}), 500