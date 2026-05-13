from typing import Optional

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str
    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 10080

    fcm_server_key: Optional[str] = None
    apns_key_id: Optional[str] = None
    apns_team_id: Optional[str] = None
    apns_bundle_id: Optional[str] = None
    apns_private_key: Optional[str] = None
    apns_private_key_path: Optional[str] = None
    apns_use_sandbox: bool = True

    class Config:
        env_file = ".env"

settings = Settings()