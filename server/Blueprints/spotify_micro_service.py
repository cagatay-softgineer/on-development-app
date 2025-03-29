from flask import Blueprint, request, jsonify
from util.spotify import calculate_playlist_duration
from util.error_handling import log_error
from config.config import settings
from util.models import PlaylistRequest  # Import the model
from pydantic import ValidationError
from cmd_gui_kit import CmdGUI
from util.logit import get_logger
import sys

# Initialize CmdGUI for visual feedback
gui = CmdGUI()

logger = get_logger("logs/spotify_micro_service.log", "SpotifyMicroService")

# Define the Blueprint
SpotifyMicroService_bp = Blueprint('api', __name__)

# Check if '--debug' is passed as a command-line argument
DEBUG_MODE = '--debug' in sys.argv
WARNING_MODE = '--warning' in sys.argv
ERROR_MODE = '--error' in sys.argv

DEBUG_MODE = settings.debug_mode
if DEBUG_MODE == "True":
    DEBUG_MODE = True

# Global cache for playlist durations
# Each key is a playlist_id and the value is a tuple: (result_data, expiration_time)
playlist_cache = {}
CACHE_DURATION = 3600  # Cache duration in seconds (1 hour)

@SpotifyMicroService_bp.route("/playlist_duration", methods=["POST"])
def get_playlist_duration_route():
    """
    API endpoint that returns the playlist duration and track count by using the calculate_playlist_duration method.
    """
    try:
        payload = PlaylistRequest.parse_obj(request.get_json())
    except ValidationError as ve:
        return jsonify({"error": ve.errors()}), 400

    user_email = payload.user_id
    playlist_id = payload.playlist_id

    try:
        result_data = calculate_playlist_duration(user_email, playlist_id)
        return jsonify(result_data), 200
    except Exception as e:
        log_error(e)
        logger.error(f"Error occurred while fetching playlist duration: {str(e)}")
        return jsonify({"error": "An internal error occurred"}), 500