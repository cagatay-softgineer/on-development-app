import logging
import os
from error_handling import log_error
from cmd_gui_kit import CmdGUI
import requests
import base64
from datetime import datetime
import hashlib
import pandas as pd
from config import settings
import firebase_operations

# Initialize CmdGUI for visual feedback
gui = CmdGUI()

# Logging setup
LOG_DIR = "logs/utils.log"
logger = logging.getLogger("Utils")
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

SPOTIFY_CLIENT_ID = settings.spotify_client_id
SPOTIFY_CLIENT_SECRET = settings.spotify_client_secret

def obfuscate(column_name: str) -> str:
    salt = settings.salt  # Replace with your own secret salt value.
    hash_value = hashlib.sha256((salt + column_name).encode('utf-8')).hexdigest()
    return f"{hash_value[:12].upper()}"

def get_access_token_for_request():
    """
    Requests an access token using a single Spotify client credential
    and caches it globally. Returns the cached token if it already exists.
    """

    client_creds_b64 = base64.b64encode(f"{SPOTIFY_CLIENT_ID}:{SPOTIFY_CLIENT_SECRET}".encode()).decode()

    token_url = "https://accounts.spotify.com/api/token"
    token_data = {"grant_type": "client_credentials"}
    token_headers = {
        "Authorization": f"Basic {client_creds_b64}",
        "Content-Type": "application/x-www-form-urlencoded",
    }

    response = requests.post(token_url, data=token_data, headers=token_headers)

    if response.status_code == 200:
        response_data = response.json()
        access_token = response_data["access_token"]

        return access_token
    else:
    
        gui.status(
            f"Failed to obtain token. Status code: {response.status_code}",
            status="error",
        )
        logger.error(
            f"Failed to obtain token. Status code: {response.status_code}"
        )
        # Optionally raise an exception or return None
        raise log_error(Exception("Could not obtain Spotify access token"))

def get_email_username(email):
    """
    Extracts and returns the part of an email address before the '@' symbol.
    
    Parameters:
        email (str): The email address.
    
    Returns:
        str: The part of the email before the '@'. Returns None if '@' is not found.
    """
    if "@" in email:
        return email.split("@")[0]
    else:
        return None


def make_request(
    url,
    max_retries=5,
    access_token=None
):
    """
    Makes a GET request to a specified URL with retry logic for rate limiting.
    Uses a single Spotify credential for all requests.
    """
    if access_token is None:
        access_token = get_access_token_for_request()
        
    headers = {"Authorization": f"Bearer {access_token}"}

    for attempt in range(max_retries):
        response = requests.get(url, headers=headers)

        if response.status_code == 200:
            return response

        elif response.status_code == 404:
            # Resource not found
        
            msg = f"Resource not found: {url}"
            gui.log(msg, level="info")
            logger.info(msg)
            return None

        elif response.status_code == 429:
            # Rate limit exceeded
            retry_after = int(response.headers.get("Retry-After", 1))
            
            msg = f"Rate limit exceeded. Waiting {retry_after} seconds before retrying."
            gui.log(msg, level="info")
            logger.info(msg)

            # Optionally refresh the token (in case it helps)
            access_token = get_access_token_for_request()
            headers["Authorization"] = f"Bearer {access_token}"

        else:
            # For other 4xx/5xx errors, raise an exception or handle
            response.raise_for_status()


    gui.status("Failed to fetch data after retries.", status="error")
    logger.error("Failed to fetch data after retries.")
    return None
            
def get_access_token():  # noqa: F811
    # Request a new access token for this client ID
    client_creds_b64 = base64.b64encode(f"{SPOTIFY_CLIENT_ID}:{SPOTIFY_CLIENT_SECRET}".encode()).decode()
    token_url = "https://accounts.spotify.com/api/token"
    token_data = {"grant_type": "client_credentials"}
    token_headers = {
        "Authorization": f"Basic {client_creds_b64}",
        "Content-Type": "application/x-www-form-urlencoded",
    }
    
    response = requests.post(token_url, data=token_data, headers=token_headers)
    
    if response.status_code == 200:
        response_data = response.json()
        access_token = response_data["access_token"]

        return access_token, 200
    
    elif response.status_code == 429:
        return "", 429
    else:
        return "", 404

def get_access_token_from_db(user_id, app_id):
    
    result = firebase_operations.get_userlinkedapps_access_refresh(user_id, app_id)[0]
    if not result:
        logger.error(f"Access token not found for user_id: {user_id}")
        return None

    access_token, refresh_token = result["access_token"], result["refresh_token"]
    if test_token(access_token) != 200:
        refresh_access_token_and_update_db(user_id, refresh_token, app_id)
        get_access_token_from_db(user_id, app_id)
        
    return access_token, refresh_token

def test_token(access_token):
    url = "https://api.spotify.com/v1/me"
    headers = {"Authorization": f"Bearer {access_token}"}
    response = requests.get(url, headers=headers)

    return response.status_code

# Function to fetch playlists of the user
def fetch_user_playlists(user_id, app_id):
    # Query to get the access token for the user
    access_token, refresh_token = get_access_token_from_db(user_id, app_id)
    #print(get_current_user_profile(access_token))
    #print(access_token)
    #print(refresh_token)

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
                "playlist_owner": item["owner"]["display_name"],
                "playlist_owner_id": item["owner"]["id"],
                "playlist_track_count": item["tracks"]["total"],
                "tracks": [],
            }
            formatted_playlists.append(formatted_playlist)

        logger.info("Successfully fetched and formatted playlists.")
        return formatted_playlists
    elif response.status_code == 401:
        refresh_access_token_and_update_db(user_id, refresh_token, app_id)
        return fetch_user_playlists(user_id, app_id)
    else:
        logger.error(f"Failed to fetch playlists: {response.status_code} - {response.text}")
        return None


# Function to refresh access token
def refresh_access_token_and_update_db(user_id, refresh_token, app_id):
    url = "https://accounts.spotify.com/api/token"
    auth_header = base64.b64encode(f"{SPOTIFY_CLIENT_ID}:{SPOTIFY_CLIENT_SECRET}".encode()).decode()

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
        firebase_operations.update_userlinkedapps_tokens(new_access_token, new_refresh_token, expires_in, user_id, app_id)
        return new_access_token
    else:
        logger.error(f"Failed to refresh access token: {response.status_code} - {response.text}")
        return None

def get_current_user_profile(access_token, user_id, app_id):
    url = "https://api.spotify.com/v1/me"
    headers = {"Authorization": f"Bearer {access_token}"}
    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        #user = response.json()
        #print(user["id"])
        return response.json()
    elif response.status_code == 401:
        result = firebase_operations.get_userlinkedapps_access_refresh(user_id, app_id)[0]
        access_token, refresh_token = result["access_token"], result["refresh_token"]
        refresh_access_token_and_update_db(user_id, refresh_token, app_id)
        return get_current_user_profile(access_token, user_id, app_id)
    else:
        logger.error(f"Failed to fetch user profile: {response.status_code} - {response.text}")
        return None
    
    
def get_user_profile(user_id):
    access_token, status_code = get_access_token()
    if status_code == 200:
        url = f"https://api.spotify.com/v1/users/{user_id}"
        headers = {"Authorization": f"Bearer {access_token}"}
        response = requests.get(url, headers=headers)

        if response.status_code == 200:
            #user = response.json()
            #print(user["id"])
            return response.json()
        else:
            logger.error(f"Failed to fetch user profile: {response.status_code} - {response.text}")
            return None
    else:
        logger.error(f"Failed to fetch user's access token: {status_code}")
        return None
    
route_descriptions = {
    "/.well-known/assetlinks.json": "Provides asset links for verifying app association with a domain.",
    "/api/docs/": "Swagger UI documentation root for API endpoints.",
    "/api/docs/<path:path>": "Serves specific Swagger UI documentation files based on the given path.",
    "/api/docs/dist/<path:filename>": "Static assets for the Swagger UI, such as JavaScript and CSS files.",
    "/apps/check_linked_app": "Checks if a specific app is linked to the current user or account.",
    "/apps/healthcheck": "Health check endpoint for the apps service to verify it's running correctly.",
    "/apps/unlink_app": "Unlinks a previously linked app from the current user or account.",
    "/auth/healthcheck": "Health check endpoint for the authentication service to verify functionality.",
    "/auth/login": "Handles user login requests with necessary credentials.",
    "/auth/register": "Handles user registration by creating a new account.",
    "/endpoints": "Lists all available endpoints in the application.",
    "/error_stats": "Displays error statistics for the application, such as error logs or counts.",
    "/healthcheck": "General health check endpoint for the main application.",
    "/profile/healthcheck": "Health check endpoint for the profile service to ensure it's operational.",
    "/profile/view": "Displays the profile of the current user.",
    "/spotify-micro-service/healthcheck": "Health check endpoint for the Spotify microservice.",
    "/spotify-micro-service/playlist_duration": "Calculates the total duration of a playlist using the Spotify microservice.",
    "/spotify/callback": "Callback endpoint for Spotify's OAuth process to handle token redirection.",
    "/spotify/healthcheck": "Health check endpoint for the Spotify service integration.",
    "/spotify/login/<user_id>": "Logs in a specific Spotify user by their user ID.",
    "/spotify/playlists": "Retrieves playlists associated with the logged-in Spotify user.",
    "/spotify/token": "Handles token requests for Spotify API authentication.",
    "/spotify/user_profile": "Retrieves profile information of the logged-in Spotify user."
}

def parse_logs_from_folder(folder_path):
    logs = []
    for filename in os.listdir(folder_path):
        file_path = os.path.join(folder_path, filename)
        if os.path.isfile(file_path) and filename.endswith('.log'):  # Assuming log files are .txt
            with open(file_path, 'r') as file:
                for line in file:
                    try:
                        parts = line.split(" - ")
                        timestamp = parts[0].strip()
                        log_type = parts[2].strip()
                        message = " - ".join(parts[3:]).strip()
                        
                        # Append parsed log data
                        logs.append({
                            "filename": filename,
                            "timestamp": datetime.strptime(timestamp, '%Y-%m-%d %H:%M:%S,%f'),  # Parse timestamp
                            "log_type": log_type,
                            "message": message
                        })
                    except (IndexError, ValueError):
                        continue
    
    # Sort logs by timestamp (descending order)
    logs.sort(key=lambda log: log['timestamp'], reverse=True)
    return logs

ACCEPTED_LOG_TYPES = {"INFO", "DEBUG", "WARN", "ERROR"}

# Helper function to parse logs and return a DataFrame
def parse_logs_to_dataframe(folder_path):
    data = []
    for filename in os.listdir(folder_path):
        file_path = os.path.join(folder_path, filename)
        if os.path.isfile(file_path) and filename.endswith('.log'):
            with open(file_path, 'r') as file:
                for line in file:
                    try:
                        parts = line.split(" - ")
                        timestamp = datetime.strptime(parts[0].strip(), '%Y-%m-%d %H:%M:%S,%f')
                        log_type = parts[2].strip().upper()  # Convert to uppercase for consistency
                        # Validate log type
                        if log_type in ACCEPTED_LOG_TYPES:
                            data.append({'timestamp': timestamp, 'log_type': log_type})
                    except (IndexError, ValueError):
                        continue
    # Create a DataFrame from the parsed data
    df = pd.DataFrame(data)
    return df