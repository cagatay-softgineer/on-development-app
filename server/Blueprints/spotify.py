from flask import Blueprint, request, jsonify, redirect, render_template
from markupsafe import escape
from flask_jwt_extended import get_jwt_identity, jwt_required
from flask_limiter import Limiter
from flask_cors import CORS
from flask_limiter.util import get_remote_address
import requests
from util.spotify import (
    get_user_profile,
    fetch_user_playlists,
    get_access_token_from_db,
)
from util.utils import get_email_username
import database.firebase_operations as firebase_operations
from util.models import UserEmailRequest
from config.config import settings
from pydantic import ValidationError
import secrets
from util.logit import get_logger
from util.authlib import requires_scope
from util.models import UserIdRequest

spotify_bp = Blueprint("spotify", __name__)
limiter = Limiter(key_func=get_remote_address)

# Enable CORS for all routes in this blueprint
CORS(spotify_bp, resources={r"/*": {"origins": "*"}})

logger = get_logger("logs", "SpotifyAPI")


@spotify_bp.before_request
def log_spotify_requests():  # noqa: F811
    logger.info("Spotify blueprint request received.")


@spotify_bp.route("/healthcheck", methods=["GET"])
def spotify_healthcheck():
    logger.info("Spotify Service healthcheck requested")
    return jsonify({"status": "ok", "service": "Spotify Service"}), 200


# Load environment variables
CLIENT_ID = settings.spotify_client_id
CLIENT_SECRET = settings.spotify_client_secret
REDIRECT_URI = settings.auth_redirect_uri

# Function to generate random state


def generate_random_state(length=16):
    return secrets.token_hex(length)


@spotify_bp.route("/login/<user_id>", methods=["GET"])
@jwt_required()
@requires_scope("spotify")
def login(user_id):
    """
    This function handles the login process for a user using Spotify's authorization flow.
    It generates a random state, constructs an authorization URL, and redirects the user to Spotify's authorization page.

    Parameters:
    - user_id (str): The unique identifier of the user. This is used to store the user's email in a global variable.

    Returns:
    - A Flask redirect response to Spotify's authorization URL.
    """

    state = generate_random_state()
    scope = (
        "app-remote-control"
        "streaming"
        "user-read-recently-played "
        "user-read-private"
        "user-read-email"
        "playlist-read-private "
        "playlist-read-collaborative"
        "user-library-read"
        "user-top-read "
        "user-read-playback-state"
        "user-modify-playback-state "
        "user-read-currently-playing"
    )

    auth_url = (
        f"https://accounts.spotify.com/authorize?"
        f"response_type=code&client_id={CLIENT_ID}"
        f"&redirect_uri={REDIRECT_URI}&scope={scope}&state={state}"
    )

    logger.info("Redirecting to Spotify authorization URL.")
    return redirect(auth_url)


@spotify_bp.route("/user_profile", methods=["POST"])
@jwt_required()
@requires_scope("spotify")
def get_user():
    """
    Retrieves user profile information from Spotify.

    This function accepts a POST request with a JSON payload containing a user ID.
    It validates the input, retrieves the user profile from Spotify using the user ID,
    and returns the user profile information in JSON format.

    Parameters:
    - request: A Flask request object containing the user ID in the JSON payload.

    Returns:
    - A Flask response object containing a JSON object with the user profile information if the input is valid.
      The JSON object has the following structure:
      {
          "user_id": <user_id>,
          "display_name": <display_name>,
          "email": <email>,
          "external_urls": {
              "spotify": <spotify_profile_url>
          },
          "images": [
              {
                  "height": <image_height>,
                  "url": <image_url>,
                  "width": <image_width>
              },
              ...
          ]
      }
    - A Flask response object containing a JSON object with an error message if the input is invalid.
      The JSON object has the following structure:
      {
          "error": <error_message>
      }
    """
    try:
        payload = UserIdRequest.parse_obj(request.get_json())
    except ValidationError as ve:
        return jsonify({"error": ve.errors()}), 400
    print(payload.user_id)
    return get_user_profile(escape(payload.user_id))


@spotify_bp.route("/playlists", methods=["POST"])
@jwt_required()
@requires_scope("spotify")
def get_playlists():
    """
    This function retrieves and returns the playlists of a user from Spotify.

    Parameters:
    - request: A Flask request object containing the user's email in the JSON payload.

    Returns:
    - A Flask response object containing a JSON object with the user's playlists if the user's email is found in the database.
      The JSON object has the following structure:
      {
          "playlists": [
              {
                  "id": <playlist_id>,
                  "name": <playlist_name>,
                  "description": <playlist_description>,
                  "public": <playlist_public_status>,
                  "collaborative": <playlist_collaborative_status>,
                  "owner": {
                      "id": <owner_id>,
                      "display_name": <owner_display_name>
                  }
              },
              ...
          ]
      }
    - A Flask response object containing a JSON object with an error message if the user's email is not found in the database.
      The JSON object has the following structure:
      {
          "error": <error_message>
      }
    """
    try:
        payload = UserEmailRequest.parse_obj(request.get_json())
    except ValidationError as ve:
        return jsonify({"error": ve.errors()}), 400
    except Exception as e:
        logger.error("An internal error occurred: %s", e)
        return jsonify({"error": "An internal error occurred."}), 400
    user_id = firebase_operations.get_user_id_by_email(payload.user_email)

    playlists_json = fetch_user_playlists(user_id, app_id=1)
    return jsonify(playlists_json), 200


@spotify_bp.route("/token", methods=["POST"])
@jwt_required()
@requires_scope("spotify")
def get_token():
    """
    This function retrieves an access token for a given user from the database.

    Parameters:
    - request: A Flask request object containing the user's email in the JSON payload.

    Returns:
    - A Flask response object containing a JSON object with the access token if the user's email is found in the database.
      The JSON object has the following structure:
      {
          "token": <access_token>
      }
    - A Flask response object containing a JSON object with an error message if the user's email is not found in the database.
      The JSON object has the following structure:
      {
          "error": <error_message>
      }
    """
    try:
        try:
            payload = UserEmailRequest.parse_obj(request.get_json())
        except ValidationError as ve:
            return jsonify({"error": ve.errors()}), 400
    except Exception as e:
        logger.error("An internal error occurred: %s", e)
        return jsonify({"error": "An internal error occurred."}), 400

    user_id = firebase_operations.get_user_id_by_email(payload.user_email)

    token = get_access_token_from_db(user_id, 1)[0]
    return jsonify({"token": token}), 200


@spotify_bp.route("/callback", methods=["GET"])
def callback():
    """
    This function handles the callback from Spotify's authorization flow.
    It exchanges the authorization code for an access token and stores it in the database.

    Parameters:
    - None

    Returns:
    - A Flask response object containing a JSON object with an error message if the authorization code is not found.
    - A Flask response object containing a rendered HTML template with success message and user ID if the access token is obtained successfully.
    - A Flask response object containing a JSON object with an error message if the access token cannot be obtained.
    """
    code = request.args.get("code")
    if not code:
        logger.error("Authorization code not found in callback request.")
        return jsonify({"error": "Authorization code not found"}), 400

    token_url = "https://accounts.spotify.com/api/token"
    token_data = {
        "grant_type": "authorization_code",
        "code": code,
        "redirect_uri": REDIRECT_URI,
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
    }
    token_headers = {"Content-Type": "application/x-www-form-urlencoded"}

    response = requests.post(token_url, data=token_data, headers=token_headers)

    if response.status_code == 200:
        token_info = response.json()
        access_token = token_info["access_token"]
        refresh_token = token_info.get("refresh_token")
        scopes = token_info.get("scope")
        # expires_in = token_info.get("expires_in")
        # token_type = token_info.get("token_type")

        logger.info("Successfully obtained access token.")
        user_email = get_jwt_identity()
        user_id = firebase_operations.get_user_id_by_email(user_email)
        firebase_operations.if_not_exists_insert_userlinkedapps(
            user_id, 1, access_token, refresh_token, scopes
        )

        return (
            render_template(
                "spotify.html", success=True, user_id=get_email_username(user_email)
            ),
            200,
        )
    else:
        logger.error(
            f"Failed to obtain access token: {response.status_code} - {response.text}"
        )
        return jsonify({"error": "Failed to obtain access token"}), 400
