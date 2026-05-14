# WhisperPush Windows Desktop

WhisperPush 消息推送客户端的 Windows 桌面版本。

## 快速开始

### 运行开发版本

```bash
# 运行 Windows 桌面应用
flutter run -d windows
```

### 构建发布版本

```bash
# 构建发布版本
flutter build windows

# 构建产物位于 build/windows/runner/Release 目录
```

## 项目结构

```
windows/
├── runner/                  # Windows 应用程序代码
│   ├── main.cpp             # 应用入口
│   ├── flutter_window.cpp   # Flutter 窗口管理
│   ├── win32_window.cpp     # Win32 窗口封装
│   └── resources/           # 资源文件
│       └── app_icon.ico     # 应用图标
├── flutter/                 # Flutter 集成代码
└── CMakeLists.txt           # CMake 配置
```

## 注意事项

- 需要安装 Visual Studio 和 Windows SDK
- 构建需要管理员权限（某些情况下）
- 发布版本需要代码签名证书（可选但推荐）
