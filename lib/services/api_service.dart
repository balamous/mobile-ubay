import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // URL dynamique selon la plateforme
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    // Pour iOS Simulator: utiliser localhost (partage la stack réseau du Mac)
    if (Platform.isIOS) {
      return 'http://127.0.01:3000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

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
        // Capturer le message d'erreur réel du serveur
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'error': errorData['error'] ??
                'Échec d\'inscription (code ${response.statusCode})',
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Échec d\'inscription (code ${response.statusCode})',
          };
        }
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
  // BENEFICIARIES
  // ========================================

  static Future<Map<String, dynamic>> getBeneficiaries(String userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/beneficiaries/$userId'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Échec de récupération des bénéficiaires',
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

  // ========================================
  // DEPOSIT - Credit user balance
  // ========================================
  static Future<Map<String, dynamic>> deposit({
    required String userId,
    required double amount,
    String? description,
    String? paymentMethod,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/deposit'),
            headers: _headers,
            body: jsonEncode({
              'userId': userId,
              'amount': amount,
              'description': description,
              'paymentMethod': paymentMethod,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Échec du dépôt',
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
  // DEBIT - Debit user balance (airtime, withdrawal)
  // ========================================
  static Future<Map<String, dynamic>> debit({
    required String userId,
    required double amount,
    String? description,
    String? category,
    String? recipient,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/debit'),
            headers: _headers,
            body: jsonEncode({
              'userId': userId,
              'amount': amount,
              'description': description,
              'category': category,
              'recipient': recipient,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Échec du débit',
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
  // TRANSFER - Transfer between users
  // ========================================
  static Future<Map<String, dynamic>> transfer({
    required String senderId,
    required String recipientPhone,
    required double amount,
    String? description,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/transfer'),
            headers: _headers,
            body: jsonEncode({
              'senderId': senderId,
              'recipientPhone': recipientPhone,
              'amount': amount,
              'description': description,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Échec du transfert',
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

  // ========================================
  // USER PROFILE
  // ========================================

  static Future<Map<String, dynamic>> updateUserProfile(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/api/users/$userId'),
            headers: _headers,
            body: jsonEncode(userData),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      print('Update user profile error: $e');
      return {
        'success': false,
        'error': 'Erreur réseau: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> uploadUserDocument(
    String userId,
    String documentType,
    String imageData,
    String fileName,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/users/$userId/documents'),
            headers: _headers,
            body: jsonEncode({
              'documentType': documentType,
              'imageData': imageData,
              'fileName': fileName,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to upload document',
        };
      }
    } catch (e) {
      print('Upload document error: $e');
      return {
        'success': false,
        'error': 'Erreur réseau: ${e.toString()}',
      };
    }
  }

  // Upload document using FormData (for MinIO)
  static Future<Map<String, dynamic>> uploadUserDocumentFile(
    String userId,
    String documentType,
    String filePath,
    String fileName,
  ) async {
    try {
      final file = File(filePath);
      final fileSize = await file.length();

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/users/$userId/documents'),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
      });

      // Add file
      final stream = file.openRead();
      final length = fileSize;
      final multipartFile = http.MultipartFile(
        'file',
        stream,
        length,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      // Add document type field
      request.fields['documentType'] = documentType;

      final response = await request.send().timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(await response.stream.bytesToString());
      } else {
        return {
          'success': false,
          'error': 'Failed to upload document: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Upload document file error: $e');
      return {
        'success': false,
        'error': 'Erreur réseau: ${e.toString()}',
      };
    }
  }
}
