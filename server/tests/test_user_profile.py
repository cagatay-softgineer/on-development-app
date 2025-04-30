import sys
import os
from flask import Flask
import pytest
from datetime import timedelta
from flask_jwt_extended import JWTManager, create_access_token

# Prepend repository root so that "server" and other modules are importable.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from server import create_app

#############################################
# Fake Functions for Firebase Operations
#############################################


def fake_get_user_id_by_email(email):
    """Fake function that always returns a test user ID."""
    return "fake_user_id"


def fake_get_user_profile(user_id):
    """
    Fake function to simulate fetching a user profile.
    Returns a list containing one dictionary with test user details.
    """
    # For example, simulate that the user exists:
    return [{
        "first_name": "Mahmut",
        "last_name": "Tuncer",
        "avatar_url": "http://fake.url/avatar.jpg",
        "bio": "Test bio, Halay"
    }]


def fake_get_user_profile_empty(user_id):
    """Fake function that simulates no profile found, returning an empty list."""
    return [[]]

#############################################
# Fixtures and Helper Functions
#############################################


@pytest.fixture
def app():
    """
    Create a Flask app instance for testing.
    Initialize the JWTManager with a test secret key.
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


def get_me_auth_headers(app, scopes=None):
    """
    Helper function to generate Authorization headers with a JWT token
    that includes the "me" scope. Adjust scopes if necessary.
    """
    if scopes is None:
        scopes = ["me"]
    token = create_access_token(
        identity="test@example.com",
        expires_delta=timedelta(days=7),
        additional_claims={"scopes": scopes},
    )
    return {"Authorization": f"Bearer {token}"}

#############################################
# Tests for Profile Endpoints
#############################################


def test_profile_healthcheck(client):
    """
    Test the public /profile/healthcheck endpoint.
    It should return a JSON response containing status 'ok' and service 'Profile Service'.
    """
    response = client.get("/profile/healthcheck")
    assert response.status_code == 200, "Expected 200 OK for profile healthcheck"
    data = response.get_json()
    assert data is not None, "Expected JSON response"
    assert data.get("status") == "ok", "Expected healthcheck status 'ok'"
    assert "Profile Service" in data.get("service", ""), "Expected 'Profile Service' in service description"


def test_view_profile_success(monkeypatch, client, app):
    """
    Test the protected /profile/view endpoint with valid credentials and a simulated profile.
    Monkeypatch the Firebase operations so that:
      - get_user_id_by_email returns a fake user ID.
      - get_user_profile returns a fake profile list.
    """

    # Patch Firebase functions
    monkeypatch.setattr("database.firebase_operations.get_user_id_by_email", fake_get_user_id_by_email)
    monkeypatch.setattr("database.firebase_operations.get_user_profile", fake_get_user_profile)

    headers = get_me_auth_headers(app, scopes=["me"])
    response = client.get("/profile/view", headers=headers)
    assert response.status_code == 200, "Expected 200 OK for view_profile request"
    data = response.get_json()
    # Check that the response contains the key details from the fake profile
    assert data.get("first_name") == "Mahmut", "Expected first name 'Mahmut'"
    assert data.get("last_name") == "Tuncer", "Expected last name 'Tuncer'"
    assert "http" in data.get("avatar_url", ""), "Expected valid avatar_url"
    assert data.get("bio") == "Test bio, Halay", "Expected bio to match"


def test_view_profile_not_found(monkeypatch, client, app):
    """
    Test the /profile/view endpoint when no user profile is found.
    Simulate this by patching get_user_profile to return an empty list.
    The endpoint should return a 404 error.
    """
    monkeypatch.setattr("database.firebase_operations.get_user_id_by_email", fake_get_user_id_by_email)
    monkeypatch.setattr("database.firebase_operations.get_user_profile", fake_get_user_profile_empty)

    headers = get_me_auth_headers(app, scopes=["me"])
    response = client.get("/profile/view", headers=headers)
    # Expect a 404 when the returned profile list is empty (or its first element is empty).
    assert response.status_code == 404, "Expected 404 Not Found when profile is missing"
    data = response.get_json()
    assert "error" in data, "Expected an error message in the response"

#############################################
# End of tests/test_profile.py
#############################################


if __name__ == "__main__":
    pytest.main()
