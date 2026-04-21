import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../services/dashboard_service.dart';
import '../../services/auth_service.dart';
import '../../data/models/user_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/card_model.dart';
import '../../widgets/visa_card_widget.dart';
import '../../widgets/transaction_item.dart';

class DashboardDynamicScreen extends StatefulWidget {
  const DashboardDynamicScreen({super.key});

  @override
  State<DashboardDynamicScreen> createState() => _DashboardDynamicScreenState();
}

class _DashboardDynamicScreenState extends State<DashboardDynamicScreen>
    with TickerProviderStateMixin {
  final DashboardService _dashboard = DashboardService.to;
  final AuthService _auth = AuthService.to;

  late TabController _tabController;
  late AnimationController _balanceAnimController;
  late AnimationController _chartAnimController;

  // Observable data
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxList<CardModel> cards = <CardModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _balanceAnimController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _chartAnimController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _balanceAnimController.dispose();
    _chartAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      isLoading.value = true;
      error.value = '';

      // Charger les données depuis le serveur
      await Future.wait([
        _loadUserData(),
        _loadTransactions(),
        _loadCards(),
      ]);

      // Démarrer les animations
      _balanceAnimController.forward();
      _chartAnimController.forward();
    } catch (e) {
      error.value = 'Erreur de chargement: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadUserData() async {
    final user = await _dashboard.getUserProfile(_auth.token.value);
    if (user != null) {
      currentUser.value = user;
    }
  }

  Future<void> _loadTransactions() async {
    final txList = await _dashboard.getTransactions(_auth.token.value);
    transactions.assignAll(txList);
  }

  Future<void> _loadCards() async {
    final cardList = await _dashboard.getCards(_auth.token.value);
    cards.assignAll(cardList);
  }

  Future<void> _refreshData() async {
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Obx(() {
        if (isLoading.value) {
          return _buildLoadingState();
        }

        if (error.value.isNotEmpty) {
          return _buildErrorState();
        }

        if (currentUser.value == null) {
          return _buildEmptyState();
        }

        return _buildDashboardContent();
      }),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chargement...',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.value,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Réessayer',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 80,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune donnée utilisateur',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Veuillez vous reconnecter',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    final user = currentUser.value!;

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(user),
            const SizedBox(height: 24),
            _buildBalanceSection(user),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildCardsSection(),
            const SizedBox(height: 24),
            _buildTransactionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel user) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: CircleAvatar(
            radius: 26,
            backgroundImage: NetworkImage(user.avatarUrl!),
            backgroundColor: Colors.transparent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${user.firstName} ${user.lastName}',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      user.isVerified ? AppColors.success : AppColors.warning,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.isVerified ? 'Vérifié' : 'Non vérifié',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            // Menu options
          },
          icon: const Icon(Icons.more_vert, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildBalanceSection(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Solde Total',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              IconButton(
                onPressed: () {
                  // Refresh balance
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _balanceAnimController,
            builder: (context, child) {
              return Text(
                '${user.balance.toStringAsFixed(2)} GNF',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                  'Épargne',
                  '${user.savingsBalance.toStringAsFixed(2)} GNF',
                  Icons.savings,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBalanceItem(
                  'Disponible',
                  '${user.balance.toStringAsFixed(2)} GNF',
                  Icons.account_balance_wallet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String title, String amount, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.white.withOpacity(0.8)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions Rapides',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Transfert',
                  Icons.send,
                  AppColors.primary,
                  () {
                    // Navigation vers transfert
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Paiement',
                  Icons.payment,
                  AppColors.success,
                  () {
                    // Navigation vers paiement
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Recharge',
                  Icons.phone_android,
                  AppColors.warning,
                  () {
                    // Navigation vers recharge
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Services',
                  Icons.apps,
                  AppColors.info,
                  () {
                    // Navigation vers services
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mes Cartes',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                // Voir toutes les cartes
              },
              child: Text(
                'Voir tout',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (cards.isEmpty) {
            return _buildEmptyCards();
          }

          return SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: VisaCardWidget(
                    card: card,
                    onTap: () {
                      // Détails de la carte
                    },
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyCards() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card,
              size: 48,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune carte',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transactions Récentes',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                // Voir toutes les transactions
              },
              child: Text(
                'Voir tout',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (transactions.isEmpty) {
            return _buildEmptyTransactions();
          }

          return Column(
            children: transactions.take(5).map((transaction) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TransactionItem(
                  transaction: transaction,
                  onTap: () {
                    // Détails de la transaction
                  },
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 48,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune transaction',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
