import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_service.dart';
import '../providers/auth_provider.dart';
import '../components/form_input.dart';
import '../components/neon_button.dart';
import '../components/glass_container.dart';
import '../theme/app_theme.dart';
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
          SnackBar(
            content: Text('修改失败: ${e.toString()}'),
            backgroundColor: AppTheme.spaceIndigo,
          ),
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
        backgroundColor: AppTheme.spaceBlue,
        title: const Text('修改密码', style: TextStyle(color: AppTheme.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _isChanged
                  ? GlassContainer(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.pulseGreen.withOpacity(0.2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.pulseGreen.withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              size: 50,
                              color: AppTheme.pulseGreen,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '密码修改成功',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '请使用新密码重新登录',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textTertiary),
                          ),
                          const SizedBox(height: 32),
                          NeonButton(
                            text: '重新登录',
                            onPressed: _logoutAndRedirect,
                          ),
                        ],
                      ),
                    )
                  : GlassContainer(
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.neonBlue.withOpacity(0.2),
                              ),
                              child: const Icon(
                                Icons.key,
                                size: 40,
                                color: AppTheme.neonBlue,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              '修改密码',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '请输入当前密码和新密码',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textTertiary),
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
                            NeonButton(
                              text: '修改密码',
                              onPressed: _submit,
                              isLoading: _isLoading,
                            ),
                            const SizedBox(height: 24),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                '取消',
                                style: TextStyle(color: AppTheme.textTertiary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}