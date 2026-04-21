import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../routes/app_routes.dart';
import '../../../services/twofa_service.dart';
import '../../../widgets/custom_button.dart';

class TwoFAVerifyScreen extends StatefulWidget {
  const TwoFAVerifyScreen({super.key});

  @override
  State<TwoFAVerifyScreen> createState() => _TwoFAVerifyScreenState();
}

class _TwoFAVerifyScreenState extends State<TwoFAVerifyScreen>
    with TickerProviderStateMixin {
  final TwoFAService _2fa = TwoFAService.to;

  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  bool _hasError = false;
  bool _isLoading = false;
  int _attempts = 0;

  // Shake animation
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  // Ring progress painter
  late AnimationController _ringCtrl;

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    _shakeCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  void _onChanged(int index, String value) {
    setState(() => _hasError = false);
    if (value.length == 1 && index < 5) {
      _nodes[index + 1].requestFocus();
    }
    if (value.length == 1 && index == 5) {
      _nodes[index].unfocus();
      _verify();
    }
  }

  Future<void> _verify() async {
    final code = _ctrls.map((c) => c.text).join();
    if (code.length < 6) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    if (_2fa.verifyCode(code)) {
      setState(() => _isLoading = false);
      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      _attempts++;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      _shakeCtrl.forward(from: 0);
      for (final c in _ctrls) c.clear();
      _nodes[0].requestFocus();

      if (_attempts >= 5) {
        // Lock out after 5 attempts
        await Future.delayed(const Duration(milliseconds: 800));
        Get.offAllNamed(AppRoutes.login);
        Get.snackbar(
          'Accès bloqué',
          'Trop de tentatives incorrectes. Reconnectez-vous.',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7F4EF),
      body: Stack(
        children: [
          // ── Gradient header ──────────────────────────────────────────────
          Container(
            height: size.height * 0.38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.info.withOpacity(0.92),
                  AppColors.accent,
                ],
              ),
            ),
          ),

          // ── Wave decoration ──────────────────────────────────────────────
          Positioned(
            top: size.height * 0.3,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 80,
              child: CustomPaint(
                painter: _WavePainter(
                    isDark ? AppColors.backgroundDark : const Color(0xFFF7F4EF)),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── App bar ──────────────────────────────────────────────
                _buildAppBar(),
                const SizedBox(height: 20),

                // ── Timer ring + icon ─────────────────────────────────────
                Obx(() => _buildTimerRing(isDark)).animate()
                    .scale(begin: const Offset(0.5, 0.5),
                        duration: 600.ms, curve: Curves.elasticOut),

                const SizedBox(height: 20),

                // ── Title ────────────────────────────────────────────────
                const Text(
                  'Code d\'authentification',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),

                const SizedBox(height: 6),

                Text(
                  'Entrez le code à 6 chiffres\nde votre application 2FA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 36),

                // ── OTP boxes ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(_shakeAnim.value, 0),
                      child: child,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (i) => _BigOtpBox(
                        controller: _ctrls[i],
                        focusNode: _nodes[i],
                        hasError: _hasError,
                        isDark: isDark,
                        onChanged: (v) => _onChanged(i, v),
                        onBackspace: () {
                          if (_ctrls[i].text.isEmpty && i > 0) {
                            _nodes[i - 1].requestFocus();
                          }
                        },
                      )),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                // ── Error message ─────────────────────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  child: _hasError
                      ? Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 32),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(
                                  isDark ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color:
                                      AppColors.error.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: AppColors.error, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Code invalide — tentative $_attempts/5',
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 28),

                // ── Verify button ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CustomButton(
                    label: 'Vérifier',
                    isLoading: _isLoading,
                    onPressed: _verify,
                    gradient: AppColors.primaryGradient,
                    suffixIcon: const Icon(Icons.verified_rounded,
                        color: Colors.white, size: 18),
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 20),

                // ── Demo hint ─────────────────────────────────────────────
                Obx(() {
                  final svc = _2fa;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.warning.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          // Countdown ring
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CustomPaint(
                              painter: _CountdownRingPainter(
                                progress: 1 - svc.codeProgress,
                                color: AppColors.warning,
                              ),
                              child: Center(
                                child: Text(
                                  '${svc.secondsLeft.value}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Code courant (démo)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatCode(svc.currentCode.value),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.warning,
                                    letterSpacing: 4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).animate().fadeIn(delay: 450.ms),

                const SizedBox(height: 20),

                // ── Use backup code ───────────────────────────────────────
                TextButton(
                  onPressed: () => _showBackupCodeSheet(isDark),
                  child: const Text(
                    'Utiliser un code de secours',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCode(String code) {
    if (code.length == 6) return '${code.substring(0, 3)} ${code.substring(3)}';
    return code;
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.offAllNamed(AppRoutes.login),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: AppColors.primaryGradient,
                  ),
                  child: const Center(
                    child: Text('u',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'uBAY — Vérification 2FA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildTimerRing(bool isDark) {
    final svc = _2fa;
    return SizedBox(
      width: 90,
      height: 90,
      child: CustomPaint(
        painter: _CountdownRingPainter(
          progress: 1 - svc.codeProgress,
          color: Colors.white.withOpacity(0.6),
          strokeWidth: 3,
        ),
        child: Center(
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border: Border.all(
                  color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
            child: const Icon(Icons.security_rounded,
                color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }

  void _showBackupCodeSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BackupCodeSheet(isDark: isDark),
    );
  }
}

// ── Big OTP box ───────────────────────────────────────────────────────────────
class _BigOtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _BigOtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.isDark,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  State<_BigOtpBox> createState() => _BigOtpBoxState();
}

class _BigOtpBoxState extends State<_BigOtpBox> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(
        () => setState(() => _focused = widget.focusNode.hasFocus));
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.hasError
        ? AppColors.error
        : _focused
            ? Colors.white
            : Colors.white.withOpacity(0.3);

    final bgColor = widget.hasError
        ? AppColors.error.withOpacity(0.12)
        : _focused
            ? Colors.white.withOpacity(0.18)
            : Colors.white.withOpacity(0.08);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: _focused ? 2 : 1.5),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              widget.controller.text.isEmpty) {
            widget.onBackspace();
          }
        },
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: widget.hasError ? AppColors.error : Colors.white,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}

// ── Backup code sheet ─────────────────────────────────────────────────────────
class _BackupCodeSheet extends StatelessWidget {
  final bool isDark;
  const _BackupCodeSheet({required this.isDark});

  // Mock backup codes
  static const _codes = [
    'UBAY-7X4K-9M2P',
    'UBAY-3Q8R-5N6T',
    'UBAY-2W1L-8J4V',
    'UBAY-6Y9S-1C3B',
    'UBAY-4F7H-0D5E',
    'UBAY-8A2G-6K1M',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Codes de secours',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: Get.back,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.cardDark : AppColors.grey100,
                  ),
                  child: const Icon(Icons.close_rounded, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Utilisez un de ces codes si vous n\'avez pas accès à votre application 2FA. Chaque code ne peut être utilisé qu\'une seule fois.',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textOnDarkSecondary
                  : AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.grey50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color:
                      isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              children: _codes.asMap().entries.map((e) {
                final used = e.key > 3; // Mock: first 4 unused
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: used
                              ? AppColors.grey300
                              : AppColors.success.withOpacity(0.15),
                        ),
                        child: Icon(
                          used ? Icons.close_rounded : Icons.check_rounded,
                          size: 12,
                          color: used ? AppColors.grey400 : AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        e.value,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: used
                              ? AppColors.grey400
                              : (isDark
                                  ? AppColors.textOnDark
                                  : AppColors.textPrimary),
                          decoration: used ? TextDecoration.lineThrough : null,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      if (!used)
                        Text(
                          'Disponible',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ces codes sont confidentiels. Ne les partagez jamais.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Countdown ring painter ────────────────────────────────────────────────────
class _CountdownRingPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0
  final Color color;
  final double strokeWidth;

  _CountdownRingPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 2.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = min(cx, cy) - strokeWidth / 2;

    // Background ring
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = color.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CountdownRingPainter old) => old.progress != progress;
}

// ── Wave painter ──────────────────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  final Color color;
  _WavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.cubicTo(
      size.width * 0.25, size.height * 0.3,
      size.width * 0.75, size.height,
      size.width, size.height * 0.5,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
