import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_service.dart';
import '../providers/auth_provider.dart';
import '../components/form_input.dart';
import '../components/custom_button.dart';
import 'login_page.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isChanged = false;

  String _newPasswordError = '';
  String _confirmPasswordError = '';

  void _validatePasswords() {
    setState(() {
      if (_newPasswordController.text.length < 6) {
        _newPasswordError = '密码至少6位';
      } else {
        _newPasswordError = '';
      }

      if (_confirmPasswordController.text.isNotEmpty && 
          _confirmPasswordController.text != _newPasswordController.text) {
        _confirmPasswordError = '两次输入的密码不一致';
      } else {
        _confirmPasswordError = '';
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newPasswordError.isNotEmpty || _confirmPasswordError.isNotEmpty) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );

      await api.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      setState(() {
        _isChanged = true;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('修改失败: ${e.toString()}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logoutAndRedirect() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('修改密码'),
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
            child: _isChanged
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
                        '密码修改成功',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '请使用新密码重新登录',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: '重新登录',
                        onPressed: _logoutAndRedirect,
                      ),
                    ],
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 48),
                        const Text(
                          '修改密码',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '请输入当前密码和新密码',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 48),
                        FormInput(
                          controller: _currentPasswordController,
                          labelText: '当前密码',
                          prefixIcon: Icons.lock,
                          obscureText: true,
                          validator: (value) => 
                              value?.isEmpty ?? true ? '请输入当前密码' : null,
                        ),
                        const SizedBox(height: 16),
                        FormInput(
                          controller: _newPasswordController,
                          labelText: '新密码',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          onChanged: (_) => _validatePasswords(),
                          errorText: _newPasswordError.isNotEmpty ? _newPasswordError : null,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return '请输入新密码';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        FormInput(
                          controller: _confirmPasswordController,
                          labelText: '确认新密码',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          onChanged: (_) => _validatePasswords(),
                          errorText: _confirmPasswordError.isNotEmpty ? _confirmPasswordError : null,
                          validator: (value) => 
                              value?.isEmpty ?? true ? '请确认新密码' : null,
                        ),
                        const SizedBox(height: 32),
                        CustomButton(
                          text: '修改密码',
                          onPressed: _submit,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('取消'),
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