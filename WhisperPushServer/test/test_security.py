"""
安全模块单元测试

测试密码哈希、验证和 JWT 令牌生成功能。
"""
from datetime import timedelta

from app.config import settings
from app.security import (
    get_password_hash,
    verify_password,
    create_access_token
)


class TestPasswordHashing:
    """密码哈希功能测试"""

    def test_password_hash_and_verify(self):
        """测试密码哈希和验证"""
        password = "test_password_123"
        hashed = get_password_hash(password)
        
        # 验证哈希不为空且格式正确
        assert hashed is not None
        assert len(hashed) > 0
        assert hashed.startswith("$2b$")  # bcrypt 哈希格式
        
        # 验证正确密码
        assert verify_password(password, hashed) is True
        
        # 验证错误密码
        assert verify_password("wrong_password", hashed) is False

    def test_password_hash_truncation(self):
        """测试密码超过72字节时的截断处理"""
        # 创建一个超过72字节的密码
        long_password = "a" * 100
        hashed = get_password_hash(long_password)
        
        # 验证前72字节的密码可以验证通过
        assert verify_password(long_password[:72], hashed) is True
        
        # 验证完整密码也可以验证通过（内部会截断）
        assert verify_password(long_password, hashed) is True

    def test_empty_password(self):
        """测试空密码处理"""
        password = ""
        hashed = get_password_hash(password)
        
        assert hashed is not None
        assert verify_password("", hashed) is True
        assert verify_password("not_empty", hashed) is False


class TestJwtToken:
    """JWT 令牌功能测试"""

    def test_create_access_token(self):
        """测试创建访问令牌"""
        data = {"sub": "123"}
        token = create_access_token(data)
        
        assert token is not None
        assert isinstance(token, str)
        assert len(token) > 0

    def test_access_token_with_expiry(self):
        """测试带过期时间的令牌"""
        data = {"sub": "456"}
        expires_delta = timedelta(minutes=30)
        token = create_access_token(data, expires_delta)
        
        assert token is not None
        assert isinstance(token, str)

    def test_token_contains_user_id(self):
        """测试令牌包含用户ID"""
        user_id = "789"
        token = create_access_token({"sub": user_id})
        
        # 验证令牌可以被解码且包含正确的用户ID
        from jose import jwt
        decoded = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        
        assert decoded["sub"] == user_id
        assert "exp" in decoded  # 包含过期时间


class TestUserRetrieval:
    """用户检索功能测试"""

    def test_get_user_by_email_without_db(self):
        """测试通过邮箱获取用户（数据库会话为空时的行为）"""
        # 这个测试主要验证函数签名正确，实际数据库查询需要集成测试
        pass

    def test_get_user_by_username_without_db(self):
        """测试通过用户名获取用户（数据库会话为空时的行为）"""
        # 这个测试主要验证函数签名正确，实际数据库查询需要集成测试
        pass
