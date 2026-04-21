import 'package:supabase_flutter/supabase_flutter.dart';

enum CardType { visa, mastercard }

enum CardStatus { active, blocked, expired }

class CardModel {
  final String id;
  final String cardNumber;
  final String cardHolder;
  final String expiryMonth;
  final String expiryYear;
  final String cvv;
  final CardType? type;
  final CardStatus? status;
  final double? limit;
  final double? spent;
  final bool isVirtual;
  final String? gradientStart;
  final String? gradientEnd;
  final User? user;
  final bool? isDefault;

  CardModel(
      {required this.id,
      required this.cardNumber,
      required this.cardHolder,
      required this.expiryMonth,
      required this.expiryYear,
      required this.cvv,
      this.type,
      this.status,
      this.limit,
      this.spent,
      required this.isVirtual,
      this.gradientStart,
      this.gradientEnd,
      this.user,
      this.isDefault});

  String get maskedNumber =>
      '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';

  String get expiryDate => '$expiryMonth/$expiryYear';

  bool get isActive => status == CardStatus.active;

  double get availableBalance => limit! - spent!;

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] ?? '',
      cardNumber: json['cardNumber'] ?? '',
      cardHolder: json['cardHolder'] ?? '',
      expiryMonth: json['expiryMonth'] ?? '',
      expiryYear: json['expiryYear'] ?? '',
      cvv: json['cvv'] ?? '',
      type: _parseCardType(json['type'] ?? ''),
      status: _parseCardStatus(json['status'] ?? ''),
      limit: (json['limit'] as num?)?.toDouble(),
      spent: (json['spent'] as num?)?.toDouble(),
      isVirtual: json['isVirtual'] ?? false,
      gradientStart: json['gradientStart'],
      gradientEnd: json['gradientEnd'],
      user: json['user'],
      isDefault: json['isDefault'],
    );
  }

  static CardType _parseCardType(String type) {
    switch (type.toLowerCase()) {
      case 'visa':
        return CardType.visa;
      case 'mastercard':
        return CardType.mastercard;
      default:
        return CardType.visa;
    }
  }

  static CardStatus _parseCardStatus(String status) {
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

  CardModel copyWith({CardStatus? status, double? spent}) {
    return CardModel(
      id: id,
      cardNumber: cardNumber,
      cardHolder: cardHolder,
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      cvv: cvv,
      type: type,
      status: status ?? this.status,
      limit: limit,
      spent: spent ?? this.spent,
      isVirtual: isVirtual,
      gradientStart: gradientStart,
      gradientEnd: gradientEnd,
    );
  }
}
