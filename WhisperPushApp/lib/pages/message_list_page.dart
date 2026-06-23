import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_service.dart';
import '../components/empty_state.dart';
import '../components/glass_container.dart';
import '../components/loading_indicator.dart';
import '../components/message_card.dart';
import '../components/search_input.dart';
import '../models/message.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
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

  int _currentSkip = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final _scrollController = ScrollController();
  static const int _pageSize = 20;

  bool _isMultiSelectMode = false;
  List<int> _selectedMessageIds = [];

  String? _filterStatus;
  String? _filterLevel;
  String? _filterGroup;
  List<String> _availableGroups = [];

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _currentSkip = 0;
    });

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

      final response = await api.getMessages(skip: 0, limit: _pageSize);

      if (kDebugMode) {
        print('消息数量: ${response.items.length} / ${response.total}');
        if (response.items.isNotEmpty) {
          print('第一条消息: ${response.items.first.title}');
        }
      }

      setState(() {
        _messages = response.items;
        _currentSkip = response.items.length;
        _hasMore = response.hasMore;
        _availableGroups = _extractGroups(_messages);
        _applyFilters();
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('加载消息失败: $e');
        print('堆栈: $stackTrace');
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载失败: ${e.toString()}')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );

      final response = await api.getMessages(skip: _currentSkip, limit: _pageSize);

      setState(() {
        _messages.addAll(response.items);
        _currentSkip += response.items.length;
        _hasMore = response.hasMore;
        _availableGroups = _extractGroups(_messages);
        _applyFilters();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载更多失败: ${e.toString()}')));
      }
    } finally {
      setState(() => _isLoadingMore = false);
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

  void _onSearchChanged(String query) {
    _applyFilters();
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
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已标记 ${_selectedMessageIds.length} 条消息为已读')),
      );
      _exitMultiSelectMode();
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败: ${e.toString()}')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedMessageIds.isEmpty) return;

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.spaceIndigo,
            title: Text('确认删除', style: TextStyle(color: AppTheme.textPrimary)),
            content: Text(
              '确定要删除选中的 ${_selectedMessageIds.length} 条消息吗？',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  '取消',
                  style: TextStyle(color: AppTheme.textTertiary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('删除', style: TextStyle(color: AppTheme.dangerRed)),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted) return;
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
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 ${_selectedMessageIds.length} 条消息')),
      );
      _exitMultiSelectMode();
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除失败: ${e.toString()}')));
      }
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已标记为未读')));
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败: ${e.toString()}')));
      }
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已删除消息')));
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除失败: ${e.toString()}')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.spaceBlue,
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
            Text(
              '筛选消息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            GlassContainer(
              padding: const EdgeInsets.all(0),
              child: DropdownButtonFormField<String>(
                initialValue: _filterStatus,
                hint: Text(
                  '状态',
                  style: TextStyle(color: AppTheme.textTertiary),
                ),
                dropdownColor: AppTheme.spaceIndigo,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('全部')),
                  DropdownMenuItem(value: 'unread', child: Text('未读')),
                  DropdownMenuItem(value: 'read', child: Text('已读')),
                ],
                onChanged: (value) {
                  setState(() => _filterStatus = value);
                  _applyFilters();
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            ),
            const SizedBox(height: 16),

            GlassContainer(
              padding: const EdgeInsets.all(0),
              child: DropdownButtonFormField<String>(
                initialValue: _filterLevel,
                hint: Text(
                  '级别',
                  style: TextStyle(color: AppTheme.textTertiary),
                ),
                dropdownColor: AppTheme.spaceIndigo,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('全部')),
                  DropdownMenuItem(value: 'critical', child: Text('紧急')),
                  DropdownMenuItem(value: 'timeSensitive', child: Text('加急')),
                  DropdownMenuItem(value: 'active', child: Text('普通')),
                ],
                onChanged: (value) {
                  setState(() => _filterLevel = value);
                  _applyFilters();
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            ),
            const SizedBox(height: 16),

            GlassContainer(
              padding: const EdgeInsets.all(0),
              child: DropdownButtonFormField<String>(
                initialValue: _filterGroup,
                hint: Text(
                  '分组',
                  style: TextStyle(color: AppTheme.textTertiary),
                ),
                dropdownColor: AppTheme.spaceIndigo,
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('全部')),
                  ..._availableGroups.map(
                    (group) =>
                        DropdownMenuItem(value: group, child: Text(group)),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _filterGroup = value);
                  _applyFilters();
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(color: AppTheme.textPrimary),
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
                      backgroundColor: AppTheme.spaceIndigo,
                      foregroundColor: AppTheme.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: AppTheme.borderColor),
                    ),
                    child: const Text('重置'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.techPurple,
                      foregroundColor: Colors.white,
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
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreMessages();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.spaceBlue,
        title: _isMultiSelectMode
            ? Text(
                '已选择 ${_selectedMessageIds.length} 条',
                style: TextStyle(color: AppTheme.textPrimary),
              )
            : Text('消息', style: TextStyle(color: AppTheme.textPrimary)),
        leading: _isMultiSelectMode
            ? IconButton(
                icon: Icon(Icons.close, color: AppTheme.textPrimary),
                onPressed: _exitMultiSelectMode,
              )
            : null,
        actions: [
          if (_isMultiSelectMode)
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.mark_email_read,
                    color: AppTheme.textPrimary,
                  ),
                  onPressed: _markSelectedAsRead,
                  tooltip: '标记为已读',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: AppTheme.dangerRed),
                  onPressed: _deleteSelected,
                  tooltip: '删除',
                ),
              ],
            )
          else
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.filter_alt, color: AppTheme.textPrimary),
                  onPressed: _showFilterDialog,
                  tooltip: '筛选',
                ),
                IconButton(
                  icon: Icon(Icons.settings, color: AppTheme.textPrimary),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                  tooltip: '设置',
                ),
              ],
            ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _loadMessages,
          backgroundColor: AppTheme.spaceIndigo,
          color: AppTheme.techPurple,
          child: _isLoading
              ? const LoadingIndicator(text: '加载中...')
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SearchInput(
                        controller: _searchController,
                        hintText: '搜索消息...',
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    Expanded(
                      child: _filteredMessages.isEmpty
                          ? EmptyState(
                              icon: _searchController.text.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.inbox,
                              title: _searchController.text.isNotEmpty
                                  ? '暂无匹配结果'
                                  : '暂无消息',
                              description: _searchController.text.isNotEmpty
                                  ? '尝试使用其他关键词搜索'
                                  : '消息会显示在这里',
                              actionText: '刷新',
                              onAction: _loadMessages,
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount: _filteredMessages.length + (_isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _filteredMessages.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final message = _filteredMessages[index];
                                return MessageCard(
                                  message: message,
                                  isSelected: _selectedMessageIds.contains(
                                    message.id,
                                  ),
                                  isMultiSelectMode: _isMultiSelectMode,
                                  onTap: () => _navigateToDetail(message),
                                  onLongPress: () =>
                                      _enterMultiSelectMode(message.id),
                                  onSelectChanged: (selected) {
                                    _toggleSelect(message.id);
                                  },
                                  onDismissed: () => _deleteMessage(message.id),
                                  onMarkToggle: () =>
                                      _markMessageAsUnread(message),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
