import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ParticleBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;

  const ParticleBackground({
    super.key,
    required this.child,
    this.particleCount = 50,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _initParticles();
  }

  void _initParticles() {
    particles = List.generate(widget.particleCount, (index) {
      return Particle(
        id: index,
        x: 0,
        y: 0,
        vx: (0.5 + (index % 3) * 0.2),
        vy: (0.3 + (index % 5) * 0.15),
        size: 2 + (index % 3).toDouble(),
        opacity: 0.3 + (index % 4) * 0.15,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: ParticlePainter(
                particles: particles,
                progress: _controller.value,
                size: MediaQuery.of(context).size,
              ),
              size: MediaQuery.of(context).size,
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class Particle {
  final int id;
  double x;
  double y;
  final double vx;
  final double vy;
  final double size;
  final double opacity;

  Particle({
    required this.id,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final Size size;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = AppTheme.techPurple
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      particle.x += particle.vx;
      particle.y += particle.vy;

      if (particle.x > canvasSize.width) particle.x = 0;
      if (particle.y > canvasSize.height) particle.y = 0;
      if (particle.x < 0) particle.x = canvasSize.width;
      if (particle.y < 0) particle.y = canvasSize.height;

      paint.color = AppTheme.techPurple.withValues(alpha: particle.opacity);
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return true;
  }
}