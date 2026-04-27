import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/user_model.dart';
import '../../services/app_controller.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Completion helper
// ─────────────────────────────────────────────────────────────────────────────
double _computeCompletion(UserModel? u) {
  if (u == null) return 0.0;

  final fields = [
    u.firstName,
    u.lastName,
    u.email,
    u.phone,
    u.birthDate?.toString(),
    u.birthPlace,
    u.gender,
    u.profession,
    u.employer,
    u.city,
    u.commune,
    u.neighborhood,
    u.nationality,
    u.idType,
    u.idNumber,
    u.idIssueDate,
    u.idExpiryDate?.toString(),
  ];
  final filled =
      fields.where((f) => f != null && f.toString().isNotEmpty).length;
  return filled / fields.length;
}

// ─────────────────────────────────────────────────────────────────────────────
// PersonalInfoScreen
// ─────────────────────────────────────────────────────────────────────────────
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Helpers date (partagés entre les deux onglets) ────────────────────────
  static const _frMonths = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  String formatDate(DateTime d) =>
      '${d.day} ${_frMonths[d.month - 1]} ${d.year}';

  DateTime? parseDate(String? text) {
    if (text == null || text.isEmpty) return null;
    final parts = text.trim().split(' ');
    if (parts.length < 3) return null;
    final day = int.tryParse(parts[0]);
    final month = _frMonths.indexOf(parts[1].toLowerCase()) + 1;
    final year = int.tryParse(parts[parts.length - 1]);
    if (day == null || month == 0 || year == null) return null;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  // Method to save user profile to database - accessible by both tabs
  Future<Map<String, dynamic>?> saveUserProfileToDatabase(
      String userId, Map<String, dynamic> data) async {
    try {
      debugPrint('Saving user profile to database: $data');
      final result = await ApiService.updateUserProfile(userId, data);

      if (result['success'] == true) {
        debugPrint('Profile saved successfully to database');
        Get.snackbar(
          'Succès',
          'Informations sauvegardées',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return result;
      } else {
        debugPrint('Failed to save profile: ${result['error']}');
        Get.snackbar(
          'Erreur',
          'Impossible de sauvegarder: ${result['error']}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.9),
          colorText: Colors.white,
        );
        return result;
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      Get.snackbar(
        'Erreur',
        'Erreur lors de la sauvegarde',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.9),
        colorText: Colors.white,
      );
      return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          _buildHeader(isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _ProfileTab(isDark: isDark),
                _DocumentTab(isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Back button — même style que create_card / register
                  GestureDetector(
                    onTap: Get.back,
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
                  // Titre + sous-titre
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informations personnelles',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Gérez vos informations de profil',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge de complétion
                  Obx(() {
                    final pct = _computeCompletion(AppController.to.user.value);
                    final pctInt = (pct * 100).round();
                    final badgeColor = pct >= 0.8
                        ? AppColors.success
                        : pct >= 0.5
                            ? AppColors.warning
                            : AppColors.error;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.35), width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: badgeColor,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$pctInt%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            // ── Barre de progression ─────────────────────────────────────
            Obx(() {
              final pct = _computeCompletion(AppController.to.user.value);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 5,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Complétez votre profil pour accéder à toutes les fonctionnalités',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
            // ── TabBar ───────────────────────────────────────────────────
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.white.withOpacity(0.15),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.55),
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.person_rounded, size: 18),
                  text: 'Profil',
                  iconMargin: EdgeInsets.only(bottom: 2),
                ),
                Tab(
                  icon: Icon(Icons.badge_rounded, size: 18),
                  text: "Pièce d'identité",
                  iconMargin: EdgeInsets.only(bottom: 2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: Profile
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final bool isDark;
  const _ProfileTab({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = AppController.to.user.value;
      if (user == null) {
        return const Center(
          child: Text('Chargement des informations utilisateur...'),
        );
      }

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Section 1 - Contact
            _SectionCard(
              isDark: isDark,
              icon: Icons.person_rounded,
              iconColor: AppColors.primary,
              title: 'Contact',
              onEdit: () => _showContactSheet(context, isDark, user),
              rows: [
                _InfoRow(
                    label: 'Prénom', value: user.firstName, isDark: isDark),
                _InfoRow(label: 'Nom', value: user.lastName, isDark: isDark),
                _InfoRow(label: 'Email', value: user.email, isDark: isDark),
                _InfoRow(
                    label: 'Téléphone',
                    value: user.phone.isNotEmpty ? '+224 ${user.phone}' : null,
                    isDark: isDark),
              ],
            ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 16),

            // Section 2 - Date de naissance
            _SectionCard(
              isDark: isDark,
              icon: Icons.cake_rounded,
              iconColor: const Color(0xFF8B5CF6),
              title: 'Date de naissance',
              onEdit: () => _showBirthSheet(context, isDark, user),
              rows: [
                _InfoRow(
                    label: 'Date de naissance',
                    value: user.birthDate,
                    isDark: isDark),
                _InfoRow(
                    label: 'Lieu de naissance',
                    value: user.birthPlace,
                    isDark: isDark),
                _InfoRow(
                  label: 'Sexe',
                  value: user.gender,
                  isDark: isDark,
                  prefix: user.gender == 'Féminin'
                      ? '♀ '
                      : user.gender == 'Masculin'
                          ? '♂ '
                          : null,
                ),
              ],
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 16),

            // Section 3 - Profession
            _SectionCard(
              isDark: isDark,
              icon: Icons.work_rounded,
              iconColor: AppColors.info,
              title: 'Profession',
              onEdit: () => _showProfessionSheet(context, isDark, user),
              rows: [
                _InfoRow(
                    label: 'Profession',
                    value: user.profession,
                    isDark: isDark),
                _InfoRow(
                    label: 'Entreprise / employeur',
                    value: user.employer,
                    isDark: isDark),
              ],
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 16),

            // Section 4 - Ville de résidence
            _SectionCard(
              isDark: isDark,
              icon: Icons.location_on_rounded,
              iconColor: AppColors.success,
              title: 'Ville de résidence',
              onEdit: () => _showLocationSheet(context, isDark, user),
              rows: [
                _InfoRow(
                    label: 'Ville de résidence',
                    value: user.city,
                    isDark: isDark),
                _InfoRow(label: 'Commune', value: user.commune, isDark: isDark),
                _InfoRow(
                    label: 'Quartier',
                    value: user.neighborhood,
                    isDark: isDark),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 32),
          ],
        ),
      );
    });
  }

  void _showContactSheet(BuildContext context, bool isDark, UserModel user) {
    final firstCtrl = TextEditingController(text: user.firstName);
    final lastCtrl = TextEditingController(text: user.lastName);
    final emailCtrl = TextEditingController(text: user.email);
    final phoneCtrl = TextEditingController(text: user.phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSheet(
        isDark: isDark,
        title: 'Modifier le contact',
        onSave: () async {
          final currentUser = AppController.to.user.value;
          if (currentUser != null) {
            // Save to database via API
            final result = await context
                .findAncestorStateOfType<_PersonalInfoScreenState>()
                ?.saveUserProfileToDatabase(currentUser.id, {
              'firstName': firstCtrl.text.trim(),
              'lastName': lastCtrl.text.trim(),
              'email': emailCtrl.text.trim(),
              'phone': phoneCtrl.text.trim(),
            });

            if (result?['success'] == true) {
              // Mettre à jour le state local après succès
              final updatedUser = currentUser.copyWith(
                firstName: firstCtrl.text.trim(),
                lastName: lastCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
              );
              AppController.to.updateUser(updatedUser);

              // Rafraîchir depuis le serveur
              await DatabaseService.to.refreshUserData();

              Get.back();
            }
          }
        },
        fields: [
          _FieldConfig(label: 'Prénom', controller: firstCtrl),
          _FieldConfig(label: 'Nom', controller: lastCtrl),
          _FieldConfig(
              label: 'Email',
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress),
          _FieldConfig(
              label: 'Téléphone',
              controller: phoneCtrl,
              keyboardType: TextInputType.phone),
        ],
      ),
    );
  }

  void _showBirthSheet(BuildContext context, bool isDark, UserModel user) {
    final parentState =
        context.findAncestorStateOfType<_PersonalInfoScreenState>();
    DateTime? selectedDate = parentState?.parseDate(user.birthDate);
    String? selectedDateString = user.birthDate;
    final birthPlaceCtrl = TextEditingController(text: user.birthPlace ?? '');
    String selectedGender = user.gender ?? 'Masculin';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => _EditSheet(
          isDark: isDark,
          title: 'Modifier la naissance',
          onSave: () async {
            final currentUser = AppController.to.user.value;
            if (currentUser != null) {
              // Préparer les données au format ISO pour l'API
              final isoDate = selectedDate != null
                  ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                  : selectedDateString;
              final apiGender = selectedGender == 'Masculin'
                  ? 'male'
                  : (selectedGender == 'Féminin' ? 'female' : 'other');

              // Save to database via API
              final result = await context
                  .findAncestorStateOfType<_PersonalInfoScreenState>()
                  ?.saveUserProfileToDatabase(currentUser.id, {
                'birthDate': isoDate,
                'birthPlace': birthPlaceCtrl.text.trim(),
                'gender': apiGender,
              });

              if (result?['success'] == true) {
                // Mettre à jour le state local avec les données correctes
                final updatedUser = currentUser.copyWith(
                  birthDate: isoDate,
                  birthPlace: birthPlaceCtrl.text.trim(),
                  gender: selectedGender,
                );
                AppController.to.updateUser(updatedUser);

                // Rafraîchir depuis le serveur pour synchroniser
                await DatabaseService.to.refreshUserData();

                Get.back();
              }
            }
          },
          fields: [
            // Champ Date de naissance avec sélecteur
            _FieldConfig(
              label: 'Date de naissance',
              controller: TextEditingController(
                text: selectedDateString ?? '',
              ),
              readOnly: true,
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: ctx,
                  initialDate: selectedDate ?? DateTime(1990),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  locale: const Locale('fr', 'FR'),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: AppColors.primary,
                          onPrimary: Colors.white,
                          surface: isDark ? AppColors.cardDark : Colors.white,
                          onSurface: isDark
                              ? AppColors.textOnDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setSheetState(() {
                    selectedDate = picked;
                    selectedDateString = parentState?.formatDate(picked);
                  });
                }
              },
            ),
            _FieldConfig(
                label: 'Lieu de naissance', controller: birthPlaceCtrl),
          ],
          extraContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Sexe',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: ['Masculin', 'Féminin']
                    .map((g) => ChoiceChip(
                          label: Text(g),
                          selected: selectedGender == g,
                          onSelected: (_) =>
                              setSheetState(() => selectedGender = g),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: selectedGender == g
                                ? Colors.white
                                : isDark
                                    ? AppColors.textOnDark
                                    : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          backgroundColor: isDark
                              ? AppColors.backgroundDark
                              : AppColors.backgroundLight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: selectedGender == g
                                  ? AppColors.primary
                                  : isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfessionSheet(BuildContext context, bool isDark, UserModel user) {
    final profCtrl = TextEditingController(text: user.profession ?? '');
    final empCtrl = TextEditingController(text: user.employer ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSheet(
        isDark: isDark,
        title: 'Modifier la profession',
        onSave: () async {
          final currentUser = AppController.to.user.value;
          if (currentUser != null) {
            // Save to database via API
            final result = await context
                .findAncestorStateOfType<_PersonalInfoScreenState>()
                ?.saveUserProfileToDatabase(currentUser.id, {
              'profession': profCtrl.text.trim(),
              'employer': empCtrl.text.trim(),
            });

            if (result?['success'] == true) {
              // Mettre à jour le state local après succès
              final updatedUser = currentUser.copyWith(
                profession: profCtrl.text.trim(),
                employer: empCtrl.text.trim(),
              );
              AppController.to.updateUser(updatedUser);

              // Rafraîchir depuis le serveur
              await DatabaseService.to.refreshUserData();

              Get.back();
              Get.back();
            }
          }
        },
        fields: [
          _FieldConfig(label: 'Profession', controller: profCtrl),
          _FieldConfig(label: 'Entreprise / employeur', controller: empCtrl),
        ],
      ),
    );
  }

  void _showLocationSheet(BuildContext context, bool isDark, UserModel user) {
    final cityCtrl = TextEditingController(text: user.city ?? '');
    final communeCtrl = TextEditingController(text: user.commune ?? '');
    final neighborhoodCtrl =
        TextEditingController(text: user.neighborhood ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSheet(
        isDark: isDark,
        title: 'Modifier la résidence',
        onSave: () async {
          final currentUser = AppController.to.user.value;
          if (currentUser != null) {
            // Save to database via API
            final result = await context
                .findAncestorStateOfType<_PersonalInfoScreenState>()
                ?.saveUserProfileToDatabase(currentUser.id, {
              'city': cityCtrl.text.trim(),
              'commune': communeCtrl.text.trim(),
              'neighborhood': neighborhoodCtrl.text.trim(),
            });

            if (result?['success'] == true) {
              // Mettre à jour le state local après succès
              final updatedUser = currentUser.copyWith(
                city: cityCtrl.text.trim(),
                commune: communeCtrl.text.trim(),
                neighborhood: neighborhoodCtrl.text.trim(),
              );
              AppController.to.updateUser(updatedUser);

              // Rafraîchir depuis le serveur
              await DatabaseService.to.refreshUserData();

              Get.back();
            }
          }
        },
        fields: [
          _FieldConfig(label: 'Ville de résidence', controller: cityCtrl),
          _FieldConfig(label: 'Commune', controller: communeCtrl),
          _FieldConfig(label: 'Quartier', controller: neighborhoodCtrl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Card widget
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onEdit;
  final List<_InfoRow> rows;

  const _SectionCard({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onEdit,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark ? AppColors.textOnDark : AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Modifier',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          // Rows
          ...rows,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Row widget
// ─────────────────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool isDark;
  final String? prefix;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    final displayValue = hasValue ? '${prefix ?? ''}$value' : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: hasValue
                ? Text(
                    displayValue!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? AppColors.textOnDark : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.right,
                  )
                : Text(
                    '—',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isDark ? AppColors.grey500 : AppColors.grey400,
                    ),
                    textAlign: TextAlign.right,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Field config for edit sheet
// ─────────────────────────────────────────────────────────────────────────────
class _FieldConfig {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;

  const _FieldConfig({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic edit bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _EditSheet extends StatelessWidget {
  final bool isDark;
  final String title;
  final List<_FieldConfig> fields;
  final VoidCallback onSave;
  final Widget? extraContent;

  const _EditSheet({
    required this.isDark,
    required this.title,
    required this.fields,
    required this.onSave,
    this.extraContent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.grey600 : AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 20),
            ...fields.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildField(f, isDark),
                )),
            if (extraContent != null) extraContent!,
            const SizedBox(height: 20),
            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Enregistrer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(_FieldConfig f, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          f.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textOnDarkSecondary
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: f.controller,
          keyboardType: f.keyboardType,
          readOnly: f.readOnly,
          onTap: f.onTap,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: isDark
                ? AppColors.backgroundDark.withOpacity(0.5)
                : AppColors.backgroundLight,
            suffixIcon: f.readOnly && f.onTap != null
                ? const Icon(Icons.calendar_today_rounded,
                    color: AppColors.primary, size: 20)
                : null,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: Document
// ─────────────────────────────────────────────────────────────────────────────
class _DocumentTab extends StatefulWidget {
  final bool isDark;
  const _DocumentTab({required this.isDark});

  @override
  State<_DocumentTab> createState() => _DocumentTabState();
}

class _DocumentTabState extends State<_DocumentTab> {
  String? _frontImagePath;
  String? _backImagePath;
  bool _analysisRunning = false;
  bool _analysisComplete = false;

  bool get _isDark => widget.isDark;

  // Expiry status: 'expired' | 'expiring' | 'valid'
  String _expiryStatus(String? date) {
    if (date == null || date.isEmpty) return 'valid';
    // Simple year extraction
    final yearMatch = RegExp(r'\d{4}').allMatches(date);
    if (yearMatch.isEmpty) return 'valid';
    final year = int.tryParse(yearMatch.last.group(0)!) ?? 9999;
    if (year < 2026) return 'expired';
    if (year == 2026) return 'expiring';
    return 'valid';
  }

  // Get image path: local if just picked, otherwise MinIO URL from user
  String? _getFrontImagePath(UserModel? user) {
    return _frontImagePath ?? user?.idFrontImage;
  }

  String? _getBackImagePath(UserModel? user) {
    return _backImagePath ?? user?.idBackImage;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = AppController.to.user.value;
      if (user == null) {
        return const Center(
          child: Text('Chargement des informations utilisateur...'),
        );
      }

      final expiryStatus = _expiryStatus(user.idExpiryDate?.toString());

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Section 1 - Nationalité
            _DocSectionCard(
              isDark: _isDark,
              icon: Icons.public_rounded,
              iconColor: AppColors.success,
              title: 'Nationalité',
              onEdit: () => _showNationalitySheet(context, user),
              rows: [
                _InfoRow(
                    label: 'Pays de nationalité',
                    value: user.nationality,
                    isDark: _isDark),
              ],
            ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 16),

            // Section 2 - Type de pièce
            _DocSectionCard(
              isDark: _isDark,
              icon: Icons.badge_rounded,
              iconColor: AppColors.info,
              title: "Type de pièce",
              onEdit: () => _showDocTypeSheet(context, user),
              rows: [
                _InfoRow(
                    label: "Pays d'émission",
                    value: user.idCountry,
                    isDark: _isDark),
                _InfoRow(
                    label: 'Type de document',
                    value: user.idType,
                    isDark: _isDark),
              ],
              extraContent: user.idType != null && user.idType!.isNotEmpty
                  ? _buildDocTypeChips(user.idType!, _isDark)
                  : null,
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 16),

            // Section 3 - Numéro de pièce
            _DocSectionCard(
              isDark: _isDark,
              icon: Icons.numbers_rounded,
              iconColor: AppColors.warning,
              title: 'Numéro de pièce',
              onEdit: () => _showDocNumberSheet(context, user),
              rows: [
                _InfoRow(
                    label: 'Numéro de la pièce',
                    value: user.idNumber,
                    isDark: _isDark),
                _InfoRow(
                    label: 'Date de délivrance',
                    value: user.idIssueDate,
                    isDark: _isDark),
              ],
              expiryRow: _ExpiryRow(
                isDark: _isDark,
                value: user.idExpiryDate?.toString(),
                status: expiryStatus,
              ),
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 16),

            // Section 4 - Photos de la pièce
            _buildPhotoSection()
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.05, end: 0),

            const SizedBox(height: 32),
          ],
        ),
      );
    });
  }

  Widget _buildDocTypeChips(String currentType, bool isDark) {
    const types = ['CNI', 'Passeport', 'Permis', 'Titre de séjour'];
    // map full type to short label
    String shortLabel(String t) {
      if (t.contains('Identité') || t.contains('CNI')) return 'CNI';
      if (t.contains('Passeport')) return 'Passeport';
      if (t.contains('Permis')) return 'Permis';
      if (t.contains('Titre')) return 'Titre de séjour';
      return t;
    }

    final currentShort = shortLabel(currentType);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: types.map((t) {
          final selected = currentShort == t;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.info.withOpacity(0.12)
                  : (isDark
                      ? AppColors.backgroundDark.withOpacity(0.5)
                      : AppColors.backgroundLight),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppColors.info
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
            ),
            child: Text(
              t,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppColors.info
                    : (isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPhotoSection() {
    final user = AppController.to.user.value;
    return Container(
      decoration: BoxDecoration(
        color: _isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.15 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Photos de la pièce d'identité",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _isDark
                          ? AppColors.textOnDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: _isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Photo cards row
                Row(
                  children: [
                    Expanded(
                      child: _DocumentPhotoCard(
                        isDark: _isDark,
                        label: 'Recto',
                        imagePath: _getFrontImagePath(user),
                        onTap: () => _showImageSourceSheet(isFront: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DocumentPhotoCard(
                        isDark: _isDark,
                        label: 'Verso',
                        imagePath: _getBackImagePath(user),
                        onTap: () => _showImageSourceSheet(isFront: false),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Analyze button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: _getFrontImagePath(user) != null &&
                          _getBackImagePath(user) != null
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _runAnalysis,
                            icon: const Icon(Icons.search_rounded,
                                color: Colors.white, size: 20),
                            label: const Text(
                              "Analyser l'authenticité",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.search_rounded, size: 20),
                          label: const Text(
                            "Analyser l'authenticité",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isDark
                                ? AppColors.borderDark
                                : AppColors.grey200,
                            foregroundColor:
                                _isDark ? AppColors.grey500 : AppColors.grey400,
                            disabledBackgroundColor: _isDark
                                ? AppColors.borderDark
                                : AppColors.grey200,
                            disabledForegroundColor:
                                _isDark ? AppColors.grey500 : AppColors.grey400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                ),

                // Analysis result card
                if (_analysisComplete) ...[
                  const SizedBox(height: 16),
                  _AnalysisResultCard(isDark: _isDark),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceSheet({required bool isFront}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: _isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _isDark ? AppColors.grey600 : AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              isFront ? 'Photo du recto' : 'Photo du verso',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _SourceOption(
              isDark: _isDark,
              icon: Icons.camera_alt_rounded,
              label: 'Prendre une photo',
              color: AppColors.info,
              onTap: () async {
                Get.back();
                await _pickAndUploadImage(
                  source: ImageSource.camera,
                  isFront: isFront,
                );
              },
            ),
            const SizedBox(height: 10),
            _SourceOption(
              isDark: _isDark,
              icon: Icons.photo_library_rounded,
              label: 'Choisir depuis la galerie',
              color: AppColors.primary,
              onTap: () async {
                Get.back();
                await _pickAndUploadImage(
                  source: ImageSource.gallery,
                  isFront: isFront,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage({
    required ImageSource source,
    required bool isFront,
  }) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Vérifier la taille avant upload (max 10MB pour le serveur)
      final bytes = await pickedFile.readAsBytes();
      if (bytes.length > 10 * 1024 * 1024) {
        Get.back();
        Get.snackbar(
          'Erreur',
          'L\'image est trop volumineuse. Veuillez choisir une image plus petite.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.9),
          colorText: Colors.white,
        );
        return;
      }

      // Update local state first
      setState(() {
        if (isFront) {
          _frontImagePath = pickedFile.path;
        } else {
          _backImagePath = pickedFile.path;
        }
        _analysisComplete = false;
      });

      // Get current user
      final currentUser = AppController.to.user.value;
      if (currentUser == null) {
        Get.back(); // Close loading
        return;
      }

      // Upload to server using file upload
      final result = await ApiService.uploadUserDocumentFile(
        currentUser.id,
        isFront ? 'id_front' : 'id_back',
        pickedFile.path,
        pickedFile.name,
      );

      Get.back(); // Close loading

      if (result['success'] == true) {
        // Update user with new document URL
        final imageUrl = result['data']['imageUrl'];
        final updatedUser = currentUser.copyWith(
          idFrontImage: isFront ? imageUrl : currentUser.idFrontImage,
          idBackImage: !isFront ? imageUrl : currentUser.idBackImage,
        );
        AppController.to.updateUser(updatedUser);

        Get.snackbar(
          'Succès',
          'Document téléchargé avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Erreur',
          'Échec du téléchargement: ${result['error']}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.9),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error picking/uploading image: $e');
      Get.back(); // Close loading if open
      Get.snackbar(
        'Erreur',
        'Erreur lors du traitement de l\'image',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
  }

  void _runAnalysis() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _FraudAnalysisSheet(
        isDark: _isDark,
        onComplete: () {
          setState(() {
            _analysisComplete = true;
          });
        },
      ),
    );
  }

  void _showNationalitySheet(BuildContext context, UserModel user) {
    final natCtrl = TextEditingController(text: user.nationality ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSheet(
        isDark: _isDark,
        title: 'Modifier la nationalité',
        onSave: () async {
          final currentUser = AppController.to.user.value;
          if (currentUser != null) {
            // Save to database via API
            final result = await context
                .findAncestorStateOfType<_PersonalInfoScreenState>()
                ?.saveUserProfileToDatabase(currentUser.id, {
              'nationality': natCtrl.text.trim(),
            });

            if (result?['success'] == true) {
              // Mettre à jour le state local après succès
              final updatedUser = currentUser.copyWith(
                nationality: natCtrl.text.trim(),
              );
              AppController.to.updateUser(updatedUser);

              // Rafraîchir depuis le serveur
              await DatabaseService.to.refreshUserData();

              Get.back();
            }
          }
        },
        fields: [
          _FieldConfig(label: 'Pays de nationalité', controller: natCtrl),
        ],
      ),
    );
  }

  // ── Sélection du type de document ────────────────────────────────────────
  void _showDocTypeSheet(BuildContext context, UserModel user) {
    final countryCtrl = TextEditingController(text: user.idCountry ?? '');

    // Définition des types avec icône + couleur
    const docTypes = [
      {
        'key': "Carte Nationale d'Identité",
        'label': 'CNI',
        'sub': "Carte Nationale d'Identité",
        'icon': Icons.credit_card_rounded,
        'color': AppColors.info,
      },
      {
        'key': 'Passeport',
        'label': 'Passeport',
        'sub': 'Passeport biométrique',
        'icon': Icons.menu_book_rounded,
        'color': AppColors.success,
      },
      {
        'key': 'Permis de conduire',
        'label': 'Permis',
        'sub': 'Permis de conduire',
        'icon': Icons.directions_car_rounded,
        'color': AppColors.warning,
      },
      {
        'key': 'Titre de séjour',
        'label': 'Titre de séjour',
        'sub': 'Titre de séjour',
        'icon': Icons.home_rounded,
        'color': AppColors.rechargeColor,
      },
    ];

    String selectedType = user.idType ?? docTypes[0]['key'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            decoration: BoxDecoration(
              color: _isDark ? AppColors.cardDark : AppColors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _isDark ? AppColors.grey600 : AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Type de pièce',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color:
                        _isDark ? AppColors.textOnDark : AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 20),

                // Pays d'émission
                Text(
                  "Pays d'émission",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: countryCtrl,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        _isDark ? AppColors.textOnDark : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                    filled: true,
                    fillColor: _isDark
                        ? AppColors.backgroundDark.withOpacity(0.5)
                        : AppColors.backgroundLight,
                  ),
                ),
                const SizedBox(height: 20),

                // Type — grille 2×2
                Text(
                  'Type de document',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.6,
                  children: docTypes.map((t) {
                    final key = t['key'] as String;
                    final label = t['label'] as String;
                    final sub = t['sub'] as String;
                    final icon = t['icon'] as IconData;
                    final color = t['color'] as Color;
                    final selected = selectedType == key;

                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedType = key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withOpacity(0.1)
                              : (_isDark
                                  ? AppColors.backgroundDark.withOpacity(0.5)
                                  : AppColors.backgroundLight),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? color
                                : (_isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color:
                                    color.withOpacity(selected ? 0.18 : 0.08),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(icon, color: color, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? color
                                          : (_isDark
                                              ? AppColors.textOnDark
                                              : AppColors.textPrimary),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (selected)
                                    Icon(Icons.check_circle_rounded,
                                        size: 11, color: color),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Bouton Enregistrer
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        final currentUser = AppController.to.user.value;
                        if (currentUser != null) {
                          final updatedUser = currentUser.copyWith(
                            idCountry: countryCtrl.text.trim(),
                            idType: selectedType,
                          );

                          // Update local state
                          AppController.to.updateUser(updatedUser);

                          // Save to database via API
                          await context
                              .findAncestorStateOfType<
                                  _PersonalInfoScreenState>()
                              ?.saveUserProfileToDatabase(currentUser.id, {
                            'idCountry': countryCtrl.text.trim(),
                            'idType': selectedType,
                          });
                        }
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Enregistrer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _shortDocType(String t) {
    if (t.contains('Identité')) return 'CNI';
    if (t.contains('Passeport')) return 'Passeport';
    if (t.contains('Permis')) return 'Permis';
    if (t.contains('Titre')) return 'Titre de séjour';
    return t;
  }

  // ── Numéro + dates avec date picker ──────────────────────────────────────
  void _showDocNumberSheet(BuildContext context, UserModel user) {
    final parentState =
        context.findAncestorStateOfType<_PersonalInfoScreenState>();
    final numCtrl = TextEditingController(text: user.idNumber ?? '');
    DateTime? issueDate = parentState?.parseDate(user.idIssueDate);
    DateTime? expiryDate = parentState?.parseDate(user.idExpiryDate.toString());
    final now = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            decoration: BoxDecoration(
              color: _isDark ? AppColors.cardDark : AppColors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _isDark ? AppColors.grey600 : AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Numéro de pièce',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color:
                        _isDark ? AppColors.textOnDark : AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Numéro de la pièce ──────────────────────────────────
                Text(
                  'Numéro de la pièce',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: numCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        _isDark ? AppColors.textOnDark : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.tag_rounded,
                        color: AppColors.grey400, size: 18),
                    hintText: 'ex: GN202456789012',
                    hintStyle:
                        const TextStyle(color: AppColors.grey400, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                    filled: true,
                    fillColor: _isDark
                        ? AppColors.backgroundDark.withOpacity(0.5)
                        : AppColors.backgroundLight,
                  ),
                ),
                const SizedBox(height: 18),

                // ── Date de délivrance ──────────────────────────────────
                _DatePickerRow(
                  isDark: _isDark,
                  label: 'Date de délivrance',
                  icon: Icons.calendar_today_rounded,
                  accentColor: AppColors.info,
                  value: issueDate,
                  firstDate: DateTime(1900),
                  lastDate: now,
                  placeholder: 'Sélectionner la date de délivrance',
                  onPick: (d) => setSheetState(() => issueDate = d),
                ),
                const SizedBox(height: 14),

                // ── Date d'expiration ───────────────────────────────────
                _DatePickerRow(
                  isDark: _isDark,
                  label: "Date d'expiration",
                  icon: Icons.event_rounded,
                  accentColor: AppColors.warning,
                  value: expiryDate,
                  firstDate: DateTime(now.year - 1, now.month, now.day),
                  lastDate: DateTime(2060),
                  placeholder: "Sélectionner la date d'expiration",
                  onPick: (d) => setSheetState(() => expiryDate = d),
                  isExpiry: true,
                ),
                const SizedBox(height: 24),

                // ── Bouton Enregistrer ──────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        final currentUser = AppController.to.user.value;
                        if (currentUser != null) {
                          final updatedUser = currentUser.copyWith(
                            idNumber: numCtrl.text.trim(),
                            idIssueDate: issueDate != null
                                ? parentState?.formatDate(issueDate!)
                                : null,
                          );

                          // Update local state
                          AppController.to.updateUser(updatedUser);

                          // Save to database via API
                          await context
                              .findAncestorStateOfType<
                                  _PersonalInfoScreenState>()
                              ?.saveUserProfileToDatabase(currentUser.id, {
                            'idNumber': numCtrl.text.trim(),
                            'idIssueDate': issueDate != null
                                ? parentState?.formatDate(issueDate!)
                                : null,
                          });
                        }
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Enregistrer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date Picker Row — champ de sélection de date avec icône et format FR
// ─────────────────────────────────────────────────────────────────────────────
class _DatePickerRow extends StatelessWidget {
  final bool isDark;
  final String label;
  final IconData icon;
  final Color accentColor;
  final DateTime? value;
  final DateTime firstDate;
  final DateTime lastDate;
  final String placeholder;
  final ValueChanged<DateTime> onPick;
  final bool isExpiry;

  const _DatePickerRow({
    required this.isDark,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.value,
    required this.firstDate,
    required this.lastDate,
    required this.placeholder,
    required this.onPick,
    this.isExpiry = false,
  });

  static const _frMonths = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  String get _formatted => value != null
      ? '${value!.day} ${_frMonths[value!.month - 1]} ${value!.year}'
      : placeholder;

  bool get _hasValue => value != null;

  // Couleur du badge expiry selon la date
  Color _expiryBadgeColor() {
    if (value == null) return Colors.transparent;
    final now = DateTime.now();
    final diff = value!.difference(now).inDays;
    if (diff < 0) return AppColors.error;
    if (diff < 180) return AppColors.warning;
    return AppColors.success;
  }

  String _expiryBadgeLabel() {
    if (value == null) return '';
    final now = DateTime.now();
    final diff = value!.difference(now).inDays;
    if (diff < 0) return 'Expirée';
    if (diff < 180) return 'Bientôt';
    return 'Valide';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textOnDarkSecondary
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ??
                  (isExpiry
                      ? DateTime.now().add(const Duration(days: 365))
                      : DateTime.now()),
              firstDate: firstDate,
              lastDate: lastDate,
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: AppColors.primary,
                    primary: AppColors.primary,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) onPick(picked);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: _hasValue
                  ? accentColor.withOpacity(0.06)
                  : (isDark
                      ? AppColors.backgroundDark.withOpacity(0.5)
                      : AppColors.backgroundLight),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasValue
                    ? accentColor.withOpacity(0.5)
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                width: _hasValue ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(_hasValue ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: accentColor, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatted,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _hasValue ? FontWeight.w600 : FontWeight.w400,
                      color: _hasValue
                          ? (isDark
                              ? AppColors.textOnDark
                              : AppColors.textPrimary)
                          : AppColors.grey400,
                    ),
                  ),
                ),
                // Badge expiry status (uniquement si isExpiry et date sélectionnée)
                if (isExpiry && _hasValue) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _expiryBadgeColor().withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _expiryBadgeColor().withOpacity(0.4)),
                    ),
                    child: Text(
                      _expiryBadgeLabel(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _expiryBadgeColor(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: AppColors.grey400),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Document Section Card (slightly different from profile section)
// ─────────────────────────────────────────────────────────────────────────────
class _DocSectionCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onEdit;
  final List<_InfoRow> rows;
  final Widget? extraContent;
  final Widget? expiryRow;

  const _DocSectionCard({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onEdit,
    required this.rows,
    this.extraContent,
    this.expiryRow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark ? AppColors.textOnDark : AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Modifier',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          ...rows,
          if (expiryRow != null) expiryRow!,
          if (extraContent != null) extraContent!,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expiry Row with status badge
// ─────────────────────────────────────────────────────────────────────────────
class _ExpiryRow extends StatelessWidget {
  final bool isDark;
  final String? value;
  final String status; // 'expired' | 'expiring' | 'valid'

  const _ExpiryRow({
    required this.isDark,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (status) {
      case 'expired':
        badgeColor = AppColors.error;
        badgeText = 'Expirée';
        badgeIcon = Icons.error_rounded;
        break;
      case 'expiring':
        badgeColor = AppColors.warning;
        badgeText = 'Bientôt expirée';
        badgeIcon = Icons.warning_rounded;
        break;
      default:
        badgeColor = AppColors.success;
        badgeText = 'Valide';
        badgeIcon = Icons.check_circle_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "Date d'expiration",
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasValue)
                  Text(
                    value!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? AppColors.textOnDark : AppColors.textPrimary,
                    ),
                  )
                else
                  Text(
                    '—',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isDark ? AppColors.grey500 : AppColors.grey400,
                    ),
                  ),
                if (hasValue) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, color: badgeColor, size: 11),
                        const SizedBox(width: 3),
                        Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Document Photo Card
// ─────────────────────────────────────────────────────────────────────────────
class _DocumentPhotoCard extends StatelessWidget {
  final bool isDark;
  final String label;
  final String? imagePath;
  final VoidCallback onTap;

  const _DocumentPhotoCard({
    required this.isDark,
    required this.label,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: hasImage
              ? null
              : Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.grey300,
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
          color: hasImage
              ? null
              : (isDark
                  ? AppColors.backgroundDark.withOpacity(0.5)
                  : AppColors.backgroundLight),
          gradient: hasImage
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A1A2E),
                    Color(0xFF2D3A5C),
                    Color(0xFF1A3A5C)
                  ],
                )
              : null,
          boxShadow: hasImage
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: hasImage
            ? _buildImageWidget(imagePath!, label)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_rounded,
                    size: 28,
                    color: isDark ? AppColors.grey500 : AppColors.grey400,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.grey500 : AppColors.grey400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Appuyer pour ajouter',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.grey600 : AppColors.grey400,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image Widget - Display real images from MinIO or local
// ─────────────────────────────────────────────────────────────────────────────
Widget _buildImageWidget(String imagePath, String label) {
  // Check if it's a network URL (MinIO)
  final isNetworkUrl =
      imagePath.startsWith('http://') || imagePath.startsWith('https://');

  if (isNetworkUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imagePath,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[800],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[800],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image,
                        color: Colors.white.withOpacity(0.5), size: 24),
                    const SizedBox(height: 4),
                    Text(
                      'Erreur chargement',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Label overlay
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Local file path - display actual image
  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[800],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image,
                      color: Colors.white.withOpacity(0.5), size: 24),
                  const SizedBox(height: 4),
                  Text(
                    'Erreur chargement',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        // Label overlay
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Mock Document Card visual
// ─────────────────────────────────────────────────────────────────────────────
class _MockDocumentCard extends StatelessWidget {
  final String label;
  const _MockDocumentCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(painter: _DocPatternPainter()),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ID CARD',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Photo placeholder
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 0.5),
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Colors.white54, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2),
                              )),
                          const SizedBox(height: 4),
                          Container(
                              height: 5,
                              width: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(2),
                              )),
                          const SizedBox(height: 4),
                          Container(
                              height: 4,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(2),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // MRZ lines
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  height: 3,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
          // Check overlay
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 10; i++) {
      canvas.drawLine(
        Offset(i * 20.0, 0),
        Offset(0, i * 20.0),
        paint,
      );
    }
    // Hologram circle
    final holoPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(size.width * 0.75, size.height * 0.4), 18, holoPaint);
  }

  @override
  bool shouldRepaint(_DocPatternPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Analysis result card
// ─────────────────────────────────────────────────────────────────────────────
class _AnalysisResultCard extends StatelessWidget {
  final bool isDark;
  const _AnalysisResultCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'AUTHENTIQUE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                '94/100',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.94,
              minHeight: 6,
              backgroundColor: AppColors.success.withOpacity(0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
          const SizedBox(height: 12),
          ..._buildChecks(isDark),
        ],
      ),
    ).animate().scale(curve: Curves.elasticOut, duration: 600.ms);
  }

  List<Widget> _buildChecks(bool isDark) {
    const checks = [
      "Résolution d'image",
      'Dimensions du document',
      'Code MRZ',
      'Éléments de sécurité',
      'Intégrité numérique',
      'Microimpression',
      'Photo biométrique',
    ];
    return checks
        .map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    c,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDark ? AppColors.textOnDark : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image source option tile
// ─────────────────────────────────────────────────────────────────────────────
class _SourceOption extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceOption({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: isDark ? AppColors.grey500 : AppColors.grey400,
                size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fraud Analysis Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _FraudAnalysisSheet extends StatefulWidget {
  final bool isDark;
  final VoidCallback onComplete;

  const _FraudAnalysisSheet({
    required this.isDark,
    required this.onComplete,
  });

  @override
  State<_FraudAnalysisSheet> createState() => _FraudAnalysisSheetState();
}

class _FraudAnalysisSheetState extends State<_FraudAnalysisSheet>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  bool _scanComplete = false;
  int _currentCheck = -1;
  bool _showVerdict = false;
  final List<bool> _checksDone = List.filled(7, false);

  static const _checks = [
    (
      Icons.image_search_rounded,
      "Résolution d'image",
      '96 DPI · Netteté excellente'
    ),
    (
      Icons.crop_rounded,
      'Dimensions du document',
      'Conformes aux normes ISO 7810'
    ),
    (Icons.qr_code_rounded, 'Code MRZ', 'Parsé avec succès · Checksum valide'),
    (
      Icons.security_rounded,
      'Éléments de sécurité',
      'Hologramme · Filigrane · UV détectés'
    ),
    (
      Icons.gpp_good_rounded,
      'Intégrité numérique',
      'Aucune altération détectée'
    ),
    (
      Icons.text_fields_rounded,
      'Microimpression',
      'Conforme au format guinéen'
    ),
    (Icons.face_rounded, 'Photo biométrique', 'Visage détecté · Normes ICAO'),
  ];

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(_scanController);

    _scanController.forward().then((_) {
      if (!mounted) return;
      setState(() => _scanComplete = true);
      _runChecks();
    });
  }

  Future<void> _runChecks() async {
    for (var i = 0; i < _checks.length; i++) {
      if (!mounted) return;
      setState(() => _currentCheck = i);
      await Future.delayed(const Duration(milliseconds: 380));
      if (!mounted) return;
      setState(() => _checksDone[i] = true);
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _showVerdict = true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.grey600 : AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            "Analyse d'authenticité",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color:
                  widget.isDark ? AppColors.textOnDark : AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),

          // Scan progress or checks
          if (!_scanComplete) ...[
            _buildScanPhase(),
          ] else ...[
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    ..._buildCheckItems(),
                    if (_showVerdict) ...[
                      const SizedBox(height: 20),
                      _buildVerdict(),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back();
                            widget.onComplete();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Fermer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanPhase() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Initialisation du scanner...',
                style: TextStyle(
                  fontSize: 13,
                  color: widget.isDark
                      ? AppColors.textOnDark
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _scanAnimation,
          builder: (_, __) => Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _scanAnimation.value,
                  minHeight: 6,
                  backgroundColor: widget.isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${(_scanAnimation.value * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  List<Widget> _buildCheckItems() {
    return List.generate(_checks.length, (i) {
      final check = _checks[i];
      final isVisible = i <= _currentCheck;
      final isDone = _checksDone[i];
      final isRunning = i == _currentCheck && !isDone;

      if (!isVisible) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: isRunning
                  ? const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    )
                  : isDone
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 22)
                      : const SizedBox.shrink(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    check.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.isDark
                          ? AppColors.textOnDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (isDone)
                    Text(
                      check.$3,
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (isDone)
              Icon(check.$1,
                  color: AppColors.success.withOpacity(0.7), size: 18),
          ],
        ),
      ).animate().fadeIn(duration: 250.ms).slideX(begin: -0.05, end: 0);
    });
  }

  Widget _buildVerdict() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '✅ DOCUMENT AUTHENTIQUE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ).animate().scale(curve: Curves.elasticOut, duration: 600.ms),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Score: ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const Text(
                '94',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                '/100',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.94,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  'Émis par: République de Guinée · Ministère de l\'Intérieur',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Vérifié le 08 jan. 2024 · Expire le 11 juin 2027',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}
