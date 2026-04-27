import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'app_controller.dart';

/// Contact model for transfer recipients
class ContactModel {
  final String id;
  final String phone;
  final String name;
  final String? contactUserId;
  final bool hasAccount;
  final String? photoUrl;
  final DateTime? createdAt;

  ContactModel({
    required this.id,
    required this.phone,
    required this.name,
    this.contactUserId,
    this.hasAccount = false,
    this.photoUrl,
    this.createdAt,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] ?? '',
      phone: json['phone'] ?? '',
      name: json['name'] ?? json['phone'] ?? '',
      contactUserId: json['contactUserId'],
      hasAccount: json['hasAccount'] ?? false,
      photoUrl: json['photoUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'name': name,
        'contactUserId': contactUserId,
        'hasAccount': hasAccount,
        'photoUrl': photoUrl,
        'createdAt': createdAt?.toIso8601String(),
      };
}

/// Contact Service for managing transfer contacts
class ContactService extends GetxService {
  static ContactService get to => Get.find();

  // Observable contacts list
  final RxList<ContactModel> contacts = <ContactModel>[].obs;
  final RxBool isLoading = false.obs;

  // API base URL
  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    // iOS simulator and macOS
    return 'http://localhost:3000';
  }

  @override
  void onInit() {
    super.onInit();
    // Load contacts when user logs in
    ever(AppController.to.user, (user) {
      if (user != null) {
        loadContacts();
      } else {
        contacts.clear();
      }
    });
  }

  /// Load contacts from backend
  Future<void> loadContacts() async {
    final user = AppController.to.user.value;
    if (user == null) return;

    try {
      isLoading.value = true;

      final response = await http.get(
        Uri.parse('$baseUrl/api/contacts/${user.id}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> contactsData = data['data']['contacts'] ?? [];
          contacts.value =
              contactsData.map((c) => ContactModel.fromJson(c)).toList();
          debugPrint('[ContactService] Loaded ${contacts.length} contacts');
        }
      } else {
        debugPrint(
            '[ContactService] Failed to load contacts: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ContactService] Error loading contacts: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Get contacts that have an account on the platform
  List<ContactModel> get platformContacts {
    return contacts.where((c) => c.hasAccount).toList();
  }

  /// Get recent contacts for transfer screen
  List<ContactModel> get recentContacts {
    return contacts.take(10).toList();
  }

  /// Search contacts by name or phone
  List<ContactModel> searchContacts(String query) {
    if (query.isEmpty) return contacts;
    final lowerQuery = query.toLowerCase();
    return contacts.where((c) {
      return c.name.toLowerCase().contains(lowerQuery) ||
          c.phone.contains(lowerQuery);
    }).toList();
  }

  /// Add a contact manually (if needed)
  Future<bool> addContact(String phone, String name) async {
    // Contacts are automatically added during transfers
    // This method is for manual addition if needed
    await loadContacts();
    return true;
  }

  /// Refresh contacts
  Future<void> refresh() async {
    await loadContacts();
  }
}
