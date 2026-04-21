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

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _amountCtrl = TextEditingController();
  final _merchantCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final AppController _appCtrl = AppController.to;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _merchants = [
    {
      'name': 'Super 5 Supermarché',
      'icon': Icons.store_rounded,
      'color': AppColors.success
    },
    {
      'name': 'Pharmacie Centrale',
      'icon': Icons.local_pharmacy_rounded,
      'color': AppColors.error
    },
    {
      'name': 'Station Total',
      'icon': Icons.local_gas_station_rounded,
      'color': AppColors.warning
    },
    {
      'name': 'Restaurant Le Plateau',
      'icon': Icons.restaurant_rounded,
      'color': AppColors.accent
    },
    {
      'name': 'École Française',
      'icon': Icons.school_rounded,
      'color': AppColors.primary
    },
    {
      'name': 'Hôpital Principal',
      'icon': Icons.local_hospital_rounded,
      'color': AppColors.withdrawColor
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _amountCtrl.dispose();
    _merchantCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) return;

    final confirmed = await BiometricGuard.show(
      context,
      action: 'paiement',
      amount: amount,
      recipient: _merchantCtrl.text.isEmpty ? 'Marchand' : _merchantCtrl.text,
      actionIcon: Icons.point_of_sale_rounded,
      actionColor: AppColors.paymentColor,
    );
    if (!confirmed) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1800));

    // Sauvegarder la transaction avec TransactionService
    final success = await TransactionService.to.savePayment(
      amount,
      'Paiement - ${_merchantCtrl.text.isEmpty ? 'Marchand' : _merchantCtrl.text}',
      _merchantCtrl.text.isEmpty ? 'Marchand' : _merchantCtrl.text,
    );

    if (success) {
      _appCtrl.updateBalance(-amount);
    }
    setState(() => _isLoading = false);
    await SuccessOverlay.show(
      title: 'Paiement réussi !',
      subtitle: 'Votre paiement a été traité avec succès.',
      amount: amount,
      reference: _appCtrl.generateReference('PAY'),
      onDone: Get.back,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: _backButton(isDark),
        title: const Text('Payer'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.paymentColor,
          indicatorWeight: 3,
          labelColor: AppColors.paymentColor,
          unselectedLabelColor: AppColors.grey400,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Marchand'),
            Tab(text: 'Scanner QR'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildMerchantTab(isDark),
          _buildQrTab(isDark),
        ],
      ),
    );
  }

  Widget _buildMerchantTab(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Merchant quick select
          Text(
            'Marchands populaires',
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
            childAspectRatio: 1.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: _merchants.map((m) {
              final isSelected = _merchantCtrl.text == m['name'];
              return GestureDetector(
                onTap: () => setState(() => _merchantCtrl.text = m['name']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (m['color'] as Color).withOpacity(0.12)
                        : isDark
                            ? AppColors.cardDark
                            : AppColors.white,
                    borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                    border: Border.all(
                      color: isSelected
                          ? m['color'] as Color
                          : isDark
                              ? AppColors.grey800
                              : AppColors.grey200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(m['icon'] as IconData,
                          color: m['color'] as Color, size: 26),
                      const SizedBox(height: 6),
                      Text(
                        (m['name'] as String).split(' ').first,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.grey300 : AppColors.grey700,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),
          InputField(
            label: 'Nom du marchand',
            hint: 'Ex: Super 5 Supermarché',
            controller: _merchantCtrl,
            prefixIcon: const Icon(Icons.store_outlined,
                size: 20, color: AppColors.grey400),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          InputField(
            label: 'Référence de commande (optionnel)',
            hint: 'Ex: CMD-2024-001',
            controller: _refCtrl,
            prefixIcon: const Icon(Icons.receipt_long_outlined,
                size: 20, color: AppColors.grey400),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 32),
          CustomButton(
            label: _isLoading ? 'Traitement...' : 'Payer maintenant',
            isLoading: _isLoading,
            onPressed: (_amountCtrl.text.isNotEmpty &&
                    (double.tryParse(_amountCtrl.text) ?? 0) > 0)
                ? _pay
                : null,
            gradient: AppColors.goldGradient,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildQrTab(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.paymentColor, width: 2),
              borderRadius: BorderRadius.circular(20),
              color: isDark ? AppColors.grey800 : AppColors.grey50,
            ),
            child: Stack(
              children: [
                // Animated scan line
                _ScanLine(),
                // Corner markers
                ..._buildCorners(),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 72,
                        color: AppColors.paymentColor.withOpacity(0.25),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Pointez la caméra\nvers le QR code',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? AppColors.grey400 : AppColors.grey500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 32),
          Text(
            'Simulation — mode démo',
            style: TextStyle(color: AppColors.grey400, fontSize: 13),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              _amountCtrl.text = '45000';
              _merchantCtrl.text = 'Super 5 Supermarché';
              _tabCtrl.animateTo(0);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              ),
              child: const Text(
                'Simuler un scan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const size = 24.0;
    const thickness = 3.0;
    final color = AppColors.paymentColor;
    Widget corner(bool top, bool left) => Positioned(
          top: top ? 0 : null,
          bottom: top ? null : 0,
          left: left ? 0 : null,
          right: left ? null : 0,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border(
                top: top
                    ? BorderSide(color: color, width: thickness)
                    : BorderSide.none,
                bottom: !top
                    ? BorderSide(color: color, width: thickness)
                    : BorderSide.none,
                left: left
                    ? BorderSide(color: color, width: thickness)
                    : BorderSide.none,
                right: !left
                    ? BorderSide(color: color, width: thickness)
                    : BorderSide.none,
              ),
            ),
          ),
        );
    return [
      corner(true, true),
      corner(true, false),
      corner(false, true),
      corner(false, false),
    ];
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

class _ScanLine extends StatefulWidget {
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Positioned(
        top: 20 + (240 * _anim.value),
        left: 20,
        right: 20,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.paymentColor.withOpacity(0.8),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
