import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

enum ToastType { success, error, warning, info }

class ToastWidget {
  static OverlayEntry? _currentToast;

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    OverlayState? overlayState = Overlay.of(context);

    if (_currentToast != null) {
      _currentToast!.remove();
      _currentToast = null;
    }

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _Toast(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
            if (_currentToast == overlayEntry) {
              _currentToast = null;
            }
          }
        },
      ),
    );

    _currentToast = overlayEntry;
    overlayState.insert(overlayEntry);
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message, type: ToastType.success);
  }

  static void showError(BuildContext context, String message) {
    show(context, message, type: ToastType.error);
  }

  static void showWarning(BuildContext context, String message) {
    show(context, message, type: ToastType.warning);
  }

  static void showInfo(BuildContext context, String message) {
    show(context, message, type: ToastType.info);
  }
}

class _Toast extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _Toast({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    Future.delayed(widget.duration - const Duration(milliseconds: 200), () {
      if (mounted) {
        _animationController.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  _ToastColorScheme _getColorScheme() {
    switch (widget.type) {
      case ToastType.success:
        return _ToastColorScheme(
          borderColor: AppTheme.pulseGreen,
          iconColor: AppTheme.pulseGreen,
          iconBg: const Color.fromARGB(20, 16, 185, 129),
          glowColor: AppTheme.pulseGreen.withValues(alpha: 0.3),
        );
      case ToastType.error:
        return _ToastColorScheme(
          borderColor: AppTheme.dangerRed,
          iconColor: AppTheme.dangerRed,
          iconBg: const Color.fromARGB(20, 239, 68, 68),
          glowColor: AppTheme.dangerRed.withValues(alpha: 0.3),
        );
      case ToastType.warning:
        return _ToastColorScheme(
          borderColor: AppTheme.warningOrange,
          iconColor: AppTheme.warningOrange,
          iconBg: const Color.fromARGB(20, 245, 158, 11),
          glowColor: AppTheme.warningOrange.withValues(alpha: 0.3),
        );
      case ToastType.info:
        return _ToastColorScheme(
          borderColor: AppTheme.techPurple,
          iconColor: AppTheme.techPurple,
          iconBg: const Color.fromARGB(20, 139, 92, 246),
          glowColor: AppTheme.techPurple.withValues(alpha: 0.3),
        );
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.error:
        return Icons.error;
      case ToastType.warning:
        return Icons.warning;
      case ToastType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final colorScheme = _getColorScheme();

    return Positioned(
      top: MediaQuery.of(context).size.height * 0.15,
      left: 24,
      right: 24,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                borderRadius: AppTheme.borderRadius,
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: colorScheme.glowColor,
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: AppTheme.borderRadius,
                child: isDark
                    ? BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(200, 30, 41, 59),
                            borderRadius: AppTheme.borderRadius,
                            border: Border.all(
                              color: colorScheme.borderColor.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.iconBg,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.iconColor.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _getIcon(),
                                  color: colorScheme.iconColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.message,
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppTheme.borderRadius,
                          border: Border.all(
                            color: colorScheme.borderColor.withValues(alpha: isDark ? 0.6 : 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.iconBg,
                              ),
                              child: Icon(
                                _getIcon(),
                                color: colorScheme.iconColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.message,
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastColorScheme {
  final Color borderColor;
  final Color iconColor;
  final Color iconBg;
  final Color glowColor;

  _ToastColorScheme({
    required this.borderColor,
    required this.iconColor,
    required this.iconBg,
    required this.glowColor,
  });
}