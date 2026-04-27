import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../services/database_service.dart';
import '../../data/models/transaction_model.dart';
import '../../services/app_controller.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/input_field.dart';
import '../../widgets/success_overlay.dart';
import '../../core/utils/biometric_guard.dart';
import '../../services/transaction_service.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _amountCtrl = TextEditingController();
  final AppController _appCtrl = AppController.to;
  String? _selectedMethod;
  bool _isLoading = false;
  final List<double> _quickAmounts = [
    10000,
    25000,
    50000,
    100000,
    250000,
    500000
  ];

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _amountCtrl.text.isNotEmpty &&
      double.tryParse(_amountCtrl.text) != null &&
      double.parse(_amountCtrl.text) > 0 &&
      _selectedMethod != null;

  @override
  void initState() {
    super.initState();
    // Charger les méthodes de paiement si elles sont vides
    if (DatabaseService.to.paymentMethods.isEmpty) {
      DatabaseService.to.loadPaymentMethods();
    }
    // Sélectionner automatiquement la première méthode si disponible
    ever(DatabaseService.to.paymentMethods, (methods) {
      if (methods.isNotEmpty && _selectedMethod == null) {
        setState(() {
          _selectedMethod = methods.first['id'];
        });
      }
    });
  }

  Future<void> _deposit() async {
    if (!_canSubmit) return;

    final confirmed = await BiometricGuard.show(
      context,
      action: 'dépôt',
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      recipient: _selectedMethod,
      actionIcon: Icons.arrow_downward_rounded,
      actionColor: AppColors.success,
    );
    if (!confirmed) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    final amount = double.parse(_amountCtrl.text);

    // Sauvegarder la transaction avec TransactionService
    final success = await TransactionService.to.saveDeposit(
      amount,
      'Dépôt via $_selectedMethod',
    );

    if (success) {
      // Rafraîchir les données utilisateur depuis le serveur
      await DatabaseService.to.refreshUserData();
    }
    setState(() => _isLoading = false);
    await SuccessOverlay.show(
      title: 'Dépôt réussi !',
      subtitle: 'Votre solde a été mis à jour.',
      amount: amount,
      onDone: Get.back,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: _backButton(isDark),
        title: const Text('Dépôt'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.depositColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              ),
              child: Text(
                AppFormatters.formatCurrencyCompact(
                    _appCtrl.user.value?.balance ?? 0),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.depositColor,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon header
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.greenGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_downward_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            ),
            const SizedBox(height: 28),
            // Amount section
            Text(
              'Montant du dépôt',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.grey900,
              ),
            ),
            const SizedBox(height: 12),
            AmountInputField(
              controller: _amountCtrl,
              onChanged: (_) => setState(() {}),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),
            // Quick amounts
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickAmounts.map((amount) {
                return GestureDetector(
                  onTap: () {
                    _amountCtrl.text = amount.toInt().toString();
                    setState(() {});
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _amountCtrl.text == amount.toInt().toString()
                          ? AppColors.primary.withOpacity(0.12)
                          : isDark
                              ? AppColors.grey800
                              : AppColors.grey100,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusFull),
                      border: Border.all(
                        color: _amountCtrl.text == amount.toInt().toString()
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      AppFormatters.formatCurrencyCompact(amount),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _amountCtrl.text == amount.toInt().toString()
                            ? AppColors.primary
                            : isDark
                                ? AppColors.grey300
                                : AppColors.grey700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 28),
            // Payment method
            Text(
              'Méthode de dépôt',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.grey900,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              if (DatabaseService.to.paymentMethods.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.grey800 : AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.grey400,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Chargement des méthodes de paiement...',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                isDark ? AppColors.grey400 : AppColors.grey600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: DatabaseService.to.paymentMethods.map((method) {
                  final isSelected = _selectedMethod == method['name'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedMethod = method['name']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.08)
                            : isDark
                                ? AppColors.cardDark
                                : AppColors.white,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusLG),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : isDark
                                  ? AppColors.grey800
                                  : AppColors.grey200,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(AppConstants.radiusMD),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppConstants.radiusMD),
                              child: Image.asset(
                                method['logoPath']!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Color(
                                      int.parse(
                                        method['color']!
                                            .replaceAll('#', '0xFF'),
                                      ),
                                    ).withOpacity(0.12),
                                    child: Icon(
                                      Icons.phone_android_rounded,
                                      size: 22,
                                      color: Color(
                                        int.parse(
                                          method['color']!
                                              .replaceAll('#', '0xFF'),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            method['name']!,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark ? AppColors.white : AppColors.grey900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
            const SizedBox(height: 32),
            CustomButton(
              label: _isLoading ? 'Traitement...' : 'Confirmer le dépôt',
              isLoading: _isLoading,
              onPressed: _canSubmit ? _deposit : null,
              gradient: AppColors.greenGradient,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _backButton(bool isDark) {
    return GestureDetector(
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
}
