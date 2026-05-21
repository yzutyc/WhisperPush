import json
from typing import Optional

import requests

BASE_URL = "http://localhost:8000/api/v1"
HEALTH_URL = "http://localhost:8000/health"

TEST_USER_EMAIL = "test@example.com"
TEST_USER_PASSWORD = "testpassword"

test_secret_key = 'bf166061-b848-4bdc-9b14-0c3cb9fedbe8'
service_available = True

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


def test_push_message_text_with_url():
    if not service_available:
        return

    url_bodies = [
        "请访问 https://example.com 查看详情",
        "API 文档: http://localhost:8080/api/v1/docs",
        "带路径的链接: https://github.com/user/repo/issues/123",
        "带查询参数: https://search.example.com/results?q=keyword&page=1",
        "带锚点: https://docs.example.com/guide#installation",
        "多个链接: https://site1.com 和 https://site2.com/path",
    ]

    all_passed = True
    for body in url_bodies:
        response = push_message(
            title="纯文本包含URL",
            body=body,
            content_type="text"
        )
        if response.status_code != 200:
            all_passed = False

    assert all_passed, "部分 text+URL 测试失败"


def test_push_message_markdown_with_url():
    if not service_available:
        return

    md_bodies = [
        "行内链接: [Google](https://google.com)",
        "自动链接: <https://example.com>",
        "图片链接: ![Logo](https://example.com/logo.png)",
        "带标题的链接: [API文档](https://docs.example.com '点击查看')",
        "混合内容: 访问 [官网](https://example.com) 或 [GitHub](https://github.com/user/repo)\n\n![截图](https://img.example.com/screenshot.png)",
        "引用中的链接:\n> 参考 [RFC 3986](https://tools.ietf.org/html/rfc3986) 了解 URI 语法",
    ]

    all_passed = True
    for body in md_bodies:
        response = push_message(
            title="Markdown包含URL",
            body=body,
            content_type="markdown"
        )
        if response.status_code != 200:
            all_passed = False

    assert all_passed, "部分 markdown+URL 测试失败"


def test_push_message_html_with_url():
    if not service_available:
        return

    html_bodies = [
        '<a href="https://example.com">点击访问</a>',
        '<a href="https://example.com" target="_blank">新窗口打开</a>',
        '<a href="https://example.com"><img src="https://img.example.com/banner.png" alt="横幅"></a>',
        '<p>请访问 <a href="https://docs.example.com">文档</a> 或 <a href="https://github.com">GitHub</a></p>',
        '<ul><li><a href="https://site1.com">站点1</a></li><li><a href="https://site2.com">站点2</a></li></ul>',
        '<a href="https://example.com/search?q=keyword&sort=date">搜索结果</a>',
    ]

    all_passed = True
    for body in html_bodies:
        response = push_message(
            title="HTML包含URL",
            body=body,
            content_type="html"
        )
        if response.status_code != 200:
            all_passed = False

    assert all_passed, "部分 html+URL 测试失败"


def test_push_message_mixed_url_formats():
    if not service_available:
        return

    mixed_cases = [
        {
            "content_type": "text",
            "body": "部署完成: https://app.example.com/deploy/12345?env=prod&region=us-east-1#summary"
        },
        {
            "content_type": "markdown",
            "body": "## 发布日志\n\n- 修复 [Issue #42](https://github.com/user/repo/issues/42)\n- 合并 [PR #10](https://github.com/user/repo/pull/10)\n\n![构建状态](https://img.shields.io/badge/build-passing-brightgreen)"
        },
        {
            "content_type": "html",
            "body": '<div><h3>通知</h3><p>服务已上线，<a href="https://dashboard.example.com/status">查看状态</a></p><img src="https://monitor.example.com/chart.png" width="600"></div>'
        }
    ]

    all_passed = True
    for case in mixed_cases:
        response = push_message(
            title=f"混合URL测试-{case['content_type']}",
            body=case["body"],
            content_type=case["content_type"]
        )
        if response.status_code != 200:
            all_passed = False

    assert all_passed, "部分混合 URL 格式测试失败"


def _build_long_html() -> str:
    """构建包含各种常见 HTML 元素的超长网页内容。"""
    sections = []

    for i in range(1, 21):
        sections.append(f"<h1>第 {i} 章 - 技术文档标题</h1>")
        sections.append(f"<p>这是第 {i} 章的导言段落，包含<strong>加粗文本</strong>、<em>斜体文本</em>、<u>下划线文本</u>和<mark>高亮文本</mark>。普通文字与<code>内联代码</code>交替出现，还有<abbr title=\"HyperText Markup Language\">HTML</abbr>缩写和<sub>下标</sub>/<sup>上标</sup>。</p>")

        # 有序列表
        sections.append(f"<h2>{i}.1 有序列表</h2>")
        sections.append("<ol>")
        for j in range(1, 6):
            sections.append(f"<li>有序列表第 {j} 项，包含<a href=\"https://example.com/item/{i}/{j}\">链接</a></li>")
        sections.append("</ol>")

        # 无序列表
        sections.append(f"<h2>{i}.2 无序列表</h2>")
        sections.append("<ul>")
        for j in range(1, 6):
            sections.append(f"<li>无序列表第 {j} 项，包含<code>var_{i}_{j}</code> 变量引用</li>")
        sections.append("</ul>")

        # 定义列表
        sections.append(f"<h2>{i}.3 定义列表</h2>")
        sections.append("<dl>")
        sections.append(f"<dt>术语 {i}A</dt><dd>术语 {i}A 的详细定义说明</dd>")
        sections.append(f"<dt>术语 {i}B</dt><dd>术语 {i}B 的详细定义说明</dd>")
        sections.append("</dl>")

        # 表格
        sections.append(f"<h2>{i}.4 数据表格</h2>")
        sections.append("<table><thead><tr><th>参数</th><th>类型</th><th>默认值</th><th>说明</th></tr></thead><tbody>")
        for j in range(1, 5):
            sections.append(f"<tr><td>param_{i}_{j}</td><td>{'string' if j % 2 else 'integer'}</td><td>{j * 10}</td><td>参数 {i}-{j} 的功能描述</td></tr>")
        sections.append("</tbody></table>")

        # 表单元素
        sections.append(f"<h2>{i}.5 表单示例</h2>")
        sections.append(f"""<form action="/submit/{i}" method="post">
  <label for="name_{i}">姓名:</label>
  <input type="text" id="name_{i}" name="name" placeholder="请输入姓名" required><br><br>
  <label for="email_{i}">邮箱:</label>
  <input type="email" id="email_{i}" name="email" placeholder="user@example.com"><br><br>
  <label for="age_{i}">年龄:</label>
  <input type="number" id="age_{i}" name="age" min="1" max="120" value="25"><br><br>
  <label for="date_{i}">日期:</label>
  <input type="date" id="date_{i}" name="date"><br><br>
  <label for="color_{i}">颜色:</label>
  <input type="color" id="color_{i}" name="color" value="#8B5CF6"><br><br>
  <label for="range_{i}">范围:</label>
  <input type="range" id="range_{i}" name="range" min="0" max="100" value="50"><br><br>
  <fieldset>
    <legend>偏好设置</legend>
    <input type="checkbox" id="notify_{i}" name="notify" checked>
    <label for="notify_{i}">启用通知</label>
    <input type="checkbox" id="digest_{i}" name="digest">
    <label for="digest_{i}">每日摘要</label><br>
    <input type="radio" id="theme_light_{i}" name="theme" value="light">
    <label for="theme_light_{i}">浅色主题</label>
    <input type="radio" id="theme_dark_{i}" name="theme" value="dark" checked>
    <label for="theme_dark_{i}">深色主题</label>
  </fieldset><br>
  <label for="lang_{i}">语言:</label>
  <select id="lang_{i}" name="lang">
    <optgroup label="常用">
      <option value="zh">中文</option>
      <option value="en" selected>English</option>
    </optgroup>
    <optgroup label="其他">
      <option value="ja">日本語</option>
      <option value="ko">한국어</option>
    </optgroup>
  </select><br><br>
  <label for="bio_{i}">简介:</label>
  <textarea id="bio_{i}" name="bio" rows="3" cols="40">这是默认的简介文本内容</textarea><br><br>
  <button type="submit">提交</button>
  <button type="reset">重置</button>
</form>""")

        # 图片与媒体
        sections.append(f"<h2>{i}.6 媒体元素</h2>")
        sections.append(f'<img src="https://picsum.photos/seed/{i}/600/300" alt="示例图片 {i}" width="600" height="300" loading="lazy">')
        sections.append(f"<figure><img src=\"https://picsum.photos/seed/fig{i}/400/200\" alt=\"图表 {i}\"><figcaption>图 {i}: 性能测试结果</figcaption></figure>")
        sections.append(f"""<audio controls>
  <source src="https://example.com/audio/{i}.mp3" type="audio/mpeg">
  <source src="https://example.com/audio/{i}.ogg" type="audio/ogg">
  您的浏览器不支持音频播放
</audio>""")
        sections.append(f"""<video width="640" height="360" controls>
  <source src="https://example.com/video/{i}.mp4" type="video/mp4">
  <source src="https://example.com/video/{i}.webm" type="video/webm">
  您的浏览器不支持视频播放
</video>""")

        # 引用与代码块
        sections.append(f"<h2>{i}.7 引用与代码</h2>")
        sections.append(f"<blockquote cite=\"https://example.com/quote/{i}\"><p>这是第 {i} 章的重要引述内容，表达了核心观点。</p><footer>— <cite>技术专家 {i}</cite></footer></blockquote>")
        sections.append(f"""<pre><code class="language-python">def process_{i}(data: dict) -> list:
    \"\"\"处理第 {i} 批数据\"\"\"
    results = []
    for key, value in data.items():
        if isinstance(value, (int, float)):
            results.append(value * {i})
        elif isinstance(value, str):
            results.append(f"{{key}}: {{value}}")
    return sorted(results, reverse=True)

# 调用示例
output = process_{i}({{"a": 10, "b": "hello", "c": 3.14}})
print(output)  # [20, 3.14, 'b: hello']
</code></pre>""")

        # 语义化标签
        sections.append(f"<h2>{i}.8 语义化区块</h2>")
        sections.append(f"""<article>
  <header>
    <h3>文章标题 {i}</h3>
    <time datetime="2026-05-21">2026年5月21日</time>
  </header>
  <p>这是使用 <code>&lt;article&gt;</code> 语义标签包裹的独立内容块，包含完整的首尾结构。</p>
  <details>
    <summary>点击展开详细信息</summary>
    <p>这是第 {i} 章的详细说明内容，默认折叠显示。包含更多技术细节和参考信息。</p>
  </details>
  <footer><small>版权所有 &copy; 2026 WhisperPush</small></footer>
</article>""")

        # 水平线与特殊元素
        sections.append("<hr>")
        sections.append(f"<address>联系方式: <a href=\"mailto:dev{i}@example.com\">dev{i}@example.com</a><br>地址: 科技路 {i} 号</address>")

    # 包裹在完整 HTML 结构中
    return f"""<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>超长 HTML 测试文档</title>
  <style>
    body {{ font-family: -apple-system, sans-serif; max-width: 960px; margin: 0 auto; padding: 20px; }}
    table {{ border-collapse: collapse; width: 100%; }}
    th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
    th {{ background-color: #8B5CF6; color: white; }}
    blockquote {{ border-left: 4px solid #8B5CF6; margin: 1em 0; padding: 0.5em 1em; background: #f8f8f8; }}
    code {{ background: #f4f4f4; padding: 2px 6px; border-radius: 3px; }}
    pre {{ background: #2d2d2d; color: #f8f8f2; padding: 16px; border-radius: 8px; overflow-x: auto; }}
    img {{ max-width: 100%; height: auto; }}
    form {{ margin: 1em 0; }}
    fieldset {{ border: 1px solid #ddd; border-radius: 8px; padding: 12px; }}
    legend {{ font-weight: bold; }}
  </style>
</head>
<body>
  <header>
    <nav>
      <a href="#home">首页</a> |
      <a href="#docs">文档</a> |
      <a href="#api">API</a> |
      <a href="#about">关于</a>
    </nav>
  </header>
  <main>
{"".join(sections)}
  </main>
  <footer>
    <p><small>本文档共包含 20 个章节，用于测试超长 HTML 内容推送。</small></p>
  </footer>
</body>
</html>"""


def _build_long_markdown() -> str:
    """构建包含各种常见 Markdown 元素的超长内容。"""
    sections = []

    for i in range(1, 21):
        sections.append(f"# 第 {i} 章 - 技术文档标题\n")
        sections.append(f"这是第 {i} 章的导言段落，包含**加粗文本**、*斜体文本**、***粗斜体***、~~删除线~~和`内联代码`。还有[超链接](https://example.com/chapter/{i})指向外部资源。\n")

        # 标题层级
        sections.append(f"## {i}.1 功能概述\n")
        sections.append(f"### {i}.1.1 子模块 A\n")
        sections.append(f"这是子模块 A 的说明，支持**多级标题**嵌套使用。\n")
        sections.append(f"### {i}.1.2 子模块 B\n")
        sections.append(f"这是子模块 B 的说明，与子模块 A 形成[对比](https://example.com/compare/{i})。\n")

        # 有序列表
        sections.append(f"## {i}.2 实施步骤\n")
        for j in range(1, 8):
            sections.append(f"{j}. 步骤 {j}: 执行操作 `action_{i}_{j}()` 并验证结果")
        sections.append("")

        # 无序列表
        sections.append(f"## {i}.3 注意事项\n")
        items = [
            "确保网络连接正常",
            "检查配置文件 `config.yaml` 中的参数",
            "备份现有数据至 `/backup/chapter_{i}`",
            "通知相关团队成员 <team@example.com>",
            "记录操作日志以供审计",
        ]
        for item in items:
            sections.append(f"- {item}")
        sections.append("")

        # 任务列表
        sections.append(f"## {i}.4 任务清单\n")
        tasks = [
            (True, "需求分析"),
            (True, "架构设计"),
            (False, "编码实现"),
            (False, "单元测试"),
            (False, "集成测试"),
        ]
        for done, task in tasks:
            mark = "x" if done else " "
            sections.append(f"- [{mark}] {task}")
        sections.append("")

        # 表格
        sections.append(f"## {i}.5 参数说明\n")
        sections.append("| 参数名 | 类型 | 必填 | 默认值 | 说明 |")
        sections.append("|--------|------|------|--------|------|")
        for j in range(1, 6):
            ptype = "string" if j % 2 else "integer"
            required = "是" if j <= 2 else "否"
            default = f"`{j * 100}`" if j > 2 else "-"
            sections.append(f"| `param_{i}_{j}` | {ptype} | {required} | {default} | 第 {i} 组第 {j} 个参数 |")
        sections.append("")

        # 代码块（多语言）
        sections.append(f"## {i}.6 代码示例\n")
        sections.append(f"""```python
def process_{i}(data: dict) -> list:
    \"\"\"处理第 {i} 批数据

    Args:
        data: 输入数据字典

    Returns:
        处理后的排序结果列表

    Raises:
        ValueError: 当数据格式不正确时
    \"\"\"
    results = []
    for key, value in data.items():
        if isinstance(value, (int, float)):
            results.append(value * {i})
        elif isinstance(value, str):
            results.append(f"{{key}}: {{value}}")
    return sorted(results, reverse=True)

# 调用示例
output = process_{i}({{"a": 10, "b": "hello", "c": 3.14}})
print(output)  # [20, 3.14, 'b: hello']
```\n""")

        sections.append(f"""```javascript
async function process{i}(data) {{
  const results = await Promise.all(
    Object.entries(data).map(([key, value]) => {{
      if (typeof value === 'number') return value * {i};
      if (typeof value === 'string') return `${{key}}: ${{value}}`;
      return null;
    }})
  );
  return results.filter(Boolean).sort((a, b) => b - a);
}}

// Usage
process{i}({{ a: 10, b: 'hello', c: 3.14 }}).then(console.log);
```\n""")

        sections.append(f"""```sql
-- 第 {i} 章数据查询
SELECT
    u.id,
    u.username,
    COUNT(m.id) AS message_count,
    MAX(m.created_at) AS last_message
FROM users u
LEFT JOIN messages m ON m.user_id = u.id
WHERE u.active = true
    AND m.created_at >= '2026-01-01'
GROUP BY u.id, u.username
HAVING COUNT(m.id) > {i}
ORDER BY message_count DESC
LIMIT 50;
```\n""")

        # 引用
        sections.append(f"## {i}.7 参考引述\n")
        sections.append(f"> 这是一段重要的引述内容，来自[技术专家 {i}](https://example.com/expert/{i})的著作。\n")
        sections.append(f"> \n")
        sections.append(f"> — *技术专家 {i}*，《高级编程实践》第 {i} 版\n")

        # 嵌套引用
        sections.append(f">> 嵌套引用：这段内容是对上述观点的补充说明，提供更多上下文和背景信息。\n")

        # 图片
        sections.append(f"## {i}.8 图表与媒体\n")
        sections.append(f"![示例图片 {i}](https://picsum.photos/seed/md{i}/600/300 \"第 {i} 章配图\")\n")
        sections.append(f"![性能图表](https://picsum.photos/seed/chart{i}/800/400 \"性能测试结果\")\n")

        # 分隔线
        sections.append("---\n")

        # 脚注
        sections.append(f"这段内容包含脚注[^{i}a]和另一个脚注[^{i}b]。\n")
        sections.append(f"[^{i}a]: 第 {i} 章，脚注 A — 详细说明链接。\n")
        sections.append(f"[^{i}b]: 第 {i} 章，脚注 B — 补充参考资料。\n")

    # YAML front matter
    front_matter = """---
title: 超长 Markdown 测试文档
author: WhisperPush Team
date: 2026-05-21
version: "0.1.9"
tags: [test, markdown, long-content]
---

"""

    return front_matter + "\n".join(sections)


def test_push_message_long_html_content():
    if not service_available:
        return

    long_html = _build_long_html()
    assert len(long_html) > 50000, f"HTML 内容长度不足，当前 {len(long_html)} 字符"

    response = push_message(
        title="超长 HTML 内容测试 - 包含各种常见 HTML 元素",
        body=long_html,
        content_type="html",
        level="info"
    )

    assert response.status_code == 200, f"期望状态码 200，实际得到 {response.status_code}，body 长度: {len(long_html)}"
    result = response.json()
    assert result["status"] == "success", f"期望 status=success，实际得到 {result['status']}"
    assert "message_id" in result, "响应缺少 message_id 字段"


def test_push_message_long_markdown_content():
    if not service_available:
        return

    long_md = _build_long_markdown()
    assert len(long_md) > 30000, f"Markdown 内容长度不足，当前 {len(long_md)} 字符"

    response = push_message(
        title="超长 Markdown 内容测试 - 包含各种常见 Markdown 元素",
        body=long_md,
        content_type="markdown",
        level="info"
    )

    assert response.status_code == 200, f"期望状态码 200，实际得到 {response.status_code}，body 长度: {len(long_md)}"
    result = response.json()
    assert result["status"] == "success", f"期望 status=success，实际得到 {result['status']}"
    assert "message_id" in result, "响应缺少 message_id 字段"

