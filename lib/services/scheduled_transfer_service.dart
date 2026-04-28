import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'app_controller.dart';

/// Scheduled Transfer Model
class ScheduledTransferModel {
  final String id;
  final String recipientPhone;
  final String recipientName;
  final String? recipientPhotoUrl;
  final double amount;
  final String frequency; // daily, weekly, monthly
  final String startDate;
  final String? endDate;
  final String? reason;
  final String status; // active, paused, completed, cancelled
  final String? lastExecution;
  final String? nextExecution;
  final String createdAt;

  ScheduledTransferModel({
    required this.id,
    required this.recipientPhone,
    required this.recipientName,
    this.recipientPhotoUrl,
    required this.amount,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.reason,
    required this.status,
    this.lastExecution,
    this.nextExecution,
    required this.createdAt,
  });

  factory ScheduledTransferModel.fromJson(Map<String, dynamic> json) {
    return ScheduledTransferModel(
      id: json['id'] ?? '',
      recipientPhone: json['recipientPhone'] ?? '',
      recipientName: json['recipientName'] ?? json['recipientPhone'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      frequency: json['frequency'] ?? 'weekly',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'],
      reason: json['reason'],
      status: json['status'] ?? 'active',
      lastExecution: json['lastExecution'],
      nextExecution: json['nextExecution'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  String get frequencyLabel {
    switch (frequency) {
      case 'daily':
        return 'Quotidien';
      case 'weekly':
        return 'Hebdomadaire';
      case 'monthly':
        return 'Mensuel';
      default:
        return frequency;
    }
  }

  bool get isActive => status == 'active';
}

/// Scheduled Transfer Service
class ScheduledTransferService extends GetxService {
  static ScheduledTransferService get to => Get.find();

  // API base URL
  String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  // Observable list
  final RxList<ScheduledTransferModel> scheduledTransfers =
      <ScheduledTransferModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Load when user logs in
    ever(AppController.to.user, (user) {
      if (user != null) {
        loadScheduledTransfers();
      } else {
        scheduledTransfers.clear();
      }
    });
  }

  /// Load scheduled transfers from backend
  Future<void> loadScheduledTransfers() async {
    final user = AppController.to.user.value;
    if (user == null) return;

    try {
      isLoading.value = true;

      final response = await http.get(
        Uri.parse('$baseUrl/api/scheduled-transfers/${user.id}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> transfersData =
              data['data']['scheduledTransfers'] ?? [];
          scheduledTransfers.value = transfersData
              .map((t) => ScheduledTransferModel.fromJson(t))
              .toList();
          debugPrint(
              '[ScheduledTransferService] Loaded ${scheduledTransfers.length} transfers');
        }
      } else {
        debugPrint(
            '[ScheduledTransferService] Failed to load: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ScheduledTransferService] Error loading: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Create a new scheduled transfer
  Future<bool> createScheduledTransfer({
    required String recipientPhone,
    required double amount,
    required String frequency,
    required String startDate,
    String? endDate,
    String? reason,
  }) async {
    final user = AppController.to.user.value;
    if (user == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/scheduled-transfers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': user.id,
          'recipientPhone': recipientPhone,
          'amount': amount,
          'frequency': frequency,
          'startDate': startDate,
          'endDate': endDate,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await loadScheduledTransfers();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('[ScheduledTransferService] Error creating: $e');
      return false;
    }
  }

  /// Update status (pause/resume/cancel)
  Future<bool> updateStatus(String id, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/scheduled-transfers/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await loadScheduledTransfers();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('[ScheduledTransferService] Error updating status: $e');
      return false;
    }
  }

  /// Delete scheduled transfer
  Future<bool> delete(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/scheduled-transfers/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await loadScheduledTransfers();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('[ScheduledTransferService] Error deleting: $e');
      return false;
    }
  }

  /// Refresh list
  Future<void> refresh() async {
    await loadScheduledTransfers();
  }
}
