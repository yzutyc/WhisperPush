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
  bool _isLoading = false;
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

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(baseUrl: url);

      final result = await api.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

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
                                color: AppTheme.techPurple.withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const LogoWidget(size: 80),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'WhisperPush',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Secure Push Notifications',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppTheme.spaceBlue,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 16),
                              const Text(
                                '欢迎回来',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '请登录您的账户',
                                style: TextStyle(color: AppTheme.textTertiary),
                              ),
                              const SizedBox(height: 32),
                              GlassContainer(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  children: [
                                    FormInput(
                                      controller: _usernameController,
                                      labelText: '用户名或邮箱',
                                      prefixIcon: Icons.person,
                                      validator: (value) =>
                                          value?.isEmpty ?? true ? '请输入用户名或邮箱' : null,
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
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: _showServerSelector,
                                    child: const Text(
                                      '选择服务器',
                                      style: TextStyle(
                                        color: AppTheme.textTertiary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ForgotPasswordPage(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      '忘记密码？',
                                      style: TextStyle(
                                        color: AppTheme.textTertiary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              NeonButton(
                                text: '登录',
                                onPressed: _submit,
                                isLoading: _isLoading,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    '还没有账户？',
                                    style: TextStyle(color: AppTheme.textTertiary),
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
                                    child: const Text(
                                      '立即注册',
                                      style: TextStyle(
                                        color: AppTheme.techPurple,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: AppTheme.spaceBlue,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
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
            const Text(
              '选择服务器',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '或输入新地址',
              style: TextStyle(color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 32),
            GlassContainer(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  FormInput(
                    controller: _newUrlController,
                    labelText: '服务器地址',
                    prefixIcon: Icons.cloud,
                    keyboardType: TextInputType.url,
                    hintText: 'https://api.example.com',
                    validator: (value) =>
                        value?.isEmpty ?? true ? '请输入服务器地址' : null,
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
                            ? const SizedBox(
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
            const SizedBox(height: 32),
            if (widget.historyUrls.isNotEmpty)
              Column(
                children: [
                  const Text(
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
                                color: const Color.fromARGB(30, 6, 182, 212),
                              ),
                              child: const Icon(
                                Icons.cloud,
                                color: AppTheme.neonBlue,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                url,
                                style: const TextStyle(color: AppTheme.textPrimary),
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
                                child: const Text(
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
                ],
              )
            else
              const EmptyState(
                icon: Icons.history,
                title: '暂无历史地址',
                description: '输入新地址并验证后会自动保存',
              ),
            const SizedBox(height: 32),
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
