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

> 💡 更多部署方式（systemd 服务、Docker、手动启动）请参见下方 [部署指南](#部署指南) 章节。

### 快速体验（Docker Compose）

```bash
# 启动服务
docker-compose up -d

# 执行数据库迁移
docker-compose exec api alembic upgrade head
```

### 快速体验（手动启动）

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
├── setup_service.sh        # Linux systemd 服务安装脚本
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
DATABASE_URL=postgresql+asyncpg://user:password@host:5432/dbname

# JWT 配置
SECRET_KEY=your-secret-key-here-keep-it-safe
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=10080  # 7天

# 服务配置（setup_service.sh 也可通过命令行参数指定）
PORT=8000                          # 监听端口
WORKERS=4                          # uvicorn worker 数量

# FCM (Android) 配置（可选）
FCM_SERVER_KEY=your-fcm-server-key

# APNs (iOS) 配置（可选）
APNS_KEY_ID=your-apns-key-id
APNS_TEAM_ID=your-apns-team-id
APNS_BUNDLE_ID=com.yourapp.bundleid
APNS_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----
APNS_PRIVATE_KEY_PATH=/path/to/AuthKey_KEYID.p8
APNS_USE_SANDBOX=true

# 华为推送配置（可选）
HUAWEI_APP_ID=
HUAWEI_APP_SECRET=

# SMTP 邮件配置（可选，用于密码重置等邮件通知）
SMTP_HOST=localhost
SMTP_PORT=587
SMTP_USERNAME=
SMTP_PASSWORD=
SMTP_FROM_ADDRESS=noreply@whisperpush.io
SMTP_USE_TLS=true
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

## 部署指南

### 方式一：systemd 服务安装（推荐，Linux 生产环境）

项目提供了 `setup_service.sh` 脚本，可一键将服务安装为 Linux systemd 服务，实现开机自启、自动重启和日志管理。

#### 前置条件

| 条件 | 说明 |
|------|------|
| 操作系统 | Linux（支持 systemd） |
| 权限 | 需要 root 权限（使用 `sudo`） |
| Python 包管理器 | [uv](https://docs.astral.sh/uv/) — 脚本会自动检测，或通过 `UV_PATH` 指定 |
| 数据库 | PostgreSQL 15+（需提前安装并创建数据库） |

#### 安装 uv（如尚未安装）

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

安装后，uv 通常位于 `~/.local/bin/uv` 或 `~/.cargo/bin/uv`。脚本会自动在这些路径下查找。

#### 准备配置文件

安装前，确保项目目录下有 `.env` 文件：

```bash
cp .env.example .env
vim .env   # 编辑数据库连接、JWT 密钥等配置
```

> ⚠️ **重要**：`SECRET_KEY` 必须修改为随机字符串，`DATABASE_URL` 必须指向可用的 PostgreSQL 数据库。

#### 执行安装

```bash
# 默认安装（监听 0.0.0.0:8000，4 worker）
sudo bash setup_service.sh

# 自定义端口安装
sudo bash setup_service.sh -p 9000

# 自定义端口和 worker 数量
sudo bash setup_service.sh -p 9000 -w 2

# 指定 uv 路径（当自动检测失败时）
sudo bash setup_service.sh --uv-path /path/to/uv

# 查看帮助
bash setup_service.sh --help
```

#### 安装过程说明

脚本执行时会依次完成以下步骤：

| 步骤 | 说明 |
|------|------|
| 1. 权限检查 | 确认以 root 权限运行 |
| 2. 检测 uv | 自动在系统路径和用户 HOME 目录查找 uv |
| 3. 系统级 uv | 若 uv 位于用户 HOME，自动复制到 `/usr/local/bin/uv` 确保服务用户可访问 |
| 4. 创建系统用户 | 创建 `whisperpush` 系统用户（无登录 shell） |
| 5. 部署项目文件 | 将项目文件拷贝至 `/opt/whisperpush-server/`（排除 `.git`、`__pycache__` 等） |
| 6. 安装依赖 | 执行 `uv sync --frozen` 安装 Python 依赖 |
| 7. 数据库迁移 | 执行 `alembic upgrade head`（失败仅警告，不中断安装） |
| 8. 创建启动前脚本 | 生成 `prestart.sh`，在服务启动前检查数据库连接并同步表结构 |
| 9. 创建 systemd 服务 | 生成 `/etc/systemd/system/whisperpush-server.service` |
| 10. 设置文件权限 | 项目文件归 `whisperpush` 用户所有，`.env` 限 owner 可读 |
| 11. 启用并启动服务 | `systemctl enable` + `systemctl restart` |

#### systemd 服务配置详情

脚本生成的 systemd 服务包含以下关键配置：

- **运行用户**：`whisperpush`（最小权限系统用户）
- **多 Worker 模式**：uvicorn 多进程运行，默认 4 worker
- **启动前检查**：`ExecStartPre` 执行数据库连接检查和表同步
- **优雅关闭**：SIGTERM 信号 + 30 秒超时
- **自动重启**：失败后 5 秒自动重启
- **安全加固**：`NoNewPrivileges`、`PrivateTmp`、`ProtectSystem=strict`、`ProtectHome=yes`
- **日志输出**：通过 journald 管理

#### 服务管理

```bash
# 查看服务状态
sudo systemctl status whisperpush-server

# 重启服务
sudo systemctl restart whisperpush-server

# 停止服务
sudo systemctl stop whisperpush-server

# 启动服务
sudo systemctl start whisperpush-server

# 查看实时日志
sudo journalctl -u whisperpush-server -f

# 查看最近 100 行日志
sudo journalctl -u whisperpush-server -n 100

# 查看今天的日志
sudo journalctl -u whisperpush-server --since today
```

#### 健康检查

```bash
curl http://localhost:8000/health
```

#### 更新部署

当项目代码更新后，重新运行安装脚本即可：

```bash
cd /path/to/WhisperPushServer
git pull
sudo bash setup_service.sh
```

脚本会检测到安装目录已存在，提示是否覆盖。确认后将重新部署文件、安装依赖并重启服务。

> 💡 已有的 `.env` 配置文件不会被覆盖，脚本会保留现有配置。

#### 卸载服务

```bash
sudo bash setup_service.sh uninstall
```

卸载过程中，脚本会依次询问：
1. 确认卸载（停止服务、禁用自启、删除 systemd 服务文件）
2. 是否删除安装目录 `/opt/whisperpush-server/`
3. 是否删除系统用户 `whisperpush`

#### 故障排查

| 问题 | 排查命令 | 常见原因 |
|------|---------|---------|
| 服务启动失败 | `sudo journalctl -u whisperpush-server -n 50` | 数据库连接配置错误 |
| 数据库连接失败 | 检查 `.env` 中 `DATABASE_URL` | 数据库未启动或连接串错误 |
| uv 找不到 | `sudo bash setup_service.sh --uv-path /path/to/uv` | uv 未安装或路径异常 |
| 权限错误 | `ls -la /opt/whisperpush-server/` | 文件归属不正确 |
| 端口被占用 | `ss -tlnp \| grep 8000` | 端口冲突，使用 `-p` 指定其他端口 |

### 方式二：Docker Compose

```bash
# 启动服务
docker-compose up -d

# 执行数据库迁移
docker-compose exec api alembic upgrade head
```

### 方式三：手动启动

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

> ⚠️ **注意**：手动启动模式仅适合开发/测试环境，生产环境请使用 systemd 服务或 Docker 部署。

### 生产环境额外建议

- 配置 HTTPS反向代理（Nginx + Let's Encrypt）
- 设置适当的日志级别和日志轮转
- 配置防火墙规则，仅开放必要端口
- 定期备份数据库
- 使用非默认端口（`-p` 参数）

## 许可证

MIT License
