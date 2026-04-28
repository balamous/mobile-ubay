# UBAY - Application de Transfert d'Argent

Application mobile de transfert d'argent (B2B & P2P) avec backend Node.js et base de données PostgreSQL.

## Architecture

- **Frontend** : Flutter avec GetX pour la state management
- **Backend** : Node.js + Express
- **Base de données** : PostgreSQL
- **WebSocket** : Notifications temps réel
- **Docker** : Conteneurisation complète

---

## Prérequis

- [Docker](https://docs.docker.com/get-docker/) (avec Docker Compose)
- [Flutter](https://docs.flutter.dev/get-started/install) SDK 3.0+
- [Android Studio](https://developer.android.com/studio) ou [Xcode](https://developer.apple.com/xcode/) (pour iOS)
- Node.js 18+ (optionnel, pour développement local sans Docker)

---

## Installation du Backend

### 1. Cloner le repository

```bash
git clone https://github.com/balamous/mobile-ubay.git
cd mobile-ubay
```

### 2. Lancer avec Docker

```bash
# Démarrer tous les services (PostgreSQL + API + WebSocket)
docker-compose up -d

# Vérifier que les conteneurs sont bien lancés
docker-compose ps
```

### 3. Vérifier l'installation

Le backend est accessible sur :
- API REST : `http://localhost:3000`
- WebSocket : `ws://localhost:3000`

Testez l'API :
```bash
curl http://localhost:3000/api/health
```

### 4. Gestion des conteneurs

```bash
# Redémarrer le backend
docker-compose restart ubay-api

# Voir les logs
docker-compose logs -f ubay-api

# Arrêter les services
docker-compose down

# Reset complet (supprime les données)
docker-compose down -v
```

---

## Installation de l'Application Flutter

### 1. Installer les dépendances

```bash
cd lib/..
flutter pub get
```

### 2. Configuration des URLs

L'application utilise automatiquement les bonnes URLs selon la plateforme :
- **Android** : `http://10.0.2.2:3000` (émulateur)
- **iOS** : `http://localhost:3000` (simulateur)
- **Web** : `http://localhost:3000`

Si vous utilisez un appareil physique, modifiez les URLs dans :
- `lib/services/api_service.dart`
- `lib/services/contact_service.dart`
- `lib/services/scheduled_transfer_service.dart`

### 3. Lancer l'application

```bash
# Vérifier la configuration Flutter
flutter doctor

# Lancer sur Android
cd /Users/macbookpro16/fintech-b2b
flutter run

# Lancer sur iOS (Mac uniquement)
cd /Users/macbookpro16/fintech-b2b
flutter run -d ios

# Lancer sur Web
cd /Users/macbookpro16/fintech-b2b
flutter run -d chrome

# Mode release
flutter run --release
```

### 4. Build pour production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## Structure du Projet

```
fintech-b2b/
├── api/                          # Backend Node.js
│   ├── server-simple.js          # Serveur principal Express
│   └── package.json
├── lib/                          # Application Flutter
│   ├── main.dart                 # Point d'entrée
│   ├── core/                     # Constantes et utils
│   │   ├── constants/
│   │   └── utils/
│   ├── data/                     # Modèles et repositories
│   │   └── models/
│   ├── modules/                  # Écrans de l'application
│   │   ├── auth/                 # Login, Register, 2FA
│   │   ├── dashboard/            # Tableau de bord
│   │   ├── transfer/             # Transferts et prélèvements
│   │   ├── history/              # Historique
│   │   └── settings/             # Paramètres
│   ├── routes/                   # Routes GetX
│   ├── services/                 # Services métier
│   │   ├── app_controller.dart
│   │   ├── contact_service.dart
│   │   ├── scheduled_transfer_service.dart
│   │   └── websocket_service.dart
│   └── widgets/                  # Composants réutilisables
├── docker-compose.yml            # Configuration Docker
└── README.md
```

---

## Principales API Endpoints

### Authentification
- `POST /api/register` - Inscription
- `POST /api/login` - Connexion
- `POST /api/verify-2fa` - Vérification 2FA
- `POST /api/setup-2fa` - Configuration 2FA

### Transferts
- `POST /api/transfer` - Effectuer un transfert
- `GET /api/transactions/:userId` - Historique des transactions
- `POST /api/deposit` - Déposer de l'argent

### Prélèvements Automatiques
- `POST /api/scheduled-transfers` - Créer un prélèvement
- `GET /api/scheduled-transfers/:userId` - Liste des prélèvements
- `PATCH /api/scheduled-transfers/:id` - Modifier statut
- `DELETE /api/scheduled-transfers/:id` - Supprimer

### Contacts
- `POST /api/contacts` - Ajouter un contact
- `GET /api/contacts/:userId` - Liste des contacts

---

## Fonctionnalités

- Transferts P2P (peer-to-peer)
- Prélèvements automatiques programmés
- Authentification biométrique (empreinte/face ID)
- Authentification à deux facteurs (2FA)
- Notifications temps réel via WebSocket
- Gestion des contacts favoris
- Historique complet des transactions

---

## Dépannage

### Problème de connexion à l'API
1. Vérifier que Docker est bien lancé : `docker-compose ps`
2. Vérifier les logs : `docker-compose logs ubay-api`
3. Sur Android émulateur, utiliser `10.0.2.2` au lieu de `localhost`

### Hot reload ne fonctionne pas
```bash
flutter clean
flutter pub get
flutter run
```

### Erreur "Connection refused"
- Vérifier que le backend écoute sur `0.0.0.0:3000`
- Sur appareil physique, remplacer `localhost` par l'IP de votre machine

---

## Technologies Utilisées

| Couche | Technologie |
|--------|-------------|
| Frontend | Flutter, Dart |
| State Management | GetX |
| Backend | Node.js, Express |
| Database | PostgreSQL |
| WebSocket | ws (Node.js) |
| UI | Material Design, Animate |

---

## Licence

Projet privé - Tous droits réservés.
