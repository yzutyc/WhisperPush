import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_service.dart';
import '../providers/auth_provider.dart';
import '../models/secret.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<Secret> _secrets = [];
  bool _isLoading = false;
  final _serverUrlController = TextEditingController();
  final _secretNameController = TextEditingController();

  Future<void> _loadSecrets() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );

      final secrets = await api.getSecrets();
      setState(() => _secrets = secrets);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createSecret() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );

      final secret = await api.createSecret(name: _secretNameController.text.isNotEmpty ? _secretNameController.text : null);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Secret 创建成功')),
        );
        _secretNameController.clear();
        await _loadSecrets();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建失败: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSecret(int id) async {
    if (!await _confirmDelete()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );

      await api.deleteSecret(id);
      await _loadSecrets();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _confirmDelete() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个 Secret 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _saveServerUrl() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.saveServerUrl(_serverUrlController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('服务器地址已保存')),
    );
  }

  Future<void> _logout() async {
    if (!await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('退出'),
          ),
        ],
      ),
    )) return;

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
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _serverUrlController.text = authProvider.serverUrl ?? '';
    _loadSecrets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('服务器配置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _serverUrlController,
            decoration: const InputDecoration(
              labelText: '服务器地址',
              prefixIcon: Icon(Icons.cloud),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _saveServerUrl,
            child: const Text('保存服务器地址'),
          ),
          const SizedBox(height: 24),
          const Text('Secret 管理', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _secretNameController,
                  decoration: const InputDecoration(
                    labelText: 'Secret 名称（可选）',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _createSecret,
                child: const Text('新建'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _secrets.isEmpty
                  ? const Center(child: Text('暂无 Secret'))
                  : Column(
                      children: _secrets.map((secret) {
                        return ListTile(
                          title: Text(secret.displayName),
                          subtitle: Text(secret.formattedCreatedAt),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteSecret(secret.id),
                          ),
                        );
                      }).toList(),
                    ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('退出登录'),
          ),
        ],
      ),
    );
  }
}