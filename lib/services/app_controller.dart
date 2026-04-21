import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../data/models/user_model.dart';
import '../data/models/transaction_model.dart';
import '../data/models/card_model.dart';
import 'database_service.dart';

class AppController extends GetxController {
  static AppController get to => Get.find();

  final DatabaseService _db = DatabaseService.to;
  final RxBool isDarkMode = false.obs;
  final RxBool isLoading = false.obs;

  // Getters that delegate to DatabaseService
  Rx<UserModel?> get user => _db.currentUser;
  RxList<TransactionModel> get transactions => _db.transactions;
  RxList<CardModel> get cards => _db.cards;
  RxList<Map<String, dynamic>> get contacts => _db.contacts;
  RxList<Map<String, dynamic>> get paymentMethods => _db.paymentMethods;
  RxList<Map<String, dynamic>> get services => _db.services;
  RxList<Map<String, dynamic>> get operators => _db.operators;

  void toggleTheme() => isDarkMode.toggle();

  Future<void> addTransaction(TransactionModel tx) async {
    await _db.addTransaction(tx);
  }

  Future<void> updateBalance(double delta) async {
    await _db.updateBalance(delta.abs(), isCredit: delta > 0);
  }

  void toggleCardStatus(String cardId) {
    final idx = cards.indexWhere((c) => c.id == cardId);
    if (idx != -1) {
      final card = cards[idx];
      cards[idx] = card.copyWith(
        status: card.status == CardStatus.active
            ? CardStatus.blocked
            : CardStatus.active,
      );
      cards.refresh();
    }
  }

  String generateReference(String prefix) {
    return _db.generateReference(prefix);
  }

  Future<void> updateUser(UserModel updatedUser) async {
    _db.currentUser.value = updatedUser;
  }

  Future<void> simulateLoading([Duration? duration]) async {
    isLoading.value = true;
    await Future.delayed(duration ?? const Duration(milliseconds: 1500));
    isLoading.value = false;
  }

  // Additional methods for dynamic data
  Future<void> addCard(CardModel card) async {
    await _db.addCard(card);
  }

  // Contact methods (cached locally, not stored on server)
  Future<void> addContact(Map<String, dynamic> contact) async {
    await _db.addContact(contact);
  }

  Future<void> addPlatformContact(String name, String phone) async {
    await _db.addPlatformContact(name, phone);
  }

  Future<void> removeContact(String phone) async {
    await _db.removeContact(phone);
  }

  Future<void> toggleFavoriteContact(String phone) async {
    await _db.toggleFavoriteContact(phone);
  }

  List<Map<String, dynamic>> get favoriteContacts => _db.getFavoriteContacts();
  List<Map<String, dynamic>> get platformContacts => _db.getPlatformContacts();

  Future<void> addNotification(Map<String, dynamic> notification) async {
    debugPrint('Notification addition requested: ${notification['title']}');
    // Will be implemented with server API
  }

  int get unreadNotificationsCount => 0; // Will be implemented with server API
}
