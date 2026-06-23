import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_service.dart';
import '../components/empty_state.dart';
import '../components/form_input.dart';
import '../components/glass_container.dart';
import '../components/logo_widget.dart';
import '../components/neon_button.dart';
import '../components/particle_background.dart';
import '../components/toast_widget.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/server_cache.dart';
import 'forgot_password_page.dart';
import 'message_list_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverUrlController = TextEditingController();
  final _twoFactorController = TextEditingController();
  bool _isLoading = false;
  bool _requiresTwoFactor = false;
  String? _tempUsername;
  String? _tempPassword;
  List<String> _historyUrls = [];

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _serverUrlController.text = authProvider.serverUrl ?? '';
    _loadHistoryUrls();
  }

  Future<void> _loadHistoryUrls() async {
    final urls = await ServerCache.getHistoryUrls();
    setState(() {
      _historyUrls = urls;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final url = _serverUrlController.text.trim();
    if (url.isEmpty) {
      ToastWidget.showWarning(context, '请先设置服务器地址');
      return;
    }

    if (_requiresTwoFactor) {
      await _submitTwoFactor(url);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(baseUrl: url);

      final result = await api.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (result['requires_two_factor'] == true) {
        setState(() {
          _requiresTwoFactor = true;
          _tempUsername = _usernameController.text.trim();
          _tempPassword = _passwordController.text.trim();
        });
        return;
      }

      await authProvider.login(
        token: result['access_token'],
        serverUrl: url,
        username: result['username'],
      );

      await ServerCache.addUrl(url);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MessageListPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        ToastWidget.showError(context, '登录失败: $errorMessage');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitTwoFactor(String url) async {
    if (_twoFactorController.text.isEmpty) {
      ToastWidget.showWarning(context, '请输入6位验证码');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(baseUrl: url);

      final result = await api.loginWithTwoFactor(
        _tempUsername!,
        _tempPassword!,
        _twoFactorController.text.trim(),
      );

      await authProvider.login(
        token: result['access_token'],
        serverUrl: url,
        username: result['username'],
      );

      await ServerCache.addUrl(url);

      if (mounted) {
        setState(() {
          _requiresTwoFactor = false;
          _tempUsername = null;
          _tempPassword = null;
          _twoFactorController.clear();
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MessageListPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        ToastWidget.showError(context, '登录失败: $errorMessage');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _cancelTwoFactor() {
    setState(() {
      _requiresTwoFactor = false;
      _tempUsername = null;
      _tempPassword = null;
      _twoFactorController.clear();
    });
  }

  void _showServerSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ServerSelectorDialog(
        currentUrl: _serverUrlController.text,
        historyUrls: _historyUrls,
        onSelect: (url) {
          setState(() {
            _serverUrlController.text = url;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _serverUrlController.dispose();
    _twoFactorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: ParticleBackground(
          particleCount: 40,
          child: Container(
            decoration: AppTheme.gradientBackground,
            child: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.techPurple.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const LogoWidget(size: 80),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'WhisperPush',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Secure Push Notifications',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textTertiary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: AppTheme.borderRadiusSmall,
                            color: const Color.fromARGB(51, 139, 92, 246),
                            border: Border.all(
                              color: AppTheme.techPurple.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            '端到端加密',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.techPurpleLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.spaceBlue,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.techPurple.withValues(alpha: 0.15),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 24),
                            Text(
                              _requiresTwoFactor ? '验证二步' : '欢迎回来',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _requiresTwoFactor
                                  ? '请输入6位验证码'
                                  : '请登录您的账户',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 32),
                            Align(
                              alignment: Alignment.centerRight,
                              child: InkWell(
                                onTap: _showServerSelector,
                                borderRadius: AppTheme.borderRadiusSmall,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: AppTheme.borderRadiusSmall,
                                    color: const Color.fromARGB(64, 139, 92, 246),
                                    border: Border.all(
                                      color: AppTheme.techPurple.withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                          borderRadius: AppTheme.borderRadiusSmall,
                                          color: Color.fromARGB(77, 6, 182, 212),
                                        ),
                                        child: Icon(
                                          Icons.cloud,
                                          color: AppTheme.neonBlue,
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _serverUrlController.text.isNotEmpty
                                            ? _serverUrlController.text.length > 20
                                                ? '${_serverUrlController.text.substring(0, 20)}...'
                                                : _serverUrlController.text
                                            : '选择服务器',
                                        style: TextStyle(
                                          color: AppTheme.neonBlueLight,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        color: AppTheme.neonBlueLight,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_requiresTwoFactor) ...[
                              GlassContainer(
                                padding: const EdgeInsets.all(0),
                                child: FormInput(
                                  controller: _twoFactorController,
                                  labelText: '6位验证码',
                                  prefixIcon: Icons.lock,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) return '请输入验证码';
                                    if (value?.length != 6) return '验证码应为6位';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _cancelTwoFactor,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.spaceIndigo,
                                        foregroundColor: AppTheme.textTertiary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      child: const Text('返回'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: NeonButton(
                                      text: '验证',
                                      onPressed: _isLoading ? null : _submit,
                                      isLoading: _isLoading,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                                FormInput(
                                  controller: _usernameController,
                                  labelText: '用户名或邮箱',
                                  prefixIcon: Icons.person,
                                  validator: (value) =>
                                  value?.isEmpty ?? true ? '请输入用户名' : null,
                                ),
                                const SizedBox(height: 16),
                                FormInput(
                                  controller: _passwordController,
                                  labelText: '密码',
                                  prefixIcon: Icons.lock,
                                  obscureText: true,
                                  validator: (value) =>
                                  value?.isEmpty ?? true ? '请输入密码' : null,
                                  onFieldSubmitted: (_) => _submit(),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const ForgotPasswordPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    '忘记密码?',
                                    style: TextStyle(color: AppTheme.textTertiary),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              NeonButton(
                                text: '登录',
                                onPressed: _isLoading ? null : _submit,
                                isLoading: _isLoading,
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '还没有账户? ',
                                    style: TextStyle(
                                      color: AppTheme.textTertiary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const RegisterPage(),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                    ),
                                    child: Text(
                                      '立即注册',
                                      style: TextStyle(
                                        color: AppTheme.techPurpleLight,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppTheme.techPurpleLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                            ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ServerSelectorDialog extends StatefulWidget {
  final String currentUrl;
  final List<String> historyUrls;
  final ValueChanged<String> onSelect;

  const ServerSelectorDialog({
    super.key,
    required this.currentUrl,
    required this.historyUrls,
    required this.onSelect,
  });

  @override
  State<ServerSelectorDialog> createState() => _ServerSelectorDialogState();
}

class _ServerSelectorDialogState extends State<ServerSelectorDialog> {
  final _newUrlController = TextEditingController();
  bool _isChecking = false;
  String? _checkStatus;
  bool? _isAvailable;

  @override
  void initState() {
    super.initState();
    _newUrlController.text = widget.currentUrl;
  }

  Future<void> _checkServer() async {
    final url = _newUrlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isChecking = true;
      _checkStatus = '验证中...';
      _isAvailable = null;
    });

    try {
      final api = ApiService(baseUrl: url);
      final available = await api.checkServerStatus();
      if (!mounted) return;

      setState(() {
        _isAvailable = available;
        _checkStatus = available ? '✓ 服务可用' : '✗ 服务不可用';
      });

      if (available) {
        ToastWidget.showSuccess(context, '服务器连接成功');
      } else {
        ToastWidget.showWarning(context, '服务器不可用');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAvailable = false;
        _checkStatus = '✗ 连接失败';
      });
      ToastWidget.showError(context, '连接失败: $e');
    } finally {
      setState(() => _isChecking = false);
    }
  }

  void _selectUrl(String url) {
    _newUrlController.text = url;
    _checkServer();
  }

  void _confirm() {
    final url = _newUrlController.text.trim();
    if (url.isEmpty) {
      ToastWidget.showWarning(context, '请输入服务器地址');
      return;
    }
    widget.onSelect(url);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _newUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppTheme.spaceBlue,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '选择服务器',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '选择历史地址或输入新地址',
              style: TextStyle(color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 24),
            GlassContainer(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  FormInput(
                    controller: _newUrlController,
                    labelText: '服务器地址',
                    prefixIcon: Icons.cloud,
                    keyboardType: TextInputType.url,
                    validator: (value) => value?.isEmpty ?? true ? '请输入服务器地址' : null,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_checkStatus != null)
                          Text(
                            _checkStatus!,
                            style: TextStyle(
                              color: _isAvailable == true
                                  ? AppTheme.pulseGreen
                                  : AppTheme.dangerRed,
                              fontSize: 12,
                            ),
                          ),
                        const SizedBox(width: 8),
                        _isChecking
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppTheme.techPurple,
                                  strokeWidth: 2,
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _checkServer,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: AppTheme.techPurple,
                                ),
                                child: const Text(
                                  '验证',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (widget.historyUrls.isNotEmpty) ...[
              Text(
                '历史地址',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textTertiary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              ...widget.historyUrls.map((url) {
                return GlassContainer(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(0),
                  onTap: () => _selectUrl(url),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: const Color.fromARGB(77, 6, 182, 212),
                          ),
                          child: Icon(
                            Icons.cloud,
                            color: AppTheme.neonBlue,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            url,
                            style: TextStyle(color: AppTheme.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.currentUrl == url)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.techPurple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '当前',
                              style: TextStyle(
                                color: AppTheme.techPurple,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                );
              }),
            ] else
              const EmptyState(
                icon: Icons.history,
                title: '暂无历史地址',
                description: '输入新地址并验证后会自动保存',
              ),
            const SizedBox(height: 24),
            NeonButton(
              text: '确认',
              onPressed: _confirm,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
