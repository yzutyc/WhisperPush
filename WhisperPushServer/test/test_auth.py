"""
认证路由单元测试

测试用户注册、登录、登出和修改密码功能。
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
    # 创建测试表
    Base.metadata.create_all(bind=test_engine)
    
    yield
    
    # 测试后清理
    Base.metadata.drop_all(bind=test_engine)


def get_test_db():
    """获取测试数据库会话"""
    db = next(get_db())
    try:
        yield db
    finally:
        db.close()


class TestUserRegistration:
    """用户注册功能测试"""

    def test_register_success(self, setup_database):
        """测试用户注册成功"""
        response = client.post(
            "/api/v1/auth/register",
            json={
                "username": "unique_test_user_123",
                "email": "unique_test_123@example.com",
                "password": "test_password_123"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["username"] == "unique_test_user_123"
        assert data["email"] == "unique_test_123@example.com"
        assert "id" in data
        assert "created_at" in data

    def test_register_duplicate_email(self, setup_database):
        """测试注册重复邮箱"""
        # 先注册一个用户
        client.post(
            "/api/v1/auth/register",
            json={
                "username": "user1",
                "email": "duplicate@example.com",
                "password": "password123"
            }
        )
        
        # 尝试用相同邮箱注册
        response = client.post(
            "/api/v1/auth/register",
            json={
                "username": "user2",
                "email": "duplicate@example.com",
                "password": "password456"
            }
        )
        
        assert response.status_code == 400
        assert response.json()["detail"] == "Email already registered"

    def test_register_duplicate_username(self, setup_database):
        """测试注册重复用户名"""
        # 先注册一个用户
        client.post(
            "/api/v1/auth/register",
            json={
                "username": "sameuser",
                "email": "user1@example.com",
                "password": "password123"
            }
        )
        
        # 尝试用相同用户名注册
        response = client.post(
            "/api/v1/auth/register",
            json={
                "username": "sameuser",
                "email": "user2@example.com",
                "password": "password456"
            }
        )
        
        assert response.status_code == 400
        assert response.json()["detail"] == "Username already taken"


class TestUserLogin:
    """用户登录功能测试"""

    def test_login_success_with_email(self, setup_database):
        """测试使用邮箱登录成功"""
        # 先注册用户
        client.post(
            "/api/v1/auth/register",
            json={
                "username": "login_test_user",
                "email": "login@example.com",
                "password": "login_password"
            }
        )
        
        # 使用邮箱登录
        response = client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "login@example.com",
                "password": "login_password"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
        assert len(data["access_token"]) > 0

    def test_login_success_with_username(self, setup_database):
        """测试使用用户名登录成功"""
        # 先注册用户
        client.post(
            "/api/v1/auth/register",
            json={
                "username": "username_login",
                "email": "username@example.com",
                "password": "password123"
            }
        )
        
        # 使用用户名登录
        response = client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "username_login",
                "password": "password123"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data

    def test_login_invalid_password(self, setup_database):
        """测试登录时密码错误"""
        # 先注册用户
        client.post(
            "/api/v1/auth/register",
            json={
                "username": "wrong_pass_user",
                "email": "wrong@example.com",
                "password": "correct_password"
            }
        )
        
        # 使用错误密码登录
        response = client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "wrong@example.com",
                "password": "wrong_password"
            }
        )
        
        assert response.status_code == 401
        assert response.json()["detail"] == "Incorrect username/email or password"

    def test_login_nonexistent_user(self, setup_database):
        """测试登录不存在的用户"""
        response = client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "nonexistent@example.com",
                "password": "password123"
            }
        )
        
        assert response.status_code == 401
        assert response.json()["detail"] == "Incorrect username/email or password"


class TestChangePassword:
    """修改密码功能测试"""

    def test_change_password_success(self, setup_database):
        """测试修改密码成功"""
        # 注册用户
        client.post(
            "/api/v1/auth/register",
            json={
                "username": "change_pass_user_456",
                "email": "change_pass_456@example.com",
                "password": "old_password"
            }
        )
        
        # 登录获取令牌
        login_response = client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "change_pass_456@example.com",
                "password": "old_password"
            }
        )
        token = login_response.json()["access_token"]
        
        # 修改密码
        response = client.post(
            "/api/v1/auth/change-password",
            json={
                "current_password": "old_password",
                "new_password": "new_password_123"
            },
            headers={"Authorization": f"Bearer {token}"}
        )
        
        assert response.status_code == 200
        assert response.json()["status"] == "success"
        assert response.json()["message"] == "Password changed successfully"

    def test_change_password_wrong_current_password(self, setup_database):
        """测试修改密码时当前密码错误"""
        # 注册用户
        client.post(
            "/api/v1/auth/register",
            json={
                "username": "wrong_current_user",
                "email": "wrong_current@example.com",
                "password": "correct_password"
            }
        )
        
        # 登录获取令牌
        login_response = client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "wrong_current@example.com",
                "password": "correct_password"
            }
        )
        token = login_response.json()["access_token"]
        
        # 使用错误的当前密码
        response = client.post(
            "/api/v1/auth/change-password",
            json={
                "current_password": "wrong_password",
                "new_password": "new_password"
            },
            headers={"Authorization": f"Bearer {token}"}
        )
        
        assert response.status_code == 400
        assert response.json()["detail"] == "Current password is incorrect"


class TestGetMe:
    """获取当前用户信息测试"""

    def test_get_me_success(self, setup_database):
        """测试获取当前用户信息成功"""
        # 注册用户
        client.post(
            "/api/v1/auth/register",
            json={
                "username": "getme_user",
                "email": "getme@example.com",
                "password": "password123"
            }
        )
        
        # 登录获取令牌
        login_response = client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "getme@example.com",
                "password": "password123"
            }
        )
        token = login_response.json()["access_token"]
        
        # 获取用户信息
        response = client.get(
            "/api/v1/auth/me",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["username"] == "getme_user"
        assert data["email"] == "getme@example.com"

    def test_get_me_unauthenticated(self, setup_database):
        """测试未认证时获取用户信息"""
        response = client.get("/api/v1/auth/me")
        
        assert response.status_code == 401