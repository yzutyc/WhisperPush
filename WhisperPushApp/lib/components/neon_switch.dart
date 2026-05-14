import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NeonSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final double width;
  final double height;

  const NeonSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.width = 52,
    this.height = 28,
  });

  @override
  State<NeonSwitch> createState() => _NeonSwitchState();
}

class _NeonSwitchState extends State<NeonSwitch> {
  late bool _isHovered;

  @override
  void initState() {
    super.initState();
    _isHovered = false;
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? AppTheme.techPurple;
    final inactiveColor = widget.inactiveColor ?? AppTheme.textTertiary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => widget.onChanged(!widget.value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.height / 2),
            gradient: widget.value
                ? LinearGradient(
                    colors: [activeColor, AppTheme.neonBlue],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : LinearGradient(
                    colors: [inactiveColor.withOpacity(0.3), inactiveColor.withOpacity(0.2)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            boxShadow: widget.value && _isHovered
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ]
                : null,
            border: Border.all(
              color: widget.value
                  ? activeColor.withOpacity(0.5)
                  : inactiveColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: widget.value ? widget.width - widget.height - 4 : 4,
                top: 4,
                child: Container(
                  width: widget.height - 8,
                  height: widget.height - 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: widget.value
                        ? [
                            BoxShadow(
                              color: activeColor.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}