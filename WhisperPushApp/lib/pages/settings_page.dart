import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../api/api_service.dart';
import '../components/empty_state.dart';
import '../components/glass_card.dart';
import '../components/neon_button.dart';
import '../components/neon_switch.dart';
import '../components/toast_widget.dart';
import '../models/secret.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';
import 'change_password_page.dart';
import 'device_management_page.dart';
import 'login_page.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';
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
    _loadNotificationsSetting();
  }

  Future<void> _loadNotificationsSetting() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );
      final enabled = await api.getUserNotificationsSetting();
      setState(() {
        _notificationsEnabled = enabled;
      });
    } catch (e) {
      Logger.e('加载推送设置失败', error: e);
    }
  }

  Future<void> _saveNotificationsSetting(bool enabled) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );
      await api.updateUserNotificationsSetting(enabled);
      if (mounted) {
        ToastWidget.showInfo(context, enabled ? '已开启推送通知' : '已关闭推送通知');
      }
    } catch (e) {
      Logger.e('保存推送设置失败', error: e);
      setState(() => _notificationsEnabled = !enabled);
      if (mounted) {
        ToastWidget.showError(context, '保存失败，请检查网络连接');
      }
    }
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
      Logger.e('加载用户信息失败', error: e);
      if (mounted) {
        ToastWidget.showError(context, '加载用户信息失败');
      }
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
      Logger.e('加载Secrets失败', error: e);
      if (mounted) {
        ToastWidget.showError(context, '加载失败');
      }
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
      await _loadSecrets();
      if (mounted) {
        _showSecretKeyDialog(secret.secretKey);
      }
    } catch (e) {
      Logger.e('创建Secret失败', error: e);
      if (mounted) {
        ToastWidget.showError(context, '创建失败');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSecretKeyDialog(String secretKey) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? const Color(0xFF1A1A2E)
            : AppTheme.spaceIndigo,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.key, color: AppTheme.techPurple),
            const SizedBox(width: 8),
            Text(
              '秘钥已生成',
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '请立即复制秘钥，关闭后无法再次查看：',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.techPurple.withValues(
                  alpha: isDark ? 0.1 : 0.08,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.techPurple.withValues(
                    alpha: isDark ? 0.3 : 0.2,
                  ),
                ),
              ),
              child: SelectableText(
                secretKey,
                style: TextStyle(
                  color: AppTheme.techPurple,
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 14),
            label: const Text('复制秘钥'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.techPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: secretKey));
              Navigator.pop(ctx);
              ToastWidget.showSuccess(context, '秘钥已复制到剪贴板');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSecret(int id) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: GlassCard(
          padding: const EdgeInsets.all(28),
          enableHover: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.dangerRed.withValues(alpha: 0.15),
                ),
                child: Icon(Icons.delete, color: AppTheme.dangerRed, size: 28),
              ),
              const SizedBox(height: 20),
              Text(
                '确认删除',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '确定要删除这个 Secret 吗？',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(30, 75, 85, 99),
                        foregroundColor: AppTheme.textSecondary,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppTheme.borderRadius,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: AppTheme.borderColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Text(
                        '取消',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dangerRed,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppTheme.borderRadius,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text(
                        '删除',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );
      await api.deleteSecret(id);
      await _loadSecrets();
      if (mounted) {
        ToastWidget.showSuccess(context, '已删除');
      }
    } catch (e) {
      Logger.e('删除Secret失败', error: e);
      if (mounted) {
        ToastWidget.showError(context, '删除失败');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: GlassCard(
          padding: const EdgeInsets.all(28),
          enableHover: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color.fromARGB(20, 239, 68, 68),
                  border: Border.all(
                    color: AppTheme.dangerRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(Icons.logout, color: AppTheme.dangerRed, size: 28),
              ),
              const SizedBox(height: 20),
              Text(
                '确认退出',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '确定要退出登录吗？',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '您将需要重新输入凭据才能访问',
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(30, 75, 85, 99),
                        foregroundColor: AppTheme.textSecondary,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppTheme.borderRadius,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: AppTheme.borderColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Text(
                        '取消',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dangerRed,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppTheme.borderRadius,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text(
                        '退出登录',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )) {
      return;
    }

    setState(() => _isLoading = true);
    try {
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
      Logger.e('退出登录失败', error: e);
      await authProvider.logout();
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
    final isDark = AppTheme.isDarkMode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          if (icon != null)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isDark
                    ? const Color.fromARGB(20, 139, 92, 246)
                    : AppTheme.techPurple.withValues(alpha: 0.08),
                border: Border.all(
                  color: isDark
                      ? const Color.fromARGB(77, 139, 92, 246)
                      : AppTheme.techPurple.withValues(alpha: 0.15),
                ),
              ),
              child: Icon(icon, color: AppTheme.techPurple, size: 18),
            ),
          if (icon != null) const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.techPurpleLight,
              letterSpacing: 2,
            ),
          ),
          const Expanded(child: SizedBox()),
          Container(
            height: 1,
            width: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.techPurple.withValues(alpha: isDark ? 0.5 : 0.3),
                  Colors.transparent,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
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
    final isDark = AppTheme.isDarkMode;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isHighlighted
                    ? (isDark
                        ? const Color.fromARGB(35, 139, 92, 246)
                        : AppTheme.techPurple.withValues(alpha: 0.12))
                    : (isDark
                        ? const Color.fromARGB(45, 51, 65, 85)
                        : const Color(0xFFF1F5F9)),
                boxShadow: isHighlighted
                    ? [
                        if (isDark)
                          const BoxShadow(
                            color: Color.fromARGB(30, 139, 92, 246),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        if (!isDark)
                          BoxShadow(
                            color: AppTheme.techPurple.withValues(alpha: 0.15),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isHighlighted
                    ? AppTheme.techPurpleLight
                    : AppTheme.textSecondary,
                size: 21,
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
                      fontSize: 15.5,
                      fontWeight: isHighlighted
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isHighlighted
                          ? AppTheme.techPurpleLight
                          : AppTheme.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textTertiary,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              Icon(
                Icons.arrow_forward_ios,
                size: 17,
                color: AppTheme.textTertiary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerInfoCard() {
    final isDark = AppTheme.isDarkMode;
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
                gradient: LinearGradient(
                  colors: [
                    AppTheme.neonBlue.withValues(alpha: isDark ? 0.2 : 0.12),
                    AppTheme.techPurple.withValues(alpha: isDark ? 0.15 : 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(Icons.cloud, color: AppTheme.neonBlue, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '服务器地址',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textTertiary,
                    ),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.techPurple.withValues(alpha: 0.15)
                    : AppTheme.techPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? AppTheme.techPurple.withValues(alpha: 0.3)
                      : AppTheme.techPurple.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '切换',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.techPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.refresh, size: 15, color: AppTheme.techPurple),
                ],
              ),
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
        title: Text('设置', style: TextStyle(color: AppTheme.textPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.techPurple),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildServerInfoCard(),
                  _buildSectionHeader('账户', icon: Icons.account_circle),
                  GlassCard(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(0),
                    enableHover: false,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppTheme.isDarkMode
                                    ? const Color.fromARGB(77, 75, 85, 99)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.techPurple,
                                      AppTheme.neonBlue,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    if (AppTheme.isDarkMode)
                                      const BoxShadow(
                                        color: Color.fromARGB(
                                          60,
                                          139,
                                          92,
                                          246,
                                        ),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    if (!AppTheme.isDarkMode)
                                      BoxShadow(
                                        color: AppTheme.techPurple.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 4),
                                      ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _currentUser?.username[0].toUpperCase() ??
                                        'U',
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
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ChangePasswordPage(),
                              ),
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
                              MaterialPageRoute(
                                builder: (context) => const TwoFactorPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  _buildSectionHeader('Secret 管理', icon: Icons.key),
                  GlassCard(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                            child: const EmptyState(
                              icon: Icons.key_off,
                              title: '暂无 Secret',
                              description: '点击上方按钮创建新的 Secret',
                            ),
                          )
                        else
                          ..._secrets.map((secret) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppTheme.isDarkMode
                                        ? const Color.fromARGB(77, 75, 85, 99)
                                        : const Color(0xFFE2E8F0),
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
                                      color: AppTheme.isDarkMode
                                          ? const Color.fromARGB(
                                              30,
                                              139,
                                              92,
                                              246,
                                            )
                                          : AppTheme.techPurple.withValues(
                                              alpha: 0.1,
                                            ),
                                    ),
                                    child: Icon(
                                      Icons.key,
                                      color: AppTheme.techPurple,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          secret.displayName,
                                          style: TextStyle(
                                            color: AppTheme.textPrimary,
                                          ),
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
                                    icon: Icon(
                                      Icons.delete,
                                      color: AppTheme.dangerRed,
                                      size: 20,
                                    ),
                                    onPressed: () => _deleteSecret(secret.id),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                  _buildSectionHeader('安全设置', icon: Icons.security),
                  GlassCard(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(0),
                    enableHover: false,
                    child: Column(
                      children: [
                        _buildSettingItem(
                          icon: Icons.devices,
                          title: '设备管理',
                          subtitle: '管理您的注册设备',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DeviceManagementPage(),
                              ),
                            );
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: AppTheme.isDarkMode
                                    ? const Color.fromARGB(77, 75, 85, 99)
                                    : const Color(0xFFE2E8F0),
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
                                  color: AppTheme.isDarkMode
                                      ? const Color.fromARGB(40, 51, 65, 85)
                                      : const Color(0xFFF1F5F9),
                                ),
                                child: Icon(
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
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
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
                                  _saveNotificationsSetting(value);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSectionHeader('外观设置', icon: Icons.palette),
                  GlassCard(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(0),
                    enableHover: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: AppTheme.isDarkMode
                                      ? const Color.fromARGB(40, 51, 65, 85)
                                      : const Color(0xFFF1F5F9),
                                  gradient: themeProvider.isDarkMode
                                      ? null
                                      : LinearGradient(
                                          colors: [
                                            const Color(0xFFF8FAFC),
                                            const Color(0xFFF1F5F9),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                ),
                                child: Icon(
                                  themeProvider.isDarkMode
                                      ? Icons.dark_mode
                                      : Icons.light_mode,
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
                                      '深色模式',
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      themeProvider.isDarkMode
                                          ? '当前使用深色主题'
                                          : '当前使用浅色主题',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              NeonSwitch(
                                value: themeProvider.isDarkMode,
                                onChanged: (value) {
                                  themeProvider.toggleTheme();
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  _buildSectionHeader('关于', icon: Icons.info),
                  GlassCard(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                                builder: (context) =>
                                    const TermsOfServicePage(),
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
                          side: BorderSide(color: AppTheme.dangerRed),
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
