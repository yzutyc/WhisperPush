import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_service.dart';
import '../providers/auth_provider.dart';
import '../models/message.dart';
import '../components/message_card.dart';
import '../components/loading_indicator.dart';
import 'message_detail_page.dart';
import 'settings_page.dart';

class MessageListPage extends StatefulWidget {
  const MessageListPage({super.key});

  @override
  State<MessageListPage> createState() => _MessageListPageState();
}

class _MessageListPageState extends State<MessageListPage> {
  List<Message> _messages = [];
  List<Message> _filteredMessages = [];
  bool _isLoading = true;
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final _searchController = TextEditingController();
  
  bool _isMultiSelectMode = false;
  List<int> _selectedMessageIds = [];
  
  String? _filterStatus;
  String? _filterLevel;
  String? _filterGroup;
  List<String> _availableGroups = [];

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.serverUrl == null || authProvider.serverUrl!.isEmpty) {
        throw Exception('服务器地址未配置');
      }
      
      if (kDebugMode) {
        print('=== 加载消息 ===');
        print('Server URL: ${authProvider.serverUrl}');
        print('Token: ${authProvider.token?.substring(0, 20) ?? 'null'}...');
      }
      
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );

      final messages = await api.getMessages();
      
      if (kDebugMode) {
        print('消息数量: ${messages.length}');
        if (messages.isNotEmpty) {
          print('第一条消息: ${messages.first.title}');
        }
      }
      
      setState(() {
        _messages = messages;
        _availableGroups = _extractGroups(messages);
        _applyFilters();
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('加载消息失败: $e');
        print('堆栈: $stackTrace');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<String> _extractGroups(List<Message> messages) {
    final groups = <String>{};
    for (var msg in messages) {
      if (msg.group != null && msg.group!.isNotEmpty) {
        groups.add(msg.group!);
      }
    }
    return groups.toList();
  }

  void _applyFilters() {
    setState(() {
      _filteredMessages = _messages.where((msg) {
        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          if (!msg.title.toLowerCase().contains(query) && 
              !msg.body.toLowerCase().contains(query)) {
            return false;
          }
        }
        if (_filterStatus != null && _filterStatus != 'all') {
          if (_filterStatus == 'unread' && msg.read) return false;
          if (_filterStatus == 'read' && !msg.read) return false;
        }
        if (_filterLevel != null && _filterLevel != 'all') {
          if (msg.level != _filterLevel) return false;
        }
        if (_filterGroup != null && _filterGroup != 'all') {
          if (msg.group != _filterGroup) return false;
        }
        return true;
      }).toList();
    });
  }

  void _navigateToDetail(Message message) {
    if (_isMultiSelectMode) {
      _toggleSelect(message.id);
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageDetailPage(message: message),
      ),
    ).then((_) => _loadMessages());
  }

  void _toggleSelect(int messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
      } else {
        _selectedMessageIds.add(messageId);
      }
      if (_selectedMessageIds.isEmpty) {
        _isMultiSelectMode = false;
      }
    });
  }

  void _enterMultiSelectMode(int messageId) {
    setState(() {
      _isMultiSelectMode = true;
      _selectedMessageIds = [messageId];
    });
  }

  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedMessageIds = [];
    });
  }

  Future<void> _markSelectedAsRead() async {
    if (_selectedMessageIds.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );
      
      for (var id in _selectedMessageIds) {
        await api.markMessageRead(id);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已标记 ${_selectedMessageIds.length} 条消息为已读')),
      );
      _exitMultiSelectMode();
      await _loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedMessageIds.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedMessageIds.length} 条消息吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirmed) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );
      
      for (var id in _selectedMessageIds) {
        await api.deleteMessage(id);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 ${_selectedMessageIds.length} 条消息')),
      );
      _exitMultiSelectMode();
      await _loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markMessageAsUnread(Message message) async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );
      
      await api.markMessageUnread(message.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已标记为未读')),
      );
      await _loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMessage(int messageId) async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );
      
      await api.deleteMessage(messageId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已删除消息')),
      );
      await _loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '筛选消息',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            DropdownButtonFormField<String>(
              value: _filterStatus,
              hint: const Text('状态'),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('全部')),
                const DropdownMenuItem(value: 'unread', child: Text('未读')),
                const DropdownMenuItem(value: 'read', child: Text('已读')),
              ],
              onChanged: (value) {
                setState(() => _filterStatus = value);
                _applyFilters();
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _filterLevel,
              hint: const Text('级别'),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('全部')),
                const DropdownMenuItem(value: 'critical', child: Text('紧急')),
                const DropdownMenuItem(value: 'timeSensitive', child: Text('时间敏感')),
                const DropdownMenuItem(value: 'active', child: Text('普通')),
              ],
              onChanged: (value) {
                setState(() => _filterLevel = value);
                _applyFilters();
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _filterGroup,
              hint: const Text('分组'),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('全部')),
                ..._availableGroups.map((group) => 
                  DropdownMenuItem(value: group, child: Text(group))
                ),
              ],
              onChanged: (value) {
                setState(() => _filterGroup = value);
                _applyFilters();
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _filterStatus = null;
                        _filterLevel = null;
                        _filterGroup = null;
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('重置'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('确定'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isMultiSelectMode
            ? Text('已选择 ${_selectedMessageIds.length} 条')
            : const Text('消息'),
        leading: _isMultiSelectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitMultiSelectMode,
              )
            : null,
        actions: [
          if (_isMultiSelectMode)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.mark_email_read),
                  onPressed: _markSelectedAsRead,
                  tooltip: '标记为已读',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _deleteSelected,
                  tooltip: '删除',
                ),
              ],
            )
          else
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_alt),
                  onPressed: _showFilterDialog,
                  tooltip: '筛选',
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsPage()),
                    );
                  },
                  tooltip: '设置',
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _loadMessages,
        child: _isLoading
            ? const LoadingIndicator(text: '加载中...')
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: '搜索消息...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _filteredMessages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  '暂无匹配结果',
                                  style: TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchController.text.isNotEmpty 
                                      ? '尝试使用其他关键词搜索' 
                                      : '消息会显示在这里',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _loadMessages,
                                  child: const Text('刷新'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredMessages.length,
                            itemBuilder: (context, index) {
                              final message = _filteredMessages[index];
                              return MessageCard(
                                message: message,
                                isSelected: _selectedMessageIds.contains(message.id),
                                isMultiSelectMode: _isMultiSelectMode,
                                onTap: () => _navigateToDetail(message),
                                onLongPress: () => _enterMultiSelectMode(message.id),
                                onSelectChanged: (selected) {
                                  _toggleSelect(message.id);
                                },
                                onDismissed: () => _deleteMessage(message.id),
                                onMarkToggle: () => _markMessageAsUnread(message),
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