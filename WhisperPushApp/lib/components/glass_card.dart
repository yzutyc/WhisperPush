import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool enableHover;
  final VoidCallback? onTap;
  final bool showBorder;
  final bool enableGlow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.enableHover = true,
    this.onTap,
    this.showBorder = true,
    this.enableGlow = true,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateHover(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (widget.enableHover) {
          _updateHover(true);
        }
      },
      onExit: (_) {
        if (widget.enableHover) {
          _updateHover(false);
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: widget.margin,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color.fromARGB(240, 30, 41, 59)
                : const Color.fromARGB(200, 30, 41, 59),
            borderRadius: AppTheme.borderRadius,
            border: widget.showBorder
                ? Border.all(
                    color: _isHovered
                        ? const Color.fromARGB(180, 139, 92, 246)
                        : const Color.fromARGB(100, 139, 92, 246),
                    width: _isHovered ? 1.5 : 1,
                  )
                : Border.all(color: Colors.transparent),
            boxShadow: widget.enableGlow
                ? [
                    BoxShadow(
                      color: const Color.fromARGB(50, 0, 0, 0),
                      blurRadius: _isHovered ? 25 : 20,
                      spreadRadius: _isHovered ? 8 : 5,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: const Color.fromARGB(60, 139, 92, 246),
                      blurRadius: _isHovered ? 30 : 15,
                      spreadRadius: _isHovered ? 10 : 3,
                    ),
                    BoxShadow(
                      color: const Color.fromARGB(40, 6, 182, 212),
                      blurRadius: _isHovered ? 20 : 10,
                      spreadRadius: _isHovered ? 6 : 2,
                    ),
                  ]
                : [
                    const BoxShadow(
                      color: Color.fromARGB(40, 0, 0, 0),
                      blurRadius: 15,
                      spreadRadius: 3,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          transform: _isHovered
              ? Matrix4.translationValues(0, -4, 10)
              : Matrix4.translationValues(0, 0, 0),
          child: ClipRRect(
            borderRadius: AppTheme.borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: _isHovered ? 20 : 15,
                sigmaY: _isHovered ? 20 : 15,
              ),
              child: widget.onTap != null
                  ? InkWell(
                      onTap: widget.onTap,
                      borderRadius: AppTheme.borderRadius,
                      child: widget.child,
                    )
                  : widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class GlassCardWithBorder extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color borderColor;
  final double borderWidth;
  final bool enableGlow;

  const GlassCardWithBorder({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderColor = const Color.fromARGB(120, 139, 92, 246),
    this.borderWidth = 1,
    this.enableGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color.fromARGB(180, 30, 41, 59),
        borderRadius: AppTheme.borderRadius,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: enableGlow
            ? [
                BoxShadow(
                  color: const Color.fromARGB(30, 0, 0, 0),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
                BoxShadow(
                  color: borderColor.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ]
            : [
                BoxShadow(
                  color: const Color.fromARGB(30, 0, 0, 0),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: AppTheme.borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }
}