import sys
import os
import pytest
from datetime import timedelta
from flask_jwt_extended import JWTManager, create_access_token

# Ensure repository root is in the Python path.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from server import create_app

#############################################
# Fake Implementation for Testing
#############################################


def fake_calculate_playlist_duration(user_email, playlist_id):
    """
    A fake implementation that simulates calculate_playlist_duration.
    Returns a predictable dictionary.
    """
    return {
        "playlist_id": playlist_id,
        "total_duration_ms": 3600000,   # 1 hour in ms
        "formatted_duration": "01:00:00",
        "total_track_count": 10,
    }

#############################################
# Fixtures
#############################################


@pytest.fixture
def app():
    """
    Create a Flask application instance for testing.
    Configure the app with testing=True, set JWT_SECRET_KEY, and initialize JWTManager.
    """
    app = create_app(testing=True)
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

#############################################
# Helper Function for Authorization Headers
#############################################


def get_spotify_auth_headers(app, scopes=None):
    """
    Generates JWT Authorization headers with the given scopes (default is ['spotify']).
    """
    if scopes is None:
        scopes = ["spotify"]
    token = create_access_token(
        identity="test@example.com",
        expires_delta=timedelta(days=7),
        additional_claims={"scopes": scopes}
    )
    return {"Authorization": f"Bearer {token}"}

#############################################
# Tests
#############################################


def test_spotify_micro_service_healthcheck(client):
    """
    Verify that the /spotify-micro-service/healthcheck endpoint returns a JSON
    response with status 'ok' and a service description including "Spotify Micro Service".
    """
    response = client.get("/spotify-micro-service/healthcheck")
    assert response.status_code == 200, "Expected status code 200 for healthcheck endpoint"
    data = response.get_json()
    assert data is not None, "Expected a JSON response"
    assert data.get("status") == "ok", "Expected status to be 'ok'"
    assert "Spotify Micro Service" in data.get("service", ""), "Expected service description to include 'Spotify Micro Service'"


def test_playlist_duration_success(monkeypatch, client, app):
    """
    Test the /playlist_duration endpoint for a valid POST request.
    Monkeypatch the calculate_playlist_duration function within the spotify_micro_service module
    to return a fake, predictable response.
    """
    # Patch the calculate_playlist_duration function in the spotify_micro_service namespace.
    # Adjust the patch target below to match your actual module path.
    monkeypatch.setattr("Blueprints.spotify_micro_service.calculate_playlist_duration", fake_calculate_playlist_duration)

    headers = get_spotify_auth_headers(app, scopes=["spotify"])
    payload = {
        "user_email": "test@example.com",  # This is used as the user identifier.
        "playlist_id": "fake_playlist_id"
    }
    response = client.post("/spotify-micro-service/playlist_duration", json=payload, headers=headers)
    assert response.status_code == 200, "Expected 200 OK for valid playlist duration request"
    data = response.get_json()
    assert data.get("playlist_id") == "fake_playlist_id", "Expected playlist_id to match the payload"
    assert data.get("total_duration_ms") == 3600000, "Expected 3600000 ms (1 hour) as total duration"
    assert data.get("formatted_duration") == "01:00:00", "Expected formatted duration '01:00:00'"
    assert data.get("total_track_count") == 10, "Expected total track count to be 10"


def test_playlist_duration_invalid_payload(client, app):
    """
    Test the /playlist_duration endpoint with an invalid payload (e.g., missing required fields).
    The endpoint should return a 400 error.
    """
    headers = get_spotify_auth_headers(app, scopes=["spotify"])
    response = client.post("/spotify-micro-service/playlist_duration", json={}, headers=headers)
    assert response.status_code == 400, "Expected 400 error for missing required fields in payload"


def test_playlist_duration_exception(monkeypatch, client, app):
    """
    Test that if calculate_playlist_duration raises an exception, the endpoint returns a 500 error.
    """
    def fake_exception(user_email, playlist_id):
        raise Exception("Simulated error")

    monkeypatch.setattr("Blueprints.spotify_micro_service.calculate_playlist_duration", fake_exception)

    headers = get_spotify_auth_headers(app, scopes=["spotify"])
    payload = {"user_email": "test@example.com", "playlist_id": "error_playlist"}
    response = client.post("/spotify-micro-service/playlist_duration", json=payload, headers=headers)
    assert response.status_code == 500, "Expected 500 Internal Server Error when exception is raised"
    data = response.get_json()
    assert "error" in data, "Expected an error message in the response"

#############################################
# End of tests/test_spotify_micro_service.py
#############################################


if __name__ == "__main__":
    pytest.main()
