from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
import requests
from config.config import settings
from util.logit import get_logger
from util.authlib import requires_scope

lyrics_bp = Blueprint("lyrics", __name__, url_prefix="/lyrics")

logger = get_logger("logs/lyrics.log", "MakroMusicService")


@lyrics_bp.before_request
def log_lyrics_requests():
    logger.info("Lyrics blueprint request received.")


@lyrics_bp.route("/healthcheck", methods=["GET"])
def lyrics_healthcheck():
    logger.info("Lyrics Service healthcheck requested")
    return jsonify({"status": "ok", "service": "Lyrics Service"}), 200


DEBUG_MODE = settings.debug_mode
if DEBUG_MODE == "True":
    DEBUG_MODE = True


@lyrics_bp.route("/get", methods=["GET"])
@jwt_required()
@requires_scope("lyrics")
def get_lyrics():
    """
    Fetch lyrics for a given track and artist from the Musixmatch API.

    Parameters:
    track (str): The name of the track.
    artist (str): The name of the artist.

    Returns:
    JSON: A JSON object containing the lyrics if found, or an error message if not found or an error occurred.
    HTTP Status Code: 400 if both "track" and "artist" query parameters are not provided, 404 if lyrics are not found, or the HTTP status code returned by the Musixmatch API.
    """
    # Extract query parameters for track and artist
    track = request.args.get("track")
    artist = request.args.get("artist")

    if not track or not artist:
        return (
            jsonify(
                {"error": 'Both "track" and "artist" query parameters are required.'}
            ),
            400,
        )

    # Define the Musixmatch API endpoint and parameters
    api_key = settings.musixmatch_API_KEY
    endpoint = "https://api.musixmatch.com/ws/1.1/matcher.lyrics.get"
    params = {"apikey": api_key, "q_track": track, "q_artist": artist}

    # Make the GET request to Musixmatch API
    response = requests.get(endpoint, params=params)

    if response.status_code != 200:
        return (
            jsonify(
                {
                    "error": "Error fetching lyrics from Musixmatch",
                    "status_code": response.status_code,
                }
            ),
            response.status_code,
        )

    # Parse the JSON response
    data = response.json()

    # Navigate through the response structure as per Musixmatch API
    # documentation
    message = data.get("message", {})
    body = message.get("body", {})
    lyrics = body.get("lyrics", {})

    # Return the lyrics (or an error message if not found)
    if not lyrics:
        return (
            jsonify({"error": "Lyrics not found for the given track and artist."}),
            404,
        )

    return jsonify(lyrics)
