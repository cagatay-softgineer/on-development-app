from functools import wraps
from flask import jsonify
from flask_jwt_extended import verify_jwt_in_request, get_jwt
from util.utils import obfuscate


def requires_scope(required_scope):
    """
    Decorator to enforce that a valid JWT is present and it contains the required scope.
    """

    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            # Verify that the JWT exists in the request
            verify_jwt_in_request()
            claims = get_jwt()
            # Assume that the scopes are stored as a list in the "scopes"
            # claim.
            token_scopes = claims.get("scopes", [])
            # If scopes were added as a space-delimited string, split it:
            if isinstance(token_scopes, str):
                token_scopes = token_scopes.split()
            if required_scope not in token_scopes:
                return (
                    jsonify(
                        {
                            "error": "Missing required scope",
                            "required": obfuscate(required_scope),
                        }
                    ),
                    403,
                )
            return fn(*args, **kwargs)

        return wrapper

    return decorator


# All Scopes
all_scopes = [
    "me",
    "apps",
    "spotify",
    "apple",
    "google",
    "lyrics",
    "youtube",
    "admin"]
default_user = ["me", "apps", "spotify", "apple", "google", "youtube"]
