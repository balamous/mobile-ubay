import 'dart:math';
import 'package:fintech_b2b/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../routes/app_routes.dart';
import '../../core/utils/biometric_guard.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/database_service.dart';

// ── Step enum ─────────────────────────────────────────────────────────────────
enum _Step { type, design, confirm }

// ── Card theme option ─────────────────────────────────────────────────────────
class _CardTheme {
  final String name;
  final LinearGradient gradient;
  const _CardTheme(this.name, this.gradient);
}

final _cardThemes = [
  _CardTheme('Nuit Profonde', AppColors.cardSignatureGradient),
  _CardTheme('Flamme Orange', AppColors.cardDebitGradient),
  _CardTheme('Or Platine', AppColors.cardPlatinumGradient),
  _CardTheme(
      'Océan',
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
      )),
  _CardTheme(
      'Émeraude',
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF064E3B), Color(0xFF065F46)],
      )),
  _CardTheme(
      'Rubis',
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF7F1D1D), Color(0xFF991B1B)],
      )),
];

// ── Screen ────────────────────────────────────────────────────────────────────
class CreateCardScreen extends StatefulWidget {
  const CreateCardScreen({super.key});

  @override
  State<CreateCardScreen> createState() => _CreateCardScreenState();
}

class _CreateCardScreenState extends State<CreateCardScreen>
    with SingleTickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────────────────
  _Step _step = _Step.type;
  bool _isVirtual = true;
  bool _isVisa = true;
  int _selectedTheme = 0;
  double _spendingLimit = 10000000;
  bool _isLoading = false;
  // Custom holder name
  final _holderCtrl = TextEditingController();
  final _pinCtrls = List.generate(4, (_) => TextEditingController());
  final _pinNodes = List.generate(4, (_) => FocusNode());

  // Preview card - Dynamic fields
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _cardFlipped = false;

  // Dynamic card data (will be updated from API)
  String _generatedNumber = '';
  String _generatedCvv = '';
  String _expiryMonth = '';
  String _expiryYear = '';
  String _cardHolderName = '';

  // Dynamic gradient selection
  String _selectedGradientStart = '';
  String _selectedGradientEnd = '';

  // Default gradients based on card type
  static const Map<String, Map<String, String>> _defaultGradients = {
    'visa': {
      'start': '#667eea',
      'end': '#764ba2',
    },
    'mastercard': {
      'start': '#f093fb',
      'end': '#f5576c',
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeDynamicFields();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutCubic),
    );
  }

  void _initializeDynamicFields() async {
    // Initialize with temporary values (will be updated from API)
    final now = DateTime.now();
    _generatedNumber = _generateTempCardNumber();
    _generatedCvv = _generateTempCvv();
    _expiryMonth = now.month.toString().padLeft(2, '0');
    _expiryYear = (now.year + 4).toString();

    // Get the user's full name from cache first
    await _getUserNameFromCache();

    // Set default gradients based on card type
    _updateSelectedGradients();
  }

  String _generateTempCardNumber() {
    final r = Random();
    return List.generate(16, (_) => r.nextInt(10).toString()).join();
  }

  String _generateTempCvv() {
    final r = Random();
    return List.generate(3, (_) => r.nextInt(10).toString()).join();
  }

  Future<void> _getUserNameFromCache() async {
    try {
      // Récupérer les informations utilisateur depuis le cache
      final cachedData = await AuthService.to.getUserFromCache();

      if (cachedData != null) {
        // Construire le nom complet depuis les données du cache
        final firstName = cachedData['first_name'] ?? '';
        final lastName = cachedData['last_name'] ?? '';
        _cardHolderName = '$firstName $lastName'.trim();

        // Mettre à jour le champ de texte en majuscules
        if (_cardHolderName.isNotEmpty) {
          _cardHolderName = _cardHolderName.toUpperCase();
          _holderCtrl.text = _cardHolderName;
          print('DEBUG: Nom récupéré depuis cache: $_cardHolderName');
        } else {
          _cardHolderName = 'UTILISATEUR';
          _holderCtrl.text = _cardHolderName;
          print('DEBUG: Nom vide dans cache, utilisation de défaut');
        }
      } else {
        // Fallback: utiliser l'utilisateur connecté actuel
        final currentUser = AuthService.to.currentUser.value;
        _cardHolderName = currentUser?.fullName?.toUpperCase() ?? 'UTILISATEUR';
        _holderCtrl.text = _cardHolderName;
        print(
            'DEBUG: Cache vide, utilisation utilisateur actuel: $_cardHolderName');
      }
    } catch (e) {
      print('DEBUG: Erreur lors de la récupération du nom depuis cache: $e');
      // Fallback ultime
      _cardHolderName = 'UTILISATEUR';
      _holderCtrl.text = _cardHolderName;
    }
  }

  void _updateSelectedGradients() {
    // Use existing _CardTheme objects
    if (_selectedTheme < _cardThemes.length) {
      final theme = _cardThemes[_selectedTheme];
      // Extract colors from gradient for API
      final gradient = theme.gradient;
      final colors = gradient.colors;
      if (colors.isNotEmpty) {
        _selectedGradientStart =
            colors.first.value.toRadixString(16).padLeft(8, '0').substring(2);
        _selectedGradientEnd =
            colors.last.value.toRadixString(16).padLeft(8, '0').substring(2);
      }
    } else {
      // Use default gradients based on card type
      final cardType = _isVisa ? 'visa' : 'mastercard';
      final defaultGradient =
          _defaultGradients[cardType] ?? _defaultGradients['visa']!;
      _selectedGradientStart = defaultGradient['start']!;
      _selectedGradientEnd = defaultGradient['end']!;
    }
  }

  void _onCardTypeChanged(bool isVisa) {
    setState(() {
      _isVisa = isVisa;
      _updateSelectedGradients();
    });
  }

  void _onVirtualChanged(bool isVirtual) {
    setState(() {
      _isVirtual = isVirtual;
    });
  }

  void _onThemeChanged(int themeIndex) {
    setState(() {
      _selectedTheme = themeIndex;
      _updateSelectedGradients();
    });
  }

  void _onCardHolderChanged(String name) {
    setState(() {
      _cardHolderName = name;
    });
  }

  @override
  void dispose() {
    _holderCtrl.dispose();
    _flipCtrl.dispose();
    for (final c in _pinCtrls) {
      c.dispose();
    }
    for (final n in _pinNodes) {
      n.dispose();
    }
    super.dispose();
  }

  double get _fee => _isVirtual
      ? (_isVisa ? 15000.0 : 12000.0) // Virtual card fees
      : (_isVisa ? 25000.0 : 22000.0); // Physical card fees

  String get _networkLabel => _isVisa ? 'Visa' : 'Mastercard';
  String get _typeLabel => _isVirtual ? 'Virtuelle' : 'Physique';

  void _flipCard() {
    setState(() => _cardFlipped = !_cardFlipped);
    if (_cardFlipped) {
      _flipCtrl.forward();
    } else {
      _flipCtrl.reverse();
    }
  }

  void _nextStep() {
    if (_step == _Step.type) {
      setState(() => _step = _Step.design);
    } else if (_step == _Step.design) {
      setState(() => _step = _Step.confirm);
    } else {
      _confirmOrder();
    }
  }

  void _prevStep() {
    if (_step == _Step.design) {
      setState(() => _step = _Step.type);
    } else if (_step == _Step.confirm) {
      setState(() => _step = _Step.design);
    }
  }

  void _confirmOrder() async {
    final confirmed = await BiometricGuard.show(
      context,
      action: 'création de carte',
      amount: _fee,
      recipient: 'Carte $_networkLabel · $_typeLabel',
      actionIcon: Icons.credit_card_rounded,
      actionColor: AppColors.primary,
    );
    if (!confirmed) return;
    await _processOrder();
  }

  Future<void> _processOrder() async {
    setState(() => _isLoading = true);

    try {
      // Get current user
      final currentUser = AuthService.to.currentUser.value;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Create card via API
      final result = await ApiService.createCard({
        'userId': currentUser.id,
        'type': _isVisa ? 'visa' : 'mastercard',
        'isVirtual': _isVirtual,
        'gradientStart': _selectedGradientStart,
        'gradientEnd': _selectedGradientEnd,
      }, AuthService.to.token.value);

      print(result.toString());

      if (result['success'] == true) {
        // Update generated number with real one from API
        setState(() {
          _generatedNumber = result['data']['cardNumber'];
        });

        // Refresh cards in DatabaseService
        await DatabaseService.to.loadCards();

        _showSuccessDialog();
      } else {
        throw Exception(
            result['error'] ?? 'Erreur lors de la création de la carte');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer la carte: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SuccessDialog(
        isVirtual: _isVirtual,
        network: _networkLabel,
        cardNumber: _generatedNumber,
        onDone: () {
          Get.back(); // close dialog
          Get.offAllNamed(AppRoutes.card);
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Header gradient
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accent, Color(0xFF2D2D50)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── App bar ──────────────────────────────────────────────
                _buildAppBar(),
                // ── Stepper ──────────────────────────────────────────────
                _buildStepper(),
                const SizedBox(height: 20),
                // ── Content ──────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Preview card (always visible)
                        _buildPreviewCard(isDark),
                        const SizedBox(height: 24),
                        // Step content
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.1, 0),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: _buildStepContent(isDark),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom action bar ────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(isDark),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _step == _Step.type ? Get.back : _prevStep,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouvelle Carte',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Créez votre carte en quelques étapes',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    final steps = ['Type', 'Design', 'Confirmer'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = _step.index == i;
          final isDone = _step.index > i;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 3,
                        decoration: BoxDecoration(
                          color: isDone || isActive
                              ? AppColors.primary
                              : Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w400,
                          color: isActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.45),
                        ),
                        child: Text(steps[i]),
                      ),
                    ],
                  ),
                ),
                if (i < steps.length - 1) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Live card preview ─────────────────────────────────────────────────────
  Widget _buildPreviewCard(bool isDark) {
    final theme = _cardThemes[_selectedTheme];
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _flipAnim,
        builder: (_, __) {
          final angle = _flipAnim.value * pi;
          final isFront = angle < pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isFront
                ? _CardFace(
                    gradient: theme.gradient,
                    isVisa: _isVisa,
                    number: _generatedNumber,
                    holder: _holderCtrl.text.toUpperCase(),
                    expiryMonth: _expiryMonth,
                    expiryYear: _expiryYear,
                    isVirtual: _isVirtual,
                  )
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(pi),
                    child: _CardBack(
                      gradient: theme.gradient,
                      cvv: _generatedCvv,
                    ),
                  ),
          );
        },
      ),
    ).animate().scale(
          begin: const Offset(0.9, 0.9),
          duration: 400.ms,
          curve: Curves.elasticOut,
        );
  }

  // ── Step content ──────────────────────────────────────────────────────────
  Widget _buildStepContent(bool isDark) {
    switch (_step) {
      case _Step.type:
        return _StepType(
          key: const ValueKey('type'),
          isVirtual: _isVirtual,
          isVisa: _isVisa,
          isDark: isDark,
          onTypeChanged: (v) => setState(() => _isVirtual = v),
          onNetworkChanged: (v) => setState(() => _isVisa = v),
        );
      case _Step.design:
        return _StepDesign(
          key: const ValueKey('design'),
          themes: _cardThemes,
          selectedTheme: _selectedTheme,
          holderCtrl: _holderCtrl,
          spendingLimit: _spendingLimit,
          isDark: isDark,
          onThemeChanged: (i) => setState(() => _selectedTheme = i),
          onLimitChanged: (v) => setState(() => _spendingLimit = v),
          onHolderChanged: (_) => setState(() {}),
        );
      case _Step.confirm:
        return _StepConfirm(
          key: const ValueKey('confirm'),
          isVirtual: _isVirtual,
          isVisa: _isVisa,
          themeName: _cardThemes[_selectedTheme].name,
          holder: _holderCtrl.text,
          limit: _spendingLimit,
          fee: _fee,
          isDark: isDark,
        );
    }
  }

  // ── Bottom action bar ─────────────────────────────────────────────────────
  Widget _buildBottomBar(bool isDark) {
    final label = _step == _Step.confirm ? 'Commander la carte' : 'Continuer';
    final icon = Icon(
      _step == _Step.confirm
          ? Icons.credit_card_rounded
          : Icons.arrow_forward_rounded,
      color: Colors.white,
      size: 18,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_step != _Step.type) ...[
            GestureDetector(
              onTap: _prevStep,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: CustomButton(
              label: label,
              isLoading: _isLoading,
              onPressed: _nextStep,
              gradient: AppColors.primaryGradient,
              suffixIcon: icon,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Step 1 — Choisir le type
// ══════════════════════════════════════════════════════════════════════════════

class _StepType extends StatelessWidget {
  final bool isVirtual;
  final bool isVisa;
  final bool isDark;
  final ValueChanged<bool> onTypeChanged;
  final ValueChanged<bool> onNetworkChanged;

  const _StepType({
    super.key,
    required this.isVirtual,
    required this.isVisa,
    required this.isDark,
    required this.onTypeChanged,
    required this.onNetworkChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Type de carte', isDark),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TypeCard(
                icon: Icons.phonelink_rounded,
                title: 'Virtuelle',
                subtitle: 'Disponible\nimmédiatement',
                fee: '50 000 GNF',
                isSelected: isVirtual,
                isDark: isDark,
                badge: 'INSTANTANÉ',
                badgeColor: AppColors.success,
                onTap: () => onTypeChanged(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TypeCard(
                icon: Icons.credit_card_rounded,
                title: 'Physique',
                subtitle: 'Livrée en\n3-5 jours ouvrés',
                fee: '150 000 GNF',
                isSelected: !isVirtual,
                isDark: isDark,
                badge: 'LIVRAISON',
                badgeColor: AppColors.primary,
                onTap: () => onTypeChanged(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _sectionTitle('Réseau de paiement', isDark),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _NetworkCard(
                label: 'Visa',
                isSelected: isVisa,
                isDark: isDark,
                color: const Color(0xFF1A1F71),
                onTap: () => onNetworkChanged(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NetworkCard(
                label: 'Mastercard',
                isSelected: !isVisa,
                isDark: isDark,
                color: const Color(0xFFEB001B),
                onTap: () => onNetworkChanged(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _InfoBanner(
          icon: Icons.info_outline_rounded,
          text: isVirtual
              ? 'La carte virtuelle est disponible immédiatement dans votre compte. Idéale pour les achats en ligne.'
              : 'La carte physique sera livrée à votre adresse enregistrée sous 3 à 5 jours ouvrés à Conakry et régions.',
          isDark: isDark,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Step 2 — Design
// ══════════════════════════════════════════════════════════════════════════════

class _StepDesign extends StatelessWidget {
  final List<_CardTheme> themes;
  final int selectedTheme;
  final TextEditingController holderCtrl;
  final double spendingLimit;
  final bool isDark;
  final ValueChanged<int> onThemeChanged;
  final ValueChanged<double> onLimitChanged;
  final ValueChanged<String> onHolderChanged;

  const _StepDesign({
    super.key,
    required this.themes,
    required this.selectedTheme,
    required this.holderCtrl,
    required this.spendingLimit,
    required this.isDark,
    required this.onThemeChanged,
    required this.onLimitChanged,
    required this.onHolderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Thème de la carte', isDark),
        const SizedBox(height: 12),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: themes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final isSelected = i == selectedTheme;
              return GestureDetector(
                onTap: () => onThemeChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 90,
                  decoration: BoxDecoration(
                    gradient: themes[i].gradient,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          themes[i].name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle('Nom sur la carte', isDark),
        const SizedBox(height: 10),
        _cardField(
          child: TextField(
            controller: holderCtrl,
            textCapitalization: TextCapitalization.characters,
            onChanged: onHolderChanged,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'NOM PRÉNOM',
              hintStyle:
                  const TextStyle(color: AppColors.grey400, letterSpacing: 1),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: const Icon(Icons.person_outline_rounded,
                  color: AppColors.grey400, size: 20),
            ),
          ),
          isDark: isDark,
        ),
        const SizedBox(height: 24),
        _sectionTitle('Plafond mensuel de dépense', isDark),
        const SizedBox(height: 4),
        Text(
          AppFormatters.formatCurrency(spendingLimit),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor:
                isDark ? AppColors.borderDark : AppColors.grey200,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.15),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: spendingLimit,
            min: 1000000,
            max: 100000000,
            divisions: 99,
            onChanged: onLimitChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1M GNF',
                style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary)),
            Text('100M GNF',
                style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Step 3 — Confirmation
// ══════════════════════════════════════════════════════════════════════════════

class _StepConfirm extends StatelessWidget {
  final bool isVirtual;
  final bool isVisa;
  final String themeName;
  final String holder;
  final double limit;
  final double fee;
  final bool isDark;

  const _StepConfirm({
    super.key,
    required this.isVirtual,
    required this.isVisa,
    required this.themeName,
    required this.holder,
    required this.limit,
    required this.fee,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Récapitulatif de votre commande', isDark),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
            border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _ConfirmRow(
                label: 'Type de carte',
                value: isVirtual ? 'Carte Virtuelle' : 'Carte Physique',
                icon: isVirtual
                    ? Icons.phonelink_rounded
                    : Icons.credit_card_rounded,
                iconColor: AppColors.primary,
                isDark: isDark,
              ),
              _divider(isDark),
              _ConfirmRow(
                label: 'Réseau',
                value: isVisa ? 'Visa' : 'Mastercard',
                icon: Icons.payment_rounded,
                iconColor:
                    isVisa ? const Color(0xFF1A1F71) : const Color(0xFFEB001B),
                isDark: isDark,
              ),
              _divider(isDark),
              _ConfirmRow(
                label: 'Thème',
                value: themeName,
                icon: Icons.palette_outlined,
                iconColor: AppColors.primary,
                isDark: isDark,
              ),
              _divider(isDark),
              _ConfirmRow(
                label: 'Titulaire',
                value: holder.isEmpty ? '—' : holder.toUpperCase(),
                icon: Icons.person_outline_rounded,
                iconColor: AppColors.textSecondary,
                isDark: isDark,
              ),
              _divider(isDark),
              _ConfirmRow(
                label: 'Plafond mensuel',
                value: AppFormatters.formatCurrency(limit),
                icon: Icons.bar_chart_rounded,
                iconColor: AppColors.primary,
                isDark: isDark,
              ),
              _divider(isDark),
              _ConfirmRow(
                label: 'Délai',
                value: isVirtual ? 'Immédiat' : '3–5 jours ouvrés',
                icon: Icons.schedule_rounded,
                iconColor: isVirtual ? AppColors.success : AppColors.warning,
                isDark: isDark,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Fee card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Frais de création',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    Text(
                      AppFormatters.formatCurrency(fee),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Débité de',
                      style: TextStyle(color: Colors.white60, fontSize: 10)),
                  Text('votre solde',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        _InfoBanner(
          icon: Icons.lock_outline_rounded,
          text:
              'Votre commande sera validée après confirmation par code PIN. Les frais seront débités de votre solde principal.',
          isDark: isDark,
        ),

        if (!isVirtual) ...[
          const SizedBox(height: 12),
          _InfoBanner(
            icon: Icons.local_shipping_outlined,
            text:
                'Livraison disponible à Conakry (Kaloum, Ratoma, Matoto, Dixinn, Matam) et dans les préfectures de Guinée.',
            isDark: isDark,
            color: AppColors.warning,
          ),
        ],
      ],
    );
  }

  Widget _divider(bool isDark) => Divider(
        height: 1,
        thickness: 1,
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        indent: 16,
        endIndent: 16,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// Card Front & Back widgets
// ══════════════════════════════════════════════════════════════════════════════

class _CardFace extends StatelessWidget {
  final LinearGradient gradient;
  final bool isVisa;
  final String number;
  final String holder;
  final String expiryMonth;
  final String expiryYear;
  final bool isVirtual;

  const _CardFace({
    required this.gradient,
    required this.isVisa,
    required this.number,
    required this.holder,
    required this.expiryMonth,
    required this.expiryYear,
    required this.isVirtual,
  });

  @override
  Widget build(BuildContext context) {
    final masked = '**** **** **** ${number.substring(number.length - 4)}';

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppConstants.radius2XL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Topographic line decoration
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radius2XL),
              child: CustomPaint(painter: _TopoLinePainter()),
            ),
          ),
          // Card content
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Bank logo
                    const Text(
                      'uBAY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (isVirtual)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Text(
                          'VIRTUELLE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                // Chip
                Container(
                  width: 36,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(5),
                    border:
                        Border.all(color: const Color(0xFFB8960C), width: 0.5),
                  ),
                  child: CustomPaint(painter: _ChipPainter()),
                ),
                const SizedBox(height: 12),
                // Card number
                Text(
                  masked,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2.5,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TITULAIRE',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 8,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          holder.isEmpty ? 'NOM PRÉNOM' : holder,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'EXPIRE',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 8,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '$expiryMonth/$expiryYear',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    // Network logo
                    isVisa
                        ? const Text(
                            'VISA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              letterSpacing: -0.5,
                            ),
                          )
                        : Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEB001B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(-10, 0),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF79E1B)
                                        .withOpacity(0.85),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  final LinearGradient gradient;
  final String cvv;

  const _CardBack({required this.gradient, required this.cvv});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppConstants.radius2XL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 28),
          Container(
            height: 40,
            color: Colors.black.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 70,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      cvv,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Retournez pour voir le CVV · Tapez la carte pour la retourner',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ══════════════════════════════════════════════════════════════════════════════

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String fee;
  final bool isSelected;
  final bool isDark;
  final String badge;
  final Color badgeColor;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.fee,
    required this.isSelected,
    required this.isDark,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : (isDark ? AppColors.cardDark : AppColors.white),
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.15)
                    : (isDark ? AppColors.surfaceDark : AppColors.grey100),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: isSelected ? AppColors.primary : AppColors.grey400,
                  size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.textOnDark : AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fee,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final Color color;
  final VoidCallback onTap;

  const _NetworkCard({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 64,
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.08)
              : (isDark ? AppColors.cardDark : AppColors.white),
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (label == 'Visa')
              Text(
                'VISA',
                style: TextStyle(
                  color: isSelected ? color : AppColors.grey400,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFEB001B)
                          : AppColors.grey300,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-8, 0),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF79E1B)
                            : AppColors.grey400,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-16, 0),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? color
                            : (isDark
                                ? AppColors.textOnDarkSecondary
                                : AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle_rounded, color: color, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool isDark;

  const _ConfirmRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  final Color color;

  const _InfoBanner({
    required this.icon,
    required this.text,
    required this.isDark,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success dialog ─────────────────────────────────────────────────────────────

class _SuccessDialog extends StatelessWidget {
  final bool isVirtual;
  final String network;
  final String cardNumber;
  final VoidCallback onDone;

  const _SuccessDialog({
    required this.isVirtual,
    required this.network,
    required this.cardNumber,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: BorderRadius.circular(AppConstants.radius2XL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 44,
              ),
            )
                .animate()
                .scale(
                    begin: const Offset(0, 0),
                    duration: 500.ms,
                    curve: Curves.elasticOut)
                .then()
                .shimmer(duration: 800.ms, color: Colors.white30),

            const SizedBox(height: 20),
            Text(
              isVirtual ? 'Carte créée !' : 'Commande envoyée !',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isVirtual
                  ? 'Votre carte $network virtuelle est active et prête à l\'emploi.'
                  : 'Votre carte $network physique sera livrée sous 3 à 5 jours ouvrés.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.credit_card_rounded,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Voir mes cartes',
              onPressed: onDone,
              gradient: AppColors.primaryGradient,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Painters ─────────────────────────────────────────────────────────────────

class _TopoLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 6; i++) {
      final offset = i * 35.0;
      final path = Path();
      path.moveTo(0, size.height * 0.3 + offset);
      path.cubicTo(
        size.width * 0.2,
        size.height * 0.1 + offset,
        size.width * 0.7,
        size.height * 0.5 + offset,
        size.width + 20,
        size.height * 0.2 + offset,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB8960C).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.15, size.height * 0.2, size.width * 0.7,
            size.height * 0.6),
        paint);
    canvas.drawLine(Offset(size.width / 2, size.height * 0.2),
        Offset(size.width / 2, size.height * 0.8), paint);
    canvas.drawLine(Offset(size.width * 0.15, size.height / 2),
        Offset(size.width * 0.85, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Widget _sectionTitle(String text, bool isDark) {
  return Text(
    text,
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
      letterSpacing: -0.2,
    ),
  );
}

Widget _cardField({required Widget child, required bool isDark}) {
  return Container(
    decoration: BoxDecoration(
      color: isDark ? AppColors.cardDark : AppColors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        width: 1.5,
      ),
    ),
    child: child,
  );
}
