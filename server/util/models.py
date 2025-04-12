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


class UserEmailRequest(BaseModel):
    user_email: EmailStr


class PlaylistRequest(BaseModel):
    playlist_id: str
    user_email: str


class PlaylistItemsRequest(BaseModel):
    playlist_id: str
    user_email: str
