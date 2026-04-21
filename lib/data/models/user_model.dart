class UserModel {
  // ── Core account ──────────────────────────────────────────────────────────
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? avatarUrl;
  final double balance;
  final double savingsBalance;
  final String accountNumber;
  final bool isVerified;
  final String kycLevel;
  final DateTime createdAt;

  // ── Personal info ─────────────────────────────────────────────────────────
  final String? birthDate; // "15 mars 1990"
  final String? birthPlace; // "Conakry, Guinée"
  final String? gender; // "Féminin" | "Masculin" | "Non précisé"
  final String? profession; // "Ingénieure en télécommunications"
  final String? employer; // "Orange Guinée S.A."
  final String? city; // "Conakry"
  final String? commune; // "Ratoma"
  final String? neighborhood; // "Bambéto"

  // ── Identity document ─────────────────────────────────────────────────────
  final String? nationality; // "Guinéenne"
  final String? idCountry; // "Guinée"
  final String? idType; // "Carte Nationale d'Identité"
  final String? idNumber; // "GN202456789012"
  final String? idIssueDate; // "12 juin 2020"
  final DateTime? idExpiryDate; // "11 juin 2027"
  final DateTime? idVerifiedAt; // "08 janvier 2024"

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.avatarUrl, // Rendre optionnel
    required this.balance,
    required this.savingsBalance,
    required this.accountNumber,
    required this.isVerified,
    required this.kycLevel,
    required this.createdAt,
    this.birthDate,
    this.birthPlace,
    this.gender,
    this.profession,
    this.employer,
    this.city,
    this.commune,
    this.neighborhood,
    this.nationality,
    this.idCountry,
    this.idType,
    this.idNumber,
    this.idIssueDate,
    this.idExpiryDate,
    this.idVerifiedAt,
  });

  String get fullName => '$firstName $lastName';

  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  // Convertir UserModel en JSON pour la sauvegarde
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'balance': balance,
      'savings_balance': savingsBalance,
      'account_number': accountNumber,
      'is_verified': isVerified,
      'kyc_level': kycLevel,
      'created_at': createdAt.toIso8601String(),
      'birth_date': birthDate,
      'birth_place': birthPlace,
      'gender': gender,
      'profession': profession,
      'employer': employer,
      'city': city,
      'commune': commune,
      'neighborhood': neighborhood,
      'nationality': nationality,
      'id_country': idCountry,
      'id_type': idType,
      'id_number': idNumber,
      'id_issue_date': idIssueDate,
      'id_expiry_date': idExpiryDate?.toIso8601String(),
      'id_verified_at': idVerifiedAt?.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      savingsBalance:
          double.tryParse(json['savingsBalance']?.toString() ?? '0') ?? 0.0,
      accountNumber: json['accountNumber'] ?? '',
      isVerified: json['isVerified'] ?? false,
      kycLevel: json['kycLevel'] ?? 'none',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      birthDate: json['birthDate'],
      birthPlace: json['birthPlace'],
      gender: json['gender'],
      profession: json['profession'],
      employer: json['employer'],
      city: json['city'],
      commune: json['commune'],
      neighborhood: json['neighborhood'],
      nationality: json['nationality'],
      idCountry: json['idCountry'],
      idType: json['idType'],
      idNumber: json['idNumber'],
      idIssueDate: json['idIssueDate'],
      idExpiryDate: json['idExpiryDate'] != null
          ? DateTime.tryParse(json['idExpiryDate'].toString())
          : null,
      idVerifiedAt: json['idVerifiedAt'] != null
          ? DateTime.tryParse(json['idVerifiedAt'].toString())
          : null,
    );
  }

  UserModel copyWith({
    double? balance,
    double? savingsBalance,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? birthDate,
    String? birthPlace,
    String? gender,
    String? profession,
    String? employer,
    String? city,
    String? commune,
    String? neighborhood,
    String? nationality,
    String? idCountry,
    String? idType,
    String? idNumber,
    String? idIssueDate,
    DateTime? idExpiryDate,
    DateTime? idVerifiedAt,
    bool? isVerified,
    String? kycLevel,
  }) {
    return UserModel(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl,
      balance: balance ?? this.balance,
      savingsBalance: savingsBalance ?? this.savingsBalance,
      accountNumber: accountNumber,
      isVerified: isVerified ?? this.isVerified,
      kycLevel: kycLevel ?? this.kycLevel,
      createdAt: createdAt,
      birthDate: birthDate ?? this.birthDate,
      birthPlace: birthPlace ?? this.birthPlace,
      gender: gender ?? this.gender,
      profession: profession ?? this.profession,
      employer: employer ?? this.employer,
      city: city ?? this.city,
      commune: commune ?? this.commune,
      neighborhood: neighborhood ?? this.neighborhood,
      nationality: nationality ?? this.nationality,
      idCountry: idCountry ?? this.idCountry,
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      idIssueDate: idIssueDate ?? this.idIssueDate,
      idExpiryDate: idExpiryDate ?? this.idExpiryDate,
      idVerifiedAt: idVerifiedAt ?? this.idVerifiedAt,
    );
  }
}
