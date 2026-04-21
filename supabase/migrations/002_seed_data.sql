-- ========================================
-- Fintech B2B - Seed Data
-- ========================================

-- ========================================
-- OPERATORS
-- ========================================
INSERT INTO operators (id, name, logo_path, color, is_active) VALUES
('op_001', 'Orange', 'assets/images/orange.png', '#FF8C00', true),
('op_002', 'MTN', 'assets/images/momo.jpeg', '#FFC107', true)
ON CONFLICT (id) DO NOTHING;

-- ========================================
-- OPERATOR_AMOUNTS
-- ========================================
INSERT INTO operator_amounts (id, operator_id, amount) VALUES
-- Orange amounts
('oa_001', 'op_001', 5000),
('oa_002', 'op_001', 10000),
('oa_003', 'op_001', 20000),
('oa_004', 'op_001', 50000),
('oa_005', 'op_001', 100000),
-- MTN amounts
('oa_006', 'op_002', 5000),
('oa_007', 'op_002', 10000),
('oa_008', 'op_002', 20000),
('oa_009', 'op_002', 50000),
('oa_010', 'op_002', 100000)
ON CONFLICT (id) DO NOTHING;

-- ========================================
-- PAYMENT_METHODS
-- ========================================
INSERT INTO payment_methods (id, name, logo_path, color, is_active) VALUES
('pm_001', 'Orange Money', 'assets/images/orange.png', '#FF8C00', true),
('pm_002', 'MTN MoMo', 'assets/images/momo.jpeg', '#FFC107', true)
ON CONFLICT (id) DO NOTHING;

-- ========================================
-- SERVICES
-- ========================================
INSERT INTO services (id, name, category, color, icon_path, is_popular, fixed_amount) VALUES
-- Utilities
('svc_001', 'EDG - Électricité', 'utilities', '#1A56DB', 'electricity', true, 220000),
('svc_002', 'SEG - Eau', 'utilities', '#0891B2', 'water', true, 15000),
-- Internet
('svc_003', 'Orange Fibre', 'internet', '#FF8C00', 'internet', true, 95000),
('svc_004', 'MTN 4G+', 'internet', '#FFC107', 'internet', false, 75000),
-- TV
('svc_005', 'Orange TV', 'tv', '#FF8C00', 'tv', true, 45000),
('svc_006', 'Canal+', 'tv', '#E50914', 'tv', true, 65000),
-- Streaming
('svc_007', 'Netflix', 'streaming', '#E50914', 'streaming', true, 35000),
('svc_008', 'Disney+', 'streaming', '#113CCF', 'streaming', false, 28000)
ON CONFLICT (id) DO NOTHING;

-- ========================================
-- SAMPLE USER (for testing)
-- ========================================
INSERT INTO users (
    id,
    email,
    phone,
    first_name,
    last_name,
    avatar_url,
    balance,
    savings_balance,
    account_number,
    is_verified,
    kyc_level,
    birth_date,
    birth_place,
    gender,
    profession,
    employer,
    city,
    commune,
    neighborhood,
    nationality,
    id_country,
    id_type,
    id_number,
    id_issue_date,
    id_expiry_date,
    id_verified_at
) VALUES (
    'user_001',
    'mamadou.bah@fintech.com',
    '621234567',
    'Mamadou',
    'Bah',
    'https://ui-avatars.com/api/?name=Mamadou+Bah&background=7C3AED&color=fff',
    850000.00,
    250000.00,
    'GN202456789012',
    true,
    'full',
    '1990-03-15',
    'Conakry, Guinée',
    'male',
    'Ingénieur en télécommunications',
    'Orange Guinée S.A.',
    'Conakry',
    'Ratoma',
    'Bambéto',
    'Guinéenne',
    'Guinée',
    'Carte Nationale d''Identité',
    'GN202456789012',
    '2020-06-12',
    '2027-06-11',
    '2024-01-08'
) ON CONFLICT (id) DO NOTHING;

-- ========================================
-- SAMPLE CARDS
-- ========================================
INSERT INTO cards (
    id,
    user_id,
    card_number,
    card_holder,
    expiry_month,
    expiry_year,
    cvv,
    card_type,
    is_default,
    is_active,
    balance,
    limit_amount
) VALUES 
('card_001', 'user_001', '4532 1234 5678 9012', 'Mamadou Bah', 12, 2025, '123', 'visa', true, true, 500000.00, 2000000.00),
('card_002', 'user_001', '5212 3456 7890 1234', 'Mamadou Bah', 9, 2024, '456', 'mastercard', false, true, 250000.00, 1500000.00)
ON CONFLICT (id) DO NOTHING;

-- ========================================
-- SAMPLE TRANSACTIONS
-- ========================================
INSERT INTO transactions (
    id,
    user_id,
    type,
    status,
    amount,
    description,
    recipient,
    recipient_avatar,
    reference,
    category,
    is_credit,
    date,
    payment_method,
    operator_name,
    phone_number
) VALUES 
-- Recent transactions
('txn_001', 'user_001', 'transfer', 'completed', 150000.00, 'Transfert à Alpha Diallo', 'Alpha Diallo', 'https://ui-avatars.com/api/?name=Alpha+Diallo&background=FF8C00&color=fff', 'TRF202401001', 'Transfert', false, '2024-01-15 10:30:00', NULL, NULL, NULL),
('txn_002', 'user_001', 'airtime', 'completed', 10000.00, 'Crédit Orange - 621234567', 'Orange', 'assets/images/orange.png', 'AIR202401002', 'Crédit tél.', false, '2024-01-15 09:15:00', NULL, 'Orange', '621234567'),
('txn_003', 'user_001', 'deposit', 'completed', 500000.00, 'Dépôt via Orange Money', 'Orange Money', 'assets/images/orange.png', 'DEP202401003', 'Dépôt', true, '2024-01-14 16:45:00', 'Orange Money', NULL, NULL),
('txn_004', 'user_001', 'service', 'completed', 220000.00, 'Paiement EDG - Électricité', 'EDG - Électricité', NULL, 'SVC202401004', 'Service', false, '2024-01-14 14:20:00', NULL, NULL, NULL),
('txn_005', 'user_001', 'payment', 'completed', 45000.00, 'Abonnement Orange TV', 'Orange TV', 'assets/images/orange.png', 'PAY202401005', 'Paiement', false, '2024-01-13 11:30:00', NULL, NULL, NULL),

-- Older transactions
('txn_006', 'user_001', 'topup', 'completed', 250000.00, 'Recharge wallet', 'MTN MoMo', 'assets/images/momo.jpeg', 'TOP202401006', 'Recharge', true, '2024-01-12 10:00:00', 'MTN MoMo', NULL, NULL),
('txn_007', 'user_001', 'withdrawal', 'completed', 100000.00, 'Retrait agence', 'Agence Bambéto', NULL, 'WTH202401007', 'Retrait', false, '2024-01-11 15:30:00', NULL, NULL, NULL),
('txn_008', 'user_001', 'transfer', 'completed', 75000.00, 'Transfert à Mariama Sow', 'Mariama Sow', 'https://ui-avatars.com/api/?name=Mariama+Sow&background=0891B2&color=fff', 'TRF202401008', 'Transfert', false, '2024-01-10 12:15:00', NULL, NULL, NULL),
('txn_009', 'user_001', 'airtime', 'completed', 5000.00, 'Crédit MTN - 661234567', 'MTN', 'assets/images/momo.jpeg', 'AIR202401009', 'Crédit tél.', false, '2024-01-09 18:45:00', NULL, 'MTN', '661234567'),
('txn_010', 'user_001', 'service', 'completed', 35000.00, 'Netflix Premium', 'Netflix', NULL, 'SVC202401010', 'Service', false, '2024-01-08 20:00:00', NULL, NULL, NULL)
ON CONFLICT (id) DO NOTHING;

-- ========================================
-- SAMPLE CONTACTS
-- ========================================
INSERT INTO contacts (
    id,
    user_id,
    name,
    phone,
    initials,
    is_favorite
) VALUES 
('cnt_001', 'user_001', 'Mamadou Bah', '621234567', 'MB', true),
('cnt_002', 'user_001', 'Alpha Diallo', 'ABD634567', 'AD', false),
('cnt_003', 'user_001', 'Mariama Sow', '661234567', 'MS', true),
('cnt_004', 'user_001', 'Ibrahima Kouyaté', '628234567', 'IK', false),
('cnt_005', 'user_001', 'Kadiatou Barry', 'K621234568', 'KB', false),
('cnt_006', 'user_001', 'Boubacar Baldé', '655234568', 'BB', true)
ON CONFLICT (id) DO NOTHING;

-- ========================================
-- SAMPLE NOTIFICATIONS
-- ========================================
INSERT INTO notifications (
    id,
    user_id,
    title,
    message,
    type,
    is_read,
    data
) VALUES 
('not_001', 'user_001', 'Transfert réussi', 'Votre transfert de 150 000 GNF à Alpha Diallo a été effectué avec succès.', 'transaction', false, '{"reference": "TRF202401001", "amount": 150000}'),
('not_002', 'user_001', 'Solde faible', 'Votre solde est inférieur à 100 000 GNF. Veuillez recharger votre compte.', 'system', false, '{"balance": 850000}'),
('not_003', 'user_001', 'Paiement reçu', 'Vous avez reçu 500 000 GNF de la part de Orange Money.', 'transaction', true, '{"amount": 500000, "sender": "Orange Money"}'),
('not_004', 'user_001', 'Promotion spéciale', 'Bénéficiez de -20% sur tous les transferts cette semaine !', 'promo', true, '{"discount": 20, "valid_until": "2024-01-31"}'),
('not_005', 'user_001', 'Connexion sécurisée', 'Une nouvelle connexion a été détectée sur votre compte.', 'security', false, '{"ip": "192.168.1.1", "device": "iPhone 14 Pro"}')
ON CONFLICT (id) DO NOTHING;
