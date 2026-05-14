import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_service.dart';
import '../providers/auth_provider.dart';
import '../components/form_input.dart';
import '../components/custom_button.dart';
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
        return Colors.red;
      case '中':
        return Colors.orange;
      case '强':
        return Colors.green;
      default:
        return Colors.grey;
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
          const SnackBar(content: Text('注册成功，请登录')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('注册失败: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Color(0xFF5C6BC0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.message,
                        size: 80,
                        color: Colors.white,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'WhisperPush',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Secure Push Notifications',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
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
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            '创建账户',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '请填写以下信息',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 32),
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
                                  const Text('密码强度: '),
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
                                            color: _passwordController.text.length >= 6 
                                                ? _getPasswordStrengthColor(_getPasswordStrength(_passwordController.text))
                                                : Colors.grey[300],
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          flex: _passwordController.text.length >= 8 ? 1 : 0,
                                          child: Container(
                                            height: 4,
                                            color: _passwordController.text.length >= 8 
                                                ? _getPasswordStrengthColor(_getPasswordStrength(_passwordController.text))
                                                : Colors.grey[300],
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
                                            color: (_passwordController.text.length >= 8 && 
                                                RegExp(r'[A-Z]').hasMatch(_passwordController.text) && 
                                                RegExp(r'[0-9]').hasMatch(_passwordController.text)) 
                                                    ? Colors.green
                                                    : Colors.grey[300],
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
                          const SizedBox(height: 24),
                          CustomButton(
                            text: '注册',
                            onPressed: _submit,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('已有账户？'),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  '立即登录',
                                  style: TextStyle(
                                    color: Colors.indigo,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '注册即表示您同意我们的服务条款和隐私政策',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('服务条款')),
                                  );
                                },
                                child: const Text(
                                  '服务条款',
                                  style: TextStyle(color: Colors.indigo, fontSize: 12),
                                ),
                              ),
                              const Text(' | '),
                              TextButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('隐私政策')),
                                  );
                                },
                                child: const Text(
                                  '隐私政策',
                                  style: TextStyle(color: Colors.indigo, fontSize: 12),
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
    );
  }
}