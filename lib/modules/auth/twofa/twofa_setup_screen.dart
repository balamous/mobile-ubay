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

class TwoFASetupScreen extends StatefulWidget {
  const TwoFASetupScreen({super.key});

  @override
  State<TwoFASetupScreen> createState() => _TwoFASetupScreenState();
}

class _TwoFASetupScreenState extends State<TwoFASetupScreen> {
  final TwoFAService _2fa = TwoFAService.to;

  int _step = 0; // 0=intro, 1=qr, 2=verify
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  bool _hasError = false;
  bool _isLoading = false;
  bool _secretRevealed = false;

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  Future<void> _verifyAndEnable() async {
    final code = _ctrls.map((c) => c.text).join();
    if (code.length < 6) return;

    setState(() { _isLoading = true; _hasError = false; });
    await Future.delayed(const Duration(milliseconds: 1000));

    if (_2fa.verifyCode(code)) {
      await _2fa.enable();
      setState(() => _isLoading = false);
      _showSuccess();
    } else {
      setState(() { _isLoading = false; _hasError = true; });
      for (final c in _ctrls) c.clear();
      _nodes[0].requestFocus();
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.white,
              borderRadius: BorderRadius.circular(AppConstants.radius2XL),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_rounded,
                      color: Colors.white, size: 38),
                ).animate().scale(
                    begin: const Offset(0, 0),
                    duration: 500.ms,
                    curve: Curves.elasticOut),
                const SizedBox(height: 20),
                const Text(
                  '2FA Activé !',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'La double authentification est maintenant active sur votre compte uBAY.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Terminer',
                  onPressed: () {
                    Get.back(); // close dialog
                    Get.back(); // close setup screen
                  },
                  gradient: AppColors.primaryGradient,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Header gradient
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.info.withOpacity(0.9),
                  AppColors.accent,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildStepper(isDark),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.08, 0),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: _buildStep(isDark),
                    ),
                  ),
                ),
                _buildBottomBar(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _step == 0 ? Get.back : () => setState(() => _step--),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Double Authentification',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800),
                ),
                Text(
                  'Sécurisez votre compte uBAY',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(bool isDark) {
    const labels = ['Présentation', 'Configuration', 'Vérification'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(3, (i) {
          final done = i < _step;
          final active = i == _step;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 3,
                        decoration: BoxDecoration(
                          color: done || active
                              ? Colors.white
                              : Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w400,
                          color: active
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < 2) const SizedBox(width: 6),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep(bool isDark) {
    switch (_step) {
      case 0:
        return _StepIntro(isDark: isDark, key: const ValueKey(0));
      case 1:
        return _StepQR(
          isDark: isDark,
          secret: _2fa.secretFormatted,
          secretRevealed: _secretRevealed,
          onReveal: () => setState(() => _secretRevealed = true),
          key: const ValueKey(1),
        );
      case 2:
        return _StepVerify(
          isDark: isDark,
          ctrls: _ctrls,
          nodes: _nodes,
          hasError: _hasError,
          isLoading: _isLoading,
          onChanged: (i, v) {
            setState(() => _hasError = false);
            if (v.length == 1 && i < 5) _nodes[i + 1].requestFocus();
            if (v.length == 1 && i == 5) {
              _nodes[i].unfocus();
              _verifyAndEnable();
            }
          },
          key: const ValueKey(2),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomBar(bool isDark) {
    final isLast = _step == 2;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        border: Border(
          top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: CustomButton(
        label: isLast ? 'Activer la 2FA' : 'Continuer',
        isLoading: _isLoading,
        gradient: AppColors.primaryGradient,
        onPressed: isLast
            ? _verifyAndEnable
            : () => setState(() => _step++),
        suffixIcon: Icon(
          isLast ? Icons.verified_user_rounded : Icons.arrow_forward_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

// ── Step 0: Introduction ──────────────────────────────────────────────────────
class _StepIntro extends StatelessWidget {
  final bool isDark;
  const _StepIntro({required this.isDark, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(AppConstants.radius2XL),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.info, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.security_rounded,
                    color: Colors.white, size: 40),
              ).animate().scale(
                  begin: const Offset(0.5, 0.5),
                  duration: 500.ms,
                  curve: Curves.elasticOut),
              const SizedBox(height: 20),
              Text(
                'Protégez votre compte',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color:
                      isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'La double authentification (2FA) ajoute une couche de sécurité supplémentaire. Même si quelqu\'un connaît votre mot de passe, il ne pourra pas accéder à votre compte.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 20),
        ..._benefits(isDark).asMap().entries.map((e) => e.value
            .animate()
            .fadeIn(delay: Duration(milliseconds: 150 + e.key * 80))
            .slideX(begin: 0.1, end: 0)),
      ],
    );
  }

  List<Widget> _benefits(bool isDark) {
    final items = [
      (Icons.shield_moon_rounded, 'Compte protégé contre les intrusions',
          AppColors.success),
      (Icons.notifications_active_rounded, 'Alerte en temps réel sur chaque connexion',
          AppColors.warning),
      (Icons.phonelink_lock_rounded, 'Code unique renouvelé toutes les 30 secondes',
          AppColors.primary),
      (Icons.language_rounded, 'Compatible Google Authenticator, Authy...',
          AppColors.info),
    ];
    return items
        .map((item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: item.$3.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.$1, color: item.$3, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textOnDark
                            : AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }
}

// ── Step 1: QR Code ───────────────────────────────────────────────────────────
class _StepQR extends StatelessWidget {
  final bool isDark;
  final String secret;
  final bool secretRevealed;
  final VoidCallback onReveal;

  const _StepQR({
    required this.isDark,
    required this.secret,
    required this.secretRevealed,
    required this.onReveal,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(AppConstants.radius2XL),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              Text(
                '1. Scannez ce QR Code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color:
                      isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ouvrez Google Authenticator, Authy ou une autre app 2FA et scannez le code ci-dessous.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: CustomPaint(
                    painter: _QRPainter(),
                  ),
                ),
              ).animate().scale(
                  begin: const Offset(0.85, 0.85),
                  duration: 400.ms,
                  curve: Curves.easeOut),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 16),

        // Manual key section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
            border: Border.all(
                color:
                    isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '2. Ou entrez la clé manuellement',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color:
                      isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: secretRevealed ? null : onReveal,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: secretRevealed
                      ? Row(
                          children: [
                            Expanded(
                              child: Text(
                                secret,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(
                                    ClipboardData(text: secret));
                                Get.snackbar(
                                  'Copié !',
                                  'Clé secrète copiée dans le presse-papier',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor:
                                      AppColors.success.withOpacity(0.9),
                                  colorText: Colors.white,
                                  margin: const EdgeInsets.all(16),
                                  borderRadius: 12,
                                );
                              },
                              child: const Icon(Icons.copy_rounded,
                                  color: AppColors.primary, size: 18),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.visibility_outlined,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Appuyez pour révéler la clé',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary.withOpacity(0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 12),
        _InfoBox(
          icon: Icons.info_outline_rounded,
          text:
              'Conservez cette clé secrète en lieu sûr. Elle vous permettra de récupérer l\'accès à votre compte si vous changez d\'appareil.',
          isDark: isDark,
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ── Step 2: Verify code ───────────────────────────────────────────────────────
class _StepVerify extends StatelessWidget {
  final bool isDark;
  final List<TextEditingController> ctrls;
  final List<FocusNode> nodes;
  final bool hasError;
  final bool isLoading;
  final void Function(int, String) onChanged;

  const _StepVerify({
    required this.isDark,
    required this.ctrls,
    required this.nodes,
    required this.hasError,
    required this.isLoading,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(AppConstants.radius2XL),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phonelink_lock_rounded,
                    color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'Entrez le code de votre app',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color:
                      isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ouvrez votre application d\'authentification et entrez le code à 6 chiffres pour confirmer la configuration.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (i) => _OtpBox(
                  controller: ctrls[i],
                  focusNode: nodes[i],
                  hasError: hasError,
                  isDark: isDark,
                  onChanged: (v) => onChanged(i, v),
                )),
              ),
              if (hasError) ...[
                const SizedBox(height: 14),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Code invalide. Vérifiez votre application.',
                      style: TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ],
                ).animate().shakeX(),
              ],
            ],
          ),
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 16),
        // Demo hint
        Obx(() {
          final svc = TwoFAService.to;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.warning.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    color: AppColors.warning, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Code démo (se renouvelle en ${svc.secondsLeft.value}s)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        svc.currentCode.value,
                        style: const TextStyle(
                          fontSize: 20,
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
          );
        }).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ── OTP box ───────────────────────────────────────────────────────────────────
class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode
        .addListener(() => setState(() => _focused = widget.focusNode.hasFocus));
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.hasError
        ? AppColors.error
        : _focused
            ? AppColors.primary
            : (widget.isDark ? AppColors.borderDark : AppColors.borderLight);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 42,
      height: 52,
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.surfaceDark : AppColors.grey50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: _focused ? 2 : 1.5),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
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
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: widget.hasError
              ? AppColors.error
              : (widget.isDark ? AppColors.textOnDark : AppColors.textPrimary),
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

// ── Info box ──────────────────────────────────────────────────────────────────
class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _InfoBox(
      {required this.icon, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fake QR code painter ──────────────────────────────────────────────────────
class _QRPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..style = PaintingStyle.fill;

    final cell = size.width / 25;
    final rng = Random(0xBA2024);

    // Draw finder patterns (3 corners)
    _drawFinder(canvas, paint, 0, 0, cell);
    _drawFinder(canvas, paint, 18, 0, cell);
    _drawFinder(canvas, paint, 0, 18, cell);

    // Draw timing patterns
    for (var i = 8; i < 17; i++) {
      if (i % 2 == 0) {
        canvas.drawRect(Rect.fromLTWH(i * cell, 6 * cell, cell, cell), paint);
        canvas.drawRect(Rect.fromLTWH(6 * cell, i * cell, cell, cell), paint);
      }
    }

    // Draw random data modules (avoiding finder pattern areas)
    for (var row = 0; row < 25; row++) {
      for (var col = 0; col < 25; col++) {
        if (_isFinderArea(row, col)) continue;
        if (rng.nextDouble() > 0.5) {
          canvas.drawRect(
            Rect.fromLTWH(col * cell, row * cell, cell, cell),
            paint,
          );
        }
      }
    }

    // Brand mark in center
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: cell * 5,
            height: cell * 5),
        Radius.circular(cell * 0.8),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: cell * 4.2,
            height: cell * 4.2),
        Radius.circular(cell * 0.6),
      ),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF07C00), Color(0xFFD46A00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: cell * 4,
            height: cell * 4)),
    );
  }

  bool _isFinderArea(int row, int col) {
    if (row < 8 && col < 8) return true;
    if (row < 8 && col > 16) return true;
    if (row > 16 && col < 8) return true;
    return false;
  }

  void _drawFinder(
      Canvas canvas, Paint paint, int startCol, int startRow, double cell) {
    // Outer 7x7
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            startCol * cell, startRow * cell, 7 * cell, 7 * cell),
        Radius.circular(cell * 0.5),
      ),
      paint,
    );
    // White 5x5
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            (startCol + 1) * cell,
            (startRow + 1) * cell,
            5 * cell,
            5 * cell),
        Radius.circular(cell * 0.3),
      ),
      Paint()..color = Colors.white,
    );
    // Inner 3x3
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            (startCol + 2) * cell,
            (startRow + 2) * cell,
            3 * cell,
            3 * cell),
        Radius.circular(cell * 0.2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
