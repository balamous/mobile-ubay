import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../routes/app_routes.dart';

class OnboardingData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final LinearGradient gradient;
  final Color accentColor;

  const OnboardingData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.accentColor,
  });
}

const _pages = [
  OnboardingData(
    title: 'Bienvenue sur\nuBAY',
    subtitle: 'Votre banque numérique en Guinée.',
    description:
        'Gérez votre argent en Francs Guinéens (GNF) depuis votre smartphone. Dépôts, retraits, transferts — sécurisé et disponible 24h/24.',
    icon: Icons.account_balance_wallet_rounded,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1A1A2E), Color(0xFF2D2D50)],
    ),
    accentColor: Color(0xFFF07C00),
  ),
  OnboardingData(
    title: 'Orange, MTN\n& Cellcom',
    subtitle: 'Rechargez en 2 taps.',
    description:
        'Payez vos factures EDG & SEG, rechargez votre téléphone Orange, MTN ou Cellcom, et réglez vos services en quelques secondes.',
    icon: Icons.contactless_rounded,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD46A00), Color(0xFFF07C00)],
    ),
    accentColor: Color(0xFF1A1A2E),
  ),
  OnboardingData(
    title: 'Carte Visa\nVirtuelle & Physique',
    subtitle: 'Payez partout dans le monde.',
    description:
        'Obtenez votre carte VISA ou Mastercard instantanément. Contrôlez vos dépenses en GNF, bloquez ou activez votre carte en temps réel.',
    icon: Icons.credit_card_rounded,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8B7355), Color(0xFFBD9A75)],
    ),
    accentColor: Color(0xFFF07C00),
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _current = 0;

  late AnimationController _iconCtrl;
  late Animation<double> _iconScale;
  late Animation<double> _iconFloat;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _iconScale = Tween(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _iconCtrl, curve: Curves.easeInOut),
    );
    _iconFloat = Tween(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _iconCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_current];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(gradient: page.gradient),
        child: Stack(
          children: [
            // ── Background decoration ─────────────────────────────────
            ..._buildBgDecoration(page),

            // ── PageView (swipe) ──────────────────────────────────────
            PageView.builder(
              controller: _pageCtrl,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) => _OnboardingPage(
                data: _pages[i],
                iconCtrl: _iconCtrl,
                iconScale: _iconScale,
                iconFloat: _iconFloat,
                isActive: i == _current,
              ),
            ),

            // ── Bottom controls ───────────────────────────────────────
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _current == i ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _current == i
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),
                      // CTA Button
                      GestureDetector(
                        onTap: _next,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusLG),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _current == _pages.length - 1
                                    ? 'Commencer'
                                    : 'Continuer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: page.gradient.colors.first,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _current == _pages.length - 1
                                    ? Icons.rocket_launch_rounded
                                    : Icons.arrow_forward_rounded,
                                color: page.gradient.colors.first,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Skip
                      if (_current < _pages.length - 1)
                        GestureDetector(
                          onTap: _goToLogin,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              'Passer',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBgDecoration(OnboardingData page) {
    return [
      Positioned(
        top: -80,
        right: -80,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      Positioned(
        bottom: -100,
        left: -60,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.04),
          ),
        ),
      ),
      Positioned(
        top: MediaQuery.of(context).size.height * 0.25,
        left: -40,
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.03),
          ),
        ),
      ),
    ];
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  final AnimationController iconCtrl;
  final Animation<double> iconScale;
  final Animation<double> iconFloat;
  final bool isActive;

  const _OnboardingPage({
    required this.data,
    required this.iconCtrl,
    required this.iconScale,
    required this.iconFloat,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: size.height * 0.08),

            // ── Floating icon ──────────────────────────────────────────
            Center(
              child: AnimatedBuilder(
                animation: iconCtrl,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, iconFloat.value),
                  child: Transform.scale(
                    scale: iconScale.value,
                    child: child,
                  ),
                ),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Icon(
                    data.icon,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ).animate(target: isActive ? 1 : 0)
                .scale(begin: const Offset(0.8, 0.8), duration: 600.ms, curve: Curves.elasticOut),

            SizedBox(height: size.height * 0.07),

            // ── Subtitle chip ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                data.subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ).animate(target: isActive ? 1 : 0)
                .fadeIn(delay: 100.ms, duration: 400.ms)
                .slideX(begin: -0.2, end: 0),

            const SizedBox(height: 16),

            // ── Title ─────────────────────────────────────────────────
            Text(
              data.title,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.1,
                letterSpacing: -1,
              ),
            ).animate(target: isActive ? 1 : 0)
                .fadeIn(delay: 150.ms, duration: 400.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 18),

            // ── Description ───────────────────────────────────────────
            Text(
              data.description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.75),
                height: 1.65,
                fontWeight: FontWeight.w400,
              ),
            ).animate(target: isActive ? 1 : 0)
                .fadeIn(delay: 250.ms, duration: 400.ms)
                .slideY(begin: 0.15, end: 0),
          ],
        ),
      ),
    );
  }
}
