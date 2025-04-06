try:
    # Code that may trigger the error
    from util.error_handling import log_error
    import flask
    from flask import Flask, jsonify, render_template, request
    from flask_jwt_extended import JWTManager
    from flask_limiter import Limiter
    from flask_swagger_ui import get_swaggerui_blueprint
    from cmd_gui_kit import CmdGUI
    from flask_cors import CORS
    from util.utils import route_descriptions, parse_logs_from_folder, parse_logs_to_dataframe
    from util.logit import get_logger, check_log_folder
    from Blueprints.auth import auth_bp
    from Blueprints.apps import apps_bp
    from Blueprints.spotify import spotify_bp
    from Blueprints.apple import apple_bp
    from Blueprints.apple_music import appleMusic_bp
    from Blueprints.user_profile import profile_bp
    from Blueprints.google_api import google_bp
    from Blueprints.spotify_micro_service import SpotifyMicroService_bp
    from Blueprints.lyrics import lyrics_bp
    from Blueprints.youtube_music import youtubeMusic_bp
    import pandas as pd
    import argparse
    from config.config import settings
    import json
    import plotly.graph_objects as go
    from plotly.utils import PlotlyJSONEncoder
    #from IPython.core.display import display  # This import may fail  # noqa: F401
except Exception as e:
    log_error(e)  # Log the error

print(settings.google_client_secret_file)

check_log_folder()

gui = CmdGUI()

app = Flask(__name__)

app.config['JWT_SECRET_KEY'] = settings.jwt_secret_key
app.config['SWAGGER_URL'] = '/api/docs'
app.config['API_URL'] = '/static/swagger.json'
app.config['SECRET_KEY'] = settings.SECRET_KEY
app.config['PREFERRED_URL_SCHEME'] = 'https'

jwt = JWTManager(app)
limiter = Limiter(app)

CORS(app, resources={r"/*": {"origins": "*"}})

# Add logging to the root logger
logger = get_logger("logs/service.log","Service")

# Middleware to log all requests
def log_request():
    """
    Logs the incoming HTTP request.

    This function logs the HTTP method and URL of the incoming request using the Flask's `request` object.
    The log message is formatted as "Request received: <HTTP_METHOD> <REQUEST_URL>".

    Parameters:
    None

    Returns:
    None
    """
    logger.info(f"Request received: {request.method} {request.url}")

app.before_request(log_request)

# Swagger documentation setup
swaggerui_blueprint = get_swaggerui_blueprint(
    app.config['SWAGGER_URL'],
    app.config['API_URL'],
    config={'app_name': "Micro Service"}
)

# Add /healthcheck to each blueprint
@auth_bp.before_request
def log_spotify_requests():
    logger.info("Spotify blueprint request received.")
    
# Add /healthcheck to each blueprint
@auth_bp.route("/healthcheck", methods=["GET"])
def auth_healthcheck():
    gui.log("Auth Service healthcheck requested")
    logger.info("Auth Service healthcheck requested")
    return jsonify({"status": "ok", "service": "Auth Service"}), 200

# Add /healthcheck to each blueprint
@apps_bp.before_request
def log_apps_requests():
    logger.info("Apps blueprint request received.")
    
# Add /healthcheck to each blueprint
@apps_bp.route("/healthcheck", methods=["GET"])
def apps_healthcheck():
    gui.log("Apps Service healthcheck requested")
    logger.info("Apps Service healthcheck requested")
    return jsonify({"status": "ok", "service": "Apps Service"}), 200

# Add /healthcheck to each blueprint
@lyrics_bp.before_request
def log_lyrics_requests():
    logger.info("Lyrics blueprint request received.")
    
# Add /healthcheck to each blueprint
@lyrics_bp.route("/healthcheck", methods=["GET"])
def lyrics_healthcheck():
    gui.log("Lyrics Service healthcheck requested")
    logger.info("Lyrics Service healthcheck requested")
    return jsonify({"status": "ok", "service": "Lyrics Service"}), 200

# Add /healthcheck to each blueprint
@SpotifyMicroService_bp.before_request
def log_spotify_micro_service_requests():  # noqa: F811
    logger.info("Spotify Micro Service blueprint request received.")
    
# Add /healthcheck to each blueprint
@SpotifyMicroService_bp.route("/healthcheck", methods=["GET"])
def spotify_micro_service_healthcheck():
    gui.log("Spotify Micro Service healthcheck requested")
    logger.info("Spotify Micro Service healthcheck requested")
    return jsonify({"status": "ok", "service": "Spotify Micro Service"}), 200

# Add /healthcheck to each blueprint
@spotify_bp.before_request
def log_spotify_requests():  # noqa: F811
    logger.info("Spotify blueprint request received.")
    
# Add /healthcheck to each blueprint
@spotify_bp.route("/healthcheck", methods=["GET"])
def spotify_healthcheck():
    gui.log("Spotify Service healthcheck requested")
    logger.info("Spotify Service healthcheck requested")
    return jsonify({"status": "ok", "service": "Spotify Service"}), 200

@profile_bp.before_request
def log_profile_requests():
    logger.info("Profile blueprint request received.")
    
@profile_bp.route("/healthcheck", methods=["GET"])
def profile_healthcheck():
    gui.log("Profile Service healthcheck requested")
    logger.info("Profile Service healthcheck requested")
    return jsonify({"status": "ok", "service": "Profile Service"}), 200

@google_bp.before_request
def log_google_requests():
    logger.info("Google blueprint request received.")
    
@google_bp.route("/healthcheck", methods=["GET"])
def google_healthcheck():
    gui.log("Google Service healthcheck requested")
    logger.info("Google Service healthcheck requested")
    return jsonify({"status": "ok", "service": "Google Service"}), 200

@youtubeMusic_bp.before_request
def log_youtube_music_requests():
    logger.info("Youtube Music blueprint request received.")
    
@youtubeMusic_bp.route("/healthcheck", methods=["GET"])
def youtube_music_healthcheck():
    gui.log("Youtube Music Service healthcheck requested")
    logger.info("Youtube Music Service healthcheck requested")
    return jsonify({"status": "ok", "service": "Youtube Music Service"}), 200

@app.route("/healthcheck", methods=['POST', 'GET'])
def app_healthcheck():
    #gui.log("App healthcheck requested")
    logger.info("App healthcheck requested")
    return jsonify({"status": "ok", "service": "App Service"}), 200

@app.route("/.well-known/assetlinks.json", methods=['POST','GET'])
def appmanifest():
    """
    This function returns a JSON response containing asset links for Android app manifest.

    Parameters:
    None

    Returns:
    dict: A JSON response containing asset links for the Android app manifest. The response includes
    the relation type and target details, such as the namespace, package name, and SHA-256 cert fingerprints.
    """
    return jsonify([
            {
            "relation": ["delegate_permission/common.handle_all_urls"],
            "target": {
              "namespace": "android_app",
              "package_name": "com.example.ssdk_rsrc",
              "sha256_cert_fingerprints": [
                "49:B0:67:2F:35:2D:6C:16:87:D9:5F:E2:4F:6A:BF:45:CA:67:41:09:11:74:54:F8:0F:56:FF:CB:C4:3F:2F:A4"
                ]
            }
            }
        ]
    )

    

app.register_blueprint(auth_bp, url_prefix="/auth")
app.register_blueprint(apps_bp, url_prefix="/apps")
app.register_blueprint(spotify_bp, url_prefix="/spotify")
app.register_blueprint(profile_bp, url_prefix="/profile")
app.register_blueprint(SpotifyMicroService_bp, url_prefix="/spotify-micro-service")
app.register_blueprint(lyrics_bp, url_prefix="/lyrics")
app.register_blueprint(google_bp, url_prefix="/google")
app.register_blueprint(youtubeMusic_bp, url_prefix="/youtube-music")
app.register_blueprint(apple_bp, url_prefix="/apple")
app.register_blueprint(appleMusic_bp, url_prefix="/apple-music")
app.register_blueprint(swaggerui_blueprint, url_prefix=app.config['SWAGGER_URL'])


# Route for visualizing logs with filtering and pagination
@app.route('/logs', methods=['GET'])
def visualize_logs():
    """
    This function retrieves logs from a specified folder, filters them based on query parameters,
    and applies pagination. It then renders a template with the paginated logs.

    Parameters:
    None

    Returns:
    render_template: A rendered template with the paginated logs, page number, per page count,
    total logs, log type filter, and filename filter.
    """
    logs_folder_path = 'logs'
    logs = parse_logs_from_folder(logs_folder_path)

    # Get query parameters
    log_type_filter = request.args.get('log_type', None)
    filename_filter = request.args.get('filename', None)
    page = int(request.args.get('page', 1))
    per_page = int(request.args.get('per_page', 10))

    # Apply filtering
    if log_type_filter:
        logs = [log for log in logs if log_type_filter.lower() in log['log_type'].lower()]
    if filename_filter:
        logs = [log for log in logs if filename_filter.lower() in log['filename'].lower()]

    # Apply pagination
    total_logs = len(logs)
    start = (page - 1) * per_page
    end = start + per_page
    paginated_logs = logs[start:end]

    # Return the rendered template with logs
    return render_template(
        "log.html",
        logs=paginated_logs,
        page=page,
        per_page=per_page,
        total_logs=total_logs,
        log_type_filter=log_type_filter,
        filename_filter=filename_filter
    )

    
# Endpoint to display the trend chart
@app.route('/logs/trend', methods=['GET'])
def logs_trend_chart():
    """
    This function generates a trend chart of log types over time.

    Parameters:
    None

    Returns:
    tuple: A tuple containing the rendered template with the log trend chart,
    or a JSON response with an error message and a status code of 404 if no valid logs are available.
    """
    try:
        logs_folder_path = 'logs'  # Replace with your actual folder path
        df = parse_logs_to_dataframe(logs_folder_path)

        if df.empty:
            return "No valid logs available to display.", 404

        # Group by time intervals and log type, then count occurrences
        df['timestamp'] = pd.to_datetime(df['timestamp'])  # Ensure timestamp is in datetime format
        df.set_index('timestamp', inplace=True)
        grouped = df.groupby([pd.Grouper(freq='1H'), 'log_type']).size().unstack(fill_value=0)

        # Create a Plotly figure
        fig = go.Figure()

        for log_type in grouped.columns:
            fig.add_trace(go.Scatter(
                x=grouped.index,
                y=grouped[log_type],
                mode='lines+markers',
                name=log_type
            ))

        # Add chart details
        fig.update_layout(
            title="Log Type Trend Over Time",
            xaxis_title="Time (Hourly)",
            yaxis_title="Count",
            legend_title="Log Type",
            template="plotly_white",
            hovermode="x unified"
        )
        # Convert the Plotly figure to JSON
        graph_json = json.dumps(fig, cls=PlotlyJSONEncoder)

        return render_template("plotly_chart.html", graph_json=graph_json)
    except Exception as e:
        log_error(e)
        return render_template("plotly_chart.html", graph_json=graph_json)



@app.route('/endpoints')
def list_endpoints():
    """
    This function lists all available endpoints in the Flask application.
    It supports optional filtering based on HTTP methods and keywords.
    The endpoints are paginated and can be returned in JSON or HTML format.

    Returns:
    JSON/HTML: A JSON response or an HTML page containing the list of endpoints,
    along with metadata such as the total number of endpoints, the current page,
    and the number of endpoints per page.
    """
    # Collect and organize endpoints
    endpoints = []
    for rule in app.url_map.iter_rules():
        if rule.endpoint.startswith('__') or rule.endpoint == 'static':  # Skip internal/static routes
            continue
        endpoints.append({
            "rule": str(rule),
            "endpoint": rule.endpoint,
            "methods": sorted(rule.methods),
            "arguments": list(rule.arguments),  # Dynamic segments like <username>
            "description": route_descriptions.get(str(rule), "No description available.")
        })

    # Apply optional filters from query parameters
    method_filter = request.args.get("method")
    keyword_filter = request.args.get("keyword")
    if method_filter:
        endpoints = [e for e in endpoints if method_filter.upper() in e["methods"]]
    if keyword_filter:
        endpoints = [e for e in endpoints if keyword_filter in e["rule"]]

    # Sort endpoints alphabetically
    endpoints = sorted(endpoints, key=lambda x: x["rule"])

    # Pagination
    page = int(request.args.get("page", 1))
    per_page = int(request.args.get("per_page", 100))
    total = len(endpoints)
    start = (page - 1) * per_page
    end = start + per_page
    paginated_endpoints = endpoints[start:end]

    # Include environment details
    metadata = {
        "total_endpoints": total,
        "current_page": page,
        "per_page": per_page,
        "flask_version": flask.__version__,
        "debug": app.debug
    }

    # Return format based on `Accept` header or query parameter
    output_format = request.args.get("format", "json").lower()
    if output_format == "json" or "application/json" in request.headers.get("Accept", ""):
        return jsonify(metadata=metadata, endpoints=paginated_endpoints), 200
    elif output_format == "html":
        return render_template("endpoint.html", metadata=metadata, endpoints=paginated_endpoints), 200
    else:  # Plain text fallback
        text_output = "Available Endpoints:\n"
        for e in paginated_endpoints:
            text_output += (
                f"{e['rule']} (Endpoint: {e['endpoint']}, Methods: {', '.join(e['methods'])}, "
                f"Args: {', '.join(e['arguments'])}, Description: {e['description']})\n"
            )
        return text_output, 200, {"Content-Type": "text/plain"}


# Dictionary to track how many times each error occurs
error_counts = {
    400: 0,
    401: 0,
    403: 0,
    404: 0,
    405: 0,
    408: 0,
    429: 0,
    500: 0
}

def increment_error_count(status_code):
    """
    Increments the count of a specific HTTP status code in the error_counts dictionary.

    Parameters:
    status_code (int): The HTTP status code to increment the count for.

    Returns:
    None
    """
    if status_code in error_counts:
        error_counts[status_code] += 1


# --------------------------------
# 400 Bad Request
# --------------------------------
@app.errorhandler(400)
def bad_request(e):
    """
    This function handles the 400 Bad Request error. It increments the error count, logs the error,
    and returns an appropriate error message and status code.

    Parameters:
    e (Exception): The exception object that caused the error.

    Returns:
    tuple: A tuple containing the rendered error template, the error message, and the status code (400).
    """
    increment_error_count(400)
    log_error(e)
    logger.error(f"400 Bad Request: {e}")
    return render_template(
        "error.html",
        error_message="Bad request. Please check your input.", error_code=400
    ), 400


# --------------------------------
# 401 Unauthorized
# --------------------------------
@app.errorhandler(401)
def unauthorized(e):
    """
    This function handles the 401 Unauthorized error. It increments the error count, logs the error,
    and returns an appropriate error message and status code.

    Parameters:
    e (Exception): The exception object that caused the error.

    Returns:
    tuple: A tuple containing the rendered error template, the error message, and the status code (401).
    """
    increment_error_count(401)
    log_error(e)
    logger.error(f"401 Unauthorized: {e}")
    return render_template(
        "error.html",
        error_message="Unauthorized access.", error_code=401
    ), 401


# --------------------------------
# 403 Forbidden
# --------------------------------
@app.errorhandler(403)
def forbidden(e):
    """
    This function handles the 403 Forbidden error. It increments the error count, logs the error,
    and returns an appropriate error message and status code.

    Parameters:
    e (Exception): The exception object that caused the error.

    Returns:
    tuple: A tuple containing the rendered error template, the error message, and the status code (403).
    """
    increment_error_count(403)
    log_error(e)
    logger.error(f"403 Forbidden: {e}")
    return render_template(
        "error.html",
        error_message="Forbidden.", error_code=403
    ), 403

# --------------------------------
# 404 Not Found
# --------------------------------
@app.errorhandler(404)
def page_not_found(e):
    """
    This function handles the 404 Not Found error. It increments the error count, logs the error,
    and returns an appropriate error message and status code.

    Parameters:
    e (Exception): The exception object that caused the error.

    Returns:
    tuple: A tuple containing the rendered error template, the error message, and the status code (404).
    """
    increment_error_count(404)
    log_error(e)
    logger.error(f"404 Not Found: {e}")
    return render_template(
        "error.html",
        error_message="The endpoint you are looking for does not exist.", error_code=404
    ), 404


# --------------------------------
# 405 Method Not Allowed
# --------------------------------
@app.errorhandler(405)
def method_not_allowed(e):
    """
    This function handles the 405 Method Not Allowed error. It increments the error count, logs the error,
    and returns an appropriate error message and status code.

    Parameters:
    e (Exception): The exception object that caused the error.

    Returns:
    tuple: A tuple containing the rendered error template, the error message, and the status code (405).
    """
    increment_error_count(405)
    log_error(e)
    logger.error(f"405 Method Not Allowed: {e}")
    return render_template(
        "error.html",
        error_message="Method not allowed for this endpoint.", error_code=405
    ), 405


# --------------------------------
# 408 Request Timeout
# --------------------------------
@app.errorhandler(408)
def request_timeout(e):
    """
    This function handles the 408 Request Timeout error. It increments the error count, logs the error,
    and returns an appropriate error message and status code.

    Parameters:
    e (Exception): The exception object that caused the error.

    Returns:
    tuple: A tuple containing the rendered error template, the error message, and the status code (408).
    """
    increment_error_count(408)
    log_error(e)
    logger.error(f"408 Request Timeout: {e}")
    return render_template(
        "error.html",
        error_message="Request timed out. Please try again.", error_code=408
    ), 408


# --------------------------------
# 429 Too Many Requests
# --------------------------------
@app.errorhandler(429)
def too_many_requests(e):
    """
    This function handles the 429 Too Many Requests error. It increments the error count, logs the error,
    and returns an appropriate error message and status code.

    Parameters:
    e (Exception): The exception object that caused the error.

    Returns:
    tuple: A tuple containing the rendered error template, the error message, and the status code (429).
    """
    increment_error_count(429)
    log_error(e)
    logger.error(f"429 Too Many Requests: {e}")
    return render_template(
        "error.html",
        error_message="You have sent too many requests in a given time.", error_code=429
    ), 429


# --------------------------------
# 500 Internal Server Error
# --------------------------------
@app.errorhandler(500)
def internal_server_error(e):
    """
    This function handles the 500 Internal Server Error. It increments the error count, logs the error,
    and returns an appropriate error message and status code.

    Parameters:
    e (Exception): The exception object that caused the error.

    Returns:
    tuple: A tuple containing the rendered error template, the error message, and the status code (500).
    """
    increment_error_count(500)
    log_error(e)
    logger.error(f"500 Internal Server Error: {e}")
    return render_template(
        "error.html",
        error_message="An internal server error occurred. Please try again later.", error_code=500
    ), 500


# Example route to display current error counts (optional)
@app.route("/error_stats")
def show_error_stats():
    """
    This function returns the current count of errors for each HTTP status code.

    Parameters:
    None

    Returns:
    dict: A dictionary containing the count of errors for each HTTP status code.
    """
    # You can return this data as JSON or render it in a template
    return jsonify(error_counts)


@jwt.unauthorized_loader
def unauthorized_loader(callback):
    """
    This function is a callback for handling unauthorized JWT tokens.
    It returns a JSON response with an error message and a status code of 401.

    Parameters:
    callback (str): The callback message to be included in the response.

    Returns:
    dict: A JSON response with the following structure:
        {
            "error": "Token missing or invalid",
            "message": callback
        }
        The status code of the response is 401.
    """
    return jsonify({"error": "Token missing or invalid", "message": callback}), 401


@jwt.expired_token_loader
def expired_token_callback(jwt_header, jwt_payload):
    """
    This function is a callback for handling expired JWT tokens.

    Parameters:
    jwt_header (dict): The header of the JWT token.
    jwt_payload (dict): The payload of the JWT token.

    Returns:
    dict: A JSON response with an error message and a status code of 401.
    """
    return jsonify({"error": "Token expired"}), 401


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run Flask on a specific port.")
    parser.add_argument("--port", type=int, default=8080, help="Port to run the Flask app.")
    args = parser.parse_args()

    app.run(host="0.0.0.0", port=args.port, ssl_context=('keys/cert.pem', 'keys/key.pem'))
