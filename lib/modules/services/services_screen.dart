import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../services/database_service.dart';
import '../../data/models/transaction_model.dart';
import '../../services/app_controller.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/input_field.dart';
import '../../widgets/success_overlay.dart';
import '../../core/utils/biometric_guard.dart';
import '../../services/transaction_service.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  String? _selectedCategory;

  List<Map<String, dynamic>> get _filteredServices => _selectedCategory == null
      ? DatabaseService.to.services
      : DatabaseService.to.services
          .where((s) => s['category'] == _selectedCategory)
          .toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: _backButton(isDark),
        title: const Text('Services & Paiements'),
        centerTitle: true,
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: Column(
        children: [
          // Category filter
          _buildCategoryFilter(isDark),
          // Services grid
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Popular services
                  if (_selectedCategory == null) ...[
                    Text(
                      'Services populaires',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.white : AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: DatabaseService.to.services
                          .where((s) => s['isPopular'] == true)
                          .map((s) => _ServiceCard(service: s, isDark: isDark))
                          .toList(),
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 24),
                    Text(
                      'Tous les services',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.white : AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: _filteredServices.map((s) {
                      if (s == null) return const SizedBox.shrink();
                      return _ServiceCard(service: s, isDark: isDark);
                    }).toList(),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDark) {
    final categories = [
      {'label': 'Tout', 'value': null},
      {'label': 'Services publics', 'value': 'utilities'},
      {'label': 'Télécom', 'value': 'telecom'},
      {'label': 'Streaming', 'value': 'streaming'},
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = _selectedCategory == cat['value'];
          return GestureDetector(
            onTap: () =>
                setState(() => _selectedCategory = cat['value'] as String?),
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
                cat['label'] as String,
                style: TextStyle(
                  fontSize: 13,
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

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final bool isDark;

  const _ServiceCard({required this.service, required this.isDark});

  Color get _color =>
      Color(int.parse(service['color'].toString().replaceAll('#', '0xFF')));

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'utilities':
        return 'Services publics';
      case 'telecom':
        return 'Télécom';
      case 'streaming':
        return 'Streaming';
      default:
        return 'Autres';
    }
  }

  IconData get _icon {
    switch (service['iconPath']) {
      case 'electricity':
        return Icons.bolt_rounded;
      case 'water':
        return Icons.water_drop_rounded;
      case 'internet':
        return Icons.wifi_rounded;
      case 'tv':
        return Icons.tv_rounded;
      case 'streaming':
        return Icons.play_circle_rounded;
      case 'music':
        return Icons.music_note_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPaymentSheet(context),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          border: Border.all(
            color: isDark ? AppColors.grey800 : AppColors.grey100,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _color.withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMD),
                    ),
                    child: Icon(_icon, color: _color, size: 22),
                  ),
                  if (service['isPopular'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Populaire',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                service['name'] as String,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.grey900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                service['fixedAmount'] != null
                    ? AppFormatters.formatCurrencyCompact(
                        (service['fixedAmount'] as num).toDouble())
                    : 'Montant variable',
                style: TextStyle(
                  fontSize: 11,
                  color: service['fixedAmount'] != null
                      ? _color
                      : isDark
                          ? AppColors.grey500
                          : AppColors.grey400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServicePaymentSheet(service: service, isDark: isDark),
    );
  }
}

class _ServicePaymentSheet extends StatefulWidget {
  final Map<String, dynamic> service;
  final bool isDark;

  const _ServicePaymentSheet({required this.service, required this.isDark});

  @override
  State<_ServicePaymentSheet> createState() => _ServicePaymentSheetState();
}

class _ServicePaymentSheetState extends State<_ServicePaymentSheet> {
  final _clientCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _isLoading = false;
  final AppController _appCtrl = AppController.to;

  @override
  void initState() {
    super.initState();
    if (widget.service['fixedAmount'] != null) {
      final amount = widget.service['fixedAmount'];
      _amountCtrl.text =
          (amount is num ? amount.toInt() : int.parse(amount.toString()))
              .toString();
    }
  }

  @override
  void dispose() {
    _clientCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Color get _color => Color(
      int.parse(widget.service['color'].toString().replaceAll('#', '0xFF')));

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'utilities':
        return 'Services publics';
      case 'telecom':
        return 'Télécom';
      case 'streaming':
        return 'Streaming';
      default:
        return 'Autres';
    }
  }

  bool get _canSubmit {
    final amountText = _amountCtrl.text;
    final amount = double.tryParse(amountText);
    final balance = _appCtrl.user.value?.balance ?? 0;

    // Pour les services avec montant fixe, pas besoin de client ID
    // Pour les services avec montant variable, client ID requis
    final hasValidClient = widget.service['fixedAmount'] != null
        ? true
        : _clientCtrl.text.isNotEmpty;

    final hasValidAmount = amount != null && amount > 0;
    final hasSufficientBalance = amount != null && amount <= balance;

    return hasValidClient && hasValidAmount && hasSufficientBalance;
  }

  Future<void> _pay() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (!_canSubmit) return;

    final confirmed = await BiometricGuard.show(
      context,
      action: 'service',
      amount: amount,
      recipient: widget.service['name'] as String,
      actionIcon: Icons.receipt_long_rounded,
      actionColor: AppColors.servicesColor,
    );
    if (!confirmed) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));

    // Sauvegarder la transaction avec TransactionService
    final success = await TransactionService.to.saveService(
      amount,
      'Paiement ${widget.service['name']}',
      widget.service['name'] as String,
    );

    if (success) {
      // Rafraîchir les données utilisateur depuis le serveur
      await DatabaseService.to.refreshUserData();
    }
    setState(() => _isLoading = false);
    Get.back();
    await SuccessOverlay.show(
      title: 'Paiement réussi !',
      subtitle:
          '${widget.service['name']} - ${AppFormatters.formatCurrency(amount)}',
      amount: amount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radius2XL),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                  ),
                  child: Icon(
                    _ServiceCard(service: widget.service, isDark: widget.isDark)
                        ._icon,
                    color: _color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.service['name'] as String,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color:
                            widget.isDark ? AppColors.white : AppColors.grey900,
                      ),
                    ),
                    Text(
                      _getCategoryLabel(widget.service['category'] as String),
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.isDark
                            ? AppColors.grey400
                            : AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            InputField(
              label: 'Numéro client / Référence',
              hint: 'Ex: 123456789',
              controller: _clientCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.person_outline_rounded,
                  size: 20, color: AppColors.grey400),
            ),
            const SizedBox(height: 16),
            if (widget.service['fixedAmount'] == null) ...[
              AmountInputField(
                controller: _amountCtrl,
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Montant fixe:',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.isDark
                            ? AppColors.grey400
                            : AppColors.grey600,
                      ),
                    ),
                    Text(
                      AppFormatters.formatCurrency(
                          (widget.service['fixedAmount'] as num).toDouble()),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Obx(() => CustomButton(
                  label: _isLoading ? 'Traitement...' : 'Payer',
                  isLoading: _isLoading,
                  onPressed: _canSubmit ? _pay : null,
                  gradient: LinearGradient(
                    colors: [_color.withOpacity(0.9), _color],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
