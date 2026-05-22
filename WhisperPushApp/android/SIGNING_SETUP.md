# Android 签名配置说明

## 配置正式签名的步骤

### 1. 生成签名密钥库 (Keystore)

在项目根目录下运行以下命令生成签名密钥库：

```bash
keytool -genkey -v -keystore whisperpush-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias whisperpush
```

按照提示输入相关信息：
- 密钥库密码 (store password)
- 密钥别名 (key alias)
- 密钥密码 (key password)
- 组织信息等

**注意**：请妥善保管生成的 `whisperpush-release-key.jks 文件和密码！

### 2. 配置签名信息

有两种方式配置签名信息：

#### 方式一：在 local.properties 中配置（推荐）

在 `android/目录下创建或编辑 `local.properties` 文件，添加以下内容：

```properties
RELEASE_STORE_FILE=whisperpush-release-key.jks
RELEASE_STORE_PASSWORD=your_store_password
RELEASE_KEY_ALIAS=whisperpush
RELEASE_KEY_PASSWORD=your_key_password
```

#### 方式二：在 gradle.properties 中配置

取消 `android/gradle.properties` 中相关行的注释，并填入实际值。

### 3. 放置密钥库位置

将生成的 `whisperpush-release-key.jks` 文件放置在 `android/app/` 目录下。

### 4. 构建发布版本

配置完成后，运行以下命令构建发布版本：

```bash
cd WhisperPushApp
flutter build apk --release
flutter build appbundle --release
```

## 安全提示

- **永远不要将密钥库文件和密码提交到版本控制系统！**
- 备份好密钥库文件，一旦丢失将无法更新应用
- 建议使用密码管理工具妥善保存密码信息
