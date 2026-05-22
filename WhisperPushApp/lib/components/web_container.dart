import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class WebContainer extends StatelessWidget {
  final Widget child;
  final double mobileWidth;
  final double mobileHeight;
  final double borderRadius;

  const WebContainer({
    super.key,
    required this.child,
    this.mobileWidth = 430.0,
    this.mobileHeight = 932.0,
    this.borderRadius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final backgroundColor = isDark
        ? const Color(0xFF0F172A)
        : AppTheme.spaceBlue;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: backgroundColor,
      child: Center(
        child: Container(
          width: mobileWidth,
          height: mobileHeight,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: isDark ? 20 : 15,
                spreadRadius: isDark ? 5 : 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: child,
          ),
        ),
      ),
    );
  }
}
