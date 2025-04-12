# config.py
from pydantic import BaseSettings, Field
import secrets

class Settings(BaseSettings):
    jwt_secret_key: str = Field(..., env="JWT_SECRET_KEY")
    spotify_client_id: str = Field(..., env="SPOTIFY_CLIENT_ID")
    spotify_client_secret: str = Field(..., env="SPOTIFY_CLIENT_SECRET")
    auth_redirect_uri: str = Field(..., env="AUTH_REDIRECT_URI")
    debug_mode: str = Field(default=False, env="DEBUG_MODE")
    salt: str = Field(..., env="SALT")
    musixmatch_API_KEY: str = Field(..., env="MUSIXMATCH_API_KEY")
    google_client_id: str = Field(..., env="GOOGLE_CLIENT_ID")
    google_client_secret: str = Field(..., env="GOOGLE_CLIENT_SECRET")
    google_client_secret_file: str = Field(..., env="GOOGLE_CLIENT_SECRET_FILE")
    SECRET_KEY: str = Field(default_factory=lambda: secrets.token_hex(16))
    apple_developer_token: str = Field(..., env="APPLE_DEVELOPER_TOKEN")
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()

class FirebaseConfig(BaseSettings):
    api_key: str = Field(..., env="FIREBASECONFIG_APIKEY")
    auth_domain: str = Field(..., env="FIREBASECONFIG_AUTHDOMAIN")
    project_id: str = Field(..., env="FIREBASECONFIG_PROJECTID")
    storage_bucket: str = Field(..., env="FIREBASECONFIG_STORAGEBUCKET")
    messaging_sender_id: str = Field(..., env="FIREBASECONFIG_MESSAGINGSENDERID")
    app_id: str = Field(..., env="FIREBASECONFIG_APPID")
    measurement_id: str = Field(..., env="FIREBASECONFIG_MEASUREMENTID")
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

firebase_config = FirebaseConfig()

# db = init_firebase(firebase_config)
# converter = SQLToFirestoreConverter(db, alias_map=sql2firebase.alias_map)