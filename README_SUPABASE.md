# Fintech B2B - Intégration Supabase

## Vue d'ensemble

Ce projet a été transformé pour utiliser Supabase comme backend, remplaçant les données mock par une base de données dynamique hébergée sur Docker.

## Architecture

### Structure des services

1. **DatabaseService** - Service de données principal (remplace MockData)
2. **AuthService** - Service d'authentification
3. **SupabaseService** - Service d'intégration Supabase (préparé)

### Base de données

La base de données Supabase contient les tables suivantes :

- `users` - Informations utilisateur
- `transactions` - Historique des transactions
- `cards` - Cartes bancaires
- `services` - Services de paiement
- `operators` - Opérateurs téléphoniques
- `payment_methods` - Méthodes de paiement
- `contacts` - Contacts utilisateur
- `notifications` - Notifications système

## Installation et Configuration

### 1. Prérequis

- Docker et Docker Compose
- Flutter SDK
- Node.js (pour les fonctions Supabase)

### 2. Configuration de l'environnement

Copiez le fichier d'environnement :
```bash
cp .env.example .env
```

Modifiez les valeurs dans `.env` selon votre configuration.

### 3. Démarrage de Supabase

```bash
# Démarrer tous les services Supabase
docker-compose up -d

# Vérifier l'état des services
docker-compose ps
```

Les services seront disponibles sur :
- **Studio** : http://localhost:3000
- **API REST** : http://localhost:8000
- **Auth** : http://localhost:9999
- **Storage** : http://localhost:5000
- **Realtime** : http://localhost:4000
- **Functions** : http://localhost:9000

### 4. Installation des dépendances Flutter

```bash
flutter pub get
```

### 5. Exécution de l'application

```bash
flutter run
```

## Migration depuis MockData

### Écrans mis à jour

Les écrans suivants ont été migrés pour utiliser DatabaseService :

- **AirtimeScreen** - Utilise `DatabaseService.to.operators`
- **DepositScreen** - Utilise `DatabaseService.to.paymentMethods`
- **TopupScreen** - Utilise `DatabaseService.to.paymentMethods`
- **ServicesScreen** - Utilise `DatabaseService.to.services`
- **TransferScreen** - Utilise `DatabaseService.to.contacts`
- **LoginScreen** - Utilise `AuthService.to.signIn()`

### Remplacement des imports

Avant :
```dart
import '../../data/mock/mock_data.dart';
// Utilisation : MockData.operators
```

Après :
```dart
import '../../services/database_service.dart';
// Utilisation : DatabaseService.to.operators
```

## Authentification

### Login dynamique

L'écran de login utilise maintenant `AuthService` avec validation :

```dart
final success = await authService.signIn(phone, password);
if (success) {
  // Navigation vers dashboard
} else {
  // Afficher erreur
}
```

### Identifiants de démo

Pour tester l'application :
- **Téléphone** : `621234567`
- **Mot de passe** : `password`

## Services de données

### DatabaseService

Service principal qui gère toutes les données de l'application :

```dart
// Obtenir l'utilisateur courant
final user = DatabaseService.to.currentUser.value;

// Ajouter une transaction
await DatabaseService.to.addTransaction(transaction);

// Obtenir les transactions
final transactions = await DatabaseService.to.getTransactions();

// Ajouter un contact
await DatabaseService.to.addContact(contact);
```

### AuthService

Gère l'authentification des utilisateurs :

```dart
// Connexion
final success = await AuthService.to.signIn(phone, password);

// Inscription
final success = await AuthService.to.signUp(
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
  phone: '621234567',
  password: 'password',
);

// Déconnexion
await AuthService.to.signOut();

// Vérifier le statut
final isLoggedIn = AuthService.to.isLoggedIn.value;
```

## Structure de la base de données

### Table users

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    balance DECIMAL(15,2) DEFAULT 0.00,
    savings_balance DECIMAL(15,2) DEFAULT 0.00,
    account_number VARCHAR(20) UNIQUE NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    kyc_level VARCHAR(20) DEFAULT 'basic',
    -- Champs KYC
    birth_date DATE,
    birth_place VARCHAR(255),
    gender VARCHAR(20),
    profession VARCHAR(255),
    employer VARCHAR(255),
    city VARCHAR(100),
    commune VARCHAR(100),
    neighborhood VARCHAR(100),
    -- Document d'identité
    nationality VARCHAR(100),
    id_country VARCHAR(100),
    id_type VARCHAR(100),
    id_number VARCHAR(100),
    id_issue_date DATE,
    id_expiry_date DATE,
    id_verified_at TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Table transactions

```sql
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL CHECK (type IN ('deposit', 'withdrawal', 'transfer', 'payment', 'topup', 'airtime', 'service')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
    amount DECIMAL(15,2) NOT NULL,
    description TEXT NOT NULL,
    recipient VARCHAR(255),
    recipient_avatar TEXT,
    reference VARCHAR(100) UNIQUE,
    category VARCHAR(100),
    is_credit BOOLEAN NOT NULL,
    date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Fonctionnalités CRUD

### Contacts

L'écran des contacts inclut :

- **Ajout** : Formulaire avec nom et téléphone
- **Modification** : Mise à jour des informations existantes
- **Suppression** : Confirmation avant suppression
- **Recherche** : Filtrage en temps réel
- **Favoris** : Marquage des contacts favoris

### Transactions

Les transactions sont créées automatiquement lors des actions utilisateurs :

```dart
// Créer une transaction
final transaction = TransactionModel(
  id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
  type: TransactionType.transfer,
  status: TransactionStatus.completed,
  amount: 150000.00,
  description: 'Transfert à Alpha Diallo',
  recipient: 'Alpha Diallo',
  date: DateTime.now(),
  reference: appController.generateReference('TRF'),
  isCredit: false,
);

await DatabaseService.to.addTransaction(transaction);
```

## Sécurité

### Row Level Security (RLS)

Toutes les tables utilisent RLS pour garantir que les utilisateurs ne voient que leurs propres données :

```sql
-- Politique pour les transactions
CREATE POLICY "Users can view own transactions" ON transactions
    FOR SELECT USING (auth.uid()::text = user_id::text);

-- Politique pour les utilisateurs
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid()::text = id::text);
```

### Validation des données

Le service `AuthService` inclut des validateurs :

```dart
String? validatePhone(String? value) {
  if (value == null || value.isEmpty) return 'Le numéro est requis';
  if (value.length < 9) return 'Minimum 9 chiffres';
  if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Chiffres uniquement';
  return null;
}
```

## Déploiement

### Production

Pour déployer en production :

1. **Configurer les variables d'environnement**
2. **Activer SSL sur Supabase**
3. **Configurer les backups automatiques**
4. **Mettre à jour les clés API**
5. **Activer les webhooks pour les notifications**

### Monitoring

- Utiliser Supabase Dashboard pour surveiller les performances
- Configurer des alertes pour les erreurs
- Surveiller l'utilisation de la base de données

## Développement continu

### Ajout de nouvelles fonctionnalités

1. **Créer la table SQL** dans `supabase/migrations/`
2. **Ajouter les méthodes** dans `DatabaseService`
3. **Mettre à jour les modèles** si nécessaire
4. **Intégrer dans les écrans**

### Tests

```bash
# Tests unitaires
flutter test

# Tests d'intégration
flutter test integration/
```

## Support

Pour toute question sur l'intégration Supabase :

1. Consulter la documentation Supabase : https://supabase.com/docs
2. Vérifier les logs Docker : `docker-compose logs`
3. Utiliser Supabase Studio : http://localhost:3000

## Prochaines étapes

- [ ] Intégration complète de Supabase Auth
- [ ] Mise en place des webhooks
- [ ] Notifications push via Supabase Realtime
- [ ] Upload de fichiers via Supabase Storage
- [ ] Fonctions edge pour les traitements complexes
