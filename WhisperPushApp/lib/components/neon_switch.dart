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
    this.width = 56,
    this.height = 32,
  });

  @override
  State<NeonSwitch> createState() => _NeonSwitchState();
}

class _NeonSwitchState extends State<NeonSwitch> with SingleTickerProviderStateMixin {
  late bool _isHovered;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _isHovered = false;
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.6, end: 0.9).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? AppTheme.techPurple;
    final inactiveColor = widget.inactiveColor ?? AppTheme.spaceLight;

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
                ? const LinearGradient(
                    colors: [AppTheme.techPurple, AppTheme.neonBlue],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : LinearGradient(
                    colors: [
                      inactiveColor.withOpacity(0.4),
                      inactiveColor.withOpacity(0.2),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            boxShadow: widget.value
                ? [
                    BoxShadow(
                      color: AppTheme.techPurple.withOpacity(
                        _isHovered ? 0.6 : _glowAnimation.value * 0.5,
                      ),
                      blurRadius: _isHovered ? 20 : 15,
                      spreadRadius: _isHovered ? 8 : 5,
                    ),
                    BoxShadow(
                      color: AppTheme.neonBlue.withOpacity(
                        _isHovered ? 0.4 : _glowAnimation.value * 0.3,
                      ),
                      blurRadius: _isHovered ? 15 : 10,
                      spreadRadius: _isHovered ? 5 : 3,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
            border: Border.all(
              color: widget.value
                  ? AppTheme.techPurple.withOpacity(0.8)
                  : inactiveColor.withOpacity(0.3),
              width: widget.value ? 1.5 : 1,
            ),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: widget.value ? widget.width - widget.height + 2 : 2,
                top: 2,
                child: ScaleTransition(
                  scale: widget.value && _isHovered
                      ? Tween<double>(begin: 1.0, end: 1.1).animate(
                          CurvedAnimation(
                            parent: _glowController,
                            curve: Curves.easeInOut,
                          ),
                        )
                      : AlwaysStoppedAnimation(1.0),
                  child: Container(
                    width: widget.height - 4,
                    height: widget.height - 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: widget.value
                          ? const LinearGradient(
                              colors: [Colors.white, Color(0xFFE2E8F0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF64748B), Color(0xFF475569)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      boxShadow: widget.value
                          ? [
                              BoxShadow(
                                color: AppTheme.techPurple.withOpacity(0.6),
                                blurRadius: 10,
                                spreadRadius: 3,
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 5,
                                spreadRadius: 1,
                              ),
                            ],
                    ),
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