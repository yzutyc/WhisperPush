import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_service.dart';
import '../components/empty_state.dart';
import '../components/glass_card.dart';
import '../components/neon_button.dart';
import '../components/toast_widget.dart';
import '../models/device.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';
import '../utils/push_service.dart';

class DeviceManagementPage extends StatefulWidget {
  const DeviceManagementPage({super.key});

  @override
  State<DeviceManagementPage> createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends State<DeviceManagementPage> {
  List<Device> _devices = [];
  bool _isLoading = false;
  final PushService _pushService = PushService();

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );
      _devices = await api.getDevices();
    } catch (e) {
      Logger.e('加载设备列表失败', error: e);
      if (mounted) {
        ToastWidget.showError(context, '加载失败，请检查网络连接');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _registerCurrentDevice() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );
      bool success = await _pushService.registerDevice(api);
      if (success) {
        await _loadDevices();
        if (mounted) {
          ToastWidget.showSuccess(context, '设备注册成功');
        }
      } else {
        if (mounted) {
          ToastWidget.showError(context, '设备注册失败');
        }
      }
    } catch (e) {
      Logger.e('设备注册失败', error: e);
      if (mounted) {
        ToastWidget.showError(context, '注册失败，请检查网络连接');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDevice(int id) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: GlassCard(
          padding: const EdgeInsets.all(28),
          enableHover: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.dangerRed.withValues(alpha: 0.15),
                ),
                child: Icon(Icons.delete, color: AppTheme.dangerRed, size: 28),
              ),
              const SizedBox(height: 20),
              Text(
                '确认删除',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '确定要删除这个设备吗？',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(30, 75, 85, 99),
                        foregroundColor: AppTheme.textSecondary,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppTheme.borderRadius,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: AppTheme.borderColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Text(
                        '取消',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dangerRed,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppTheme.borderRadius,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text(
                        '删除',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );
      await api.deleteDevice(id);

      int? registeredDeviceId = await _pushService.getRegisteredDeviceId();
      if (registeredDeviceId == id) {
        await _pushService.unregisterDevice();
      }

      await _loadDevices();
      if (mounted) {
        ToastWidget.showSuccess(context, '已删除');
      }
    } catch (e) {
      Logger.e('删除设备失败', error: e);
      if (mounted) {
        ToastWidget.showError(context, '删除失败');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDeviceItem(Device device, bool isCurrentDevice) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color.fromARGB(77, 75, 85, 99)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isCurrentDevice
                  ? const Color.fromARGB(30, 6, 182, 212)
                  : const Color.fromARGB(30, 139, 92, 246),
            ),
            child: Icon(
              _getDeviceIcon(device.deviceType),
              color: isCurrentDevice ? AppTheme.neonBlue : AppTheme.techPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      device.deviceName ?? '未知设备',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: isCurrentDevice
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (isCurrentDevice)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.neonBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppTheme.neonBlue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '当前设备',
                          style: TextStyle(
                            color: AppTheme.neonBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      device.deviceTypeDisplayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                    if (device.pushVendor != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.techPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          device.vendorDisplayName,
                          style: TextStyle(
                            color: AppTheme.techPurple,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  device.formattedCreatedAt,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textTertiary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          if (!isCurrentDevice)
            IconButton(
              icon: Icon(Icons.delete, color: AppTheme.dangerRed, size: 20),
              onPressed: () => _deleteDevice(device.id),
            ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'android':
        return Icons.phone_android;
      case 'ios':
        return Icons.phone_iphone;
      case 'web':
        return Icons.web;
      case 'windows':
        return Icons.desktop_windows;
      case 'macos':
        return Icons.laptop_mac;
      case 'linux':
        return Icons.computer;
      default:
        return Icons.devices;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.spaceBlue,
        title: Text('设备管理', style: TextStyle(color: AppTheme.textPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.techPurple),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  GlassCard(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(16),
                    enableHover: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.devices,
                              color: AppTheme.techPurple,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '注册当前设备',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '将此设备添加到您的账户以接收推送通知',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        NeonButton(
                          text: '立即注册',
                          onPressed: _registerCurrentDevice,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: const Color.fromARGB(20, 139, 92, 246),
                            border: Border.all(
                              color: const Color.fromARGB(77, 139, 92, 246),
                            ),
                          ),
                          child: Icon(
                            Icons.devices_other,
                            color: AppTheme.techPurple,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '已注册设备'.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.techPurpleLight,
                            letterSpacing: 2,
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                        Container(
                          height: 1,
                          width: 40,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color.fromARGB(128, 139, 92, 246),
                                Colors.transparent,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GlassCard(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(0),
                    enableHover: false,
                    child: _devices.isEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: const EmptyState(
                              icon: Icons.phone_android,
                              title: '暂无设备',
                              description: '您还没有注册任何设备',
                            ),
                          )
                        : FutureBuilder<int?>(
                            future: _pushService.getRegisteredDeviceId(),
                            builder: (context, snapshot) {
                              int? currentDeviceId = snapshot.data;
                              return Column(
                                children: _devices.map((device) {
                                  bool isCurrentDevice =
                                      device.id == currentDeviceId;
                                  return _buildDeviceItem(
                                    device,
                                    isCurrentDevice,
                                  );
                                }).toList(),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
