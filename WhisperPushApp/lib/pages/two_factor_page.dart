import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../api/api_service.dart';
import '../providers/auth_provider.dart';
import '../components/custom_button.dart';
import '../components/toast_widget.dart';

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
        _qrCodeUrl = result['qr_code_url'];
        _secret = result['secret'];
      });
    } catch (e) {
      ToastWidget.showError(context, '启用失败: ${e.toString()}');
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
        _codeController.clear();
      });
      ToastWidget.showSuccess(context, '双因素认证已启用');
    } catch (e) {
      ToastWidget.showError(context, '验证失败: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disableTwoFactor() async {
    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认禁用'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入您的密码以确认禁用双因素认证'),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (password == null || password.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );
      await api.disableTwoFactor(password);
      setState(() {
        _isTwoFactorEnabled = false;
        _showRecoveryCodes = false;
        _recoveryCodes = [];
      });
      ToastWidget.showSuccess(context, '双因素认证已禁用');
    } catch (e) {
      ToastWidget.showError(context, '禁用失败: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _copyRecoveryCodes() async {
    final codes = _recoveryCodes.join('\n');
    await Clipboard.setData(ClipboardData(text: codes));
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
      setState(() {
        _recoveryCodes = codes;
      });
      ToastWidget.showSuccess(context, '恢复码已重新生成');
    } catch (e) {
      ToastWidget.showError(context, '生成失败: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('双因素认证'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_apiAvailable
              ? _buildApiUnavailableSection()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      if (_showRecoveryCodes)
                        _buildRecoveryCodesSection()
                      else if (_qrCodeUrl != null)
                        _buildEnableVerificationSection()
                      else
                        _buildMainSection(),
                    ],
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
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.cloud_off,
                size: 64,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '服务暂不可用',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '双因素认证功能尚未在服务器端启用',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              '错误信息: $_apiError',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadTwoFactorInfo,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isTwoFactorEnabled ? Colors.green[50] : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isTwoFactorEnabled ? Colors.green : Colors.grey,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isTwoFactorEnabled ? Icons.check_circle : Icons.circle,
                color: _isTwoFactorEnabled ? Colors.green : Colors.grey,
                size: 32,
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
                        color: _isTwoFactorEnabled ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '双因素认证可以提高您账户的安全性',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '什么是双因素认证？',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          '双因素认证（2FA）是一种安全验证方式，除了密码之外，还需要额外的验证步骤才能登录您的账户。这可以有效防止他人在获取您密码后访问您的账户。',
          style: TextStyle(height: 1.6, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        const Text(
          '工作原理',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('1. 启用双因素认证后，系统会生成一个二维码'),
            SizedBox(height: 8),
            Text('2. 使用认证应用（如Google Authenticator）扫描二维码'),
            SizedBox(height: 8),
            Text('3. 每次登录时，除了密码外还需要输入认证应用生成的6位验证码'),
          ],
        ),
        const SizedBox(height: 32),
        CustomButton(
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
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.black,
                ),
                child: const Text('查看恢复码'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildEnableVerificationSection() {
    return Column(
      children: [
        const Text(
          '扫描二维码',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          '使用认证应用（如Google Authenticator）扫描下方二维码',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: _qrCodeUrl != null
              ? Image.network(
                  _qrCodeUrl!,
                  width: 200,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 200,
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.qr_code, size: 64, color: Colors.grey),
                  ),
                )
              : const SizedBox(
                  width: 200,
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const Text('手动输入密钥（如果无法扫描）'),
              const SizedBox(height: 8),
              SelectableText(
                _secret ?? '',
                style: const TextStyle(fontFamily: 'Monospace', fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '输入验证码',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: '6位验证码',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: '验证并启用',
          onPressed: _verifyTwoFactor,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _qrCodeUrl = null;
              _secret = null;
            });
          },
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
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            border: Border.all(color: Colors.amber),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '⚠️ 重要：请妥善保存这些恢复码！如果您丢失了认证设备，可以使用这些恢复码来登录您的账户。',
            style: TextStyle(color: Colors.amber[800]),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: _recoveryCodes
                .asMap()
                .entries
                .map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            '${entry.key + 1}.',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            entry.value,
                            style: const TextStyle(fontFamily: 'Monospace'),
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
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.black,
                ),
                child: const Text('复制所有'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _regenerateRecoveryCodes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.black,
                ),
                child: const Text('重新生成'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: '完成',
          onPressed: () {
            setState(() => _showRecoveryCodes = false);
          },
        ),
      ],
    );
  }
}