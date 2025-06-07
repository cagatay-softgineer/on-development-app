# `env.` File
##### ====== CORE SECRETS ======
JWT_SECRET_KEY=your_jwt_secret_key
SECRET_KEY=your_flask_secret_key
SALT=your_custom_salt

##### ====== DEBUG & ENVIRONMENT ======
DEBUG_MODE=True

##### ====== SPOTIFY API ======
SPOTIFY_CLIENT_ID=your_spotify_client_id
SPOTIFY_CLIENT_SECRET=your_spotify_client_secret
AUTH_REDIRECT_URI=https://your-backend-domain.com/spotify/callback

##### ====== APPLE MUSIC API ======
APPLE_TEAM_ID=your_apple_team_id
APPLE_KEY_ID=your_apple_key_id
APPLE_PRIVATE_KEY_PATH=keys/AuthKey.p8
APPLE_DEVELOPER_TOKEN=your_apple_developer_token

##### ====== GOOGLE / YOUTUBE / OAUTH ======
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
GOOGLE_CLIENT_SECRET_FILE=google_client_secret.json

##### ====== MUSIXMATCH (LYRICS) ======
MUSIXMATCH_API_KEY=your_musixmatch_api_key

##### ====== FIREBASE JSON CREDENTIAL FILE (Path or base64 string) ======
FIREBASE_CC_JSON=keys/firebase-adminsdk.json

##### ====== FIREBASE CONFIGURATION (Client SDK, e.g. for front-end or admin API) ======
FIREBASECONFIG_APIKEY=your_firebase_api_key
FIREBASECONFIG_AUTHDOMAIN=your_project.firebaseapp.com
FIREBASECONFIG_PROJECTID=your_project_id
FIREBASECONFIG_STORAGEBUCKET=your_project.appspot.com
FIREBASECONFIG_MESSAGINGSENDERID=your_messaging_sender_id
FIREBASECONFIG_APPID=your_firebase_app_id
FIREBASECONFIG_MEASUREMENTID=your_measurement_id

##### ====== OPTIONAL (Logging, Custom CORS, etc.) ======
##### LOG_LEVEL=INFO
##### CORS_ALLOWED_ORIGINS=https://your-frontend-domain.com,https://another-frontend.com

