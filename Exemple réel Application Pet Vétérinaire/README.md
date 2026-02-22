# Application de Gestion Vétérinaire

Application web complète de gestion pour clinique vétérinaire avec cluster Cassandra 4 nœuds.

## 🏗️ Architecture

- **Frontend**: HTML5 + JavaScript (SPA)
- **Backend**: Node.js + Express
- **Base de données**: Apache Cassandra (cluster 4 nœuds)
- **Cluster Cassandra**:
  - cassandra01: 192.168.100.151
  - cassandra02: 192.168.100.152
  - cassandra03: 192.168.100.153
  - cassandra04: 192.168.100.154

## 📋 Fonctionnalités

✅ **Gestion des Vétérinaires**
- Ajout, modification, suppression (soft delete)
- Informations: nom, prénom, spécialité, contact

✅ **Gestion des Espèces**
- Ajout, modification, suppression
- Référentiel des espèces animales

✅ **Gestion des Animaux**
- Fiche complète par animal
- Validation: espèce doit exister
- Informations propriétaire

✅ **Gestion des Rendez-vous**
- Planification avec date/heure
- Validation: animal et vétérinaire doivent exister
- Suivi des statuts



***

# 🚀 GUIDE DE DÉMARRAGE RAPIDE

## Installation en 3 étapes

cd  ~/cassandra-tp00

sudo rm -Rf veterinary-app*

## On récupère l'application : https://drive.google.com/file/d/1nVQRPSP-jRu_5M-Lsr-4dvxZFt2aXejm/view?usp=drive_link
wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1nVQRPSP-jRu_5M-Lsr-4dvxZFt2aXejm' -O veterinary-app.tar
ls 
tar -xvf veterinary-app.tar
# Affichage en retour : 
	veterinary-app/
	veterinary-app/QUICKSTART.md
	veterinary-app/README.md
	veterinary-app/package.json
	veterinary-app/public/
	veterinary-app/public/index.html
	veterinary-app/schema.cql
	veterinary-app/server.js
	veterinary-app/verify-compliance.sh

# Si le fichier avait été compressé (.gz)
# tar -xzvf veterinary-app.tar.gz


# Regardons le modèle de donnée proposé : 
cat ~/cassandra-tp00/veterinary-app/schema.cql

## Affichage en retour : 
-- Schéma Cassandra pour l'application de gestion vétérinaire
-- À exécuter sur le cluster Cassandra

DROP KEYSPACE IF EXISTS veterinary;

-- Créer le keyspace avec réplication sur les 4 nœuds
CREATE KEYSPACE IF NOT EXISTS veterinary
WITH replication = {
    'class': 'NetworkTopologyStrategy',
    'dc1': 3
};

USE veterinary;

-- Table des vétérinaires
CREATE TABLE IF NOT EXISTS veterinaires (
    id UUID PRIMARY KEY,
    nom TEXT,
    prenom TEXT,
    specialite TEXT,
    telephone TEXT,
    email TEXT,
    actif BOOLEAN
);

-- Table des espèces animales
CREATE TABLE IF NOT EXISTS especes (
    id UUID PRIMARY KEY,
    nom TEXT,
    description TEXT
);

-- Table des animaux
CREATE TABLE IF NOT EXISTS animaux (
    id UUID PRIMARY KEY,
    nom TEXT,
    espece_id UUID,
    espece_nom TEXT,
    proprietaire_nom TEXT,
    proprietaire_telephone TEXT,
    proprietaire_email TEXT,
    date_naissance DATE,
    notes TEXT
);

-- Table des rendez-vous
CREATE TABLE IF NOT EXISTS rendezvous (
    id UUID PRIMARY KEY,
    animal_id UUID,
    animal_nom TEXT,
    veterinaire_id UUID,
    veterinaire_nom TEXT,
    date_heure TIMESTAMP,
    motif TEXT,
    statut TEXT,
    notes TEXT
);

-- Index pour recherches
CREATE INDEX IF NOT EXISTS ON animaux (espece_id);
CREATE INDEX IF NOT EXISTS ON rendezvous (animal_id);
CREATE INDEX IF NOT EXISTS ON rendezvous (veterinaire_id);
CREATE INDEX IF NOT EXISTS ON rendezvous (date_heure);

-- Insérer quelques données de test
INSERT INTO veterinaires (id, nom, prenom, specialite, telephone, email, actif)
VALUES (uuid(), 'Dupont', 'Marie', 'Généraliste', '0601020304', 'marie.dupont@clinic.fr', true);

INSERT INTO veterinaires (id, nom, prenom, specialite, telephone, email, actif)
VALUES (uuid(), 'Martin', 'Pierre', 'Chirurgien', '0605060708', 'pierre.martin@clinic.fr', true);

INSERT INTO especes (id, nom, description)
VALUES (uuid(), 'Chat', 'Félin domestique');

INSERT INTO especes (id, nom, description)
VALUES (uuid(), 'Chien', 'Canidé domestique');

INSERT INTO especes (id, nom, description)
VALUES (uuid(), 'Lapin', 'Lagomorphe');

INSERT INTO especes (id, nom, description)
VALUES (uuid(), 'Oiseau', 'Volatiles divers');




### 1️⃣ Initialiser Cassandra

```bash
# Connectez-vous à votre cluster Cassandra
docker exec -it cassandra01 cqlsh

# Ou avec l'IP en local :
# Activer l'environnement
pyenv activate cqlsh-env
# Lancer cqlsh
cqlsh localhost 9142

# Puis exécutez le fichier schema.cql dans le shell CQL :
SOURCE '~/cassandra-tp00/veterinary-app/schema.cql';

# Ou directement depuis l'extérieur (en terminal de commande linux) : 
docker exec -i cassandra01 cqlsh < ~/cassandra-tp00/veterinary-app/schema.cql
```


## En CQL, on regarde le keyspace et les tables créées : 

cqlsh> describe keyspaces

## Affichage en retour : 
	system       system_distributed  system_traces  system_virtual_schema
	system_auth  system_schema       system_views   veterinary

## Plus en détail : 
describe keyspace veterinary

## Affichage en retour : 
... > Remarquez les différences avec le CQL d'origine utilisé pour la création ( schema.cql)


### 2️⃣ Installer les dépendances Node.js

```bash
cd /home/user/cassandra-tp00/veterinary-app
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
cd /home/user/cassandra-tp00/veterinary-app
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
pyenv activate cqlsh-env
cqlsh 192.168.100.151 -e "DESCRIBE KEYSPACE veterinary;"
```

### Si pb de port 3000 occupé
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

