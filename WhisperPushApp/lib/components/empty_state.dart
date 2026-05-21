import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onAction;
  final bool enableGlow;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox,
    required this.title,
    required this.description,
    this.actionText,
    this.onAction,
    this.enableGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromARGB(25, 139, 92, 246),
              border: Border.all(color: AppTheme.techPurple.withValues(alpha:0.4), width: 1.5),
              boxShadow: enableGlow
                  ? [
                      const BoxShadow(
                        color: Color.fromARGB(40, 139, 92, 246),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                      const BoxShadow(
                        color: Color.fromARGB(25, 6, 182, 212),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 48,
              color: AppTheme.techPurpleLight,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 14.5,
                color: AppTheme.textTertiary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (actionText != null && onAction != null)
            Padding(
              padding: const EdgeInsets.only(top: 28),
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppTheme.techPurpleLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.borderRadius,
                    side: BorderSide(color: AppTheme.techPurple, width: 1.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                child: Text(
                  actionText!,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}