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

class _SearchInputState extends State<SearchInput> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: _isFocused 
          ? AppTheme.searchInputFocusedDecoration 
          : AppTheme.searchInputDecoration,
      child: TextField(
        controller: widget.controller,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: AppTheme.textDisabled, fontSize: 14),
          prefixIcon: Icon(
            Icons.search, 
            color: _isFocused ? AppTheme.techPurpleLight : AppTheme.textDisabled,
            size: 18,
          ),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.textDisabled, size: 16),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onChanged?.call('');
                    widget.onClear?.call();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: widget.onChanged,
        onTap: () {
          setState(() => _isFocused = true);
        },
        onSubmitted: (_) {
          FocusScope.of(context).unfocus();
          setState(() => _isFocused = false);
        },
      ),
    );
  }
}