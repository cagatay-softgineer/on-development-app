import requests
import base64
import time
import json
import os
from threading import Lock
import sys
from error_handling import log_error
from dotenv import load_dotenv
from cmd_gui_kit import CmdGUI
import logging

# Check if '--debug' is passed as a command-line argument
DEBUG_MODE = '--debug' in sys.argv
WARNING_MODE = '--warning' in sys.argv
ERROR_MODE = '--error' in sys.argv

# Setup logging
LOG_FILE = "logs/token_cred.log"

# Create a logger
logger = logging.getLogger("Token_CRED")
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

load_dotenv()

SPOTIFY_CLIENT_ID = os.getenv("SPOTIFY_CLIENT_ID")
SPOTIFY_CLIENT_SECRET = os.getenv("SPOTIFY_CLIENT_SECRET")

DEBUG_MODE = os.getenv("DEBUG_MODE")
if DEBUG_MODE == "True":
    DEBUG_MODE = True

CLIENT_ID = os.getenv("SPOTIFY_CLIENT_ID")
CLIENT_SECRET = os.getenv("SPOTIFY_CLIENT_SECRET")
api_commands_str = os.getenv("API_COMMANDS")

CREDENTIALS = [{"client_id":CLIENT_ID,"client_secret":CLIENT_SECRET}]

# Load API_COMMANDS from JSON string
if api_commands_str:
    API_COMMANDS = json.loads(api_commands_str)
else:
    API_COMMANDS = {}

token_cache = {
    "access_token": None
}
lock = Lock()

# ----------------------------------------------------------------------
# GET ACCESS TOKEN (SINGLE CREDENTIAL)
# ----------------------------------------------------------------------
def get_access_token_for_request(debug_mode=DEBUG_MODE, warning_mode=WARNING_MODE, error_mode=ERROR_MODE):
    """
    Requests an access token using a single Spotify client credential
    and caches it globally. Returns the cached token if it already exists.
    """
    # If we already have a cached token, just return it
    if token_cache["access_token"]:
        if debug_mode:
            gui.log("Using cached Spotify access token", level="info")
            logger.info("Using cached Spotify access token")
        return token_cache["access_token"]

    # Otherwise, request a new token from Spotify
    if debug_mode:
        gui.log("Requesting new Spotify access token", level="info")
        logger.info("Requesting new Spotify access token")

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

        # Cache the token
        token_cache["access_token"] = access_token

        if debug_mode:
            gui.log("Successfully obtained new Spotify access token", level="info")
            logger.info("Successfully obtained new Spotify access token")

        return access_token
    else:
        if error_mode:
            gui.status(
                f"Failed to obtain token. Status code: {response.status_code}",
                status="error",
            )
            logger.error(
                f"Failed to obtain token. Status code: {response.status_code}"
            )
        # Optionally raise an exception or return None
        raise log_error(Exception("Could not obtain Spotify access token"))


def make_request(
    url,
    max_retries=5,
    debug_mode=DEBUG_MODE,
    warning_mode=WARNING_MODE,
    error_mode=ERROR_MODE,
):
    """
    Makes a GET request to a specified URL with retry logic for rate limiting.
    Uses a single Spotify credential for all requests.
    """
    access_token = get_access_token_for_request(debug_mode, warning_mode, error_mode)
    headers = {"Authorization": f"Bearer {access_token}"}

    for attempt in range(max_retries):
        response = requests.get(url, headers=headers)

        if response.status_code == 200:
            return response

        elif response.status_code == 404:
            # Resource not found
            if debug_mode or warning_mode:
                msg = f"Resource not found: {url}"
                gui.log(msg, level="info")
                logger.info(msg)
            return None

        elif response.status_code == 429:
            # Rate limit exceeded
            retry_after = int(response.headers.get("Retry-After", 1))
            if debug_mode or warning_mode:
                msg = f"Rate limit exceeded. Waiting {retry_after} seconds before retrying."
                gui.log(msg, level="info")
                logger.info(msg)
            time.sleep(retry_after)

            # Optionally refresh the token (in case it helps)
            access_token = get_access_token_for_request(debug_mode, warning_mode, error_mode)
            headers["Authorization"] = f"Bearer {access_token}"

        else:
            # For other 4xx/5xx errors, raise an exception or handle
            response.raise_for_status()

    if debug_mode or error_mode:
        gui.status("Failed to fetch data after retries.", status="error")
        logger.error("Failed to fetch data after retries.")
    return None

# Example usage
# Replace 'API_COMMANDS' with your actual API command dictionary
# make_request(API_COMMANDS["Get Playlists"], "Get Playlists")
