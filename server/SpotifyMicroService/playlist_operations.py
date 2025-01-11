from SpotifyMicroService.token_cred import make_request
from SpotifyMicroService.db_operations import check_and_insert_playlist, check_and_insert_track, fetch_and_insert_audio_features
from SpotifyMicroService.fetch_playlist_image import fetch_and_insert_playlist_images 
import sys
from cmd_gui_kit import CmdGUI
import logging
from dotenv import load_dotenv
import os

# Setup logging
LOG_FILE = "logs/playlist_operations.log"

# Create a logger
logger = logging.getLogger("Playlist_Operations")
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

load_dotenv()

gui = CmdGUI()

# Check if '--debug' is passed as a command-line argument
DEBUG_MODE = '--debug' in sys.argv
WARNING_MODE = '--warning' in sys.argv
ERROR_MODE = '--error' in sys.argv


DEBUG_MODE = os.getenv("DEBUG_MODE")
if DEBUG_MODE == "True":
    DEBUG_MODE = True

            
def handle_playlist(playlist_id, cursor, conn, debug_mode=DEBUG_MODE, warning_mode=WARNING_MODE, error_mode=ERROR_MODE):
    """
    Retrieves tracks for a specific playlist and processes each track.

    Args:
        playlist_id (str): The Spotify playlist ID.
        cursor (pyodbc.Cursor): Database cursor for executing SQL queries.
        conn (pyodbc.Connection): Database connection to commit transactions.
        debug_mode (bool): If True, print debug information.
        warning_mode (bool): If True, print warning information.
        error_mode (bool): If True, print error information.
    """
    # Buffer to hold track IDs for batch processing
    track_buffer = []

    # Use the request type "Get Playlist" for token management
    if debug_mode:
        gui.log(f"Fetching tracks for playlist ID: {playlist_id}", level="info")
        logger.info(f"Fetching tracks for playlist ID: {playlist_id}")

    # Insert playlist and associate with user
    check_and_insert_playlist(playlist_id, cursor, conn)

    cursor.execute("SELECT images FROM Playlists WHERE playlist_id = ?", (playlist_id,))
    result = cursor.fetchone()
    if result and result[0]:
        if debug_mode:
            gui.log(f"Images already exist for playlist {playlist_id}. Skipping image fetch.", level="info")
            logger.info(f"Images already exist for playlist {playlist_id}. Skipping image fetch.")
    else:
        # Fetch and insert images for the playlist
        fetch_and_insert_playlist_images(playlist_id, cursor, conn, debug_mode, warning_mode, error_mode)
    
    # Fetch tracks for the given playlist ID
    tracks_url = f"https://api.spotify.com/v1/playlists/{playlist_id}/tracks"
    tracks_response = make_request(tracks_url)

    if tracks_response is None:
        if debug_mode or error_mode:
            gui.status(f"No data received for playlist ID {playlist_id}.", status="error")
            logger.error(f"No data received for playlist ID {playlist_id}.")
        return  # Skip processing if there's no data

    if tracks_response and tracks_response.status_code == 200:
        tracks_data = tracks_response.json()

        if debug_mode:
            gui.log(f"Processing tracks for playlist ID: {playlist_id}", level="info")
            logger.info(f"Processing tracks for playlist ID: {playlist_id}")

        for track_item in tracks_data["items"]:
            if not track_item or 'track' not in track_item or track_item['track'] is None:
                if warning_mode:
                    gui.log(f"Skipping invalid track data in playlist {playlist_id}.", level="warn")
                    logger.info(f"Skipping invalid track data in playlist {playlist_id}.")
                continue  # Skip invalid or unavailable track data

            # Pass the playlist ID and track_buffer to check_and_insert_track
            check_and_insert_track(track_item, playlist_id, None, cursor, conn, track_buffer, debug_mode=debug_mode)

        # After processing all tracks, ensure remaining tracks in buffer are processed
        if track_buffer:
            fetch_and_insert_audio_features(track_buffer, None, cursor, conn, debug_mode)
            track_buffer.clear()  # Clear the buffer after processing

        if debug_mode:
            gui.log(f"Finished processing tracks for playlist ID: {playlist_id}", level="info")
            logger.info(f"Finished processing tracks for playlist ID: {playlist_id}")
    else:
        if debug_mode or error_mode:
            gui.status(f"Failed to fetch tracks for playlist ID {playlist_id}. Status Code: {tracks_response.status_code}", status="error")
            logger.error(f"Failed to fetch tracks for playlist ID {playlist_id}. Status Code: {tracks_response.status_code}")
            if tracks_response:
                gui.status(f"Response: {tracks_response.text}", status="error")                
                logger.error(f"Response: {tracks_response.text}")