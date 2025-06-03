import os
import sys
from unittest.mock import Mock

# Ensure the server package and root are on sys.path
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, BASE_DIR)
sys.path.insert(0, os.path.join(BASE_DIR, 'server'))

# Set dummy environment variables required by the app during import
os.environ.setdefault("FIREBASE_CC_JSON", '{"type": "service_account", "client_email": "fake@example.com"}')
os.environ.setdefault("GOOGLE_CLIENT_SECRET_FILE", '{}')
os.environ.setdefault("APPLE_PRIVATE_KEY", 'FAKE')
os.environ.setdefault("APPLE_PRIVATE_KEY_PATH", 'keys/fake_key.p8')

# Settings required by config.Settings
os.environ.setdefault("JWT_SECRET_KEY", "test")
os.environ.setdefault("SPOTIFY_CLIENT_ID", "id")
os.environ.setdefault("SPOTIFY_CLIENT_SECRET", "secret")
os.environ.setdefault("AUTH_REDIRECT_URI", "http://example.com")
os.environ.setdefault("SALT", "salt")
os.environ.setdefault("MUSIXMATCH_API_KEY", "key")
os.environ.setdefault("GOOGLE_CLIENT_ID", "id")
os.environ.setdefault("GOOGLE_CLIENT_SECRET", "secret")
os.environ.setdefault("APPLE_TEAM_ID", "team")
os.environ.setdefault("APPLE_KEY_ID", "key")
os.environ.setdefault("APPLE_DEVELOPER_TOKEN", "token")
os.environ.setdefault("FIREBASECONFIG_APIKEY", "api")
os.environ.setdefault("FIREBASECONFIG_AUTHDOMAIN", "domain")
os.environ.setdefault("FIREBASECONFIG_PROJECTID", "project")
os.environ.setdefault("FIREBASECONFIG_STORAGEBUCKET", "bucket")
os.environ.setdefault("FIREBASECONFIG_MESSAGINGSENDERID", "sender")
os.environ.setdefault("FIREBASECONFIG_APPID", "appid")
os.environ.setdefault("FIREBASECONFIG_MEASUREMENTID", "measure")

# Patch firebase_admin to avoid requiring valid credentials
import firebase_admin
from firebase_admin import credentials, firestore

credentials.Certificate = lambda *args, **kwargs: Mock()
firebase_admin.initialize_app = lambda *args, **kwargs: Mock()
firestore.client = lambda *args, **kwargs: Mock()

# Ensure settings has debug_mode attribute for blueprints that access it
try:
    import config.config as config_module
    if not hasattr(config_module.settings, 'debug_mode'):
        object.__setattr__(config_module.settings, 'debug_mode', 'False')
except Exception:
    pass
