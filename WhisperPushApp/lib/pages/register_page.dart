import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_service.dart';
import '../components/form_input.dart';
import '../components/glass_container.dart';
import '../components/logo_widget.dart';
import '../components/neon_button.dart';
import '../components/particle_background.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String _passwordError = '';
  String _confirmPasswordError = '';

  String _getPasswordStrength(String password) {
    if (password.length < 6) return '弱';
    if (password.length < 8) return '中';
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[0-9]').hasMatch(password)) return '强';
    return '中';
  }

  Color _getPasswordStrengthColor(String strength) {
    switch (strength) {
      case '弱':
        return AppTheme.dangerRed;
      case '中':
        return AppTheme.warningOrange;
      case '强':
        return AppTheme.pulseGreen;
      default:
        return AppTheme.textTertiary;
    }
  }

  void _validatePasswords() {
    setState(() {
      if (_passwordController.text.length < 6) {
        _passwordError = '密码至少6位';
      } else {
        _passwordError = '';
      }

      if (_confirmPasswordController.text.isNotEmpty && 
          _confirmPasswordController.text != _passwordController.text) {
        _confirmPasswordError = '两次输入的密码不一致';
      } else {
        _confirmPasswordError = '';
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordError.isNotEmpty || _confirmPasswordError.isNotEmpty) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(baseUrl: authProvider.serverUrl!);

      await api.register(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('注册成功，请登录'),
            backgroundColor: AppTheme.spaceIndigo,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('注册失败: ${e.toString()}'),
            backgroundColor: AppTheme.spaceIndigo,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          children: [
                            const SizedBox(height: 16),
                            const Text(
                              '创建账户',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '请填写以下信息',
                              style: TextStyle(color: AppTheme.textTertiary),
                            ),
                            const SizedBox(height: 32),
                            GlassContainer(
                              padding: const EdgeInsets.all(0),
                              child: Column(
                                children: [
                                  FormInput(
                                    controller: _usernameController,
                                    labelText: '用户名',
                                    prefixIcon: Icons.person,
                                    validator: (value) => 
                                        value?.isEmpty ?? true ? '请输入用户名' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  FormInput(
                                    controller: _emailController,
                                    labelText: '邮箱',
                                    prefixIcon: Icons.email,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) return '请输入邮箱';
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                                        return '请输入有效的邮箱地址';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      FormInput(
                                        controller: _passwordController,
                                        labelText: '密码',
                                        prefixIcon: Icons.lock,
                                        obscureText: true,
                                        onChanged: (value) => _validatePasswords(),
                                        errorText: _passwordError.isNotEmpty ? _passwordError : null,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Text(
                                            '密码强度: ',
                                            style: TextStyle(color: AppTheme.textTertiary),
                                          ),
                                          Text(
                                            _getPasswordStrength(_passwordController.text),
                                            style: TextStyle(
                                              color: _getPasswordStrengthColor(_getPasswordStrength(_passwordController.text)),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: _passwordController.text.length >= 6 ? 1 : 0,
                                                  child: Container(
                                                    height: 4,
                                                    decoration: BoxDecoration(
                                                      color: _passwordController.text.length >= 6 
                                                          ? _getPasswordStrengthColor(_getPasswordStrength(_passwordController.text))
                                                          : AppTheme.borderColor,
                                                      borderRadius: BorderRadius.circular(2),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 2),
                                                Expanded(
                                                  flex: _passwordController.text.length >= 8 ? 1 : 0,
                                                  child: Container(
                                                    height: 4,
                                                    decoration: BoxDecoration(
                                                      color: _passwordController.text.length >= 8 
                                                          ? _getPasswordStrengthColor(_getPasswordStrength(_passwordController.text))
                                                          : AppTheme.borderColor,
                                                      borderRadius: BorderRadius.circular(2),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 2),
                                                Expanded(
                                                  flex: (_passwordController.text.length >= 8 && 
                                                      RegExp(r'[A-Z]').hasMatch(_passwordController.text) && 
                                                      RegExp(r'[0-9]').hasMatch(_passwordController.text)) 
                                                          ? 1 : 0,
                                                  child: Container(
                                                    height: 4,
                                                    decoration: BoxDecoration(
                                                      color: (_passwordController.text.length >= 8 && 
                                                          RegExp(r'[A-Z]').hasMatch(_passwordController.text) && 
                                                          RegExp(r'[0-9]').hasMatch(_passwordController.text)) 
                                                              ? AppTheme.pulseGreen
                                                              : AppTheme.borderColor,
                                                      borderRadius: BorderRadius.circular(2),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  FormInput(
                                    controller: _confirmPasswordController,
                                    labelText: '确认密码',
                                    prefixIcon: Icons.lock,
                                    obscureText: true,
                                    onChanged: (value) => _validatePasswords(),
                                    errorText: _confirmPasswordError.isNotEmpty ? _confirmPasswordError : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            NeonButton(
                              text: '注册',
                              onPressed: _submit,
                              isLoading: _isLoading,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '已有账户？',
                                  style: TextStyle(color: AppTheme.textTertiary),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    '立即登录',
                                    style: TextStyle(
                                      color: AppTheme.techPurple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '注册即表示您同意我们的服务条款和隐私政策',
                              style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                              textAlign: TextAlign.center,
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
    );
  }
}