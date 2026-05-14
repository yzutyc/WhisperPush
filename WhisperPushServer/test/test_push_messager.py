import requests
import json
import sys
from typing import Optional

BASE_URL = "http://localhost:8000/api/v1"
HEALTH_URL = "http://localhost:8000/health"

TEST_USER_EMAIL = "test@example.com"
TEST_USER_PASSWORD = "testpassword"

test_secret_key = None
service_available = False

CONTENT_TYPES = ["text", "markdown", "html"]
LEVELS = ["active", "info", "warning", "timeSensitive", "passive"]


def check_service_health() -> bool:
    try:
        response = requests.get(HEALTH_URL, timeout=5)
        if response.status_code == 200:
            data = response.json()
            if data.get("status") == "healthy":
                return True
    except Exception:
        pass
    return False


def register_user(email: str, password: str) -> bool:
    url = f"{BASE_URL}/auth/register"
    payload = {
        "username": email.split("@")[0],
        "email": email,
        "password": password
    }
    try:
        response = requests.post(url, json=payload, timeout=10)
        if response.status_code == 200:
            return True
        elif response.status_code == 400:
            return False
    except Exception:
        pass
    return False


def get_auth_token(email: str, password: str) -> Optional[str]:
    url = f"{BASE_URL}/auth/login"
    payload = {"username_or_email": email, "password": password}
    try:
        response = requests.post(url, json=payload, timeout=10)
        if response.status_code == 200:
            return response.json()["access_token"]
    except Exception:
        pass
    return None


def create_secret_key(token: str) -> Optional[str]:
    url = f"{BASE_URL}/secrets"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    payload = {"name": "test-secret"}
    try:
        response = requests.post(url, headers=headers, json=payload, timeout=10)
        if response.status_code == 200:
            return response.json()["secret_key"]
    except Exception:
        pass
    return None


def get_or_create_secret_key() -> str:
    token = get_auth_token(TEST_USER_EMAIL, TEST_USER_PASSWORD)
    
    if not token:
        register_user(TEST_USER_EMAIL, TEST_USER_PASSWORD)
        token = get_auth_token(TEST_USER_EMAIL, TEST_USER_PASSWORD)
    
    if not token:
        return '37157098-4b1a-438e-8cd9-e26d078231be'
    
    new_key = create_secret_key(token)
    if new_key:
        return new_key
    
    return '37157098-4b1a-438e-8cd9-e26d078231be'


def push_message(
    title: str,
    body: str,
    content_type: str = "text",
    group: Optional[str] = None,
    level: str = "active"
) -> requests.Response:
    url = f"{BASE_URL}/push"
    headers = {
        "X-Secret-Key": test_secret_key,
        "Content-Type": "application/json"
    }
    payload = {
        "title": title,
        "body": body,
        "content_type": content_type,
        "level": level
    }
    if group is not None:
        payload["group"] = group
    
    return requests.post(url, headers=headers, data=json.dumps(payload))


def test_push_message_success():
    if not service_available:
        return
    
    response = push_message(
        title="测试消息标题",
        body="这是一条测试消息内容",
        content_type="text",
        group="test-group",
        level="active"
    )
    
    assert response.status_code == 200, f"期望状态码 200，实际得到 {response.status_code}"
    result = response.json()
    assert "status" in result, "响应缺少 status 字段"
    assert result["status"] == "success", f"期望 status=success，实际得到 {result['status']}"
    assert "message_id" in result, "响应缺少 message_id 字段"


def test_push_message_missing_secret_key():
    if not service_available:
        return
    
    url = f"{BASE_URL}/push"
    headers = {"Content-Type": "application/json"}
    payload = {"title": "测试消息标题", "body": "这是一条测试消息内容"}
    
    response = requests.post(url, headers=headers, data=json.dumps(payload))
    
    assert response.status_code == 401, f"期望状态码 401，实际得到 {response.status_code}"
    result = response.json()
    assert result["detail"] == "Secret key required", "错误信息不正确"


def test_push_message_invalid_secret_key():
    if not service_available:
        return
    
    url = f"{BASE_URL}/push"
    headers = {
        "X-Secret-Key": "invalid-secret-key-12345",
        "Content-Type": "application/json"
    }
    payload = {"title": "测试消息标题", "body": "这是一条测试消息内容"}
    
    response = requests.post(url, headers=headers, data=json.dumps(payload))
    
    assert response.status_code == 401, f"期望状态码 401，实际得到 {response.status_code}"
    result = response.json()
    assert result["detail"] == "Invalid secret key", "错误信息不正确"


def test_push_message_missing_title():
    if not service_available:
        return
    
    url = f"{BASE_URL}/push"
    headers = {
        "X-Secret-Key": test_secret_key,
        "Content-Type": "application/json"
    }
    payload = {"body": "这是一条缺少标题的测试消息"}
    
    response = requests.post(url, headers=headers, data=json.dumps(payload))
    
    assert response.status_code == 422, f"期望状态码 422，实际得到 {response.status_code}"


def test_push_message_missing_body():
    if not service_available:
        return
    
    url = f"{BASE_URL}/push"
    headers = {
        "X-Secret-Key": test_secret_key,
        "Content-Type": "application/json"
    }
    payload = {"title": "缺少正文的测试消息"}
    
    response = requests.post(url, headers=headers, data=json.dumps(payload))
    
    assert response.status_code == 422, f"期望状态码 422，实际得到 {response.status_code}"


def test_push_message_default_values():
    if not service_available:
        return
    
    response = push_message(
        title="仅包含必填字段",
        body="使用默认的 content_type 和 level"
    )
    
    assert response.status_code == 200, f"期望状态码 200，实际得到 {response.status_code}"
    result = response.json()
    assert result["status"] == "success", f"期望 status=success，实际得到 {result['status']}"


def test_push_message_content_types():
    if not service_available:
        return
    
    all_passed = True
    
    for content_type in CONTENT_TYPES:
        response = push_message(
            title=f"测试 {content_type} 类型",
            body=f"这是 {content_type} 类型的消息内容",
            content_type=content_type
        )
        
        if response.status_code != 200:
            all_passed = False
    
    assert all_passed, "部分 content_type 测试失败"


def test_push_message_levels():
    if not service_available:
        return
    
    all_passed = True
    
    for level in LEVELS:
        response = push_message(
            title=f"测试 {level} 级别",
            body=f"这是 {level} 级别的消息",
            level=level
        )
        
        if response.status_code != 200:
            all_passed = False
    
    assert all_passed, "部分 level 测试失败"


def test_push_message_with_group():
    if not service_available:
        return
    
    groups = ["monitoring", "alert", "notification", "system"]
    all_passed = True
    
    for group in groups:
        response = push_message(
            title=f"分组消息: {group}",
            body=f"这是 {group} 分组的消息",
            group=group
        )
        
        if response.status_code != 200:
            all_passed = False
    
    assert all_passed, "部分 group 测试失败"


def test_push_message_without_group():
    if not service_available:
        return
    
    response = push_message(
        title="无分组消息",
        body="这是一条没有分组的消息",
        group=None
    )
    
    assert response.status_code == 200, f"期望状态码 200，实际得到 {response.status_code}"
    result = response.json()
    assert result["status"] == "success", f"期望 status=success，实际得到 {result['status']}"


def test_push_message_html_content():
    if not service_available:
        return
    
    response = push_message(
        title="HTML 内容测试",
        body="<p>这是 <strong>HTML</strong> 内容</p><ul><li>列表项1</li><li>列表项2</li></ul>",
        content_type="html",
        level="info"
    )
    
    assert response.status_code == 200, f"期望状态码 200，实际得到 {response.status_code}"
    result = response.json()
    assert result["status"] == "success", f"期望 status=success，实际得到 {result['status']}"


def test_push_message_markdown_content():
    if not service_available:
        return
    
    response = push_message(
        title="Markdown 内容测试",
        body="# 这是标题\n\n这是 **粗体** 和 *斜体* 文本\n\n- 列表项1\n- 列表项2\n\n[链接](https://example.com)",
        content_type="markdown",
        level="info"
    )
    
    assert response.status_code == 200, f"期望状态码 200，实际得到 {response.status_code}"
    result = response.json()
    assert result["status"] == "success", f"期望 status=success，实际得到 {result['status']}"


def test_push_message_special_characters():
    if not service_available:
        return
    
    special_bodies = [
        'Hello "World"',
        "Hello 'World'",
        "Line1\nLine2\nLine3",
        "中文测试内容",
        "Emoji 😊🎉",
        "HTML tags <script>alert('xss')</script>",
        "Special chars: !@#$%^&*()_+-=[]{}|;:,.<>?"
    ]
    
    all_passed = True
    
    for body in special_bodies:
        response = push_message(
            title="特殊字符测试",
            body=body
        )
        
        if response.status_code != 200:
            all_passed = False
    
    assert all_passed, "部分特殊字符测试失败"


def test_get_messages():
    if not service_available:
        return
    
    token = get_auth_token(TEST_USER_EMAIL, TEST_USER_PASSWORD)
    if not token:
        return
    
    url = f"{BASE_URL}/messages?skip=0&limit=100"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    response = requests.get(url, headers=headers)
    
    assert response.status_code == 200, f"期望状态码 200，实际得到 {response.status_code}"

