import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../api/api_service.dart';
import '../providers/auth_provider.dart';
import '../models/secret.dart';
import '../models/user.dart';
import '../components/glass_card.dart';
import '../components/neon_button.dart';
import '../components/neon_switch.dart';
import '../components/empty_state.dart';
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
  String? _serverUrl;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadSecrets();
    _loadAppVersion();
    _loadServerUrl();
  }

  void _loadServerUrl() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _serverUrl = authProvider.serverUrl;
    });
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
      await api.createSecret();
      await _loadSecrets();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Secret 创建成功')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建失败: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSecret(int id) async {
    if (!await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          enableHover: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '确认删除',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '确定要删除这个 Secret 吗？',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.spaceBlue,
                        foregroundColor: AppTheme.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppTheme.borderColor),
                      ),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dangerRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('删除'),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      await api.deleteSecret(id);
      await _loadSecrets();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已删除')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    if (!await showDialog(
      context: context,
      builder: (context) => GlassCard(
        padding: const EdgeInsets.all(24),
        enableHover: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '确认退出',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '确定要退出登录吗？',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.spaceBlue,
                      foregroundColor: AppTheme.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppTheme.borderColor),
                    ),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dangerRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('退出'),
                  ),
                ),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          if (icon != null)
            Icon(icon, color: AppTheme.techPurple, size: 20),
          if (icon != null)
            const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textTertiary,
              letterSpacing: 1.5,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isHighlighted 
                    ? const Color.fromARGB(30, 139, 92, 246)
                    : const Color.fromARGB(40, 51, 65, 85),
              ),
              child: Icon(icon, 
                color: isHighlighted ? AppTheme.techPurple : AppTheme.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
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

  Widget _buildServerInfoCard() {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(0),
      enableHover: true,
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color.fromARGB(30, 6, 182, 212),
              ),
              child: const Icon(Icons.cloud, color: AppTheme.neonBlue, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '服务器地址',
                    style: TextStyle(fontSize: 13, color: AppTheme.textTertiary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _serverUrl ?? '未设置',
                    style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  '切换',
                  style: TextStyle(fontSize: 13, color: AppTheme.techPurple),
                ),
                const SizedBox(width: 4),
                Icon(Icons.refresh, size: 16, color: AppTheme.techPurple),
              ],
            ),
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
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildServerInfoCard(),
                  _buildSectionHeader('账户', icon: Icons.account_circle),
                  GlassCard(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(0),
                    enableHover: false,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppTheme.borderColor.withOpacity(0.3)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.techPurple, AppTheme.neonBlue],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color.fromARGB(60, 139, 92, 246),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _currentUser?.username[0].toUpperCase() ?? 'U',
                                    style: const TextStyle(
                                      fontSize: 30,
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
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currentUser?.email ?? 'user@example.com',
                                      style: TextStyle(
                                        fontSize: 13,
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
                  GlassCard(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(0),
                    enableHover: false,
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
                            child: EmptyState(
                              icon: Icons.key_off,
                              title: '暂无 Secret',
                              description: '点击上方按钮创建新的 Secret',
                            ),
                          )
                        else
                          ..._secrets.map((secret) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppTheme.borderColor.withOpacity(0.3),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: const Color.fromARGB(30, 139, 92, 246),
                                    ),
                                    child: const Icon(
                                      Icons.key,
                                      color: AppTheme.techPurple,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
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
                                      size: 20,
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
                  GlassCard(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(0),
                    enableHover: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: const Color.fromARGB(40, 51, 65, 85),
                            ),
                            child: const Icon(
                              Icons.notifications,
                              color: AppTheme.textSecondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
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
                  ),
                  _buildSectionHeader('关于', icon: Icons.info),
                  GlassCard(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(0),
                    enableHover: false,
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
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppTheme.dangerRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.borderRadius,
                          border: Border.all(color: AppTheme.dangerRed),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('退出登录'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }
}