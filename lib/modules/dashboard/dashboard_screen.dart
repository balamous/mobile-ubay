import 'package:fintech_b2b/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../routes/app_routes.dart';
import '../../services/app_controller.dart';
import '../../services/biometric_service.dart';
import '../../services/transaction_service.dart';
import '../../widgets/action_tile.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/transaction_item.dart';
import '../../widgets/visa_card_widget.dart';
import '../../widgets/shimmer_loader.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AppController _appCtrl = AppController.to;
  final BiometricService _bioService = BiometricService.to;
  bool _balanceVisible = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200),
        () => mounted ? setState(() => _isLoadingData = false) : null);

    // Lock balance if biometric is enabled
    if (_bioService.isEnabled.value) {
      _bioService.lock();
    }

    // Load transactions
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    await TransactionService.to.loadTransactions();
  }

  Future<void> _toggleBalanceVisibility() async {
    if (_bioService.isEnabled.value && !_balanceVisible) {
      // Need to authenticate to show balance
      final result = await _bioService.authenticate(
        reason: 'Authentifiez-vous pour afficher votre solde',
      );

      if (result == BiometricResult.success) {
        setState(() => _balanceVisible = true);
        _bioService.unlock();

        // Auto-hide after 30 seconds for security
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted && _balanceVisible) {
            setState(() => _balanceVisible = false);
            if (_bioService.isEnabled.value) {
              _bioService.lock();
            }
          }
        });
      }
    } else {
      // Simple toggle if biometric is not enabled or balance is already visible
      setState(() => _balanceVisible = !_balanceVisible);
      if (!_balanceVisible && _bioService.isEnabled.value) {
        _bioService.lock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: _isLoadingData
          ? _buildShimmer(isDark)
          : RefreshIndicator(
              onRefresh: () async {
                setState(() => _isLoadingData = true);
                await Future.delayed(const Duration(milliseconds: 1000));
                if (mounted) setState(() => _isLoadingData = false);
              },
              color: AppColors.primary,
              backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  _buildSliverHeader(isDark),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBalanceCard(isDark),
                        const SizedBox(height: 28),
                        _buildQuickActions(isDark),
                        const SizedBox(height: 28),
                        _buildCardsSection(isDark),
                        const SizedBox(height: 28),
                        _buildTransactionsSection(isDark),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  // ── Shimmer ──────────────────────────────────────────────────────────────
  Widget _buildShimmer(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 100),
          ShimmerBox(
              width: double.infinity,
              height: 170,
              borderRadius: AppConstants.radius2XL),
          const SizedBox(height: 24),
          ShimmerBox(
              width: double.infinity,
              height: 90,
              borderRadius: AppConstants.radiusXL),
          const SizedBox(height: 24),
          ShimmerBox(
              width: double.infinity,
              height: 200,
              borderRadius: AppConstants.radius2XL),
          const SizedBox(height: 24),
          const TransactionShimmer(),
        ],
      ),
    );
  }

  // ── Sliver Header ─────────────────────────────────────────────────────────
  Widget _buildSliverHeader(bool isDark) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      snap: true,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        ),
      ),
      title: Obx(() {
        final user = _appCtrl.user.value;
        if (user == null) {
          return const SizedBox.shrink();
        }
        return Row(
          children: [
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.profile),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bonjour 👋',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textOnDarkSecondary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    user.firstName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.white : AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            // Theme toggle
            GestureDetector(
              onTap: _appCtrl.toggleTheme,
              child: _headerIcon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                isDark,
              ),
            ),
            const SizedBox(width: 8),
            // Refresh user data
            GestureDetector(
              onTap: _refreshUserData,
              child: _headerIcon(Icons.refresh_rounded, isDark),
            ),
            const SizedBox(width: 8),
            // Notifications
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.notifications),
              child: Stack(
                children: [
                  _headerIcon(Icons.notifications_outlined, isDark),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.backgroundDark
                              : AppColors.backgroundLight,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _headerIcon(IconData icon, bool isDark) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        size: 20,
        color: isDark ? AppColors.white : AppColors.textPrimary,
      ),
    );
  }

  // ── Balance card ──────────────────────────────────────────────────────────
  Widget _buildBalanceCard(bool isDark) {
    return Obx(() {
      final user = _appCtrl.user.value;
      if (user == null) {
        return const SizedBox(); // Return empty widget if user is null
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.balanceGradient,
            borderRadius: BorderRadius.circular(AppConstants.radius2XL),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.35),
                blurRadius: 28,
                offset: const Offset(0, 12),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decoration circles
              Positioned(
                top: -50,
                right: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                left: -20,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.08),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Solde principal',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleBalanceVisibility,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _balanceVisible
                                ? Icons.visibility_outlined
                                : (_bioService.isEnabled.value
                                    ? Icons.fingerprint
                                    : Icons.visibility_off_outlined),
                            color: Colors.white.withOpacity(0.7),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      key: ValueKey(_balanceVisible),
                      children: [
                        Text(
                          _balanceVisible
                              ? AppFormatters.formatCurrency(user.balance)
                              : '**** GNF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        if (!_balanceVisible && _bioService.isEnabled.value)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  _bioService.isFace
                                      ? Icons.face
                                      : Icons.fingerprint,
                                  size: 14,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Appuyez pour vous authentifier',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'N° ${user.accountNumber}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Savings + stats
                  Row(
                    children: [
                      Expanded(
                        child: _balanceStatChip(
                          Icons.savings_outlined,
                          'Épargne',
                          _balanceVisible
                              ? AppFormatters.formatCurrencyCompact(
                                  user.savingsBalance)
                              : '••••',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _balanceStatChip(
                          Icons.trending_up_rounded,
                          'Rendement',
                          '+5.2%',
                          valueColor: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0),
      );
    });
  }

  Widget _balanceStatChip(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.6), size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Quick actions ─────────────────────────────────────────────────────────
  Widget _buildQuickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Actions rapides', isDark),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.white,
              borderRadius: BorderRadius.circular(AppConstants.radius2XL),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.82,
              crossAxisSpacing: 4,
              mainAxisSpacing: 8,
              children: [
                ActionTile(
                  label: 'Dépôt',
                  icon: Icons.arrow_downward_rounded,
                  color: AppColors.depositColor,
                  onTap: () => Get.toNamed(AppRoutes.deposit),
                  isCompact: true,
                ),
                // ActionTile(
                //   label: 'Retrait',
                //   icon: Icons.arrow_upward_rounded,
                //   color: AppColors.withdrawColor,
                //   onTap: () => Get.toNamed(AppRoutes.withdrawal),
                //   isCompact: true,
                // ),
                ActionTile(
                  label: 'Payer',
                  icon: Icons.contactless_rounded,
                  color: AppColors.paymentColor,
                  onTap: () => Get.toNamed(AppRoutes.payment),
                  isCompact: true,
                ),
                ActionTile(
                  label: 'Recharger',
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.rechargeColor,
                  onTap: () => Get.toNamed(AppRoutes.topup),
                  isCompact: true,
                ),
                ActionTile(
                  label: 'Crédit tél.',
                  icon: Icons.phone_android_rounded,
                  color: AppColors.airtimeColor,
                  onTap: () => Get.toNamed(AppRoutes.airtime),
                  isCompact: true,
                ),
                ActionTile(
                  label: 'Services',
                  icon: Icons.grid_view_rounded,
                  color: AppColors.servicesColor,
                  onTap: () => Get.toNamed(AppRoutes.services),
                  isCompact: true,
                ),
                ActionTile(
                  label: 'Scanner',
                  icon: Icons.qr_code_scanner_rounded,
                  color: AppColors.info,
                  onTap: () => _showQrSheet(context, isDark),
                  isCompact: true,
                ),
                ActionTile(
                  label: 'Autres services',
                  icon: Icons.apps_rounded,
                  color: AppColors.grey500,
                  onTap: () => Get.toNamed(AppRoutes.otherServices),
                  isCompact: true,
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
    );
  }

  // ── Cards section ─────────────────────────────────────────────────────────
  Widget _buildCardsSection(bool isDark) {
    return Obx(() {
      final cards = _appCtrl.cards;
      if (cards.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('Mes cartes', isDark),
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.card),
                  child: _viewAllLink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CardCarousel(
            cards: cards,
            height: 210,
            onCardTap: (_) => Get.toNamed(AppRoutes.card),
          ),
        ],
      ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
    });
  }

  // ── Transactions section ──────────────────────────────────────────────────
  Widget _buildTransactionsSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('Transactions récentes', isDark),
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.history),
                child: _viewAllLink(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Obx(() {
            final txns = TransactionService.to.recentTransactions;
            return Column(
              children: txns.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TransactionItem(
                    transaction: e.value,
                    onTap: () => _showTxDetail(context, e.value, isDark),
                  ).animate().fadeIn(
                        delay: Duration(milliseconds: 300 + e.key * 60),
                        duration: 300.ms,
                      ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _sectionTitle(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: isDark ? AppColors.white : AppColors.textPrimary,
        letterSpacing: -0.4,
      ),
    );
  }

  Widget _viewAllLink() {
    return Row(
      children: const [
        Text(
          'Voir tout',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: 2),
        Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primary),
      ],
    );
  }

  void _showQrSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.72,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.radius2XL)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 14),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Scanner QR Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Stack(
                children: [
                  ..._corners(),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner_rounded,
                            size: 72,
                            color: AppColors.primary.withOpacity(0.2)),
                        const SizedBox(height: 12),
                        Text(
                          'Placez le QR code\ndans le cadre',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.grey500
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Mode simulation',
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.grey500 : AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _corners() {
    const s = 20.0;
    const t = 3.0;
    final c = AppColors.primary;
    w(bool top, bool left) => Positioned(
          top: top ? 0 : null,
          bottom: top ? null : 0,
          left: left ? 0 : null,
          right: left ? null : 0,
          child: Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              border: Border(
                top: top ? BorderSide(color: c, width: t) : BorderSide.none,
                bottom: !top ? BorderSide(color: c, width: t) : BorderSide.none,
                left: left ? BorderSide(color: c, width: t) : BorderSide.none,
                right: !left ? BorderSide(color: c, width: t) : BorderSide.none,
              ),
            ),
          ),
        );
    return [w(true, true), w(true, false), w(false, true), w(false, false)];
  }

  void _showTxDetail(BuildContext context, dynamic tx, bool isDark) {
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
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2))),
            Text(
              '${tx.isCredit ? '+' : '-'} ${AppFormatters.formatCurrency(tx.amount)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: tx.isCredit
                    ? AppColors.success
                    : isDark
                        ? AppColors.white
                        : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(tx.description,
                style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary)),
            const SizedBox(height: 24),
            _row('Type', tx.typeLabel, isDark),
            _row('Statut', tx.statusLabel, isDark),
            _row('Date', AppFormatters.formatDateTime(tx.date), isDark),
            if (tx.reference != null) _row('Référence', tx.reference!, isDark),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.textPrimary)),
        ],
      ),
    );
  }

  Future<void> _refreshUserData() async {
    try {
      final authService = AuthService.to;
      final success = await authService.refreshUserData();

      if (success) {
        Get.snackbar(
          'Succès',
          'Données utilisateur mises à jour',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Erreur',
          authService.error.value,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors du rafraîchissement: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
