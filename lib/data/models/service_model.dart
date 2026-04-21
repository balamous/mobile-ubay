enum ServiceCategory {
  utilities,
  internet,
  tv,
  streaming,
  insurance,
  other,
}

class ServiceModel {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final ServiceCategory category;
  final bool isPopular;
  final double? fixedAmount;
  final String color;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.category,
    required this.isPopular,
    this.fixedAmount,
    required this.color,
  });

  String get categoryLabel {
    switch (category) {
      case ServiceCategory.utilities:
        return 'Services publics';
      case ServiceCategory.internet:
        return 'Internet';
      case ServiceCategory.tv:
        return 'TV & Câble';
      case ServiceCategory.streaming:
        return 'Streaming';
      case ServiceCategory.insurance:
        return 'Assurance';
      case ServiceCategory.other:
        return 'Autre';
    }
  }
}

class OperatorModel {
  final String id;
  final String name;
  final String logoPath;
  final String color;
  final List<double> amounts;

  OperatorModel({
    required this.id,
    required this.name,
    required this.logoPath,
    required this.color,
    required this.amounts,
  });
}
