#!/bin/bash

# Script de vérification amélioré avec tests de connectivité réels
# Teste la connexion au cluster Cassandra et valide la configuration

echo "=================================================="
echo "🔍 VÉRIFICATION AVANCÉE - APPLICATION VÉTÉRINAIRE"
echo "=================================================="
echo ""

# Compteur d'erreurs
ERRORS=0
WARNINGS=0

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les résultats
check_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅${NC} $1"
    else
        echo -e "${RED}❌${NC} $1"
        ((ERRORS++))
    fi
}

check_warning() {
    echo -e "${YELLOW}⚠️${NC}  $1"
    ((WARNINGS++))
}

# ==================== TESTS STRUCTURELS ====================

echo "📁 Vérification des fichiers essentiels..."
test -f "server.js"
check_result "Fichier server.js présent"

test -f "package.json"
check_result "Fichier package.json présent"

test -f "schema.cql"
check_result "Fichier schema.cql présent"

test -f "public/index.html"
check_result "Fichier public/index.html présent"

echo ""

# ==================== TESTS CASSANDRA RÉELS ====================

echo "🗄️  Tests de connectivité Cassandra..."

# Détecter si on est dans un environnement Docker
if command -v docker &> /dev/null; then
    # Essayer de se connecter via les conteneurs Docker
    echo "   Détection environnement Docker..."
    
    # Vérifier si les conteneurs existent
    if docker ps --format '{{.Names}}' | grep -q 'cassandra01'; then
        echo "   ✅ Conteneur cassandra01 trouvé"
        
        # Test de connectivité via nodetool
        if docker exec cassandra01 nodetool status &> /dev/null; then
            echo -e "${GREEN}✅${NC} Cluster Cassandra accessible via Docker"
            
            # Afficher l'état du cluster
            echo ""
            echo "   📊 État du cluster:"
            docker exec cassandra01 nodetool status | grep -E "^(UN|DN)" | while read line; do
                status=$(echo $line | awk '{print $1}')
                ip=$(echo $line | awk '{print $2}')
                if [ "$status" = "UN" ]; then
                    echo -e "      ${GREEN}●${NC} $ip (UP)"
                else
                    echo -e "      ${RED}●${NC} $ip (DOWN)"
                fi
            done
            
            # Compter les nœuds actifs
            NODES_UP=$(docker exec cassandra01 nodetool status | grep -c "^UN")
            if [ "$NODES_UP" -eq 4 ]; then
                echo -e "${GREEN}✅${NC} 4 nœuds actifs (conforme)"
            elif [ "$NODES_UP" -gt 0 ]; then
                check_warning "Seulement $NODES_UP nœud(s) actif(s) sur 4"
            else
                echo -e "${RED}❌${NC} Aucun nœud actif"
                ((ERRORS++))
            fi
            
            # Vérifier le keyspace
            echo ""
            echo "   🔑 Vérification du keyspace..."
            if docker exec cassandra01 cqlsh -e "DESCRIBE KEYSPACE veterinary;" &> /dev/null; then
                echo -e "${GREEN}✅${NC} Keyspace 'veterinary' existe"
                
                # Vérifier les tables
                TABLES=$(docker exec cassandra01 cqlsh -e "USE veterinary; DESCRIBE TABLES;" 2>/dev/null)
                for table in veterinaires especes animaux rendezvous; do
                    if echo "$TABLES" | grep -q "$table"; then
                        echo -e "${GREEN}   ✅${NC} Table '$table' existe"
                    else
                        echo -e "${RED}   ❌${NC} Table '$table' manquante"
                        ((ERRORS++))
                    fi
                done
            else
                check_warning "Keyspace 'veterinary' n'existe pas encore (exécutez schema.cql)"
            fi
        else
            check_warning "Impossible de se connecter au cluster via Docker"
        fi
    else
        check_warning "Conteneurs Cassandra non trouvés en Docker"
        echo "   💡 Vérifiez avec: docker ps | grep cassandra"
    fi
else
    check_warning "Docker non détecté, impossible de tester la connectivité"
fi

echo ""

# ==================== TEST DE CONFIGURATION ====================

echo "⚙️  Vérification de la configuration..."

# Vérifier que la configuration est flexible
if grep -q "process.env.CASSANDRA_NODES" server.js; then
    echo -e "${GREEN}✅${NC} Configuration flexible avec variables d'environnement"
else
    check_warning "Configuration Cassandra en dur (recommandé: utiliser variables d'environnement)"
fi

# Vérifier les IPs par défaut
if grep -q "192.168.100.151" server.js; then
    echo -e "${GREEN}✅${NC} IPs par défaut configurées (192.168.100.151-154)"
else
    check_warning "IPs par défaut non trouvées"
fi

echo ""

# ==================== TESTS D'INTÉGRITÉ ====================

echo "🔍 Vérification de l'intégrité du code..."

# Vérifier les routes essentielles
for route in veterinaires especes animaux rendezvous; do
    if grep -q "app.get('/api/$route'" server.js && \
       grep -q "app.post('/api/$route'" server.js && \
       grep -q "app.put('/api/$route" server.js && \
       grep -q "app.delete('/api/$route" server.js; then
        echo -e "${GREEN}✅${NC} Routes CRUD complètes pour '$route'"
    else
        echo -e "${RED}❌${NC} Routes incomplètes pour '$route'"
        ((ERRORS++))
    fi
done

echo ""

# Vérifier les validations
echo "✔️  Vérification des validations de données..."

if grep -q "SELECT nom FROM especes WHERE id = ?" server.js; then
    echo -e "${GREEN}✅${NC} Validation espèce pour animaux"
else
    echo -e "${RED}❌${NC} Validation espèce manquante"
    ((ERRORS++))
fi

if grep -q "SELECT nom FROM animaux WHERE id = ?" server.js; then
    echo -e "${GREEN}✅${NC} Validation animal pour rendez-vous"
else
    echo -e "${RED}❌${NC} Validation animal manquante"
    ((ERRORS++))
fi

if grep -q "SELECT nom, prenom FROM veterinaires WHERE id = ?" server.js; then
    echo -e "${GREEN}✅${NC} Validation vétérinaire pour rendez-vous"
else
    echo -e "${RED}❌${NC} Validation vétérinaire manquante"
    ((ERRORS++))
fi

echo ""

# ==================== TEST DÉPENDANCES ====================

echo "📦 Vérification des dépendances..."

if [ -f "package.json" ]; then
    for dep in express cassandra-driver body-parser cors uuid; do
        if grep -q "\"$dep\"" package.json; then
            echo -e "${GREEN}✅${NC} Dépendance '$dep' déclarée"
        else
            echo -e "${RED}❌${NC} Dépendance '$dep' manquante"
            ((ERRORS++))
        fi
    done
    
    # Vérifier si node_modules existe
    if [ -d "node_modules" ]; then
        echo -e "${GREEN}✅${NC} Dépendances installées (node_modules présent)"
    else
        check_warning "Dépendances non installées (exécutez: npm install)"
    fi
else
    echo -e "${RED}❌${NC} package.json manquant"
    ((ERRORS++))
fi

echo ""

# ==================== RÉSUMÉ ====================

echo "=================================================="
echo "📋 RÉSUMÉ DE LA VÉRIFICATION"
echo "=================================================="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ PARFAIT${NC} - Aucune erreur ni avertissement!"
    echo ""
    echo "L'application est prête:"
    echo "  ✅ Structure des fichiers complète"
    echo "  ✅ Cluster Cassandra accessible"
    echo "  ✅ Configuration validée"
    echo "  ✅ Routes API complètes"
    echo "  ✅ Validations implémentées"
    echo "  ✅ Dépendances installées"
    echo ""
    echo "🚀 Lancez l'application avec: npm start"
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  OK AVEC AVERTISSEMENTS${NC} - $WARNINGS avertissement(s)"
    echo ""
    echo "L'application devrait fonctionner mais vérifiez:"
    [ $WARNINGS -gt 0 ] && echo "  - Les avertissements ci-dessus"
    echo ""
    echo "💡 Actions recommandées:"
    echo "  - Si keyspace manquant: docker exec -i cassandra01 cqlsh < schema.cql"
    echo "  - Si node_modules manquant: npm install"
    echo ""
    exit 0
else
    echo -e "${RED}❌ ÉCHEC${NC} - $ERRORS erreur(s) critique(s)"
    [ $WARNINGS -gt 0 ] && echo -e "         $WARNINGS avertissement(s)"
    echo ""
    echo "Corrigez les erreurs ci-dessus avant de continuer."
    echo ""
    exit 1
fi
