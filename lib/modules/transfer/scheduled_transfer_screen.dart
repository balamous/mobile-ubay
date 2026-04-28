import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../services/app_controller.dart';
import '../../services/scheduled_transfer_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/input_field.dart';

class ScheduledTransferScreen extends StatefulWidget {
  const ScheduledTransferScreen({super.key});

  @override
  State<ScheduledTransferScreen> createState() =>
      _ScheduledTransferScreenState();
}

class _ScheduledTransferScreenState extends State<ScheduledTransferScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form controllers for "Programmer" tab
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _frequency = 'weekly'; // weekly, monthly, daily

  final List<int> _quickAmounts = [1000, 2000, 5000, 10000, 20000, 50000];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Charger les prélèvements existants
    ScheduledTransferService.to.loadScheduledTransfers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _selectQuickAmount(int amount) {
    setState(() {
      _amountCtrl.text = amount.toString();
    });
  }

  Future<void> _pickDate(bool isStartDate) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? now : (_startDate ?? now),
      firstDate: isStartDate ? now : (_startDate ?? now),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.cardDark,
              onSurface: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Reset end date if it's before new start date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _scheduleTransfer() async {
    if (_phoneCtrl.text.length < 9) {
      Get.snackbar(
        'Erreur',
        'Veuillez entrer un numéro de téléphone valide',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      Get.snackbar(
        'Erreur',
        'Veuillez entrer un montant valide',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_startDate == null) {
      Get.snackbar(
        'Erreur',
        'Veuillez sélectionner une date de début',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Appel API pour créer le prélèvement
    final success = await ScheduledTransferService.to.createScheduledTransfer(
      recipientPhone: _phoneCtrl.text,
      amount: amount,
      frequency: _frequency,
      startDate:
          '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}',
      endDate: _endDate != null
          ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'
          : null,
      reason: _reasonCtrl.text.isNotEmpty ? _reasonCtrl.text : null,
    );

    if (success) {
      Get.snackbar(
        'Succès',
        'Transfert programmé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Reset form
      _phoneCtrl.clear();
      _amountCtrl.clear();
      _reasonCtrl.clear();
      setState(() {
        _startDate = null;
        _endDate = null;
        _frequency = 'weekly';
      });

      // Switch to history tab
      _tabController.animateTo(1);
    } else {
      Get.snackbar(
        'Erreur',
        'Impossible de programmer le transfert',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(isDark),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor:
                    isDark ? AppColors.grey400 : AppColors.grey600,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                dividerHeight: 0,
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: 'Programmer'),
                  Tab(text: 'Historique'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProgrammerTab(isDark),
                  _buildHistoriqueTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: isDark ? AppColors.white : AppColors.grey800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Prélèvement automatique',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgrammerTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phone input
          Text(
            'Numéro de téléphone',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.grey300 : AppColors.grey700,
            ),
          ),
          const SizedBox(height: 8),
          InputField(
            controller: _phoneCtrl,
            hint: 'Ex: XXX XX XX XX',
            keyboardType: TextInputType.phone,
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          const SizedBox(height: 20),

          // Frequency selector
          Text(
            'Fréquence',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.grey300 : AppColors.grey700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFrequencyChip('Quotidien', 'daily', isDark),
              const SizedBox(width: 8),
              _buildFrequencyChip('Hebdomadaire', 'weekly', isDark),
              const SizedBox(width: 8),
              _buildFrequencyChip('Mensuel', 'monthly', isDark),
            ],
          ),
          const SizedBox(height: 20),

          // Amount input
          Text(
            'Montant',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.grey300 : AppColors.grey700,
            ),
          ),
          const SizedBox(height: 8),
          InputField(
            controller: _amountCtrl,
            hint: '0 GNF',
            keyboardType: TextInputType.number,
            prefixIcon: Icon(Icons.attach_money_outlined),
          ),
          const SizedBox(height: 12),

          // Quick amounts
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAmounts.map((amount) {
              return _buildQuickAmountChip(amount, isDark);
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Date pickers
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  'Date début',
                  _startDate,
                  () => _pickDate(true),
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePicker(
                  'Date fin (optionnel)',
                  _endDate,
                  () => _pickDate(false),
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Reason input
          Text(
            'Motif (optionnel)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.grey300 : AppColors.grey700,
            ),
          ),
          const SizedBox(height: 8),
          InputField(
            controller: _reasonCtrl,
            hint: 'Ex: Loyer, Abonnement...',
            prefixIcon: Icon(Icons.edit_note_outlined),
          ),
          const SizedBox(height: 32),

          // Submit button
          CustomButton(
            label: 'Programmer le transfert',
            onPressed: _scheduleTransfer,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildFrequencyChip(String label, String value, bool isDark) {
    final isSelected = _frequency == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _frequency = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.cardDark : AppColors.grey100),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.grey400 : AppColors.grey600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountChip(int amount, bool isDark) {
    return GestureDetector(
      onTap: () => _selectQuickAmount(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          '${AppFormatters.formatCurrency(amount.toDouble())}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? date,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.grey200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.grey400 : AppColors.grey500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              date != null
                  ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                  : 'Sélectionner',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: date != null
                    ? (isDark ? AppColors.white : AppColors.grey900)
                    : (isDark ? AppColors.grey500 : AppColors.grey400),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoriqueTab(bool isDark) {
    return Obx(() {
      final transfers = ScheduledTransferService.to.scheduledTransfers;
      final isLoading = ScheduledTransferService.to.isLoading.value;

      if (isLoading) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (transfers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history_outlined,
                size: 64,
                color: isDark ? AppColors.grey600 : AppColors.grey300,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun prélèvement programmé',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.grey400 : AppColors.grey600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Commencez par programmer un transfert automatique',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.grey500 : AppColors.grey500,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => ScheduledTransferService.to.refresh(),
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: transfers.length,
          itemBuilder: (context, index) {
            final item = transfers[index];
            return _buildHistoryCard(item, isDark);
          },
        ),
      ).animate().fadeIn(duration: 300.ms);
    });
  }

  Widget _buildHistoryCard(ScheduledTransferModel item, bool isDark) {
    final isActive = item.isActive;
    final nextDate = item.nextExecution != null
        ? '${item.nextExecution!.substring(8, 10)}/${item.nextExecution!.substring(5, 7)}/${item.nextExecution!.substring(0, 4)}'
        : '---';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.grey200,
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: item.recipientPhotoUrl != null
                    ? NetworkImage(item.recipientPhotoUrl!)
                    : null,
                child: item.recipientPhotoUrl == null
                    ? Text(
                        item.recipientName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.recipientName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.white : AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.recipientPhone,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.grey400 : AppColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'Actif' : 'En pause',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                  'Montant', AppFormatters.formatCurrency(item.amount), isDark),
              _buildInfoItem('Fréquence', item.frequencyLabel, isDark),
              _buildInfoItem('Prochain', nextDate, isDark),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  isActive ? 'Mettre en pause' : 'Activer',
                  isActive ? Icons.pause : Icons.play_arrow,
                  isActive ? Colors.orange : Colors.green,
                  () async {
                    final newStatus = isActive ? 'paused' : 'active';
                    final success = await ScheduledTransferService.to
                        .updateStatus(item.id, newStatus);
                    if (success) {
                      Get.snackbar(
                        'Succès',
                        isActive
                            ? 'Prélèvement mis en pause'
                            : 'Prélèvement activé',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  'Supprimer',
                  Icons.delete_outline,
                  Colors.red,
                  () async {
                    final confirmed = await Get.dialog<bool>(
                      AlertDialog(
                        title: const Text('Confirmer'),
                        content: const Text(
                            'Voulez-vous vraiment supprimer ce prélèvement automatique ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(result: false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Get.back(result: true),
                            child: const Text(
                              'Supprimer',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      final success =
                          await ScheduledTransferService.to.delete(item.id);
                      if (success) {
                        Get.snackbar(
                          'Succès',
                          'Prélèvement supprimé',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.grey500 : AppColors.grey500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.grey900,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
