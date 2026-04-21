import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/input_field.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final DatabaseService _db = DatabaseService.to;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> get _filteredContacts {
    if (_searchQuery.isEmpty) {
      return _db.contacts;
    }
    return _db.contacts.where((contact) {
      final name = contact['name'].toString().toLowerCase();
      final phone = contact['phone'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          phone.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Contacts'),
        backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showAddContactDialog,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            child: InputField(
              hint: 'Rechercher un contact...',
              controller: _searchCtrl,
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          // Contacts list
          Expanded(
            child: Obx(() {
              if (_db.contacts.isEmpty) {
                return _buildEmptyState(isDark);
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.pagePadding),
                itemCount: _filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = _filteredContacts[index];
                  return _ContactItem(
                    contact: contact,
                    onTap: () => _showContactOptions(contact),
                    onEdit: () => _showEditContactDialog(contact),
                    onDelete: () => _showDeleteContactDialog(contact),
                  ).animate().fadeIn(delay: (index * 50).ms);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.contacts_outlined,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun contact',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.grey900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez vos contacts pour des transferts rapides',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.grey400 : AppColors.grey600,
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Ajouter un contact',
            onPressed: _showAddContactDialog,
            gradient: AppColors.primaryGradient,
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog() {
    _showContactDialog(
      title: 'Ajouter un contact',
      onSave: (name, phone) async {
        final initials = _getInitials(name);
        await _db.addContact({
          'name': name,
          'phone': phone,
          'initials': initials,
          'isFavorite': false,
        });
        Get.snackbar(
          'Succès',
          'Contact ajouté avec succès',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      },
    );
  }

  void _showEditContactDialog(Map<String, dynamic> contact) {
    _showContactDialog(
      title: 'Modifier le contact',
      initialName: contact['name'],
      initialPhone: contact['phone'],
      onSave: (name, phone) async {
        // Update contact logic would go here
        // For now, we'll just show a success message
        Get.snackbar(
          'Succès',
          'Contact modifié avec succès',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      },
    );
  }

  void _showContactDialog({
    required String title,
    String? initialName,
    String? initialPhone,
    required Function(String, String) onSave,
  }) {
    final nameCtrl = TextEditingController(text: initialName ?? '');
    final phoneCtrl = TextEditingController(text: initialPhone ?? '');
    final formKey = GlobalKey<FormState>();
    final isDark = Get.isPlatformDarkMode ? true : false;

    Get.dialog(
      Dialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radius2XL),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.grey900,
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    InputField(
                      label: 'Nom',
                      hint: 'Entrez le nom',
                      controller: nameCtrl,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le nom est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InputField(
                      label: 'Téléphone',
                      hint: 'Entrez le numéro de téléphone',
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le numéro de téléphone est requis';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: 'Annuler',
                      onPressed: () => Get.back(),
                      variant: ButtonVariant.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      label: 'Enregistrer',
                      onPressed: () {
                        if (formKey.currentState?.validate() ?? false) {
                          onSave(nameCtrl.text.trim(), phoneCtrl.text.trim());
                          Get.back();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactOptions(Map<String, dynamic> contact) {
    final isDark = Get.isPlatformDarkMode ? true : false;
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.radius2XL)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      contact['name'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.white : AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      contact['phone'],
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.grey400 : AppColors.grey600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      leading: const Icon(Icons.edit, color: AppColors.primary),
                      title: const Text('Modifier'),
                      onTap: () {
                        Get.back();
                        _showEditContactDialog(contact);
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        contact['isFavorite'] ? Icons.star : Icons.star_border,
                        color: AppColors.warning,
                      ),
                      title: Text(contact['isFavorite']
                          ? 'Retirer des favoris'
                          : 'Ajouter aux favoris'),
                      onTap: () {
                        Get.back();
                        // Toggle favorite logic would go here
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete, color: AppColors.error),
                      title: const Text('Supprimer'),
                      onTap: () {
                        Get.back();
                        _showDeleteContactDialog(contact);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteContactDialog(Map<String, dynamic> contact) {
    final isDark = Get.isPlatformDarkMode ? true : false;
    Get.dialog(
      Dialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radius2XL),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete,
                  color: AppColors.error,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Supprimer le contact',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.grey900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Êtes-vous sûr de vouloir supprimer ${contact['name']} ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.grey400 : AppColors.grey600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: 'Annuler',
                      onPressed: () => Get.back(),
                      variant: ButtonVariant.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      label: 'Supprimer',
                      onPressed: () {
                        // Delete contact logic would go here
                        Get.back();
                        Get.snackbar(
                          'Succès',
                          'Contact supprimé',
                          backgroundColor: AppColors.success,
                          colorText: Colors.white,
                        );
                      },
                      gradient: LinearGradient(
                        colors: [
                          AppColors.error,
                          AppColors.error.withOpacity(0.8)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : '';
  }
}

class _ContactItem extends StatelessWidget {
  final Map<String, dynamic> contact;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContactItem({
    required this.contact,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(
          color: isDark ? AppColors.grey800 : AppColors.grey100,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              contact['initials'],
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        title: Text(
          contact['name'],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.white : AppColors.grey900,
          ),
        ),
        subtitle: Text(
          contact['phone'],
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.grey400 : AppColors.grey600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (contact['isFavorite'])
              const Icon(Icons.star, color: AppColors.warning, size: 20),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right,
                color: isDark ? AppColors.grey400 : AppColors.grey600),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
