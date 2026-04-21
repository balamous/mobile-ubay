import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_model.dart';
import '../data/models/transaction_model.dart';
import '../data/models/card_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class DatabaseService extends GetxService {
  static DatabaseService get to => Get.find();

  // ========================================
  // DYNAMIC DATA FROM SERVER API
  // ========================================

  // User data from PostgreSQL database
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  // Dynamic data from server - initially empty
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxList<CardModel> cards = <CardModel>[].obs;
  final RxBool isLoading = false.obs;

  // Cache contacts for platform users (stored locally, not on server)
  final RxList<Map<String, dynamic>> contacts = <Map<String, dynamic>>[].obs;

  // Payment methods from server
  final RxList<Map<String, dynamic>> paymentMethods =
      <Map<String, dynamic>>[].obs;

  // Services from server
  final RxList<Map<String, dynamic>> services = <Map<String, dynamic>>[].obs;

  // Operators from server
  final RxList<Map<String, dynamic>> operators = <Map<String, dynamic>>[].obs;

  // ========================================
  // INITIALIZATION
  // ========================================

  @override
  Future<void> onInit() async {
    super.onInit();
    debugPrint('DatabaseService initialized - ready to load data from server');

    // Charger les données utilisateur depuis le cache si disponible
    await loadUserFromCache();

    await loadPaymentMethods();
    await loadServices();
    await loadOperators();
  }

  // Charger les données utilisateur depuis SharedPreferences
  Future<void> loadUserFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');

      print('DEBUG: Données brutes du cache: $userString');
      print('DEBUG: Type de données: ${userString.runtimeType}');

      if (userString != null && userString.isNotEmpty) {
        // Vérifier si la chaîne commence par '{' (JSON valide)
        if (!userString.trim().startsWith('{')) {
          print('DEBUG: Les données ne commencent pas par un JSON valide');
          print('DEBUG: Premier caractère: "${userString[0]}"');
          return;
        }

        // Convertir la chaîne JSON en UserModel
        print('DEBUG: Tentative de décodage JSON...');
        final userJson = jsonDecode(userString) as Map<String, dynamic>;
        print('DEBUG: JSON décodé avec succès: ${userJson.runtimeType}');

        final userModel = UserModel.fromJson(userJson);
        print('DEBUG: UserModel créé: ${userModel.runtimeType}');

        // Affecter à la variable currentUser
        currentUser.value = userModel;

        debugPrint(
            'DEBUG: Utilisateur chargé depuis le cache: ${userModel.fullName}');
      } else {
        debugPrint('DEBUG: Aucune donnée utilisateur trouvée dans le cache');
      }
    } catch (e) {
      debugPrint(
          'Erreur lors du chargement des données utilisateur depuis le cache: $e');
      debugPrint('Type d\'erreur: ${e.runtimeType}');

      // Essayer de récupérer les données brutes pour le debug
      final prefs = await SharedPreferences.getInstance();
      final rawData = prefs.getString('user');
      debugPrint('Données brutes qui ont causé l\'erreur: "$rawData"');

      // Solution de fallback : nettoyer le cache et essayer une approche simplifiée
      print('DEBUG: Nettoyage du cache utilisateur corrompu...');
      await prefs.remove('user');

      // Créer un utilisateur par défaut si nécessaire
      print('DEBUG: Création d\'un utilisateur par défaut vide...');
      currentUser.value = null;
    }
  }

  Future<void> loadPaymentMethods() async {
    try {
      final result = await ApiService.getPaymentMethods();
      if (result['success'] == true) {
        final List<dynamic> methodsData =
            result['data']['paymentMethods'] ?? [];
        await loadPaymentMethodsFromServer(methodsData
            .map((method) => method as Map<String, dynamic>)
            .toList());
      }
    } catch (e) {
      debugPrint('Error loading payment methods: $e');
    }
  }

  Future<void> loadCards() async {
    try {
      final currentUser = AuthService.to.currentUser.value;
      if (currentUser == null) {
        debugPrint('DEBUG: No user logged in, cannot load cards');
        return;
      }

      final result = await ApiService.getUserCards(currentUser.id);
      if (result['success'] == true) {
        final List<dynamic> cardsData = result['data']['cards'] ?? [];
        cards.clear();

        for (final cardData in cardsData) {
          final card = CardModel(
            id: cardData['id'],
            cardNumber: cardData['cardNumber'],
            cardHolder: cardData['cardHolder'],
            expiryMonth: cardData['expiryMonth'],
            expiryYear: cardData['expiryYear'],
            cvv: cardData['cvv'],
            type: cardData['type'] == 'visa'
                ? CardType.visa
                : CardType.mastercard,
            status: cardData['status'] == 'active'
                ? CardStatus.active
                : cardData['status'] == 'blocked'
                    ? CardStatus.blocked
                    : CardStatus.expired,
            limit: cardData['limit'],
            spent: cardData['spent'],
            isVirtual: cardData['isVirtual'],
            gradientStart: cardData['gradientStart'],
            gradientEnd: cardData['gradientEnd'],
            isDefault: cardData['isDefault'],
          );
          cards.add(card);
        }

        debugPrint('DEBUG: Loaded ${cards.length} cards from API');
      } else {
        debugPrint('DEBUG: Failed to load cards: ${result['error']}');
      }
    } catch (e) {
      debugPrint('Error loading cards: $e');
    }
  }

  Future<void> loadServices() async {
    try {
      final result = await ApiService.getServices();
      if (result['success'] == true) {
        final List<dynamic> servicesData = result['data']['services'] ?? [];
        await loadServicesFromServer(servicesData
            .map((service) => service as Map<String, dynamic>)
            .toList());
      }
    } catch (e) {
      debugPrint('Error loading services: $e');
    }
  }

  Future<void> loadOperators() async {
    try {
      final result = await ApiService.getOperators();
      if (result['success'] == true) {
        final List<dynamic> operatorsData = result['data']['operators'] ?? [];
        await loadOperatorsFromServer(operatorsData
            .map((operator) => operator as Map<String, dynamic>)
            .toList());
      }
    } catch (e) {
      debugPrint('Error loading operators: $e');
    }
  }

  // ========================================
  // USER METHODS
  // ========================================

  Future<void> updateBalance(double amount, {bool isCredit = true}) async {
    if (currentUser.value == null) return;

    try {
      final newBalance =
          currentUser.value!.balance + (isCredit ? amount : -amount);
      currentUser.value = currentUser.value!.copyWith(balance: newBalance);
      debugPrint('Balance updated locally: $newBalance');
    } catch (e) {
      debugPrint('Error updating balance: $e');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (currentUser.value == null) return;

    try {
      debugPrint('Profile update requested: $data');
      // This will be implemented with actual API calls
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  // ========================================
  // TRANSACTION METHODS
  // ========================================

  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      transactions.insert(0, transaction);
      await updateBalance(transaction.amount, isCredit: transaction.isCredit);
      debugPrint('Transaction added: ${transaction.description}');
    } catch (e) {
      debugPrint('Error adding transaction: $e');
    }
  }

  Future<List<TransactionModel>> getTransactions({int limit = 50}) async {
    return transactions.take(limit).toList();
  }

  String generateReference(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$prefix${timestamp.toString().substring(5)}';
  }

  // ========================================
  // CARD METHODS
  // ========================================

  Future<void> addCard(CardModel card) async {
    try {
      cards.add(card);
      debugPrint('Card added: ${card.cardNumber}');
    } catch (e) {
      debugPrint('Error adding card: $e');
    }
  }

  Future<void> updateCardSpending(String cardId, double amount) async {
    try {
      final index = cards.indexWhere((card) => card.id == cardId);
      if (index != -1) {
        final card = cards[index];
        final updatedSpent = card.spent! + amount;
        final updatedCard = card.copyWith(spent: updatedSpent);
        cards[index] = updatedCard;
        debugPrint('Card spending updated: $updatedSpent');
      }
    } catch (e) {
      debugPrint('Error updating card spending: $e');
    }
  }

  // ========================================
  // DATA MANAGEMENT
  // ========================================

  Future<void> loadTransactionsFromServer(
      List<Map<String, dynamic>> serverData) async {
    try {
      transactions.clear();
      transactions.addAll(
          serverData.map((txn) => TransactionModel.fromJson(txn)).toList());
      debugPrint('Loaded ${transactions.length} transactions from server');
    } catch (e) {
      debugPrint('Error loading transactions from server: $e');
    }
  }

  Future<void> loadCardsFromServer(
      List<Map<String, dynamic>> serverData) async {
    try {
      cards.clear();
      cards.addAll(serverData.map((card) => CardModel.fromJson(card)).toList());
      debugPrint('Loaded ${cards.length} cards from server');
    } catch (e) {
      debugPrint('Error loading cards from server: $e');
    }
  }

  // ========================================
  // CONTACT CACHE METHODS
  // ========================================

  Future<void> addContact(Map<String, dynamic> contact) async {
    try {
      // Check if contact already exists
      final existingIndex =
          contacts.indexWhere((c) => c['phone'] == contact['phone']);
      if (existingIndex == -1) {
        contacts.add({
          'id': 'contact_${DateTime.now().millisecondsSinceEpoch}',
          'name': contact['name'] ?? '',
          'phone': contact['phone'] ?? '',
          'initials': _getInitials(contact['name'] ?? ''),
          'isFavorite': contact['isFavorite'] ?? false,
          'isPlatformUser': contact['isPlatformUser'] ?? false,
          'addedAt': DateTime.now().toIso8601String(),
        });
        debugPrint('Contact added to cache: ${contact['name']}');
      } else {
        debugPrint('Contact already exists: ${contact['phone']}');
      }
    } catch (e) {
      debugPrint('Error adding contact: $e');
    }
  }

  Future<void> addPlatformContact(String name, String phone) async {
    await addContact({
      'name': name,
      'phone': phone,
      'isPlatformUser': true,
    });
  }

  Future<void> removeContact(String phone) async {
    try {
      contacts.removeWhere((contact) => contact['phone'] == phone);
      debugPrint('Contact removed: $phone');
    } catch (e) {
      debugPrint('Error removing contact: $e');
    }
  }

  Future<void> toggleFavoriteContact(String phone) async {
    try {
      final index = contacts.indexWhere((c) => c['phone'] == phone);
      if (index != -1) {
        contacts[index]['isFavorite'] =
            !(contacts[index]['isFavorite'] ?? false);
        contacts.refresh();
        debugPrint('Contact favorite toggled: $phone');
      }
    } catch (e) {
      debugPrint('Error toggling favorite contact: $e');
    }
  }

  List<Map<String, dynamic>> getFavoriteContacts() {
    return contacts.where((c) => c['isFavorite'] == true).toList();
  }

  List<Map<String, dynamic>> getPlatformContacts() {
    return contacts.where((c) => c['isPlatformUser'] == true).toList();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  // ========================================
  // OPERATORS
  // ========================================

  Future<void> loadOperatorsFromServer(
      List<Map<String, dynamic>> serverData) async {
    try {
      operators.clear();
      operators.addAll(serverData);
      debugPrint('Loaded ${operators.length} operators from server');
    } catch (e) {
      debugPrint('Error loading operators from server: $e');
    }
  }

  // ========================================
  // SERVICES
  // ========================================

  Future<void> loadServicesFromServer(
      List<Map<String, dynamic>> serverData) async {
    try {
      services.clear();
      services.addAll(serverData);
      debugPrint('Loaded ${services.length} services from server');
    } catch (e) {
      debugPrint('Error loading services from server: $e');
    }
  }

  // ========================================
  // PAYMENT METHODS
  // ========================================

  Future<void> loadPaymentMethodsFromServer(
      List<Map<String, dynamic>> serverData) async {
    try {
      paymentMethods.clear();
      paymentMethods.addAll(serverData);
      debugPrint('Loaded ${paymentMethods.length} payment methods from server');
    } catch (e) {
      debugPrint('Error loading payment methods from server: $e');
    }
  }

  Future<void> addPaymentMethod(Map<String, dynamic> method) async {
    try {
      paymentMethods.add(method);
      debugPrint('Payment method added: ${method['name']}');
    } catch (e) {
      debugPrint('Error adding payment method: $e');
    }
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  Future<void> refreshAllData() async {
    debugPrint('Data refresh requested - will be implemented with server API');
  }

  void clearAllData() {
    transactions.clear();
    cards.clear();
    contacts.clear();
    paymentMethods.clear();
    services.clear();
    operators.clear();
    debugPrint('All local data cleared');
  }
}
