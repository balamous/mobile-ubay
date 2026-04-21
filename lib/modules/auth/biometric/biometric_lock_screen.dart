import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../routes/app_routes.dart';
import '../../../services/app_controller.dart';
import '../../../services/biometric_service.dart';

class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen>
    with SingleTickerProviderStateMixin {
  final BiometricService _bio = BiometricService.to;
  final AppController _app = AppController.to;

  // ── Pulse animation ───────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  // ── State ─────────────────────────────────────────────────────────────────
  _LockState _state = _LockState.idle;
  String? _errorMsg;
  int _failCount = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Auto-trigger biometric after a brief moment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 700), _triggerBiometric);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _triggerBiometric() async {
    if (!mounted) return;
    setState(() {
      _state = _LockState.scanning;
      _errorMsg = null;
    });

    final result = await _bio.authenticate(
      reason: 'Déverrouillez uBAY pour accéder à votre compte',
    );

    if (!mounted) return;

    switch (result) {
      case BiometricResult.success:
        setState(() => _state = _LockState.success);
        _bio.unlock();
        await Future.delayed(const Duration(milliseconds: 800));
        Get.offAllNamed(AppRoutes.dashboard);
        break;

      case BiometricResult.failed:
        _failCount++;
        setState(() {
          _state = _LockState.error;
          _errorMsg = _failCount >= 3
              ? 'Trop de tentatives. Utilisez votre mot de passe.'
              : 'Authentification échouée. Réessayez.';
        });
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted && _failCount < 3) {
          setState(() => _state = _LockState.idle);
        }
        break;

      case BiometricResult.lockedOut:
        setState(() {
          _state = _LockState.error;
          _errorMsg = 'Biométrie verrouillée. Utilisez votre mot de passe.';
        });
        break;

      case BiometricResult.notEnrolled:
        setState(() {
          _state = _LockState.error;
          _errorMsg = 'Aucune biométrie enregistrée sur cet appareil.';
        });
        break;

      case BiometricResult.unavailable:
        setState(() {
          _state = _LockState.error;
          _errorMsg = 'Biométrie non disponible. Utilisez votre mot de passe.';
        });
        break;

      default:
        setState(() {
          _state = _LockState.idle;
          _errorMsg = null;
        });
    }
  }

  void _goToPassword() {
    _bio.disableBiometric();
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final user = _app.user.value;
    final isFace = _bio.isFace;
    final label = _bio.kindLabel;

    return Scaffold(
      backgroundColor: const Color(0xFF080812),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background ──────────────────────────────────────────────────
          _buildBackground(),

          // ── Particles ───────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _BgParticlePainter(_pulseCtrl.value),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────────────
                _buildTopBar(),
                const Spacer(),

                // ── Avatar + greeting ────────────────────────────────────
                _buildGreeting(user!.firstName).animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 60),

                // ── Biometric icon ───────────────────────────────────────
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => _buildBiometricIcon(isFace),
                ),

                const SizedBox(height: 32),

                // ── Status text ──────────────────────────────────────────
                _buildStatusText(label),

                const Spacer(),

                // ── Bottom actions ───────────────────────────────────────
                _buildBottomActions(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Background ────────────────────────────────────────────────────────────
  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, 0.1),
            radius: 1.1,
            colors: [
              _state == _LockState.success
                  ? AppColors.success.withOpacity(0.15)
                  : _state == _LockState.error
                      ? AppColors.error.withOpacity(0.12)
                      : AppColors.primary.withOpacity(0.10 * _pulse.value),
              const Color(0xFF0D0D1E),
              const Color(0xFF080812),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: AppColors.primaryGradient,
            ),
            child: const Center(
              child: Text(
                'u',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'uBAY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  // ── Greeting ──────────────────────────────────────────────────────────────
  Widget _buildGreeting(String firstName) {
    return Column(
      children: [
        // Avatar
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Bonjour, $firstName 👋',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Vérifiez votre identité pour continuer',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ── Biometric icon ────────────────────────────────────────────────────────
  Widget _buildBiometricIcon(bool isFace) {
    final Color iconColor = _state == _LockState.success
        ? AppColors.success
        : _state == _LockState.error
            ? AppColors.error
            : AppColors.primary;

    final double scale =
        _state == _LockState.scanning ? _pulse.value : 1.0;

    return GestureDetector(
      onTap: _state == _LockState.scanning ? null : _triggerBiometric,
      child: Transform.scale(
        scale: scale,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: iconColor.withOpacity(0.15),
                  width: 1,
                ),
              ),
            ),
            // Middle ring
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: iconColor.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
            ),
            // Inner filled circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withOpacity(0.1),
                border: Border.all(
                  color: iconColor.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(
                        _state == _LockState.scanning ? 0.4 : 0.2),
                    blurRadius: _state == _LockState.scanning ? 30 : 16,
                    spreadRadius:
                        _state == _LockState.scanning ? 4 : 0,
                  ),
                ],
              ),
              child: Icon(
                _state == _LockState.success
                    ? Icons.check_rounded
                    : _state == _LockState.error
                        ? Icons.close_rounded
                        : isFace
                            ? Icons.face_rounded
                            : Icons.fingerprint_rounded,
                color: iconColor,
                size: 44,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Status text ───────────────────────────────────────────────────────────
  Widget _buildStatusText(String label) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _state == _LockState.idle
                ? 'Appuyez pour vous authentifier'
                : _state == _LockState.scanning
                    ? 'Scan en cours...'
                    : _state == _LockState.success
                        ? 'Authentification réussie !'
                        : 'Authentification échouée',
            key: ValueKey(_state),
            style: TextStyle(
              color: _state == _LockState.success
                  ? AppColors.success
                  : _state == _LockState.error
                      ? AppColors.error
                      : Colors.white.withOpacity(0.75),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (_errorMsg != null) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Text(
              _errorMsg!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
              ),
            ),
          ).animate().shakeX(),
        ],
        const SizedBox(height: 12),
        // Label chip
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _bio.isFace
                    ? Icons.face_retouching_natural_rounded
                    : Icons.fingerprint_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Bottom actions ────────────────────────────────────────────────────────
  Widget _buildBottomActions() {
    return Column(
      children: [
        // Retry button if error
        if (_state == _LockState.error && _failCount < 3) ...[
          GestureDetector(
            onTap: _triggerBiometric,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Text(
                'Réessayer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Use password fallback
        GestureDetector(
          onTap: _goToPassword,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.white.withOpacity(0.6),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Utiliser le mot de passe',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }
}

enum _LockState { idle, scanning, success, error }

// ── Background particle painter ───────────────────────────────────────────────
class _BgParticlePainter extends CustomPainter {
  final double t;
  _BgParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(7);
    final paint = Paint();
    for (var i = 0; i < 20; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final phase = rng.nextDouble();
      final alpha = (sin((t + phase) * 2 * pi) * 0.5 + 0.5) * 0.08;
      final r = 1.5 + rng.nextDouble() * 2;
      paint.color = (i % 3 == 0 ? AppColors.primary : Colors.white)
          .withOpacity(alpha.clamp(0, 1));
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_BgParticlePainter old) => old.t != t;
}
