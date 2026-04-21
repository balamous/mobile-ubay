import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../routes/app_routes.dart';
import '../../services/app_controller.dart';
import '../../services/biometric_service.dart';
import '../../services/twofa_service.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/custom_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appCtrl = AppController.to;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      body: Obx(() {
        final user = appCtrl.user.value;
        if (user == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              _buildHeader(context, user, appCtrl, isDark),
              // ── Stats ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStats(user, isDark),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 24),
              // ── KYC Badge ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildKycBanner(isDark),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 24),
              // ── Menu sections ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _MenuSection(
                      title: 'Compte',
                      isDark: isDark,
                      items: [
                        _MenuItem(
                          icon: Icons.person_outline_rounded,
                          label: 'Informations personnelles',
                          color: AppColors.primary,
                          isDark: isDark,
                          onTap: () => Get.toNamed(AppRoutes.personalInfo),
                        ),
                        _MenuItem(
                          icon: Icons.shield_outlined,
                          label: 'Sécurité & PIN',
                          color: AppColors.info,
                          isDark: isDark,
                          onTap: () => _showSecuritySheet(context, isDark),
                        ),
                        _MenuItem(
                          icon: Icons.verified_user_outlined,
                          label: 'Vérification KYC',
                          color: AppColors.success,
                          isDark: isDark,
                          trailing: _kycBadge(),
                        ),
                        _MenuItem(
                          icon: Icons.account_balance_outlined,
                          label: 'Comptes bancaires liés',
                          color: AppColors.accent,
                          isDark: isDark,
                          onTap: () {},
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 16),
                    _MenuSection(
                      title: 'Préférences',
                      isDark: isDark,
                      items: [
                        _MenuItem(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          color: AppColors.airtimeColor,
                          isDark: isDark,
                          onTap: () => Get.toNamed(AppRoutes.notifications),
                        ),
                        _MenuItem(
                          icon: isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          label: isDark ? 'Mode clair' : 'Mode sombre',
                          color: AppColors.grey600,
                          isDark: isDark,
                          trailing: _ThemeSwitch(appCtrl: appCtrl),
                        ),
                        _MenuItem(
                          icon: Icons.language_outlined,
                          label: 'Langue',
                          color: AppColors.servicesColor,
                          isDark: isDark,
                          trailing: Text(
                            'Français',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textOnDarkSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        _MenuItem(
                          icon: Icons.currency_exchange_rounded,
                          label: 'Devise',
                          color: AppColors.paymentColor,
                          isDark: isDark,
                          trailing: Text(
                            'GNF (Franc Guinéen)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textOnDarkSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 250.ms),
                    const SizedBox(height: 16),
                    _MenuSection(
                      title: 'Support',
                      isDark: isDark,
                      items: [
                        _MenuItem(
                          icon: Icons.help_outline_rounded,
                          label: 'Centre d\'aide',
                          color: AppColors.info,
                          isDark: isDark,
                          onTap: () {},
                        ),
                        _MenuItem(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Contacter le support',
                          color: AppColors.success,
                          isDark: isDark,
                          onTap: () {},
                        ),
                        _MenuItem(
                          icon: Icons.star_outline_rounded,
                          label: 'Noter l\'application',
                          color: AppColors.warning,
                          isDark: isDark,
                          onTap: () {},
                        ),
                        _MenuItem(
                          icon: Icons.info_outline_rounded,
                          label: 'À propos',
                          color: AppColors.grey500,
                          isDark: isDark,
                          trailing: Text(
                            'v1.0.0',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.grey500
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 24),
                    CustomButton(
                      label: 'Se déconnecter',
                      variant: ButtonVariant.danger,
                      prefixIcon: const Icon(Icons.logout_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => _confirmLogout(context, isDark),
                    ).animate().fadeIn(delay: 350.ms),
                    const SizedBox(height: 8),
                    Text(
                      'uBAY · Version 1.0.0',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            isDark ? AppColors.grey600 : AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(
      BuildContext context, dynamic user, AppController appCtrl, bool isDark) {
    if (user == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            children: [
              // Top bar
              Row(
                children: [
                  Text(
                    'Mon Profil',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.white : AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.notifications),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.backgroundDark
                            : AppColors.backgroundLight,
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              Icons.notifications_outlined,
                              size: 22,
                              color: isDark
                                  ? AppColors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.cardDark : AppColors.white,
                          width: 2.5,
                        ),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: Colors.white, size: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                user.fullName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.white : AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _infoBadge(Icons.phone_android_rounded,
                      AppFormatters.formatPhoneNumber(user.phone), isDark),
                  const SizedBox(width: 10),
                  _infoBadge(Icons.verified_rounded, user.kycLevel, isDark,
                      color: AppColors.success),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.03, end: 0);
  }

  Widget _infoBadge(IconData icon, String label, bool isDark, {Color? color}) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(dynamic user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _statItem(
              'Solde',
              AppFormatters.formatCurrencyCompact(user.balance),
              isDark: false,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Expanded(
            child: _statItem(
              'Épargne',
              AppFormatters.formatCurrencyCompact(user.savingsBalance),
              isDark: false,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Expanded(
            child: _statItem('Membre depuis', 'Mars 2023', isDark: false),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, {required bool isDark}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.65),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildKycBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded,
                color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compte vérifié — KYC 3',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Accès à toutes les fonctionnalités',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.success, size: 20),
        ],
      ),
    );
  }

  Widget _kycBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Vérifié',
        style: TextStyle(
          fontSize: 11,
          color: AppColors.success,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext context, bool isDark) {
    Get.toNamed(AppRoutes.personalInfo);
  }

  void _showSecuritySheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SecuritySheet(isDark: isDark),
    );
  }

  void _confirmLogout(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusXL)),
        title: const Text('Se déconnecter ?'),
        content:
            const Text('Vous allez être redirigé vers l\'écran de connexion.'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Get.offAllNamed(AppRoutes.login),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}

// ── Security bottom sheet ────────────────────────────────────────────────────
class _SecuritySheet extends StatelessWidget {
  final bool isDark;
  const _SecuritySheet({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bio = BiometricService.to;
    final twofa = TwoFAService.to;

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radius2XL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_outlined,
                    color: AppColors.info, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Sécurité du compte',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Biometric section ──────────────────────────────────────────
          _SectionLabel('Déverrouillage biométrique', isDark),
          const SizedBox(height: 10),
          Obx(() {
            final available = bio.isAvailable.value;
            final enabled = bio.isEnabled.value;

            return _SecurityCard(
              icon: bio.isFace ? Icons.face_rounded : Icons.fingerprint_rounded,
              iconColor: AppColors.primary,
              isDark: isDark,
              title: bio.kindLabel,
              subtitle: available
                  ? (enabled
                      ? 'Actif — connexion sécurisée activée'
                      : 'Inactif — activez pour une connexion rapide')
                  : 'Non disponible sur cet appareil',
              trailing: available
                  ? Transform.scale(
                      scale: 0.85,
                      child: Switch(
                        value: enabled,
                        onChanged: (v) async {
                          if (v) {
                            await bio.enableBiometric();
                          } else {
                            await bio.disableBiometric();
                          }
                        },
                        activeColor: AppColors.primary,
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.grey200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Indisponible',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.grey500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            );
          }),

          const SizedBox(height: 16),

          // ── 2FA section ────────────────────────────────────────────────
          _SectionLabel('Double authentification (2FA)', isDark),
          const SizedBox(height: 10),
          Obx(() {
            final enabled = twofa.is2FAEnabled.value;
            return Column(
              children: [
                _SecurityCard(
                  icon: Icons.security_rounded,
                  iconColor: enabled ? AppColors.success : AppColors.grey400,
                  isDark: isDark,
                  title: 'Authentification TOTP',
                  subtitle: enabled
                      ? 'Actif — code requis à chaque connexion'
                      : 'Inactif — recommandé pour sécuriser votre compte',
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (enabled ? AppColors.success : AppColors.grey400)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      enabled ? 'ACTIVÉ' : 'DÉSACTIVÉ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: enabled ? AppColors.success : AppColors.grey400,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (enabled)
                  // Current code card
                  Obx(() => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.success.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.phonelink_lock_rounded,
                                color: AppColors.success, size: 20),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Code actuel (démo)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.textOnDarkSecondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${twofa.currentCode.value.substring(0, 3)} ${twofa.currentCode.value.substring(3)}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.success,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              'expire dans\n${twofa.secondsLeft.value}s',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textOnDarkSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ActionBtn(
                        label: enabled ? 'Reconfigurer' : 'Activer la 2FA',
                        icon: Icons.qr_code_rounded,
                        color: AppColors.primary,
                        isDark: isDark,
                        onTap: () {
                          Get.back();
                          Get.toNamed(AppRoutes.twoFASetup);
                        },
                      ),
                    ),
                    if (enabled) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionBtn(
                          label: 'Désactiver',
                          icon: Icons.no_encryption_gmailerrorred_rounded,
                          color: AppColors.error,
                          isDark: isDark,
                          onTap: () async {
                            await twofa.disable();
                            Get.snackbar(
                              '2FA désactivée',
                              'La double authentification a été désactivée.',
                              backgroundColor:
                                  AppColors.warning.withOpacity(0.9),
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
          }),

          const SizedBox(height: 16),

          // ── PIN section ────────────────────────────────────────────────
          _SectionLabel('Code PIN', isDark),
          const SizedBox(height: 10),
          _SecurityCard(
            icon: Icons.pin_outlined,
            iconColor: AppColors.warning,
            isDark: isDark,
            title: 'Modifier le PIN',
            subtitle: 'Code à 4 chiffres pour confirmer vos transactions',
            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppColors.grey400),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel(this.text, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color:
              isDark ? AppColors.textOnDarkSecondary : AppColors.textTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SecurityCard({
    required this.icon,
    required this.iconColor,
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.grey50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark ? AppColors.textOnDark : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textOnDarkSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  final bool isDark;

  const _MenuSection(
      {required this.title, required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textOnDarkSecondary
                  : AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.1 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              return Column(
                children: [
                  e.value,
                  if (e.key < items.length - 1)
                    Divider(
                      height: 1,
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                      indent: 60,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.white : AppColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else ...[
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SecureItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Widget? trailing;

  const _SecureItem({
    required this.icon,
    required this.label,
    required this.isDark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon,
              color: isDark
                  ? AppColors.textOnDarkSecondary
                  : AppColors.textSecondary,
              size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.textPrimary,
              ),
            ),
          ),
          trailing ??
              Icon(Icons.chevron_right_rounded,
                  color: isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.textTertiary,
                  size: 20),
        ],
      ),
    );
  }
}

class _ThemeSwitch extends StatelessWidget {
  final AppController appCtrl;

  const _ThemeSwitch({required this.appCtrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Switch(
          value: appCtrl.isDarkMode.value,
          onChanged: (_) => appCtrl.toggleTheme(),
          activeColor: AppColors.primary,
        ));
  }
}
