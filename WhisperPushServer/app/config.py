from typing import Optional

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = ""
    secret_key: str = ""
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 10080

    fcm_server_key: Optional[str] = None
    apns_key_id: Optional[str] = None
    apns_team_id: Optional[str] = None
    apns_bundle_id: Optional[str] = None
    apns_private_key: Optional[str] = None
    apns_private_key_path: Optional[str] = None
    apns_use_sandbox: bool = True
    
    huawei_app_id: Optional[str] = None
    huawei_app_secret: Optional[str] = None

    # SMTP 邮件配置
    smtp_host: str = "localhost"
    smtp_port: int = 587
    smtp_username: Optional[str] = None
    smtp_password: Optional[str] = None
    smtp_from_address: str = "noreply@whisperpush.io"
    smtp_use_tls: bool = True

    class Config:
        def __init__(self):
            pass

        env_file = ".env"


settings = Settings()
