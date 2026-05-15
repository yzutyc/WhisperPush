import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  final Color? backgroundColor;
  final EdgeInsets padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.blur = 10,
    this.borderColor,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.spaceIndigo.withOpacity(0.6),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppTheme.techPurple.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.techPurple.withOpacity(0.1),
            blurRadius: blur,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
