// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../api/api_service.dart';
import '../components/glass_container.dart';
import '../components/neon_button.dart';
import '../components/toast_widget.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class TwoFactorPage extends StatefulWidget {
  const TwoFactorPage({super.key});

  @override
  State<TwoFactorPage> createState() => _TwoFactorPageState();
}

class _TwoFactorPageState extends State<TwoFactorPage> {
  bool _isLoading = false;
  bool _isTwoFactorEnabled = false;
  bool _apiAvailable = true;
  String? _apiError;
  String? _qrCodeUrl;
  String? _secret;
  String? _otpAuthUrl;
  List<String> _recoveryCodes = [];
  final _codeController = TextEditingController();
  bool _showRecoveryCodes = false;
  bool _isEnabling = false;

  @override
  void initState() {
    super.initState();
    _loadTwoFactorInfo();
  }

  Future<void> _loadTwoFactorInfo() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );
      final info = await api.getTwoFactorInfo();
      setState(() {
        _isTwoFactorEnabled = info['enabled'] ?? false;
        _apiAvailable = true;
      });
    } catch (e) {
      setState(() {
        _apiAvailable = false;
        _apiError = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _enableTwoFactor() async {
    setState(() => _isEnabling = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );
      final result = await api.enableTwoFactor();
      setState(() {
        _secret = result['secret'];
        _otpAuthUrl = result['otpauth_url'];
      });
    } catch (e) {
      if (mounted) {
        ToastWidget.showError(context, '启用失败: ${e.toString()}');
      }
    } finally {
      setState(() => _isEnabling = false);
    }
  }

  Future<void> _verifyTwoFactor() async {
    if (_codeController.text.isEmpty) {
      ToastWidget.showWarning(context, '请输入验证码');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );
      await api.verifyTwoFactor(_codeController.text);
      
      final codes = await api.getRecoveryCodes();
      setState(() {
        _recoveryCodes = codes;
        _showRecoveryCodes = true;
        _isTwoFactorEnabled = true;
        _qrCodeUrl = null;
        _secret = null;
        _otpAuthUrl = null;
        _codeController.clear();
      });
      if (!mounted) return;
      ToastWidget.showSuccess(context, '双因素认证已启用');
    } catch (e) {
      if (mounted) {
        ToastWidget.showError(context, '验证失败: ${e.toString()}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disableTwoFactor() async {
    final password = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '确认禁用',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '请输入您的密码以确认禁用双因素认证',
                style: TextStyle(color: AppTheme.textTertiary),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: '密码',
                  labelStyle: const TextStyle(color: AppTheme.textTertiary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.techPurple, width: 2),
                  ),
                  filled: true,
                  fillColor: AppTheme.spaceBlue,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onSubmitted: (value) => Navigator.pop(context, value),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.spaceIndigo,
                        foregroundColor: AppTheme.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeonButton(
                      text: '确认',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (password == null || password.isEmpty) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );
      await api.disableTwoFactor(password);
      if (!mounted) return;
      setState(() {
        _isTwoFactorEnabled = false;
        _showRecoveryCodes = false;
        _recoveryCodes = [];
      });
      ToastWidget.showSuccess(context, '双因素认证已禁用');
    } catch (e) {
      if (mounted) {
        ToastWidget.showError(context, '禁用失败: ${e.toString()}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _copyRecoveryCodes() async {
    final codes = _recoveryCodes.join('\n');
    await Clipboard.setData(ClipboardData(text: codes));
    if (!mounted) return;
    ToastWidget.showSuccess(context, '恢复码已复制到剪贴板');
  }

  Future<void> _regenerateRecoveryCodes() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );
      final codes = await api.regenerateRecoveryCodes();
      if (!mounted) return;
      setState(() {
        _recoveryCodes = codes;
      });
      ToastWidget.showSuccess(context, '恢复码已重新生成');
    } catch (e) {
      if (mounted) {
        ToastWidget.showError(context, '生成失败: ${e.toString()}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.spaceBlue,
        title: const Text('双因素认证', style: TextStyle(color: AppTheme.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.techPurple),
              )
            : !_apiAvailable
                ? _buildApiUnavailableSection()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        if (_showRecoveryCodes)
                          _buildRecoveryCodesSection()
                        else if (_otpAuthUrl != null || _secret != null)
                          _buildEnableVerificationSection()
                        else
                          _buildMainSection(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildApiUnavailableSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.spaceIndigo,
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Icon(
                Icons.cloud_off,
                size: 64,
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '服务暂不可用',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '双因素认证功能尚未在服务器端启用',
              style: TextStyle(color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 8),
            Text(
              '错误信息: $_apiError',
              style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            NeonButton(
              text: '重试',
              onPressed: _loadTwoFactorInfo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainSection() {
    return Column(
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isTwoFactorEnabled
                      ? const Color.fromARGB(51, 16, 185, 129)
                      : const Color.fromARGB(51, 203, 213, 224),
                  boxShadow: _isTwoFactorEnabled
                      ? const [
                          BoxShadow(
                            color: Color.fromARGB(77, 16, 185, 129),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  _isTwoFactorEnabled ? Icons.check_circle : Icons.circle,
                  color: _isTwoFactorEnabled
                      ? AppTheme.pulseGreen
                      : AppTheme.textTertiary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isTwoFactorEnabled ? '已启用' : '未启用',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isTwoFactorEnabled
                            ? AppTheme.pulseGreen
                            : AppTheme.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '双因素认证可以提高您账户的安全性',
                      style: TextStyle(color: AppTheme.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.techPurple),
                  SizedBox(width: 8),
                  Text(
                    '什么是双因素认证？',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                '双因素认证（2FA）是一种安全验证方式，除了密码之外，还需要额外的验证步骤才能登录您的账户。这可以有效防止他人在获取您密码后访问您的账户。',
                style: TextStyle(height: 1.6, color: AppTheme.textTertiary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.work, color: AppTheme.neonBlue),
                  SizedBox(width: 8),
                  Text(
                    '工作原理',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. 启用双因素认证后，系统会生成一个二维码',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '2. 使用认证应用（如Google Authenticator）扫描二维码',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '3. 每次登录时，除了密码外还需要输入认证应用生成的6位验证码',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        NeonButton(
          text: _isTwoFactorEnabled ? '禁用双因素认证' : '启用双因素认证',
          onPressed: _isTwoFactorEnabled ? _disableTwoFactor : _enableTwoFactor,
          isLoading: _isEnabling,
        ),
        if (_isTwoFactorEnabled)
          Column(
            children: [
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() => _showRecoveryCodes = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.spaceIndigo,
                  foregroundColor: AppTheme.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                ),
                child: const Text('查看恢复码'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildEnableVerificationSection() {
    final qrData = _otpAuthUrl ?? (_secret != null ? 'otpauth://totp/WhisperPush?secret=$_secret' : '');

    return Column(
      children: [
        const Text(
          '扫描二维码',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '使用认证应用（如Google Authenticator）扫描下方二维码',
          style: TextStyle(color: AppTheme.textTertiary),
        ),
        const SizedBox(height: 24),
        GlassContainer(
          padding: const EdgeInsets.all(24),
          child: qrData.isNotEmpty
              ? QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                  errorStateBuilder: (context, error) => Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppTheme.spaceBlue,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: const Icon(
                      Icons.qr_code,
                      size: 64,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                )
              : const SizedBox(
                  width: 200,
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.techPurple),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                '手动输入密钥（如果无法扫描）',
                style: TextStyle(color: AppTheme.textTertiary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.spaceBlue,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color.fromARGB(77, 139, 92, 246)),
                ),
                child: SelectableText(
                  _secret ?? '',
                  style: const TextStyle(
                    fontFamily: 'Monospace',
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '输入验证码',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GlassContainer(
          padding: const EdgeInsets.all(0),
          child: TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: '6位验证码',
              hintStyle: TextStyle(color: AppTheme.textTertiary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              counterText: '',
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        NeonButton(
          text: '验证并启用',
          onPressed: _verifyTwoFactor,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _qrCodeUrl = null;
              _secret = null;
              _otpAuthUrl = null;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.spaceIndigo,
            foregroundColor: AppTheme.textTertiary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 14,
            ),
          ),
          child: const Text('取消'),
        ),
      ],
    );
  }

  Widget _buildRecoveryCodesSection() {
    return Column(
      children: [
        const Text(
          '恢复码',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(26, 245, 158, 11),
            border: Border.all(color: AppTheme.warningOrange),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '⚠️ 重要：请妥善保存这些恢复码！如果您丢失了认证设备，可以使用这些恢复码来登录您的账户。',
            style: TextStyle(color: AppTheme.warningOrange),
          ),
        ),
        const SizedBox(height: 24),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: _recoveryCodes
                .asMap()
                .entries
                .map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            '${entry.key + 1}.',
                            style: const TextStyle(color: AppTheme.textTertiary),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            entry.value,
                            style: const TextStyle(
                              fontFamily: 'Monospace',
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _copyRecoveryCodes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.spaceIndigo,
                  foregroundColor: AppTheme.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('复制所有'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _regenerateRecoveryCodes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.spaceIndigo,
                  foregroundColor: AppTheme.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('重新生成'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        NeonButton(
          text: '完成',
          onPressed: () {
            setState(() => _showRecoveryCodes = false);
          },
        ),
      ],
    );
  }
}
