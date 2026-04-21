# Docker - Guide de Dépannage

## Problèmes Courants et Solutions

### ❌ Erreur: "failed to resolve reference"

**Problème :**
```
Error response from daemon: failed to resolve reference "docker.io/supabase/edge-runtime:v1.45.3": not found
```

**Causes possibles :**
1. **Problème de connexion Internet**
2. **Registry Docker inaccessible**
3. **Version d'image incorrecte**
4. **Problème de DNS**

**Solutions :**

#### Solution 1: Utiliser les images locales
```bash
# Télécharger les images manuellement
docker pull supabase/postgres:15.1.0.117
docker pull supabase/gotrue:v2.91.0
docker pull supabase/studio:20240109-a4b3c1e
docker pull supabase/postgrest:v12.0.1
docker pull supabase/storage-api:v0.48.4
docker pull supabase/realtime:v2.25.73
```

#### Solution 2: Modifier docker-compose.yml
```yaml
# Remplacer les images par les versions spécifiques
services:
  db:
    image: supabase/postgres:15.1.0.117  # Version spécifique
  auth:
    image: supabase/gotrue:v2.91.0          # Version spécifique
  studio:
    image: supabase/studio:20240109-a4b3c1e  # Version spécifique
  # ... autres services
```

#### Solution 3: Utiliser un registry miroir
```bash
# Configurer un registry miroir
export DOCKER_REGISTRY_MIRROR=https://mirror.gcr.io
docker-compose up -d
```

#### Solution 4: Forcer la recréation des images
```bash
# Nettoyer et recréer
docker system prune -f
docker-compose down
docker-compose pull --no-cache
docker-compose up -d
```

### ❌ Erreur: "Interrupted"

**Problème :**
```
[+] up 7/7
 ! Image supabase/postgrest:v12.0.1       Interrupted
```

**Solutions :**

#### Solution 1: Vérifier l'espace disque
```bash
# Vérifier l'espace disponible
df -h

# Nettoyer si nécessaire
docker system prune -f
```

#### Solution 2: Augmenter les ressources Docker
```bash
# Augmenter la mémoire Docker
export DOCKER_MEMORY=4g

# Augmenter les limites
docker-compose up -d --scale db=2
```

#### Solution 3: Utiliser Docker Desktop
```bash
# Si Docker Desktop est installé
open -a Docker Desktop

# Ou utiliser Colima pour macOS
colima start
docker-compose up -d
```

### ❌ Erreur: "Port déjà utilisé"

**Problème :**
```
Error: Port 3000 is already allocated
```

**Solutions :**

#### Solution 1: Changer les ports
```yaml
# Modifier docker-compose.yml
services:
  studio:
    ports:
      - '3001:3000'  # Changer le port
  auth:
    ports:
      - '9998:9999'  # Changer le port
```

#### Solution 2: Tuer les processus
```bash
# Trouver les processus utilisant les ports
lsof -i :3000
lsof -i :5432

# Tuer les processus
kill -9 <PID>
```

#### Solution 3: Utiliser un réseau différent
```yaml
# Utiliser un réseau dédié
networks:
  fintech-network:
    driver: bridge

services:
  db:
    networks:
      - fintech-network
```

### ❌ Erreur: "Permission denied"

**Problème :**
```
ERROR: permission denied while trying to connect to the Docker daemon socket
```

**Solutions :**

#### Solution 1: Ajouter l'utilisateur au groupe Docker
```bash
# Sur macOS/Linux
sudo usermod -aG docker
newgrp docker

# Se reconnecter
sudo su - $USER
docker-compose up -d
```

#### Solution 2: Utiliser Docker avec sudo
```bash
# Exécuter avec sudo
sudo docker-compose up -d
```

#### Solution 3: Démarrer Docker Desktop
```bash
# S'assurer que Docker Desktop est en cours d'exécution
docker version
docker-compose up -d
```

### 🚀 Solution Complète pour UBAY-DB

#### Étape 1: Préparation
```bash
# 1. Créer un réseau Docker dédié
docker network create fintech-network

# 2. Nettoyer les anciennes images
docker system prune -f

# 3. Vérifier la configuration
cat docker-compose.yml
```

#### Étape 2: Configuration Locale
```yaml
# docker-compose.local.yml (version pour développement local)
version: '3.8'

services:
  # Utiliser des images locales si problèmes de connexion
  db:
    image: postgres:15-alpine  # Image PostgreSQL simple
    environment:
      POSTGRES_DB: fintech_db
      POSTGRES_USER: fintech_admin
      POSTGRES_PASSWORD: fintech_password_2024
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./supabase/migrations:/docker-entrypoint-initdb.d
    ports:
      - '5432:5432'
```

#### Étape 3: Démarrage Progressif
```bash
# 1. Démarrer seulement la base de données
docker-compose -f docker-compose.local.yml up -d db

# 2. Vérifier que PostgreSQL fonctionne
docker-compose -f docker-compose.local.yml exec db psql -U fintech_admin -d fintech_db -c "SELECT version();"

# 3. Démarrer les autres services un par un
docker-compose up -d auth
# Attendre 30 secondes
docker-compose up -d studio
# Attendre 30 secondes
docker-compose up -d rest
```

### 🔧 Scripts Utiles

#### Script de démarrage avec vérification
```bash
#!/bin/bash

echo "🚀 Démarrage de UBAY-DB..."

# Vérifier si Docker fonctionne
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker n'est pas en cours d'exécution"
    echo "Veuillez démarrer Docker Desktop ou utiliser 'sudo docker-compose up -d'"
    exit 1
fi

# Nettoyer les anciens conteneurs
echo "🧹 Nettoyage des conteneurs précédents..."
docker-compose down 2>/dev/null

# Démarrer les services par ordre de dépendance
echo "📊 Démarrage de la base de données..."
docker-compose up -d db

echo "⏳ Attente de la base de données (30s)..."
sleep 30

echo "🔐 Démarrage de l'authentification..."
docker-compose up -d auth

echo "⏳ Attente de l'authentification (10s)..."
sleep 10

echo "🌐 Démarrage de l'API REST..."
docker-compose up -d rest

echo "🎨 Démarrage de Supabase Studio..."
docker-compose up -d studio

echo "✅ UBAY-DB est maintenant disponible !"
echo ""
echo "📱 Supabase Studio: http://localhost:3000"
echo "🔌 API REST: http://localhost:8000"
echo "🔐 Auth: http://localhost:9999"
echo "💾 Storage: http://localhost:5000"
echo "⚡ Realtime: ws://localhost:4000"
```

#### Script de vérification de santé
```bash
#!/bin/bash

echo "🔍 Vérification de santé de UBAY-DB..."

# Vérifier les conteneurs
echo "📦 Conteneurs actifs :"
docker-compose ps

# Vérifier les ports
echo "🌐 Ports utilisés :"
netstat -tulpn | grep :3000
netstat -tulpn | grep :5432
netstat -tulpn | grep :8000
netstat -tulpn | grep :9999

# Tester la connexion PostgreSQL
echo "🗄️ Test de connexion PostgreSQL :"
docker-compose exec -T db psql -U supabase_admin -d postgres -c "SELECT version();" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ PostgreSQL fonctionne correctement"
else
    echo "❌ Erreur de connexion PostgreSQL"
fi

# Tester l'API REST
echo "🌐 Test de l'API REST :"
curl -s http://localhost:8000/rest/v1/ 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ API REST accessible"
else
    echo "❌ API REST inaccessible"
fi

echo "🏁 Vérification terminée !"
```

### 📱 Commandes Essentielles

#### Démarrage complet
```bash
# Démarrer tous les services
docker-compose up -d

# Vérifier l'état
docker-compose ps

# Afficher les logs
docker-compose logs -f

# Arrêter tous les services
docker-compose down

# Redémarrer un service spécifique
docker-compose restart db
```

#### Maintenance
```bash
# Sauvegarder la base de données
docker-compose exec db pg_dump -U supabase_admin fintech_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Restaurer la base de données
docker-compose exec -T db psql -U supabase_admin -d fintech_db < backup_20241220_143022.sql

# Accéder au conteneur
docker-compose exec db bash

# Mettre à jour les migrations
docker-compose exec db psql -U supabase_admin -d fintech_db -f /docker-entrypoint-initdb.d/001_new_migration.sql
```

### 🌐 Accès aux Services

Une fois Docker démarré, vous pouvez accéder aux services suivants :

- **Supabase Studio** : http://localhost:3000
  - Dashboard d'administration
  - Éditeur de tables
  - Gestion des permissions

- **API REST** : http://localhost:8000
  - Documentation automatique (Swagger)
  - Endpoints pour votre application Flutter

- **Authentification** : http://localhost:9999
  - JWT tokens
  - Inscription/connexion
  - Magic links

- **Stockage** : http://localhost:5000
  - Upload de fichiers
  - Avatars utilisateurs
  - Documents KYC

- **Realtime** : ws://localhost:4000
  - WebSocket pour notifications
  - Synchronisation en temps réel

### 🚨 Dépannage Avancé

#### Problèmes de performance
```bash
# Surveiller l'utilisation des ressources
docker stats

# Limiter l'utilisation mémoire/CPU
docker-compose up -d --memory=2g --cpus=1.0

# Optimiser PostgreSQL
docker-compose exec db psql -U supabase_admin -d postgres -c "SELECT * FROM pg_stat_activity;"
```

#### Problèmes de réseau
```bash
# Reconstruire le réseau
docker network prune

# Vérifier la connectivité
docker network ls
docker network inspect fintech-network
```

Cette documentation devrait vous aider à résoudre la plupart des problèmes Docker courants avec votre configuration UBAY-DB.
