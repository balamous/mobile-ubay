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
import '../../services/contact_service.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _amountCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _recipientController = TextEditingController();
  final AppController _appCtrl = AppController.to;
  Map<String, dynamic>? _selectedContact;
  bool _isLoading = false;
  String _transferType = 'national'; // 'national' ou 'international'

  @override
  void initState() {
    super.initState();
    // Listen for balance changes to update the submit button state
    ever(_appCtrl.user, (user) {
      if (mounted) setState(() {});
    });

    // Charger les bénéficiaires et contacts récents
    DatabaseService.to.loadBeneficiaries();
    ContactService.to.loadContacts();
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

    final typeLabel = _transferType == 'international'
        ? 'Transfert International'
        : 'Transfert National';
    final confirmed = await BiometricGuard.show(
      context,
      action: typeLabel,
      amount: amount,
      recipient: recipient,
      actionIcon: Icons.send_rounded,
      actionColor: AppColors.transferColor,
    );
    if (!confirmed) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1800));

    // Sauvegarder la transaction avec TransactionService
    final txTypeLabel =
        _transferType == 'international' ? 'International' : 'National';
    final success = await TransactionService.to.saveTransfer(
      amount,
      'Transfert $txTypeLabel vers $recipient',
      recipient,
    );

    if (success) {
      // Rafraîchir les données utilisateur depuis le serveur pour avoir le solde correct
      await DatabaseService.to.refreshUserData();
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
            if (DatabaseService.to.contacts.length == 0)
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
            // Bénéficiaires récents
            _buildBeneficiariesSection(isDark),
            const SizedBox(height: 24),

            // Contacts avec compte UBAY
            _buildContactsSection(isDark),
            const SizedBox(height: 24),

            // Type de transfert (National / International)
            Text(
              'Type de transfert',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.grey900,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TransferTypeChip(
                    label: 'National',
                    icon: Icons.public,
                    isSelected: _transferType == 'national',
                    onTap: () => setState(() => _transferType = 'national'),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TransferTypeChip(
                    label: 'International',
                    icon: Icons.flight,
                    isSelected: _transferType == 'international',
                    onTap: () =>
                        setState(() => _transferType = 'international'),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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

  Widget _buildBeneficiariesSection(bool isDark) {
    return Obx(() {
      final beneficiaries = DatabaseService.to.recentBeneficiaries;

      if (beneficiaries.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bénéficiaires récents',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.grey900,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: beneficiaries.length,
              itemBuilder: (context, index) {
                final beneficiary = beneficiaries[index];
                final hasAccount = beneficiary['hasAccount'] == true;
                final user = beneficiary['user'];
                final phone = beneficiary['phone'] as String?;
                final name = user != null
                    ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
                        .trim()
                    : (beneficiary['name'] ?? phone ?? 'Inconnu');

                return GestureDetector(
                  onTap: () {
                    if (phone != null) {
                      setState(() {
                        _phoneCtrl.text = phone;
                        _selectedContact = {
                          'name': name,
                          'phone': phone,
                        };
                      });
                    }
                  },
                  child: Container(
                    width: 72,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: hasAccount
                                ? AppColors.primary.withOpacity(0.12)
                                : (isDark
                                    ? AppColors.grey800
                                    : AppColors.grey100),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: hasAccount
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: user?['photoUrl'] != null
                              ? ClipOval(
                                  child: Image.network(
                                    user['photoUrl'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.person,
                                      color: hasAccount
                                          ? AppColors.primary
                                          : AppColors.grey400,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  color: hasAccount
                                      ? AppColors.primary
                                      : AppColors.grey400,
                                ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          name.length > 12
                              ? '${name.substring(0, 12)}...'
                              : name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                hasAccount ? FontWeight.w600 : FontWeight.w400,
                            color: isDark ? AppColors.white : AppColors.grey800,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildContactsSection(bool isDark) {
    return Obx(() {
      final contacts = ContactService.to.platformContacts;

      if (contacts.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Contacts UBAY',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.grey900,
                ),
              ),
              if (contacts.length > 5)
                TextButton(
                  onPressed: () {
                    // Show all contacts
                  },
                  child: Text(
                    'Voir tout',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: contacts.take(10).length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _recipientController.text = contact.phone;
                    });
                    Get.snackbar(
                      'Contact sélectionné',
                      contact.name,
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          backgroundImage: contact.photoUrl != null
                              ? NetworkImage(contact.photoUrl!)
                              : null,
                          child: contact.photoUrl == null
                              ? Text(
                                  contact.name.isNotEmpty
                                      ? contact.name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          contact.name.split(' ').first,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.white : AppColors.grey900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TRANSFER TYPE CHIP
// ═════════════════════════════════════════════════════════════════════════════
class _TransferTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _TransferTypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected
              ? null
              : isDark
                  ? AppColors.grey800
                  : AppColors.grey100,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Colors.white
                  : isDark
                      ? AppColors.grey400
                      : AppColors.grey600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? AppColors.grey300
                        : AppColors.grey700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
