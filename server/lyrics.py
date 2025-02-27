from flask import Blueprint, request, jsonify
import requests
from config import settings
import logging

LOG_FILE = "logs/spotify_micro_service.log"
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

DEBUG_MODE = settings.debug_mode
if DEBUG_MODE == "True":
    DEBUG_MODE = True

lyrics_bp = Blueprint('lyrics', __name__, url_prefix='/lyrics')

@lyrics_bp.route('/get', methods=['GET'])
def get_lyrics():
    # Extract query parameters for track and artist
    track = request.args.get('track')
    artist = request.args.get('artist')
    
    if not track or not artist:
        return jsonify({
            'error': 'Both "track" and "artist" query parameters are required.'
        }), 400
    
    # Define the Musixmatch API endpoint and parameters
    api_key = settings.musixmatch_API_KEY
    endpoint = "https://api.musixmatch.com/ws/1.1/matcher.lyrics.get"
    params = {
        'apikey': api_key,
        'q_track': track,
        'q_artist': artist
    }
    
    # Make the GET request to Musixmatch API
    response = requests.get(endpoint, params=params)
    
    if response.status_code != 200:
        return jsonify({
            'error': 'Error fetching lyrics from Musixmatch',
            'status_code': response.status_code
        }), response.status_code
    
    # Parse the JSON response
    data = response.json()
    
    # Navigate through the response structure as per Musixmatch API documentation
    message = data.get('message', {})
    body = message.get('body', {})
    lyrics = body.get('lyrics', {})
    
    # Return the lyrics (or an error message if not found)
    if not lyrics:
        return jsonify({
            'error': 'Lyrics not found for the given track and artist.'
        }), 404

    return jsonify(lyrics)
