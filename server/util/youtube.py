import datetime
import time
from flask import jsonify
import requests
import isodate
from util.logit import get_logger
from config.config import settings

logger = get_logger("logs/youtube_utils.log", "YoutubeUtils")
playlist_cache = {}
CACHE_DURATION = 3600  # Cache duration in seconds (1 hour)


def iso_duration_to_milliseconds(iso_duration: str) -> int:
    """
    Convert an ISO 8601 duration string to milliseconds.
    
    For durations that include years or months, approximate conversions are used:
      - 1 year = 365 days
      - 1 month = 30 days
    """
    duration = isodate.parse_duration(iso_duration)
    
    # If the duration is a datetime.timedelta, perform a direct conversion.
    if isinstance(duration, datetime.timedelta):
        ms = int(duration.total_seconds() * 1000)
    else:
        # Handle isodate.Duration which may include years and months.
        # Approximate years and months to days.
        total_seconds = (
            (duration.years * 365 * 24 * 3600 if duration.years else 0) +
            (duration.months * 30 * 24 * 3600 if duration.months else 0) +
            (duration.days * 24 * 3600 if duration.days else 0) +
            (duration.tdelta.total_seconds() if duration.tdelta else 0)
        )
        ms = int(total_seconds * 1000)
    return ms


def playlist_items(access_token, playlist_id):
    """
    Fetches all playlist items from YouTube, calculates the total duration, and returns a tuple:
    (tracks, total_duration, total_tracks). Uses caching to avoid repeated API calls for the same playlist.

    Parameters:
      access_token (str): The access token for YouTube API authorization.
      playlist_id (str): The YouTube playlist ID.

    Returns:
      tuple: A tuple containing:
          - tracks (list): A list of dictionaries with video_id, duration, and title.
          - total_duration (int): The sum of all video durations in milliseconds.
          - total_tracks (int): The total number of tracks.
      
    Raises:
      Exception: If fetching playlist items or track details fails.
    """
    # Check if the result is in the cache and not expired
    cached_entry = playlist_cache.get(playlist_id)
    if cached_entry:
        cached_data, expiration_time = cached_entry
        if time.time() < expiration_time:
            return cached_data
        else:
            # Remove expired cache entry
            del playlist_cache[playlist_id]

    # Now, fetch all playlist items from YouTube
    url = "https://www.googleapis.com/youtube/v3/playlistItems"
    headers = {
        "Authorization": f"Bearer {access_token}"
    }
    tracks = []
    playlist_items_ids = []  # To store video IDs
    total_duration = 0
    total_tracks = 0
    nextPageToken = None

    try:
        # First loop: Retrieve video IDs from the playlist
        while True:
            params = {
                "part": "snippet,contentDetails,id,status",
                "playlistId": playlist_id,
                "maxResults": 50,
                "client_id": settings.google_client_id
            }
            if nextPageToken:
                params["pageToken"] = nextPageToken

            response = requests.get(url, headers=headers, params=params)
            if response.status_code != 200:
                logger.error("Error fetching playlist items: %s", response.text)
                return jsonify({"error": "Failed to fetch playlist items."}), response.status_code

            data = response.json()
            for item in data.get("items", []):
                snippet = item.get("snippet", {})
                video_id = snippet.get("resourceId", {}).get("videoId")
                if video_id:
                    playlist_items_ids.append(video_id)

            nextPageToken = data.get("nextPageToken")
            if not nextPageToken:
                break

        # Reset nextPageToken for the second API call (if pagination is needed)
        nextPageToken = None

        # Second loop: Retrieve track details (duration, title, etc.) using the video IDs
        while True:
            print("Playlist fetching...")
            url = "https://www.googleapis.com/youtube/v3/videos"
            headers = {
                "Authorization": f"Bearer {access_token}"
            }
            params = {
                "part": "snippet,contentDetails",
                "id": ','.join(map(str, playlist_items_ids)),
                "client_id": settings.google_client_id
            }
            if nextPageToken:
                params["pageToken"] = nextPageToken

            response = requests.get(url, headers=headers, params=params)
            if response.status_code != 200:
                logger.error("Error fetching tracks: %s", response.text)
                raise Exception("Failed to fetch tracks.")

            data = response.json()
            for item in data.get("items", []):
                snippet = item.get("snippet", {})
                contentDetails = item.get("contentDetails", {})
                
                video_id = item.get("id")
                title = snippet.get("title")
                duration_iso = contentDetails.get("duration")
                duration_ms = iso_duration_to_milliseconds(duration_iso)
                total_duration += duration_ms
                total_tracks += 1
                if video_id:
                    tracks.append({"video_id": video_id, "duration": duration_ms, "title": title})

            nextPageToken = data.get("nextPageToken")
            if not nextPageToken:
                break

        result = (tracks, total_duration, total_tracks)
        # Store the result in the cache with a CACHE_DURATION expiration
        playlist_cache[playlist_id] = (result, time.time() + CACHE_DURATION)
        return result

    except Exception as e:
        logger.error("Error fetching all tracks: %s", e)
        raise Exception("An error occurred while fetching tracks.")