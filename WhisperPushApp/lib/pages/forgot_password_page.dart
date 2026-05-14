import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_service.dart';
import '../providers/auth_provider.dart';
import '../components/form_input.dart';
import '../components/custom_button.dart';
import 'login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSubmitted = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(baseUrl: authProvider.serverUrl!);

      await api.forgotPassword(_emailController.text);

      setState(() {
        _isSubmitted = true;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: ${e.toString()}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('忘记密码'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _isSubmitted
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 80,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '重置邮件已发送',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '请检查您的邮箱，点击邮件中的链接重置密码',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: '返回登录',
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                      ),
                    ],
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 48),
                        const Text(
                          '忘记密码',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '请输入您注册时使用的邮箱，我们会发送重置链接到您的邮箱',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 48),
                        FormInput(
                          controller: _emailController,
                          labelText: '邮箱地址',
                          prefixIcon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return '请输入邮箱地址';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                              return '请输入有效的邮箱地址';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        CustomButton(
                          text: '发送重置链接',
                          onPressed: _submit,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('返回登录'),
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