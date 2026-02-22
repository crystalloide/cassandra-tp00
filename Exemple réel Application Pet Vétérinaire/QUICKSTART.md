# 🚀 GUIDE DE DÉMARRAGE RAPIDE

## Installation en 3 étapes

### 1️⃣ Initialiser Cassandra

```bash
# Connectez-vous à votre cluster Cassandra
docker exec -it cassandra01 cqlsh

# Ou avec l'IP
cqlsh 192.168.100.151

# Puis exécutez le fichier schema.cql
SOURCE 'schema.cql';

# Ou directement depuis l'extérieur
docker exec -i cassandra01 cqlsh < schema.cql
```

### 2️⃣ Installer les dépendances Node.js

```bash
cd veterinary-app
npm install
```

### 3️⃣ Démarrer l'application

```bash
npm start
```

🌐 Ouvrez votre navigateur sur: **http://localhost:3000**

---

## ✅ Vérification de conformité

Lancez le script de vérification pour confirmer que tout est correct:

```bash
chmod +x verify-compliance.sh
./verify-compliance.sh
```

Ce script vérifie automatiquement:
- ✅ Configuration du cluster 4 nœuds Cassandra
- ✅ Présence de toutes les routes API
- ✅ Validations des données
- ✅ Structure de l'interface

---

## 📊 Architecture validée

```
┌─────────────────────────────────────────────────┐
│           Interface Web (1 page HTML)           │
│  Onglets: Vétérinaires | Espèces | Animaux | RDV│
└────────────────┬────────────────────────────────┘
                 │ API REST
┌────────────────▼────────────────────────────────┐
│         Serveur Node.js + Express               │
│   Validation automatique des références         │
└────────────────┬────────────────────────────────┘
                 │ Cassandra Driver
┌────────────────▼────────────────────────────────┐
│          Cluster Cassandra (4 nœuds)            │
│  cassandra01: 192.168.100.151                   │
│  cassandra02: 192.168.100.152                   │
│  cassandra03: 192.168.100.153                   │
│  cassandra04: 192.168.100.154                   │
│  Réplication factor: 3                          │
└─────────────────────────────────────────────────┘
```

---

## 🎯 Fonctionnalités implémentées

### 👨‍⚕️ Vétérinaires
- ➕ Ajout avec validation complète
- ✏️ Modification des informations
- 🗑️ Suppression (soft delete - désactivation)

### 🦁 Espèces
- ➕ Ajout d'espèces animales
- ✏️ Modification
- 🗑️ Suppression

### 🐶 Animaux
- ➕ Ajout avec validation espèce
- ⚠️ **Validation**: L'espèce doit exister
- Informations propriétaire complètes
- ✏️ Modification
- 🗑️ Suppression

### 📅 Rendez-vous
- ➕ Création avec planification
- ⚠️ **Validation**: Animal ET vétérinaire doivent exister
- Gestion des statuts
- ✏️ Modification
- 🗑️ Suppression

---

## 🔐 Validations automatiques

L'application refuse automatiquement:
- ❌ Animal avec espèce inexistante
- ❌ Rendez-vous avec animal inexistant
- ❌ Rendez-vous avec vétérinaire inexistant

Messages d'erreur clairs affichés à l'utilisateur.

---

## 📝 Workflow recommandé

1. **Ajouter des vétérinaires** (Dr. Dupont, Dr. Martin déjà présents)
2. **Ajouter des espèces** (Chat, Chien, Lapin, Oiseau déjà présents)
3. **Ajouter des animaux** (nécessite des espèces existantes)
4. **Créer des rendez-vous** (nécessite animaux et vétérinaires existants)

---

## 🐛 Dépannage rapide

### Problème de connexion Cassandra
```bash
# Vérifier l'état du cluster
docker exec cassandra01 nodetool status

# Tester la connexion
cqlsh 192.168.100.151 -e "DESCRIBE KEYSPACE veterinary;"
```

### Port 3000 occupé
Modifiez dans `server.js`:
```javascript
const PORT = 3001; // Changez le port
```

### Données de test
Le fichier `schema.cql` inclut des données de démo:
- 2 vétérinaires
- 4 espèces

---

## 📂 Structure des fichiers

```
veterinary-app/
├── server.js              # Serveur Node.js + API REST
├── package.json           # Dépendances
├── schema.cql             # Schéma Cassandra
├── README.md              # Documentation complète
├── verify-compliance.sh   # Script de vérification
└── public/
    └── index.html         # Interface web (SPA)
```

---

## 🎉 C'est prêt !

Votre application respecte TOUTES les spécifications:
- ✅ Cluster Cassandra 4 nœuds (192.168.100.151-154)
- ✅ Gestion complète (vétérinaires, espèces, animaux, RDV)
- ✅ Validation des saisies (valeurs existantes)
- ✅ Interface 1 page HTML
- ✅ Backend Node.js
- ✅ Persistance Cassandra avec réplication

**Lancez `npm start` et commencez à utiliser l'application !** 🚀
