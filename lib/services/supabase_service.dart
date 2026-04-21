import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../data/models/user_model.dart';
import '../data/models/transaction_model.dart';
import '../data/models/card_model.dart';
import '../data/models/service_model.dart';

class SupabaseService extends GetxService {
  static SupabaseService get to => Get.find();
  late final SupabaseClient _supabase;

  @override
  Future<void> onInit() async {
    super.onInit();

    await dotenv.load(fileName: ".env");

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? 'http://localhost:8000',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ??
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7OEeoPwXJtBj47BKgPvMiHIGmpxz4t8-1jz9M',
    );
    _supabase = Supabase.instance.client;
  }

  // ========================================
  // AUTHENTICATION
  // ========================================

  Future<AuthResponse> signUpWithEmail(
    String email,
    String password, {
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
        },
      );

      if (response.user != null) {
        // Create user profile
        await _createUserProfile(
            response.user!.id, email, firstName, lastName, phone);
      }

      return response;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      return await _supabase.auth
          .signInWithPassword(email: email, password: password);
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      return _supabase.auth.currentUser;
    } catch (e) {
      debugPrint('Get current user error: $e');
      return null;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Reset password error: $e');
      rethrow;
    }
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // ========================================
  // USER PROFILE
  // ========================================

  Future<void> _createUserProfile(String userId, String email, String firstName,
      String lastName, String phone) async {
    try {
      final accountNumber = _generateAccountNumber();

      await _supabase.from('users').insert({
        'id': userId,
        'email': email,
        'phone': phone,
        'first_name': firstName,
        'last_name': lastName,
        'account_number': accountNumber,
        'balance': 0.0,
        'savings_balance': 0.0,
        'is_verified': false,
        'kyc_level': 'basic',
      });
    } catch (e) {
      debugPrint('Create user profile error: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response =
          await _supabase.from('users').select().eq('id', userId).single();

      if (response != null) {
        return _mapToUserModel(response);
      }
      return null;
    } catch (e) {
      debugPrint('Get user profile error: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      await _supabase.from('users').update(data).eq('id', userId);
    } catch (e) {
      debugPrint('Update user profile error: $e');
      rethrow;
    }
  }

  Future<void> updateBalance(String userId, double amount,
      {bool isCredit = true}) async {
    try {
      final currentBalance = await _supabase
          .from('users')
          .select('balance')
          .eq('id', userId)
          .single();

      final newBalance =
          (currentBalance['balance'] as double) + (isCredit ? amount : -amount);

      await _supabase
          .from('users')
          .update({'balance': newBalance}).eq('id', userId);
    } catch (e) {
      debugPrint('Update balance error: $e');
      rethrow;
    }
  }

  // ========================================
  // TRANSACTIONS
  // ========================================

  Future<List<TransactionModel>> getTransactions(String userId,
      {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(limit);

      return response.map((tx) => _mapToTransactionModel(tx)).toList();
    } catch (e) {
      debugPrint('Get transactions error: $e');
      return [];
    }
  }

  Future<TransactionModel?> createTransaction(
      TransactionModel transaction) async {
    try {
      final response = await _supabase
          .from('transactions')
          .insert({
            'id': transaction.id,
            'user_id': transaction.id, // Will be updated with actual user_id
            'type': transaction.type.name,
            'status': transaction.status.name,
            'amount': transaction.amount,
            'description': transaction.description,
            'recipient': transaction.recipient,
            'recipient_avatar': transaction.recipientAvatar,
            'reference': transaction.reference,
            'category': transaction.category,
            'is_credit': transaction.isCredit,
            'date': transaction.date.toIso8601String(),
          })
          .select()
          .single();

      if (response != null) {
        return _mapToTransactionModel(response);
      }
      return null;
    } catch (e) {
      debugPrint('Create transaction error: $e');
      return null;
    }
  }

  // ========================================
  // CARDS
  // ========================================

  Future<List<CardModel>> getCards(String userId) async {
    try {
      final response = await _supabase
          .from('cards')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false);

      return response.map((card) => _mapToCardModel(card)).toList();
    } catch (e) {
      debugPrint('Get cards error: $e');
      return [];
    }
  }

  Future<CardModel?> createCard(CardModel card) async {
    try {
      final response = await _supabase
          .from('cards')
          .insert({
            'id': card.id,
            'user_id': card.user?.id,
            'card_number': card.cardNumber,
            'card_holder': card.cardHolder,
            'expiry_month': card.expiryMonth,
            'expiry_year': card.expiryYear,
            'cvv': card.cvv,
            'card_type': card.type,
            'is_default': card.isDefault,
            'is_active': card.isActive,
            'balance': card.spent,
            'limit_amount': card.limit,
          })
          .select()
          .single();

      if (response != null) {
        return _mapToCardModel(response);
      }
      return null;
    } catch (e) {
      debugPrint('Create card error: $e');
      return null;
    }
  }

  // ========================================
  // SERVICES
  // ========================================

  Future<List<ServiceModel>> getServices() async {
    try {
      final response = await _supabase
          .from('services')
          .select()
          .order('is_popular', ascending: false);

      return response.map((service) => _mapToServiceModel(service)).toList();
    } catch (e) {
      debugPrint('Get services error: $e');
      return [];
    }
  }

  // ========================================
  // OPERATORS
  // ========================================

  Future<List<Map<String, dynamic>>> getOperators() async {
    try {
      final operators = await _supabase
          .from('operators')
          .select('*, operator_amounts(amount)')
          .eq('is_active', true);

      return operators;
    } catch (e) {
      debugPrint('Get operators error: $e');
      return [];
    }
  }

  // ========================================
  // PAYMENT METHODS
  // ========================================

  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      return await _supabase
          .from('payment_methods')
          .select()
          .eq('is_active', true);
    } catch (e) {
      debugPrint('Get payment methods error: $e');
      return [];
    }
  }

  // ========================================
  // CONTACTS
  // ========================================

  Future<List<Map<String, dynamic>>> getContacts(String userId) async {
    try {
      return await _supabase
          .from('contacts')
          .select()
          .eq('user_id', userId)
          .order('is_favorite', ascending: F);
    } catch (e) {
      debugPrint('Get contacts error: $e');
      return [];
    }
  }

  Future<void> addContact(String userId, Map<String, dynamic> contact) async {
    try {
      await _supabase.from('contacts').insert({
        'user_id': userId,
        ...contact,
      });
    } catch (e) {
      debugPrint('Add contact error: $e');
      rethrow;
    }
  }

  // ========================================
  // NOTIFICATIONS
  // ========================================

  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      return await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
    } catch (e) {
      debugPrint('Get notifications error: $e');
      return [];
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
    } catch (e) {
      debugPrint('Mark notification as read error: $e');
      rethrow;
    }
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  String _generateAccountNumber() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return 'GN${random.toString().substring(5)}';
  }

  UserModel _mapToUserModel(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'],
      firstName: data['first_name'],
      lastName: data['last_name'],
      email: data['email'],
      phone: data['phone'],
      avatarUrl: data['avatar_url'] ?? '',
      balance: (data['balance'] as num).toDouble(),
      savingsBalance: (data['savings_balance'] as num).toDouble(),
      accountNumber: data['account_number'],
      isVerified: data['is_verified'],
      kycLevel: data['kyc_level'],
      createdAt: DateTime.parse(data['created_at']),
      birthDate: data['birth_date'],
      birthPlace: data['birth_place'],
      gender: data['gender'],
      profession: data['profession'],
      employer: data['employer'],
      city: data['city'],
      commune: data['commune'],
      neighborhood: data['neighborhood'],
      nationality: data['nationality'],
      idCountry: data['id_country'],
      idType: data['id_type'],
      idNumber: data['id_number'],
      idIssueDate: data['id_issue_date'],
      idExpiryDate: data['id_expiry_date'],
      idVerifiedAt: data['id_verified_at'],
    );
  }

  TransactionModel _mapToTransactionModel(Map<String, dynamic> data) {
    return TransactionModel(
      id: data['id'],
      type: TransactionType.values.firstWhere((e) => e.name == data['type']),
      status:
          TransactionStatus.values.firstWhere((e) => e.name == data['status']),
      amount: (data['amount'] as num).toDouble(),
      description: data['description'],
      recipient: data['recipient'],
      recipientAvatar: data['recipient_avatar'],
      date: DateTime.parse(data['date']),
      reference: data['reference'],
      category: data['category'],
      isCredit: data['is_credit'],
    );
  }

  CardModel _mapToCardModel(Map<String, dynamic> data) {
    return CardModel(
      id: data['id'],
      cardNumber: data['card_number'],
      cardHolder: data['card_holder'],
      expiryMonth: data['expiry_month'],
      expiryYear: data['expiry_year'],
      cvv: data['cvv'],
      type: CardType.values.firstWhere((e) => e.name == data['card_type']),
      status: CardStatus.values.firstWhere((e) => e.name == data['status']),
      limit: (data['limit'] as num?)?.toDouble() ?? 0.0,
      spent: (data['spent'] as num?)?.toDouble() ?? 0.0,
      isVirtual: data['is_virtual'] ?? false,
      gradientStart: data['gradient_start'],
      gradientEnd: data['gradient_end'],
    );
  }

  ServiceModel _mapToServiceModel(Map<String, dynamic> data) {
    return ServiceModel(
      id: data['id'],
      name: data['name'],
      category:
          ServiceCategory.values.firstWhere((e) => e.name == data['category']),
      color: data['color'],
      iconPath: data['icon_path'],
      isPopular: data['is_popular'],
      fixedAmount: (data['fixed_amount'] as num?)?.toDouble(),
      description: '',
    );
  }
}
