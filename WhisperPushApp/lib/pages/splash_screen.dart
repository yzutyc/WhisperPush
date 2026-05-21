import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../components/logo_widget.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';
import 'message_list_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _particleAnimation;
  List<_ParticleData> particles = [];
  String _version = '';

  @override
  void initState() {
    super.initState();

    _initParticles();
    _loadVersion();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: const SawTooth(3)),
    );

    _particleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    _animationController.forward();
    _checkAuth();
  }

  void _initParticles() {
    particles = List.generate(30, (index) {
      return _ParticleData(
        x: (index * 37) % 400,
        y: (index * 53) % 600,
        vx: 0.3 + (index % 3) * 0.2,
        vy: 0.2 + (index % 5) * 0.15,
        size: 2 + (index % 3).toDouble(),
        opacity: 0.3 + (index % 4) * 0.15,
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = 'v${packageInfo.version}';
      });
    }
  }

  Future<void> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadFromStorage();

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        if (authProvider.isAuthenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MessageListPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          decoration: AppTheme.gradientBackground,
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _particleAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ParticlePainter(particles: particles),
                    size: MediaQuery.of(context).size,
                  );
                },
              ),
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromARGB(102, 139, 92, 246),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const LogoWidget(size: 100),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'WhisperPush',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Secure Push Notifications',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textTertiary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 64),
                        const NeonLoader(),
                        const SizedBox(height: 16),
                        Text(
                          _version,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textTertiary,
                          ),
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

class _ParticleData {
  double x;
  double y;
  final double vx;
  final double vy;
  final double size;
  final double opacity;

  _ParticleData({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_ParticleData> particles;

  _ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.techPurple
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      particle.x += particle.vx;
      particle.y += particle.vy;

      if (particle.x > size.width) particle.x = 0;
      if (particle.y > size.height) particle.y = 0;
      if (particle.x < 0) particle.x = size.width;
      if (particle.y < 0) particle.y = size.height;

      paint.color = Color.fromARGB(
        (particle.opacity * 255).toInt(),
        139,
        92,
        246,
      );
      canvas.drawCircle(Offset(particle.x, particle.y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return true;
  }
}

class NeonLoader extends StatelessWidget {
  const NeonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.techPurple),
        backgroundColor: AppTheme.spaceIndigo,
        strokeWidth: 3,
      ),
    );
  }
}
