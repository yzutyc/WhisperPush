import requests
import json

BASE_URL = "http://localhost:8000/api/v1"

# 测试用的登录凭证
TEST_USER_EMAIL = "test@example.com"
TEST_USER_PASSWORD = "testpassword"

# 当前使用的 secret key（需要为测试用户创建）
test_secret_key = None


def get_auth_token(email, password):
    """获取认证 token"""
    url = f"{BASE_URL}/auth/login"
    payload = {"username_or_email": email, "password": password}
    response = requests.post(url, json=payload)
    if response.status_code == 200:
        return response.json()["access_token"]
    print(f"登录失败: {response.text}")
    return None


def create_secret_key(token):
    """创建新的 secret key"""
    url = f"{BASE_URL}/secrets"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    payload = {"name": "test-secret"}
    response = requests.post(url, headers=headers, json=payload)
    if response.status_code == 200:
        return response.json()["secret_key"]
    print(f"创建 secret key 失败: {response.text}")
    return None


def get_or_create_secret_key():
    """获取或创建测试用户的 secret key"""
    print("=== 获取测试用户的 Secret Key ===")
    token = get_auth_token(TEST_USER_EMAIL, TEST_USER_PASSWORD)
    if not token:
        print("✗ 登录失败，使用默认 secret key")
        return '37157098-4b1a-438e-8cd9-e26d078231be'
    
    print("✓ 登录成功")
    
    # 先尝试获取已有的 secret keys
    url = f"{BASE_URL}/secrets"
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(url, headers=headers)
    
    if response.status_code == 200:
        secrets = response.json()
        if len(secrets) > 0:
            key = secrets[0].get("secret_key")
            if key:
                print(f"✓ 找到已存在的 secret key")
                return key
    
    # 创建新的 secret key
    new_key = create_secret_key(token)
    if new_key:
        print(f"✓ 创建新的 secret key")
        return new_key
    
    print("✗ 无法获取 secret key，使用默认值")
    return '37157098-4b1a-438e-8cd9-e26d078231be'


def test_push_message_success():
    """测试正常推送消息"""
    url = f"{BASE_URL}/push"
    headers = {
        "X-Secret-Key": test_secret_key,
        "Content-Type": "application/json"
    }
    payload = {
        "title": "测试消息标题",
        "body": "这是一条测试消息内容",
        "content_type": "text",
        "group": "test-group",
        "level": "active"
    }
    
    response = requests.post(url, headers=headers, data=json.dumps(payload))
    
    print(f"=== 测试正常推送 ===")
    print(f"状态码: {response.status_code}")
    print(f"响应: {response.text}")
    
    assert response.status_code == 200, f"期望状态码 200，实际得到 {response.status_code}"
    result = response.json()
    assert "status" in result, "响应缺少 status 字段"
    assert result["status"] == "success", f"期望 status=success，实际得到 {result['status']}"
    assert "message_id" in result, "响应缺少 message_id 字段"
    print("✓ 测试通过\n")


def test_push_message_missing_secret_key():
    """测试缺少 secret key"""
    url = f"{BASE_URL}/push"
    headers = {
        "Content-Type": "application/json"
    }
    payload = {
        "title": "测试消息标题",
        "body": "这是一条测试消息内容"
    }
    
    response = requests.post(url, headers=headers, data=json.dumps(payload))
    
    print(f"=== 测试缺少 secret key ===")
    print(f"状态码: {response.status_code}")
    print(f"响应: {response.text}")
    
    assert response.status_code == 401, f"期望状态码 401，实际得到 {response.status_code}"
    result = response.json()
    assert result["detail"] == "Secret key required", "错误信息不正确"
    print("✓ 测试通过\n")


def test_push_message_invalid_secret_key():
    """测试无效的 secret key"""
    url = f"{BASE_URL}/push"
    headers = {
        "X-Secret-Key": "invalid-secret-key-12345",
        "Content-Type": "application/json"
    }
    payload = {
        "title": "测试消息标题",
        "body": "这是一条测试消息内容"
    }
    
    response = requests.post(url, headers=headers, data=json.dumps(payload))
    
    print(f"=== 测试无效 secret key ===")
    print(f"状态码: {response.status_code}")
    print(f"响应: {response.text}")
    
    assert response.status_code == 401, f"期望状态码 401，实际得到 {response.status_code}"
    result = response.json()
    assert result["detail"] == "Invalid secret key", "错误信息不正确"
    print("✓ 测试通过\n")


def test_push_message_missing_title():
    """测试缺少标题字段"""
    url = f"{BASE_URL}/push"
    headers = {
        "X-Secret-Key": test_secret_key,
        "Content-Type": "application/json"
    }
    payload = {
        "body": "这是一条缺少标题的测试消息"
    }
    
    response = requests.post(url, headers=headers, data=json.dumps(payload))
    
    print(f"=== 测试缺少标题 ===")
    print(f"状态码: {response.status_code}")
    print(f"响应: {response.text}")
    
    assert response.status_code == 422, f"期望状态码 422，实际得到 {response.status_code}"
    print("✓ 测试通过\n")


def test_push_message_missing_body():
    """测试缺少正文字段"""
    url = f"{BASE_URL}/push"
    headers = {
        "X-Secret-Key": test_secret_key,
        "Content-Type": "application/json"
    }
    payload = {
        "title": "缺少正文的测试消息"
    }
    
    response = requests.post(url, headers=headers, data=json.dumps(payload))
    
    print(f"=== 测试缺少正文 ===")
    print(f"状态码: {response.status_code}")
    print(f"响应: {response.text}")
    
    assert response.status_code == 422, f"期望状态码 422，实际得到 {response.status_code}"
    print("✓ 测试通过\n")


def test_push_message_default_values():
    """测试使用默认值"""
    url = f"{BASE_URL}/push"
    headers = {
        "X-Secret-Key": test_secret_key,
        "Content-Type": "application/json"
    }
    payload = {
        "title": "仅包含必填字段",
        "body": "使用默认的 content_type 和 level"
    }
    
    response = requests.post(url, headers=headers, data=json.dumps(payload))
    
    print(f"=== 测试默认值 ===")
    print(f"状态码: {response.status_code}")
    print(f"响应: {response.text}")
    
    assert response.status_code == 200, f"期望状态码 200，实际得到 {response.status_code}"
    result = response.json()
    assert result["status"] == "success", f"期望 status=success，实际得到 {result['status']}"
    print("✓ 测试通过\n")


def test_push_message_with_custom_content_type():
    """测试自定义 content_type"""
    url = f"{BASE_URL}/push"
    headers = {
        "X-Secret-Key": test_secret_key,
        "Content-Type": "application/json"
    }
    payload = {
        "title": "HTML 内容测试",
        "body": "<p>这是 <strong>HTML</strong> 内容</p>",
        "content_type": "html",
        "level": "info"
    }
    
    response = requests.post(url, headers=headers, data=json.dumps(payload))
    
    print(f"=== 测试自定义 content_type ===")
    print(f"状态码: {response.status_code}")
    print(f"响应: {response.text}")
    
    assert response.status_code == 200, f"期望状态码 200，实际得到 {response.status_code}"
    result = response.json()
    assert result["status"] == "success", f"期望 status=success，实际得到 {result['status']}"
    print("✓ 测试通过\n")


def test_push_message_markdown():
    """测试 markdown 内容"""
    url = f"{BASE_URL}/push"
    headers = {
        "X-Secret-Key": test_secret_key,
        "Content-Type": "application/json"
    }
    payload = {
        "title": "Markdown 内容测试",
        "body": "# 这是 Markdown 标题\n\n这是 **Markdown** 内容",
        "content_type": "markdown",
        "level": "info"
    }
    
    response = requests.post(url, headers=headers, data=json.dumps(payload))
    
    print(f"=== 测试 Markdown 内容 ===")
    print(f"状态码: {response.status_code}")
    print(f"响应: {response.text}")
    
    assert response.status_code == 200, f"期望状态码 200，实际得到 {response.status_code}"
    result = response.json()
    assert result["status"] == "success", f"期望 status=success，实际得到 {result['status']}"
    print("✓ 测试通过\n")


def test_get_messages():
    """测试获取消息列表"""
    token = get_auth_token(TEST_USER_EMAIL, TEST_USER_PASSWORD)
    if not token:
        print("=== 跳过获取消息测试（登录失败）===")
        return
    
    url = f"{BASE_URL}/messages?skip=0&limit=100"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    response = requests.get(url, headers=headers)
    
    print(f"=== 测试获取消息列表 ===")
    print(f"状态码: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"消息数量: {len(data)}")
        if len(data) > 0:
            print(f"第一条消息: {data[0]['title']}")
        print("✓ 测试通过\n")
    else:
        print(f"获取消息失败: {response.text}")


if __name__ == "__main__":
    print("=" * 50)
    print("Push Message API 测试套件")
    print("=" * 50 + "\n")
    
    # 获取测试用户的 secret key
    test_secret_key = get_or_create_secret_key()
    print(f"使用的 Secret Key: {test_secret_key[:10]}...\n")
    
    try:
        test_push_message_success()
        test_push_message_missing_secret_key()
        test_push_message_invalid_secret_key()
        test_push_message_missing_title()
        test_push_message_missing_body()
        test_push_message_default_values()
        test_push_message_with_custom_content_type()
        test_push_message_markdown()
        test_get_messages()
        
        print("=" * 50)
        print("所有测试通过!")
        print("=" * 50)
    except AssertionError as e:
        print(f"\n✗ 测试失败: {e}")
        exit(1)
    except requests.exceptions.ConnectionError:
        print("\n✗ 无法连接到服务器，请确保服务器正在运行")
        exit(1)