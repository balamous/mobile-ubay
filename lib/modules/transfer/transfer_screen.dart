import 'package:flutter/material.dart';
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

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _amountCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final AppController _appCtrl = AppController.to;
  Map<String, dynamic>? _selectedContact;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Listen for balance changes to update the submit button state
    ever(_appCtrl.user, (user) {
      if (mounted) setState(() {});
    });
  }

  bool get _canSubmit {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    return amount > 0 &&
        amount <= _appCtrl.user.value!.balance &&
        (_selectedContact != null || _phoneCtrl.text.length >= 9);
  }

  Future<void> _transfer() async {
    final amount = double.parse(_amountCtrl.text);
    final recipient = _selectedContact?['name'] ?? _phoneCtrl.text;

    final confirmed = await BiometricGuard.show(
      context,
      action: 'transfert',
      amount: amount,
      recipient: recipient,
      actionIcon: Icons.send_rounded,
      actionColor: AppColors.transferColor,
    );
    if (!confirmed) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1800));

    // Sauvegarder la transaction avec TransactionService
    final success = await TransactionService.to.saveTransfer(
      amount,
      'Transfert vers $recipient',
      recipient,
    );

    if (success) {
      _appCtrl.updateBalance(-amount);
    }
    setState(() => _isLoading = false);
    await SuccessOverlay.show(
      title: 'Transfert effectué !',
      subtitle: 'Le transfert a été envoyé à $recipient.',
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
        title: const Text('Transfert'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contacts carousel
            Text(
              'Contacts récents',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.grey900,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: DatabaseService.to.contacts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final contact = DatabaseService.to.contacts[i];
                  final isSelected =
                      _selectedContact?['name'] == contact['name'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedContact = contact;
                        _phoneCtrl.text = contact['phone']!;
                      });
                    },
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient:
                                isSelected ? AppColors.primaryGradient : null,
                            color: isSelected
                                ? null
                                : isDark
                                    ? AppColors.grey800
                                    : AppColors.grey100,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              contact['initials']!,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : isDark
                                        ? AppColors.grey300
                                        : AppColors.grey700,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          contact['name']!.split(' ').first,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : isDark
                                    ? AppColors.grey400
                                    : AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            // Phone input
            InputField(
              label: 'Numéro de téléphone',
              hint: '77 123 45 67',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_outlined,
                  size: 20, color: AppColors.grey400),
              onChanged: (_) => setState(() {}),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 20),
            Text(
              'Montant',
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
            const SizedBox(height: 20),
            InputField(
              label: 'Note (optionnel)',
              hint: 'Pour quoi ?',
              controller: _noteCtrl,
              prefixIcon: const Icon(Icons.note_outlined,
                  size: 20, color: AppColors.grey400),
              maxLines: 2,
            ),
            // Balance
            const SizedBox(height: 20),
            _buildFeeRow(isDark),
            const SizedBox(height: 28),
            CustomButton(
              label: _isLoading ? 'Traitement...' : 'Envoyer',
              isLoading: _isLoading,
              onPressed: _canSubmit ? _transfer : null,
              gradient: AppColors.primaryGradient,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeRow(bool isDark) {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    final fee = amount > 0 ? (amount * 0.005).clamp(200, 5000) : 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : AppColors.grey100,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      ),
      child: Column(
        children: [
          _feeItem('Montant', amount, isDark),
          const SizedBox(height: 8),
          _feeItem('Frais', fee.toDouble(), isDark),
          Divider(color: isDark ? AppColors.grey700 : AppColors.grey300),
          _feeItem('Total à débiter', amount + fee.toDouble(), isDark,
              isBold: true),
        ],
      ),
    );
  }

  Widget _feeItem(String label, double amount, bool isDark,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.grey400 : AppColors.grey600,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          AppFormatters.formatCurrency(amount),
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: isBold
                ? AppColors.primary
                : isDark
                    ? AppColors.white
                    : AppColors.grey900,
          ),
        ),
      ],
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
