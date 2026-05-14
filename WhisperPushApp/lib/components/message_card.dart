import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/message.dart';

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
    Color bgColor;
    Color textColor;
    String label;
    IconData? icon;

    switch (message.level) {
      case 'critical':
        bgColor = Colors.red[100]!;
        textColor = Colors.red;
        label = '紧急';
        icon = Icons.warning;
        break;
      case 'timeSensitive':
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange;
        label = '时间敏感';
        icon = Icons.timer;
        break;
      case 'active':
        bgColor = Colors.green[100]!;
        textColor = Colors.green;
        label = '普通';
        icon = Icons.check_circle;
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey;
        label = '未知';
        icon = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 12, color: textColor),
          if (icon != null)
            const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
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
        color: Colors.indigo[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            message.group!,
            style: TextStyle(
              color: Colors.indigo,
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
        ? SizedBox(
            width: 8,
            height: 8,
            child: CircleAvatar(
              backgroundColor: Colors.grey[300],
            ),
          )
        : const SizedBox(
            width: 8,
            height: 8,
            child: CircleAvatar(
              backgroundColor: Colors.blue,
            ),
          );
  }

  Widget _buildContentPreview() {
    String preview = message.body;
    
    if (preview.length > 80) {
      preview = '${preview.substring(0, 80)}...';
    }

    switch (message.contentType.toLowerCase()) {
      case 'markdown':
        return MarkdownBody(
          data: preview,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(fontSize: 14, color: Colors.black54),
            strong: const TextStyle(fontWeight: FontWeight.bold),
            em: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      case 'html':
        return Html(
          data: preview,
          style: {
            'body': Style(
              fontSize: FontSize(14),
              color: const Color.fromARGB(255, 87, 87, 87),
              margin: Margins.zero,
              padding: HtmlPaddings.zero,
            ),
            'p': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
          },
        );
      default:
        return Text(
          preview,
          style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('message-${message.id}'),
      direction: onDismissed != null || onMarkToggle != null ? DismissDirection.horizontal : DismissDirection.none,
      background: onDismissed != null
          ? Container(
              color: Colors.red,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 24),
              child: const Icon(Icons.delete, color: Colors.white, size: 28),
            )
          : const SizedBox(),
      secondaryBackground: onMarkToggle != null
          ? Container(
              color: Colors.green,
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
      child: InkWell(
        onTap: () {
          if (isMultiSelectMode) {
            onSelectChanged(!isSelected);
          } else {
            onTap();
          }
        },
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: isSelected
                ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                : message.read
                    ? null
                    : Border(left: const BorderSide(color: Colors.blue, width: 4)),
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
                      activeColor: Theme.of(context).primaryColor,
                    ),
                  _buildReadStatus(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message.title,
                      style: TextStyle(
                        fontWeight: message.read ? FontWeight.normal : FontWeight.bold,
                        fontSize: 16,
                        color: message.read ? Colors.black87 : Colors.black,
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
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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