from SpotifyMicroService.token_cred import make_request
import sys
from dateutil import parser
from cmd_gui_kit import CmdGUI
import logging
import os
from dotenv import load_dotenv

load_dotenv()

# Setup logging
LOG_FILE = "logs/db.log"

# Create a logger
logger = logging.getLogger("DB_Operations")
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

gui = CmdGUI()

# Check if '--debug' is passed as a command-line argument
DEBUG_MODE = '--debug' in sys.argv
WARNING_MODE = '--warning' in sys.argv
ERROR_MODE = '--error' in sys.argv

DEBUG_MODE = os.getenv("DEBUG_MODE")
if DEBUG_MODE == "True":
    DEBUG_MODE = True

def check_and_insert_playlist(playlist_id, cursor, conn, debug_mode=False):
    """
    Ensures the playlist with the given ID exists in the Playlists table.
    If not found, inserts it. Then commits.
    """
    # 1) Check if playlist already exists
    cursor.execute("SELECT playlist_id FROM Playlists WHERE playlist_id = ?", (playlist_id,))
    row = cursor.fetchone()
    
    if row:
        # Already in the DB, so nothing to do
        if debug_mode:
            gui.log(f"Playlist {playlist_id} already exists.", level="info")
            logger.info(f"Playlist {playlist_id} already exists.")
    else:
        # 2) If missing, insert a minimal row (adjust columns as needed)
        insert_sql = """
            INSERT INTO Playlists (playlist_id, name, description, images)
            VALUES (?, ?, ?, ?)
        """
        # Provide some default or placeholder values if you don’t have them yet
        cursor.execute(insert_sql, (playlist_id, f"Playlist {playlist_id}", None, None))
        
        if debug_mode:
            gui.log(f"Inserted new playlist {playlist_id} into Playlists.", level="info")
            logger.info(f"Inserted new playlist {playlist_id} into Playlists.")
    
    # 3) IMPORTANT: Commit the transaction so the row is definitely visible
    conn.commit()
                    
def fetch_and_insert_audio_features(track_ids, headers, cursor, conn, debug_mode=DEBUG_MODE, warning_mode=WARNING_MODE, error_mode=ERROR_MODE):
    """
    Fetches audio features for up to 100 track IDs in one request and inserts them into the database.

    Args:
        track_ids (list): List of track IDs to fetch audio features for.
        headers (dict): Authorization headers for Spotify API.
        cursor (pyodbc.Cursor): Database cursor for executing SQL queries.
        conn (pyodbc.Connection): Database connection to commit transactions.
        debug_mode (bool): If True, print debug information.
    """
    if not track_ids:
        if debug_mode:
            gui.log("No track IDs to process.", level="info")
            logger.info("No track IDs to process.")
        return  # No track IDs to process

    # Make a request for audio features in bulk (up to 100 track IDs)
    track_ids_string = ",".join(track_ids)
    audio_features_url = f"https://api.spotify.com/v1/audio-features?ids={track_ids_string}"

    if debug_mode:
        gui.log(f"Requesting audio features for {len(track_ids)} track IDs.", level="info")
        logger.info(f"Requesting audio features for {len(track_ids)} track IDs.")
        gui.log(f"Request URL: {audio_features_url}", level="info")
        logger.info(f"Request URL: {audio_features_url}")

    response = make_request(audio_features_url, "Get Audio Features Batch")

    if response:
        if response.status_code == 200:
            audio_features_list = response.json().get("audio_features", [])
            if debug_mode:
                gui.log(f"Received audio features for {len(audio_features_list)} tracks.", level="info")
                logger.info(f"Received audio features for {len(audio_features_list)} tracks.")

            for audio_features_data in audio_features_list:
                if audio_features_data:  # Ensure data is not None
                    track_id = audio_features_data.get("id")
                    if debug_mode:
                        gui.log(f"Inserting audio features for track ID: {track_id}", level="info")
                        logger.info(f"Inserting audio features for track ID: {track_id}")
                    cursor.execute("""
                    INSERT INTO Audio_Features (track_id, acousticness, danceability, energy, instrumentalness, liveness, loudness, speechiness, valence, tempo, track_key, mode, time_signature)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, track_id, audio_features_data.get("acousticness"), audio_features_data.get("danceability"),
                    audio_features_data.get("energy"), audio_features_data.get("instrumentalness"),
                    audio_features_data.get("liveness"), audio_features_data.get("loudness"),
                    audio_features_data.get("speechiness"), audio_features_data.get("valence"),
                    audio_features_data.get("tempo"), audio_features_data.get("key"),
                    audio_features_data.get("mode"), audio_features_data.get("time_signature"))
            conn.commit()
            if debug_mode:
                gui.log(f"Committed audio features for batch of {len(track_ids)} tracks.", level="info")
                logger.info(f"Committed audio features for batch of {len(track_ids)} tracks.")
        else:
            if debug_mode or error_mode:
                gui.status(f"Failed to fetch audio features. Status Code: {response.status_code}", status="error")
                logger.error(f"Failed to fetch audio features. Status Code: {response.status_code}")
                gui.status(f"Response: {response.text}", status="error")
                logger.error(f"Response: {response.text}")
    else:
        if debug_mode or error_mode:
            gui.status("No response received for the request.", status="error")
            logger.error("No response received for the request.")

def check_and_insert_track(track_item, playlist_id, headers, cursor, conn, track_buffer, max_buffer_size=100, debug_mode=DEBUG_MODE, warning_mode=WARNING_MODE, error_mode=ERROR_MODE):
    if not track_item or 'track' not in track_item or track_item['track'] is None:
        if debug_mode or warning_mode:
            gui.log("Track data is None or unavailable, skipping this track.", level="warn")
            logger.info("Track data is None or unavailable, skipping this track.")
        return  # Skip if the track data is invalid

    track_info = track_item["track"]
    track_id = track_info.get("id")
    album_info = track_info.get("album", {})
    album_id = album_info.get("id")

    if not track_id:
        if debug_mode or warning_mode:
            gui.log("Track ID is missing, skipping.", level="warn")
            logger.info("Track ID is missing, skipping.")
        return  # Skip tracks with no valid ID

    if not album_id:
        if debug_mode or warning_mode:
            gui.log(f"Skipping track {track_id} due to missing album_id.", level="warn")
            logger.info(f"Skipping track {track_id} due to missing album_id.")
        return  # Skip this track if album_id is missing

    # Insert album into Albums table if not exists
    cursor.execute("SELECT 1 FROM Albums WHERE album_id = ?", (album_id,))
    if cursor.fetchone() is None:
        release_date = album_info.get("release_date", None)
        parsed_date = None
        if release_date:
            try:
                parsed_date = parser.parse(release_date).strftime('%Y-%m-%d')
            except ValueError:
                if debug_mode or warning_mode:
                    gui.log(f"Invalid release date format for album {album_id}.", level="warn")
                    logger.info(f"Invalid release date format for album {album_id}.")
        
        cursor.execute("""
        INSERT INTO Albums (album_id, name, release_date, total_tracks, album_type, album_href, uri)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """, album_id, album_info.get("name"), parsed_date,
        album_info.get("total_tracks", 0), album_info.get("album_type", ""),
        album_info.get("href", ""), album_info.get("uri", ""))
        conn.commit()  # Commit the album insertion to ensure it is visible

    # Insert track into Tracks table if not exists
    cursor.execute("SELECT 1 FROM Tracks WHERE track_id = ?", (track_id,))
    if cursor.fetchone() is None:
        cursor.execute("""
        INSERT INTO Tracks (track_id, name, album_id, duration_ms, explicit, popularity, preview_url, track_href, uri)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, track_id, track_info.get("name"), album_id,
        track_info.get("duration_ms"), int(track_info.get("explicit", 0)),
        track_info.get("popularity", 0), track_info.get("preview_url"),
        track_info.get("href"), track_info.get("uri"))
        conn.commit()  # Commit the track insertion

    # Associate playlist with track in Playlist_Tracks table using provided playlist_id
    cursor.execute("SELECT 1 FROM Playlist_Tracks WHERE playlist_id = ? AND track_id = ?", (playlist_id, track_id))
    if cursor.fetchone() is None:
        cursor.execute("""
        INSERT INTO Playlist_Tracks (playlist_id, track_id, added_at)
        VALUES (?, ?, ?)
        """, playlist_id, track_id, track_item["added_at"])
        conn.commit()  # Commit the association