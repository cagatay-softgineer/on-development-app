from flask import Blueprint, request, jsonify
from flask_limiter import Limiter
from flask_jwt_extended import jwt_required
from flask_cors import CORS
from flask_limiter.util import get_remote_address
from pydantic import ValidationError

# Ensure your settings include apple_developer_token
from config.config import settings
import requests
import logging
import database.firebase_operations as firebase_operations
from util.utils import (
    ms2FormattedDuration,
)  # Utility to format milliseconds into human readable string
from util.authlib import requires_scope
from util.models import PlaylistItemsRequest, UserEmailRequest


appleMusic_bp = Blueprint("appleMusic", __name__)
limiter = Limiter(key_func=get_remote_address)
CORS(appleMusic_bp, resources=settings.CORS_resource_allow_all)

logger = logging.getLogger("logs/apple_music.log")


@appleMusic_bp.route("/albums", methods=["POST"])
@jwt_required()
@requires_scope("apple")
def get_albums():
    """
    Retrieve the current user's Apple Music library albums.

    Expects a JSON payload:
        {
            "user_email": "USER_EMAIL"
        }

    Returns:
        A JSON response containing the user's library albums or an error message.
    """
    try:
        payload = UserEmailRequest.parse_obj(request.get_json())
    except ValidationError as ve:
        return jsonify({"error": ve.errors()}), 400
    user_email = payload.user_email
    # Your configured developer token
    developer_token = settings.apple_developer_token
    user_id = firebase_operations.get_user_id_by_email(user_email)
    response = firebase_operations.get_userlinkedapps_tokens(user_id, 2)

    access_tokens = response[0]["access_token"]
    headers = {
        "Authorization": f"Bearer {developer_token}",
        "Music-User-Token": access_tokens,
    }

    url = "https://api.music.apple.com/v1/me/library/albums"
    try:
        response = requests.get(url, headers=headers)
        if response.status_code != 200:
            logger.error("Error fetching albums: %s", response.text)
            return (
                jsonify(
                    {
                        "error": "Failed to fetch albums from Apple Music API.",
                        "details": response.json(),
                    }
                ),
                response.status_code,
            )

        albums_data = response.json()
        logger.info("Successfully retrieved albums.")
        return jsonify(albums_data), 200

    except Exception as e:
        logger.error("Exception occurred while fetching albums: %s", e)
        return (
            jsonify(
                {
                    "error": "An error occurred while fetching albums.",
                }
            ),
            500,
        )


@appleMusic_bp.route("/playlists", methods=["POST"])
@jwt_required()
@requires_scope("apple")
def get_playlists():
    """
    Retrieve the current user's Apple Music library playlists along with duration details.

    Expects a JSON payload:
        {
            "user_email": "USER_EMAIL"
        }

    For each playlist, the response will include:
        - total_duration: Total duration in milliseconds of all tracks.
        - formatted_duration: Human-readable duration string.
        - total_tracks: Number of tracks.
        - playlist_id: The Apple Music playlist identifier.

    Returns:
        A JSON response containing the user's library playlists with the added duration details.
    """
    try:
        payload = UserEmailRequest.parse_obj(request.get_json())
    except ValidationError as ve:
        return jsonify({"error": ve.errors()}), 400
    user_email = payload.user_email

    # Your configured developer token
    developer_token = settings.apple_developer_token
    user_id = firebase_operations.get_user_id_by_email(user_email)
    response_tokens = firebase_operations.get_userlinkedapps_tokens(user_id, 2)
    access_token = response_tokens[0]["access_token"]

    headers = {
        "Authorization": f"Bearer {developer_token}",
        "Music-User-Token": access_token,
    }

    url = "https://api.music.apple.com/v1/me/library/playlists"
    try:
        response = requests.get(url, headers=headers)
        if response.status_code != 200:
            logger.error("Error fetching playlists: %s", response.text)
            return (
                jsonify(
                    {
                        "error": "Failed to fetch playlists from Apple Music API.",
                        "details": response.json(),
                    }
                ),
                response.status_code,
            )

        playlists_data = response.json()
        # Assume the playlists are in the "data" key.
        playlists = playlists_data.get("data", [])

        # Process each playlist to add duration and track count info.
        for playlist in playlists:
            playlist_id = playlist.get("id")
            if not playlist_id:
                continue  # Skip if no id is present.

            # Build the URL to fetch tracks for the playlist.
            tracks_url = f"https://api.music.apple.com/v1/me/library/playlists/{playlist_id}/tracks"
            try:
                tracks_response = requests.get(tracks_url, headers=headers)
                if tracks_response.status_code == 200:
                    tracks_data = tracks_response.json()
                    # Extract the list of tracks; this response is assumed to
                    # be structured with a "data" key.
                    if "data" in tracks_data and isinstance(
                            tracks_data["data"], list):
                        tracks = tracks_data["data"]
                    else:
                        tracks = []

                    total_duration = 0
                    for track in tracks:
                        # Each track is expected to include a duration under
                        # attributes['durationInMillis'].
                        duration = track.get("attributes", {}).get(
                            "durationInMillis", 0
                        )
                        try:
                            total_duration += int(duration)
                        except (ValueError, TypeError):
                            continue

                    formatted_duration = ms2FormattedDuration(total_duration)
                    total_tracks = len(tracks)

                    # Add additional keys to the playlist data.
                    playlist["total_duration"] = total_duration
                    playlist["formatted_duration"] = formatted_duration
                    playlist["total_tracks"] = total_tracks
                    playlist["playlist_id"] = playlist_id
                else:
                    logger.error(
                        "Error fetching tracks for playlist %s: %s",
                        playlist_id,
                        tracks_response.text,
                    )
                    # Set default values on error.
                    playlist["total_duration"] = 0
                    playlist["formatted_duration"] = ms2FormattedDuration(0)
                    playlist["total_tracks"] = 0
                    playlist["playlist_id"] = playlist_id
            except Exception as inner_e:
                logger.error(
                    "Exception processing playlist %s: %s", playlist_id, inner_e
                )
                playlist["total_duration"] = 0
                playlist["formatted_duration"] = ms2FormattedDuration(0)
                playlist["total_tracks"] = 0
                playlist["playlist_id"] = playlist_id

        logger.info(
            "Successfully processed playlists for user: %s",
            user_email)
        return jsonify(playlists_data), 200

    except Exception as e:
        logger.error("Exception occurred while fetching playlists: %s", e)
        return jsonify(
            {"error": "An error occurred while fetching playlists."}), 500


@appleMusic_bp.route("/albums/<album_id>/tracks", methods=["POST"])
@jwt_required()
@requires_scope("apple")
def get_album_tracks(album_id):
    """
    Retrieve tracks for a specific album from the user's Apple Music library.

    Expects a JSON payload:
        {
            "user_email": "USER_EMAIL"
        }

    Parameters:
        album_id (str): The Apple Music album identifier.

    Returns:
        A JSON response containing the album's tracks or an error message.
    """
    try:
        payload = UserEmailRequest.parse_obj(request.get_json())
    except ValidationError as ve:
        return jsonify({"error": ve.errors()}), 400
    user_email = payload.user_email

    developer_token = (
        settings.apple_developer_token
    )  # Ensure this is set in your configuration
    user_id = firebase_operations.get_user_id_by_email(user_email)
    response = firebase_operations.get_userlinkedapps_tokens(user_id, 2)

    access_tokens = response[0]["access_token"]
    headers = {
        "Authorization": f"Bearer {developer_token}",
        "Music-User-Token": access_tokens,
    }

    url = f"https://api.music.apple.com/v1/me/library/albums/{album_id}/tracks"
    try:
        response = requests.get(url, headers=headers)
        if response.status_code != 200:
            logger.error(
                "Error fetching tracks for album %s: %s", album_id, response.text
            )
            return (
                jsonify(
                    {
                        "error": "Failed to fetch album tracks from Apple Music API.",
                        "details": response.json(),
                    }
                ),
                response.status_code,
            )

        tracks_data = response.json()
        logger.info("Successfully retrieved tracks for album %s.", album_id)
        return jsonify(tracks_data), 200

    except Exception as e:
        logger.error("Exception occurred while fetching album tracks: %s", e)
        return (
            jsonify(
                {
                    "error": "An error occurred while fetching album tracks.",
                }
            ),
            500,
        )


# playlists


@appleMusic_bp.route("/playlist_duration", methods=["POST"])
@jwt_required()
@requires_scope("apple")
def playlist_duration():
    """
    Retrieve the total duration of a user's Apple Music playlist.

    Expects a JSON payload:
        {
            "user_email": "USER_EMAIL",
            "playlist_id": "APPLE_MUSIC_PLAYLIST_ID"
        }

    Returns:
        A JSON response containing the total duration in milliseconds,
        a formatted duration string, and the total number of tracks.
    """
    try:
        payload = PlaylistItemsRequest.parse_obj(request.get_json())
    except ValidationError as ve:
        return jsonify({"error": ve.errors()}), 400
    user_email = payload.user_email
    playlist_id = payload.playlist_id

    if not user_email or not playlist_id:
        return jsonify(
            {"error": "Missing user_id or playlist_id parameter."}), 400

    developer_token = settings.apple_developer_token
    user_id = firebase_operations.get_user_id_by_email(user_email)
    response = firebase_operations.get_userlinkedapps_tokens(user_id, 2)

    access_tokens = response[0]["access_token"]
    headers = {
        "Authorization": f"Bearer {developer_token}",
        "Music-User-Token": access_tokens,
    }

    url = f"https://api.music.apple.com/v1/me/library/playlists/{playlist_id}/tracks"
    try:
        response = requests.get(url, headers=headers)
        if response.status_code != 200:
            logger.error(
                "Error fetching tracks for playlist %s: %s", playlist_id, response.text
            )
            return (
                jsonify(
                    {
                        "error": "Failed to fetch playlist tracks from Apple Music API.",
                        "details": response.json(),
                    }
                ),
                response.status_code,
            )

        tracks_data = response.json()
        # Extract tracks from possible response structures
        if "data" in tracks_data and isinstance(tracks_data["data"], list):
            tracks = tracks_data["data"]
        elif "data" in tracks_data and "data" in tracks_data["data"]:
            tracks = tracks_data["data"]["data"]
        else:
            logger.error("Unexpected tracks response format: %s", tracks_data)
            return jsonify(
                {"error": "Unexpected tracks response format."}), 500

        total_duration = 0
        for track in tracks:
            # Assume each track's duration is in 'durationInMillis' under
            # attributes
            duration = track.get("attributes", {}).get("durationInMillis", 0)
            try:
                total_duration += int(duration)
            except (ValueError, TypeError):
                continue

        formatted_duration = ms2FormattedDuration(total_duration)
        total_tracks = len(tracks)

        logger.info(
            "Successfully calculated playlist duration for playlist %s.", playlist_id
        )
        return (
            jsonify(
                {
                    "total_duration": total_duration,
                    "formatted_duration": formatted_duration,
                    "total_tracks": total_tracks,
                    "playlist_id": playlist_id,
                }
            ),
            200,
        )

    except Exception as e:
        logger.error(
            "Exception occurred while calculating playlist duration: %s", e)
        return (
            jsonify(
                {
                    "error": "An error occurred while calculating playlist duration.",
                }
            ),
            500,
        )
