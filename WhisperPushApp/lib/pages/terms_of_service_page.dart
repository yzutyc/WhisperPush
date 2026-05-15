import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('服务条款'),
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
                  '服务条款',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24),
                Text(
                  '生效日期：2026年5月15日',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 32),
                Text(
                  '1. 服务概述',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'WhisperPush 是一款安全的推送通知服务，允许用户接收和管理推送消息。通过使用本服务，您同意遵守以下条款和条件。',
                  style: TextStyle(height: 1.6),
                ),
                SizedBox(height: 24),
                Text(
                  '2. 用户义务',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  '2.1 您必须提供准确、完整的注册信息，并及时更新您的账户信息。\n\n'
                  '2.2 您对您账户下的所有活动和操作负责。\n\n'
                  '2.3 您不得使用本服务发送垃圾邮件、骚扰信息或任何违法内容。\n\n'
                  '2.4 您必须保护您的账户密码安全，不得与他人共享。',
                  style: TextStyle(height: 1.6),
                ),
                SizedBox(height: 24),
                Text(
                  '3. 服务使用',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  '3.1 WhisperPush 保留随时修改或终止服务的权利，无需提前通知。\n\n'
                  '3.2 您同意不尝试破解、逆向工程或修改本服务的任何部分。\n\n'
                  '3.3 您同意不使用自动化工具或机器人访问本服务。',
                  style: TextStyle(height: 1.6),
                ),
                SizedBox(height: 24),
                Text(
                  '4. 隐私政策',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  '我们重视您的隐私。请参阅我们的隐私政策了解我们如何收集、使用和保护您的信息。',
                  style: TextStyle(height: 1.6),
                ),
                SizedBox(height: 24),
                Text(
                  '5. 免责声明',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  '5.1 本服务按"现状"提供，不提供任何明示或暗示的保证。\n\n'
                  '5.2 WhisperPush 不对因使用本服务造成的任何损失负责。\n\n'
                  '5.3 WhisperPush 不保证服务的连续性或可用性。',
                  style: TextStyle(height: 1.6),
                ),
                SizedBox(height: 24),
                Text(
                  '6. 条款修改',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  '我们保留随时修改这些条款的权利。修改后的条款将在发布后立即生效。您继续使用本服务即表示您同意修改后的条款。',
                  style: TextStyle(height: 1.6),
                ),
                SizedBox(height: 24),
                Text(
                  '7. 联系我们',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  '如果您对这些条款有任何疑问，请联系我们：support@whisperpush.com',
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