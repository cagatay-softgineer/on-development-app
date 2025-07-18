import os
from cmd_gui_kit import CmdGUI
import hashlib
from config.config import settings
from util.logit import get_logger
import json
from dotenv import load_dotenv

OAUTHLIB_INSECURE_TRANSPORT = 1

# Initialize CmdGUI for visual feedback
gui = CmdGUI()

# Logging setup
logger = get_logger("logs", "Utils")


def obfuscate(column_name: str) -> str:
    """
    Obfuscates a given column name by hashing it with a salt value and returning the first 12 characters in uppercase.

    Parameters:
    column_name (str): The column name to be obfuscated.

    Returns:
    str: The obfuscated column name, consisting of the first 12 characters of the hashed value in uppercase.
    """
    salt = settings.salt  # Replace with your own secret salt value.
    hash_value = hashlib.sha256(
        (salt + column_name).encode("utf-8")).hexdigest()
    return f"{hash_value[:12].upper()}"


def get_email_username(email: str) -> str:
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
    "/spotify/user_profile": "Retrieves profile information of the logged-in Spotify user.",
}


def ms2FormattedDuration(total_duration_ms: int) -> str:
    """
    Converts a given duration in milliseconds to a formatted string representing hours, minutes, and seconds.

    Parameters:
    total_duration_ms (int): The total duration in milliseconds.

    Returns:
    str: A formatted string representing the duration in the format "HH:MM:SS".
    """
    total_seconds = total_duration_ms // 1000
    hours = total_seconds // 3600
    minutes = (total_seconds % 3600) // 60
    seconds = total_seconds % 60
    formatted_duration = f"{hours:02}:{minutes:02}:{seconds:02}"
    return formatted_duration


def load_JSONs():
    # Load environment variables from the .env file.
    current_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    load_dotenv()

    # Retrieve the JSON string from the environment variable.
    raw_json_str = os.getenv("FIREBASE_CC_JSON")
    if not raw_json_str:
        raise EnvironmentError("FIREBASE_CC_JSON environment variable not found.")

    # Decode escape sequences so that '\\n' becomes actual newline characters.
    # This is necessary so that the private_key gets formatted correctly.
    decoded_json_str = raw_json_str.encode("utf-8").decode("unicode_escape")

    # Parse the JSON string to make sure it is valid.
    try:
        json_data = json.loads(decoded_json_str)
    except json.JSONDecodeError as e:
        raise ValueError("The FIREBASE_CC_JSON environment variable contains invalid JSON.") from e

    # Ensure that the target directory exists.
    target_directory = os.path.join(current_dir, "database")
    os.makedirs(target_directory, exist_ok=True)

    # Define the full file path.
    file_path = os.path.join(target_directory, "fb-cc-test.json")

    # Write the parsed JSON data into the file with pretty printing.
    with open(file_path, 'w', encoding='utf-8') as file:
        json.dump(json_data, file, indent=2)

    print(f"JSON file has been successfully written to: {file_path}")

    raw_json_str = os.getenv("GOOGLE_CLIENT_SECRET_FILE")
    if not raw_json_str:
        raise EnvironmentError("GOOGLE_CLIENT_SECRET_FILE environment variable not found.")

    # Decode escape sequences so that '\\n' becomes actual newline characters.
    # This is necessary so that the private_key gets formatted correctly.
    decoded_json_str = raw_json_str.encode("utf-8").decode("unicode_escape")

    # Parse the JSON string to make sure it is valid.
    try:
        json_data = json.loads(decoded_json_str)
    except json.JSONDecodeError as e:
        raise ValueError("The GOOGLE_CLIENT_SECRET_FILE environment variable contains invalid JSON.") from e

    # Ensure that the target directory exists.

    target_directory = os.path.join(current_dir, "keys")
    os.makedirs(target_directory, exist_ok=True)

    # Define the full file path.
    file_path = os.path.join(target_directory, "client_secret_test.json")

    # Write the parsed JSON data into the file with pretty printing.
    with open(file_path, 'w', encoding='utf-8') as file:
        json.dump(json_data, file, indent=2)

    print(f"JSON file has been successfully written to: {file_path}")

