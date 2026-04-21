import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/input_field.dart';
import '../../../services/auth_service.dart';

// ── Country data ──────────────────────────────────────────────────────────────
class _Country {
  final String flag;
  final String name;
  final String dialCode;
  final int maxLength;
  const _Country(this.flag, this.name, this.dialCode, this.maxLength);
}

const _countries = [
  _Country('🇬🇳', 'Guinée', '+224', 9),
  _Country('🇸🇳', 'Sénégal', '+221', 9),
  _Country('🇨🇮', 'Côte d\'Ivoire', '+225', 10),
  _Country('🇲🇱', 'Mali', '+223', 8),
  _Country('🇧🇫', 'Burkina Faso', '+226', 8),
  _Country('🇬🇼', 'Guinée-Bissau', '+245', 9),
  _Country('🇸🇱', 'Sierra Leone', '+232', 8),
  _Country('🇱🇷', 'Libéria', '+231', 7),
  _Country('🇫🇷', 'France', '+33', 9),
  _Country('🇺🇸', 'États-Unis', '+1', 10),
];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  _Country _selectedCountry = _countries.first;
  bool _isLoading = false;
  bool _acceptTerms = false;
  bool _phoneFocused = false;
  final _phoneFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(() {
      setState(() => _phoneFocused = _phoneFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptTerms) {
      Get.snackbar(
        'Conditions requises',
        'Veuillez accepter les conditions d\'utilisation',
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Numéro requis',
        'Veuillez entrer votre numéro de téléphone',
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call API for registration
      final authService = AuthService.to;
      final success = await authService.signUp(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      setState(() => _isLoading = false);

      if (success) {
        // Show success message
        Get.snackbar(
          'Inscription réussie',
          'Votre compte a été créé avec succès',
          backgroundColor: AppColors.success.withOpacity(0.1),
          colorText: AppColors.success,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );

        // Navigate to OTP screen with phone info
        Get.toNamed(
          AppRoutes.otp,
          arguments: {
            'phone': _phoneCtrl.text.trim(),
            'dialCode': _selectedCountry.dialCode,
          },
        );
      } else {
        // Show error message
        Get.snackbar(
          'Erreur d\'inscription',
          authService.error.value,
          backgroundColor: AppColors.error.withOpacity(0.1),
          colorText: AppColors.error,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue lors de l\'inscription',
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CountryPickerSheet(
        selected: _selectedCountry,
        onSelect: (c) => setState(() => _selectedCountry = c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 200,
            color: AppColors.accent,
          ),
          SafeArea(
            child: Column(
              children: [
                // ── App bar ──────────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      // Bouton retour circulaire
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
                      const SizedBox(width: 12),
                      // Titre + sous-titre
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Créer un compte',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Rejoignez uBAY en quelques étapes',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Icône identité
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.12),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1.5),
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Form
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name row
                            Row(
                              children: [
                                Expanded(
                                  child: InputField(
                                    label: 'Prénom',
                                    hint: 'Aminata',
                                    controller: _firstNameCtrl,
                                    validator: (v) =>
                                        (v?.isEmpty ?? true) ? 'Requis' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InputField(
                                    label: 'Nom',
                                    hint: 'Diallo',
                                    controller: _lastNameCtrl,
                                    validator: (v) =>
                                        (v?.isEmpty ?? true) ? 'Requis' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Email
                            InputField(
                              label: 'Adresse email',
                              hint: 'votre@email.com',
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                size: 20,
                                color: AppColors.grey400,
                              ),
                              validator: (v) =>
                                  (v?.isEmpty ?? true) ? 'Requis' : null,
                            ),
                            const SizedBox(height: 16),

                            // Phone field label
                            Text(
                              'Numéro de téléphone',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _phoneFocused
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.textOnDarkSecondary
                                        : AppColors.textSecondary),
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Phone field (country code + number)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _phoneFocused
                                      ? AppColors.primary
                                      : (isDark
                                          ? AppColors.borderDark
                                          : AppColors.borderLight),
                                  width: _phoneFocused ? 2 : 1.5,
                                ),
                                boxShadow: _phoneFocused
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withOpacity(0.15),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  // Country selector
                                  GestureDetector(
                                    onTap: _showCountryPicker,
                                    child: Container(
                                      height: 52,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.surfaceDark
                                            : AppColors.grey50,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(11),
                                          bottomLeft: Radius.circular(11),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            _selectedCountry.flag,
                                            style:
                                                const TextStyle(fontSize: 20),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _selectedCountry.dialCode,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? AppColors.textOnDark
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 18,
                                            color: AppColors.grey400,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Divider
                                  Container(
                                    width: 1,
                                    height: 28,
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight,
                                  ),
                                  // Phone number input
                                  Expanded(
                                    child: TextField(
                                      controller: _phoneCtrl,
                                      focusNode: _phoneFocus,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(
                                            _selectedCountry.maxLength),
                                      ],
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? AppColors.textOnDark
                                            : AppColors.textPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '7X XXX XX XX',
                                        hintStyle: TextStyle(
                                          color: AppColors.grey400,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Password
                            InputField(
                              label: 'Mot de passe',
                              hint: '••••••••',
                              controller: _passCtrl,
                              obscureText: true,
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 20,
                                color: AppColors.grey400,
                              ),
                              validator: (v) => (v?.length ?? 0) < 6
                                  ? 'Min. 6 caractères'
                                  : null,
                            ),
                            const SizedBox(height: 20),

                            // Terms checkbox
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _acceptTerms = !_acceptTerms),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: _acceptTerms
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _acceptTerms
                                            ? AppColors.primary
                                            : AppColors.grey400,
                                        width: 2,
                                      ),
                                    ),
                                    child: _acceptTerms
                                        ? const Icon(Icons.check_rounded,
                                            color: Colors.white, size: 14)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        text: 'J\'accepte les ',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? AppColors.grey400
                                              : AppColors.grey600,
                                        ),
                                        children: const [
                                          TextSpan(
                                            text: 'Conditions d\'utilisation',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(text: ' et la '),
                                          TextSpan(
                                            text:
                                                'Politique de confidentialité',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            CustomButton(
                              label: 'Créer mon compte',
                              isLoading: _isLoading,
                              onPressed: _register,
                              gradient: AppColors.primaryGradient,
                            ),
                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Déjà un compte ? ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? AppColors.grey400
                                        : AppColors.grey500,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: Get.back,
                                  child: const Text(
                                    'Se connecter',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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

// ── Country picker bottom sheet ───────────────────────────────────────────────

class _CountryPickerSheet extends StatefulWidget {
  final _Country selected;
  final ValueChanged<_Country> onSelect;

  const _CountryPickerSheet({required this.selected, required this.onSelect});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _query = '';

  List<_Country> get _filtered => _countries
      .where((c) =>
          c.name.toLowerCase().contains(_query.toLowerCase()) ||
          c.dialCode.contains(_query))
      .toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Choisir le pays',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color:
                        isDark ? AppColors.textOnDark : AppColors.textPrimary,
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
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color:
                          isDark ? AppColors.grey400 : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Rechercher un pays...',
                hintStyle:
                    const TextStyle(color: AppColors.grey400, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.grey400, size: 20),
                filled: true,
                fillColor: isDark ? AppColors.cardDark : AppColors.grey50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Countries list
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final c = _filtered[i];
                final isSelected = c.dialCode == widget.selected.dialCode;
                return ListTile(
                  onTap: () {
                    widget.onSelect(c);
                    Get.back();
                  },
                  leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    c.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.textOnDark
                              : AppColors.textPrimary),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.dialCode,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
