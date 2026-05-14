import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../api/api_service.dart';
import '../providers/auth_provider.dart';
import '../models/secret.dart';
import '../models/user.dart';
import 'login_page.dart';
import 'change_password_page.dart';
import 'terms_of_service_page.dart';
import 'privacy_policy_page.dart';
import 'two_factor_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<Secret> _secrets = [];
  bool _isLoading = false;
  User? _currentUser;
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadSecrets();
    _loadAppVersion();
  }

  Future<void> _loadUserInfo() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );
      _currentUser = await api.getCurrentUser();
    } catch (e) {
      print('加载用户信息失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSecrets() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );
      _secrets = await api.getSecrets();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  Future<void> _createSecret() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );
      final secret = await api.createSecret();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => SecretDetailDialog(secret: secret),
        );
      }
      await _loadSecrets();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建失败: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSecret(int id) async {
    if (!await _confirmDelete()) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );
      await api.deleteSecret(id);
      await _loadSecrets();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _confirmDelete() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个 Secret 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _logout() async {
    if (!await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('退出'),
          ),
        ],
      ),
    )) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );
      await api.logout();
      
      await authProvider.logout();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      print('退出登录失败: $e');
      await Provider.of<AuthProvider>(context, listen: false).logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSettingCard({
    required String title,
    required Widget child,
    Widget? leading,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (leading != null) leading,
                if (leading != null) const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSettingCard(
                  title: '账户信息',
                  leading: const Icon(Icons.account_circle, size: 24),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          child: _currentUser != null
                              ? Text(_currentUser!.username[0].toUpperCase())
                              : const Icon(Icons.person),
                          backgroundColor: Colors.indigo[100],
                          foregroundColor: Colors.indigo,
                        ),
                        title: Text(_currentUser?.username ?? '用户名'),
                        subtitle: Text(_currentUser?.email ?? 'user@example.com'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock, size: 20),
                        title: const Text('修改密码'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.shield, size: 20),
                        title: const Text('双因素认证'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TwoFactorPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                _buildSettingCard(
                  title: 'Secret 管理',
                  leading: const Icon(Icons.key, size: 24),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _createSecret,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('新建 Secret'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _secrets.isEmpty
                          ? const Center(
                              child: Text('暂无 Secret'),
                            )
                          : Column(
                              children: _secrets.map((secret) {
                                return ListTile(
                                  title: Text(secret.displayName),
                                  subtitle: Text(secret.formattedCreatedAt),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteSecret(secret.id),
                                  ),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
                _buildSettingCard(
                  title: '安全设置',
                  leading: const Icon(Icons.security, size: 24),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.notifications, size: 20),
                        title: const Text('推送通知'),
                        trailing: Switch(
                          value: true,
                          onChanged: (value) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('推送设置功能开发中')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSettingCard(
                  title: '关于',
                  leading: const Icon(Icons.info, size: 24),
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('版本号'),
                        trailing: Text(_appVersion),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('服务条款'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TermsOfServicePage()),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('隐私政策'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextButton(
                    onPressed: _logout,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text('退出登录'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

class SecretDetailDialog extends StatelessWidget {
  final SecretWithKey secret;

  const SecretDetailDialog({super.key, required this.secret});

  Future<void> _copyKey(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: secret.secretKey));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('秘钥已复制到剪贴板')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Secret 创建成功'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('请妥善保管您的秘钥，它只会显示一次！'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    secret.secretKey,
                    style: const TextStyle(fontFamily: 'Monospace', fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyKey(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('名称: '),
              Text(secret.name ?? '未命名'),
            ],
          ),
          Row(
            children: [
              const Text('ID: '),
              Text(secret.id.toString()),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('确定'),
        ),
      ],
    );
  }
}