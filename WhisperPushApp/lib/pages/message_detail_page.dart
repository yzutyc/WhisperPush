import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '确认删除',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
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
        return MarkdownBody(
          data: widget.message.body,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.6),
            strong: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            em: TextStyle(fontStyle: FontStyle.italic, color: AppTheme.textSecondary),
            h1: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            h2: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            h3: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
            blockquote: TextStyle(
              color: AppTheme.textTertiary,
              fontStyle: FontStyle.italic,
            ),
            code: TextStyle(
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
          style: TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.6),
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
        glowColor = AppTheme.textTertiary;
        label = '未知';
        icon = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: glowColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: glowColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.2),
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
        color: AppTheme.techPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.techPurple.withOpacity(0.3)),
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
                  color: AppTheme.techPurple.withOpacity(0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            widget.message.group!,
            style: TextStyle(
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
        title: const Text('消息详情', style: TextStyle(color: AppTheme.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: AppTheme.textPrimary),
            onPressed: _copyToClipboard,
            tooltip: '复制内容',
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: GlassCard(
                  padding: const EdgeInsets.all(0),
                  enableHover: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppTheme.borderColor.withOpacity(0.5)),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildGroupTag(),
                            if (widget.message.group != null) const SizedBox(width: 12),
                            _buildLevelBadge(),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.message.title,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: widget.message.read
                                        ? AppTheme.textTertiary
                                        : AppTheme.techPurple,
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: widget.message.read
                                        ? []
                                        : [
                                            BoxShadow(
                                              color: const Color.fromARGB(80, 139, 92, 246),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  widget.message.read ? '已读' : '未读',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: widget.message.read
                                        ? AppTheme.textTertiary
                                        : AppTheme.techPurpleLight,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.access_time, size: 14, color: AppTheme.textTertiary),
                                const SizedBox(width: 6),
                                Text(
                                  widget.message.formattedDate,
                                  style: TextStyle(fontSize: 13, color: AppTheme.textTertiary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(60, 30, 41, 59),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: _buildContent(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GlassCard(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(0),
              enableHover: false,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: NeonButton(
                        onPressed: _isMarkingUnread ? null : _markAsUnread,
                        variant: NeonButtonVariant.outline,
                        child: _isMarkingUnread
                            ? const CircularProgressIndicator(color: AppTheme.textPrimary)
                            : const Text('标记未读'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeonButton(
                        onPressed: _shareMessage,
                        variant: NeonButtonVariant.primary,
                        child: const Text('分享'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeonButton(
                        onPressed: _deleteMessage,
                        variant: NeonButtonVariant.danger,
                        child: const Text('删除'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NeonButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final NeonButtonVariant variant;

  const NeonButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = NeonButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;
    List<BoxShadow> boxShadow;

    switch (variant) {
      case NeonButtonVariant.primary:
        backgroundColor = AppTheme.techPurple;
        foregroundColor = Colors.white;
        borderColor = Colors.transparent;
        boxShadow = [
          BoxShadow(
            color: const Color.fromARGB(100, 139, 92, 246),
            blurRadius: 15,
            spreadRadius: 3,
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case NeonButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = AppTheme.textPrimary;
        borderColor = AppTheme.borderColor;
        boxShadow = [];
        break;
      case NeonButtonVariant.danger:
        backgroundColor = AppTheme.dangerRed;
        foregroundColor = Colors.white;
        borderColor = Colors.transparent;
        boxShadow = [
          BoxShadow(
            color: const Color.fromARGB(100, 239, 68, 68),
            blurRadius: 15,
            spreadRadius: 3,
            offset: const Offset(0, 4),
          ),
        ];
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: boxShadow,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: foregroundColor,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: child,
      ),
    );
  }
}

enum NeonButtonVariant {
  primary,
  outline,
  danger,
}