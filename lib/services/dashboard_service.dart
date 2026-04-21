import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../data/models/user_model.dart';
import '../data/models/transaction_model.dart';
import '../data/models/card_model.dart';

class DashboardService extends GetxService {
  static DashboardService get to => Get.find();

  final String _baseUrl = 'http://localhost:3000';
  final Duration _timeout = const Duration(seconds: 30);

  // ========================================
  // API METHODS
  // ========================================

  Future<Map<String, dynamic>> getHealthStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'status': 'unhealthy'};
    } catch (e) {
      return {'status': 'error', 'error': e.toString()};
    }
  }

  Future<UserModel?> getUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel(
          id: data['id'] ?? '',
          firstName: data['firstName'] ?? '',
          lastName: data['lastName'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          avatarUrl: 'https://ui-avatars.com/api/?name=${data['firstName'] ?? ''}+${data['lastName'] ?? ''}&background=7C3AED&color=fff',
          balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
          savingsBalance: (data['savings_balance'] as num?)?.toDouble() ?? 0.0,
          accountNumber: data['account_number'] ?? '',
          isVerified: data['is_verified'] ?? false,
          kycLevel: data['kyc_level'] ?? 'none',
          createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
          birthDate: data['birth_date'] ?? '',
          birthPlace: data['birth_place'] ?? '',
          gender: data['gender'] ?? '',
          profession: data['profession'] ?? '',
          employer: data['employer'] ?? '',
          city: data['city'] ?? '',
          commune: data['commune'] ?? '',
          neighborhood: data['neighborhood'] ?? '',
          nationality: data['nationality'] ?? '',
          idCountry: data['id_country'] ?? '',
          idType: data['id_type'] ?? '',
          idNumber: data['id_number'] ?? '',
          idIssueDate: data['id_issue_date'] ?? '',
          idExpiryDate: data['id_expiry_date'] ?? '',
          idVerifiedAt: data['id_verified_at'] != null
              ? DateTime.tryParse(data['id_verified_at'].toString())
              : null,
        );
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<List<TransactionModel>> getTransactions(String token, {
    int page = 1,
    int limit = 20,
    String? type,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (type != null) 'type': type!,
        if (status != null) 'status': status!,
      };

      final uri = Uri.parse('$_baseUrl/transactions');
      final requestUri = uri.replace(queryParameters: queryParams);

      final response = await http.get(
        requestUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transactionsList = data['transactions'] as List;
        return transactionsList.map((tx) {
          return TransactionModel(
            id: tx['id'] ?? '',
            type: _parseTransactionType(tx['type'] ?? ''),
            status: _parseTransactionStatus(tx['status'] ?? ''),
            amount: (tx['amount'] as num?)?.toDouble() ?? 0.0,
            description: tx['description'] ?? '',
            recipient: tx['recipient'] ?? '',
            recipientAvatar: tx['recipient_avatar'] ?? '',
            reference: tx['reference'] ?? '',
            category: tx['category'] ?? '',
            isCredit: tx['is_credit'] ?? false,
            date: DateTime.tryParse(tx['date'] ?? '') ?? DateTime.now(),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  Future<List<CardModel>> getCards(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/cards'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cardsList = data as List;
        return cardsList.map((card) {
          return CardModel(
            id: card['id'] ?? '',
            cardNumber: card['card_number'] ?? '',
            cardHolder: card['card_holder'] ?? '',
            expiryMonth: card['expiry_month'] ?? '',
            expiryYear: card['expiry_year'] ?? '',
            cvv: card['cvv'] ?? '',
            type: _parseCardType(card['card_type'] ?? ''),
            status: _parseCardStatus(card['status'] ?? ''),
            limit: (card['limit'] as num?)?.toDouble() ?? 0.0,
            spent: (card['spent'] as num?)?.toDouble() ?? 0.0,
            isVirtual: card['is_virtual'] ?? false,
            gradientStart: card['gradient_start'] ?? '',
            gradientEnd: card['gradient_end'] ?? '',
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error getting cards: $e');
      return [];
    }
  }

  // ========================================
  // PARSING HELPERS
  // ========================================

  TransactionType _parseTransactionType(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
        return TransactionType.deposit;
      case 'withdrawal':
        return TransactionType.withdrawal;
      case 'transfer':
        return TransactionType.transfer;
      case 'payment':
        return TransactionType.payment;
      case 'topup':
        return TransactionType.topup;
      case 'airtime':
        return TransactionType.airtime;
      default:
        return TransactionType.deposit;
    }
  }

  TransactionStatus _parseTransactionStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return TransactionStatus.pending;
      case 'completed':
        return TransactionStatus.completed;
      case 'failed':
        return TransactionStatus.failed;
      case 'cancelled':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.pending;
    }
  }

  CardType _parseCardType(String type) {
    switch (type.toLowerCase()) {
      case 'visa':
        return CardType.visa;
      case 'mastercard':
        return CardType.mastercard;
      default:
        return CardType.visa;
    }
  }

  CardStatus _parseCardStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return CardStatus.active;
      case 'blocked':
        return CardStatus.blocked;
      case 'expired':
        return CardStatus.expired;
      default:
        return CardStatus.active;
    }
  }

  // ========================================
  // MOCK DATA FALLBACK
  // ========================================

  Future<List<TransactionModel>> getMockTransactions() async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 800));
    
    return [
      TransactionModel(
        id: 'tx_001',
        type: TransactionType.transfer,
        status: TransactionStatus.completed,
        amount: 150000.00,
        description: 'Transfert à Bah Mamadou',
        recipient: 'Bah Mamadou',
        recipientAvatar: 'https://ui-avatars.com/api/?name=Bah+Mamadou&background=7C3AED&color=fff',
        reference: 'TRF202412200001',
        category: 'Transfert',
        isCredit: false,
        date: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      TransactionModel(
        id: 'tx_002',
        type: TransactionType.deposit,
        status: TransactionStatus.completed,
        amount: 500000.00,
        description: 'Dépôt Orange Money',
        recipient: 'Orange Money',
        recipientAvatar: 'https://ui-avatars.com/api/?name=Orange+Money&background=FF6B35&color=fff',
        reference: 'DEP202412200002',
        category: 'Dépôt',
        isCredit: true,
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TransactionModel(
        id: 'tx_003',
        type: TransactionType.payment,
        status: TransactionStatus.completed,
        amount: 25000.00,
        description: 'Paiement SODECI',
        recipient: 'SODECI',
        recipientAvatar: 'https://ui-avatars.com/api/?name=SODECI&background=10B981&color=fff',
        reference: 'PAY202412200003',
        category: 'Services',
        isCredit: false,
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  Future<List<CardModel>> getMockCards() async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 600));
    
    return [
      CardModel(
        id: 'card_001',
        cardNumber: '**** **** **** 4532',
        cardHolder: 'Mamadou Bah',
        expiryMonth: '12',
        expiryYear: '25',
        cvv: '123',
        type: CardType.visa,
        status: CardStatus.active,
        limit: 1000000.00,
        spent: 250000.00,
        isVirtual: false,
        gradientStart: '#667EEA',
        gradientEnd: '#764BA2',
      ),
      CardModel(
        id: 'card_002',
        cardNumber: '**** **** **** 7891',
        cardHolder: 'Mamadou Bah',
        expiryMonth: '09',
        expiryYear: '24',
        cvv: '456',
        type: CardType.mastercard,
        status: CardStatus.active,
        limit: 500000.00,
        spent: 125000.00,
        isVirtual: true,
        gradientStart: '#F093FB',
        gradientEnd: '#F5576C',
      ),
    ];
  }
}
