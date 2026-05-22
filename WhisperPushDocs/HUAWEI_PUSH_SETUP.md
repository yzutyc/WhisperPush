# 华为推送集成指南

## 概述

本指南将帮助您完成 WhisperPush 应用集成华为推送服务。

## 前置条件

- 华为开发者账号
- 华为 AppGallery Connect（AGC）账号
- 已集成 HMS Core 的 Huawei 或 Honor 设备（测试用

## 第一步：创建华为应用

1. 访问 [华为 AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)
2. 登录您的项目
3. 创建一个项目和应用

### 配置包名

确保 Android 项目的包名与 AGC 中的一致（在 `android/app/build.gradle.kts` 中 `namespace:
   ```kotlin
   android {
       namespace = "whisperpush.yangtze.asia"
       // 你的包名
       ...
   }
   ```

## 第二步：开启推送服务

在 AGC 中开启 Push Kit：

1. 在 AGC 项目页面，选择"项目设置 > API 管理
2. 找到 Push Kit > 开启服务
3. 添加 SHA-256 指纹（用于签名：

## 。

## 第三步：配置文件

1. 从 AGC 下载 `agconnect-services.json` 项目文件
2. 将文件放入 Android 项目的 `android/app/` 目录中
3. 或，文件内容包含：
   - app_id
   - client_id
   - 等关键信息

### 注意事项：
我们的备用方案

如在 `android/app/src/main/res/xml/agconnect_services.xml` 文件，手动配置相应的值替换您从华为获取的。

## 第四步：服务端配置

在服务端在 `.env` 文件中添加以下配置：

```env
# Huawei Push
HUAWEI_APP_ID=your_huawei_app_id
HUAWEI_APP_SECRET=your_huawei_app_secret
```

获取方式：
- 在 AGC 应用设置 → 应用信息 中获取。

## 第五步：测试

1. 华为或荣耀设备：
- 安装应用
- 打开设备管理页面，注册设备
- 在后台服务发送测试推送

## 功能说明

1. **自动检测和检测设备厂商：
   - 华为和荣耀设备，优先使用华为推送
   - 其他设备按需或使用备用推送服务

2. **Token 获取：
   - 失败时使用备用方案

3. **监听：
   - 收到通知应用通知

## 问题排查

### HMS Core 不可用？

1. 确保设备上安装了最新版的 HMS Core 应用。

### 获取 Token 失败？

1. 检查 agconnect-services.json 配置
2. 检查 SHA-256 指纹
3. 查看设备是否有网络连接

## 架构特点

### 扩展性强

-，可以轻松扩展到其他的：小米、OPPO、VIVO 等只需要：

1. 添加对应厂商 SDK
2. 实现对应适配器（Adapter）
3. 服务端添加适配的
4. 前端添加工厂厂商厂商
5. 在 `push_vendor` 支持。

## 相关资源

- [华为 Push Kit 官方文档](https://developer.huawei.com/consumer/cn/doc/development/HMSCore-Guides/introduction-0000001050040063)
- [Flutter Huawei Push Package](https://pub.dev/packages/huawei_push)
