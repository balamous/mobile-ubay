import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/card_model.dart';
import '../models/service_model.dart';

class MockData {
  // ─── User — Guinéen ───────────────────────────────────────────────────────// User Data - Now retrieved from PostgreSQL database
  static UserModel? currentUser;

  // ─── Transactions — contexte guinéen ─────────────────────────────────────
  static final List<TransactionModel> transactions = [
    TransactionModel(
      id: 'txn_001',
      type: TransactionType.deposit,
      status: TransactionStatus.completed,
      amount: 5000000,
      description: 'Dépôt via Orange Money Guinée',
      recipient: 'Orange Money GN',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      reference: 'OM-20240108-001',
      category: 'Dépôt',
      isCredit: true,
    ),
    TransactionModel(
      id: 'txn_002',
      type: TransactionType.transfer,
      status: TransactionStatus.completed,
      amount: 2000000,
      description: 'Transfert vers Mamadou Bah',
      recipient: 'Mamadou Bah',
      date: DateTime.now().subtract(const Duration(hours: 5)),
      reference: 'TRF-20240108-002',
      category: 'Transfert',
      isCredit: false,
    ),
    TransactionModel(
      id: 'txn_003',
      type: TransactionType.payment,
      status: TransactionStatus.completed,
      amount: 450000,
      description: 'Facture EDG - Électricité janvier',
      recipient: 'EDG',
      date: DateTime.now().subtract(const Duration(days: 1)),
      reference: 'PAY-20240107-003',
      category: 'Électricité',
      isCredit: false,
    ),
    TransactionModel(
      id: 'txn_004',
      type: TransactionType.airtime,
      status: TransactionStatus.completed,
      amount: 50000,
      description: 'Crédit Orange — 622 13 45 67',
      recipient: 'Orange GN',
      date: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      reference: 'AIR-20240107-004',
      category: 'Crédit tél.',
      isCredit: false,
    ),
    TransactionModel(
      id: 'txn_005',
      type: TransactionType.withdrawal,
      status: TransactionStatus.completed,
      amount: 3000000,
      description: 'Retrait espèces — Agence Kaloum',
      date: DateTime.now().subtract(const Duration(days: 2)),
      reference: 'WDR-20240106-005',
      category: 'Retrait',
      isCredit: false,
    ),
    TransactionModel(
      id: 'txn_006',
      type: TransactionType.service,
      status: TransactionStatus.completed,
      amount: 200000,
      description: 'Abonnement Canal+ Guinée',
      recipient: 'Canal+',
      date: DateTime.now().subtract(const Duration(days: 3)),
      reference: 'SVC-20240105-006',
      category: 'TV',
      isCredit: false,
    ),
    TransactionModel(
      id: 'txn_007',
      type: TransactionType.deposit,
      status: TransactionStatus.completed,
      amount: 10000000,
      description: 'Virement entrant — Ecobank Guinée',
      recipient: 'Ecobank GN',
      date: DateTime.now().subtract(const Duration(days: 4)),
      reference: 'DEP-20240104-007',
      category: 'Dépôt',
      isCredit: true,
    ),
    TransactionModel(
      id: 'txn_008',
      type: TransactionType.payment,
      status: TransactionStatus.pending,
      amount: 180000,
      description: 'Facture SEG — Eau janvier',
      recipient: 'SEG',
      date: DateTime.now().subtract(const Duration(days: 5)),
      reference: 'PAY-20240103-008',
      category: 'Eau',
      isCredit: false,
    ),
    TransactionModel(
      id: 'txn_009',
      type: TransactionType.transfer,
      status: TransactionStatus.failed,
      amount: 4000000,
      description: 'Transfert vers Alpha Diallo',
      recipient: 'Alpha Diallo',
      date: DateTime.now().subtract(const Duration(days: 5, hours: 6)),
      reference: 'TRF-20240103-009',
      category: 'Transfert',
      isCredit: false,
    ),
    TransactionModel(
      id: 'txn_010',
      type: TransactionType.topup,
      status: TransactionStatus.completed,
      amount: 1000000,
      description: 'Recharge portefeuille MTN MoMo',
      recipient: 'MTN MoMo',
      date: DateTime.now().subtract(const Duration(days: 6)),
      reference: 'TOP-20240102-010',
      category: 'Recharge',
      isCredit: true,
    ),
  ];

  // ─── Cards ────────────────────────────────────────────────────────────────
  static final List<CardModel> cards = [
    CardModel(
      id: 'card_001',
      cardNumber: '4532015112830366',
      cardHolder: 'FATOUMATA CAMARA',
      expiryMonth: '09',
      expiryYear: '28',
      cvv: '742',
      type: CardType.visa,
      status: CardStatus.active,
      limit: 50000000,
      spent: 12500000,
      isVirtual: true,
    ),
    CardModel(
      id: 'card_002',
      cardNumber: '5425233430109903',
      cardHolder: 'FATOUMATA CAMARA',
      expiryMonth: '12',
      expiryYear: '26',
      cvv: '318',
      type: CardType.mastercard,
      status: CardStatus.active,
      limit: 20000000,
      spent: 4500000,
      isVirtual: false,
    ),
  ];

  // ─── Services — contexte guinéen ──────────────────────────────────────────
  static final List<ServiceModel> services = [
    ServiceModel(
      id: 'svc_001',
      name: 'EDG',
      description: 'Électricité de Guinée',
      iconPath: 'electricity',
      category: ServiceCategory.utilities,
      isPopular: true,
      color: '#F59E0B',
    ),
    ServiceModel(
      id: 'svc_002',
      name: 'SEG',
      description: 'Société des Eaux de Guinée',
      iconPath: 'water',
      category: ServiceCategory.utilities,
      isPopular: true,
      color: '#06B6D4',
    ),
    ServiceModel(
      id: 'svc_003',
      name: 'Orange Guinée',
      description: 'Internet & téléphonie Orange',
      iconPath: 'internet',
      category: ServiceCategory.internet,
      isPopular: true,
      color: '#FF8C00',
    ),
    ServiceModel(
      id: 'svc_004',
      name: 'MTN Guinée',
      description: 'Internet & téléphonie MTN',
      iconPath: 'internet',
      category: ServiceCategory.internet,
      isPopular: true,
      color: '#FFC107',
    ),
    ServiceModel(
      id: 'svc_005',
      name: 'Canal+',
      description: 'Abonnement TV satellite',
      iconPath: 'tv',
      category: ServiceCategory.tv,
      isPopular: true,
      fixedAmount: 200000,
      color: '#1E1B4B',
    ),
    ServiceModel(
      id: 'svc_006',
      name: 'Sotelgui',
      description: 'Téléphonie fixe & internet',
      iconPath: 'internet',
      category: ServiceCategory.internet,
      isPopular: false,
      color: '#059669',
    ),
    ServiceModel(
      id: 'svc_008',
      name: 'Netflix',
      description: 'Streaming vidéo',
      iconPath: 'streaming',
      category: ServiceCategory.streaming,
      isPopular: false,
      fixedAmount: 220000,
      color: '#E50914',
    ),
  ];

  // ─── Operators Airtime — Guinée ───────────────────────────────────────────
  static final List<OperatorModel> operators = [
    OperatorModel(
      id: 'op_001',
      name: 'Orange',
      logoPath: 'assets/images/orange.png',
      color: '#FF8C00',
      amounts: [5000, 10000, 20000, 50000, 100000],
    ),
    OperatorModel(
      id: 'op_002',
      name: 'MTN',
      logoPath: 'assets/images/mtn.jpeg',
      color: '#FFC107',
      amounts: [5000, 10000, 20000, 50000, 100000],
    ),
  ];

  // ─── Contacts — noms guinéens ─────────────────────────────────────────────
  static final List<Map<String, String>> contacts = [
    {'name': 'Mamadou Bah', 'phone': '621234567', 'initials': 'MB'},
    {'name': 'Alpha Diallo', 'phone': 'ABD634567', 'initials': 'AD'},
    {'name': 'Mariama Sow', 'phone': '661234567', 'initials': 'MS'},
    {'name': 'Ibrahima Kouyaté', 'phone': '628234567', 'initials': 'IK'},
    {'name': 'Kadiatou Barry', 'phone': 'K621234568', 'initials': 'KB'},
    {'name': 'Boubacar Baldé', 'phone': '655234568', 'initials': 'BB'},
  ];

  // ─── Payment Methods — Guinée ─────────────────────────────────────────────
  static final List<Map<String, String>> paymentMethods = [
    {
      'id': 'pm_001',
      'name': 'Orange Money',
      'logoPath': 'assets/images/orange.png',
      'color': '#FF8C00'
    },
    {
      'id': 'pm_002',
      'name': 'MTN MoMo',
      'logoPath': 'assets/images/momo.jpeg',
      'color': '#FFC107'
    },
  ];

  // ─── Banques locales Guinée ───────────────────────────────────────────────
  static final List<Map<String, String>> localBanks = [
    {
      'id': 'bk_001',
      'name': 'Ecobank Guinée',
      'code': 'ECO-GN',
      'color': '#003087'
    },
    {'id': 'bk_002', 'name': 'BICIGUI', 'code': 'BICI-GN', 'color': '#006600'},
    {
      'id': 'bk_003',
      'name': 'BSIC Guinée',
      'code': 'BSIC-GN',
      'color': '#C8102E'
    },
    {
      'id': 'bk_004',
      'name': 'UBA Guinée',
      'code': 'UBA-GN',
      'color': '#CC0000'
    },
    {
      'id': 'bk_005',
      'name': 'Banque Islamique GN',
      'code': 'BIG-GN',
      'color': '#006400'
    },
    {
      'id': 'bk_006',
      'name': 'Coris Bank GN',
      'code': 'COB-GN',
      'color': '#F07C00'
    },
  ];

  // ─── Frais carte ──────────────────────────────────────────────────────────
  static const Map<String, double> cardFees = {
    'virtual_visa': 50000,
    'virtual_mastercard': 50000,
    'physical_visa': 150000,
    'physical_mastercard': 150000,
  };
}
