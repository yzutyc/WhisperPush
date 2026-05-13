import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_html/flutter_html.dart';

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

  Widget _buildContent() {
    switch (widget.message.contentType.toLowerCase()) {
      case 'markdown':
        return MarkdownBody(data: widget.message.body);
      case 'html':
        return Html(data: widget.message.body);
      default:
        return Text(widget.message.body);
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
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: widget.message.body));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制到剪贴板')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.message.group != null)
              Chip(
                label: Text(widget.message.group!),
                backgroundColor: Colors.grey[200],
              ),
            const SizedBox(height: 8),
            Text(
              widget.message.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(widget.message.formattedDate),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.message.levelColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.message.levelText,
                    style: TextStyle(color: widget.message.levelColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }
}