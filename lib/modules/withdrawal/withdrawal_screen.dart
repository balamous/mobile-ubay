import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../../services/app_controller.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/input_field.dart';
import '../../widgets/success_overlay.dart';
import '../../core/utils/biometric_guard.dart';
import '../../services/transaction_service.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _amountCtrl = TextEditingController();
  final AppController _appCtrl = AppController.to;
  bool _isLoading = false;
  String? _selectedPoint;

  final List<Map<String, String>> _points = [
    {'name': 'Agence Plateau', 'address': 'Rue Mohamed V, Dakar'},
    {'name': 'Agence Medina', 'address': 'Avenue Cheikh Anta Diop'},
    {'name': 'Point Retrait - Mermoz', 'address': 'Rue 10, Mermoz'},
    {'name': 'Agence Grand Dakar', 'address': 'Grand Dakar Bis'},
  ];

  final List<double> _quickAmounts = [10000, 25000, 50000, 100000, 200000];

  bool get _canSubmit {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    return amount > 0 &&
        amount <= _appCtrl.user.value!.balance &&
        _selectedPoint != null;
  }

  Future<void> _withdraw() async {
    final amount = double.parse(_amountCtrl.text);
    if (amount > _appCtrl.user.value!.balance) {
      Get.snackbar(
        'Solde insuffisant',
        'Votre solde est insuffisant pour ce retrait.',
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final confirmed = await BiometricGuard.show(
      context,
      action: 'retrait',
      amount: amount,
      recipient: _selectedPoint,
      actionIcon: Icons.arrow_upward_rounded,
      actionColor: AppColors.error,
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));

    // Sauvegarder la transaction avec TransactionService
    final success = await TransactionService.to.saveWithdrawal(
      amount,
      'Retrait - $_selectedPoint',
      _selectedPoint,
    );

    if (success) {
      _appCtrl.updateBalance(-amount);
    }
    setState(() => _isLoading = false);
    await SuccessOverlay.show(
      title: 'Retrait confirmé !',
      subtitle: 'Présentez-vous au point de retrait.',
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
        title: const Text('Retrait'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance info
            Obx(() => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.grey800 : AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded,
                          color: AppColors.withdrawColor, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        'Solde disponible: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.grey400 : AppColors.grey600,
                        ),
                      ),
                      Text(
                        AppFormatters.formatCurrency(
                            _appCtrl.user.value!.balance),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.withdrawColor,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
            Text(
              'Montant du retrait',
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
                          ? AppColors.withdrawColor.withOpacity(0.12)
                          : isDark
                              ? AppColors.grey800
                              : AppColors.grey100,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusFull),
                      border: Border.all(
                        color: _amountCtrl.text == amount.toInt().toString()
                            ? AppColors.withdrawColor
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
                            ? AppColors.withdrawColor
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
              'Point de retrait',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.grey900,
              ),
            ),
            const SizedBox(height: 12),
            ..._points.map((point) {
              final isSelected = _selectedPoint == point['name'];
              return GestureDetector(
                onTap: () => setState(() => _selectedPoint = point['name']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.withdrawColor.withOpacity(0.08)
                        : isDark
                            ? AppColors.cardDark
                            : AppColors.white,
                    borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.withdrawColor
                          : isDark
                              ? AppColors.grey800
                              : AppColors.grey200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.withdrawColor.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMD),
                        ),
                        child: const Icon(Icons.store_rounded,
                            color: AppColors.withdrawColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              point['name']!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.white
                                    : AppColors.grey900,
                              ),
                            ),
                            Text(
                              point['address']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.grey500
                                    : AppColors.grey400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.withdrawColor
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.withdrawColor
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
              label: 'Valider le retrait',
              isLoading: _isLoading,
              onPressed: _canSubmit ? _withdraw : null,
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              ),
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
