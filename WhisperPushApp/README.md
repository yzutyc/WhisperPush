# WhisperPush

一个安全、跨平台的推送通知应用，让您随时随地接收和管理重要消息。

## 📱 项目简介

WhisperPush 是一款基于 Flutter 开发的多平台推送通知客户端，配合 WhisperPushServer 后端服务使用。它提供了安全的消息推送、实时通知接收和消息管理功能，支持 iOS、Android、Windows、macOS、Linux 和 Web 等多个平台。

## ✨ 核心功能

- 🔐 **安全认证**：支持用户注册、登录、密码重置及双重验证
- 💬 **消息管理**：查看消息列表、消息详情，支持搜索和筛选
- 📋 **批量操作**：多选消息进行批量标记已读或删除
- 🔍 **智能筛选**：按状态（已读/未读）、级别（紧急/加急/普通）、分组筛选消息
- 🔄 **自定义服务器**：支持连接自定义 WhisperPushServer 实例
- 📱 **多平台支持**：一套代码，多端运行
- 🎨 **精美 UI**：深色主题、玻璃态设计、霓虹效果
- 💾 **本地缓存**：服务器地址历史记录自动保存

## 🛠️ 技术栈

### 核心框架
- **Flutter SDK**: ^3.11.5
- **Dart**: 最新稳定版

### 主要依赖
- **provider**: ^6.1.2 - 状态管理
- **shared_preferences**: ^2.3.2 - 本地数据持久化
- **http**: ^1.2.2 - 网络请求
- **flutter_html**: ^3.0.0-beta.2 - HTML 内容渲染
- **flutter_markdown**: ^0.7.3 - Markdown 内容渲染
- **intl**: ^0.19.0 - 国际化和日期格式化
- **share_plus**: ^9.0.0 - 分享功能
- **package_info_plus**: ^8.0.0 - 应用信息获取
- **cupertino_icons**: ^1.0.8 - iOS 风格图标

## 📁 项目结构

```
WhisperPushApp/
├── lib/
│   ├── api/                    # API 服务层
│   │   └── api_service.dart    # 后端 API 接口封装
│   ├── components/             # 通用组件
│   │   ├── custom_button.dart
│   │   ├── empty_state.dart
│   │   ├── form_input.dart
│   │   ├── glass_card.dart
│   │   ├── glass_container.dart
│   │   ├── loading_indicator.dart
│   │   ├── logo_widget.dart
│   │   ├── message_card.dart
│   │   ├── neon_button.dart
│   │   ├── neon_switch.dart
│   │   ├── particle_background.dart
│   │   ├── search_input.dart
│   │   └── toast_widget.dart
│   ├── models/                 # 数据模型
│   │   ├── message.dart
│   │   ├── secret.dart
│   │   └── user.dart
│   ├── pages/                  # 页面
│   │   ├── change_password_page.dart
│   │   ├── forgot_password_page.dart
│   │   ├── login_page.dart
│   │   ├── message_detail_page.dart
│   │   ├── message_list_page.dart
│   │   ├── privacy_policy_page.dart
│   │   ├── register_page.dart
│   │   ├── settings_page.dart
│   │   ├── splash_screen.dart
│   │   ├── terms_of_service_page.dart
│   │   └── two_factor_page.dart
│   ├── providers/              # 状态管理
│   │   └── auth_provider.dart
│   ├── theme/                  # 主题配置
│   │   └── app_theme.dart
│   ├── utils/                  # 工具类
│   │   ├── logger.dart
│   │   └── server_cache.dart
│   └── main.dart               # 应用入口
├── linux/                      # Linux 平台配置
├── macos/                      # macOS 平台配置
├── windows/                    # Windows 平台配置
├── pubspec.yaml                # 依赖配置
└── README.md
```

## 🚀 快速开始

### 前置要求

确保您已安装以下工具：
- Flutter SDK (>=3.11.5)
- Dart SDK
- IDE (推荐 Android Studio 或 VS Code)
- 一个运行中的 WhisperPushServer 后端服务

### 安装步骤

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd WhisperPushApp
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **配置后端服务**
   
   确保您的 WhisperPushServer 已启动并可访问。默认地址为 `http://localhost:8000`，您也可以在应用中自定义服务器地址。

4. **运行应用**

## 📦 构建和运行

### Android
```bash
flutter run -d android
```

### iOS (仅 macOS)
```bash
flutter run -d ios
```

### Windows
```bash
flutter run -d windows
```

### macOS
```bash
flutter run -d macos
```

### Linux
```bash
flutter run -d linux
```

### Web (Chrome)
```bash
flutter run -d chrome
```

### 构建发布版本

#### Android APK
```bash
flutter build apk --release
```

#### iOS App
```bash
flutter build ios --release
```

#### Windows
```bash
flutter build windows --release
```

#### macOS
```bash
flutter build macos --release
```

#### Linux
```bash
flutter build linux --release
```

#### Web
```bash
flutter build web --release
```

## 🖥️ 后端服务

WhisperPushApp 需要配合 WhisperPushServer 后端服务使用。请确保：

1. 后端服务已正确部署并运行
2. 网络连接正常，应用可以访问后端 API
3. 在应用中配置正确的服务器地址

更多后端信息请参考 [WhisperPushServer 文档]()。

## 📄 许可证

本项目采用 MIT 许可证 - 详见 LICENSE 文件。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📧 联系方式

如有问题或建议，请通过以下方式联系：
- 提交 GitHub Issue
- 发送邮件至 [your-email@example.com]

---

**享受 WhisperPush 带来的便捷推送体验！** 🎉
