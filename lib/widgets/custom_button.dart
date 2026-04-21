import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

enum ButtonVariant { primary, secondary, outline, ghost, danger }
enum ButtonSize { sm, md, lg }

class CustomButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isLoading;
  final bool fullWidth;
  final Gradient? gradient;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.md,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.fullWidth = true,
    this.gradient,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.0,
      upperBound: 0.05,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _height {
    switch (widget.size) {
      case ButtonSize.sm:
        return 40;
      case ButtonSize.md:
        return 52;
      case ButtonSize.lg:
        return 60;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case ButtonSize.sm:
        return 13;
      case ButtonSize.md:
        return 15;
      case ButtonSize.lg:
        return 17;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          height: _height,
          child: _buildButton(isDisabled),
        ),
      ),
    );
  }

  Widget _buildButton(bool isDisabled) {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return _gradientButton(isDisabled);
      case ButtonVariant.secondary:
        return _secondaryButton(isDisabled);
      case ButtonVariant.outline:
        return _outlineButton(isDisabled);
      case ButtonVariant.ghost:
        return _ghostButton(isDisabled);
      case ButtonVariant.danger:
        return _dangerButton(isDisabled);
    }
  }

  Widget _gradientButton(bool isDisabled) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isDisabled
            ? LinearGradient(
                colors: [AppColors.grey300, AppColors.grey300],
              )
            : (widget.gradient ?? AppColors.primaryGradient),
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        boxShadow: isDisabled
            ? []
            : [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: _buttonContent(Colors.white, isDisabled),
    );
  }

  Widget _secondaryButton(bool isDisabled) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDisabled
            ? AppColors.grey200
            : AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
      ),
      child: _buttonContent(
        isDisabled ? AppColors.grey400 : AppColors.primary,
        isDisabled,
      ),
    );
  }

  Widget _outlineButton(bool isDisabled) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: isDisabled ? AppColors.grey300 : AppColors.primary,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
      ),
      child: _buttonContent(
        isDisabled ? AppColors.grey400 : AppColors.primary,
        isDisabled,
      ),
    );
  }

  Widget _ghostButton(bool isDisabled) {
    return _buttonContent(
      isDisabled ? AppColors.grey400 : AppColors.primary,
      isDisabled,
    );
  }

  Widget _dangerButton(bool isDisabled) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isDisabled
            ? LinearGradient(colors: [AppColors.grey300, AppColors.grey300])
            : const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              ),
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        boxShadow: isDisabled
            ? []
            : [
                BoxShadow(
                  color: AppColors.error.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: _buttonContent(Colors.white, isDisabled),
    );
  }

  Widget _buttonContent(Color textColor, bool isDisabled) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : widget.onPressed,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize:
                widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (widget.isLoading) ...[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 10),
              ] else ...[
                if (widget.prefixIcon != null) ...[
                  widget.prefixIcon!,
                  const SizedBox(width: 8),
                ],
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.w600,
                  color: isDisabled && widget.variant == ButtonVariant.primary
                      ? AppColors.grey500
                      : textColor,
                  letterSpacing: 0.2,
                ),
              ),
              if (widget.suffixIcon != null && !widget.isLoading) ...[
                const SizedBox(width: 8),
                widget.suffixIcon!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
