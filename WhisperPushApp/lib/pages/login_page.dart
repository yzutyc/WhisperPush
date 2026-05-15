import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_service.dart';
import '../components/empty_state.dart';
import '../components/form_input.dart';
import '../components/glass_card.dart';
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
  bool _isCheckingServer = false;
  String? _serverStatus;
  bool? _serverAvailable;
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

  Future<void> _checkServerStatus() async {
    final url = _serverUrlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isCheckingServer = true;
      _serverStatus = '验证中...';
      _serverAvailable = null;
    });

    try {
      final api = ApiService(baseUrl: url);
      final available = await api.checkServerStatus();
      
      setState(() {
        _serverAvailable = available;
        _serverStatus = available ? '✓ 服务可用' : '✗ 服务不可用';
      });

      if (available) {
        ToastWidget.showSuccess(context, '服务器连接成功');
      } else {
        ToastWidget.showWarning(context, '服务器不可用，请检查地址');
      }
    } catch (e) {
      setState(() {
        _serverAvailable = false;
        _serverStatus = '✗ 连接失败';
      });
      ToastWidget.showError(context, '连接失败: ${e.toString()}');
    } finally {
      setState(() => _isCheckingServer = false);
    }
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
      ToastWidget.showError(context, '登录失败: ${e.toString()}');
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
          child: SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height,
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
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppTheme.techPurple, AppTheme.neonBlue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.techPurple.withOpacity(0.5),
                                  blurRadius: 40,
                                  spreadRadius: 15,
                                ),
                                BoxShadow(
                                  color: AppTheme.neonBlue.withOpacity(0.3),
                                  blurRadius: 25,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: LogoWidget(size: 50),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'WhisperPush',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
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
                              color: const Color.fromARGB(20, 139, 92, 246),
                              border: Border.all(
                                color: AppTheme.techPurple.withOpacity(0.2),
                              ),
                            ),
                            child: const Text(
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
                            color: AppTheme.techPurple.withOpacity(0.15),
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
                                '欢迎回来',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '请登录您的账户',
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
                                      color: const Color.fromARGB(25, 139, 92, 246),
                                      border: Border.all(
                                        color: AppTheme.techPurple.withOpacity(0.25),
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
                                            color: Color.fromARGB(30, 6, 182, 212),
                                          ),
                                          child: const Icon(
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
                                          style: const TextStyle(
                                            color: AppTheme.neonBlueLight,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
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
                              GlassCard(
                                enableHover: false,
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
                                  child: const Text(
                                    '忘记密码?',
                                    style: TextStyle(color: AppTheme.textTertiary),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              NeonButton(
                                text: '登录',
                                onPressed: _submit,
                                isLoading: _isLoading,
                                height: 52,
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
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
                                    child: const Text(
                                      '立即注册',
                                      style: TextStyle(
                                        color: AppTheme.techPurpleLight,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppTheme.techPurpleLight,
                                        decorationThickness: 1.5,
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
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppTheme.spaceBlue,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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
              '选择历史地址或输入新地址',
              style: TextStyle(color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 24),
            GlassCard(
              padding: const EdgeInsets.all(0),
              enableHover: false,
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
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
                    return GlassCard(
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
                                  color: AppTheme.techPurple.withOpacity(0.2),
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
            const SizedBox(height: 24),
            NeonButton(
              text: '确认',
              onPressed: _confirm,
              height: 50,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}