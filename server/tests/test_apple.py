# tests/test_apple.py

import sys
import os
from flask import Flask
import pytest
from flask_jwt_extended import create_access_token

# Prepend the repository root so that "server" and "util" modules are importable.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from server import create_app  # Ensure that create_app is defined in server/__init__.py or server.py


@pytest.fixture
def app():
    """
    Create a Flask app instance for testing. Ensure that a JWT secret key is set
    so that tokens can be generated.
    """
    app = Flask(__name__)
    app = create_app(app, testing=True)
    app.config["JWT_SECRET_KEY"] = "test-secret"
    return app


@pytest.fixture
def client(app):
    """
    Create a test client with an active application context.
    This ensures that decorators and functions that require context (like JWT checks)
    work as expected.
    """
    with app.test_client() as client:
        with app.app_context():
            yield client


def get_auth_headers(app, scopes=None):
    """
    Helper function to generate Authorization headers with a JWT token.

    :param scopes: List of scopes to embed in the token. Defaults to ["apple"].
    :return: Dictionary with an Authorization header.
    """
    if scopes is None:
        scopes = ["apple"]
    token = create_access_token(identity="test@example.com", additional_claims={"scopes": scopes})
    return {"Authorization": f"Bearer {token}"}


def test_apple_healthcheck(client):
    """
    Verify that the /apple/healthcheck endpoint returns a JSON response with status 'ok'
    and a service description that includes "Apple Service".
    """
    response = client.get("/apple/healthcheck")
    assert response.status_code == 200, "Expected status code 200 for healthcheck endpoint"

    data = response.get_json()
    assert data is not None, "Response should be valid JSON"
    assert "status" in data, "JSON response should contain 'status'"
    assert "service" in data, "JSON response should contain 'service'"
    assert data["status"] == "ok", f"Expected status 'ok', got {data['status']}"
    assert "Apple" in data["service"], f"Expected 'Apple' in service description, got {data['service']}"

# def test_apple_login_authorized(client, app):
#    """
#    Test /apple/login/<user_id> with a valid JWT (with "apple" scope).
#    The endpoint is expected to render the Apple Music login page with the appropriate developer token.
#    """
#    headers = get_auth_headers(app, scopes=["apple"])
#    user_id = "cagatayalkan333@gmail.com"
#    response = client.get(f"/apple/login/{user_id}", headers=headers)
#
#    # Since the endpoint renders an HTML template, we expect a 200 status.
#    assert response.status_code == 200, "Expected status 200 for authorized login"
#    # Check that the response contains the developer token or user_id.
#    assert b"developer_token" in response.data or user_id.encode() in response.data, (
#        "Response should contain developer token or provided user ID"
#    )


# def test_apple_login_forbidden(client, app):
#     """
#     Test /apple/login/<user_id> with a token lacking the "apple" scope.
#     Should return a 403 Forbidden error.
#     """
#     headers = get_auth_headers(app, scopes=["not-apple"])
#     user_id = "test_user"
#     response = client.get(f"/apple/login/{user_id}", headers=headers)
#     assert response.status_code == 403, "Expected 403 for token missing the 'apple' scope"


def test_apple_callback_missing_user_token(client):
    """
    Ensure that calling /apple/callback without a 'user_token' parameter returns a 400 error.
    """
    response = client.get("/apple/callback")
    assert response.status_code == 400, "Expected 400 when 'user_token' query parameter is missing"


def test_get_token_missing_payload(client, app):
    """
    Test that POSTing to /apple/token with an empty JSON payload returns a 400 error.
    """
    headers = get_auth_headers(app, scopes=["apple"])
    response = client.post("/apple/token", json={}, headers=headers)
    assert response.status_code == 400, "Expected 400 for missing 'user_email' field in payload"


def fake_get_user_id_by_email(email):
    """Fake function to simulate Firebase user lookup."""
    return "fake_user_id"


def fake_get_userlinkedapps_tokens(user_id, app_id):
    """Fake function to simulate retrieval of user tokens from the database."""
    return [{"access_token": "fake_access_token"}]


def test_get_token_valid_payload(client, app, monkeypatch):
    """
    Test that /apple/token returns a token when provided a valid payload.
    This test uses monkeypatching to simulate Firebase operations.
    """
    headers = get_auth_headers(app, scopes=["apple"])

    # Monkey-patch the database calls.
    monkeypatch.setattr("database.firebase_operations.get_user_id_by_email", fake_get_user_id_by_email)
    monkeypatch.setattr("database.firebase_operations.get_userlinkedapps_tokens", fake_get_userlinkedapps_tokens)

    payload = {"user_email": "cagatayalkan333@gmail.com"}
    response = client.post("/apple/token", json=payload, headers=headers)

    assert response.status_code == 200, "Expected 200 for valid token request"
    data = response.get_json()
    assert "token" in data, "Response JSON should include 'token'"
    assert data["token"] == "fake_access_token", "The token should match the fake token value"


def test_get_library_missing_payload(client, app):
    """
    Test that POSTing to /apple/library with an empty payload returns a 400 error.
    """
    headers = get_auth_headers(app, scopes=["apple"])
    response = client.post("/apple/library", json={}, headers=headers)
    assert response.status_code == 400, "Expected 400 for missing 'user_email' field in payload"


if __name__ == "__main__":
    pytest.main()
