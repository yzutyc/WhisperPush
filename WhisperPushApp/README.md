# WhisperPush App

消息推送系统移动端应用，基于 Flutter 构建，支持 iOS、Android 和桌面平台。

## 功能特性

### 核心功能
- **用户认证**：登录、注册、自动登录、退出登录
- **消息管理**：消息列表、详情查看、标记已读/未读、删除消息
- **内容渲染**：支持 text、markdown、html 三种格式
- **服务器配置**：自定义服务器地址，支持历史地址缓存和自动检测
- **Secret 管理**：创建、查看、删除推送秘钥
- **双因素认证**：支持 TOTP 双因素认证设置
- **Toast 提示**：美观的消息提示组件

### 安全特性
- JWT Token 认证
- 密码加密存储
- 服务器地址验证
- 自动登录状态管理

### 用户体验
- 流畅的页面导航
- 下拉刷新消息列表
- Toast 消息提示
- 响应式设计

## 技术栈

- Flutter 3.0+
- Dart 3.0+
- Provider 状态管理
- HTTP 网络请求
- SharedPreferences 本地存储
- Flutter Markdown 渲染
- Flutter HTML 渲染

## 快速开始

### 环境要求

- Flutter 3.0+
- Dart 3.0+
- Android Studio / Xcode（移动端开发）
- Visual Studio（Windows 桌面开发）

### 安装依赖

```bash
# 获取依赖
flutter pub get

# 运行构建（默认设备）
flutter run

# 指定平台运行
flutter run -d windows
flutter run -d android
flutter run -d ios
```

### 构建 APK（Android）

```bash
# 构建发布版本
flutter build apk --release

# 构建 App Bundle（推荐）
flutter build appbundle
```

### 构建 IPA（iOS）

```bash
# 构建发布版本
flutter build ios --release

# 在 Xcode 中签名并导出
open ios/Runner.xcworkspace
```

### 构建 Windows 桌面应用

```bash
# 构建发布版本
flutter build windows

# 运行桌面应用
flutter run -d windows
```

## 项目结构

```
.
├── lib/                    # Dart 代码
│   ├── main.dart           # 应用入口
│   ├── providers/          # 状态管理
│   │   └── auth_provider.dart    # 认证状态管理
│   ├── api/                # API 服务
│   │   └── api_service.dart       # HTTP API 调用
│   ├── models/             # 数据模型
│   │   ├── user.dart              # 用户模型
│   │   ├── message.dart           # 消息模型
│   │   └── secret.dart            # 秘钥模型
│   ├── components/         # 可复用组件
│   │   ├── custom_button.dart     # 自定义按钮
│   │   ├── form_input.dart        # 表单输入框
│   │   ├── loading_indicator.dart # 加载指示器
│   │   ├── logo_widget.dart       # Logo 组件
│   │   ├── message_card.dart      # 消息卡片
│   │   └── toast_widget.dart      # Toast 提示组件
│   ├── pages/              # 页面组件
│   │   ├── splash_screen.dart          # 启动页
│   │   ├── login_page.dart             # 登录页
│   │   ├── register_page.dart          # 注册页
│   │   ├── message_list_page.dart      # 消息列表页
│   │   ├── message_detail_page.dart    # 消息详情页
│   │   ├── settings_page.dart          # 设置页
│   │   ├── change_password_page.dart   # 修改密码页
│   │   ├── forgot_password_page.dart   # 忘记密码页
│   │   ├── two_factor_page.dart        # 双因素认证页
│   │   ├── privacy_policy_page.dart    # 隐私政策页
│   │   └── terms_of_service_page.dart  # 服务条款页
│   ├── theme/              # 主题配置
│   │   └── app_theme.dart           # 应用主题
│   └── utils/              # 工具函数
│       └── server_cache.dart        # 服务器地址缓存
├── android/                # Android 配置
├── ios/                    # iOS 配置
├── windows/                # Windows 桌面配置
├── pubspec.yaml            # 项目配置
└── README.md               # 项目说明
```

## 页面说明

| 页面 | 功能 |
|------|------|
| SplashScreen | 启动页，检查登录状态，自动跳转 |
| LoginPage | 用户登录，支持邮箱/用户名登录 |
| RegisterPage | 用户注册，表单验证 |
| MessageListPage | 消息列表，支持下拉刷新、标记已读 |
| MessageDetailPage | 消息详情，根据内容类型渲染（text/markdown/html） |
| SettingsPage | 设置页：服务器配置、Secret 管理、退出登录 |
| ChangePasswordPage | 修改密码 |
| ForgotPasswordPage | 忘记密码，发送重置链接 |
| TwoFactorPage | 双因素认证设置 |
| PrivacyPolicyPage | 隐私政策展示 |
| TermsOfServicePage | 服务条款展示 |

## 使用说明

### 首次使用流程
1. **打开应用**：进入启动页，自动检查登录状态
2. **注册/登录**：如未登录，跳转到登录页
3. **配置服务器**：进入设置页 → 输入服务器地址 → 点击检测 → 保存
4. **创建 Secret**：进入设置页 → 点击"新建秘钥" → 复制秘钥
5. **推送消息**：使用 HTTP API 携带 Secret 推送消息
6. **查看消息**：消息列表页查看所有消息

### 服务器地址管理
- 支持手动输入服务器地址
- 自动缓存历史地址，支持下拉选择
- 地址录入后自动检测服务是否可用

### 消息操作
- 点击消息卡片查看详情
- 滑动消息卡片快速标记已读/未读
- 长按消息卡片删除消息

## API 调用示例

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

## 依赖包

| 包名 | 用途 | 版本 |
|------|------|------|
| http | HTTP 请求 | ^1.0.0 |
| shared_preferences | 本地存储 | ^2.2.0 |
| provider | 状态管理 | ^6.0.0 |
| flutter_markdown | Markdown 渲染 | ^0.6.0 |
| flutter_html | HTML 渲染 | ^3.0.0 |
| intl | 国际化日期格式化 | ^0.18.0 |
| url_launcher | URL 跳转 | ^6.1.0 |

## 开发指南

### 添加新页面

1. 在 `lib/pages/` 目录下创建新页面文件
2. 在 `lib/main.dart` 中注册路由
3. 在 `lib/providers/` 中添加状态管理（如需要）
4. 在 `lib/api/` 中添加 API 调用（如需要）

### 添加新组件

1. 在 `lib/components/` 目录下创建新组件文件
2. 在需要使用的页面中导入并使用

### 添加新模型

1. 在 `lib/models/` 目录下创建新模型文件
2. 定义数据类和序列化方法

## 配置说明

### pubspec.yaml 关键配置

```yaml
name: whisperpush_app
description: WhisperPush message push client application
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  http: ^1.0.0
  shared_preferences: ^2.2.0
  provider: ^6.0.0
  flutter_markdown: ^0.6.0
  flutter_html: ^3.0.0
  intl: ^0.18.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
```

## 许可证

MIT License
