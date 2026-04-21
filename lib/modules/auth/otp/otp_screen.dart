import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../routes/app_routes.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  // ── Arguments passed from RegisterScreen ─────────────────────────────────
  late final String _phone;
  late final String _dialCode;

  // ── OTP fields ────────────────────────────────────────────────────────────
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _hasError = false;
  int _secondsLeft = 60;
  Timer? _timer;

  // ── Shake animation ───────────────────────────────────────────────────────
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _phone = args['phone'] as String? ?? '';
    _dialCode = args['dialCode'] as String? ?? '+221';

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeCtrl.dispose();
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  // ── Resend ────────────────────────────────────────────────────────────────
  void _resend() {
    if (_secondsLeft > 0) return;
    for (final c in _ctrls) {
      c.clear();
    }
    setState(() => _hasError = false);
    _nodes[0].requestFocus();
    _startTimer();
    Get.snackbar(
      'Code envoyé',
      'Un nouveau code a été envoyé au $_dialCode $_phone',
      backgroundColor: AppColors.success.withOpacity(0.1),
      colorText: AppColors.success,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.check_circle_outline_rounded,
          color: AppColors.success),
    );
  }

  // ── Verify ────────────────────────────────────────────────────────────────
  Future<void> _verify() async {
    final code = _ctrls.map((c) => c.text).join();
    if (code.length < 6) {
      Get.snackbar(
        'Code incomplet',
        'Veuillez saisir les 6 chiffres du code',
        backgroundColor: AppColors.warning.withOpacity(0.1),
        colorText: AppColors.warning,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    // Simulate network verification delay
    await Future.delayed(const Duration(milliseconds: 1800));

    // Mock: correct code is 123456
    if (code == '123456') {
      setState(() => _isLoading = false);
      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      // Shake the OTP boxes
      _shakeCtrl.forward(from: 0);
      // Clear fields and refocus first box
      for (final c in _ctrls) {
        c.clear();
      }
      _nodes[0].requestFocus();
    }
  }

  // ── Key input handling ────────────────────────────────────────────────────
  void _onChanged(int index, String value) {
    setState(() => _hasError = false);
    if (value.length == 1 && index < 5) {
      _nodes[index + 1].requestFocus();
    }
    if (value.length == 1 && index == 5) {
      _nodes[index].unfocus();
      // Auto-submit when last digit entered
      _verify();
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _ctrls[index].text.isEmpty &&
        index > 0) {
      _nodes[index - 1].requestFocus();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maskedPhone = _phone.length > 4
        ? '${'*' * (_phone.length - 4)}${_phone.substring(_phone.length - 4)}'
        : _phone;

    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient header ──────────────────────────────────────────────
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accent, AppColors.accentLight],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── App bar ──────────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: Get.back,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Header content ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.25), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.message_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ).animate().scale(
                            begin: const Offset(0.5, 0.5),
                            duration: 500.ms,
                            curve: Curves.elasticOut,
                          ),
                      const SizedBox(height: 14),
                      const Text(
                        'Vérification SMS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3, end: 0),
                      const SizedBox(height: 6),
                      Text(
                        'Code envoyé au $_dialCode $maskedPhone',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Main card ────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.white,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radius2XL),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Entrez le code à 6 chiffres',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textOnDark
                                  : AppColors.textPrimary,
                            ),
                          ).animate().fadeIn(delay: 250.ms),

                          const SizedBox(height: 8),

                          Text(
                            'Le code expire dans quelques minutes.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textOnDarkSecondary
                                  : AppColors.textSecondary,
                            ),
                          ).animate().fadeIn(delay: 300.ms),

                          const SizedBox(height: 32),

                          // ── OTP boxes ────────────────────────────────
                          AnimatedBuilder(
                            animation: _shakeAnim,
                            builder: (_, child) => Transform.translate(
                              offset: Offset(_shakeAnim.value, 0),
                              child: child,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(6, (i) {
                                return _OtpBox(
                                  controller: _ctrls[i],
                                  focusNode: _nodes[i],
                                  hasError: _hasError,
                                  isDark: isDark,
                                  onChanged: (v) => _onChanged(i, v),
                                  onKeyEvent: (e) => _onKeyEvent(i, e),
                                );
                              }),
                            ),
                          ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2, end: 0),

                          // ── Error message ─────────────────────────────
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            child: _hasError
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          color: AppColors.error,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Code incorrect. Veuillez réessayer.',
                                          style: TextStyle(
                                            color: AppColors.error,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          const SizedBox(height: 32),

                          // ── Verify button ─────────────────────────────
                          _VerifyButton(
                            isLoading: _isLoading,
                            onPressed: _verify,
                          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.2, end: 0),

                          const SizedBox(height: 28),

                          // ── Resend section ────────────────────────────
                          Column(
                            children: [
                              Text(
                                'Vous n\'avez pas reçu le code ?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.textOnDarkSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _secondsLeft == 0 ? _resend : null,
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _secondsLeft == 0
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.grey600
                                            : AppColors.grey400),
                                  ),
                                  child: _secondsLeft > 0
                                      ? Text(
                                          'Renvoyer dans $_secondsLeft s',
                                        )
                                      : const Text('Renvoyer le code'),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 500.ms),

                          const SizedBox(height: 16),

                          // ── Hint for demo ─────────────────────────────
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Code démo : ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textOnDarkSecondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                const Text(
                                  '1 2 3 4 5 6',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 600.ms),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── OTP single digit box ─────────────────────────────────────────────────────

class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.isDark,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.hasError
        ? AppColors.error
        : _isFocused
            ? AppColors.primary
            : (widget.isDark ? AppColors.borderDark : AppColors.borderLight);

    final bgColor = widget.hasError
        ? AppColors.error.withOpacity(0.05)
        : _isFocused
            ? AppColors.primary.withOpacity(0.05)
            : (widget.isDark ? AppColors.surfaceDark : AppColors.grey50);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 46,
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: _isFocused || widget.hasError ? 2 : 1.5,
        ),
        boxShadow: _isFocused && !widget.hasError
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.18),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : widget.hasError
                ? [
                    BoxShadow(
                      color: AppColors.error.withOpacity(0.15),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: widget.onKeyEvent,
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
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: widget.hasError
                ? AppColors.error
                : (widget.isDark
                    ? AppColors.textOnDark
                    : AppColors.textPrimary),
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}

// ── Verify button ─────────────────────────────────────────────────────────────

class _VerifyButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _VerifyButton({required this.isLoading, required this.onPressed});

  @override
  State<_VerifyButton> createState() => _VerifyButtonState();
}

class _VerifyButtonState extends State<_VerifyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        if (!widget.isLoading) widget.onPressed();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: widget.isLoading ? null : AppColors.primaryGradient,
            color: widget.isLoading ? AppColors.grey200 : null,
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
            boxShadow: widget.isLoading
                ? []
                : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Vérifier le code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
