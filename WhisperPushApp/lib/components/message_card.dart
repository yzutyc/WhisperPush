import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/message.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class MessageCard extends StatelessWidget {
  final Message message;
  final bool isSelected;
  final bool isMultiSelectMode;
  final Function() onTap;
  final Function() onLongPress;
  final Function(bool?) onSelectChanged;
  final Function()? onDismissed;
  final Function()? onMarkToggle;

  const MessageCard({
    super.key,
    required this.message,
    this.isSelected = false,
    this.isMultiSelectMode = false,
    required this.onTap,
    required this.onLongPress,
    required this.onSelectChanged,
    this.onDismissed,
    this.onMarkToggle,
  });

  Widget _buildLevelBadge() {
    Color glowColor;
    Color borderColor;
    String label;
    IconData? icon;

    switch (message.level) {
      case 'critical':
        glowColor = AppTheme.dangerRed;
        borderColor = const Color.fromARGB(100, 239, 68, 68);
        label = '紧急';
        icon = Icons.warning;
        break;
      case 'timeSensitive':
        glowColor = AppTheme.warningOrange;
        borderColor = const Color.fromARGB(100, 245, 158, 11);
        label = '加急';
        icon = Icons.timer;
        break;
      case 'active':
        glowColor = AppTheme.pulseGreen;
        borderColor = const Color.fromARGB(100, 16, 185, 129);
        label = '普通';
        icon = Icons.check_circle;
        break;
      default:
        glowColor = AppTheme.textTertiary;
        borderColor = const Color.fromARGB(100, 209, 213, 219);
        label = '未知';
        icon = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color.fromARGB(20, glowColor.red, glowColor.green, glowColor.blue),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(30, glowColor.red, glowColor.green, glowColor.blue),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 12, color: glowColor),
          if (icon != null)
            const SizedBox(width: 4),
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
    if (message.group == null || message.group!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color.fromARGB(20, 139, 92, 246),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color.fromARGB(60, 139, 92, 246)),
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
                  color: const Color.fromARGB(100, 139, 92, 246),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            message.group!,
            style: TextStyle(
              color: AppTheme.techPurpleLight,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadStatus() {
    return message.read
        ? Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.textDisabled,
              borderRadius: BorderRadius.circular(4),
            ),
          )
        : _UnreadIndicator();
  }

  Widget _buildContentPreview() {
    String preview = message.body;
    
    if (preview.length > 100) {
      preview = '${preview.substring(0, 100)}...';
    }

    switch (message.contentType.toLowerCase()) {
      case 'markdown':
        return MarkdownBody(
          data: preview,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(fontSize: 14, color: AppTheme.textTertiary),
            strong: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
            em: TextStyle(fontStyle: FontStyle.italic, color: AppTheme.textTertiary),
          ),
        );
      case 'html':
        return Html(
          data: preview,
          style: {
            'body': Style(
              fontSize: FontSize(14),
              color: AppTheme.textTertiary,
              margin: Margins.zero,
              padding: HtmlPaddings.zero,
            ),
            'p': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
            'strong': Style(color: AppTheme.textSecondary),
          },
        );
      default:
        return Text(
          preview,
          style: TextStyle(fontSize: 14, color: AppTheme.textTertiary, height: 1.5),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('message-${message.id}'),
      direction: onDismissed != null || onMarkToggle != null 
          ? DismissDirection.horizontal 
          : DismissDirection.none,
      background: onDismissed != null
          ? Container(
              decoration: BoxDecoration(
                color: AppTheme.dangerRed,
                borderRadius: AppTheme.borderRadius,
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 24),
              child: const Icon(Icons.delete, color: Colors.white, size: 28),
            )
          : const SizedBox(),
      secondaryBackground: onMarkToggle != null
          ? Container(
              decoration: BoxDecoration(
                color: AppTheme.pulseGreen,
                borderRadius: AppTheme.borderRadius,
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: Icon(
                message.read ? Icons.mark_email_unread : Icons.mark_email_read,
                color: Colors.white,
                size: 28,
              ),
            )
          : const SizedBox(),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd && onDismissed != null) {
          onDismissed!();
        } else if (direction == DismissDirection.endToStart && onMarkToggle != null) {
          onMarkToggle!();
        }
      },
      child: GlassCard(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(0),
        onTap: () {
          if (isMultiSelectMode) {
            onSelectChanged(!isSelected);
          } else {
            onTap();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: AppTheme.borderRadius,
            border: isSelected
                ? Border.all(color: AppTheme.techPurple, width: 2)
                : message.read
                    ? Border.all(color: Colors.transparent)
                    : Border(
                        left: BorderSide(color: AppTheme.techPurple, width: 4),
                      ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isMultiSelectMode)
                    Checkbox(
                      value: isSelected,
                      onChanged: onSelectChanged,
                      activeColor: AppTheme.techPurple,
                      checkColor: Colors.white,
                    ),
                  _buildReadStatus(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message.title,
                      style: TextStyle(
                        fontWeight: message.read ? FontWeight.normal : FontWeight.bold,
                        fontSize: 16,
                        color: message.read ? AppTheme.textSecondary : AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildLevelBadge(),
                ],
              ),
              const SizedBox(height: 12),
              _buildContentPreview(),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildGroupTag(),
                  const Spacer(),
                  Text(
                    message.formattedTime,
                    style: TextStyle(fontSize: 12, color: AppTheme.textDisabled),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnreadIndicator extends StatefulWidget {
  @override
  State<_UnreadIndicator> createState() => _UnreadIndicatorState();
}

class _UnreadIndicatorState extends State<_UnreadIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const SawTooth(2),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppTheme.techPurple,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(100, 139, 92, 246),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}