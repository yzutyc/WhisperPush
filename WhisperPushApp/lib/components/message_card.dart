import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
        borderColor = const Color.fromARGB(120, 239, 68, 68);
        label = '紧急';
        icon = Icons.warning;
        break;
      case 'timeSensitive':
        glowColor = AppTheme.warningOrange;
        borderColor = const Color.fromARGB(120, 245, 158, 11);
        label = '加急';
        icon = Icons.timer;
        break;
      case 'active':
        glowColor = AppTheme.pulseGreen;
        borderColor = const Color.fromARGB(120, 16, 185, 129);
        label = '普通';
        icon = Icons.check_circle;
        break;
      default:
        glowColor = AppTheme.textTertiary;
        borderColor = const Color.fromARGB(80, 209, 213, 219);
        label = '未知';
        icon = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: glowColor.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: glowColor.withAlpha(40),
            blurRadius: 10,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 13, color: glowColor),
          if (icon != null)
            const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: glowColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color.fromARGB(25, 139, 92, 246),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color.fromARGB(80, 139, 92, 246)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(30, 139, 92, 246),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: AppTheme.techPurple,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromARGB(120, 139, 92, 246),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
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
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppTheme.textDisabled,
              borderRadius: BorderRadius.circular(5),
            ),
          )
        : const _UnreadIndicator();
  }

  Widget _buildContentPreview() {
    String preview = message.body;
    
    if (preview.length > 120) {
      preview = '${preview.substring(0, 120)}...';
    }

    switch (message.contentType.toLowerCase()) {
      case 'markdown':
        return MarkdownBody(
          data: preview,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(fontSize: 14, color: AppTheme.textTertiary, height: 1.5),
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
              decoration: const BoxDecoration(
                color: Color.fromARGB(220, 239, 68, 68),
                borderRadius: AppTheme.borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(60, 239, 68, 68),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 24),
              child: const Icon(Icons.delete, color: Colors.white, size: 30),
            )
          : const SizedBox(),
      secondaryBackground: onMarkToggle != null
          ? Container(
              decoration: const BoxDecoration(
                color: Color.fromARGB(220, 16, 185, 129),
                borderRadius: AppTheme.borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(60, 16, 185, 129),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: Icon(
                message.read ? Icons.mark_email_unread : Icons.mark_email_read,
                color: Colors.white,
                size: 30,
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
        enableGlow: !message.read || isSelected,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: AppTheme.borderRadius,
            border: isSelected
                ? Border.all(color: AppTheme.techPurple, width: 2.5)
                : Border.all(color: Colors.transparent),
            boxShadow: !message.read && !isSelected
                ? [
                    const BoxShadow(
                      color: Color.fromARGB(30, 139, 92, 246),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isMultiSelectMode)
                    AnimatedScale(
                      scale: isSelected ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: onSelectChanged,
                        activeColor: AppTheme.techPurple,
                        checkColor: Colors.white,
                        side: BorderSide(
                          color: isSelected ? AppTheme.techPurple : AppTheme.textDisabled,
                          width: 2,
                        ),
                      ),
                    ),
                  SizedBox(width: isMultiSelectMode ? 12 : 0),
                  Expanded(
                    child: Text(
                      message.title,
                      style: TextStyle(
                        fontWeight: message.read ? FontWeight.normal : FontWeight.bold,
                        fontSize: 20,
                        color: message.read ? AppTheme.textSecondary : AppTheme.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildContentPreview(),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildGroupTag(),
                  if (message.group != null) const SizedBox(width: 8),
                  _buildLevelBadge(),
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
  const _UnreadIndicator();

  @override
  State<_UnreadIndicator> createState() => _UnreadIndicatorState();
}

class _UnreadIndicatorState extends State<_UnreadIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.3).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const SawTooth(2),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
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
      scale: _scaleAnimation,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: AppTheme.techPurple,
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(150, 139, 92, 246),
              blurRadius: 8 * _pulseAnimation.value,
              spreadRadius: 3 * _pulseAnimation.value,
            ),
            BoxShadow(
              color: const Color.fromARGB(80, 6, 182, 212),
              blurRadius: 5 * _pulseAnimation.value,
              spreadRadius: 2 * _pulseAnimation.value,
            ),
          ],
        ),
      ),
    );
  }
}