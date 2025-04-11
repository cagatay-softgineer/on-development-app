from flask import Blueprint, render_template, jsonify, request
from util.logit import get_logger
from util.error_handling import log_error
import flask
from util.utils import route_descriptions, parse_logs_from_folder, parse_logs_to_dataframe
import pandas as pd
import json
import plotly.graph_objects as go
from plotly.utils import PlotlyJSONEncoder
from util.authlib import requires_scope

util_bp = Blueprint('util', __name__)
logger = get_logger("logs/app_util.log", "App Utils")

### ### REMOVE ON PRODUCTION ### ###

# Route for visualizing logs with filtering and pagination
@util_bp.route('/logs', methods=['GET'])
@requires_scope("admin")
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
@util_bp.route('/logs/trend', methods=['GET'])
@requires_scope("admin")
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



@util_bp.route('/endpoints')
@requires_scope("admin")
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
    for rule in util_bp.url_map.iter_rules():
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
        "debug": util_bp.debug
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
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #
### ### REMOVE ON PRODUCTION ### ###



@util_bp.route("/healthcheck", methods=['POST', 'GET'])
@requires_scope("admin")
def app_healthcheck():
    #gui.log("App healthcheck requested")
    logger.info("App healthcheck requested")
    return jsonify({"status": "ok", "service": "App Service"}), 200

@util_bp.route("/.well-known/assetlinks.json", methods=['POST','GET'])
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