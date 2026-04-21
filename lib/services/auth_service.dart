import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_model.dart';
import 'database_service.dart';
import 'api_service.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();
  final DatabaseService _db = DatabaseService.to;

  // Observable state
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoggedIn = false.obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString token = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _checkAuthStatus();
  }

  // ========================================
  // AUTHENTICATION METHODS
  // ========================================

  // Login with phone and password
  Future<bool> login(String phone, String password) async {
    return await signIn(phone, password);
  }

  // SignIn method for compatibility with LoginScreen
  Future<bool> signIn(String phone, String password) async {
    try {
      isLoading.value = true;
      error.value = '';

      print('DEBUG: Tentative de connexion avec phone: $phone');

      // Call API for authentication
      final result = await ApiService.login(phone, password);

      // print('DEBUG: Résultat de l\'API: $result');

      if (result['success'] == true) {
        final userData = result['data']['user'];
        final authToken = result['data']['token'];

        print('DEBUG: Utilisateur reçu: $userData');
        print('DEBUG: Token reçu: $authToken');

        // Convert API response to UserModel
        currentUser.value = UserModel.fromJson(userData);
        token.value = authToken;
        isLoggedIn.value = true;

        // Save token to SharedPreferences for persistence
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', authToken);
        await prefs.setBool('is_logged_in', true);

        // Sauvegarder les données utilisateur en JSON (méthode alternative)
        print("DEBUG: Sauvegarde des données utilisateur...");
        final user = currentUser.value!;

        // Créer manuellement le JSON pour éviter les problèmes de sérialisation
        final userMap = {
          'id': user.id,
          'first_name': user.firstName,
          'last_name': user.lastName,
          'email': user.email,
          'phone': user.phone,
          'avatar_url': user.avatarUrl,
          'balance': user.balance,
          'savings_balance': user.savingsBalance,
          'account_number': user.accountNumber,
          'is_verified': user.isVerified,
          'kyc_level': user.kycLevel,
          'created_at': user.createdAt.toIso8601String(),
          'birth_date': user.birthDate,
          'birth_place': user.birthPlace,
          'gender': user.gender,
          'profession': user.profession,
          'employer': user.employer,
          'city': user.city,
          'commune': user.commune,
          'neighborhood': user.neighborhood,
          'nationality': user.nationality,
          'id_country': user.idCountry,
          'id_type': user.idType,
          'id_number': user.idNumber,
          'id_issue_date': user.idIssueDate,
          'id_expiry_date': user.idExpiryDate?.toIso8601String(),
          'id_verified_at': user.idVerifiedAt?.toIso8601String(),
        };

        final jsonString = jsonEncode(userMap);
        print("DEBUG: JSON string: $jsonString");

        await prefs.setString('user', jsonString);

        print("Information caching");
        print(await prefs.getString('user'));

        // Update DatabaseService user
        _db.currentUser.value = currentUser.value;

        print('DEBUG: Connexion réussie');
        return true;
      } else {
        print('DEBUG: Échec de connexion: ${result['error']}');
        error.value =
            result['error'] ?? 'Numéro de téléphone ou mot de passe incorrect';
        return false;
      }
    } catch (e) {
      print('DEBUG: Exception lors de la connexion: $e');
      error.value = 'Erreur de connexion: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      print(
          'DEBUG: Tentative d\'inscription avec email: $email, phone: $phone');

      // Call API for registration
      final result = await ApiService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );

      print('DEBUG: Résultat de l\'API register: $result');

      if (result['success'] == true) {
        final userData = result['data']['user'];
        final authToken = result['data']['token'];

        print('DEBUG: Utilisateur créé: $userData');
        print('DEBUG: Token reçu: $authToken');

        // Convert API response to UserModel
        currentUser.value = UserModel.fromJson(userData);
        token.value = authToken;
        isLoggedIn.value = true;

        // Save token to SharedPreferences for persistence
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', authToken);
        await prefs.setBool('is_logged_in', true);

        // Update DatabaseService user
        _db.currentUser.value = currentUser.value;

        print('DEBUG: Inscription réussie');
        return true;
      } else {
        print('DEBUG: Échec d\'inscription: ${result['error']}');
        error.value = result['error'] ?? 'Erreur lors de l\'inscription';
        return false;
      }
    } catch (e) {
      print('DEBUG: Exception lors de l\'inscription: $e');
      error.value = 'Erreur d\'inscription: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      // Clear current user
      currentUser.value = null;
      token.value = '';
      isLoggedIn.value = false;

      // Clear stored auth data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('is_logged_in');

      // Clear DatabaseService user
      _db.currentUser.value = null;

      print('DEBUG: Déconnexion réussie, token effacé');
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  Future<bool> resetPassword(String phone) async {
    try {
      isLoading.value = true;
      error.value = '';

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 1000));

      // For demo, accept any phone number
      return true;
    } catch (e) {
      error.value = 'Erreur de réinitialisation: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      error.value = '';

      if (currentUser.value != null) {
        final updatedUser = currentUser.value!.copyWith(
          firstName: data['firstName'],
          lastName: data['lastName'],
          email: data['email'],
          phone: data['phone'],
          birthDate: data['birthDate'],
          birthPlace: data['birthPlace'],
          gender: data['gender'],
          profession: data['profession'],
          employer: data['employer'],
          city: data['city'],
          commune: data['commune'],
          neighborhood: data['neighborhood'],
          nationality: data['nationality'],
          idCountry: data['idCountry'],
          idType: data['idType'],
          idNumber: data['idNumber'],
          idIssueDate: data['idIssueDate'],
          idExpiryDate: data['idExpiryDate'],
        );

        currentUser.value = updatedUser;
        _db.currentUser.value = updatedUser;
        return true;
      }
      return false;
    } catch (e) {
      error.value = 'Erreur de mise à jour: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> refreshUserData() async {
    try {
      isLoading.value = true;
      error.value = '';

      if (token.value.isEmpty) {
        error.value = 'Aucun token d\'authentification';
        return false;
      }

      // Call API to get fresh user data
      final result = await ApiService.getProfile(token.value);

      if (result['success'] == true) {
        final userData = result['data']['user'];

        print('DEBUG: Données utilisateur rafraîchies: $userData');

        // Convert API response to UserModel
        final freshUser = UserModel.fromJson(userData);
        currentUser.value = freshUser;
        _db.currentUser.value = freshUser;

        print('DEBUG: Cache utilisateur mis à jour avec succès');
        return true;
      } else {
        print('DEBUG: Échec du rafraîchissement: ${result['error']}');
        error.value =
            result['error'] ?? 'Erreur lors du rafraîchissement des données';
        return false;
      }
    } catch (e) {
      print('DEBUG: Exception lors du rafraîchissement: $e');
      error.value = 'Erreur de rafraîchissement: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  void _checkAuthStatus() async {
    // Check stored auth state from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('auth_token');
    final isUserLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (isUserLoggedIn && storedToken != null && storedToken.isNotEmpty) {
      token.value = storedToken;
      this.isLoggedIn.value = true;
      print('DEBUG: Token restauré depuis SharedPreferences: $storedToken');

      // Try to get user data from DatabaseService if available
      final dbUser = _db.currentUser.value;
      if (dbUser != null && dbUser.id.isNotEmpty) {
        currentUser.value = dbUser;
        print('DEBUG: Utilisateur restauré depuis DatabaseService');
      }
    } else {
      print('DEBUG: Aucun token trouvé, utilisateur non connecté');
      this.isLoggedIn.value = false;
    }
  }

  String _generateAccountNumber() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return 'GN${random.toString().substring(5)}';
  }

  void clearError() {
    error.value = '';
  }

  // ========================================
  // VALIDATION METHODS
  // ========================================

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    if (value.length < 9) {
      return 'Le numéro de téléphone doit contenir au moins 9 chiffres';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Le numéro de téléphone ne doit contenir que des chiffres';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Veuillez entrer un email valide';
    }
    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ce champ est requis';
    }
    if (value.length < 2) {
      return 'Ce champ doit contenir au moins 2 caractères';
    }
    return null;
  }
}
