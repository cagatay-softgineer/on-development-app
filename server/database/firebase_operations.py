# firebase_commands.py

import datetime as DT
from dateutil.parser import parse  # If using date parsing from strings
import os
import bcrypt
from google.cloud.firestore_v1.base_query import FieldFilter
from google.cloud.firestore_v1.collection import CollectionReference
from google.cloud.firestore_v1.transforms import SERVER_TIMESTAMP
from config.config import firebase_config
from config.config import FirebaseConfig
from firebase_admin import credentials, firestore
import firebase_admin

# You can import your alias_map from your configuration (for example, using Pydantic)
# For demonstration, we define it here:
alias_map = {
    "users": "database_structure/Users/rows",
    "apps": "database_structure/Apps/rows",
    "userlinkedapps": "database_structure/UserLinkedApps/rows",
    "userprofiles": "database_structure/UserProfiles/rows",
    "userchains": "database_structure/UserChains/rows",
}


def init_firebase(config: FirebaseConfig):
    current_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    cert_path = os.path.join(current_dir, "database/fb-cc-test.json")
    cred = credentials.Certificate(cert_path)
    # config)
    firebase_admin.initialize_app(
        cred,
        {
            "apiKey": config.api_key,
            "authDomain": config.auth_domain,
            "projectId": config.project_id,
            "storageBucket": config.storage_bucket,
            "messagingSenderId": config.messaging_sender_id,
            "appId": config.app_id,
            "measurementId": config.measurement_id,
        },
    )
    return firestore.client()


DB = init_firebase(firebase_config)


def get_collection(table: str, alias_map: dict) -> CollectionReference:
    """
    Returns a Firestore collection reference by looking up the given table alias
    in the alias_map. If the alias is not found, it returns the table name as-is.
    """
    collection_path = alias_map.get(table.lower(), table)
    return DB.collection(collection_path)


# ---------------------------
# Users and Apps Commands
# ---------------------------


def get_user_id_by_email(email: str, alias_map: dict = alias_map):
    """
    Emulates:
      SELECT user_id FROM users WHERE email = ?
    """
    col = get_collection("users", alias_map)
    filt = FieldFilter(field_path="email", op_string="==", value=email)
    docs = col.where(filter=filt).stream()
    user_ids = []
    for doc in docs:
        data = doc.to_dict()
        if "user_id" in data:
            user_ids.append(data["user_id"])

    if user_ids:
        user_id = user_ids[0]
        return user_id
    else:
        return None


def get_app_id_by_name(app_name: str, alias_map: dict = alias_map):
    """
    Emulates:
      SELECT app_id FROM Apps WHERE app_name = ?
    """
    col = get_collection("apps", alias_map)
    filt = FieldFilter(field_path="app_name", op_string="==", value=app_name)
    docs = col.where(filter=filt).stream()
    app_ids = []
    for doc in docs:
        data = doc.to_dict()
        if "app_id" in data:
            app_ids.append(data["app_id"])

    if app_ids:
        app_id = app_ids[0]
        return app_id
    else:
        return None


def get_userlinkedapps_count_and_access_token(
    app_id: int, user_id: int, alias_map: dict = alias_map
):
    """
    Emulates:
      SELECT
          (SELECT COUNT(*) FROM UserLinkedApps WHERE app_id = ? AND user_id = ?) AS user_linked,
          access_token
      FROM UserLinkedApps
      WHERE app_id = ? AND user_id = ?

    Returns a tuple: (count, [list of access_tokens])
    """
    col = get_collection("userlinkedapps", alias_map)
    filt_app = FieldFilter(field_path="app_id", op_string="==", value=app_id)
    filt_user = FieldFilter(
        field_path="user_id",
        op_string="==",
        value=user_id)
    query = col.where(filter=filt_app).where(filter=filt_user)
    docs = list(query.stream())
    count = len(docs)
    access_tokens = [
        doc.to_dict().get("access_token")
        for doc in docs
        if "access_token" in doc.to_dict()
    ]
    return count, access_tokens


def delete_userlinkedapps(user_id: int, app_id: int,
                          alias_map: dict = alias_map):
    """
    Emulates:
      DELETE FROM UserLinkedApps WHERE app_id = ? AND user_id = ?
    """
    col = get_collection("userlinkedapps", alias_map)
    filt_app = FieldFilter(field_path="app_id", op_string="==", value=app_id)
    filt_user = FieldFilter(
        field_path="user_id",
        op_string="==",
        value=user_id)
    query = col.where(filter=filt_app).where(filter=filt_user)
    for doc in query.stream():
        doc.reference.delete()


# ---------------------------
# Auth Commands
# ---------------------------

def get_next_user_id(db: firestore.Client = DB) -> int:
    counter_ref = db.collection("counters").document("users")

    @firestore.transactional
    def txn_increment(txn):
        snap = counter_ref.get(transaction=txn)
        current = snap.get("seq") or 0
        new = current + 1
        txn.update(counter_ref, {"seq": new})
        return new

    transaction = db.transaction()
    return txn_increment(transaction)


def insert_user(email: str, password: str, alias_map: dict = alias_map) -> int:
    """
    Emulates:
      INSERT INTO users (email, password) VALUES (?, ?)
    Inserts a user with:
      • numeric user_id       (from our counter)
      • bcrypt-hashed password
      • created_at & updated_at (UTC datetime)

    Returns the new user_id.
    """
    # 1) Initialize Firestore client
    users_col = get_collection("users", alias_map)

    # 2) Hash the password
    hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt())
    hashed_str = hashed.decode("utf-8")

    # 3) Obtain the next numeric ID
    user_id = get_next_user_id()

    # 4) Prepare timestamp
    now = DT.datetime.utcnow()

    # 5) Create the user document (ID = str(user_id))
    users_col.document(str(user_id)).set({
        "user_id": user_id,
        "email": email,
        "password": hashed_str,
        "created_at": now,
        "updated_at": now,
    })

    return user_id


def get_user_password_and_email(email: str, alias_map: dict = alias_map):
    """
    Emulates:
      SELECT password, email FROM users WHERE email = ?
    """
    col = get_collection("users", alias_map)
    filt = FieldFilter(field_path="email", op_string="==", value=email)
    docs = col.where(filter=filt).stream()
    results = []
    for doc in docs:
        data = doc.to_dict()
        results.append({"email": data.get("email"),
                       "password": data.get("password")})
    return results


# ---------------------------
# Google API Commands
# ---------------------------


def get_userlinkedapps_tokens(
        user_id: int, app_id: int, alias_map: dict = alias_map):
    """
    Emulates:
      SELECT access_token, refresh_token, token_expires_at, scopes
      FROM UserLinkedApps
      WHERE user_id = ? AND app_id = ?
    """
    col = get_collection("userlinkedapps", alias_map)
    filt_user = FieldFilter(
        field_path="user_id",
        op_string="==",
        value=user_id)
    filt_app = FieldFilter(field_path="app_id", op_string="==", value=app_id)
    docs = col.where(filter=filt_user).where(filter=filt_app).stream()
    results = []
    for doc in docs:
        data = doc.to_dict()
        results.append(
            {
                "access_token": data.get("access_token"),
                "refresh_token": data.get("refresh_token"),
                "token_expires_at": data.get("token_expires_at"),
                "scopes": data.get("scopes"),
            }
        )
    return results


def insert_userlinkedapps(
    user_id: int,
    app_id: int,
    access_token: str,
    refresh_token: str,
    token_expires_at: int,
    scopes: str,
    alias_map: dict = alias_map,
):
    """
    Emulates:
      INSERT INTO UserLinkedApps
        (user_id, app_id, connected_at, access_token, refresh_token, token_expires_at, scopes)
      VALUES
        (?, ?, CURRENT_TIMESTAMP, ?, ?, ?, ?)
    """
    col = get_collection("userlinkedapps", alias_map)
    col.add(
        {
            "user_id": user_id,
            "app_id": app_id,
            "connected_at": SERVER_TIMESTAMP,
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_expires_at": token_expires_at,
            "scopes": scopes,
        }
    )


def if_not_exists_insert_userlinkedapps(
    user_id: int,
    app_id: int,
    access_token: str,
    refresh_token: str,
    scopes: str,
    alias_map: dict = alias_map,
):
    """
    Emulates:
      IF NOT EXISTS (
          SELECT 1 FROM UserLinkedApps WHERE user_id = ? AND app_id = ?
      )
      BEGIN
          INSERT INTO UserLinkedApps (user_id, app_id, access_token, refresh_token, token_expires_at, scopes)
          VALUES (?, ?, ?, ?, DATEADD(HOUR, 1, GETDATE()), ?)
      END
    """
    col = get_collection("userlinkedapps", alias_map)
    filt_user = FieldFilter(
        field_path="user_id",
        op_string="==",
        value=user_id)
    filt_app = FieldFilter(field_path="app_id", op_string="==", value=app_id)
    docs = col.where(filter=filt_user).where(filter=filt_app).stream()
    if not list(docs):
        expires = DT.datetime.utcnow() + DT.timedelta(hours=1)
        col.add(
            {
                "user_id": user_id,
                "app_id": app_id,
                "access_token": access_token,
                "refresh_token": refresh_token,
                "token_expires_at": expires,
                "scopes": scopes,
            }
        )


# ---------------------------
# Spotify Micro Service Commands
# ---------------------------

# Reuse get_user_id_by_email from the Users commands.


# ---------------------------
# Spotify Commands
# ---------------------------


# Reuse get_user_id_by_email.
# For conditional insert, reuse if_not_exists_insert_userlinkedapps.
def if_not_exists_insert_userlinkedapps_spotify(
    user_id: int,
    app_id: int,
    access_token: str,
    refresh_token: str,
    scopes: str,
    alias_map: dict = alias_map,
):
    if_not_exists_insert_userlinkedapps(
        user_id, app_id, access_token, refresh_token, scopes, alias_map
    )


# ---------------------------
# User Profile Commands
# ---------------------------


def get_user_profile(user_id: int, alias_map: dict = alias_map):
    """
    Emulates:
      SELECT first_name, last_name, avatar_url, bio
      FROM UserProfiles
      WHERE user_id = ?
    """
    col = get_collection("userprofiles", alias_map)
    filt_user = FieldFilter(
        field_path="user_id",
        op_string="==",
        value=user_id)
    docs = col.where(filter=filt_user).stream()
    profiles = []
    for doc in docs:
        data = doc.to_dict()
        print(data)
        profiles.append(
            {
                "first_name": data.get("first_name"),
                "last_name": data.get("last_name"),
                "avatar_url": data.get("avatar_url"),
                "bio": data.get("bio"),
            }
        )
    return profiles


# ---------------------------
# Utils Commands
# ---------------------------


def get_userlinkedapps_access_refresh(
    user_id: int, app_id: int, alias_map: dict = alias_map
):
    """
    Emulates:
      SELECT access_token, refresh_token
      FROM UserLinkedApps
      WHERE user_id = ? AND app_id = ?
    """
    col = get_collection("userlinkedapps", alias_map)
    filt_user = FieldFilter(
        field_path="user_id",
        op_string="==",
        value=user_id)
    filt_app = FieldFilter(field_path="app_id", op_string="==", value=app_id)
    docs = col.where(filter=filt_user).where(filter=filt_app).stream()
    results = []
    for doc in docs:
        data = doc.to_dict()
        results.append(
            {
                "access_token": data.get("access_token"),
                "refresh_token": data.get("refresh_token"),
            }
        )
    return results


def update_userlinkedapps_tokens(
    new_access_token: str,
    new_refresh_token: str,
    seconds_from_now: int,
    user_id: int,
    app_id: int,
    alias_map: dict = alias_map,
):
    """
    Updates the access token, refresh token, and token expiration time for a specific user and app in the UserLinkedApps collection.

    Emulates:
      UPDATE UserLinkedApps
      SET access_token = ?,
          refresh_token = ?,
          token_expires_at = DATEADD(SECOND, ?, GETDATE())
      WHERE user_id = ? AND app_id = ?

    Parameters:
    - new_access_token (str): The new access token to be updated.
    - new_refresh_token (str): The new refresh token to be updated.
    - seconds_from_now (int): The number of seconds from the current time to set as the new token expiration time.
    - user_id (int): The user ID for which the tokens need to be updated.
    - app_id (int): The app ID for which the tokens need to be updated.
    - alias_map (dict, optional): A dictionary mapping table aliases to their actual paths in the Firestore collection. Defaults to the global `alias_map`.

    Returns:
    - None. The function updates the tokens in the Firestore collection directly.
    """
    col = get_collection("userlinkedapps", alias_map)
    filt_user = FieldFilter(
        field_path="user_id",
        op_string="==",
        value=user_id)
    filt_app = FieldFilter(field_path="app_id", op_string="==", value=app_id)
    docs = col.where(filter=filt_user).where(filter=filt_app).stream()
    new_expires = DT.datetime.utcnow() + DT.timedelta(
        seconds=seconds_from_now
    )
    for doc in docs:
        doc.reference.update(
            {
                "access_token": new_access_token,
                "refresh_token": new_refresh_token,
                "token_expires_at": new_expires,
            }
        )


def get_user_chain_status(user_id: int, alias_map: dict = alias_map):
    """
    Retrieve the current chain status for a user.
    Returns None if no document exists for that user.
    """
    col = get_collection("userchains", alias_map)
    filt = FieldFilter(field_path="user_id", op_string="==", value=user_id)
    docs = col.where(filter=filt).stream()
    for doc in docs:
        data = doc.to_dict()
        return data  # Return first (and only) doc found
    return None


def upsert_user_chain(user_id: int, action_data: dict, alias_map: dict = alias_map):
    """
    Upsert (update or insert) the chain status for a user.
    """
    col = get_collection("userchains", alias_map)
    today = DT.datetime.utcnow().date()
    filt = FieldFilter(field_path="user_id", op_string="==", value=user_id)
    docs = list(col.where(filter=filt).stream())

    # CASE 1: Chain does not exist for this user
    if not docs:
        doc_data = {
            "user_id": user_id,
            "chain_start_date": today.isoformat(),
            "chain_streak": 1,
            "max_chain_streak": 1,
            "last_update_date": DT.datetime.utcnow().isoformat(),
            "broken": False,
            "history": [{"date": today.isoformat(), "action": action_data.get("action")}]
        }
        # Use user_id as document name to ensure one doc per user (or generate unique doc_id if needed)
        col.document(str(user_id)).set(doc_data)
        return doc_data

    # CASE 2: Chain exists, update it
    doc = docs[0]
    doc_id = doc.id
    doc_data = doc.to_dict()
    last_update = parse(doc_data["last_update_date"]).date()
    # Check streak continuation
    if (today - last_update).days == 1:
        doc_data["chain_streak"] += 1
        doc_data["max_chain_streak"] = max(doc_data["max_chain_streak"], doc_data["chain_streak"])
        doc_data["broken"] = False
    elif (today - last_update).days > 1:
        doc_data["chain_streak"] = 1
        doc_data["broken"] = True
        doc_data["chain_start_date"] = today.isoformat()
    # else: already updated today (can update history if needed)
    doc_data["last_update_date"] = DT.datetime.utcnow().isoformat()
    doc_data.setdefault("history", []).append({"date": today.isoformat(), "action": action_data.get("action")})
    # Update document
    col.document(doc_id).set(doc_data)
    return doc_data
