import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('隐私政策'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '隐私政策',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24),
                Text(
                  '生效日期：2026年5月15日',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 32),
                Text(
                  '1. 引言',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'WhisperPush 重视您的隐私。本隐私政策说明了我们如何收集、使用、存储和保护您的个人信息。',
                  style: TextStyle(height: 1.6),
                ),
                SizedBox(height: 24),
                Text(
                  '2. 收集的信息',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  '2.1 账户信息：当您注册账户时，我们收集您的用户名、邮箱地址和密码（加密存储）。\n\n'
                  '2.2 设备信息：我们可能收集您的设备类型、操作系统版本、IP地址等信息。\n\n'
                  '2.3 使用信息：我们记录您如何使用本服务，包括消息阅读记录、设置更改等。\n\n'
                  '2.4 推送令牌：为了发送推送通知，我们收集您的设备推送令牌。',
                  style: TextStyle(height: 1.6),
                ),
                SizedBox(height: 24),
                Text(
                  '3. 使用信息的方式',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  '3.1 提供和维护服务：使用您的信息提供推送通知服务。\n\n'
                  '3.2 改进服务：分析使用数据以改进我们的服务。\n\n'
                  '3.3 安全：保护您的账户和服务安全。\n\n'
                  '3.4 通信：向您发送重要通知和更新。',
                  style: TextStyle(height: 1.6),
                ),
                SizedBox(height: 24),
                Text(
                  '4. 信息共享',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  '4.1 我们不会向第三方出售您的个人信息。\n\n'
                  '4.2 我们可能与第三方服务提供商共享信息，以帮助我们提供服务（如云存储、推送服务）。\n\n'
                  '4.3 我们可能根据法律要求或为了保护我们的权利而披露信息。',
                  style: TextStyle(height: 1.6),
                ),
                SizedBox(height: 24),
                Text(
                  '5. 信息安全',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  '5.1 我们使用加密技术保护您的数据传输和存储。\n\n'
                  '5.2 我们定期审查安全措施，保护您的信息免受未经授权的访问。\n\n'
                  '5.3 尽管我们采取了安全措施，但没有任何安全系统是完美的。',
                  style: TextStyle(height: 1.6),
                ),
                SizedBox(height: 24),
                Text(
                  '6. 您的权利',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  '6.1 访问权：您可以访问您的个人信息。\n\n'
                  '6.2 修改权：您可以修改您的账户信息。\n\n'
                  '6.3 删除权：您可以请求删除您的账户和数据。\n\n'
                  '6.4 退出权：您可以随时停止使用我们的服务。',
                  style: TextStyle(height: 1.6),
                ),
                SizedBox(height: 24),
                Text(
                  '7. 政策修改',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  '我们保留随时修改本政策的权利。修改后的政策将在发布后立即生效。',
                  style: TextStyle(height: 1.6),
                ),
                SizedBox(height: 24),
                Text(
                  '8. 联系我们',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  '如果您对本隐私政策有任何疑问，请联系我们：privacy@whisperpush.com',
                  style: TextStyle(height: 1.6),
                ),
                SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}