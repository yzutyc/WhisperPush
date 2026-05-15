"""
消息路由单元测试

测试消息推送、查询、标记已读/未读和删除功能。
"""
import os

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

os.environ["DATABASE_URL"] = "sqlite:///./test.db"

from app.config import settings
from app.main import app
from app.database import Base, get_db

# 创建测试数据库引擎
test_engine = create_engine(settings.database_url, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)

def override_get_db():
    """覆盖数据库依赖，使用测试数据库"""
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)

@pytest.fixture(scope="function")
def setup_database():
    """测试前设置数据库"""
    Base.metadata.create_all(bind=test_engine)
    yield
    Base.metadata.drop_all(bind=test_engine)


class TestMessagePush:
    """消息推送功能测试"""

    def test_push_message_with_valid_secret(self, setup_database):
        """测试使用有效秘钥推送消息"""
        # 注册用户
        client.post(
            "/api/v1/auth/register",
            json={
                "username": "push_user",
                "email": "push@example.com",
                "password": "password123"
            }
        )
        
        # 登录获取令牌
        login_response = client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "push@example.com",
                "password": "password123"
            }
        )
        token = login_response.json()["access_token"]
        
        # 创建秘钥
        create_secret_response = client.post(
            "/api/v1/secrets/",
            json={"name": "test_secret"},
            headers={"Authorization": f"Bearer {token}"}
        )
        secret_key = create_secret_response.json()["secret_key"]
        
        # 使用秘钥推送消息
        response = client.post(
            "/api/v1/push",
            json={
                "title": "Test Message",
                "body": "This is a test message",
                "content_type": "text",
                "group": "test",
                "level": "info"
            },
            headers={"X-Secret-Key": secret_key}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert "message_id" in data

    def test_push_message_missing_secret(self, setup_database):
        """测试缺少秘钥推送消息"""
        response = client.post(
            "/api/v1/push",
            json={
                "title": "Test Message",
                "body": "This is a test message"
            }
        )
        
        assert response.status_code == 401
        assert response.json()["detail"] == "Secret key required"

    def test_push_message_invalid_secret(self, setup_database):
        """测试使用无效秘钥推送消息"""
        response = client.post(
            "/api/v1/push",
            json={
                "title": "Test Message",
                "body": "This is a test message"
            },
            headers={"X-Secret-Key": "invalid_secret_key"}
        )
        
        assert response.status_code == 401
        assert response.json()["detail"] == "Invalid secret key"


class TestMessageRetrieval:
    """消息查询功能测试"""

    def test_get_messages_success(self, setup_database):
        """测试获取消息列表成功"""
        # 注册用户
        client.post(
            "/api/v1/auth/register",
            json={
                "username": "message_user",
                "email": "message@example.com",
                "password": "password123"
            }
        )
        
        # 登录获取令牌
        login_response = client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "message@example.com",
                "password": "password123"
            }
        )
        token = login_response.json()["access_token"]
        
        # 创建秘钥
        create_secret_response = client.post(
            "/api/v1/secrets/",
            json={"name": "test_secret"},
            headers={"Authorization": f"Bearer {token}"}
        )
        secret_key = create_secret_response.json()["secret_key"]
        
        # 推送消息
        client.post(
            "/api/v1/push",
            json={
                "title": "Test Message",
                "body": "This is a test message"
            },
            headers={"X-Secret-Key": secret_key}
        )
        
        # 获取消息列表
        response = client.get(
            "/api/v1/messages",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 1

    def test_get_messages_unauthenticated(self, setup_database):
        """测试未认证时获取消息列表"""
        response = client.get("/api/v1/messages")
        
        assert response.status_code == 401

    def test_get_single_message(self, setup_database):
        """测试获取单条消息"""
        # 注册用户
        client.post(
            "/api/v1/auth/register",
            json={
                "username": "single_message_user",
                "email": "single_message@example.com",
                "password": "password123"
            }
        )
        
        # 登录获取令牌
        login_response = client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "single_message@example.com",
                "password": "password123"
            }
        )
        token = login_response.json()["access_token"]
        
        # 创建秘钥
        create_secret_response = client.post(
            "/api/v1/secrets/",
            json={"name": "test_secret"},
            headers={"Authorization": f"Bearer {token}"}
        )
        secret_key = create_secret_response.json()["secret_key"]
        
        # 推送消息
        push_response = client.post(
            "/api/v1/push",
            json={
                "title": "Single Message",
                "body": "This is a single test message"
            },
            headers={"X-Secret-Key": secret_key}
        )
        message_id = push_response.json()["message_id"]
        
        # 获取单条消息
        response = client.get(
            f"/api/v1/messages/{message_id}",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == message_id
        assert data["title"] == "Single Message"

    def test_get_message_not_found(self, setup_database):
        """测试获取不存在的消息"""
        # 注册用户
        client.post(
            "/api/v1/auth/register",
            json={
                "username": "not_found_user",
                "email": "not_found@example.com",
                "password": "password123"
            }
        )
        
        # 登录获取令牌
        login_response = client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "not_found@example.com",
                "password": "password123"
            }
        )
        token = login_response.json()["access_token"]
        
        # 获取不存在的消息
        response = client.get(
            "/api/v1/messages/99999",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        assert response.status_code == 404
        assert response.json()["detail"] == "Message not found"


class TestMessageStatus:
    """消息状态更新测试"""

    def test_mark_message_read(self, setup_database):
        """测试标记消息为已读"""
        # 注册用户
        client.post(
            "/api/v1/auth/register",
            json={
                "username": "read_user",
                "email": "read@example.com",
                "password": "password123"
            }
        )
        
        # 登录获取令牌
        login_response = client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "read@example.com",
                "password": "password123"
            }
        )
        token = login_response.json()["access_token"]
        
        # 创建秘钥
        create_secret_response = client.post(
            "/api/v1/secrets/",
            json={"name": "test_secret"},
            headers={"Authorization": f"Bearer {token}"}
        )
        secret_key = create_secret_response.json()["secret_key"]
        
        # 推送消息
        push_response = client.post(
            "/api/v1/push",
            json={
                "title": "Mark Read Message",
                "body": "This message will be marked as read"
            },
            headers={"X-Secret-Key": secret_key}
        )
        message_id = push_response.json()["message_id"]
        
        # 标记消息为已读
        response = client.patch(
            f"/api/v1/messages/{message_id}/read",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == message_id
        assert data["read"] is True

    def test_mark_message_unread(self, setup_database):
        """测试标记消息为未读"""
        # 注册用户
        client.post(
            "/api/v1/auth/register",
            json={
                "username": "unread_user",
                "email": "unread@example.com",
                "password": "password123"
            }
        )
        
        # 登录获取令牌
        login_response = client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "unread@example.com",
                "password": "password123"
            }
        )
        token = login_response.json()["access_token"]
        
        # 创建秘钥
        create_secret_response = client.post(
            "/api/v1/secrets/",
            json={"name": "test_secret"},
            headers={"Authorization": f"Bearer {token}"}
        )
        secret_key = create_secret_response.json()["secret_key"]
        
        # 推送消息
        push_response = client.post(
            "/api/v1/push",
            json={
                "title": "Mark Unread Message",
                "body": "This message will be marked as unread"
            },
            headers={"X-Secret-Key": secret_key}
        )
        message_id = push_response.json()["message_id"]
        
        # 先标记为已读
        client.patch(
            f"/api/v1/messages/{message_id}/read",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        # 再标记为未读
        response = client.patch(
            f"/api/v1/messages/{message_id}/unread",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == message_id
        assert data["read"] is False


class TestMessageDeletion:
    """消息删除功能测试"""

    def test_delete_message_success(self, setup_database):
        """测试删除消息成功"""
        # 注册用户
        client.post(
            "/api/v1/auth/register",
            json={
                "username": "delete_user",
                "email": "delete@example.com",
                "password": "password123"
            }
        )
        
        # 登录获取令牌
        login_response = client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "delete@example.com",
                "password": "password123"
            }
        )
        token = login_response.json()["access_token"]
        
        # 创建秘钥
        create_secret_response = client.post(
            "/api/v1/secrets/",
            json={"name": "test_secret"},
            headers={"Authorization": f"Bearer {token}"}
        )
        secret_key = create_secret_response.json()["secret_key"]
        
        # 推送消息
        push_response = client.post(
            "/api/v1/push",
            json={
                "title": "Delete Message",
                "body": "This message will be deleted"
            },
            headers={"X-Secret-Key": secret_key}
        )
        message_id = push_response.json()["message_id"]
        
        # 删除消息
        response = client.delete(
            f"/api/v1/messages/{message_id}",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        assert response.status_code == 204

    def test_delete_message_not_found(self, setup_database):
        """测试删除不存在的消息"""
        # 注册用户
        client.post(
            "/api/v1/auth/register",
            json={
                "username": "delete_not_found_user",
                "email": "delete_not_found@example.com",
                "password": "password123"
            }
        )
        
        # 登录获取令牌
        login_response = client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "delete_not_found@example.com",
                "password": "password123"
            }
        )
        token = login_response.json()["access_token"]
        
        # 删除不存在的消息
        response = client.delete(
            "/api/v1/messages/99999",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        assert response.status_code == 404
        assert response.json()["detail"] == "Message not found"
