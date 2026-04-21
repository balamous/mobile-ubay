import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../utils/formatters.dart';
import '../../services/biometric_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BiometricGuard — point d'entrée unique
// ─────────────────────────────────────────────────────────────────────────────

class BiometricGuard {
  BiometricGuard._();

  /// Affiche la feuille de confirmation biométrique (ou PIN en fallback).
  /// Retourne `true` si l'utilisateur est confirmé, `false` sinon.
  static Future<bool> show(
    BuildContext context, {
    required String action,
    required double amount,
    String? recipient,
    IconData actionIcon = Icons.lock_rounded,
    Color actionColor = AppColors.primary,
  }) async {
    final bio = BiometricService.to;

    if (bio.isAvailable.value) {
      final result = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        enableDrag: false,
        builder: (_) => _BiometricSheet(
          action: action,
          amount: amount,
          recipient: recipient,
          actionIcon: actionIcon,
          actionColor: actionColor,
        ),
      );
      return result ?? false;
    } else {
      // Fallback PIN
      final result = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _PinFallbackSheet(
          action: action,
          amount: amount,
          recipient: recipient,
          actionIcon: actionIcon,
          actionColor: actionColor,
        ),
      );
      return result ?? false;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Biometric Confirmation Sheet
// ─────────────────────────────────────────────────────────────────────────────

enum _BioState { idle, scanning, success, error }

class _BiometricSheet extends StatefulWidget {
  final String action;
  final double amount;
  final String? recipient;
  final IconData actionIcon;
  final Color actionColor;

  const _BiometricSheet({
    required this.action,
    required this.amount,
    required this.recipient,
    required this.actionIcon,
    required this.actionColor,
  });

  @override
  State<_BiometricSheet> createState() => _BiometricSheetState();
}

class _BiometricSheetState extends State<_BiometricSheet>
    with TickerProviderStateMixin {
  final BiometricService _bio = BiometricService.to;

  _BioState _state = _BioState.idle;
  String? _errorMsg;
  int _failCount = 0;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _shakeCtrl;
  late Animation<double> _shake;
  late AnimationController _glowCtrl;
  late Animation<double> _glow;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulse = Tween(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _glow = Tween(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // Auto-déclenche après 600ms
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), _authenticate);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _shakeCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (!mounted) return;
    setState(() {
      _state = _BioState.scanning;
      _errorMsg = null;
    });

    final result = await _bio.authenticate(
      reason: 'Confirmez votre identité pour ${widget.action.toLowerCase()} de '
          '${AppFormatters.formatCurrency(widget.amount)}',
    );

    if (!mounted) return;

    switch (result) {
      case BiometricResult.success:
        setState(() => _state = _BioState.success);
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) Get.back(result: true);
        break;

      case BiometricResult.failed:
        _failCount++;
        HapticFeedback.vibrate();
        setState(() {
          _state = _BioState.error;
          _errorMsg = _failCount >= 3
              ? 'Trop d\'échecs. Utilisez votre PIN.'
              : 'Authentification échouée. Réessayez.';
        });
        _shakeCtrl.forward(from: 0);
        if (_failCount >= 3) {
          await Future.delayed(const Duration(milliseconds: 700));
          if (mounted) _switchToPin();
        }
        break;

      case BiometricResult.lockedOut:
        setState(() {
          _state = _BioState.error;
          _errorMsg = 'Biométrie verrouillée. Utilisez votre PIN.';
        });
        _shakeCtrl.forward(from: 0);
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) _switchToPin();
        break;

      default:
        setState(() => _state = _BioState.idle);
    }
  }

  void _switchToPin() {
    Get.back(result: false);
    // Redirige vers le fallback PIN
    showModalBottomSheet<bool>(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PinFallbackSheet(
        action: widget.action,
        amount: widget.amount,
        recipient: widget.recipient,
        actionIcon: widget.actionIcon,
        actionColor: widget.actionColor,
      ),
    ).then((ok) {
      if (ok == true) Get.back(result: true);
    });
  }

  Color get _stateColor => switch (_state) {
        _BioState.success => AppColors.success,
        _BioState.error => AppColors.error,
        _BioState.scanning => widget.actionColor,
        _ => AppColors.grey400,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ────────────────────────────────────────
              _DragHandle(isDark: _isDark),
              const SizedBox(height: 8),

              // ── Title ──────────────────────────────────────────────
              _SheetTitle(
                action: widget.action,
                actionIcon: widget.actionIcon,
                actionColor: widget.actionColor,
                isDark: _isDark,
              ),
              const SizedBox(height: 20),

              // ── Amount card ────────────────────────────────────────
              _AmountCard(
                amount: widget.amount,
                recipient: widget.recipient,
                actionColor: widget.actionColor,
                isDark: _isDark,
              ),
              const SizedBox(height: 28),

              // ── Biometric icon ────────────────────────────────────
              AnimatedBuilder(
                animation:
                    Listenable.merge([_pulseCtrl, _shakeCtrl, _glowCtrl]),
                builder: (_, __) {
                  return Transform.translate(
                    offset: Offset(
                      _state == _BioState.error ? _shake.value : 0,
                      0,
                    ),
                    child: _buildBiometricRings(),
                  );
                },
              ),
              const SizedBox(height: 20),

              // ── Status label ───────────────────────────────────────
              _StatusLabel(state: _state, errorMsg: _errorMsg, isDark: _isDark),
              const SizedBox(height: 24),

              // ── Buttons ────────────────────────────────────────────
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricRings() {
    final isFace = _bio.isFace;
    final color = _stateColor;
    final isScanning = _state == _BioState.scanning;
    final scale = isScanning ? _pulse.value : 1.0;
    final glowOpacity = isScanning ? _glow.value * 0.5 : 0.2;

    return Transform.scale(
      scale: scale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 136,
            height: 136,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: isScanning
                  ? [
                      BoxShadow(
                        color: color.withOpacity(glowOpacity),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ]
                  : [],
            ),
          ),
          // Middle ring
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
          // Inner circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.5), width: 2.5),
              boxShadow: _state == _BioState.success
                  ? [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.6),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              _state == _BioState.success
                  ? Icons.check_rounded
                  : _state == _BioState.error
                      ? Icons.close_rounded
                      : isFace
                          ? Icons.face_rounded
                          : Icons.fingerprint_rounded,
              color: color,
              size: 38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    if (_state == _BioState.scanning) {
      return Text(
        'Ne bougez pas...',
        style: TextStyle(
          fontSize: 13,
          color:
              _isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
        ),
      );
    }
    if (_state == _BioState.success) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (_state == _BioState.error) ...[
          GestureDetector(
            onTap: _authenticate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'Réessayer',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text(
            'Annuler',
            style: TextStyle(
              fontSize: 14,
              color: _isDark ? AppColors.grey500 : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PIN Fallback Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PinFallbackSheet extends StatefulWidget {
  final String action;
  final double amount;
  final String? recipient;
  final IconData actionIcon;
  final Color actionColor;

  const _PinFallbackSheet({
    required this.action,
    required this.amount,
    required this.recipient,
    required this.actionIcon,
    required this.actionColor,
  });

  @override
  State<_PinFallbackSheet> createState() => _PinFallbackSheetState();
}

class _PinFallbackSheetState extends State<_PinFallbackSheet>
    with SingleTickerProviderStateMixin {
  final List<String> _digits = [];
  bool _hasError = false;
  int _attempts = 0;

  late AnimationController _shakeCtrl;
  late Animation<double> _shake;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _addDigit(String d) {
    if (_digits.length >= 4) return;
    setState(() {
      _digits.add(d);
      _hasError = false;
    });
    HapticFeedback.selectionClick();
    if (_digits.length == 4) _validate();
  }

  void _removeDigit() {
    if (_digits.isEmpty) return;
    setState(() => _digits.removeLast());
    HapticFeedback.selectionClick();
  }

  Future<void> _validate() async {
    final pin = _digits.join();
    await Future.delayed(const Duration(milliseconds: 200));
    if (pin == AppConstants.mockPin) {
      HapticFeedback.heavyImpact();
      Get.back(result: true);
    } else {
      _attempts++;
      HapticFeedback.vibrate();
      setState(() {
        _hasError = true;
        _digits.clear();
      });
      _shakeCtrl.forward(from: 0);
      if (_attempts >= 3) {
        await Future.delayed(const Duration(milliseconds: 600));
        Get.back(result: false);
        Get.snackbar(
          'PIN bloqué',
          'Trop de tentatives incorrectes.',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: _isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                24, 12, 24, 12 + MediaQuery.of(context).viewPadding.bottom),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DragHandle(isDark: _isDark),
                  const SizedBox(height: 8),
                  _SheetTitle(
                    action: widget.action,
                    actionIcon: widget.actionIcon,
                    actionColor: widget.actionColor,
                    isDark: _isDark,
                  ),
                  const SizedBox(height: 16),
                  _AmountCard(
                    amount: widget.amount,
                    recipient: widget.recipient,
                    actionColor: widget.actionColor,
                    isDark: _isDark,
                  ),
                  const SizedBox(height: 24),
                  // PIN label
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_rounded,
                          size: 14,
                          color: _isDark
                              ? AppColors.textOnDarkSecondary
                              : AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Entrez votre code PIN',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _isDark
                              ? AppColors.textOnDarkSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // PIN dots
                  AnimatedBuilder(
                    animation: _shakeCtrl,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(_shake.value, 0),
                      child: _buildPinDots(),
                    ),
                  ),
                  if (_hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'PIN incorrect — tentative $_attempts/3',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ).animate().shakeX(),
                    ),
                  const SizedBox(height: 24),
                  // Keypad
                  _buildKeypad(),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isDark
                            ? AppColors.grey500
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final filled = i < _digits.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hasError
                ? AppColors.error
                : filled
                    ? widget.actionColor
                    : Colors.transparent,
            border: Border.all(
              color: _hasError
                  ? AppColors.error
                  : filled
                      ? widget.actionColor
                      : (_isDark ? AppColors.grey600 : AppColors.grey300),
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 80, height: 56);
              return GestureDetector(
                onTap: () => key == '⌫' ? _removeDigit() : _addDigit(key),
                child: Container(
                  width: 80,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: _isDark
                        ? AppColors.surfaceDark
                        : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Center(
                    child: key == '⌫'
                        ? Icon(
                            Icons.backspace_outlined,
                            size: 20,
                            color: _isDark
                                ? AppColors.textOnDarkSecondary
                                : AppColors.textSecondary,
                          )
                        : Text(
                            key,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: _isDark
                                  ? AppColors.textOnDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  final bool isDark;
  const _DragHandle({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.grey600 : AppColors.grey300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  final String action;
  final IconData actionIcon;
  final Color actionColor;
  final bool isDark;

  const _SheetTitle({
    required this.action,
    required this.actionIcon,
    required this.actionColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: actionColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(actionIcon, color: actionColor, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirmer le $action',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Vérification d\'identité requise',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

class _AmountCard extends StatelessWidget {
  final double amount;
  final String? recipient;
  final Color actionColor;
  final bool isDark;

  const _AmountCard({
    required this.amount,
    required this.recipient,
    required this.actionColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: actionColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: actionColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            AppFormatters.formatCurrency(amount),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: actionColor,
              letterSpacing: -0.5,
            ),
          ),
          if (recipient != null && recipient!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              recipient!,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    ).animate().scale(
          begin: const Offset(0.95, 0.95),
          duration: 350.ms,
          curve: Curves.easeOut,
        );
  }
}

class _StatusLabel extends StatelessWidget {
  final _BioState state;
  final String? errorMsg;
  final bool isDark;

  const _StatusLabel({
    required this.state,
    required this.errorMsg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bio = BiometricService.to;
    final label = bio.kindLabel;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Column(
        key: ValueKey(state),
        children: [
          Text(
            switch (state) {
              _BioState.idle => 'Appuyez sur l\'icône pour confirmer',
              _BioState.scanning => 'Authentification en cours...',
              _BioState.success => 'Identité confirmée !',
              _BioState.error => errorMsg ?? 'Échec de l\'authentification',
            },
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: switch (state) {
                _BioState.success => AppColors.success,
                _BioState.error => AppColors.error,
                _ => isDark ? AppColors.textOnDark : AppColors.textPrimary,
              },
            ),
          ),
          if (state == _BioState.idle || state == _BioState.scanning) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.surfaceDark : AppColors.grey100),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    bio.isFace
                        ? Icons.face_retouching_natural_rounded
                        : Icons.fingerprint_rounded,
                    size: 13,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textOnDarkSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
