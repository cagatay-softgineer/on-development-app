# models.py
from pydantic import BaseModel, EmailStr, constr

class RegisterRequest(BaseModel):
    email: EmailStr
    password: constr(min_length=6) # type: ignore

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

# Add additional models as needed for other endpoints
