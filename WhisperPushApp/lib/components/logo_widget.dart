import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  final double size;

  const LogoWidget({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
        ),
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            spreadRadius: 4,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.message,
          color: Colors.white,
          size: size * 0.5,
          shadows: const [
            Shadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 1)),
          ],
        ),
      ),
    );
  }
}

class LogoTextWidget extends StatelessWidget {
  const LogoTextWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'WhisperPush',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        foreground: Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ).createShader(const Rect.fromLTWH(0, 0, 200, 40)),
      ),
    );
  }
}
