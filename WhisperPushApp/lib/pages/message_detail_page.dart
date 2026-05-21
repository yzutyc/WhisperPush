// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_service.dart';
import '../components/glass_card.dart';
import '../components/glass_container.dart';
import '../models/message.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('标记失败: ${e.toString()}')));
      }
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已标记为未读')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('标记失败: ${e.toString()}')));
      }
    } finally {
      setState(() => _isMarkingUnread = false);
    }
  }

  Future<void> _deleteMessage() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '确认删除',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '确定要删除这条消息吗？',
                    style: TextStyle(color: AppTheme.textTertiary),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, false),
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
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.dangerRed,
                            foregroundColor: Colors.white,
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
                ],
              ),
            ),
          ),
        ) ??
        false;

    if (!mounted) return;
    if (!confirmed) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = ApiService(
        baseUrl: authProvider.serverUrl!,
        token: authProvider.token,
      );

      await api.deleteMessage(widget.message.id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已删除消息')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除失败: ${e.toString()}')));
      }
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.message.body));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已复制到剪贴板')));
  }

  Future<void> _shareMessage() async {
    await Share.share('${widget.message.title}\n\n${widget.message.body}');
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('无法打开链接: $url')));
      }
    }
  }

  Widget _buildContent() {
    switch (widget.message.contentType.toLowerCase()) {
      case 'markdown':
        return MarkdownBody(
          data: widget.message.body,
          onTapLink: (text, href, title) {
            if (href != null) {
              _launchUrl(href);
            }
          },
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
            strong: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            em: const TextStyle(
              fontStyle: FontStyle.italic,
              color: AppTheme.textSecondary,
            ),
            h1: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            h2: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            h3: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
            blockquote: const TextStyle(
              color: AppTheme.textTertiary,
              fontStyle: FontStyle.italic,
            ),
            code: const TextStyle(
              backgroundColor: AppTheme.spaceBlue,
              color: AppTheme.neonBlue,
              fontFamily: 'Monospace',
            ),
            codeblockDecoration: BoxDecoration(
              color: AppTheme.spaceBlue,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      case 'html':
        return Html(
          data: widget.message.body,
          onLinkTap: (url, attributes, element) {
            if (url != null) {
              _launchUrl(url);
            }
          },
          style: {
            'body': Style(
              fontSize: FontSize(15),
              color: AppTheme.textSecondary,
              margin: Margins.zero,
              padding: HtmlPaddings.zero,
            ),
            'p': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
            'strong': Style(color: AppTheme.textPrimary),
            'h1': Style(
              fontSize: FontSize(24),
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            'h2': Style(
              fontSize: FontSize(20),
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            'code': Style(
              backgroundColor: AppTheme.spaceBlue,
              color: AppTheme.neonBlue,
            ),
          },
        );
      default:
        return Text(
          widget.message.body,
          style: const TextStyle(
            fontSize: 15,
            color: AppTheme.textSecondary,
            height: 1.6,
          ),
        );
    }
  }

  Widget _buildLevelBadge() {
    Color glowColor;
    String label;
    IconData? icon;

    switch (widget.message.level) {
      case 'critical':
        glowColor = AppTheme.dangerRed;
        label = '紧急';
        icon = Icons.warning;
        break;
      case 'timeSensitive':
        glowColor = AppTheme.warningOrange;
        label = '加急';
        icon = Icons.timer;
        break;
      case 'active':
        glowColor = AppTheme.pulseGreen;
        label = '普通';
        icon = Icons.check_circle;
        break;
      default:
        glowColor = AppTheme.pulseGreen;
        label = '普通';
        icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: glowColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: glowColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 12, color: glowColor),
          if (icon != null) const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: glowColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTag() {
    if (widget.message.group == null || widget.message.group!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.techPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.techPurple.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.techPurple,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.techPurple.withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            widget.message.group!,
            style: const TextStyle(
              color: AppTheme.techPurple,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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
        backgroundColor: AppTheme.spaceBlue,
        title: const Text(
          '消息详情',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: AppTheme.textPrimary),
            onPressed: _copyToClipboard,
            tooltip: '复制内容',
          ),
          IconButton(
            icon: const Icon(
              Icons.mark_email_unread,
              color: AppTheme.textPrimary,
            ),
            onPressed: _isMarkingUnread ? null : _markAsUnread,
            tooltip: '标记未读',
          ),
          IconButton(
            icon: const Icon(Icons.share, color: AppTheme.textPrimary),
            onPressed: _shareMessage,
            tooltip: '分享',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppTheme.dangerRed),
            onPressed: _deleteMessage,
            tooltip: '删除',
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: GlassCard(
                  padding: const EdgeInsets.all(0),
                  enableHover: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Text(
                          widget.message.title,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            _buildGroupTag(),
                            if (widget.message.group != null)
                              const SizedBox(width: 12),
                            _buildLevelBadge(),
                            const Spacer(),
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppTheme.textTertiary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.message.formattedDate,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        height: 1,
                        color: AppTheme.borderColor.withValues(alpha: 0.5),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: _buildContent(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
