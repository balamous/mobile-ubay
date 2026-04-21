import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/formatters.dart';
import 'custom_button.dart';

class SuccessOverlay extends StatefulWidget {
  final String title;
  final String subtitle;
  final double? amount;
  final String? reference;
  final VoidCallback? onDone;

  const SuccessOverlay({
    super.key,
    required this.title,
    required this.subtitle,
    this.amount,
    this.reference,
    this.onDone,
  });

  static Future<void> show({
    required String title,
    required String subtitle,
    double? amount,
    String? reference,
    VoidCallback? onDone,
  }) async {
    await Get.dialog(
      SuccessOverlay(
        title: title,
        subtitle: subtitle,
        amount: amount,
        reference: reference,
        onDone: onDone,
      ),
      barrierColor: Colors.black.withOpacity(0.6),
    );
  }

  @override
  State<SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<SuccessOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppConstants.animSlow,
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(AppConstants.radius3XL),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: AppColors.greenGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.white : AppColors.grey900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.grey400 : AppColors.grey500,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.amount != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                  ),
                  child: Text(
                    AppFormatters.formatCurrency(widget.amount!),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
              if (widget.reference != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Réf: ${widget.reference}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.grey500 : AppColors.grey400,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              const SizedBox(height: 28),
              CustomButton(
                label: 'Terminé',
                onPressed: () {
                  Get.back();
                  widget.onDone?.call();
                },
                gradient: AppColors.primaryGradient,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// PIN entry dialog
class PinEntryDialog extends StatefulWidget {
  final String title;
  final Function(String pin) onConfirm;

  const PinEntryDialog({
    super.key,
    required this.title,
    required this.onConfirm,
  });

  static Future<bool?> show({
    required String title,
    required Function(String pin) onConfirm,
  }) async {
    return await Get.dialog<bool>(
      PinEntryDialog(title: title, onConfirm: onConfirm),
      barrierColor: Colors.black.withOpacity(0.6),
    );
  }

  @override
  State<PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<PinEntryDialog> {
  String _pin = '';
  bool _hasError = false;
  static const int _pinLength = 4;

  void _onKey(String key) {
    if (_pin.length < _pinLength) {
      setState(() {
        _pin += key;
        _hasError = false;
      });
      if (_pin.length == _pinLength) {
        Future.delayed(const Duration(milliseconds: 200), _submit);
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  void _submit() {
    widget.onConfirm(_pin);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: BorderRadius.circular(AppConstants.radius3XL),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.grey900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Entrez votre code PIN à 4 chiffres',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.grey400 : AppColors.grey500,
              ),
            ),
            const SizedBox(height: 28),
            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (i) {
                final filled = i < _pin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hasError
                        ? AppColors.error
                        : filled
                            ? AppColors.primary
                            : Colors.transparent,
                    border: Border.all(
                      color: _hasError
                          ? AppColors.error
                          : filled
                              ? AppColors.primary
                              : AppColors.grey300,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            if (_hasError) ...[
              const SizedBox(height: 12),
              Text(
                'PIN incorrect. Réessayez.',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 28),
            // Numpad
            _buildNumpad(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad(bool isDark) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 72, height: 56);
              return GestureDetector(
                onTap: () => key == 'del' ? _onDelete() : _onKey(key),
                child: Container(
                  width: 72,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.grey800 : AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  ),
                  alignment: Alignment.center,
                  child: key == 'del'
                      ? Icon(
                          Icons.backspace_outlined,
                          size: 20,
                          color: isDark ? AppColors.grey300 : AppColors.grey700,
                        )
                      : Text(
                          key,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.white : AppColors.grey900,
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
