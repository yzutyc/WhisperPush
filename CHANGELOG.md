# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-05-15

### Added

#### 客户端 (WhisperPushApp)
- 用户注册与登录界面
- 双因素认证 (2FA/TOTP) 支持
- 消息列表与详情页面，支持纯文本、Markdown、HTML 三种内容格式
- Markdown 和 HTML 内容中的链接点击跳转功能
- 消息分享功能
- 设备管理页面
- 用户设置管理页面
- 消息推送设置（可保存到后端数据库）
- 服务器地址配置与切换
- 全局毛玻璃风格 UI 设计
- 多平台支持：Android、iOS、Windows、Linux、macOS、Web
- QR 码生成（用于 2FA 绑定）

#### 服务端 (WhisperPushServer)
- FastAPI + SQLAlchemy + PostgreSQL 后端架构
- JWT 令牌认证
- bcrypt 密码哈希
- TOTP 双因素认证
- 端到端加密消息推送
- WebSocket 实时通信
- 设备管理 API
- 用户设置 API
- 密码重置功能
- 健康检查端点 (`/health`)
- 请求日志中间件
- 数据库自动迁移（Alembic）
- Docker 与 docker-compose 部署支持
- 推送消息完整测试套件（含 URL 格式测试）

#### CI/CD
- GitHub Actions 多平台自动构建（Android、iOS、Windows、Linux、macOS、Web）
- Tag 触发自动发布 Release

### Changed
- 健康检查端点路径从 `/api/health` 调整为 `/health`
- 推送消息时级别为空默认为"普通"
- UI 全局圆角优化、登录界面改进、弹窗设计优化
