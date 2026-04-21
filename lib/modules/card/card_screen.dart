import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/card_model.dart';
import '../../services/app_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/visa_card_widget.dart';

class CardScreen extends StatefulWidget {
  const CardScreen({super.key});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  final AppController _appCtrl = AppController.to;
  int _selectedIndex = 0;
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        leading: _backBtn(isDark),
        title: const Text('Mes Cartes'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _addCardSheet(context, isDark),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded,
                    color: AppColors.primary, size: 22),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: Obx(() {
        final cards = _appCtrl.cards;
        if (cards.isEmpty) return _buildEmpty(isDark);
        final idx = _selectedIndex.clamp(0, cards.length - 1);
        final card = cards[idx];

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // ── Cards PageView ──────────────────────────────────────────
              CardCarousel(
                cards: cards,
                height: 215,
                showDetails: _showDetails,
                onCardTap: (i) => setState(() => _selectedIndex = i),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 12),
              // Show/hide details
              Center(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _showDetails = !_showDetails),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.cardDark
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(
                          AppConstants.radiusFull),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showDetails
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showDetails
                              ? 'Masquer les données'
                              : 'Afficher CVV & numéro',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // ── Stats ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStats(card, isDark),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 20),
              // ── Actions ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildActions(card, isDark),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 20),
              // ── Card details ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildDetails(card, isDark),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  // ── Stats card ──────────────────────────────────────────────────────────
  Widget _buildStats(CardModel card, bool isDark) {
    final progress = card.limit! > 0
        ? (card.spent! / card.limit!).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Utilisation mensuelle',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (progress > 0.8
                          ? AppColors.error
                          : AppColors.primary)
                      .withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusFull),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: progress > 0.8
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor:
                  isDark ? AppColors.grey700 : AppColors.grey200,
              color: progress > 0.8 ? AppColors.error : AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statPill('Dépensé',
                  AppFormatters.formatCurrencyCompact(card.spent!),
                  AppColors.withdrawColor, isDark),
              const SizedBox(width: 8),
              _statPill('Disponible',
                  AppFormatters.formatCurrencyCompact(card.availableBalance),
                  AppColors.success, isDark),
              const SizedBox(width: 8),
              _statPill('Limite',
                  AppFormatters.formatCurrencyCompact(card.limit!),
                  AppColors.primary, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick actions ────────────────────────────────────────────────────────
  Widget _buildActions(CardModel card, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _ActionBtn(
            icon: card.isActive
                ? Icons.pause_circle_outline_rounded
                : Icons.play_circle_outline_rounded,
            label: card.isActive ? 'Désactiver' : 'Activer',
            color: card.isActive ? AppColors.warning : AppColors.success,
            isDark: isDark,
            onTap: () => _toggleCard(card),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            icon: Icons.lock_outline_rounded,
            label: 'Bloquer',
            color: AppColors.error,
            isDark: isDark,
            onTap: () => _blockCard(context, card, isDark),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            icon: Icons.refresh_rounded,
            label: 'Renouveler',
            color: AppColors.info,
            isDark: isDark,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            icon: Icons.settings_outlined,
            label: 'Paramètres',
            color: AppColors.grey500,
            isDark: isDark,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  // ── Card details ─────────────────────────────────────────────────────────
  Widget _buildDetails(CardModel card, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _detail(Icons.credit_card_rounded, 'Numéro',
              _showDetails
                  ? _fmt(card.cardNumber)
                  : card.maskedNumber,
              isDark, monospace: true),
          _divider(isDark),
          _detail(Icons.person_outline_rounded, 'Titulaire',
              card.cardHolder, isDark),
          _divider(isDark),
          _detail(Icons.calendar_today_rounded, 'Expiration',
              card.expiryDate, isDark),
          _divider(isDark),
          _detail(Icons.lock_rounded, 'CVV',
              _showDetails ? card.cvv : '•••', isDark),
          _divider(isDark),
          _detail(Icons.contactless_rounded, 'Type',
              '${card.type.toString().toUpperCase()} ${card.isVirtual ? "Virtuelle" : "Physique"}',
              isDark),
          _divider(isDark),
          _detail(Icons.circle_rounded, 'Statut',
              card.status.toString().toUpperCase(), isDark,
              valueColor:
                  card.isActive ? AppColors.success : AppColors.error),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String label, String value, bool isDark,
      {Color? valueColor, bool monospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                size: 16,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textOnDarkSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ??
                  (isDark ? AppColors.white : AppColors.textPrimary),
              fontFamily: monospace ? 'monospace' : null,
              letterSpacing: monospace ? 2 : 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(
        height: 1,
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        indent: 62,
      );

  String _fmt(String n) {
    final c = n.replaceAll(' ', '');
    final groups = <String>[];
    for (var i = 0; i < c.length; i += 4) {
      groups.add(c.substring(i, (i + 4).clamp(0, c.length)));
    }
    return groups.join('  ');
  }

  void _toggleCard(CardModel card) {
    _appCtrl.toggleCardStatus(card.id);
    Get.snackbar(
      card.isActive ? 'Carte désactivée' : 'Carte activée',
      card.isActive
          ? 'La carte a été désactivée.'
          : 'La carte est maintenant active.',
      backgroundColor:
          (card.isActive ? AppColors.warning : AppColors.success)
              .withOpacity(0.1),
      colorText: card.isActive ? AppColors.warning : AppColors.success,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: AppConstants.radiusMD,
    );
  }

  void _blockCard(BuildContext context, CardModel card, bool isDark) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusXL)),
        title: const Text('Bloquer la carte ?'),
        content: const Text(
            'Cette action bloquera définitivement la carte. Contactez le support pour la débloquer.'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _appCtrl.toggleCardStatus(card.id);
              Get.snackbar('Carte bloquée', 'Votre carte a été bloquée.',
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  colorText: AppColors.error,
                  snackPosition: SnackPosition.BOTTOM,
                  margin: const EdgeInsets.all(16));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Bloquer'),
          ),
        ],
      ),
    );
  }

  void _addCardSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.radius2XL)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2))),
            Text('Ajouter une carte',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.white : AppColors.textPrimary)),
            const SizedBox(height: 20),
            CustomButton(
              label: 'Carte virtuelle (Visa / Mastercard)',
              variant: ButtonVariant.primary,
              gradient: AppColors.primaryGradient,
              prefixIcon: const Icon(Icons.phonelink_rounded,
                  size: 20, color: Colors.white),
              onPressed: () {
                Get.back();
                Get.toNamed(AppRoutes.createCard);
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Carte physique (Visa / Mastercard)',
              variant: ButtonVariant.outline,
              prefixIcon: const Icon(Icons.credit_card_rounded,
                  size: 20, color: AppColors.primary),
              onPressed: () {
                Get.back();
                Get.toNamed(AppRoutes.createCard);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card_off_rounded,
                size: 64,
                color: isDark ? AppColors.grey600 : AppColors.grey300),
            const SizedBox(height: 16),
            Text('Aucune carte',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.grey400 : AppColors.textSecondary)),
            const SizedBox(height: 24),
            CustomButton(
                label: 'Créer une carte',
                onPressed: () => Get.toNamed(AppRoutes.createCard),
                gradient: AppColors.primaryGradient,
                fullWidth: false),
          ],
        ),
      );

  Widget _backBtn(bool isDark) => GestureDetector(
        onTap: Get.back,
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            shape: BoxShape.circle,
            border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: isDark ? AppColors.white : AppColors.textPrimary),
        ),
      );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
