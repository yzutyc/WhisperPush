from sqlalchemy import Column, Integer, String, Text, DateTime, Boolean
from sqlalchemy.sql import func

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True)
    email = Column(String(100), unique=True, index=True)
    password_hash = Column(String(128))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Secret(Base):
    __tablename__ = "secrets"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)
    secret_key_hash = Column(String(64))
    name = Column(String(50))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    is_active = Column(Boolean, default=True)

class Message(Base):
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)
    title = Column(String(100))
    body = Column(Text)
    content_type = Column(String(20))
    group = Column(String(50))
    level = Column(String(20))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    read = Column(Boolean, default=False)

class Device(Base):
    __tablename__ = "devices"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)
    device_type = Column(String(20))
    device_token = Column(String(255), nullable=True)
    device_name = Column(String(100), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    is_active = Column(Boolean, default=True)