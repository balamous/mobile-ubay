import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/biometric_service.dart';
import '../../../services/twofa_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/input_field.dart';

// ── Country dial codes ────────────────────────────────────────────────────────
class CountryCode {
  final String flag;
  final String name;
  final String code;
  const CountryCode(this.flag, this.name, this.code);
}

const _countries = [
  CountryCode('🇬🇳', 'Guinée', '+224'),
  CountryCode('🇸🇳', 'Sénégal', '+221'),
  CountryCode('🇨🇮', 'Côte d\'Ivoire', '+225'),
  CountryCode('🇲🇱', 'Mali', '+223'),
  CountryCode('🇧🇫', 'Burkina Faso', '+226'),
  CountryCode('🇬🇼', 'Guinée-Bissau', '+245'),
  CountryCode('🇸🇱', 'Sierra Leone', '+232'),
  CountryCode('🇱🇷', 'Libéria', '+231'),
  CountryCode('🇫🇷', 'France', '+33'),
  CountryCode('🇺🇸', 'États-Unis', '+1'),
];

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  CountryCode _selectedCountry = _countries.first;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authService = AuthService.to;
    final phone = _phoneCtrl.text.trim();
    final password = _passCtrl.text.trim();

    final success = await authService.signIn(phone, password);

    if (success) {
      // If 2FA enabled -> verify first
      final twofa = TwoFAService.to;
      if (twofa.is2FAEnabled.value) {
        Get.toNamed(AppRoutes.twoFAVerify);
      } else {
        Get.offAllNamed(AppRoutes.dashboard);
      }
    } else {
      // Show error message
      Get.snackbar(
        'Erreur de connexion',
        authService.error.value,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    }
  }

  Future<void> _biometricLogin() async {
    final bio = BiometricService.to;
    if (!bio.isEnabled.value || !bio.isAvailable.value) return;

    final result = await bio.authenticate(
      reason: 'Connectez-vous à uBAY avec votre biométrie',
    );

    if (result == BiometricResult.success) {
      final twofa = TwoFAService.to;
      if (twofa.is2FAEnabled.value) {
        Get.toNamed(AppRoutes.twoFAVerify);
      } else {
        Get.offAllNamed(AppRoutes.dashboard);
      }
    } else if (result == BiometricResult.failed) {
      Get.snackbar(
        'Échec biométrique',
        'Authentification refusée. Utilisez votre mot de passe.',
        backgroundColor: AppColors.error.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  void _showCountryPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CountryPickerSheet(
        countries: _countries,
        selected: _selectedCountry,
        isDark: isDark,
        onSelect: (c) => setState(() => _selectedCountry = c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Hero ────────────────────────────────────────────────────
            _buildHero(isDark, size),

            // ── Form card ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connexion',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.white : AppColors.textPrimary,
                        letterSpacing: -0.8,
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 4),
                    Text(
                      'Entrez votre numéro de téléphone',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary,
                      ),
                    ).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 28),

                    // ── Phone field ────────────────────────────────────
                    _PhoneField(
                      controller: _phoneCtrl,
                      selectedCountry: _selectedCountry,
                      isDark: isDark,
                      onCountryTap: _showCountryPicker,
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 16),

                    // ── Password field ─────────────────────────────────
                    InputField(
                      label: 'Mot de passe',
                      hint: '••••••••',
                      controller: _passCtrl,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      onSubmitted: (_) => _login(),
                      validator: (v) =>
                          (v?.isEmpty ?? true) ? 'Mot de passe requis' : null,
                    ).animate().fadeIn(delay: 250.ms),

                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 24),
                    CustomButton(
                      label: 'Se connecter',
                      isLoading: _isLoading,
                      onPressed: _login,
                      gradient: AppColors.primaryGradient,
                    ).animate().fadeIn(delay: 350.ms),

                    const SizedBox(height: 16),

                    // ── Biometric login ────────────────────────────────
                    Obx(() {
                      final bio = BiometricService.to;
                      if (!bio.isEnabled.value || !bio.isAvailable.value) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'ou',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textOnDarkSecondary
                                        : AppColors.textTertiary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: _biometricLogin,
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.cardDark
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radiusLG),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      bio.isFace
                                          ? Icons.face_rounded
                                          : Icons.fingerprint_rounded,
                                      color: AppColors.primary,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Connexion avec ${bio.kindLabel}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.textOnDark
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 32),

                    // ── Sign up link ───────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pas encore de compte ? ',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textOnDarkSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Get.toNamed(AppRoutes.register),
                          child: const Text(
                            'S\'inscrire',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(bool isDark, Size size) {
    return Container(
      width: double.infinity,
      height: size.height * 0.34,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 38,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(
              'uBAY',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: isDark ? AppColors.white : AppColors.textPrimary,
                letterSpacing: -1,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 6),
            Text(
              'Votre plateforme financière de confiance',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
              ),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
            child: Divider(
                color: isDark ? AppColors.borderDark : AppColors.borderLight)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou continuer avec',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textOnDarkSecondary
                  : AppColors.textTertiary,
            ),
          ),
        ),
        Expanded(
            child: Divider(
                color: isDark ? AppColors.borderDark : AppColors.borderLight)),
      ],
    );
  }

  Widget _buildSocialRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _SocialBtn(
            label: 'Google',
            icon: Icons.g_mobiledata_rounded,
            color: const Color(0xFFDB4437),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialBtn(
            label: 'Facebook',
            icon: Icons.facebook_rounded,
            color: const Color(0xFF1877F2),
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

// ── Phone input ───────────────────────────────────────────────────────────────
class _PhoneField extends StatefulWidget {
  final TextEditingController controller;
  final CountryCode selectedCountry;
  final bool isDark;
  final VoidCallback onCountryTap;

  const _PhoneField({
    required this.controller,
    required this.selectedCountry,
    required this.isDark,
    required this.onCountryTap,
  });

  @override
  State<_PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<_PhoneField> {
  final _focus = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _isFocused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Numéro de téléphone',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _isFocused
                ? AppColors.primary
                : widget.isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.12),
                      blurRadius: 0,
                      spreadRadius: 3,
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              // ── Country selector ────────────────────────────────────
              GestureDetector(
                onTap: widget.onCountryTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: widget.isDark ? AppColors.cardDark : AppColors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    border: Border.all(
                      color: _isFocused
                          ? AppColors.primary
                          : widget.isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                      width: _isFocused ? 2 : 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.selectedCountry.flag,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.selectedCountry.code,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: widget.isDark
                              ? AppColors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: widget.isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              // ── Separator ───────────────────────────────────────────
              Container(
                width: 1,
                height: 54,
                color: _isFocused
                    ? AppColors.primary
                    : widget.isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
              ),
              // ── Phone number input ──────────────────────────────────
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focus,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        widget.isDark ? AppColors.white : AppColors.textPrimary,
                    letterSpacing: 1,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Numéro requis';
                    if (v.length < 7) return 'Numéro invalide';
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: '77 000 00 00',
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color:
                          widget.isDark ? AppColors.grey600 : AppColors.grey300,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1,
                    ),
                    filled: true,
                    fillColor:
                        widget.isDark ? AppColors.cardDark : AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      borderSide: BorderSide(
                        color: _isFocused
                            ? AppColors.primary
                            : widget.isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                        width: _isFocused ? 2 : 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      borderSide: BorderSide(
                        color: widget.isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      borderSide:
                          BorderSide(color: AppColors.primary, width: 2),
                    ),
                    errorBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      borderSide:
                          BorderSide(color: AppColors.error, width: 1.5),
                    ),
                    focusedErrorBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      borderSide: BorderSide(color: AppColors.error, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Country picker sheet ──────────────────────────────────────────────────────
class _CountryPickerSheet extends StatefulWidget {
  final List<CountryCode> countries;
  final CountryCode selected;
  final bool isDark;
  final void Function(CountryCode) onSelect;

  const _CountryPickerSheet({
    required this.countries,
    required this.selected,
    required this.isDark,
    required this.onSelect,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _search = '';

  List<CountryCode> get _filtered => widget.countries
      .where((c) =>
          c.name.toLowerCase().contains(_search.toLowerCase()) ||
          c.code.contains(_search))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radius2XL)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Choisir un pays',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: widget.isDark ? AppColors.white : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Rechercher un pays...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.grey400, size: 20),
                filled: true,
                fillColor: widget.isDark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final c = _filtered[i];
                final isSelected = c.code == widget.selected.code;
                return GestureDetector(
                  onTap: () {
                    widget.onSelect(c);
                    Get.back();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: AppColors.primary.withOpacity(0.3))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Text(c.flag, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            c.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark
                                  ? AppColors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          c.code,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.primary
                                : widget.isDark
                                    ? AppColors.textOnDarkSecondary
                                    : AppColors.textSecondary,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary, size: 18),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Social button ─────────────────────────────────────────────────────────────
class _SocialBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SocialBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
