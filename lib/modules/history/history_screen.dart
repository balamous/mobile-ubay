import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../../services/app_controller.dart';
import '../../services/transaction_service.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/transaction_item.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final AppController _appCtrl = AppController.to;
  TransactionType? _filterType;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    await TransactionService.to.loadTransactions();
  }

  List<TransactionModel> get _filteredTransactions {
    var list = TransactionService.to.transactions.toList();
    if (_filterType != null) {
      list = list.where((t) => t.type == _filterType).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((t) =>
              t.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (t.recipient ?? '')
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return list;
  }

  Map<String, List<TransactionModel>> get _groupedTransactions {
    final map = <String, List<TransactionModel>>{};
    for (final tx in _filteredTransactions) {
      final key = AppFormatters.formatRelativeDate(tx.date);
      map.putIfAbsent(key, () => []).add(tx);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: _backButton(isDark),
        title: const Text('Historique'),
        centerTitle: true,
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: _buildSearchBar(isDark),
          ),
          _buildFilterChips(isDark),
          Expanded(
            child: Obx(() {
              final grouped = _groupedTransactions;
              if (grouped.isEmpty) {
                return _buildEmptyState(isDark);
              }
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: grouped.length,
                itemBuilder: (_, groupIdx) {
                  final dateKey = grouped.keys.elementAt(groupIdx);
                  final txns = grouped[dateKey]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Text(
                              dateKey,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.grey400
                                    : AppColors.grey500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Divider(
                                color: isDark
                                    ? AppColors.grey800
                                    : AppColors.grey200,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...txns.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Dismissible(
                            key: Key(entry.value.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radiusLG),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.error,
                                size: 24,
                              ),
                            ),
                            onDismissed: (_) {
                              _appCtrl.transactions.remove(entry.value);
                            },
                            child: TransactionItem(
                              transaction: entry.value,
                              onTap: () =>
                                  _showDetail(context, entry.value, isDark),
                            ).animate().fadeIn(
                                delay: Duration(milliseconds: entry.key * 50),
                                duration: 300.ms),
                          ),
                        );
                      }),
                    ],
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _searchQuery = v),
      decoration: InputDecoration(
        hintText: 'Rechercher une transaction...',
        prefixIcon: const Icon(Icons.search_rounded,
            color: AppColors.grey400, size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Icon(Icons.clear_rounded,
                    color: AppColors.grey400, size: 18),
              )
            : null,
        filled: true,
        fillColor: isDark ? AppColors.grey800 : AppColors.grey100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        isDense: true,
      ),
      style: TextStyle(
        fontSize: 14,
        color: isDark ? AppColors.white : AppColors.grey900,
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final filters = [
      {'label': 'Tout', 'value': null},
      {'label': 'Dépôts', 'value': TransactionType.deposit},
      {'label': 'Retraits', 'value': TransactionType.withdrawal},
      {'label': 'Transferts', 'value': TransactionType.transfer},
      {'label': 'Paiements', 'value': TransactionType.payment},
      {'label': 'Crédit', 'value': TransactionType.airtime},
    ];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filters[i];
          final isSelected = _filterType == f['value'];
          return GestureDetector(
            onTap: () =>
                setState(() => _filterType = f['value'] as TransactionType?),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isDark
                        ? AppColors.grey800
                        : AppColors.grey100,
                borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              ),
              child: Text(
                f['label'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : isDark
                          ? AppColors.grey300
                          : AppColors.grey700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? AppColors.grey800 : AppColors.grey100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded,
                size: 36, color: AppColors.grey400),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune transaction',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.grey300 : AppColors.grey700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune transaction ne correspond\nà vos critères de recherche.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.grey500 : AppColors.grey400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, TransactionModel tx, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radius2XL),
          ),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: (tx.isCredit ? AppColors.success : AppColors.primary)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                tx.isCredit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: tx.isCredit ? AppColors.success : AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${tx.isCredit ? '+' : '-'} ${AppFormatters.formatCurrency(tx.amount)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: tx.isCredit
                    ? AppColors.success
                    : (isDark ? AppColors.white : AppColors.grey900),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tx.description,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.grey400 : AppColors.grey500,
              ),
            ),
            const SizedBox(height: 24),
            _detailItem(
                Icons.tag_rounded, 'Référence', tx.reference ?? '—', isDark),
            _detailItem(Icons.category_rounded, 'Type', tx.typeLabel, isDark),
            _detailItem(Icons.circle_rounded, 'Statut', tx.statusLabel, isDark),
            _detailItem(Icons.calendar_today_rounded, 'Date',
                AppFormatters.formatDateTime(tx.date), isDark),
            if (tx.recipient != null)
              _detailItem(
                  Icons.person_rounded, 'Destinataire', tx.recipient!, isDark),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon,
              size: 18, color: isDark ? AppColors.grey500 : AppColors.grey400),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.grey400 : AppColors.grey500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.white : AppColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _backButton(bool isDark) => GestureDetector(
        onTap: Get.back,
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.grey800 : AppColors.grey100,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
      );
}
