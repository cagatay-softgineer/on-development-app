from database import firebase_operations
from util.logit import get_logger
from util.utils import get_email_username, obfuscate
from util.google import get_google_profile
from util.spotify import get_current_user_profile
from flask import Response
from typing import Tuple

logger = get_logger("logs", "Bind Apps")


def _fetch_binding_state(
    *,
    app_name: str,
    app_id: int,
    user_id: str,
    user_email: str,
) -> Tuple[bool, dict | None]:
    """
    Return (user_linked, user_profile) for a single app.

    Any exception or error →  (False, None)  **without** bubbling up to the caller.
    """
    try:
        tokens_doc = firebase_operations.get_userlinkedapps_tokens(user_id, app_id)

        # Nothing stored in DB → not linked
        if not tokens_doc or not tokens_doc[0].get("access_token"):
            return False, None

        tokens = tokens_doc[0]["access_token"]

        # ----------------- Per-provider handling ---------------- #
        if app_name == "Spotify":
            profile = get_current_user_profile(tokens[0], user_id, app_id)
            if profile is None:                       # invalid/expired
                raise RuntimeError("Spotify token invalid")
            return True, profile

        if app_name == "AppleMusic":
            return True, {"name": get_email_username(user_email)}

        if app_name in ("YoutubeMusic", "Google API"):
            profile = get_google_profile(user_email)
            # `get_google_profile` may return a Flask `Response` or {"error": …}
            if isinstance(profile, Response) or (isinstance(profile, dict) and profile.get("error")):
                raise RuntimeError("Google profile fetch failed")
            return True, profile

        # Add more providers here …
        # -------------------------------------------------------- #

        # Default: treat presence of token as “linked”, but we have no profile data
        return True, None

    except Exception as exc:
        # Clean up *only* this provider, leave the rest untouched
        logger.info(
            "Unlinking %s for user %s → %s",
            app_name,
            obfuscate(user_email),
            exc,
            exc_info=True,
        )
        firebase_operations.delete_userlinkedapps(user_id, app_id)
        return False, None


def _json_safe(obj):
    """
    Recursively convert obj into something json.dumps can handle:
      * Flask Response  -> obj.get_json()  (if possible)  else None
      * datetime/date   -> ISO-8601 string
      * set/tuple       -> list
      * any unknown     -> str(obj)
    """
    from datetime import date, datetime

    if obj is None or isinstance(obj, (str, int, float, bool)):
        return obj

    if isinstance(obj, Response):
        try:
            return obj.get_json(silent=True) or None
        except Exception:          # noqa: BLE001
            return None

    if isinstance(obj, (datetime, date)):
        return obj.isoformat()

    if isinstance(obj, dict):
        return {k: _json_safe(v) for k, v in obj.items()}

    if isinstance(obj, (list, tuple, set)):
        return [_json_safe(x) for x in obj]

    # fall-back: string-ify everything else
    return str(obj)
