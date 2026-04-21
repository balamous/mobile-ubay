import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../data/models/transaction_model.dart';
import '../data/models/user_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class TransactionService extends GetxService {
  static TransactionService get to => Get.find();

  // Observable state
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  // Types de transactions
  static const String TYPE_DEPOSIT = 'deposit';
  static const String TYPE_WITHDRAWAL = 'withdrawal';
  static const String TYPE_TRANSFER = 'transfer';
  static const String TYPE_PAYMENT = 'payment';
  static const String TYPE_TOPUP = 'topup';
  static const String TYPE_AIRTIME = 'airtime';
  static const String TYPE_SERVICE = 'service';

  // ========================================
  // SAVE TRANSACTION
  // ========================================

  Future<bool> saveTransaction({
    required TransactionType type,
    required double amount,
    required String description,
    String? recipient,
    String? category,
    TransactionStatus status = TransactionStatus.completed,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final authService = AuthService.to;
      if (authService.currentUser.value == null) {
        error.value = 'Utilisateur non connecté';
        return false;
      }

      final userId = authService.currentUser.value!.id;
      
      // Créer la transaction
      final transaction = TransactionModel.create(
        userId: userId,
        type: type,
        amount: amount,
        description: description,
        recipient: recipient,
        category: category,
        status: status,
      );

      // Sauvegarder via l'API
      final result = await ApiService.saveTransaction(
        userId: userId,
        type: type.name,
        amount: amount,
        description: description,
        recipient: recipient,
        category: category,
        status: status.name,
      );

      if (result['success'] == true) {
        // Ajouter à la liste locale
        transactions.insert(0, transaction);
        debugPrint('Transaction sauvegardée: ${transaction.id}');
        return true;
      } else {
        error.value = result['error'] ?? 'Erreur de sauvegarde';
        debugPrint('Erreur sauvegarde transaction: ${result['error']}');
        return false;
      }
    } catch (e) {
      error.value = 'Erreur: ${e.toString()}';
      debugPrint('Exception sauvegarde transaction: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ========================================
  // LOAD TRANSACTIONS
  // ========================================

  Future<bool> loadTransactions({int limit = 50, int offset = 0}) async {
    try {
      isLoading.value = true;
      error.value = '';

      final authService = AuthService.to;
      if (authService.currentUser.value == null) {
        error.value = 'Utilisateur non connecté';
        return false;
      }

      final userId = authService.currentUser.value!.id;

      // Récupérer depuis l'API
      final result = await ApiService.getUserTransactionsByUserId(
        userId: userId,
        limit: limit,
        offset: offset,
      );

      if (result['success'] == true) {
        final List<dynamic> transactionsData = result['data']['transactions'] ?? [];
        
        // Convertir en TransactionModel
        final List<TransactionModel> loadedTransactions = transactionsData
            .map((tx) => TransactionModel.fromApiMap(tx as Map<String, dynamic>))
            .toList();

        // Mettre à jour la liste
        if (offset == 0) {
          transactions.value = loadedTransactions;
        } else {
          transactions.addAll(loadedTransactions);
        }

        debugPrint('Transactions chargées: ${loadedTransactions.length}');
        return true;
      } else {
        error.value = result['error'] ?? 'Erreur de chargement';
        debugPrint('Erreur chargement transactions: ${result['error']}');
        return false;
      }
    } catch (e) {
      error.value = 'Erreur: ${e.toString()}';
      debugPrint('Exception chargement transactions: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  // Obtenir les transactions récentes pour le dashboard
  List<TransactionModel> get recentTransactions {
    return transactions.take(5).toList();
  }

  // Filtrer les transactions par type
  List<TransactionModel> getTransactionsByType(TransactionType type) {
    return transactions.where((tx) => tx.type == type).toList();
  }

  // Obtenir le total des transactions par type
  double getTotalByType(TransactionType type) {
    return transactions
        .where((tx) => tx.type == type && tx.status == TransactionStatus.completed)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // Obtenir le solde total (crédits - débits)
  double get totalBalance {
    double credits = transactions
        .where((tx) => tx.isCredit && tx.status == TransactionStatus.completed)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    
    double debits = transactions
        .where((tx) => !tx.isCredit && tx.status == TransactionStatus.completed)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    
    return credits - debits;
  }

  // Vider la liste des transactions
  void clearTransactions() {
    transactions.clear();
  }

  // Rafraîchir les transactions
  Future<bool> refreshTransactions() async {
    clearTransactions();
    return await loadTransactions();
  }

  // ========================================
  // CONVENIENCE METHODS
  // ========================================

  // Dépôt
  Future<bool> saveDeposit(double amount, String description) async {
    return await saveTransaction(
      type: TransactionType.deposit,
      amount: amount,
      description: description,
      category: 'deposit',
    );
  }

  // Retrait
  Future<bool> saveWithdrawal(double amount, String description, String? point) async {
    return await saveTransaction(
      type: TransactionType.withdrawal,
      amount: amount,
      description: description,
      recipient: point,
      category: 'withdrawal',
    );
  }

  // Transfert
  Future<bool> saveTransfer(double amount, String description, String recipient) async {
    return await saveTransaction(
      type: TransactionType.transfer,
      amount: amount,
      description: description,
      recipient: recipient,
      category: 'transfer',
    );
  }

  // Paiement
  Future<bool> savePayment(double amount, String description, String recipient) async {
    return await saveTransaction(
      type: TransactionType.payment,
      amount: amount,
      description: description,
      recipient: recipient,
      category: 'payment',
    );
  }

  // Recharge
  Future<bool> saveTopup(double amount, String description, String? operator) async {
    return await saveTransaction(
      type: TransactionType.topup,
      amount: amount,
      description: description,
      recipient: operator,
      category: 'topup',
    );
  }

  // Crédit téléphonique
  Future<bool> saveAirtime(double amount, String description, String? operator) async {
    return await saveTransaction(
      type: TransactionType.airtime,
      amount: amount,
      description: description,
      recipient: operator,
      category: 'airtime',
    );
  }

  // Service
  Future<bool> saveService(double amount, String description, String service) async {
    return await saveTransaction(
      type: TransactionType.service,
      amount: amount,
      description: description,
      recipient: service,
      category: 'service',
    );
  }

  void clearError() {
    error.value = '';
  }
}
