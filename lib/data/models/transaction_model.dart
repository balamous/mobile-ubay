enum TransactionType {
  deposit,
  withdrawal,
  transfer,
  payment,
  topup,
  airtime,
  service,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
}

class TransactionModel {
  final String id;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final String description;
  final String? recipient;
  final String? recipientAvatar;
  final DateTime date;
  final String? reference;
  final String? category;
  final bool isCredit;

  TransactionModel({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.description,
    this.recipient,
    this.recipientAvatar,
    required this.date,
    this.reference,
    this.category,
    required this.isCredit,
  });

  String get typeLabel {
    switch (type) {
      case TransactionType.deposit:
        return 'Dépôt';
      case TransactionType.withdrawal:
        return 'Retrait';
      case TransactionType.transfer:
        return 'Transfert';
      case TransactionType.payment:
        return 'Paiement';
      case TransactionType.topup:
        return 'Recharge';
      case TransactionType.airtime:
        return 'Crédit tél.';
      case TransactionType.service:
        return 'Service';
    }
  }

  String get statusLabel {
    switch (status) {
      case TransactionStatus.pending:
        return 'En attente';
      case TransactionStatus.completed:
        return 'Complété';
      case TransactionStatus.failed:
        return 'Échoué';
      case TransactionStatus.cancelled:
        return 'Annulé';
    }
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      type: _parseTransactionType(json['type'] ?? ''),
      status: _parseTransactionStatus(json['status'] ?? ''),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      recipient: json['recipient'],
      recipientAvatar: json['recipientAvatar'],
      date: DateTime.tryParse(json['createdAt']?.toString() ??
              json['date']?.toString() ??
              '') ??
          DateTime.now(),
      reference: json['reference'],
      category: json['category'],
      isCredit: _determineIsCredit(json['type'] ?? ''),
    );
  }

  // Créer une transaction depuis une Map API (pour compatibilité)
  static TransactionModel fromApiMap(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      type: _parseTransactionType(json['type'] ?? ''),
      status: _parseTransactionStatus(json['status'] ?? ''),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      recipient: json['recipient'],
      recipientAvatar: json['recipientAvatar'],
      date: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      reference: json['reference'],
      category: json['category'],
      isCredit: _determineIsCredit(json['type'] ?? ''),
    );
  }

  // Créer une transaction pour une opération
  static TransactionModel create({
    required String userId,
    required TransactionType type,
    required double amount,
    required String description,
    String? recipient,
    String? category,
    TransactionStatus status = TransactionStatus.completed,
  }) {
    return TransactionModel(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      status: status,
      amount: amount,
      description: description,
      recipient: recipient,
      date: DateTime.now(),
      category: category,
      isCredit: _determineIsCredit(type.name),
    );
  }

  // Convertir en Map pour l'API
  Map<String, dynamic> toApiMap(String userId) {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'description': description,
      'recipient': recipient,
      'category': category,
      'status': status.name,
      'createdAt': date.toIso8601String(),
    };
  }

  // Déterminer si c'est un crédit basé sur le type
  static bool _determineIsCredit(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
        return true;
      case 'withdrawal':
        return false;
      case 'transfer':
        return false;
      case 'payment':
        return false;
      case 'topup':
        return false;
      case 'airtime':
        return false;
      case 'service':
        return false;
      default:
        return false;
    }
  }

  static TransactionType _parseTransactionType(String type) {
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
      case 'service':
        return TransactionType.service;
      default:
        return TransactionType.deposit;
    }
  }

  static TransactionStatus _parseTransactionStatus(String status) {
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
}
