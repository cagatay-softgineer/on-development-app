import os
import sys
import pytest

# Ensure repository root is in sys.path so that the 'util' module is importable.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from util.utils import (
    ms2FormattedDuration,
    obfuscate,
    get_email_username,
    load_JSONs,
)


def test_ms2FormattedDuration():
    # 0 ms => "00:00:00"
    assert ms2FormattedDuration(0) == "00:00:00"
    # 3661000 ms => 1 hour, 1 minute, 1 second
    assert ms2FormattedDuration(3661000) == "01:01:01"


def test_obfuscate():
    # Ensure the obfuscate function returns a string of 12 uppercase characters.
    result = obfuscate("test")
    assert isinstance(result, str)
    assert len(result) == 12
    assert result == result.upper()


def test_get_email_username():
    """Test extracting username from email."""
    assert get_email_username("user@example.com") == "user"
    assert get_email_username("invalid") is None


def test_load_jsons_success(monkeypatch):
    """Ensure load_JSONs writes json files when env vars are valid."""
    fb_json = '{"client_email": "test@example.com"}'
    google_json = '{"client_id": "id"}'
    monkeypatch.setenv("FIREBASE_CC_JSON", fb_json)
    monkeypatch.setenv("GOOGLE_CLIENT_SECRET_FILE", google_json)

    db_file = os.path.join(os.path.dirname(__file__), "..", "database", "fb-cc-test.json")
    key_file = os.path.join(os.path.dirname(__file__), "..", "keys", "client_secret_test.json")

    if os.path.exists(db_file):
        os.remove(db_file)
    if os.path.exists(key_file):
        os.remove(key_file)

    load_JSONs()

    assert os.path.exists(db_file)
    assert os.path.exists(key_file)


def test_load_jsons_invalid(monkeypatch):
    """load_JSONs should raise when FIREBASE_CC_JSON is invalid."""
    monkeypatch.setenv("FIREBASE_CC_JSON", "not-json")
    monkeypatch.setenv("GOOGLE_CLIENT_SECRET_FILE", "{}")
    with pytest.raises(ValueError):
        load_JSONs()


def test_load_jsons_missing(monkeypatch):
    """load_JSONs should raise when env var is missing."""
    monkeypatch.delenv("FIREBASE_CC_JSON", raising=False)
    monkeypatch.setenv("GOOGLE_CLIENT_SECRET_FILE", "{}")
    with pytest.raises(EnvironmentError):
        load_JSONs()


if __name__ == "__main__":
    pytest.main()
