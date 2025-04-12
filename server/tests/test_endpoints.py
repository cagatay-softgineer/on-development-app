# tests/test_endpoints.py

import sys
import os
import pytest
from flask_jwt_extended import JWTManager, create_access_token

# Prepend repository root so that "server" and "util" modules are importable.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from server import create_app

############################################
# Fixtures and helper functions
############################################

@pytest.fixture
def app():
    """
    Create a Flask application instance for testing.
    Initializes the JWTManager so that JWT-dependent endpoints can be tested.
    """
    app = create_app(testing=True)
    app.config["JWT_SECRET_KEY"] = "test-secret"
    JWTManager(app)
    return app

@pytest.fixture
def client(app):
    """
    Create the Flask test client within an application context.
    """
    with app.test_client() as client:
        with app.app_context():
            yield client

def get_admin_auth_headers(app):
    """
    Helper function to generate JWT Authorization headers containing the admin scope.
    """
    token = create_access_token(
        identity="admin@example.com",
        additional_claims={"scopes": ["admin"]}
    )
    return {"Authorization": f"Bearer {token}"}

############################################
# Tests for Endpoints (Util Blueprint)
############################################

def test_app_healthcheck(client):
    """
    Test the /healthcheck endpoint defined in utilx (or util blueprint).
    This endpoint should return JSON with status 'ok' and service 'App Service'.
    """
    # Note: The endpoint supports both POST and GET; here we test GET.
    response = client.get("/healthcheck")
    assert response.status_code == 200, "Expected status 200 for app healthcheck"
    data = response.get_json()
    assert data.get("status") == "ok", "Expected health status 'ok'"
    assert "App Service" in data.get("service", ""), "Expected 'App Service' in service description"


def test_visualize_logs_without_auth(client):
    """
    Test the /logs endpoint without JWT authorization.
    The endpoint is protected with requires_scope("admin"), so it should error.
    """
    response = client.get("/logs")
    # Since there's no token, this should result in an error (often 401 or 403).
    assert response.status_code in (401, 403), (
        f"Expected unauthorized or forbidden error without token, got {response.status_code}"
    )


def test_visualize_logs_with_auth(monkeypatch, client, app):
    """
    Test the /logs endpoint with proper admin authorization.
    Monkeypatch parse_logs_from_folder to return a controlled list of logs.
    """
    # Create fake logs data
    fake_logs = [
        {"filename": "app.log", "timestamp": "2023-01-01 12:00:00,000", "log_type": "INFO", "message": "Test log 1"},
        {"filename": "app.log", "timestamp": "2023-01-01 13:00:00,000", "log_type": "ERROR", "message": "Test log 2"},
    ]
    
    # Monkeypatch the parse_logs_from_folder function in utilx module to return fake logs.
    monkeypatch.setattr("util.utils.parse_logs_from_folder", lambda folder: fake_logs)
    
    headers = get_admin_auth_headers(app)
    response = client.get("/logs", headers=headers, query_string={"page": "1", "per_page": "1"})
    # Since this endpoint renders a template, we can check for status 200 and HTML content.
    assert response.status_code == 200, "Expected 200 for authorized logs visualization"
    # For example, check that some part of the HTML template is present.
    assert b"<html" in response.data.lower(), "Expected HTML output in response"


def test_logs_trend_chart(client, app, monkeypatch):
    """
    Test the /logs/trend endpoint with admin authorization.
    Monkeypatch parse_logs_to_dataframe to return a non-empty DataFrame.
    """
    import pandas as pd
    from datetime import datetime

    # Create a fake DataFrame with timestamp and log_type columns.
    fake_data = pd.DataFrame({
        "timestamp": [datetime(2023, 1, 1, 12, 0), datetime(2023, 1, 1, 13, 0)],
        "log_type": ["INFO", "ERROR"]
    })
    monkeypatch.setattr("util.utils.parse_logs_to_dataframe", lambda folder: fake_data)
    
    headers = get_admin_auth_headers(app)
    response = client.get("/logs/trend", headers=headers)
    # Endpoint should return a rendered template (200 status); check for HTML markers.
    assert response.status_code == 200, "Expected 200 for logs trend chart endpoint"
    assert b"<html" in response.data.lower(), "Expected HTML output for trend chart"


def test_list_endpoints_json(client, app, monkeypatch):
    """
    Test the /endpoints endpoint by simulating filtering and verifying the JSON output.
    Monkeypatch route_descriptions if necessary.
    """
    # Monkeypatching route_descriptions dictionary to include a fake description.
    monkeypatch.setattr("util.utils.route_descriptions", {"/fake": "Fake route for testing"})
    
    headers = get_admin_auth_headers(app)
    # Simulate a GET request with query parameters: format=json
    response = client.get("/endpoints", headers=headers, query_string={"format": "json"})
    assert response.status_code == 200, "Expected 200 for endpoints listing"
    
    data = response.get_json()
    # Check that metadata and endpoints keys are present
    assert "metadata" in data, "Expected 'metadata' in JSON response"
    assert "endpoints" in data, "Expected 'endpoints' in JSON response"
    # Optionally, check that the endpoints list is a list type.
    assert isinstance(data["endpoints"], list), "Expected endpoints to be a list"

############################################
# End of test_endpoints.py
############################################

if __name__ == "__main__":
    pytest.main()
