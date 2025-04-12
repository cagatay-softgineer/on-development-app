# tests/test_lyrics.py

from flask_jwt_extended import JWTManager, create_access_token
import sys
import os
import pytest
from datetime import timedelta

# Prepend repository root so that "server" and other modules are importable.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from server import create_app

#############################################
# Fixtures and Helper Functions
#############################################


@pytest.fixture
def app():
    """
    Create a Flask app instance for testing.
    Initialize the JWTManager so that JWT-protected endpoints work.
    """
    app = create_app(testing=True)
    app.config["JWT_SECRET_KEY"] = "test-secret"
    JWTManager(app)
    return app


@pytest.fixture
def client(app):
    """
    Create the test client using the app's test_client within an application context.
    """
    with app.test_client() as client:
        with app.app_context():
            yield client


def get_auth_headers(app, scopes=None):
    """
    Helper function to generate Authorization headers containing a JWT token.
    The token will include the provided scopes.

    :param scopes: List of scopes (default is ["lyrics"])
    :return: A dictionary with the Authorization header.
    """
    if scopes is None:
        scopes = ["lyrics"]
    token = create_access_token(
        identity="test@example.com",
        expires_delta=timedelta(days=7),
        additional_claims={"scopes": scopes},
    )
    return {"Authorization": f"Bearer {token}"}

#############################################
# Fake Response for Monkeypatching
#############################################


class FakeResponse:
    def __init__(self, json_data, status_code):
        self._json = json_data
        self.status_code = status_code

    def json(self):
        return self._json

#############################################
# Tests for the Lyrics Blueprint
#############################################


def test_lyrics_healthcheck(client):
    """
    Test the public /lyrics/healthcheck endpoint. It should return JSON with status 'ok'
    and indicate the service is "Lyrics Service".
    """
    response = client.get("/lyrics/healthcheck")
    assert response.status_code == 200, "Healthcheck should return 200 OK"
    data = response.get_json()
    assert data is not None, "Expected a JSON response"
    assert data.get("status") == "ok", "Status should be 'ok'"
    assert "Lyrics Service" in data.get("service", ""), "Service description should mention 'Lyrics Service'"


def test_get_lyrics_missing_parameters(client, app):
    """
    Test the /lyrics/get endpoint with missing query parameters.
    Since both 'track' and 'artist' are required, a missing parameter should return a 400 error.
    """
    # The /get endpoint is protected, so include a valid JWT with 'lyrics' scope.
    headers = get_auth_headers(app, scopes=["lyrics"])
    # Call without query parameters
    response = client.get("/lyrics/get", headers=headers)
    # We expect a 400 error because either 'track' or 'artist' is missing.
    assert response.status_code == 400, "Expected 400 error when required parameters are missing"


def test_get_lyrics_success(monkeypatch, client, app):
    """
    Test the /lyrics/get endpoint when a valid track and artist are provided.
    Monkeypatch requests.get to simulate a successful response from the Musixmatch API.
    """
    headers = get_auth_headers(app, scopes=["lyrics"])
    # Define a fake API response that mimics Musixmatch response structure.
    fake_api_json = {
        "message": {
            "body": {
                "lyrics": {
                    "lyrics_body": "These are fake lyrics. \n...",
                    "explicit": 0
                }
            }
        }
    }
    fake_response = FakeResponse(json_data=fake_api_json, status_code=200)

    def fake_requests_get(url, params=None):
        # You can add assertions on url and params if necessary.
        return fake_response

    # Monkeypatch the requests.get used in the get_lyrics endpoint.
    monkeypatch.setattr("requests.get", fake_requests_get)
    # Alternatively, if the function is imported elsewhere, adjust the module path accordingly,
    # e.g., monkeypatch.setattr("util.lyrics.requests.get", fake_requests_get)

    # Provide query parameters for a valid request.
    query_params = {"track": "Fake Track", "artist": "Fake Artist"}
    response = client.get("/lyrics/get", headers=headers, query_string=query_params)
    # Expect a 200 response and that the response contains our fake lyrics.
    assert response.status_code == 200, "Expected 200 OK for valid track/artist request"
    data = response.get_json()
    assert "lyrics_body" in data, "Response JSON should contain 'lyrics_body'"
    assert "fake lyrics" in data["lyrics_body"].lower(), "The fake lyrics should be present"


def test_get_lyrics_api_failure(monkeypatch, client, app):
    """
    Test the /lyrics/get endpoint when the external API returns an error.
    Monkeypatch requests.get to return a non-200 status code.
    """
    headers = get_auth_headers(app, scopes=["lyrics"])

    def fake_requests_get(url, params=None):
        # Return a fake response with an error status (e.g., 500)
        return FakeResponse(json_data={"error": "Something went wrong"}, status_code=500)

    monkeypatch.setattr("requests.get", fake_requests_get)
    query_params = {"track": "Fake Track", "artist": "Fake Artist"}
    response = client.get("/lyrics/get", headers=headers, query_string=query_params)
    # Expect that our endpoint passes along the error status code from the external call.
    assert response.status_code == 500, "Expected 500 when external API returns an error"


#############################################
# End of tests/test_lyrics.py
#############################################

if __name__ == "__main__":
    pytest.main()
