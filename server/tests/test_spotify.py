# tests/test_spotify.py

import os
import sys
import pytest
from datetime import timedelta
from flask_jwt_extended import JWTManager, create_access_token

# Ensure the repository root is in the Python path so that modules (server, util, etc.) can be imported.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from server import create_app

#############################################
# Fake Implementations for Monkeypatching
#############################################

def fake_get_user_profile(user_id, *args, **kwargs):
    """
    Fake implementation of get_user_profile that returns a dummy profile.
    """
    return {
        "user_id": user_id,
        "display_name": "Fake Display Name",
        "email": "fake@example.com",
        "external_urls": {"spotify": "http://fake.spotify.url"},
        "images": [{"height": 640, "url": "http://fake.image.url", "width": 640}],
    }

def fake_fetch_user_playlists(user_id, app_id):
    """
    Fake implementation of fetch_user_playlists that returns a dummy playlist list.
    """
    return {"playlists": [{"id": "playlist1", "name": "Fake Playlist"}]}


#############################################
# Fixtures and Helper Functions
#############################################

@pytest.fixture
def app():
    """
    Create a Flask application instance for testing.
    Configure the app for testing, set the JWT secret key, and initialize JWTManager.
    """
    app = create_app(testing=True)
    app.config["JWT_SECRET_KEY"] = "test-secret"
    JWTManager(app)
    return app

@pytest.fixture
def client(app):
    """
    Create the test client within an active application context.
    """
    with app.test_client() as client:
        with app.app_context():
            yield client

def get_spotify_auth_headers(app, scopes=None):
    """
    Helper to generate an Authorization header with a JWT token containing the given scopes.
    Defaults to ["spotify"].
    """
    if scopes is None:
        scopes = ["spotify"]
    token = create_access_token(
        identity="test@example.com",
        expires_delta=timedelta(days=7),
        additional_claims={"scopes": scopes},
    )
    return {"Authorization": f"Bearer {token}"}

#############################################
# Tests for Spotify Blueprint Endpoints
#############################################

def test_spotify_healthcheck(client):
    """
    Test the /spotify/healthcheck endpoint.
    It should return 200 with JSON that includes status 'ok' and service 'Spotify Service'.
    """
    response = client.get("/spotify/healthcheck")
    assert response.status_code == 200, "Expected status 200 for healthcheck"
    data = response.get_json()
    assert data is not None, "Response should be JSON"
    assert data.get("status") == "ok", "Healthcheck status should be 'ok'"
    assert "Spotify Service" in data.get("service", ""), "Expected 'Spotify Service' in the response"

def test_spotify_login_authorized(client, app):
    """
    Test the /spotify/login/<user_id> endpoint with a valid JWT token (with 'spotify' scope).
    Since the endpoint generates a redirect URL (for Spotify’s auth flow), we expect a redirect.
    """
    headers = get_spotify_auth_headers(app, scopes=["spotify"])
    user_email = "test_user@example.com"
    response = client.get(f"/spotify/login/{user_email}", headers=headers)
    # The endpoint should issue a redirection to Spotify's authorization URL.
    # A redirect usually has a 302 status code.
    assert response.status_code in (302, 301), "Expected a redirect (302) for a valid login flow"
    # Optionally, check that the Location header is present.
    assert "Location" in response.headers, "Response should have a Location header for redirection"

def test_spotify_login_forbidden(client, app):
    """
    Test that calling /spotify/login/<user_id> with a JWT token lacking the 'spotify' scope returns 403.
    """
    headers = get_spotify_auth_headers(app, scopes=["not_spotify"])
    user_email = "test_user@example.com"
    response = client.get(f"/spotify/login/{user_email}", headers=headers)
    assert response.status_code == 403, "Expected 403 Forbidden when token lacks 'spotify' scope"

def test_spotify_user_profile(monkeypatch, client, app):
    """
    Test the /spotify/user_profile endpoint.
    Monkeypatch get_user_profile to return a fake profile.
    """

    # Patch get_user_profile in the spotify blueprint module to use our fake.
    monkeypatch.setattr("Blueprints.spotify.get_user_profile", fake_get_user_profile)
    
    headers = get_spotify_auth_headers(app, scopes=["spotify"])
    payload = {"user_email": "test_user@example.com"}
    response = client.post("/spotify/user_profile", json=payload, headers=headers)
    assert response.status_code == 200, "Expected 200 OK for user profile request"
    data = response.get_json()
    assert "display_name" in data, "Expected display_name in user profile"
    assert data.get("email") == "fake@example.com", "Expected fake email in profile"

def test_spotify_playlists(monkeypatch, client, app):
    """
    Test the /spotify/playlists endpoint.
    Monkeypatch fetch_user_playlists to simulate returning fake playlist data.
    """
    # Patch fetch_user_playlists to return fake data.
    monkeypatch.setattr("Blueprints.spotify.fetch_user_playlists", fake_fetch_user_playlists)
    
    headers = get_spotify_auth_headers(app, scopes=["spotify"])
    payload = {"user_email": "test_user@example.com"}
    response = client.post("/spotify/playlists", json=payload, headers=headers)
    assert response.status_code == 200, "Expected 200 OK for playlists request"
    data = response.get_json()
    assert "playlists" in data, "Expected playlists key in response"

def fake_get_user_id_by_email(email):
    """Fake function to simulate user lookup."""
    return "fake_user_id"

def fake_get_access_token_from_db(user_id, app_id):
    """
    Fake implementation that returns a list with a dictionary containing a fake access token 
    and fake refresh token.
    """
    return [{"access_token": "fake_access_token", "refresh_token": "fake_refresh_token"}]

def fake_test_token(access_token):
    """Fake test_token function: always returns 200 to avoid triggering recursion."""
    return 200

def test_spotify_callback_missing_code(client):
    """
    Test the /spotify/callback endpoint when no code parameter is provided.
    Expect a 400 error.
    """
    response = client.get("/spotify/callback")
    assert response.status_code == 400, "Expected 400 when 'code' parameter is missing"

#############################################
# End of tests/test_spotify.py
#############################################

if __name__ == "__main__":
    pytest.main()
