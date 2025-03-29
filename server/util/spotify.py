import time
from cmd_gui_kit import CmdGUI
import requests
import base64
from config.config import settings
from util.error_handling import log_error
from util.logit import get_logger
from util.utils import ms2FormattedDuration
import database.firebase_operations as firebase_operations

# Initialize CmdGUI for visual feedback
gui = CmdGUI()

# Logging setup
logger = get_logger("logs/spotify_util.log", "SpotifyUtils")

SPOTIFY_CLIENT_ID = settings.spotify_client_id
SPOTIFY_CLIENT_SECRET = settings.spotify_client_secret


# Global cache for playlist durations
# Each key is a playlist_id and the value is a tuple: (result_data, expiration_time)
playlist_cache = {}
CACHE_DURATION = 3600  # Cache duration in seconds (1 hour)


def get_access_token_for_request():
    """
    This function requests an access token using a single Spotify client credential
    and caches it globally. If the token already exists, it returns the cached token.

    Parameters:
    None

    Returns:
    str: The access token if the request is successful.
         Raises an exception if the request fails.
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

    

def make_request(
    url,
    max_retries=5,
    access_token=None
):
    """
    Makes a GET request to a specified URL with retry logic for rate limiting.
    Uses a single Spotify credential for all requests.

    Parameters:
    url (str): The URL to which the GET request will be made.
    max_retries (int, optional): The maximum number of times the request will be retried in case of rate limiting.
                                  Defaults to 5.
    access_token (str, optional): The access token to be used for authentication. If not provided, it will be obtained
                                   using the `get_access_token_for_request` function. Defaults to None.

    Returns:
    requests.Response or None: The response object if the request is successful (status code 200).
                                Returns None if the request fails due to a 404 status code (resource not found)
                                or if the maximum number of retries is reached.
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
    """
    Requests a new access token for the Spotify client ID.

    This function sends a POST request to the Spotify Accounts API token endpoint with the client credentials
    to obtain a new access token. The function handles rate limit exceeded errors by returning an empty string
    and a status code of 429. For other HTTP errors, it returns an empty string and a status code of 404.

    Parameters:
    None

    Returns:
    tuple: A tuple containing the access token (str) and a status code (int).
           If the request is successful, the status code will be 200.
           If the request fails due to rate limit exceeded, the status code will be 429.
           If the request fails due to other HTTP errors, the status code will be 404.
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

        return access_token, 200

    elif response.status_code == 429:
        return "", 429
    else:
        return "", 404



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
    url_template = "https://api.spotify.com/v1/me/playlists?limit=50&offset={offset}"
    offset = 0
    order = 0
    formatted_playlists = []
    playlist_count_limit = 10
    is_playlist_count_exceeded_to_limit = False
    while True:
        url = url_template.format(offset=offset)
        response = make_request(url, access_token=access_token)

        if response.status_code == 200:
            playlists_data = response.json()
            items = playlists_data.get('items', [])
            if not items:
                print("Not Found Any Item")
                break
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
                    "order": order,
                    "offset": offset, 
                    "playlist_name": item["name"],
                    "playlist_id": item["id"],
                    "playlist_image": item["images"][0]["url"] if item["images"] else "",
                    "playlist_owner": item["owner"]["display_name"],
                    "playlist_owner_id": item["owner"]["id"],
                    "playlist_track_count": item["tracks"]["total"],
                    "playlist_duration": "Loading..",
                    #"playlist_duration": calculate_playlist_duration(user_id, item["id"], access_token, refresh_token)["formatted_duration"],
                    "tracks": [],
                }
                if formatted_playlist["playlist_track_count"] < 100:    
                    order += 1
                    formatted_playlists.append(formatted_playlist)
                    
                    is_playlist_count_exceeded_to_limit = len(formatted_playlists) > playlist_count_limit
                    if is_playlist_count_exceeded_to_limit:
                        break
            if is_playlist_count_exceeded_to_limit:
                        break        
            offset += 50
        
        elif response.status_code == 401:
            refresh_access_token_and_update_db(user_id, refresh_token, app_id)
            formatted_playlists.clear()
            return fetch_user_playlists(user_id, app_id)
        else:
            logger.error(f"Failed to fetch playlists: {response.status_code} - {response.text}")
            return None
    logger.info("Successfully fetched and formatted playlists.")
    return formatted_playlists


def calculate_playlist_duration(
    user_email: str,
    playlist_id: str,
    access_token: str | None = None,
    refresh_token: str | None = None
) -> dict:
    """
    Calculates and returns the playlist duration and track count for a given Spotify playlist.
    
    Parameters:
      user_email (str): The user's email.
      playlist_id (str): The Spotify playlist ID.
      access_token (str | None): The access token (optional). If None, it will be retrieved.
      refresh_token (str | None): The refresh token (optional).
      
    Returns:
      dict: A dictionary containing playlist_id, total_duration_ms, formatted_duration, and total_track_count.
    
    Raises:
      Exception: If fetching the playlist tracks fails.
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

    # Compute the playlist duration
    url_template = "https://api.spotify.com/v1/playlists/{playlist_id}/tracks?limit=50&offset={offset}"
    offset = 0
    total_duration_ms = 0
    total_track_count = 0

    while True:
        url = url_template.format(playlist_id=playlist_id, offset=offset)
        # Retrieve the user_id from the email if tokens are not provided.
        if access_token is None and refresh_token is None:
            user_id = firebase_operations.get_user_id_by_email(user_email)
            # Get the access token (and ignore the refresh token here)
            access_token, _ = get_access_token_from_db(user_id, app_id=1)
        
        response = make_request(url, access_token=access_token)
        
        if not response or response.status_code != 200:
            raise Exception(f"Failed to fetch playlist tracks. Response: {response.text if response else 'None'}")
        
        if response.status_code == 401:
           access_token = refresh_access_token_and_update_db(user_id,refresh_token,app_id=1)
           calculate_playlist_duration(user_id, access_token)
        
        data = response.json()
        items = data.get('items', [])
        if not items:
            break

        for item in items:
            track = item.get('track')
            if track and 'duration_ms' in track:
                total_duration_ms += track['duration_ms']
                total_track_count += 1

        offset += 50

    formatted_duration = ms2FormattedDuration(total_duration_ms)

    result_data = {
        "playlist_id": playlist_id,
        "total_duration_ms": total_duration_ms,
        "formatted_duration": formatted_duration,
        "total_track_count": total_track_count
    }

    # Store the result in the cache with a 1-hour expiration
    playlist_cache[playlist_id] = (result_data, time.time() + CACHE_DURATION)
    return result_data

# Function to refresh access token
def refresh_access_token_and_update_db(user_id, refresh_token, app_id):
    """
    Refreshes the Spotify access token for a given user and updates the database with the new token.

    Parameters:
    user_id (str): The unique identifier of the user for whom the access token needs to be refreshed.
    refresh_token (str): The refresh token used to obtain a new access token.
    app_id (str): The unique identifier of the application.

    Returns:
    str: The new access token if the refresh is successful.
         None: If the refresh fails.
    """
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
    """
    Retrieves the current user's profile from the Spotify API using the provided access token.
    If the access token is expired, it refreshes the token and updates the database.

    Parameters:
    access_token (str): The access token used to authenticate the request.
    user_id (str): The unique identifier of the user for whom the profile is to be fetched.
    app_id (str): The unique identifier of the application.

    Returns:
    dict: A dictionary containing the user profile data if the request is successful.
          If the request fails due to an expired access token, the function will attempt to refresh the token
          and retry the request. If the request still fails, it will log the error and return None.
    """
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
    """
    Retrieves the user profile from the Spotify API using the provided user ID.

    Parameters:
    user_id (str): The unique identifier of the user for whom the profile is to be fetched.

    Returns:
    dict: A dictionary containing the user profile data if the request is successful.
          If the request fails, returns None.
    """
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

    

def get_access_token_from_db(user_id, app_id):
    """
    Retrieves the access token and refresh token for a given user and app from the database.
    If the access token is not valid, it refreshes the token and updates the database.

    Parameters:
    user_id (str): The unique identifier of the user.
    app_id (str): The unique identifier of the application.

    Returns:
    tuple: A tuple containing the access token and refresh token. If the access token is not found, returns None.
    """
    result = firebase_operations.get_userlinkedapps_access_refresh(user_id, app_id)[0]
    print(result)
    if not result:
        logger.error(f"Access token not found for user_id: {user_id}")
        return None

    access_token, refresh_token = result["access_token"], result["refresh_token"]
    if test_token(access_token) != 200:
        refresh_access_token_and_update_db(user_id, refresh_token, app_id)
        get_access_token_from_db(user_id, app_id)

    return access_token, refresh_token
