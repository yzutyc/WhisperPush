import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../api/api_service.dart';
import '../providers/auth_provider.dart';
import '../components/form_input.dart';
import '../components/neon_button.dart';
import '../components/glass_container.dart';
import '../components/particle_background.dart';
import '../components/logo_widget.dart';
import '../components/toast_widget.dart';
import '../utils/server_cache.dart';
import '../theme/app_theme.dart';
import 'register_page.dart';
import 'message_list_page.dart';
import 'forgot_password_page.dart';

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
  bool _showHistoryDropdown = false;

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
      ToastWidget.showError(context, '服务器连接失败: ${e.toString()}');
    } finally {
      setState(() {
        _isCheckingServer = false;
      });
    }
  }

  void _selectHistoryUrl(String url) {
    setState(() {
      _serverUrlController.text = url;
      _showHistoryDropdown = false;
    });
    _checkServerStatus();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      await authProvider.saveServerUrl(_serverUrlController.text);
      await ServerCache.setCurrentServer(_serverUrlController.text);
      
      final api = ApiService(baseUrl: authProvider.serverUrl!);
      
      final result = await api.login(
        _usernameController.text,
        _passwordController.text,
      );

      await authProvider.saveToken(result['access_token']);

      if (mounted) {
        ToastWidget.showSuccess(context, '登录成功');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MessageListPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ToastWidget.showError(context, '登录失败: ${e.toString()}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
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
          particleCount: 50,
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
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.techPurple.withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: LogoWidget(size: 80),
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
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppTheme.spaceBlue,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
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
                              GlassContainer(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    FormInput(
                                      controller: _serverUrlController,
                                      labelText: '服务器地址',
                                      prefixIcon: Icons.cloud,
                                      keyboardType: TextInputType.url,
                                      validator: (value) => 
                                          value?.isEmpty ?? true ? '请输入服务器地址' : null,
                                      onChanged: (_) {
                                        setState(() {
                                          _serverStatus = null;
                                          _serverAvailable = null;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (_serverStatus != null)
                                          Expanded(
                                            child: Text(
                                              _serverStatus!,
                                              style: TextStyle(
                                                color: _serverAvailable == true 
                                                  ? AppTheme.pulseGreen 
                                                  : AppTheme.dangerRed,
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        const SizedBox(width: 8),
                                        Row(
                                          children: [
                                            if (_historyUrls.isNotEmpty)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.arrow_drop_down,
                                                  color: AppTheme.textTertiary,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _showHistoryDropdown = !_showHistoryDropdown;
                                                  });
                                                },
                                              ),
                                            _isCheckingServer
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      color: AppTheme.techPurple,
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : ElevatedButton(
                                                    onPressed: _checkServerStatus,
                                                    style: ElevatedButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 12, 
                                                        vertical: 6,
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      minimumSize: const Size(60, 32),
                                                      backgroundColor: AppTheme.techPurple,
                                                    ),
                                                    child: const Text(
                                                      '验证',
                                                      style: TextStyle(color: Colors.white),
                                                    ),
                                                  ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (_showHistoryDropdown && _historyUrls.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: AppTheme.borderColor),
                                          borderRadius: BorderRadius.circular(8),
                                          color: AppTheme.spaceIndigo,
                                        ),
                                        child: Column(
                                          children: _historyUrls.map((url) {
                                            return ListTile(
                                              title: Text(
                                                url,
                                                style: const TextStyle(color: AppTheme.textSecondary),
                                              ),
                                              onTap: () => _selectHistoryUrl(url),
                                              trailing: const Icon(
                                                Icons.arrow_right,
                                                color: AppTheme.textTertiary,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              GlassContainer(
                                padding: const EdgeInsets.all(0),
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
                                    '忘记密码？',
                                    style: TextStyle(color: AppTheme.techPurple),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              NeonButton(
                                text: '登录',
                                onPressed: _submit,
                                isLoading: _isLoading,
                              ),
                              const SizedBox(height: 24),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
