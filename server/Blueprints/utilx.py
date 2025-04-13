from flask import Blueprint, render_template, jsonify, request, current_app
from util.logit import get_logger
from util.utils import (
    route_descriptions,
    parse_logs_from_folder,
)
from util.authlib import requires_scope

util_bp = Blueprint("util", __name__)
logger = get_logger("logs", "App Utils")

# REMOVE ON PRODUCTION


# Route for visualizing logs with filtering and pagination
@util_bp.route("/logs", methods=["GET"])
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
    logs_folder_path = "logs"
    logs = parse_logs_from_folder(logs_folder_path)

    # Get query parameters
    log_type_filter = request.args.get("log_type", None)
    filename_filter = request.args.get("filename", None)
    page = int(request.args.get("page", 1))
    per_page = int(request.args.get("per_page", 10))

    # Apply filtering
    if log_type_filter:
        logs = [
            log for log in logs if log_type_filter.lower() in log["log_type"].lower()
        ]
    if filename_filter:
        logs = [
            log for log in logs if filename_filter.lower() in log["filename"].lower()
        ]

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
        filename_filter=filename_filter,
    )

@util_bp.route("/endpoints")
@requires_scope("admin")
def list_endpoints():
    """
    This function lists all available endpoints in the Flask application.
    It supports optional filtering based on HTTP methods and keywords.
    The endpoints are paginated and can be returned in JSON or HTML format.
    """
    endpoints = []
    # Use current_app.url_map instead of util_bp.url_map to fetch all endpoints.
    for rule in current_app.url_map.iter_rules():
        # Skip internal and static endpoints
        if rule.endpoint.startswith("__") or rule.endpoint == "static":
            continue
        endpoints.append({
            "rule": str(rule),
            "endpoint": rule.endpoint,
            "methods": sorted(rule.methods),
            "arguments": list(rule.arguments),
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

    metadata = {
        "total_endpoints": total,
        "current_page": page,
        "per_page": per_page,
        "flask_version": current_app.config.get("FLASK_VERSION", "Unknown"),
        "debug": current_app.debug,
    }

    output_format = request.args.get("format", "json").lower()
    if output_format == "json" or "application/json" in request.headers.get("Accept", ""):
        return jsonify(metadata=metadata, endpoints=paginated_endpoints), 200
    elif output_format == "html":
        return render_template("endpoint.html", metadata=metadata, endpoints=paginated_endpoints), 200
    else:
        text_output = "Available Endpoints:\n"
        for e in paginated_endpoints:
            text_output += (
                f"{e['rule']} (Endpoint: {e['endpoint']}, Methods: {', '.join(e['methods'])}, "
                f"Args: {', '.join(e['arguments'])}, Description: {e['description']})\n"
            )
        return text_output, 200, {"Content-Type": "text/plain"}


# ^^^^^^^^^^^^^^^^^^^^
# REMOVE ON PRODUCTION


@util_bp.route("/healthcheck", methods=["POST", "GET"])
def app_healthcheck():
    # gui.log("App healthcheck requested")
    logger.info("App healthcheck requested")
    return jsonify({"status": "ok", "service": "App Service"}), 200


@util_bp.route("/.well-known/assetlinks.json", methods=["POST", "GET"])
def appmanifest():
    """
    This function returns a JSON response containing asset links for Android app manifest.

    Parameters:
    None

    Returns:
    dict: A JSON response containing asset links for the Android app manifest. The response includes
    the relation type and target details, such as the namespace, package name, and SHA-256 cert fingerprints.
    """
    return jsonify(
        [
            {
                "relation": ["delegate_permission/common.handle_all_urls"],
                "target": {
                    "namespace": "android_app",
                    "package_name": "com.example.ssdk_rsrc",
                    "sha256_cert_fingerprints": [
                        "49:B0:67:2F:35:2D:6C:16:87:D9:5F:E2:4F:6A:BF:45:CA:67:41:09:11:74:54:F8:0F:56:FF:CB:C4:3F:2F:A4"
                    ],
                },
            }
        ]
    )
