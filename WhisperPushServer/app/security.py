import secrets
from datetime import datetime, timedelta, timezone
from typing import Optional

import bcrypt
from jose import jwt
from passlib.context import CryptContext
from sqlalchemy import select
from sqlalchemy.orm import Session

from app import models
from app.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
RESET_TOKEN_EXPIRE_HOURS = 1


def get_password_hash(password: str) -> str:
    """
    哈希密码
    
    使用 bcrypt 算法对密码进行哈希处理，自动处理 72 字节限制。
    返回的哈希值包含 salt 和算法标识，可直接存储到数据库。
    
    Args:
        password: 原始密码字符串
    
    Returns:
        str: 哈希后的密码字符串
    """
    pwd_bytes = password.encode('utf-8')
    if len(pwd_bytes) > 72:
        pwd_bytes = pwd_bytes[:72]
    hashed = bcrypt.hashpw(pwd_bytes, bcrypt.gensalt())
    return hashed.decode('utf-8')


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    验证密码
    
    将明文密码与存储的哈希密码进行比对，验证密码是否正确。
    
    Args:
        plain_password: 用户输入的明文密码
        hashed_password: 数据库中存储的哈希密码
    
    Returns:
        bool: 密码是否匹配
    """
    pwd_bytes = plain_password.encode('utf-8')
    if len(pwd_bytes) > 72:
        pwd_bytes = pwd_bytes[:72]
    hashed_bytes = hashed_password.encode('utf-8')
    return bcrypt.checkpw(pwd_bytes, hashed_bytes)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """
    创建 JWT 访问令牌
    
    生成包含用户数据的 JWT 令牌，支持自定义过期时间。
    
    Args:
        data: 要嵌入令牌的数据（如用户ID）
        expires_delta: 过期时间间隔，默认为配置的默认值
    
    Returns:
        str: JWT 令牌字符串
    """
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.access_token_expire_minutes)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)
    return encoded_jwt


def get_user_by_email(db: Session, email: str) -> Optional[models.User]:
    """
    通过邮箱获取用户
    
    在数据库中查找指定邮箱的用户记录。
    
    Args:
        db: 数据库会话
        email: 用户邮箱
    
    Returns:
        Optional[models.User]: 用户对象，如果不存在则返回 None
    """
    from sqlalchemy import select
    result = db.execute(select(models.User).where(models.User.email == email))
    return result.scalars().first()


def get_user_by_username(db: Session, username: str) -> Optional[models.User]:
    """
    通过用户名获取用户

    在数据库中查找指定用户名的用户记录。

    Args:
        db: 数据库会话
        username: 用户名

    Returns:
        Optional[models.User]: 用户对象，如果不存在则返回 None
    """
    result = db.execute(select(models.User).where(models.User.username == username))
    return result.scalars().first()


def generate_reset_token() -> str:
    """
    生成密码重置令牌

    使用 secrets.token_urlsafe 生成安全的随机令牌。

    Returns:
        str: URL 安全的随机令牌字符串
    """
    return secrets.token_urlsafe(48)


def create_password_reset_token(db: Session, user_id: int) -> str:
    """
    创建密码重置令牌并存储

    生成重置令牌，计算哈希值存储到数据库，返回原始令牌。
    将用户之前未使用的重置令牌全部标记为已使用。

    Args:
        db: 数据库会话
        user_id: 用户ID

    Returns:
        str: 原始重置令牌（仅此一次可见）
    """
    # 将旧令牌标记为已使用
    db.execute(
        select(models.PasswordResetToken).where(
            models.PasswordResetToken.user_id == user_id,
            models.PasswordResetToken.used == False
        )
    ).scalars().all()
    # Actually need to update them properly
    old_tokens = db.execute(
        select(models.PasswordResetToken).where(
            models.PasswordResetToken.user_id == user_id,
            models.PasswordResetToken.used == False
        )
    ).scalars().all()
    for t in old_tokens:
        t.used = True

    raw_token = generate_reset_token()
    token_hash = get_password_hash(raw_token)
    expires_at = datetime.now(timezone.utc) + timedelta(hours=RESET_TOKEN_EXPIRE_HOURS)

    reset_token = models.PasswordResetToken(
        user_id=user_id,
        token_hash=token_hash,
        expires_at=expires_at
    )
    db.add(reset_token)
    db.commit()

    return raw_token


def verify_reset_token(db: Session, token: str) -> Optional[models.User]:
    """
    验证密码重置令牌

    查找匹配的未使用、未过期的重置令牌，返回对应的用户。

    Args:
        db: 数据库会话
        token: 用户提供的原始重置令牌

    Returns:
        Optional[models.User]: 令牌有效的用户，无效则返回 None
    """
    # 查找所有未使用的令牌，然后逐一比对
    reset_tokens = db.execute(
        select(models.PasswordResetToken).where(
            models.PasswordResetToken.used == False
        )
    ).scalars().all()

    for rt in reset_tokens:
        if verify_password(token, rt.token_hash):
            if rt.expires_at.replace(tzinfo=timezone.utc) < datetime.now(timezone.utc):
                return None
            return db.execute(
                select(models.User).where(models.User.id == rt.user_id)
            ).scalars().first()

    return None


def consume_reset_token(db: Session, token: str) -> None:
    """
    消耗密码重置令牌（标记为已使用）

    Args:
        db: 数据库会话
        token: 用户提供的原始重置令牌
    """
    reset_tokens = db.execute(
        select(models.PasswordResetToken).where(
            models.PasswordResetToken.used == False
        )
    ).scalars().all()

    for rt in reset_tokens:
        if verify_password(token, rt.token_hash):
            rt.used = True
            db.commit()
            return