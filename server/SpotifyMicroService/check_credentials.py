import requests
import base64
import time
import json
from datetime import datetime
from dotenv import load_dotenv
import os
import logging
from cmd_gui_kit import CmdGUI  # Import CmdGUI for visual feedback

# Initialize CmdGUI
gui = CmdGUI()

# Configure logging
LOG_FILE = "logs/spotify_api.log"
logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE, encoding="utf-8"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("Check_credentials")

logger.propagate = False

load_dotenv()

SPOTIFY_TOKEN = os.getenv("SPOTIFY_TOKEN")
USER_ID = os.getenv("USER_ID")
TRACK_ID = os.getenv("TRACK_ID")
PLAYLIST_ID = os.getenv("PLAYLIST_ID")
ALBUM_ID = os.getenv("ALBUM_ID")
ARTISTS_ID = os.getenv("ARTISTS_ID")

credentials_str = os.getenv("CREDENTIALS")
api_commands_str = os.getenv("API_COMMANDS")

# Load CREDENTIALS from JSON string
CREDENTIALS = []

# Load API_COMMANDS from JSON string
if api_commands_str:
    API_COMMANDS = json.loads(api_commands_str)
else:
    API_COMMANDS = {}

formatted_api_commands = {key: value.format(
    USER_ID=USER_ID,
    TRACK_ID=TRACK_ID,
    PLAYLIST_ID=PLAYLIST_ID,
    ALBUM_ID=ALBUM_ID,
    ARTISTS_ID=ARTISTS_ID
) for key, value in API_COMMANDS.items()}

def get_access_token(client_id, client_secret, gui):
    client_creds_b64 = base64.b64encode(f"{client_id}:{client_secret}".encode()).decode()
    token_url = "https://accounts.spotify.com/api/token"
    token_data = {"grant_type": "client_credentials"}
    token_headers = {
        "Authorization": f"Basic {client_creds_b64}",
        "Content-Type": "application/x-www-form-urlencoded",
    }

    gui.spinner(duration=2, message="Requesting access token...")
    logger.debug("Requesting access token.")

    response = requests.post(token_url, data=token_data, headers=token_headers)
    if response.status_code == 200:
        logger.info("Access token successfully retrieved.")
        return response.json()["access_token"]
    elif response.status_code == 429:
        retry_after = int(response.headers.get("Retry-After", 1))
        retry_time = datetime.utcfromtimestamp(time.time() + retry_after).strftime('%Y-%m-%d %H:%M:%S')
        logger.warning(f"Rate-limited. Retry at {retry_time}.")
        return f"Rate-Limited; Retry at {retry_time}"
    else:
        logger.error(f"Error retrieving access token: {response.status_code}")
        return f"Error: {response.status_code}"

def check_api_status(access_token, commands, max_retries=1, gui=None):
    headers = {"Authorization": f"Bearer {access_token}"}
    status_results = {}

    for command, url in commands.items():
        retries = 0
        while retries < max_retries:
            test_url = url.replace("{track_id}", TRACK_ID) if "{track_id}" in url else url
            response = requests.get(test_url, headers=headers)

            if response.status_code == 200:
                status_results[command] = "Active"
                logger.info(f"{command} is active.")
                break
            elif response.status_code == 429:
                retry_after = int(response.headers.get("Retry-After", 1))
                retry_time = datetime.utcfromtimestamp(time.time() + retry_after).strftime('%Y-%m-%d %H:%M:%S')
                status_results[command] = f"Rate-Limited; Retry at {retry_time}"
                gui.log(f"{command} is rate-limited. Retrying after {retry_after} seconds.", level="warn")
                logger.warning(f"{command} is rate-limited. Retry at {retry_time}.")
                time.sleep(retry_after)
                retries += 1
            else:
                status_results[command] = f"Error: {response.status_code}"
                logger.error(f"Error with {command}: {response.status_code}")
                break

    return status_results