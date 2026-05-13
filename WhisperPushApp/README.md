# WhisperPush App

消息推送系统移动端应用，基于 Flutter 构建，支持 iOS 和 Android。

## 功能特性

- **用户认证**：登录、注册、自动登录
- **消息管理**：消息列表、详情查看、标记已读
- **内容渲染**：支持 text、markdown、html 三种格式
- **服务器配置**：自定义服务器地址
- **Secret 管理**：创建、删除秘钥

## 技术栈

- Flutter 3.0+
- Dart 3.0+
- Provider 状态管理
- HTTP 网络请求
- SharedPreferences 本地存储

## 快速开始

### 环境要求

- Flutter 3.0+
- Dart 3.0+
- Android Studio / Xcode

### 安装依赖

```bash
# 获取依赖
flutter pub get

# 运行构建
flutter run
```

### 构建 APK（Android）

```bash
flutter build apk --release
```

### 构建 IPA（iOS）

```bash
flutter build ios --release
```

## 项目结构

```
.
├── lib/                    # Dart 代码
│   ├── main.dart           # 应用入口
│   ├── providers/          # 状态管理
│   │   └── auth_provider.dart
│   ├── api/                # API 服务
│   │   └── api_service.dart
│   ├── models/             # 数据模型
│   │   ├── user.dart
│   │   ├── message.dart
│   │   └── secret.dart
│   └── pages/              # 页面组件
│       ├── splash_screen.dart      # 启动页
│       ├── login_page.dart         # 登录页
│       ├── register_page.dart      # 注册页
│       ├── message_list_page.dart  # 消息列表页
│       ├── message_detail_page.dart# 消息详情页
│       └── settings_page.dart      # 设置页
├── android/                # Android 配置
├── ios/                    # iOS 配置
├── pubspec.yaml            # 项目配置
└── README.md               # 项目说明
```

## 页面说明

| 页面 | 功能 |
|------|------|
| SplashScreen | 启动页，检查登录状态 |
| LoginPage | 用户登录 |
| RegisterPage | 用户注册 |
| MessageListPage | 消息列表，支持下拉刷新 |
| MessageDetailPage | 消息详情，根据内容类型渲染 |
| SettingsPage | 服务器配置、Secret管理、退出登录 |

## 使用说明

1. **首次使用**：打开应用 → 注册/登录账户
2. **配置服务器**：进入设置页 → 输入服务器地址 → 保存
3. **创建 Secret**：进入设置页 → 点击"新建" → 获取秘钥
4. **推送消息**：使用 HTTP API 携带 Secret 推送消息
5. **查看消息**：消息列表页查看所有消息

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

| 包名 | 用途 |
|------|------|
| http | HTTP 请求 |
| shared_preferences | 本地存储 |
| provider | 状态管理 |
| flutter_markdown | Markdown 渲染 |
| flutter_html | HTML 渲染 |
| intl | 国际化日期格式化 |