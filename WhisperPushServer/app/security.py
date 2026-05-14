import bcrypt

from datetime import datetime, timedelta
from typing import Optional

from jose import jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from app import models
from app.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


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
    from sqlalchemy import select
    result = db.execute(select(models.User).where(models.User.username == username))
    return result.scalars().first()