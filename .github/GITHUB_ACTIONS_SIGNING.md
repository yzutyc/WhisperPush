# GitHub Actions 签名配置说明

## 概述

本指南说明如何为 GitHub Actions 配置 Android 应用签名，以便在自动构建时使用正式签名。

## 需要配置的 Secrets

在 GitHub 仓库的 Settings > Secrets and variables > Actions 页面，添加以下 Secrets：

### 1. ANDROID_KEYSTORE_BASE64
签名密钥库文件的 Base64 编码内容

### 2. RELEASE_STORE_PASSWORD
密钥库密码

### 3. RELEASE_KEY_ALIAS
密钥别名

### 4. RELEASE_KEY_PASSWORD
密钥密码

## 配置步骤

### 第一步：生成签名密钥库（如果还没有）

如果您还没有签名密钥库，先按照 [SIGNING_SETUP.md](../WhisperPushApp/android/SIGNING_SETUP.md) 中的说明生成一个。

### 第二步：将密钥库转换为 Base64

在本地运行以下命令将 keystore 文件转换为 Base64：

#### Windows (PowerShell):
```powershell
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes("whisperpush-release-key.jks")) | Out-File -Encoding ASCII keystore-base64.txt
```

#### Linux/Mac:
```bash
base64 -w 0 whisperpush-release-key.jks > keystore-base64.txt
```

### 第三步：在 GitHub 中配置 Secrets

1. 进入您的 GitHub 仓库
2. 点击 **Settings**
3. 在左侧菜单中找到 **Secrets and variables** > **Actions**
4. 点击 **New repository secret**
5. 添加以下 Secrets：

| Secret 名称 | 说明 |
|------------|------|
| `ANDROID_KEYSTORE_BASE64` | 从 `keystore-base64.txt` 复制全部内容 |
| `RELEASE_STORE_PASSWORD` | 您的密钥库密码 |
| `RELEASE_KEY_ALIAS` | 您的密钥别名（如 `whisperpush`） |
| `RELEASE_KEY_PASSWORD` | 您的密钥密码 |

### 第四步：触发构建

配置完成后，推送一个新的 tag（如 `v0.1.12`），GitHub Actions 将会自动使用您配置的正式签名构建应用。

## 安全注意事项

- **永远不要将密钥库文件或密码提交到代码仓库！**
- 确保 Secrets 的访问权限设置正确
- 定期轮换签名密钥（如果可能）
- 备份好密钥库文件和密码
