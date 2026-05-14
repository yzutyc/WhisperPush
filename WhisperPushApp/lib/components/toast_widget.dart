import 'package:flutter/material.dart';

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
    if (overlayState == null) return;

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

  Color _getBackgroundColor() {
    switch (widget.type) {
      case ToastType.success:
        return const Color(0xFF10B981);
      case ToastType.error:
        return const Color(0xFFEF4444);
      case ToastType.warning:
        return const Color(0xFFF59E0B);
      case ToastType.info:
        return const Color(0xFF3B82F6);
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
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.2,
      left: 20,
      right: 20,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getIcon(),
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}