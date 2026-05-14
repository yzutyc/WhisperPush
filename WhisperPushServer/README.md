# WhisperPush Server

消息推送系统后端服务，基于 FastAPI + SQLAlchemy + PostgreSQL 构建，支持实时消息推送和多平台通知。

## 功能特性

### 核心功能
- **用户认证**：注册、登录、JWT Token 认证、密码修改、忘记密码
- **双因素认证**：TOTP 双因素认证支持，提高账户安全性
- **Secret 管理**：创建、查询、删除推送秘钥
- **消息推送**：支持 text/markdown/html 三种内容格式
- **消息管理**：消息列表、详情、标记已读/未读、删除
- **实时推送**：WebSocket 实时消息推送
- **系统通知**：支持 APNs (iOS) 和 FCM (Android) 系统级推送通知
- **设备管理**：设备注册、列表、删除

### 安全特性
- JWT Token 认证机制
- 密码使用 bcrypt 加密存储
- 双因素认证支持
- 请求日志记录（方法、路径、状态码、耗时、客户端IP）
- 异常错误日志记录

### 运维特性
- 健康检查接口 `/health`
- 自动数据库迁移（Alembic）
- Docker 容器化支持

## 技术栈

- Python 3.10+
- FastAPI 0.109+
- SQLAlchemy 2.0+
- PostgreSQL 15+ / SQLite（开发/测试）
- JWT (python-jose)
- bcrypt 密码加密
- pyotp 双因素认证
- AioHTTP WebSocket
- Alembic 数据库迁移

## 快速开始

### 环境要求

- Python 3.10+
- PostgreSQL 15+（生产环境）
- SQLite（开发/测试环境，自动配置）

### 使用 Docker Compose（推荐）

```bash
# 启动服务
docker-compose up -d

# 执行数据库迁移
docker-compose exec api alembic upgrade head
```

### 手动启动

```bash
# 安装依赖（使用 uv 或 pip）
pip install .

# 或者使用开发模式
pip install -e .

# 设置环境变量
cp .env.example .env
# 编辑 .env 文件配置数据库连接

# 执行数据库迁移
alembic upgrade head

# 启动服务
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 运行测试

```bash
# 运行所有测试
pytest test/ -v

# 运行特定测试文件
pytest test/test_auth.py -v
pytest test/test_messages.py -v
pytest test/test_security.py -v

# 测试覆盖率
pytest test/ -v --cov=app
```

## 项目结构

```
.
├── app/                    # 应用代码
│   ├── __init__.py
│   ├── main.py             # 应用入口
│   ├── config.py           # 配置管理
│   ├── database.py         # 数据库连接
│   ├── models.py           # SQLAlchemy 模型
│   ├── schemas.py          # Pydantic 模式
│   ├── security.py         # 安全工具（密码哈希、JWT）
│   ├── dependencies.py     # 依赖注入
│   ├── websocket.py        # WebSocket 管理器
│   ├── push_service.py     # APNs/FCM 推送服务
│   ├── middleware/         # 中间件
│   │   └── logging_middleware.py  # 请求日志中间件
│   └── routers/            # API 路由
│       ├── auth.py         # 认证接口
│       ├── secrets.py      # Secret 管理
│       ├── messages.py     # 消息接口
│       ├── devices.py      # 设备管理接口
│       └── two_factor.py   # 双因素认证接口
├── test/                   # 单元测试
│   ├── test_auth.py        # 认证测试
│   ├── test_messages.py    # 消息测试
│   └── test_security.py    # 安全模块测试
├── alembic/                # 数据库迁移
├── .env                    # 环境变量
├── .env.example            # 环境变量示例
├── docker-compose.yml      # Docker 配置
├── Dockerfile              # Docker 镜像
├── pyproject.toml          # 项目配置与依赖
└── README.md               # 项目说明
```

## API 接口

### 认证接口

| 方法 | 路径 | 功能 | 认证 |
|------|------|------|------|
| POST | `/api/v1/auth/register` | 用户注册 | 否 |
| POST | `/api/v1/auth/login` | 用户登录 | 否 |
| GET | `/api/v1/auth/me` | 获取当前用户 | 是 |
| POST | `/api/v1/auth/logout` | 用户登出 | 是 |
| POST | `/api/v1/auth/forgot-password` | 忘记密码 | 否 |
| POST | `/api/v1/auth/change-password` | 修改密码 | 是 |

### 双因素认证接口

| 方法 | 路径 | 功能 | 认证 |
|------|------|------|------|
| GET | `/api/v1/two-factor/status` | 获取双因素认证状态 | 是 |
| POST | `/api/v1/two-factor/enable` | 启用双因素认证 | 是 |
| POST | `/api/v1/two-factor/verify` | 验证双因素认证码 | 是 |
| POST | `/api/v1/two-factor/disable` | 禁用双因素认证 | 是 |
| GET | `/api/v1/two-factor/recovery-codes` | 获取恢复码 | 是 |

### Secret 管理接口

| 方法 | 路径 | 功能 | 认证 |
|------|------|------|------|
| POST | `/api/v1/secrets` | 创建 Secret | 是 |
| GET | `/api/v1/secrets` | 列出所有 Secret | 是 |
| DELETE | `/api/v1/secrets/{id}` | 删除 Secret | 是 |

### 消息接口

| 方法 | 路径 | 功能 | 认证 |
|------|------|------|------|
| POST | `/api/v1/push` | 推送消息（外部调用） | Secret |
| GET | `/api/v1/messages` | 获取消息列表 | 是 |
| GET | `/api/v1/messages/{id}` | 获取消息详情 | 是 |
| PATCH | `/api/v1/messages/{id}/read` | 标记消息已读 | 是 |
| PATCH | `/api/v1/messages/{id}/unread` | 标记消息未读 | 是 |
| DELETE | `/api/v1/messages/{id}` | 删除消息 | 是 |

### 设备管理接口

| 方法 | 路径 | 功能 | 认证 |
|------|------|------|------|
| POST | `/api/v1/devices` | 注册设备 | 是 |
| GET | `/api/v1/devices` | 列出用户设备 | 是 |
| DELETE | `/api/v1/devices/{id}` | 删除设备 | 是 |
| WS | `/api/v1/ws` | WebSocket 实时连接 | Token |

### 健康检查

| 方法 | 路径 | 功能 |
|------|------|------|
| GET | `/health` | 健康检查 |

## 环境变量

```env
# 数据库配置
DATABASE_URL=postgresql://user:password@host:5432/dbname

# JWT 配置
SECRET_KEY=your-secret-key-here-keep-it-safe
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=10080  # 7天

# FCM (Android) 配置（可选）
FCM_SERVER_KEY=your-fcm-server-key

# APNs (iOS) 配置（可选）
APNS_KEY_ID=your-apns-key-id
APNS_TEAM_ID=your-apns-team-id
APNS_BUNDLE_ID=com.yourapp.bundleid
APNS_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----
APNS_PRIVATE_KEY_PATH=/path/to/AuthKey_KEYID.p8
APNS_USE_SANDBOX=true
```

## 推送通知说明

### 设备类型
- `ios` - iOS 设备，使用 APNs 推送
- `android` - Android 设备，使用 FCM 推送
- `web` - Web 浏览器，仅使用 WebSocket

### 推送消息示例

使用 curl 推送消息：

```bash
curl -X POST http://your-server/api/v1/push \
  -H "X-Secret-Key: your-secret-key" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "服务器告警",
    "body": "# CPU 使用率过高\n当前负载: 95%",
    "content_type": "markdown",
    "group": "monitoring",
    "level": "timeSensitive"
  }'
```

### WebSocket 消息格式
```json
{
  "type": "new_message",
  "data": {
    "id": 1,
    "title": "消息标题",
    "body": "消息内容",
    "content_type": "text",
    "group": "test",
    "level": "active",
    "created_at": "2024-01-01T00:00:00Z",
    "read": false
  }
}
```

### 客户端集成流程
1. 用户登录获取 JWT token
2. 调用 `POST /api/v1/devices` 注册设备（需要 APNs/FCM token）
3. 建立 WebSocket 连接：`ws://host/api/v1/ws?token=xxx`
4. 保持连接，新消息会立即推送
5. 如离线，系统通知会通过 APNs/FCM 发送

## 日志说明

系统会自动记录每次请求的关键信息：
- 请求方法（GET/POST/PUT/DELETE等）
- 请求路径
- 状态码
- 请求耗时
- 客户端IP
- 错误信息（当请求失败时）

日志格式示例：
```
INFO     Request | Method: POST | Path: /api/v1/auth/login | Status: 200 | Duration: 45.23ms | Client IP: 127.0.0.1
ERROR    Request failed | Method: POST | Path: /api/v1/auth/register | Duration: 30.12ms | Client IP: 127.0.0.1 | Error: Email already registered
```

## 双因素认证使用说明

1. **启用双因素认证**：
   ```bash
   curl -X POST http://your-server/api/v1/two-factor/enable \
     -H "Authorization: Bearer your-jwt-token"
   ```
   返回包含 TOTP 秘钥和 QR Code URL

2. **扫描二维码**：使用 Authenticator 应用扫描 QR Code

3. **验证启用**：
   ```bash
   curl -X POST http://your-server/api/v1/two-factor/verify \
     -H "Authorization: Bearer your-jwt-token" \
     -H "Content-Type: application/json" \
     -d '{"code": "123456"}'
   ```

4. **登录时使用**：登录接口支持可选的 `two_factor_code` 参数

## API 文档

启动服务后访问：
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## 开发指南

### 添加新的 API 路由

1. 在 `app/routers/` 目录下创建新文件
2. 在 `app/main.py` 中导入并注册路由
3. 在 `app/schemas.py` 中定义请求/响应模型
4. 在 `app/models.py` 中添加数据库模型（如需要）

### 数据库迁移

```bash
# 创建新的迁移文件
alembic revision --autogenerate -m "description of changes"

# 应用迁移
alembic upgrade head

# 回滚迁移
alembic downgrade -1
```

## 部署建议

### 生产环境
- 使用 PostgreSQL 数据库
- 使用 Gunicorn 或 Uvicorn 作为 WSGI 服务器
- 配置 HTTPS（使用 Nginx + Let's Encrypt）
- 设置适当的日志级别和日志轮转
- 配置防火墙规则

### Docker 部署

```bash
# 构建镜像
docker build -t whisperpush-server .

# 运行容器
docker run -d -p 8000:8000 --env-file .env whisperpush-server
```

## 许可证

MIT License
