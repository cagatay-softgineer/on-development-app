from flask import Blueprint, request, jsonify
from utils import get_db_connection, execute_query_with_logging
from error_handling import log_error
from dotenv import load_dotenv
import os
import logging
from cmd_gui_kit import CmdGUI
from SpotifyMicroService.playlist_operations import handle_playlist
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
spotify_bp = Blueprint('api', __name__)

# Check if '--debug' is passed as a command-line argument
DEBUG_MODE = '--debug' in sys.argv
WARNING_MODE = '--warning' in sys.argv
ERROR_MODE = '--error' in sys.argv

load_dotenv()

DEBUG_MODE = os.getenv("DEBUG_MODE")
if DEBUG_MODE == "True":
    DEBUG_MODE = True

# Function to process playlist data
def process_playlist_data(playlist_id, conn, cursor, debug_mode=DEBUG_MODE, warning_mode=WARNING_MODE, error_mode=ERROR_MODE):
    try:

        if debug_mode:
            gui.log(f"Handling playlist: {playlist_id}", level="info")
            logger.info(f"Handling playlist: {playlist_id}")
        try:
            handle_playlist(playlist_id, cursor, conn)
        except AttributeError as e:
            log_error(e)
            # Continue to the next playlist even if an error occurred

    except Exception as e:
        log_error(e) ### GeneralError

# Main function
def main(playlist_id, debug_mode=DEBUG_MODE, warning_mode=WARNING_MODE, error_mode=ERROR_MODE):
    # Connect to SQL Server
    conn = get_db_connection("secondary")
    cursor = conn.cursor()
    if debug_mode:
        gui.log("Connected to the database successfully.", level="info")
        logger.info("Connected to the database successfully.")

    process_playlist_data(playlist_id, conn, cursor)

    # Close the database connection
    cursor.close()
    conn.close()
    

@spotify_bp.route("/playlist_duration", methods=["POST","GET"])
def get_playlist_duration():
    """
    Returns the total duration of the specified playlist.
    Example usage: GET /spotify/playlist_duration?playlist_id=123
    """
    data = request.json
    playlist_id = data.get('playlist_id')
    if not playlist_id:
        return jsonify({"error": "Missing playlist_id"}), 400
    
    main(playlist_id)
    
    query = """
        SELECT SUM(t.duration_ms) AS total_duration_ms
        FROM Playlist_Tracks pt
        JOIN Tracks t ON pt.track_id = t.track_id
        WHERE pt.playlist_id = ?
    """
    
    try:
        # Execute query with parameter
        result, description = execute_query_with_logging(query, "secondary", params=(playlist_id,), fetch=True)
        if not result:
            # If no rows returned, the playlist might be empty or not exist
            return jsonify({"playlist_id": playlist_id, "total_duration_ms": 0}), 200

        # Extract the total duration from the first row
        total_duration_ms = result[0][0] if result[0][0] is not None else 0
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
        return jsonify({"error": "An internal error has occurred!"}), 500