#!/bin/bash

# UBAY-DB Local Docker Setup
# Script de démarrage facile pour l'environnement local

echo "=========================================="
echo "    UBAY-DB - Démarrage Local Docker     "
echo "=========================================="

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonctions de logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérification des prérequis
check_prerequisites() {
    log_info "Vérification des prérequis..."
    
    # Vérifier Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker n'est pas installé. Veuillez installer Docker d'abord."
        exit 1
    fi
    
    # Vérifier Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose n'est pas installé. Veuillez installer Docker Compose d'abord."
        exit 1
    fi
    
    # Vérifier que Docker fonctionne
    if ! docker info &> /dev/null; then
        log_error "Docker n'est pas démarré. Veuillez démarrer Docker Desktop."
        exit 1
    fi
    
    log_success "Prérequis vérifiés avec succès"
}

# Nettoyage de l'environnement
cleanup() {
    log_info "Nettoyage de l'environnement précédent..."
    
    # Arrêter les conteneurs existants
    docker-compose -f docker-compose.local.yml down 2>/dev/null
    
    # Nettoyer les volumes si nécessaire
    if [ "$1" = "--clean" ]; then
        log_warning "Suppression des volumes de données..."
        docker volume prune -f
        docker system prune -f
    fi
    
    log_success "Nettoyage terminé"
}

# Création des répertoires nécessaires
create_directories() {
    log_info "Création des répertoires nécessaires..."
    
    # Créer le répertoire API s'il n'existe pas
    mkdir -p api
    
    # Créer le répertoire de migrations s'il n'existe pas
    mkdir -p supabase/migrations
    
    # Créer le répertoire nginx s'il n'existe pas
    mkdir -p nginx
    
    log_success "Répertoires créés"
}

# Démarrage des services
start_services() {
    log_info "Démarrage des services UBAY-DB..."
    
    # Démarrer avec le fichier local
    docker-compose -f docker-compose.local.yml up -d
    
    if [ $? -eq 0 ]; then
        log_success "Services démarrés avec succès"
    else
        log_error "Erreur lors du démarrage des services"
        exit 1
    fi
}

# Attente et vérification des services
wait_for_services() {
    log_info "Attente du démarrage des services..."
    
    # Attendre que PostgreSQL soit prêt
    log_info "Attente de PostgreSQL (30 secondes)..."
    sleep 30
    
    # Vérifier que PostgreSQL fonctionne
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker-compose -f docker-compose.local.yml exec -T db pg_isready -U fintech_admin -d fintech_db &>/dev/null; then
            log_success "PostgreSQL est prêt"
            break
        fi
        
        log_info "Tentative $attempt/$max_attempts - PostgreSQL n'est pas encore prêt..."
        sleep 5
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        log_error "PostgreSQL n'a pas pu démarrer correctement"
        exit 1
    fi
    
    # Attendre que l'API soit prête
    log_info "Attente de l'API (15 secondes)..."
    sleep 15
    
    # Vérifier que l'API fonctionne
    local api_attempts=5
    local api_attempt=1
    
    while [ $api_attempt -le $api_attempts ]; do
        if curl -s http://localhost:3000/health &>/dev/null; then
            log_success "API est prête"
            break
        fi
        
        log_info "Tentative $api_attempt/$api_attempts - API n'est pas encore prête..."
        sleep 3
        api_attempt=$((api_attempt + 1))
    done
    
    if [ $api_attempt -gt $api_attempts ]; then
        log_warning "API n'a pas pu démarrer correctement, mais PostgreSQL fonctionne"
    fi
}

# Affichage des informations d'accès
show_access_info() {
    echo ""
    echo "=========================================="
    echo "    UBAY-DB - Services Accessibles        "
    echo "=========================================="
    echo ""
    echo -e "${GREEN}Base de données PostgreSQL:${NC}"
    echo "  Hôte: localhost"
    echo "  Port: 5432"
    echo "  Base: fintech_db"
    echo "  Utilisateur: fintech_admin"
    echo "  Mot de passe: fintech_password_2024"
    echo ""
    echo -e "${GREEN}pgAdmin (Interface Web):${NC}"
    echo "  URL: http://localhost:5050"
    echo "  Email: admin@ubay.com"
    echo "  Mot de passe: admin123"
    echo ""
    echo -e "${GREEN}API REST:${NC}"
    echo "  URL: http://localhost:3000"
    echo "  Health Check: http://localhost:3000/health"
    echo ""
    echo -e "${GREEN}Redis (Cache):${NC}"
    echo "  Hôte: localhost"
    echo "  Port: 6379"
    echo ""
    echo "=========================================="
    echo ""
    echo -e "${BLUE}Commandes utiles:${NC}"
    echo "  Voir les logs: docker-compose -f docker-compose.local.yml logs -f"
    echo "  Arrêter tout: docker-compose -f docker-compose.local.yml down"
    echo "  Redémarrer: docker-compose -f docker-compose.local.yml restart"
    echo ""
}

# Fonction principale
main() {
    case "$1" in
        --clean)
            cleanup --clean
            ;;
        --help|-h)
            echo "Usage: $0 [--clean|--help]"
            echo ""
            echo "Options:"
            echo "  --clean    Nettoie complètement l'environnement avant de démarrer"
            echo "  --help     Affiche cette aide"
            echo ""
            exit 0
            ;;
        "")
            cleanup
            ;;
    esac
    
    check_prerequisites
    create_directories
    start_services
    wait_for_services
    show_access_info
    
    log_success "UBAY-DB est maintenant opérationnel !"
}

# Gestion des signaux
trap 'log_warning "Arrêt forcé..."; docker-compose -f docker-compose.local.yml down; exit 1' INT TERM

# Exécution principale
main "$@"
