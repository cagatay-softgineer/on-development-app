# models.py
from pydantic import BaseModel, EmailStr, constr

class RegisterRequest(BaseModel):
    email: EmailStr
    password: constr(min_length=6)  # type: ignore

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class LinkedAppRequest(BaseModel):
    app_name: str
    user_email: EmailStr

class UserIdRequest(BaseModel):
    user_id: str

class PlaylistDurationRequest(BaseModel):
    playlist_id: str
    user_id: str

class FirebaseConfig(BaseModel):
    api_key: str
    auth_domain: str
    project_id: str
    storage_bucket: str
    messaging_sender_id: str
    app_id: str
    measurement_id: str