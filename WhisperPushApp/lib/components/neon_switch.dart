// ignore_for_file: unused_local_variable

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

class _NeonSwitchState extends State<NeonSwitch>
    with SingleTickerProviderStateMixin {
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
    final isDark = AppTheme.isDarkMode;
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
                ? LinearGradient(
                    colors: [AppTheme.techPurple, AppTheme.neonBlue],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : LinearGradient(
                    colors: isDark
                        ? [
                            inactiveColor.withValues(alpha: 0.4),
                            inactiveColor.withValues(alpha: 0.2),
                          ]
                        : [
                            const Color(0xFFE2E8F0),
                            const Color(0xFFCBD5E1),
                          ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            boxShadow: widget.value
                ? [
                    if (isDark)
                      BoxShadow(
                        color: AppTheme.techPurple.withValues(
                          alpha: _isHovered ? 0.6 : _glowAnimation.value * 0.5,
                        ),
                        blurRadius: _isHovered ? 20 : 15,
                        spreadRadius: _isHovered ? 8 : 5,
                      ),
                    if (isDark)
                      BoxShadow(
                        color: AppTheme.neonBlue.withValues(
                          alpha: _isHovered ? 0.4 : _glowAnimation.value * 0.3,
                        ),
                        blurRadius: _isHovered ? 15 : 10,
                        spreadRadius: _isHovered ? 5 : 3,
                      ),
                    if (!isDark)
                      BoxShadow(
                        color: AppTheme.techPurple.withValues(
                          alpha: _isHovered ? 0.4 : _glowAnimation.value * 0.25,
                        ),
                        blurRadius: _isHovered ? 16 : 12,
                        spreadRadius: _isHovered ? 4 : 2,
                        offset: const Offset(0, 2),
                      ),
                  ]
                : [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.08),
                      blurRadius: isDark ? 8 : 4,
                      spreadRadius: isDark ? 2 : 0,
                      offset: isDark ? const Offset(0, 2) : const Offset(0, 1),
                    ),
                  ],
            border: Border.all(
              color: widget.value
                  ? AppTheme.techPurple.withValues(alpha: isDark ? 0.8 : 0.6)
                  : isDark
                      ? inactiveColor.withValues(alpha: 0.3)
                      : const Color(0xFFCBD5E1),
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
                      : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    width: widget.height - 4,
                    height: widget.height - 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: widget.value
                          ? LinearGradient(
                              colors: isDark
                                  ? const [Colors.white, Color(0xFFE2E8F0)]
                                  : const [Colors.white, Color(0xFFF1F5F9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: isDark
                                  ? const [
                                      Color(0xFF64748B),
                                      Color(0xFF475569)
                                    ]
                                  : const [
                                      Color(0xFF94A3B8),
                                      Color(0xFF64748B)
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      boxShadow: widget.value
                          ? [
                              if (isDark)
                                BoxShadow(
                                  color: AppTheme.techPurple.withValues(
                                    alpha: 0.6,
                                  ),
                                  blurRadius: 10,
                                  spreadRadius: 3,
                                ),
                              if (isDark)
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              if (!isDark)
                                BoxShadow(
                                  color: AppTheme.techPurple.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 2),
                                ),
                              if (!isDark)
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                  offset: const Offset(0, -1),
                                ),
                            ]
                          : [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.3)
                                    : Colors.black.withValues(alpha: 0.1),
                                blurRadius: isDark ? 5 : 3,
                                spreadRadius: isDark ? 1 : 0,
                                offset: const Offset(0, 1),
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
