# config.py
from pydantic import BaseSettings, Field

class Settings(BaseSettings):
    jwt_secret_key: str = Field(..., env="JWT_SECRET_KEY")
    sql_server_host: str = Field(..., env="SQL_SERVER_HOST")
    sql_server_port: str = Field(..., env="SQL_SERVER_PORT")
    sql_server_database: str = Field(..., env="SQL_SERVER_DATABASE")
    sql_server_user: str = Field(..., env="SQL_SERVER_USER")
    sql_server_password: str = Field(..., env="SQL_SERVER_PASSWORD")
    secondary_sql_database: str = Field(..., env="SSQL_SERVER_DATABASE")
    spotify_client_id: str = Field(..., env="SPOTIFY_CLIENT_ID")
    spotify_client_secret: str = Field(..., env="SPOTIFY_CLIENT_SECRET")
    auth_redirect_uri: str = Field(..., env="AUTH_REDIRECT_URI")
    debug_mode: str = Field(default=False, env="DEBUG_MODE")
    salt: str = Field(..., env="SALT")

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()
