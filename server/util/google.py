import requests
from config.config import settings
from util.logit import get_logger
import database.firebase_operations as firebase_operations

logger = get_logger("logs", "GoogleUtils")


def get_current_user_profile_google(
    access_token: str, user_id: int | str
) -> dict:
    """
    Fetches the Google user profile using the provided access token.
    If the token is expired (HTTP 401), refreshes the token and retries.

    Parameters:
    access_token (str): The access token used to authenticate the request.
    user_id (int | str): The unique identifier of the user.

    Returns:
    dict: The user profile information if the request is successful, None otherwise.
    """
    url = "https://www.googleapis.com/oauth2/v1/userinfo"
    headers = {"Authorization": f"Bearer {access_token}"}
    params = {"client_id": settings.google_client_id}
    response = requests.get(url, headers=headers, params=params)

    if response.status_code == 200:
        return response.json()
    elif response.status_code == 401:
        # Retrieve tokens from your database; assumes result is a dict
        result = firebase_operations.get_userlinkedapps_access_refresh(user_id, 4)[
            0]
        access_token, refresh_token = result["access_token"], result["refresh_token"]
        # print(access_token)
        # print(refresh_token)
        new_access_token = refresh_access_token_and_update_db_for_Google(
            user_id, refresh_token
        )
        if new_access_token:
            return get_current_user_profile_google(new_access_token, user_id)
        else:
            return None
    else:
        logger.error(
            f"Failed to fetch Google user profile: {response.status_code} - {response.text}"
        )
        return None


def refresh_access_token_and_update_db_for_Google(user_id, refresh_token):
    """
    Refreshes the Google access token using the provided refresh token and updates the database with the new tokens.

    Parameters:
    user_id (int | str): The unique identifier of the user.
    refresh_token (str): The refresh token used to obtain a new access token.

    Returns:
    str: The new access token if the refresh is successful, None otherwise.
    """
    url = "https://oauth2.googleapis.com/token"
    data = {
        "client_id": settings.google_client_id,
        "client_secret": settings.google_client_secret,
        "refresh_token": refresh_token,
        "grant_type": "refresh_token",
    }
    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    response = requests.post(url, headers=headers, data=data)

    if response.status_code == 200:
        token_info = response.json()
        new_access_token = token_info.get("access_token")
        expires_in = token_info.get("expires_in", 3600)
        new_refresh_token = token_info.get("refresh_token", refresh_token)

        logger.info("Successfully refreshed Google access token.")
        firebase_operations.update_userlinkedapps_tokens(
            new_access_token, new_refresh_token, expires_in, user_id, 3
        )
        firebase_operations.update_userlinkedapps_tokens(
            new_access_token, new_refresh_token, expires_in, user_id, 4
        )
        return new_access_token
    else:
        logger.error(
            f"Failed to refresh Google access token: {response.status_code} - {response.text}"
        )
        return None
