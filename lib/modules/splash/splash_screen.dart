import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Main sequence ─────────────────────────────────────────────────────────
  late AnimationController _mainCtrl;

  // Stage 0 – rings expand
  late Animation<double> _ring1Scale;
  late Animation<double> _ring1Opacity;
  late Animation<double> _ring2Scale;
  late Animation<double> _ring2Opacity;
  late Animation<double> _ring3Scale;
  late Animation<double> _ring3Opacity;

  // Stage 1 – logo
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoGlow;

  // Stage 2 – wordmark
  late Animation<double> _wordmarkOpacity;
  late Animation<Offset> _wordmarkSlide;

  // Stage 3 – tagline + bar
  late Animation<double> _tagOpacity;
  late Animation<double> _barWidth;

  // ── Pulse (repeat) ────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  // ── Shimmer ───────────────────────────────────────────────────────────────
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // ── Main controller: 2 600 ms ─────────────────────────────────────────
    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    // Rings
    _ring1Scale = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.00, 0.45, curve: Curves.easeOut)));
    _ring1Opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.18), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.18, end: 0.0), weight: 1),
    ]).animate(
        CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.00, 0.55)));

    _ring2Scale = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.08, 0.52, curve: Curves.easeOut)));
    _ring2Opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: 0.0), weight: 1),
    ]).animate(
        CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.08, 0.60)));

    _ring3Scale = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.15, 0.60, curve: Curves.easeOut)));
    _ring3Opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.08), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: 0.0), weight: 1),
    ]).animate(
        CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.15, 0.65)));

    // Logo
    _logoScale = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.15, 0.55, curve: Curves.elasticOut)));
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.15, 0.35, curve: Curves.easeIn)));
    _logoGlow = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.30, 0.60, curve: Curves.easeOut)));

    // Wordmark
    _wordmarkOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.52, 0.75, curve: Curves.easeOut)));
    _wordmarkSlide =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _mainCtrl,
                curve: const Interval(0.52, 0.78, curve: Curves.easeOut)));

    // Tagline + bar
    _tagOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.70, 0.90, curve: Curves.easeOut)));
    _barWidth = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.78, 1.00, curve: Curves.easeInOut)));

    // ── Pulse controller ──────────────────────────────────────────────────
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.97, end: 1.03)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // ── Shimmer controller ────────────────────────────────────────────────
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _shimmer = Tween(begin: -1.0, end: 2.0).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    _mainCtrl.forward();

    // Navigate after 3.8 s
    Future.delayed(const Duration(milliseconds: 3800), () async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

      // Check if user is already logged in
      final authService = AuthService.to;

      if (authService.isLoggedIn.value && authService.token.value.isNotEmpty) {
        // User is logged in - fetch fresh data from API
        await DatabaseService.to.refreshUserData();

        // Go to dashboard
        if (seenOnboarding) {
          Get.offAllNamed(AppRoutes.dashboard);
        } else {
          await prefs.setBool('seen_onboarding', true);
          Get.offAllNamed(AppRoutes.dashboard);
        }
      } else {
        // User is not logged in, go to login or onboarding
        if (seenOnboarding) {
          Get.offAllNamed(AppRoutes.login);
        } else {
          await prefs.setBool('seen_onboarding', true);
          Get.offAllNamed(AppRoutes.onboarding);
        }
      }
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF080812),
      body: AnimatedBuilder(
        animation: Listenable.merge([_mainCtrl, _pulseCtrl, _shimmerCtrl]),
        builder: (_, __) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // ── 1. Background gradient ─────────────────────────────────
              _buildBackground(size),

              // ── 2. Expanding rings ─────────────────────────────────────
              _buildRings(size),

              // ── 3. Glow orb ───────────────────────────────────────────
              _buildGlowOrb(size),

              // ── 4. Particles ───────────────────────────────────────────
              _buildParticles(size),

              // ── 5. Center content ──────────────────────────────────────
              _buildCenterContent(size),

              // ── 6. Bottom bar ──────────────────────────────────────────
              _buildBottom(size),
            ],
          );
        },
      ),
    );
  }

  // ── Background ────────────────────────────────────────────────────────────
  Widget _buildBackground(Size size) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.15),
          radius: 1.2,
          colors: [
            AppColors.primary.withOpacity(0.18 * _logoGlow.value),
            const Color(0xFF0D0D1E),
            const Color(0xFF080812),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
    );
  }

  // ── Rings ─────────────────────────────────────────────────────────────────
  Widget _buildRings(Size size) {
    final maxR = size.width * 1.1;
    return Stack(
      children: [
        _ring(size, maxR * 0.55, _ring1Scale.value, _ring1Opacity.value,
            AppColors.primary),
        _ring(size, maxR * 0.78, _ring2Scale.value, _ring2Opacity.value,
            AppColors.primaryLight),
        _ring(size, maxR * 1.05, _ring3Scale.value, _ring3Opacity.value,
            AppColors.white),
      ],
    );
  }

  Widget _ring(
      Size size, double diameter, double scale, double opacity, Color color) {
    return Center(
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(opacity), width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Glow orb ──────────────────────────────────────────────────────────────
  Widget _buildGlowOrb(Size size) {
    return Center(
      child: Transform.translate(
        offset: const Offset(0, -30),
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withOpacity(0.22 * _logoGlow.value),
                AppColors.primary.withOpacity(0.08 * _logoGlow.value),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Particles ─────────────────────────────────────────────────────────────
  Widget _buildParticles(Size size) {
    final opacity = (_logoGlow.value * 0.6).clamp(0.0, 0.6);
    if (opacity < 0.01) return const SizedBox.shrink();
    return CustomPaint(
      size: size,
      painter: _ParticlePainter(
        progress: _mainCtrl.value,
        shimmer: _shimmer.value,
        opacity: opacity,
      ),
    );
  }

  // ── Center content ────────────────────────────────────────────────────────
  Widget _buildCenterContent(Size size) {
    return Align(
      alignment: const Alignment(0, -0.18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo icon
          Opacity(
            opacity: _logoOpacity.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: (_logoScale.value * _pulse.value).clamp(0.0, 1.5),
              child: _buildLogoIcon(),
            ),
          ),

          const SizedBox(height: 28),

          // Wordmark "uBAY"
          Opacity(
            opacity: _wordmarkOpacity.value.clamp(0.0, 1.0),
            child: SlideTransition(
              position: _wordmarkSlide,
              child: _buildWordmark(),
            ),
          ),

          const SizedBox(height: 10),

          // Tagline
          Opacity(
            opacity: _tagOpacity.value.clamp(0.0, 1.0),
            child: _buildTagline(),
          ),
        ],
      ),
    );
  }

  // ── Logo icon ─────────────────────────────────────────────────────────────
  Widget _buildLogoIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3 * _logoGlow.value),
              width: 1,
            ),
          ),
        ),
        // Inner glow ring
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.15 * _logoGlow.value),
              width: 1,
            ),
          ),
        ),
        // Icon container
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF9A2E),
                Color(0xFFF07C00),
                Color(0xFFD46A00),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.55 * _logoGlow.value),
                blurRadius: 32,
                spreadRadius: 4,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25 * _logoGlow.value),
                blurRadius: 60,
                spreadRadius: 12,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shine overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 38,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(22)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Shimmer sweep
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: AnimatedBuilder(
                    animation: _shimmerCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _ShimmerPainter(_shimmer.value),
                    ),
                  ),
                ),
              ),
              // "u" letter
              Center(
                child: Text(
                  'u',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: -2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Wordmark ──────────────────────────────────────────────────────────────
  Widget _buildWordmark() {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          Colors.white,
          Colors.white.withOpacity(0.92),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bounds),
      child: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'u',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
                height: 1,
              ),
            ),
            TextSpan(
              text: 'BAY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tagline ───────────────────────────────────────────────────────────────
  Widget _buildTagline() {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 1,
              color: AppColors.primary.withOpacity(0.5),
            ),
            const SizedBox(width: 10),
            Text(
              'Votre banque mobile en Guinée',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 24,
              height: 1,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'GNF · Sécurisé · Instantané',
              style: TextStyle(
                color: AppColors.primary.withOpacity(0.75),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Bottom ────────────────────────────────────────────────────────────────
  Widget _buildBottom(Size size) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Opacity(
        opacity: _tagOpacity.value.clamp(0.0, 1.0),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 52),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated progress bar
              Container(
                width: 140,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: _barWidth.value.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryLight, AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Dot loader
              _DotLoader(progress: _barWidth.value),
              const SizedBox(height: 20),
              // Version
              Text(
                'v1.0.0 · Conakry, Guinée',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dot loader ────────────────────────────────────────────────────────────────
class _DotLoader extends StatefulWidget {
  final double progress;
  const _DotLoader({required this.progress});

  @override
  State<_DotLoader> createState() => _DotLoaderState();
}

class _DotLoaderState extends State<_DotLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_ctrl.value - i * 0.25).clamp(0.0, 1.0);
            final scale = (sin(phase * pi)).abs();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(
                  0.3 + 0.7 * scale,
                ),
              ),
              transform: Matrix4.identity()..translate(0.0, -3.0 * scale),
            );
          }),
        );
      },
    );
  }
}

// ── Particle painter ──────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double progress;
  final double shimmer;
  final double opacity;

  _ParticlePainter({
    required this.progress,
    required this.shimmer,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final cx = size.width / 2;
    final cy = size.height * 0.38;

    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < 28; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = 90 + rng.nextDouble() * 180;
      final phase = rng.nextDouble();
      final t = ((progress - phase) % 1.0).abs();

      final px = cx + cos(angle) * dist * t;
      final py = cy + sin(angle) * dist * t - 40 * t;
      final r = (2.5 - 2.0 * t) * (0.6 + rng.nextDouble() * 0.4);
      final a = (1.0 - t) * opacity * 0.7;

      paint.color = (i % 3 == 0 ? AppColors.primary : Colors.white)
          .withOpacity(a.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(px, py), r.clamp(0.3, 2.5), paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.progress != progress || old.shimmer != shimmer;
}

// ── Shimmer sweep painter ─────────────────────────────────────────────────────
class _ShimmerPainter extends CustomPainter {
  final double value; // -1 → 2

  _ShimmerPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * (value * 0.5 + 0.25);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.3, 0.5, 0.7],
        transform: GradientRotation(pi / 4),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 30, -10, 60, size.height + 20),
        const Radius.circular(30),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.value != value;
}
