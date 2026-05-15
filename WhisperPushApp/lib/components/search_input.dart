import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SearchInput extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const SearchInput({
    super.key,
    required this.controller,
    this.hintText = '搜索...',
    this.onChanged,
    this.onClear,
  });

  @override
  State<SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> with SingleTickerProviderStateMixin {
  bool _isFocused = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: _isFocused
            ? const Color.fromARGB(240, 30, 41, 59)
            : const Color.fromARGB(200, 30, 41, 59),
        borderRadius: AppTheme.borderRadius,
        border: Border.all(
          color: _isFocused
              ? const Color.fromARGB(180, 139, 92, 246)
              : const Color.fromARGB(60, 139, 92, 246),
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: const Color.fromARGB(80, 139, 92, 246),
                  blurRadius: 25 * _pulseAnimation.value,
                  spreadRadius: 8 * _pulseAnimation.value,
                ),
                BoxShadow(
                  color: const Color.fromARGB(50, 6, 182, 212),
                  blurRadius: 15 * _pulseAnimation.value,
                  spreadRadius: 5 * _pulseAnimation.value,
                ),
              ]
            : [
                BoxShadow(
                  color: const Color.fromARGB(20, 139, 92, 246),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: AppTheme.borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _isFocused ? 20 : 15,
            sigmaY: _isFocused ? 20 : 15,
          ),
          child: TextField(
            controller: widget.controller,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: _isFocused ? FontWeight.w500 : FontWeight.normal,
            ),
            cursorColor: AppTheme.techPurple,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: _isFocused ? AppTheme.textTertiary : AppTheme.textDisabled,
                fontSize: 15,
              ),
              prefixIcon: ScaleTransition(
                scale: _isFocused ? _pulseAnimation : AlwaysStoppedAnimation(1.0),
                child: Icon(
                  Icons.search,
                  color: _isFocused ? AppTheme.techPurpleLight : AppTheme.textDisabled,
                  size: 20,
                ),
              ),
              suffixIcon: widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppTheme.textTertiary, size: 18),
                      onPressed: () {
                        widget.controller.clear();
                        widget.onChanged?.call('');
                        widget.onClear?.call();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: widget.onChanged,
            onTap: () {
              setState(() => _isFocused = true);
            },
            onSubmitted: (_) {
              FocusScope.of(context).unfocus();
              setState(() => _isFocused = false);
            },
            onEditingComplete: () {
              FocusScope.of(context).unfocus();
              setState(() => _isFocused = false);
            },
          ),
        ),
      ),
    );
  }
}