import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_service.dart';
import '../components/form_input.dart';
import '../components/glass_container.dart';
import '../components/neon_button.dart';
import '../components/toast_widget.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String resetToken;

  const ResetPasswordPage({super.key, required this.resetToken});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
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
    if (_newPasswordError.isNotEmpty || _confirmPasswordError.isNotEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(baseUrl: authProvider.serverUrl!);

      await api.resetPassword(widget.resetToken, _newPasswordController.text);

      setState(() {
        _isChanged = true;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        ToastWidget.showError(context, '重置失败: $errorMessage');
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.spaceBlue,
        title: Text('重置密码', style: TextStyle(color: AppTheme.textPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
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
                              color: AppTheme.pulseGreen.withValues(alpha: 0.2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.pulseGreen.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 15,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.check_circle,
                              size: 50,
                              color: AppTheme.pulseGreen,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '密码重置成功',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '请使用新密码登录您的账户',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textTertiary),
                          ),
                          const SizedBox(height: 32),
                          NeonButton(
                            text: '返回登录',
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                                (route) => false,
                              );
                            },
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
                                color: AppTheme.techPurple.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                              child: Icon(
                                Icons.lock_reset,
                                size: 40,
                                color: AppTheme.techPurple,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              '重置密码',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '请输入您的新密码',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textTertiary),
                            ),
                            const SizedBox(height: 48),
                            FormInput(
                              controller: _newPasswordController,
                              labelText: '新密码',
                              prefixIcon: Icons.lock_outline,
                              obscureText: true,
                              onChanged: (value) => _validatePasswords(),
                              errorText: _newPasswordError.isNotEmpty
                                  ? _newPasswordError
                                  : null,
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
                              onChanged: (value) => _validatePasswords(),
                              errorText: _confirmPasswordError.isNotEmpty
                                  ? _confirmPasswordError
                                  : null,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? '请确认新密码' : null,
                            ),
                            const SizedBox(height: 32),
                            NeonButton(
                              text: '重置密码',
                              onPressed: _submit,
                              isLoading: _isLoading,
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
