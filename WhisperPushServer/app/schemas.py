from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr


class UserCreate(BaseModel):
    username: str
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: int
    username: str
    email: EmailStr
    created_at: datetime

    class Config:
        from_attributes = True

class LoginRequest(BaseModel):
    username_or_email: str
    password: str
    two_factor_code: Optional[str] = None

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str

class Token(BaseModel):
    access_token: str
    token_type: str
    username: str

class TokenData(BaseModel):
    user_id: Optional[int] = None

class SecretCreate(BaseModel):
    name: Optional[str] = None

class SecretResponse(BaseModel):
    id: int
    user_id: int
    name: Optional[str]
    created_at: datetime
    is_active: bool

    class Config:
        from_attributes = True

class SecretWithKeyResponse(SecretResponse):
    secret_key: str

class PushMessageRequest(BaseModel):
    title: str
    body: str
    content_type: Optional[str] = "text"
    group: Optional[str] = None
    level: Optional[str] = "active"

class MessageResponse(BaseModel):
    id: int
    user_id: int
    title: str
    body: str
    content_type: str
    group: Optional[str]
    level: str
    created_at: datetime
    read: bool

    class Config:
        from_attributes = True

class DeviceCreate(BaseModel):
    device_type: str
    device_token: Optional[str] = None
    device_name: Optional[str] = None

class DeviceResponse(BaseModel):
    id: int
    user_id: int
    device_type: str
    device_token: Optional[str]
    device_name: Optional[str]
    created_at: datetime
    is_active: bool

    class Config:
        from_attributes = True

class WSMessage(BaseModel):
    type: str
    data: dict


class TwoFactorInfoResponse(BaseModel):
    enabled: bool


class TwoFactorEnableResponse(BaseModel):
    secret: str
    qr_code_url: str


class TwoFactorVerifyRequest(BaseModel):
    code: str


class TwoFactorDisableRequest(BaseModel):
    password: str


class RecoveryCodesResponse(BaseModel):
    recovery_codes: list[str]