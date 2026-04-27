import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../services/database_service.dart';
import '../../data/models/transaction_model.dart';
import '../../services/app_controller.dart';
import '../../services/transaction_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/input_field.dart';
import '../../widgets/success_overlay.dart';
import '../../core/utils/biometric_guard.dart';

class TopupScreen extends StatefulWidget {
  const TopupScreen({super.key});

  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  final _amountCtrl = TextEditingController();
  final AppController _appCtrl = AppController.to;
  String? _selectedMethod;
  bool _isLoading = false;

  final List<double> _quickAmounts = [5000, 10000, 25000, 50000, 100000];

  bool get _canSubmit {
    final a = double.tryParse(_amountCtrl.text) ?? 0;
    return a > 0 && _selectedMethod != null;
  }

  Future<void> _topup() async {
    final amount = double.parse(_amountCtrl.text);

    final confirmed = await BiometricGuard.show(
      context,
      action: 'recharge',
      amount: amount,
      recipient: _selectedMethod,
      actionIcon: Icons.account_balance_wallet_rounded,
      actionColor: AppColors.rechargeColor,
    );
    if (!confirmed) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));

    // Sauvegarder la transaction avec TransactionService
    final success = await TransactionService.to.saveTopup(
      amount,
      'Recharge via $_selectedMethod',
      _selectedMethod,
    );

    if (success) {
      _appCtrl.updateBalance(amount);
    }
    setState(() => _isLoading = false);
    await SuccessOverlay.show(
      title: 'Recharge effectuée !',
      subtitle: 'Votre portefeuille a été rechargé.',
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
        title: const Text('Recharger le wallet'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current balance
            Obx(() => Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solde actuel',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            AppFormatters.formatCurrency(
                                _appCtrl.user.value?.balance ?? 0),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            Text(
              'Montant à recharger',
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
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickAmounts.map((amount) {
                final isSelected =
                    _amountCtrl.text == amount.toInt().toString();
                return GestureDetector(
                  onTap: () {
                    _amountCtrl.text = amount.toInt().toString();
                    setState(() {});
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.rechargeColor.withOpacity(0.12)
                          : isDark
                              ? AppColors.grey800
                              : AppColors.grey100,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusFull),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.rechargeColor
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      AppFormatters.formatCurrencyCompact(amount),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.rechargeColor
                            : isDark
                                ? AppColors.grey300
                                : AppColors.grey700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            Text(
              'Via quel canal ?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.grey900,
              ),
            ),
            const SizedBox(height: 12),
            ...DatabaseService.to.paymentMethods.take(4).map((method) {
              final isSelected = _selectedMethod == method['name'];
              return GestureDetector(
                onTap: () => setState(() => _selectedMethod = method['name']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.rechargeColor.withOpacity(0.08)
                        : isDark
                            ? AppColors.cardDark
                            : AppColors.white,
                    borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.rechargeColor
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
                                ? AppColors.rechargeColor
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
                                color: AppColors.rechargeColor.withOpacity(0.1),
                                child: const Icon(
                                  Icons.phone_android_rounded,
                                  color: AppColors.rechargeColor,
                                  size: 22,
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
                          color: isDark ? AppColors.white : AppColors.grey900,
                        ),
                      ),
                      const Spacer(),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.rechargeColor
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.rechargeColor
                                : AppColors.grey400,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 13)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
            CustomButton(
              label: _isLoading ? 'Traitement...' : 'Recharger maintenant',
              isLoading: _isLoading,
              onPressed: _canSubmit ? _topup : null,
              gradient: const LinearGradient(
                colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
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
