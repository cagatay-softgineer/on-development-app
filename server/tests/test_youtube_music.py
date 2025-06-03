from flask import Flask
from flask_jwt_extended import JWTManager, create_access_token
import os
import sys
import pytest
from datetime import timedelta

# Ensure repository root is in sys.path so that modules can be imported.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from server import create_app

#############################################
# Fake Implementations for Monkeypatching
#############################################


def fake_get_user_id_by_email(email):
    """Return a fake user ID for testing."""
    return "fake_user_id"


def fake_get_userlinkedapps_access_refresh(user_id, app_id):
    """Return a fake token dictionary with both access and refresh tokens."""
    return [{"access_token": ["fake_youtube_access_token"], "refresh_token": "fake_youtube_refresh_token"}]


def fake_refresh_access_token_and_update_db_for_Google(user_id, refresh_token):
    """Return a fake list with a new access token to simulate a successful token refresh."""
    return ["fake_youtube_access_token"]


def fake_playlist_items(access_token, playlist_id):
    """
    Fake implementation of playlist_items.
    Returns a tuple: (tracks, total_duration, total_tracks).
    For example, simulate 2 tracks with a total duration of 7200000 ms (2 hours).
    """
    return (["fake_track1", "fake_track2"], 7200000, 2)


class FakeResponse:
    """A fake response object simulating requests.Response."""

    def __init__(self, json_data, status_code):
        self._json = json_data
        self.status_code = status_code

    def json(self):
        return self._json


def fake_requests_get_success(url, headers=None, params=None):
    """
    Fake requests.get function that simulates responses based on the URL.
    - For URLs containing 'playlists' with 'mine'=="true": return fake playlist data.
    - For URLs containing 'channels': return fake channel details.
    - For URLs containing 'playlistItems': return fake first video data.
    """
    if "playlists" in url and params and params.get("mine") == "true":
        fake_json = {
            "items": [
                {
                    "id": "playlist1",
                    "snippet": {"channelId": "channel1", "title": "Fake Playlist"},
                    "tracks": {"total": 5},
                }
            ]
        }
        return FakeResponse(fake_json, 200)
    elif "channels" in url:
        fake_json = {
            "items": [
                {
                    "id": "channel1",
                    "snippet": {
                        "thumbnails": {
                            "high": {"url": "http://fake.channel.high.jpg"},
                            "default": {"url": "http://fake.channel.default.jpg"},
                        }
                    },
                }
            ]
        }
        return FakeResponse(fake_json, 200)
    elif "playlistItems" in url:
        fake_json = {
            "items": [
                {
                    "snippet": {"resourceId": {"videoId": "fake_video_id"}}
                }
            ]
        }
        return FakeResponse(fake_json, 200)
    return FakeResponse({}, 200)

#############################################
# Fixtures and Helper Functions
#############################################


@pytest.fixture
def app():
    """
    Create a Flask application instance for testing.
    Configure the app with testing=True, set JWT_SECRET_KEY, and initialize JWTManager.
    """
    app = Flask(__name__)
    app = create_app(app, testing=True)
    app.config["JWT_SECRET_KEY"] = "test-secret"
    JWTManager(app)
    return app


@pytest.fixture
def client(app):
    """
    Create the Flask test client within an active application context.
    """
    with app.test_client() as client:
        with app.app_context():
            yield client


def get_youtube_auth_headers(app, scopes=None):
    """
    Generate an Authorization header with a JWT token containing the "youtube" scope.
    Defaults to ["youtube"].
    """
    if scopes is None:
        scopes = ["youtube"]
    token = create_access_token(
        identity="test_user@example.com",
        expires_delta=timedelta(days=7),
        additional_claims={"scopes": scopes},
    )
    return {"Authorization": f"Bearer {token}"}

#############################################
# Tests for YouTube Music Blueprint Endpoints
#############################################


def test_youtube_music_healthcheck(client):
    response = client.get("/youtube-music/healthcheck")
    assert response.status_code == 200, "Expected 200 OK for healthcheck endpoint"
    data = response.get_json()
    assert data.get("status") == "ok", "Expected status to be 'ok'"
    assert "Youtube Music Service" in data.get("service", ""), "Expected service description to include 'Youtube Music Service'"


def test_youtube_playlists(monkeypatch, client, app):

    monkeypatch.setattr("database.firebase_operations.get_user_id_by_email", fake_get_user_id_by_email)
    monkeypatch.setattr("database.firebase_operations.get_userlinkedapps_access_refresh", fake_get_userlinkedapps_access_refresh)
    # Patch the refresh token function in the blueprint's namespace.
    monkeypatch.setattr("Blueprints.youtube_music.refresh_access_token_and_update_db_for_Google", fake_refresh_access_token_and_update_db_for_Google)
    monkeypatch.setattr("requests.get", fake_requests_get_success)
    # Patch playlist_items in the blueprint's namespace.
    monkeypatch.setattr("Blueprints.youtube_music.playlist_items", fake_playlist_items)
    monkeypatch.setattr("util.utils.ms2FormattedDuration", lambda ms: "02:00:00" if ms == 7200000 else "00:00:00")

    headers = get_youtube_auth_headers(app, scopes=["youtube"])
    payload = {"user_email": "test_user@example.com"}
    response = client.post("/youtube-music/playlists", json=payload, headers=headers)
    assert response.status_code == 200, "Expected 200 OK for playlists endpoint"
    data = response.get_json()
    items = data.get("items", [])
    assert len(items) >= 1, "Expected at least one playlist in the response"
    assert any(item.get("id") == "playlist1" for item in items), "Expected fake playlist 'playlist1' in response"


def test_fetch_first_video_id(monkeypatch, client, app):

    monkeypatch.setattr("database.firebase_operations.get_user_id_by_email", fake_get_user_id_by_email)
    monkeypatch.setattr("database.firebase_operations.get_userlinkedapps_access_refresh", fake_get_userlinkedapps_access_refresh)
    monkeypatch.setattr("Blueprints.youtube_music.refresh_access_token_and_update_db_for_Google", fake_refresh_access_token_and_update_db_for_Google)
    monkeypatch.setattr("requests.get", fake_requests_get_success)

    headers = get_youtube_auth_headers(app, scopes=["youtube"])
    # Payload uses "user_email" to identify the user
    payload = {"user_email": "test_user@example.com", "playlist_id": "fake_playlist_id"}
    response = client.post("/youtube-music/fetch_first_video_id", json=payload, headers=headers)
    assert response.status_code == 200, "Expected 200 OK for fetch_first_video_id endpoint"
    data = response.get_json()
    assert "videoId" in data, "Expected videoId in response"
    assert data["videoId"] == "fake_video_id", "Expected fake_video_id to be returned"


def test_playlist_duration_endpoint(monkeypatch, client, app):

    monkeypatch.setattr("database.firebase_operations.get_user_id_by_email", fake_get_user_id_by_email)
    monkeypatch.setattr("database.firebase_operations.get_userlinkedapps_access_refresh", fake_get_userlinkedapps_access_refresh)
    monkeypatch.setattr("Blueprints.youtube_music.refresh_access_token_and_update_db_for_Google", fake_refresh_access_token_and_update_db_for_Google)
    monkeypatch.setattr("Blueprints.youtube_music.playlist_items", fake_playlist_items)
    monkeypatch.setattr("util.utils.ms2FormattedDuration", lambda ms: "02:00:00" if ms == 7200000 else "00:00:00")

    headers = get_youtube_auth_headers(app, scopes=["youtube"])
    # Use "user_email" instead of "user_id"
    payload = {"user_email": "test_user@example.com", "playlist_id": "fake_playlist_id"}
    response = client.post("/youtube-music/playlist_duration", json=payload, headers=headers)
    assert response.status_code == 200, "Expected 200 OK for playlist_duration endpoint"
    data = response.get_json()
    assert data.get("total_duration") == 7200000, "Expected total_duration to be 7200000 ms"
    assert data.get("formatted_duration") == "02:00:00", "Expected formatted_duration to be '02:00:00'"
    assert data.get("total_tracks") == 2, "Expected total_tracks to be 2"

#############################################
# End of tests/test_youtube_music.py
#############################################


if __name__ == "__main__":
    pytest.main()
