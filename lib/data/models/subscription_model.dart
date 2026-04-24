class UserSubscription {
  final String id;
  final String serviceId;
  final String serviceName;
  final String serviceDescription;
  final String serviceIcon;
  final String serviceColor;
  final String status;
  final double amount;
  final String? nextBillingDate;
  final bool autoRenew;
  final String createdAt;

  UserSubscription({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.serviceDescription,
    required this.serviceIcon,
    required this.serviceColor,
    required this.status,
    required this.amount,
    this.nextBillingDate,
    required this.autoRenew,
    required this.createdAt,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'] ?? '',
      serviceId: json['serviceId'] ?? '',
      serviceName: json['serviceName'] ?? '',
      serviceDescription: json['serviceDescription'] ?? '',
      serviceIcon: json['serviceIcon'] ?? '',
      serviceColor: json['serviceColor'] ?? '',
      status: json['status'] ?? 'active',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      nextBillingDate: json['nextBillingDate'],
      autoRenew: json['autoRenew'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'serviceDescription': serviceDescription,
      'serviceIcon': serviceIcon,
      'serviceColor': serviceColor,
      'status': status,
      'amount': amount,
      'nextBillingDate': nextBillingDate,
      'autoRenew': autoRenew,
      'createdAt': createdAt,
    };
  }

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isCancelled => status == 'cancelled';
}
