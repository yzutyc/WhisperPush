import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool enableHover;
  final VoidCallback? onTap;
  final bool showBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.enableHover = true,
    this.onTap,
    this.showBorder = true,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (widget.enableHover) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        if (widget.enableHover) {
          setState(() => _isHovered = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        margin: widget.margin,
        padding: widget.padding,
        decoration: _isHovered 
            ? AppTheme.glassCardHoverDecoration 
            : AppTheme.glassCardDecoration,
        transform: _isHovered ? Matrix4.translationValues(0, -4, 0) : Matrix4.identity(),
        child: widget.onTap != null 
            ? InkWell(
                onTap: widget.onTap,
                borderRadius: AppTheme.borderRadius,
                child: widget.child,
              )
            : widget.child,
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

  const GlassCardWithBorder({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderColor = const Color.fromARGB(100, 139, 92, 246),
    this.borderWidth = 1,
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
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(30, 0, 0, 0),
            blurRadius: 15,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: const Color.fromARGB(20, 139, 92, 246),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}