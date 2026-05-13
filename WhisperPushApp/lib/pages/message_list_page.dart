import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_service.dart';
import '../providers/auth_provider.dart';
import '../models/message.dart';
import 'message_detail_page.dart';
import 'settings_page.dart';

class MessageListPage extends StatefulWidget {
  const MessageListPage({super.key});

  @override
  State<MessageListPage> createState() => _MessageListPageState();
}

class _MessageListPageState extends State<MessageListPage> {
  List<Message> _messages = [];
  bool _isLoading = true;
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );

      final messages = await api.getMessages();
      setState(() => _messages = messages);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _navigateToDetail(Message message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageDetailPage(message: message),
      ),
    ).then((_) => _loadMessages());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _loadMessages,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _messages.isEmpty
                ? const Center(child: Text('暂无消息'))
                : ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return ListTile(
                        leading: message.read
                            ? const Icon(Icons.mark_email_read)
                            : const Icon(Icons.mark_email_unread, color: Colors.blue),
                        title: Text(message.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.body.length > 50
                                  ? '${message.body.substring(0, 50)}...'
                                  : message.body,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                if (message.group != null)
                                  Chip(
                                    label: Text(message.group!),
                                    labelStyle: const TextStyle(fontSize: 10),
                                    padding: const EdgeInsets.all(2),
                                  ),
                                const SizedBox(width: 8),
                                Text(message.formattedTime),
                              ],
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: message.levelColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            message.levelText,
                            style: TextStyle(color: message.levelColor, fontSize: 12),
                          ),
                        ),
                        onTap: () => _navigateToDetail(message),
                      );
                    },
                  ),
      ),
    );
  }
}