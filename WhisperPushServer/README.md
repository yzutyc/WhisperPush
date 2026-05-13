# WhisperPush Server

消息推送系统后端服务，基于 FastAPI + SQLAlchemy + PostgreSQL 构建。

## 功能特性

- **用户认证**：注册、登录、JWT Token 认证
- **Secret 管理**：创建、查询、删除秘钥
- **消息推送**：支持 text/markdown/html 三种内容格式
- **消息管理**：消息列表、详情、标记已读
- **实时推送**：WebSocket 实时消息推送
- **系统通知**：支持 APNs (iOS) 和 FCM (Android) 系统级推送通知
- **设备管理**：设备注册、列表、删除
- **健康检查**：内置 `/health` 接口

## 技术栈

- Python 3.10+
- FastAPI 0.109+
- SQLAlchemy 2.0+
- PostgreSQL 15+
- JWT 认证

## 快速开始

### 使用 Docker Compose（推荐）

```bash
# 启动服务
docker-compose up -d

# 执行数据库迁移
docker-compose exec api alembic upgrade head
```

### 手动启动

```bash
# 安装依赖
pip install -r requirements.txt

# 设置环境变量（可选）
cp .env.example .env
# 编辑 .env 文件配置数据库连接

# 执行数据库迁移
alembic upgrade head

# 启动服务
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
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
│   ├── security.py         # 安全工具
│   ├── dependencies.py     # 依赖注入
│   ├── websocket.py        # WebSocket 管理器
│   ├── push_service.py     # APNs/FCM 推送服务
│   └── routers/            # API 路由
│       ├── auth.py         # 认证接口
│       ├── secrets.py      # Secret 管理
│       ├── messages.py     # 消息接口
│       └── devices.py      # 设备管理接口
├── alembic/                # 数据库迁移
├── requirements.txt        # 依赖列表
├── .env                    # 环境变量
├── docker-compose.yml      # Docker 配置
└── Dockerfile              # Docker 镜像
```

## API 接口

### 认证接口

| 方法 | 路径 | 功能 |
|------|------|------|
| POST | `/api/v1/auth/register` | 用户注册 |
| POST | `/api/v1/auth/login` | 用户登录 |
| GET | `/api/v1/auth/me` | 获取当前用户 |

### Secret 管理接口

| 方法 | 路径 | 功能 |
|------|------|------|
| POST | `/api/v1/secrets` | 创建 Secret |
| GET | `/api/v1/secrets` | 列出所有 Secret |
| DELETE | `/api/v1/secrets/{id}` | 删除 Secret |

### 消息接口

| 方法 | 路径 | 功能 |
|------|------|------|
| POST | `/api/v1/push` | 推送消息（外部调用） |
| GET | `/api/v1/messages` | 获取消息列表 |
| GET | `/api/v1/messages/{id}` | 获取消息详情 |
| PATCH | `/api/v1/messages/{id}/read` | 标记消息已读 |

### 设备管理接口

| 方法 | 路径 | 功能 |
|------|------|------|
| POST | `/api/v1/devices` | 注册设备 |
| GET | `/api/v1/devices` | 列出用户设备 |
| DELETE | `/api/v1/devices/{id}` | 删除设备 |
| WS | `/api/v1/ws` | WebSocket 实时连接 |

## 环境变量

```env
DATABASE_URL=postgresql+asyncpg://user:password@host/dbname
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=10080

# FCM (Android) 配置
FCM_SERVER_KEY=your-fcm-server-key

# APNs (iOS) 配置
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

### 客户端集成
1. 用户登录获取 token
2. 调用 `POST /api/v1/devices` 注册设备（需要 APNs/FCM token）
3. 建立 WebSocket 连接：`ws://host/api/v1/ws?token=xxx`
4. 保持连接，新消息会立即推送
5. 如离线，系统通知会通过 APNs/FCM 发送

## 文档

启动服务后访问：
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc