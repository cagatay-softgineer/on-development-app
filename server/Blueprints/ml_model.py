from flask import Blueprint, jsonify, request
from flask_limiter import Limiter
from flask_cors import CORS
from flask_limiter.util import get_remote_address
from pydantic import ValidationError
from util.logit import get_logger
from config.config import settings
from models.use_model import predict
from util.models import MLRequest

mlModel_bp = Blueprint("mlModel", __name__)
limiter = Limiter(key_func=get_remote_address)

# Enable CORS for all routes in this blueprint
CORS(mlModel_bp, resources=settings.CORS_resource_allow_all)

logger = get_logger("logs", "mlModel")


# Add /healthcheck to each blueprint
@mlModel_bp.before_request
def log_spotify_requests():
    logger.info("mlModel blueprint request received.")


# Add /healthcheck to each blueprint
@mlModel_bp.route("/healthcheck", methods=["GET"])
def auth_healthcheck():
    logger.info("mlModel Service healthcheck requested")
    return jsonify({"status": "ok", "service": "mlModel Service"}), 200


@mlModel_bp.route("/predict", methods=["POST"])
def predict_():
    try:
        payload = MLRequest.parse_obj(request.get_json())
    except ValidationError as ve:
        return jsonify({"error": ve.errors()}), 400
    return jsonify(predict(payload.data / 60000.0))
