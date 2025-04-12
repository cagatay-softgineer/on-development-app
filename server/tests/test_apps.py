# tests/test_apps.py


import sys
import os
import pytest
from flask_jwt_extended import JWTManager, create_access_token

# Prepend repository root so imports for 'server' and 'util' work correctly.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from server import create_app  # Ensure your app factory is defined here

@pytest.fixture
def app():
    """
    Create a Flask app instance for testing.
    Set the 'TESTING' flag and initialize the JWTManager to support JWT-protected endpoints.
    """
    app = create_app(testing=True)
    app.config["JWT_SECRET_KEY"] = "test-secret"  # Use a simple secret for tests
    JWTManager(app)
    return app


@pytest.fixture
def client(app):
    """
    Create a test client with an active application context.
    """
    with app.test_client() as client:
        with app.app_context():
            yield client


def get_auth_headers(app, scopes=None):
    """
    Helper function to generate the Authorization header with a JWT token.
    :param scopes: List of scopes to include; defaults to ["apps"].
    :return: A dictionary with the Authorization header.
    """
    if scopes is None:
        scopes = ["apps"]
    token = create_access_token(identity="test@example.com", additional_claims={"scopes": scopes})
    return {"Authorization": f"Bearer {token}"}


#############################################
# Fake Implementations for Dependency Mocking
#############################################

def fake_get_user_id_by_email(email):
    """Simulate the Firebase user lookup."""
    return "fake_user_id"


def fake_get_app_id_by_name(app_name):
    """Simulate retrieval of an app ID from Firebase based on the app name."""
    mapping = {"Spotify": 1, "AppleMusic": 2, "YoutubeMusic": 3, "Google API": 4}
    return mapping.get(app_name, None)


def fake_get_userlinkedapps_tokens(user_id, app_id):
    """Simulate retrieval of user token data; returns a fake token."""
    return [{"access_token": ["fake_access_token"]}]


def fake_get_current_user_profile(access_token, user_id, app_id):
    """Simulate fetching a user profile for an app (e.g., Spotify)."""
    return {"profile": "fake_profile"}


def fake_get_google_profile(user_email):
    """Simulate fetching a Google profile for a given email."""
    return {"profile": "fake_google_profile"}


def fake_get_email_username(user_email):
    """Extract a simple username from the email address."""
    return user_email.split("@")[0]


#############################################
# Tests for apps endpoints
#############################################

def test_apps_healthcheck(client):
    """
    Verify that the /apps/healthcheck endpoint returns a JSON with status 'ok'
    and the expected service description.
    """
    response = client.get("/apps/healthcheck")
    assert response.status_code == 200, "Expected status 200 for apps healthcheck"
    data = response.get_json()
    assert data["status"] == "ok"
    assert "Apps Service" in data["service"]


def test_check_linked_app_valid_payload(client, app, monkeypatch):
    """
    Test the /apps/check_linked_app endpoint with a valid payload.
    Monkeypatch external dependencies to return fake values.
    """
    headers = get_auth_headers(app, scopes=["apps"])

    monkeypatch.setattr("database.firebase_operations.get_user_id_by_email", fake_get_user_id_by_email)
    monkeypatch.setattr("database.firebase_operations.get_app_id_by_name", fake_get_app_id_by_name)
    monkeypatch.setattr("database.firebase_operations.get_userlinkedapps_tokens", fake_get_userlinkedapps_tokens)
    # Patch the external functions called in the endpoint.
    monkeypatch.setattr("Blueprints.apps.get_current_user_profile", fake_get_current_user_profile)
    monkeypatch.setattr("util.utils.get_email_username", fake_get_email_username)
    monkeypatch.setattr("Blueprints.apps.get_google_profile", fake_get_google_profile)

    payload = {"app_name": "Spotify", "user_email": "test@example.com"}
    response = client.post("/apps/check_linked_app", json=payload, headers=headers)

    assert response.status_code == 200, "Expected 200 for valid payload"
    data = response.get_json()
    assert data["user_linked"] is True, "Expected user_linked to be True"
    assert data["user_profile"] == {"profile": "fake_profile"}


def test_check_linked_app_missing_payload(client, app):
    """
    Test that posting an empty JSON payload to /apps/check_linked_app returns a 400 error.
    """
    headers = get_auth_headers(app, scopes=["apps"])
    response = client.post("/apps/check_linked_app", json={}, headers=headers)
    assert response.status_code == 400, "Expected 400 for missing required fields in payload"
    data = response.get_json()
    assert "error" in data


def test_unlink_app(client, app, monkeypatch):
    """
    Test the /apps/unlink_app endpoint by simulating correct payload and successful deletion.
    """
    headers = get_auth_headers(app, scopes=["apps"])

    monkeypatch.setattr("database.firebase_operations.get_user_id_by_email", fake_get_user_id_by_email)
    monkeypatch.setattr("database.firebase_operations.get_app_id_by_name", fake_get_app_id_by_name)
    # For deletion, simulate a no-op.
    monkeypatch.setattr("database.firebase_operations.delete_userlinkedapps", lambda user_id, app_id: None)

    payload = {"app_name": "Spotify", "user_email": "test@example.com"}
    response = client.post("/apps/unlink_app", json=payload, headers=headers)
    assert response.status_code == 201, "Expected 201 on successful unlink"
    data = response.get_json()
    assert "App Unlinked!" in data["message"]


def test_get_all_apps_binding(client, app, monkeypatch):
    """
    Test the /apps/get_all_apps_binding endpoint.
    This endpoint should return a list of apps with binding status and profiles.
    """
    headers = get_auth_headers(app, scopes=["apps"])

    monkeypatch.setattr("database.firebase_operations.get_user_id_by_email", fake_get_user_id_by_email)
    monkeypatch.setattr("database.firebase_operations.get_app_id_by_name", fake_get_app_id_by_name)
    monkeypatch.setattr("database.firebase_operations.get_userlinkedapps_tokens", fake_get_userlinkedapps_tokens)
    monkeypatch.setattr("Blueprints.apps.get_current_user_profile", fake_get_current_user_profile)
    monkeypatch.setattr("util.utils.get_email_username", fake_get_email_username)
    monkeypatch.setattr("Blueprints.apps.get_google_profile", fake_get_google_profile)

    payload = {"user_email": "test@example.com"}
    response = client.post("/apps/get_all_apps_binding", json=payload, headers=headers)
    assert response.status_code == 200, "Expected 200 for valid get_all_apps_binding request"
    data = response.get_json()
    assert "user_email" in data
    assert "apps" in data
    for app_status in data["apps"]:
        assert "app_name" in app_status
        assert "user_linked" in app_status
        assert "user_profile" in app_status


if __name__ == "__main__":
    pytest.main()
