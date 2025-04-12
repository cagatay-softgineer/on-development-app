# tests/test_auth.py

import sys
import os
import pytest
from datetime import timedelta
from flask_jwt_extended import JWTManager, create_access_token, create_refresh_token

# Prepend the repository root so that imports for "server" and other modules work.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from server import create_app  # Make sure your create_app() function is defined in server/__init__.py or server.py
import bcrypt

#########################################
# Fake functions for Firebase simulation
#########################################

def fake_insert_user(email, password):
    # Simply simulate a successful insertion (do nothing)
    pass

def fake_get_user_password_and_email(email):
    # Return a fake record with email as user_id and a bcrypt-hashed password.
    # For testing, if the plain password is "test123", hash it.
    fake_password = "test123"
    hashed = bcrypt.hashpw(fake_password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")
    # Return a list with one dictionary (simulate database record)
    return [{"email": email, "password": hashed}]

#########################################
# Application and Test Client Fixtures
#########################################

@pytest.fixture
def app():
    """
    Create a Flask application instance for testing. Initialize JWTManager so that
    endpoints protected by JWT work. Set a simple JWT_SECRET_KEY.
    """
    app = create_app(testing=True)
    app.config["JWT_SECRET_KEY"] = "test-secret"
    JWTManager(app)
    return app

@pytest.fixture
def client(app):
    """
    Create the test client inside an application context.
    """
    with app.test_client() as client:
        with app.app_context():
            yield client

#########################################
# Helper to Generate Auth Headers
#########################################

def get_auth_headers(app, scopes=None, refresh=False):
    """
    Generate an Authorization header containing a JWT token.
    
    :param scopes: List of scopes to include in the token.
    :param refresh: If True, generate a refresh token instead.
    :return: Dictionary with the "Authorization" header.
    """
    if scopes is None:
        scopes = ["auth"]  # default scope for auth endpoints; adjust as needed

    if refresh:
        token = create_refresh_token(identity="test@example.com", expires_delta=timedelta(days=30))
    else:
        # For login protection in endpoints (if any)
        token = create_access_token(
            identity="test@example.com",
            expires_delta=timedelta(days=7),
            additional_claims={"scopes": scopes},
        )
    return {"Authorization": f"Bearer {token}"}

#########################################
# Tests for Auth Blueprint Endpoints
#########################################

def test_auth_healthcheck(client):
    """
    Test the /auth/healthcheck endpoint.
    """
    response = client.get("/auth/healthcheck")
    assert response.status_code == 200, "Expected 200 OK for auth healthcheck"
    data = response.get_json()
    assert data is not None, "Expected JSON response"
    assert data["status"] == "ok", "Expected health status 'ok'"
    assert "Auth Service" in data["service"], "Expected 'Auth Service' in response service info"


def test_register_valid_payload(client, monkeypatch):
    """
    Test the /auth/register endpoint with a valid payload.
    Monkeypatch firebase_operations.insert_user to simulate successful insertion.
    """
    monkeypatch.setattr("database.firebase_operations.insert_user", fake_insert_user)
    
    payload = {"email": "test@example.com", "password": "test123"}
    response = client.post("/auth/register", json=payload)
    
    assert response.status_code == 201, "Expected 201 Created for valid registration"
    data = response.get_json()
    assert data["message"] == "User registered successfully"


def test_register_invalid_payload(client):
    """
    Test the /auth/register endpoint with an invalid payload (e.g., missing required fields)
    """
    # Passing an empty payload will cause a ValidationError
    response = client.post("/auth/register", json={})
    assert response.status_code == 400, "Expected 400 for invalid registration payload"
    data = response.get_json()
    assert "error" in data, "Expected an error message in the response"


def test_login_valid_credentials(client, monkeypatch):
    """
    Test the /auth/login endpoint with valid credentials.
    Monkeypatch firebase_operations.get_user_password_and_email to return a fake user record.
    """
    monkeypatch.setattr("database.firebase_operations.get_user_password_and_email", fake_get_user_password_and_email)
    
    payload = {"email": "test@example.com", "password": "test123"}
    response = client.post("/auth/login", json=payload)
    
    assert response.status_code == 200, "Expected 200 OK for valid login"
    data = response.get_json()
    assert "access_token" in data, "Expected an access token in the response"
    assert "refresh_token" in data, "Expected a refresh token in the response"
    assert "user_id" in data, "Expected a user_id in the response"


def test_login_invalid_credentials(client, monkeypatch):
    """
    Test the /auth/login endpoint with invalid credentials.
    Monkeypatch firebase_operations.get_user_password_and_email to return a fake record but use a wrong password.
    """
    monkeypatch.setattr("database.firebase_operations.get_user_password_and_email", fake_get_user_password_and_email)
    
    payload = {"email": "test@example.com", "password": "wrongpassword"}
    response = client.post("/auth/login", json=payload)
    
    assert response.status_code == 401, "Expected 401 Unauthorized for invalid credentials"
    data = response.get_json()
    assert "error" in data, "Expected an error message in the response"


def test_refresh_token(client, app):
    """
    Test the /auth/refresh endpoint which requires a valid refresh token.
    """
    # First, create a refresh token for the test identity.
    refresh_token = create_refresh_token(identity="test@example.com", expires_delta=timedelta(days=30))
    headers = {"Authorization": f"Bearer {refresh_token}"}

    response = client.post("/auth/refresh", headers=headers)
    assert response.status_code == 200, "Expected 200 OK for token refresh"
    data = response.get_json()
    assert "access_token" in data, "Expected a new access token in the refresh response"


#########################################
# End of Test File
#########################################

if __name__ == "__main__":
    pytest.main()
