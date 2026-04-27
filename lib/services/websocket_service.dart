import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'app_controller.dart';
import 'database_service.dart';
import 'transaction_service.dart';

/// WebSocket Service for real-time transaction notifications
/// Connects to backend Socket.IO server and handles all real-time events
class WebSocketService extends GetxService {
  static WebSocketService get to => Get.find();

  // Socket instance
  IO.Socket? _socket;

  // Connection state
  final RxBool isConnected = false.obs;
  final RxBool isAuthenticated = false.obs;

  // Stream controllers for different event types
  final _transactionController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _balanceController = StreamController<Map<String, dynamic>>.broadcast();
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get onTransaction =>
      _transactionController.stream;
  Stream<Map<String, dynamic>> get onBalanceUpdate => _balanceController.stream;
  Stream<Map<String, dynamic>> get onNotification =>
      _notificationController.stream;

  // Server URL
  String get _serverUrl {
    if (Platform.isIOS) {
      return 'http://localhost:3000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  @override
  void onInit() {
    super.onInit();
    // Auto-connect when service initializes
    ever(AppController.to.user, (user) {
      if (user != null && !isConnected.value) {
        connect();
      } else if (user == null && isConnected.value) {
        disconnect();
      }
    });
  }

  @override
  void onClose() {
    disconnect();
    _transactionController.close();
    _balanceController.close();
    _notificationController.close();
    super.onClose();
  }

  /// Connect to WebSocket server
  void connect() {
    if (_socket != null && _socket!.connected) {
      debugPrint('[WebSocket] Already connected');
      return;
    }

    debugPrint('[WebSocket] Connecting to $_serverUrl...');

    _socket = IO.io(
        _serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setRandomizationFactor(0.5)
            .build());

    _setupEventListeners();
    _socket!.connect();
  }

  /// Disconnect from WebSocket server
  void disconnect() {
    if (_socket == null) return;

    debugPrint('[WebSocket] Disconnecting...');
    _socket!.disconnect();
    _socket = null;
    isConnected.value = false;
    isAuthenticated.value = false;
  }

  /// Setup all event listeners
  void _setupEventListeners() {
    _socket!.on('connect', (_) {
      debugPrint('[WebSocket] Connected');
      isConnected.value = true;
      _authenticate();
    });

    _socket!.on('disconnect', (reason) {
      debugPrint('[WebSocket] Disconnected: $reason');
      isConnected.value = false;
      isAuthenticated.value = false;
    });

    _socket!.on('connect_error', (error) {
      debugPrint('[WebSocket] Connection error: $error');
    });

    _socket!.on('authenticated', (data) {
      debugPrint('[WebSocket] Authenticated: $data');
      isAuthenticated.value = true;
    });

    // Transaction events
    _socket!.on('new_transaction', (data) {
      debugPrint('[WebSocket] New transaction: $data');
      _transactionController.add(data);
      _handleTransaction(data);
    });

    // Balance update events
    _socket!.on('balance_update', (data) {
      debugPrint('[WebSocket] Balance update: $data');
      _balanceController.add(data);
      _handleBalanceUpdate(data);
    });

    // General notifications
    _socket!.on('notification', (data) {
      debugPrint('[WebSocket] Notification: $data');
      _notificationController.add(data);
      _handleNotification(data);
    });
  }

  /// Authenticate with user ID
  void _authenticate() {
    final user = AppController.to.user.value;
    if (user != null) {
      debugPrint('[WebSocket] Authenticating as user ${user.id}');
      _socket!.emit('authenticate', {'userId': user.id});
    }
  }

  /// Handle incoming transaction
  void _handleTransaction(Map<String, dynamic> data) {
    try {
      final transaction = data['data'] as Map<String, dynamic>?;
      if (transaction == null) return;

      final type = transaction['type'] as String?;
      final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
      final newBalance = (transaction['newBalance'] as num?)?.toDouble();

      // Update user balance in AppController
      if (newBalance != null) {
        _updateUserBalance(newBalance);
      }

      // Refresh transactions from database
      TransactionService.to.loadTransactions();

      // Show notification for received transfers
      if (type == 'transfer_received') {
        _showTransferNotification(transaction);
      }
    } catch (e) {
      debugPrint('[WebSocket] Error handling transaction: $e');
    }
  }

  /// Handle balance update
  void _handleBalanceUpdate(Map<String, dynamic> data) {
    try {
      final balanceData = data['data'] as Map<String, dynamic>?;
      if (balanceData == null) return;

      final newBalance = (balanceData['balance'] as num?)?.toDouble();
      if (newBalance != null) {
        _updateUserBalance(newBalance);
      }
    } catch (e) {
      debugPrint('[WebSocket] Error handling balance update: $e');
    }
  }

  /// Handle general notification
  void _handleNotification(Map<String, dynamic> data) {
    // Handle other types of notifications if needed
    debugPrint('[WebSocket] General notification: ${data['message']}');
  }

  /// Update user balance in AppController
  void _updateUserBalance(double newBalance) {
    final currentUser = AppController.to.user.value;
    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(balance: newBalance);
      AppController.to.updateUser(updatedUser);
      debugPrint('[WebSocket] Balance updated: $newBalance');
    }
  }

  /// Show transfer received notification
  void _showTransferNotification(Map<String, dynamic> transaction) {
    final senderName = transaction['senderName'] as String? ?? 'Quelqu\'un';
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;

    Get.snackbar(
      '💰 Transfert reçu !',
      'Vous avez reçu ${amount.toStringAsFixed(0)} FCFA de $senderName',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 5),
      backgroundColor: const Color(0xFF4CAF50),
      colorText: const Color(0xFFFFFFFF),
      icon: const Icon(Icons.arrow_downward, color: Colors.white),
    );
  }

  /// Manual reconnect
  void reconnect() {
    disconnect();
    Future.delayed(const Duration(seconds: 1), connect);
  }

  /// Check connection status
  bool get connected => _socket?.connected ?? false;
}
