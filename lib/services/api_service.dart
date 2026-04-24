import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://localhost:3000';
  static const Duration _timeout = Duration(seconds: 30);
  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ========================================
  // AUTHENTICATION
  // ========================================

  static Future<Map<String, dynamic>> login(
      String phone, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: _headers,
            body: jsonEncode({
              'phone': phone,
              'password': password,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data; // Retourner directement les données de l'API
      } else {
        return {
          'success': false,
          'error': 'Échec de connexion',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur réseau: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/register'),
            headers: _headers,
            body: jsonEncode({
              'email': email,
              'password': password,
              'firstName': firstName,
              'lastName': lastName,
              'phone': phone,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data; // Retourner directement les données de l'API
      } else {
        return {
          'success': false,
          'error': 'Échec d\'inscription',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur réseau: ${e.toString()}',
      };
    }
  }

  // ========================================
  // USER PROFILE
  // ========================================

  static Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/profile'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'success': false,
          'error': 'Échec de récupération du profil',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur réseau: ${e.toString()}',
      };
    }
  }

  // ========================================
  // PAYMENT METHODS
  // ========================================

  static Future<Map<String, dynamic>> getPaymentMethods() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/payment-methods'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data; // Retourner directement les données de l'API
      } else {
        return {
          'success': false,
          'error': 'Échec de récupération des méthodes de paiement',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur réseau: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getOperators() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/operators'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data; // Retourner directement les données de l'API
      } else {
        return {
          'success': false,
          'error': 'Échec de récupération des opérateurs',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur réseau: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/profile'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data; // Retourner directement les données de l'API
      } else {
        return {
          'success': false,
          'error': 'Échec de récupération du profil',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur réseau: ${e.toString()}',
      };
    }
  }

  // ========================================
  // TRANSACTIONS
  // ========================================

  static Future<Map<String, dynamic>> getUserTransactions(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/transactions'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'success': false,
          'error': 'Échec de récupération des transactions',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur réseau: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> saveTransaction({
    required String userId,
    required String type,
    required double amount,
    required String description,
    String? recipient,
    String? category,
    String status = 'completed',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/transactions'),
            headers: {
              ..._headers,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'userId': userId,
              'type': type,
              'amount': amount,
              'description': description,
              'recipient': recipient,
              'category': category,
              'status': status,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'success': false,
          'error': 'Échec de sauvegarde de la transaction',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur réseau: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getUserTransactionsByUserId({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final uri =
          Uri.parse('$_baseUrl/api/transactions').replace(queryParameters: {
        'userId': userId,
        'limit': limit.toString(),
        'offset': offset.toString(),
      });

      final response = await http
          .get(
            uri,
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'success': false,
          'error': 'Échec de récupération des transactions',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur réseau: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> createTransaction(
    Map<String, dynamic> transactionData,
    String token,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/transactions'),
            headers: {
              ..._headers,
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(transactionData),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'success': false,
          'error': 'Échec de création de transaction',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur réseau: ${e.toString()}',
      };
    }
  }

  // ========================================
  // CARDS
  // ========================================

  static Future<Map<String, dynamic>> createCard(
    Map<String, dynamic> cardData,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/cards'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(cardData),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create card');
      }
    } catch (e) {
      print('Create card error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getUserCards(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/cards/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to get cards');
      }
    } catch (e) {
      print('Get cards error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getServiceCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/service-categories'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to get service categories');
      }
    } catch (e) {
      print('Get service categories error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getServices({String? categoryId}) async {
    try {
      String url = '$_baseUrl/api/services';
      if (categoryId != null) {
        url += '?categoryId=$categoryId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to get services');
      }
    } catch (e) {
      print('Get services error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> subscribeToService(
    Map<String, dynamic> subscriptionData,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/service-subscriptions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(subscriptionData),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to subscribe to service');
      }
    } catch (e) {
      print('Subscribe to service error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getUserSubscriptions(
      String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/service-subscriptions/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to get user subscriptions');
      }
    } catch (e) {
      print('Get user subscriptions error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateCard(
    String cardId,
    Map<String, dynamic> cardData,
    String token,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/cards/$cardId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(cardData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to update card');
      }
    } catch (e) {
      print('Update card error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteCard(
    String cardId,
    String token,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/cards/$cardId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete card');
      }
    } catch (e) {
      print('Delete card error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
