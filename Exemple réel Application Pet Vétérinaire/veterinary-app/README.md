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

## 🚀 Installation

### Prérequis

1. Cluster Cassandra opérationnel (4 nœuds)
2. Node.js 16+ installé
3. npm ou yarn

### Étape 1: Initialiser la base de données

Connectez-vous à l'un des nœuds Cassandra et exécutez:

```bash
# Depuis un conteneur Cassandra
docker exec -it cassandra01 cqlsh

# Ou depuis cqlsh local
cqlsh 192.168.100.151
```

Puis exécutez le contenu du fichier `schema.cql`:

```bash
# Ou directement depuis le fichier
docker exec -i cassandra01 cqlsh < schema.cql
```

### Étape 2: Installer les dépendances Node.js

```bash
npm install
```

### Étape 3: Démarrer le serveur

```bash
# Mode production
npm start

# Mode développement (avec auto-reload)
npm run dev
```

Le serveur démarre sur `http://localhost:3000`

## 📊 Schéma de données

### Keyspace
```sql
CREATE KEYSPACE veterinary
WITH replication = {
    'class': 'SimpleStrategy',
    'replication_factor': 3
};
```

### Tables

- **veterinaires**: Informations des vétérinaires (avec soft delete)
- **especes**: Référentiel des espèces animales
- **animaux**: Fiches des animaux avec propriétaires
- **rendezvous**: Planning des consultations

## 🔄 Réplication Cassandra

L'application est configurée pour utiliser le cluster avec:
- **Facteur de réplication**: 3 (sur 4 nœuds)
- **Contact points**: Les 4 nœuds du cluster
- **Consistance**: ONE par défaut (configurable)

## 🔐 Validation des données

L'application valide automatiquement:
- ✅ Espèce existante lors de l'ajout d'un animal
- ✅ Animal existant lors de la création d'un rendez-vous
- ✅ Vétérinaire existant lors de la création d'un rendez-vous

## 📱 Utilisation de l'interface

1. **Accédez à l'application**: `http://localhost:3000`
2. **Navigation par onglets**:
   - 👨‍⚕️ Vétérinaires
   - 🦁 Espèces
   - 🐶 Animaux
   - 📅 Rendez-vous

3. **Workflow recommandé**:
   - Ajouter des vétérinaires
   - Ajouter des espèces
   - Ajouter des animaux (nécessite des espèces)
   - Créer des rendez-vous (nécessite animaux + vétérinaires)

## 🛠️ Configuration avancée

Pour modifier les points de contact Cassandra, éditez `server.js`:

```javascript
const client = new cassandra.Client({
    contactPoints: [
        '192.168.100.151',
        '192.168.100.152',
        '192.168.100.153',
        '192.168.100.154'
    ],
    localDataCenter: 'datacenter1',
    keyspace: 'veterinary'
});
```

## 📦 Structure du projet

```
.
├── package.json          # Dépendances Node.js
├── server.js             # Serveur Express + API REST
├── schema.cql            # Schéma Cassandra
├── public/
│   └── index.html        # Interface web (SPA)
└── README.md             # Ce fichier
```

## 🔍 API REST

### Vétérinaires
- `GET /api/veterinaires` - Liste
- `POST /api/veterinaires` - Créer
- `PUT /api/veterinaires/:id` - Modifier
- `DELETE /api/veterinaires/:id` - Supprimer (soft)

### Espèces
- `GET /api/especes` - Liste
- `POST /api/especes` - Créer
- `PUT /api/especes/:id` - Modifier
- `DELETE /api/especes/:id` - Supprimer

### Animaux
- `GET /api/animaux` - Liste
- `POST /api/animaux` - Créer (valide l'espèce)
- `PUT /api/animaux/:id` - Modifier
- `DELETE /api/animaux/:id` - Supprimer

### Rendez-vous
- `GET /api/rendezvous` - Liste
- `POST /api/rendezvous` - Créer (valide animal + vétérinaire)
- `PUT /api/rendezvous/:id` - Modifier
- `DELETE /api/rendezvous/:id` - Supprimer

## 🐛 Dépannage

### Erreur de connexion Cassandra
Vérifiez que:
- Les 4 nœuds sont démarrés
- Le port 9042 est accessible
- Le keyspace 'veterinary' existe

```bash
# Vérifier l'état du cluster
docker exec cassandra01 nodetool status

# Tester la connexion
cqlsh 192.168.100.151
```

### Port 3000 déjà utilisé
Modifiez le port dans `server.js`:
```javascript
const PORT = 3001; // Ou autre port disponible
```

## 📝 Données de test

Le fichier `schema.cql` inclut des données de test:
- 2 vétérinaires (Dr. Dupont, Dr. Martin)
- 4 espèces (Chat, Chien, Lapin, Oiseau)

## 🎯 Points de vérification

✅ Cluster Cassandra avec exactement 4 nœuds:
   - 192.168.100.151, 152, 153, 154

✅ Validation des saisies:
   - Espèce existante pour animaux
   - Animal existant pour rendez-vous
   - Vétérinaire existant pour rendez-vous

✅ Interface simple: 1 page HTML avec onglets

✅ Persistance dans Cassandra avec réplication

✅ Backend Node.js avec Express

## 📞 Support

Pour toute question sur l'application, vérifiez d'abord:
1. Les logs du serveur Node.js
2. L'état du cluster Cassandra
3. Les requêtes réseau dans la console du navigateur
