# WhisperPush

一个安全、高效的消息推送系统，提供端到端加密的即时消息服务。

## 项目结构

```
WhisperPush/
├── WhisperPushApp/          # Flutter 客户端应用
│   ├── lib/                 # 应用源码
│   ├── test/                # 测试代码
│   └── windows/             # 桌面平台支持
├── WhisperPushServer/       # FastAPI 后端服务
│   ├── app/                 # 应用源码
│   ├── alembic/             # 数据库迁移
│   └── test/                # 测试代码
└── WhisperPushDocs/         # 项目文档
```

## 技术栈

### 前端 (WhisperPushApp)
- **框架**: Flutter 3.0+
- **状态管理**: Provider
- **HTTP 客户端**: http
- **存储**: shared_preferences
- **UI 特效**: particles_flutter

### 后端 (WhisperPushServer)
- **框架**: FastAPI 0.109+
- **数据库**: PostgreSQL + SQLAlchemy 2.0
- **认证**: JWT + 双因素认证 (TOTP)
- **密码哈希**: bcrypt
- **异步通信**: WebSocket

## 快速开始

### 后端服务

```bash
cd WhisperPushServer

# 安装依赖
pip install uv
uv sync

# 配置环境变量
cp .env.example .env
# 编辑 .env 文件，配置数据库连接等

# 数据库迁移
uv run alembic upgrade head

# 启动服务
uv run python start.py
```

### 前端应用

```bash
cd WhisperPushApp

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

## 功能特性

- ✅ 用户注册与登录
- ✅ 双因素认证 (2FA)
- ✅ 端到端加密消息
- ✅ 实时消息推送
- ✅ 设备管理
- ✅ 密码重置
- ✅ 用户设置管理

## API 接口

后端服务提供 RESTful API 和 WebSocket 接口：

- **认证接口**: `/api/auth/`
- **消息接口**: `/api/messages/`
- **设备接口**: `/api/devices/`
- **WebSocket**: `/ws/`

## 安全特性

- JWT 令牌认证
- bcrypt 密码哈希
- TOTP 双因素认证
- 输入验证与清理
- 安全的密码策略

## 测试

### 后端测试

```bash
cd WhisperPushServer
uv run pytest
```

### 前端测试

```bash
cd WhisperPushApp
flutter test
```

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！