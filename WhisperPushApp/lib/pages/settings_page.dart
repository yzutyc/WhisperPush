import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../api/api_service.dart';
import '../providers/auth_provider.dart';
import '../models/secret.dart';
import '../models/user.dart';
import '../components/glass_container.dart';
import '../components/neon_button.dart';
import '../components/neon_switch.dart';
import '../theme/app_theme.dart';
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
  bool _notificationsEnabled = true;

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
      builder: (context) => GlassContainer(
        child: AlertDialog(
          backgroundColor: AppTheme.spaceIndigo,
          title: const Text('确认删除', style: TextStyle(color: AppTheme.textPrimary)),
          content: const Text(
            '确定要删除这个 Secret 吗？',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消', style: TextStyle(color: AppTheme.textTertiary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除', style: TextStyle(color: AppTheme.dangerRed)),
            ),
          ],
        ),
      ),
    ) ?? false;
  }

  Future<void> _logout() async {
    if (!await showDialog(
      context: context,
      builder: (context) => GlassContainer(
        child: AlertDialog(
          backgroundColor: AppTheme.spaceIndigo,
          title: const Text('确认退出', style: TextStyle(color: AppTheme.textPrimary)),
          content: const Text(
            '确定要退出登录吗？',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消', style: TextStyle(color: AppTheme.textTertiary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('退出', style: TextStyle(color: AppTheme.dangerRed)),
            ),
          ],
        ),
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

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (icon != null)
            Icon(icon, color: AppTheme.techPurple, size: 20),
          if (icon != null)
            const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textTertiary,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isHighlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.borderColor.withOpacity(0.5)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isHighlighted 
                    ? AppTheme.techPurple.withOpacity(0.2)
                    : AppTheme.spaceBlue,
              ),
              child: Icon(icon, 
                color: isHighlighted ? AppTheme.techPurple : AppTheme.textTertiary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                      color: isHighlighted ? AppTheme.techPurple : AppTheme.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.spaceBlue,
        title: const Text('设置', style: TextStyle(color: AppTheme.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.techPurple),
              )
            : ListView(
                children: [
                  _buildSectionHeader('账户信息', icon: Icons.account_circle),
                  GlassContainer(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppTheme.borderColor.withOpacity(0.5)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.techPurple, AppTheme.neonBlue],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.techPurple.withOpacity(0.3),
                                      blurRadius: 15,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _currentUser?.username[0].toUpperCase() ?? 'U',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentUser?.username ?? '用户名',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currentUser?.email ?? 'user@example.com',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildSettingItem(
                          icon: Icons.lock,
                          title: '修改密码',
                          subtitle: '更新您的账户密码',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                            );
                          },
                        ),
                        _buildSettingItem(
                          icon: Icons.shield,
                          title: '双因素认证',
                          subtitle: '增强账户安全性',
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
                  _buildSectionHeader('Secret 管理', icon: Icons.key),
                  GlassContainer(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: NeonButton(
                            text: '新建 Secret',
                            onPressed: _createSecret,
                            isLoading: _isLoading,
                          ),
                        ),
                        if (_secrets.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(color: AppTheme.borderColor),
                                  ),
                                  child: const Icon(
                                    Icons.key_off,
                                    size: 32,
                                    color: AppTheme.textTertiary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '暂无 Secret',
                                  style: TextStyle(color: AppTheme.textTertiary),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._secrets.map((secret) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppTheme.borderColor.withOpacity(0.5),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: AppTheme.spaceBlue,
                                    ),
                                    child: const Icon(
                                      Icons.key,
                                      color: AppTheme.techPurple,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          secret.displayName,
                                          style: TextStyle(color: AppTheme.textPrimary),
                                        ),
                                        Text(
                                          secret.formattedCreatedAt,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textTertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: AppTheme.dangerRed,
                                    ),
                                    onPressed: () => _deleteSecret(secret.id),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                  _buildSectionHeader('安全设置', icon: Icons.security),
                  GlassContainer(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: AppTheme.spaceBlue,
                                ),
                                child: const Icon(
                                  Icons.notifications,
                                  color: AppTheme.textTertiary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '推送通知',
                                      style: TextStyle(color: AppTheme.textPrimary),
                                    ),
                                    Text(
                                      '接收重要消息推送',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              NeonSwitch(
                                value: _notificationsEnabled,
                                onChanged: (value) {
                                  setState(() => _notificationsEnabled = value);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('推送设置功能开发中'),
                                      backgroundColor: AppTheme.spaceIndigo,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSectionHeader('关于', icon: Icons.info),
                  GlassContainer(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      children: [
                        _buildSettingItem(
                          icon: Icons.info_outline,
                          title: '版本号',
                          trailing: Text(
                            _appVersion,
                            style: TextStyle(color: AppTheme.textTertiary),
                          ),
                        ),
                        _buildSettingItem(
                          icon: Icons.description,
                          title: '服务条款',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TermsOfServicePage(),
                              ),
                            );
                          },
                        ),
                        _buildSettingItem(
                          icon: Icons.lock_outline,
                          title: '隐私政策',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PrivacyPolicyPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.dangerRed),
                      ),
                      child: TextButton(
                        onPressed: _logout,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          '退出登录',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.dangerRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
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
      const SnackBar(
        content: Text('秘钥已复制到剪贴板'),
        backgroundColor: AppTheme.spaceIndigo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Secret 创建成功',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.spaceBlue,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Text(
                '请妥善保管您的秘钥，它只会显示一次！',
                style: TextStyle(color: AppTheme.warningOrange),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.spaceBlue,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.techPurple.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      secret.secretKey,
                      style: TextStyle(
                        fontFamily: 'Monospace',
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.copy,
                      color: AppTheme.techPurple,
                    ),
                    onPressed: () => _copyKey(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '名称: ',
                  style: TextStyle(color: AppTheme.textTertiary),
                ),
                Text(
                  secret.name ?? '未命名',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'ID: ',
                  style: TextStyle(color: AppTheme.textTertiary),
                ),
                Text(
                  secret.id.toString(),
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            NeonButton(
              text: '确定',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}