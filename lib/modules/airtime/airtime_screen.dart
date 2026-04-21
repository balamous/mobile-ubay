import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../../services/app_controller.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/input_field.dart';
import '../../widgets/success_overlay.dart';
import '../../core/utils/biometric_guard.dart';
import '../../services/transaction_service.dart';

class AirtimeScreen extends StatefulWidget {
  const AirtimeScreen({super.key});

  @override
  State<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends State<AirtimeScreen> {
  final _phoneCtrl = TextEditingController();
  final AppController _appCtrl = AppController.to;
  String? _selectedOperator;
  double? _selectedAmount;
  bool _isLoading = false;

  bool get _canSubmit =>
      _phoneCtrl.text.length >= 9 &&
      _selectedOperator != null &&
      _selectedAmount != null;

  Future<void> _sendAirtime() async {
    final confirmed = await BiometricGuard.show(
      context,
      action: 'crédit téléphonique',
      amount: _selectedAmount ?? 0,
      recipient: '${_selectedOperator ?? ''} · ${_phoneCtrl.text}',
      actionIcon: Icons.phone_android_rounded,
      actionColor: AppColors.airtimeColor,
    );
    if (!confirmed) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));

    // Sauvegarder la transaction avec TransactionService
    final success = await TransactionService.to.saveAirtime(
      _selectedAmount!,
      'Crédit $_selectedOperator - ${_phoneCtrl.text}',
      _selectedOperator,
    );

    if (success) {
      _appCtrl.updateBalance(-_selectedAmount!);
    }
    setState(() => _isLoading = false);
    await SuccessOverlay.show(
      title: 'Crédit envoyé !',
      subtitle:
          'Le crédit ${AppFormatters.formatCurrency(_selectedAmount!)} a été envoyé au ${_phoneCtrl.text}.',
      amount: _selectedAmount,
      onDone: Get.back,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: _backButton(isDark),
        title: const Text('Crédit téléphonique'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Operators
            Text(
              'Choisir un opérateur',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.grey900,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: DatabaseService.to.operators.map((op) {
                final isSelected = _selectedOperator == op['name'];
                final color =
                    Color(int.parse(op['color'].replaceAll('#', '0xFF')));
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedOperator = op['name']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(
                        right: DatabaseService.to.operators.last == op ? 0 : 10,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.12)
                            : isDark
                                ? AppColors.cardDark
                                : AppColors.white,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusLG),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : isDark
                                  ? AppColors.grey800
                                  : AppColors.grey200,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? color : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                op['logoPath'],
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: color.withOpacity(0.15),
                                    child: Center(
                                      child: Text(
                                        op['name'][0],
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            op['name'],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? color
                                  : isDark
                                      ? AppColors.grey300
                                      : AppColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            // Phone number
            InputField(
              label: 'Numéro de téléphone',
              hint: '77 123 45 67',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: const Icon(Icons.phone_android_rounded,
                  size: 20, color: AppColors.grey400),
              onChanged: (_) => setState(() {}),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 24),
            // Amount chips
            if (_selectedOperator != null) ...[
              Text(
                'Choisir un montant',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.grey900,
                ),
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: DatabaseService.to.operators
                    .firstWhere(
                        (o) => o['name'] == _selectedOperator)['amounts']
                    .map((amount) {
                  final isSelected = _selectedAmount == amount;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAmount = amount),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.airtimeColor.withOpacity(0.12)
                            : isDark
                                ? AppColors.cardDark
                                : AppColors.white,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMD),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.airtimeColor
                              : isDark
                                  ? AppColors.grey800
                                  : AppColors.grey200,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        AppFormatters.formatCurrencyCompact(amount),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.airtimeColor
                              : isDark
                                  ? AppColors.grey300
                                  : AppColors.grey700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(delay: 150.ms),
            ],
            // Summary
            if (_selectedAmount != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.airtimeColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  border: Border.all(
                    color: AppColors.airtimeColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    _summaryRow('Opérateur', _selectedOperator ?? '', isDark),
                    const SizedBox(height: 8),
                    _summaryRow(
                        'Numéro',
                        _phoneCtrl.text.isEmpty
                            ? '—'
                            : AppFormatters.formatPhoneNumber(_phoneCtrl.text),
                        isDark),
                    const SizedBox(height: 8),
                    _summaryRow('Montant',
                        AppFormatters.formatCurrency(_selectedAmount!), isDark,
                        valueColor: AppColors.airtimeColor),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            CustomButton(
              label: _isLoading ? 'Envoi...' : 'Envoyer le crédit',
              isLoading: _isLoading,
              onPressed: _canSubmit ? _sendAirtime : null,
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 204, 146, 11),
                  Color.fromARGB(255, 176, 122, 6)
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, bool isDark,
      {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.grey400 : AppColors.grey600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? (isDark ? AppColors.white : AppColors.grey900),
          ),
        ),
      ],
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
