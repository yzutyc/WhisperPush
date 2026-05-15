import 'package:flutter/material.dart';

class WebContainer extends StatelessWidget {
  final Widget child;
  final double mobileWidth;
  final double mobileHeight;
  final Color backgroundColor;
  final double borderRadius;

  const WebContainer({
    super.key,
    required this.child,
    this.mobileWidth = 430.0,
    this.mobileHeight = 932.0,
    this.backgroundColor = const Color(0xFF0F172A),
    this.borderRadius = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: backgroundColor,
      child: Center(
        child: Container(
          width: mobileWidth,
          height: mobileHeight,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: child,
          ),
        ),
      ),
    );
  }
}
