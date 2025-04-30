from flask import Flask
from flask_swagger_ui import get_swaggerui_blueprint
from Blueprints.auth import auth_bp
from Blueprints.utilx import util_bp
from Blueprints.apps import apps_bp
from Blueprints.spotify import spotify_bp
from Blueprints.apple import apple_bp
from Blueprints.apple_music import appleMusic_bp
from Blueprints.user_profile import profile_bp
from Blueprints.google_api import google_bp
from Blueprints.spotify_micro_service import SpotifyMicroService_bp
from Blueprints.lyrics import lyrics_bp
from Blueprints.youtube_music import youtubeMusic_bp

def register_blueprints(app:Flask, testing=False):

        # Swagger documentation setup
    swaggerui_blueprint = get_swaggerui_blueprint(
        app.config["SWAGGER_URL"],
        app.config["API_URL"],
        config={"app_name": "Micro Service"},
    )

    app.register_blueprint(auth_bp, url_prefix="/auth")
    app.register_blueprint(apps_bp, url_prefix="/apps")
    app.register_blueprint(spotify_bp, url_prefix="/spotify")
    app.register_blueprint(profile_bp, url_prefix="/profile")
    app.register_blueprint(
        SpotifyMicroService_bp,
        url_prefix="/spotify-micro-service")
    app.register_blueprint(lyrics_bp, url_prefix="/lyrics")
    app.register_blueprint(google_bp, url_prefix="/google")
    app.register_blueprint(youtubeMusic_bp, url_prefix="/youtube-music")
    app.register_blueprint(apple_bp, url_prefix="/apple")
    app.register_blueprint(appleMusic_bp, url_prefix="/apple-music")
    app.register_blueprint(
        swaggerui_blueprint,
        url_prefix=app.config["SWAGGER_URL"])

    app.register_blueprint(util_bp, url_prefix="/")

    return app