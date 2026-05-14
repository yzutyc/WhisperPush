import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:share_plus/share_plus.dart';

import '../api/api_service.dart';
import '../providers/auth_provider.dart';
import '../models/message.dart';

class MessageDetailPage extends StatefulWidget {
  final Message message;

  const MessageDetailPage({super.key, required this.message});

  @override
  State<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends State<MessageDetailPage> {
  bool _isMarkingRead = false;
  bool _isMarkingUnread = false;

  Future<void> _markAsRead() async {
    if (widget.message.read) return;

    setState(() => _isMarkingRead = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );

      await api.markMessageRead(widget.message.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('标记失败: ${e.toString()}')),
      );
    } finally {
      setState(() => _isMarkingRead = false);
    }
  }

  Future<void> _markAsUnread() async {
    setState(() => _isMarkingUnread = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );

      await api.markMessageUnread(widget.message.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已标记为未读')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('标记失败: ${e.toString()}')),
      );
    } finally {
      setState(() => _isMarkingUnread = false);
    }
  }

  Future<void> _deleteMessage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条消息吗？'),
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

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );

      await api.deleteMessage(widget.message.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除消息')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: ${e.toString()}')),
      );
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.message.body));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }

  Future<void> _shareMessage() async {
    await Share.share('${widget.message.title}\n\n${widget.message.body}');
  }

  Widget _buildContent() {
    switch (widget.message.contentType.toLowerCase()) {
      case 'markdown':
        return MarkdownBody(data: widget.message.body);
      case 'html':
        return Html(data: widget.message.body);
      default:
        return Text(
          widget.message.body,
          style: const TextStyle(fontSize: 16, height: 1.6),
        );
    }
  }

  @override
  void initState() {
    super.initState();
    if (!widget.message.read) {
      _markAsRead();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyToClipboard,
            tooltip: '复制内容',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (widget.message.group != null)
                        Chip(
                          label: Text(widget.message.group!),
                          backgroundColor: Colors.grey[100],
                          labelStyle: const TextStyle(fontSize: 12),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.message.levelColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.message.levelText,
                          style: TextStyle(
                            color: widget.message.levelColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.message.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        widget.message.formattedDate,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.mark_email_read, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        widget.message.read ? '已读' : '未读',
                        style: TextStyle(
                          color: widget.message.read ? Colors.grey : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[100]!),
                    ),
                    child: _buildContent(),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[100]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isMarkingUnread ? null : _markAsUnread,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isMarkingUnread
                        ? const CircularProgressIndicator(color: Colors.black87)
                        : const Text('标记未读'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _shareMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('分享'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _deleteMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('删除'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}