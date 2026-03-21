# TP — Installation et utilisation de Medusa sur cluster Cassandra Docker 4 nœuds (2 racks / 2 DC)

---

## Objectif

Ajouter **Medusa** (outil de sauvegarde/restauration pour Apache Cassandra) au cluster Docker composé de 4 nœuds répartis sur 2 Data Centers et 2 racks. 

Les sauvegardes seront stockées dans un répertoire partagé monté depuis la machine hôte : `${PWD}/docker/medusa_sauvegarde`.

---

## Architecture cible

```
Machine hôte
│
├── docker/medusa_sauvegarde/     ← répertoire de sauvegarde partagé (hôte)
│   └── cassandra_backups/
│       ├── cassandra01/
│       ├── cassandra02/
│       ├── cassandra03/
│       └── cassandra04/
│
└── Docker réseau : cassandra_network (192.168.100.0/24)
    │
    ├── cassandra01  192.168.100.151  DC=Nord               RACK=Winterfell
    ├── cassandra02  192.168.100.152  DC=Terres-de-la-Couronne  RACK=Port-Real
    ├── cassandra03  192.168.100.153  DC=Nord               RACK=Winterfell
    └── cassandra04  192.168.100.154  DC=Terres-de-la-Couronne  RACK=Port-Real
```

**Principe de sauvegarde :**
- Medusa est **installé dans chaque conteneur Cassandra** (via pip3).
- Le répertoire hôte `${PWD}/docker/medusa_sauvegarde` est monté dans **chaque conteneur** sous `/medusa_sauvegarde`.
- Les 4 nœuds écrivent leurs sauvegardes dans ce répertoire partagé, ce qui permet de tout centraliser sur l'hôte.

---

## Étape 1 — Arrêt du cluster et mise à jour du docker-compose.yml

### 1.1 Arrêt propre du cluster existant

```bash
docker compose down
```
#### Recréation des répertoires pour les volumes persistés :
```bash
sudo rm -Rf ~/cassandra-tp00/docker/cassandra*
mkdir -p ~/cassandra-tp00/docker/cassandra01 ~/cassandra-tp00/docker/cassandra02 ~/cassandra-tp00/docker/cassandra03 ~/cassandra-tp00/docker/cassandra04
```

```bash
mkdir -p ~/cassandra-tp00/docker/cassandra01-conf ~/cassandra-tp00/docker/cassandra02-conf ~/cassandra-tp00/docker/cassandra03-conf ~/cassandra-tp00/docker/cassandra04-conf
```

#### On affiche les répertoires créés :
```bash
ls ~/cassandra-tp00/docker
```
##### Affichage : 
```bash
     cassandra01       cassandra02       cassandra03       cassandra04
     assandra01-conf  cassandra02-conf  cassandra03-conf  cassandra04-conf
```

### 1.2 Création du répertoire de sauvegarde sur l'hôte

```bash
mkdir -p ${PWD}/docker/medusa_sauvegarde
chmod 777 ${PWD}/docker/medusa_sauvegarde
```

### 1.3 Modification du fichier docker-compose.yml

Ajouter le volume de sauvegarde `medusa_sauvegarde` à **chacun des 4 services** Cassandra, et déclarer le volume nommé correspondant.

Voici le fichier complet mis à jour :

```yaml
networks:
  cassandra_network:
    ipam:
      config:
        - subnet: 192.168.100.0/24

services:
  cassandra01:
    image: docker.io/library/cassandra:latest
    hostname: cassandra01
    container_name: cassandra01
    mem_limit: 1g
    cpus: 0.5
    restart: always
    networks:
      cassandra_network:
        ipv4_address: 192.168.100.151
    volumes:
      - ${PWD}/docker/cassandra01:/var/lib/cassandra
      - conf01:/opt/cassandra/conf
      - medusa_sauvegarde:/medusa_sauvegarde    # ← AJOUT
    environment:
      - CASSANDRA_CLUSTER_NAME=formation
      - CASSANDRA_SEEDS=cassandra01,cassandra02
      - CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
      - CASSANDRA_DC=Nord
      - CASSANDRA_RACK=Winterfell
      - CASSANDRA_BROADCAST_RPC_ADDRESS=192.168.100.151
      - CASSANDRA_NATIVE_TRANSPORT_PORT=9042
      - MAX_HEAP_SIZE=256m
      - HEAP_NEWSIZE=50m
      - LOCAL_JMX=no
      - JVM_EXTRA_OPTS=-Djava.rmi.server.hostname=192.168.100.151 -Dcom.sun.management.jmxremote.authenticate=false
    ports:
      - "7100:7000"
      - "9142:9042"
      - "7199:7199"
      - "8181:8081"
    healthcheck:
      test: ["CMD-SHELL", "grep -q 'Startup complete' /var/log/cassandra/system.log"]
      interval: 15s
      timeout: 10s
      retries: 50
      start_period: 180s

  cassandra02:
    depends_on:
      cassandra01:
        condition: service_healthy
    image: docker.io/library/cassandra:latest
    hostname: cassandra02
    container_name: cassandra02
    mem_limit: 1g
    cpus: 0.5
    restart: always
    networks:
      cassandra_network:
        ipv4_address: 192.168.100.152
    volumes:
      - ${PWD}/docker/cassandra02:/var/lib/cassandra
      - conf02:/opt/cassandra/conf
      - medusa_sauvegarde:/medusa_sauvegarde    # ← AJOUT
    environment:
      - CASSANDRA_CLUSTER_NAME=formation
      - CASSANDRA_SEEDS=cassandra01,cassandra02
      - CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
      - CASSANDRA_DC=Terres-de-la-Couronne
      - CASSANDRA_RACK=Port-Real
      - CASSANDRA_BROADCAST_RPC_ADDRESS=192.168.100.152
      - CASSANDRA_NATIVE_TRANSPORT_PORT=9042
      - MAX_HEAP_SIZE=256m
      - HEAP_NEWSIZE=50m
      - LOCAL_JMX=no
      - JVM_EXTRA_OPTS=-Djava.rmi.server.hostname=192.168.100.152 -Dcom.sun.management.jmxremote.authenticate=false
    ports:
      - "7200:7000"
      - "9242:9042"
      - "7299:7199"
      - "8281:8081"
    healthcheck:
      test: ["CMD-SHELL", "grep -q 'Startup complete' /var/log/cassandra/system.log"]
      interval: 15s
      timeout: 10s
      retries: 50
      start_period: 180s

  cassandra03:
    depends_on:
      cassandra02:
        condition: service_healthy
    image: docker.io/library/cassandra:latest
    hostname: cassandra03
    container_name: cassandra03
    mem_limit: 1g
    cpus: 0.5
    restart: always
    networks:
      cassandra_network:
        ipv4_address: 192.168.100.153
    volumes:
      - ${PWD}/docker/cassandra03:/var/lib/cassandra
      - conf03:/opt/cassandra/conf
      - medusa_sauvegarde:/medusa_sauvegarde    # ← AJOUT
    environment:
      - CASSANDRA_CLUSTER_NAME=formation
      - CASSANDRA_SEEDS=cassandra01,cassandra02
      - CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
      - CASSANDRA_DC=Nord
      - CASSANDRA_RACK=Winterfell
      - CASSANDRA_BROADCAST_RPC_ADDRESS=192.168.100.153
      - CASSANDRA_NATIVE_TRANSPORT_PORT=9042
      - MAX_HEAP_SIZE=256m
      - HEAP_NEWSIZE=50m
      - LOCAL_JMX=no
      - JVM_EXTRA_OPTS=-Djava.rmi.server.hostname=192.168.100.153 -Dcom.sun.management.jmxremote.authenticate=false
    ports:
      - "7300:7000"
      - "9342:9042"
      - "7399:7199"
      - "8381:8081"
    healthcheck:
      test: ["CMD-SHELL", "grep -q 'Startup complete' /var/log/cassandra/system.log"]
      interval: 15s
      timeout: 10s
      retries: 50
      start_period: 180s

  cassandra04:
    depends_on:
      cassandra03:
        condition: service_healthy
    image: docker.io/library/cassandra:latest
    hostname: cassandra04
    container_name: cassandra04
    mem_limit: 1g
    cpus: 0.5
    restart: always
    networks:
      cassandra_network:
        ipv4_address: 192.168.100.154
    volumes:
      - ${PWD}/docker/cassandra04:/var/lib/cassandra
      - conf04:/opt/cassandra/conf
      - medusa_sauvegarde:/medusa_sauvegarde    # ← AJOUT
    environment:
      - CASSANDRA_CLUSTER_NAME=formation
      - CASSANDRA_SEEDS=cassandra01,cassandra02
      - CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
      - CASSANDRA_DC=Terres-de-la-Couronne
      - CASSANDRA_RACK=Port-Real
      - CASSANDRA_BROADCAST_RPC_ADDRESS=192.168.100.154
      - CASSANDRA_NATIVE_TRANSPORT_PORT=9042
      - MAX_HEAP_SIZE=256m
      - HEAP_NEWSIZE=50m
      - LOCAL_JMX=no
      - JVM_EXTRA_OPTS=-Djava.rmi.server.hostname=192.168.100.154 -Dcom.sun.management.jmxremote.authenticate=false
    ports:
      - "7400:7000"
      - "9442:9042"
      - "7499:7199"
      - "8481:8081"
    healthcheck:
      test: ["CMD-SHELL", "grep -q 'Startup complete' /var/log/cassandra/system.log"]
      interval: 15s
      timeout: 10s
      retries: 50
      start_period: 180s

volumes:
  conf01:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${PWD}/docker/cassandra01-conf
  conf02:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${PWD}/docker/cassandra02-conf
  conf03:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${PWD}/docker/cassandra03-conf
  conf04:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${PWD}/docker/cassandra04-conf

  # ← NOUVEAU VOLUME PARTAGÉ
  medusa_sauvegarde:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${PWD}/docker/medusa_sauvegarde
```

---

## Étape 2 — Démarrage du cluster mis à jour

```bash
docker compose up -d
```

Attendre que les 4 nœuds soient healthy (peut prendre 5 à 10 minutes) :

```bash
docker compose ps
```

Résultat attendu — tous les statuts doivent être `healthy` :

```
NAME          STATUS
cassandra01   Up X minutes (healthy)
cassandra02   Up X minutes (healthy)
cassandra03   Up X minutes (healthy)
cassandra04   Up X minutes (healthy)
```

Vérifier le cluster :

```bash
docker exec cassandra01 nodetool status
```

Résultat attendu :

```
Datacenter: Nord
=================
Status=Up/Normal
|/ State=Normal
-- Address          Load        Tokens  Owns  Host ID  Rack
UN 192.168.100.151  ...         256     ?     ...      Winterfell
UN 192.168.100.153  ...         256     ?     ...      Winterfell

Datacenter: Terres-de-la-Couronne
==================================
UN 192.168.100.152  ...         256     ?     ...      Port-Real
UN 192.168.100.154  ...         256     ?     ...      Winterfell
```

---

## Étape 3 — Création de données de test

Avant de configurer Medusa, on insère des données pour avoir quelque chose à sauvegarder et restaurer.

```bash
docker exec -it cassandra01 cqlsh 192.168.100.151 9042
```

Dans le shell CQL :

```sql
-- Créer un keyspace répliqué sur les 2 DC
CREATE KEYSPACE IF NOT EXISTS formation
  WITH replication = {
    'class': 'NetworkTopologyStrategy',
    'Nord': 2,
    'Terres-de-la-Couronne': 2
  };

-- Créer une table
CREATE TABLE IF NOT EXISTS formation.employes (
  id   UUID PRIMARY KEY,
  nom  TEXT,
  poste TEXT,
  dc    TEXT
);

-- Insérer des données
INSERT INTO formation.employes (id, nom, poste, dc)
  VALUES (uuid(), 'Alice Martin',   'DBA',      'Nord');
INSERT INTO formation.employes (id, nom, poste, dc)
  VALUES (uuid(), 'Bob Dupont',     'DevOps',   'Terres-de-la-Couronne');
INSERT INTO formation.employes (id, nom, poste, dc)
  VALUES (uuid(), 'Claire Durand',  'Dev',      'Nord');
INSERT INTO formation.employes (id, nom, poste, dc)
  VALUES (uuid(), 'David Lemaire',  'SRE',      'Nord');

-- Vérifier
SELECT * FROM formation.employes;

EXIT;
```

---

## Étape 4 — Installation de Medusa dans chaque conteneur

> **Remarque :** L'image officielle `cassandra:latest` est basée sur Debian. On installe Medusa via pip3 directement dans chaque conteneur. Cette installation ne persiste pas au redémarrage — pour un usage production, construire une image Docker personnalisée.

### 4.1 Installation sur cassandra01

```bash
docker exec -it cassandra01 bash
```

Dans le conteneur :

```bash
# Mettre à jour les paquets et installer pip3
apt-get update -y && apt-get install -y python3-pip python3-dev gcc

# Installer Medusa (stockage local)
pip3 install cassandra-medusa

# Vérifier l'installation
medusa --version
# Résultat attendu : 0.24.x ou supérieur

exit
```

### 4.2 Installation sur cassandra02

```bash
docker exec -it cassandra02 bash
apt-get update -y && apt-get install -y python3-pip python3-dev gcc
pip3 install cassandra-medusa
medusa --version
exit
```

### 4.3 Installation sur cassandra03

```bash
docker exec -it cassandra03 bash
apt-get update -y && apt-get install -y python3-pip python3-dev gcc
pip3 install cassandra-medusa
medusa --version
exit
```

### 4.4 Installation sur cassandra04

```bash
docker exec -it cassandra04 bash
apt-get update -y && apt-get install -y python3-pip python3-dev gcc
pip3 install cassandra-medusa
medusa --version
exit
```

> **Astuce :** Pour gagner du temps, on peut lancer les 4 installations en parallèle depuis 4 terminaux.

---

## Étape 5 — Configuration de medusa.ini sur chaque nœud

Le fichier `medusa.ini` doit être créé dans `/etc/medusa/` sur **chaque conteneur**. Les paramètres clés diffèrent uniquement sur `nodetool_host` (l'IP du nœud).

### 5.1 Configuration sur cassandra01

```bash
docker exec -it cassandra01 bash
```

```bash
mkdir -p /etc/medusa

cat > /etc/medusa/medusa.ini << 'EOF'
[cassandra]
; Chemin vers cassandra.yaml (volume conf monté dans le conteneur)
config_file = /opt/cassandra/conf/cassandra.yaml

; Identifiants CQL (authentification désactivée par défaut)
;cql_username = cassandra
;cql_password = cassandra

; Connexion JMX pour nodetool
nodetool_host = 192.168.100.151
nodetool_port = 7199

; Vérification que Cassandra tourne
check_running = nodetool version

; Résolution des adresses IP
resolve_ip_addresses = True

; Pas besoin de sudo dans le conteneur (on est root)
use_sudo = False

[storage]
; Stockage local — le volume /medusa_sauvegarde est monté depuis l'hôte
storage_provider = local
base_path = /medusa_sauvegarde
bucket_name = cassandra_backups

; Préfixe pour identifier ce cluster dans le répertoire de stockage
prefix = formation

; Rétention : 0 = pas de purge automatique
max_backup_age = 0
max_backup_count = 0

; Délai de grâce avant suppression physique des fichiers (jours)
backup_grace_period_in_days = 10

; Throttling des transferts
transfer_max_bandwidth = 50MB/s
concurrent_transfers = 1
multi_part_upload_threshold = 104857600

[monitoring]
;monitoring_provider = local

[ssh]
; Non utilisé en mode sauvegarde nœud par nœud

[checks]
;health_check = cql

[logging]
enabled = 1
file = /var/log/cassandra/medusa.log
level = INFO
EOF

chmod 644 /etc/medusa/medusa.ini

exit
```

### 5.2 Configuration sur cassandra02

```bash
docker exec -it cassandra02 bash
```

```bash
mkdir -p /etc/medusa

cat > /etc/medusa/medusa.ini << 'EOF'
[cassandra]
config_file = /opt/cassandra/conf/cassandra.yaml
nodetool_host = 192.168.100.152
nodetool_port = 7199
check_running = nodetool version
resolve_ip_addresses = True
use_sudo = False

[storage]
storage_provider = local
base_path = /medusa_sauvegarde
bucket_name = cassandra_backups
prefix = formation
max_backup_age = 0
max_backup_count = 0
backup_grace_period_in_days = 10
transfer_max_bandwidth = 50MB/s
concurrent_transfers = 1
multi_part_upload_threshold = 104857600

[logging]
enabled = 1
file = /var/log/cassandra/medusa.log
level = INFO
EOF

exit
```

### 5.3 Configuration sur cassandra03

```bash
docker exec -it cassandra03 bash
```

```bash
mkdir -p /etc/medusa

cat > /etc/medusa/medusa.ini << 'EOF'
[cassandra]
config_file = /opt/cassandra/conf/cassandra.yaml
nodetool_host = 192.168.100.153
nodetool_port = 7199
check_running = nodetool version
resolve_ip_addresses = True
use_sudo = False

[storage]
storage_provider = local
base_path = /medusa_sauvegarde
bucket_name = cassandra_backups
prefix = formation
max_backup_age = 0
max_backup_count = 0
backup_grace_period_in_days = 10
transfer_max_bandwidth = 50MB/s
concurrent_transfers = 1
multi_part_upload_threshold = 104857600

[logging]
enabled = 1
file = /var/log/cassandra/medusa.log
level = INFO
EOF

exit
```

### 5.4 Configuration sur cassandra04

```bash
docker exec -it cassandra04 bash
```

```bash
mkdir -p /etc/medusa

cat > /etc/medusa/medusa.ini << 'EOF'
[cassandra]
config_file = /opt/cassandra/conf/cassandra.yaml
nodetool_host = 192.168.100.154
nodetool_port = 7199
check_running = nodetool version
resolve_ip_addresses = True
use_sudo = False

[storage]
storage_provider = local
base_path = /medusa_sauvegarde
bucket_name = cassandra_backups
prefix = formation
max_backup_age = 0
max_backup_count = 0
backup_grace_period_in_days = 10
transfer_max_bandwidth = 50MB/s
concurrent_transfers = 1
multi_part_upload_threshold = 104857600

[logging]
enabled = 1
file = /var/log/cassandra/medusa.log
level = INFO
EOF

exit
```

---

## Étape 6 — Sauvegarde différentielle de chaque nœud

On lance une sauvegarde différentielle nœud par nœud. Medusa va :
1. Créer un snapshot via `nodetool snapshot`
2. Copier les SSTables vers `/medusa_sauvegarde/cassandra_backups/`
3. Enregistrer le schéma CQL, la tokenmap et un manifeste MD5
4. Supprimer le snapshot local

### 6.1 Sauvegarde sur cassandra01

```bash
docker exec cassandra01 medusa backup --backup-name=sauvegarde_initiale
```

Résultat attendu :

```
[INFO] Resolving ip address
[INFO] ip address to resolve 192.168.100.151
[INFO] Registered backup id sauvegarde_initiale
[INFO] Monitoring provider is noop
[INFO] Starting backup using Stagger: None Mode: differential Name: sauvegarde_initiale
[INFO] Saving tokenmap and schema
[INFO] Creating snapshot
[INFO] Backing up system_schema.keyspaces-...
[INFO] Backing up formation.employes-...
[INFO] Updating backup index
[INFO] Backup done
[INFO] - Started: 2026-03-21 HH:MM:SS
[INFO] - Finished: 2026-03-21 HH:MM:SS
[INFO] - X files, X.XX KB
```

### 6.2 Sauvegarde sur cassandra02

```bash
docker exec cassandra02 medusa backup --backup-name=sauvegarde_initiale
```

### 6.3 Sauvegarde sur cassandra03

```bash
docker exec cassandra03 medusa backup --backup-name=sauvegarde_initiale
```

### 6.4 Sauvegarde sur cassandra04

```bash
docker exec cassandra04 medusa backup --backup-name=sauvegarde_initiale
```

---

## Étape 7 — Vérification des sauvegardes sur l'hôte

Depuis la machine hôte, explorer le répertoire de sauvegarde :

```bash
ls -la ${PWD}/docker/medusa_sauvegarde/
```

Résultat attendu :

```
cassandra_backups/
```

```bash
ls -la ${PWD}/docker/medusa_sauvegarde/cassandra_backups/
```

Résultat attendu (un répertoire par nœud + index) :

```
drwxr-xr-x  cassandra01/
drwxr-xr-x  cassandra02/
drwxr-xr-x  cassandra03/
drwxr-xr-x  cassandra04/
drwxr-xr-x  index/
```

Examiner le contenu de la sauvegarde du nœud cassandra01 :

```bash
ls -la ${PWD}/docker/medusa_sauvegarde/cassandra_backups/cassandra01/
```

```
drwxr-xr-x  sauvegarde_initiale/
drwxr-xr-x  data/
```

```bash
ls -la ${PWD}/docker/medusa_sauvegarde/cassandra_backups/cassandra01/sauvegarde_initiale/meta/
```

```
-rw-r--r--  differential       ← type de sauvegarde
-rw-r--r--  manifest.json      ← liste des fichiers avec leur hash MD5
-rw-r--r--  schema.cql         ← schéma CQL complet du cluster
-rw-r--r--  server_version.json
-rw-r--r--  tokenmap.json      ← répartition des tokens entre nœuds
```

---

## Étape 8 — Lister et vérifier les sauvegardes

### 8.1 Lister les sauvegardes disponibles

Depuis cassandra01, lister toutes les sauvegardes du répertoire de stockage :

```bash
docker exec cassandra01 medusa list-backups --show-all
```

Résultat attendu :

```
sauvegarde_initiale (started: 2026-03-21 HH:MM:SS, finished: 2026-03-21 HH:MM:SS)
```

> L'option `--show-all` affiche les sauvegardes de **tous les nœuds** dans le stockage, pas uniquement celles du nœud courant.

### 8.2 Vérifier l'intégrité d'une sauvegarde

```bash
docker exec cassandra01 medusa verify --backup-name=sauvegarde_initiale
```

Résultat attendu :

```
Validating sauvegarde_initiale ...
- Completion: OK!
- Manifest validated: OK!!
```

> En cas de nœud manquant dans la sauvegarde, Medusa le signalera : `Completion: Not complete!` suivi du détail des nœuds manquants.

### 8.3 Afficher le statut détaillé d'une sauvegarde

```bash
docker exec cassandra01 medusa status --backup-name=sauvegarde_initiale
```

Résultat attendu :

```
sauvegarde_initiale
- Started: 2026-03-21 HH:MM:SS, Finished: 2026-03-21 HH:MM:SS
- 4 nodes completed, 0 nodes incomplete, 0 nodes missing
- XXXX files, X.XX MB
```

---

## Étape 9 — Sauvegarde complète (full)

Par défaut, Medusa effectue des sauvegardes **différentielles** (seuls les fichiers nouveaux ou modifiés sont copiés). On peut forcer une sauvegarde complète avec `--mode=full`.

```bash
# Sur chaque nœud, sauvegarde complète
docker exec cassandra01 medusa backup --backup-name=sauvegarde_full --mode=full
docker exec cassandra02 medusa backup --backup-name=sauvegarde_full --mode=full
docker exec cassandra03 medusa backup --backup-name=sauvegarde_full --mode=full
docker exec cassandra04 medusa backup --backup-name=sauvegarde_full --mode=full
```

Vérifier que les deux sauvegardes sont présentes :

```bash
docker exec cassandra01 medusa list-backups --show-all
```

Résultat attendu :

```
sauvegarde_initiale (started: ..., finished: ...)
sauvegarde_full     (started: ..., finished: ...)
```

---

## Étape 10 — Scénario de restauration d'un nœud

### 10.1 Simulation d'une perte de données

On supprime les données du keyspace `formation` pour simuler une corruption :

```bash
docker exec -it cassandra01 cqlsh 192.168.100.151 9042
```

```sql
-- Supprimer toutes les données
TRUNCATE formation.employes;

-- Vérifier que la table est vide
SELECT * FROM formation.employes;
-- Résultat attendu : 0 rows

EXIT;
```

### 10.2 Restauration du nœud cassandra01

> **Important :** La restauration Medusa nécessite un arrêt/redémarrage de Cassandra. Dans un contexte Docker sans systemd, on gère cela manuellement.

```bash
docker exec -it cassandra01 bash
```

Dans le conteneur :

```bash
# Étape A : arrêter Cassandra proprement
nodetool drain
pkill -f CassandraDaemon

# Attendre l'arrêt complet
sleep 5

# Étape B : restaurer le nœud depuis la sauvegarde
medusa restore-node \
  --backup-name=sauvegarde_initiale \
  --keyspace=formation

# Résultat attendu :
# [INFO] Restoring node from backup sauvegarde_initiale
# [INFO] Downloading backup files ...
# [INFO] Stopping Cassandra ...
# [INFO] Moving files to Cassandra data directory ...
# [INFO] Node restore complete

# Étape C : redémarrer Cassandra
/docker-entrypoint.sh cassandra -f &

exit
```

Attendre que le nœud soit de nouveau opérationnel :

```bash
docker exec cassandra01 nodetool status
```

### 10.3 Vérification de la restauration

```bash
docker exec -it cassandra01 cqlsh 192.168.100.151 9042
```

```sql
SELECT * FROM formation.employes;
```

Résultat attendu : les 4 lignes insérées à l'étape 3 sont de nouveau présentes.

---

## Étape 11 — Informations sur la dernière sauvegarde

```bash
docker exec cassandra01 medusa report-last-backup
```

Résultat attendu :

```
[INFO] Latest node backup finished XXXXX seconds ago
[INFO] Latest complete backup:
[INFO] - Name: sauvegarde_full
[INFO] - Finished: XXXXX seconds ago
[INFO] Latest backup:
[INFO] - Name: sauvegarde_full
[INFO] - Complete backup: 4 nodes have completed the backup
[INFO] - Total size: X.XX MB
[INFO] - Total files: XXXX
```

---

## Étape 12 — Gestion du cycle de vie des sauvegardes

### 12.1 Supprimer une sauvegarde spécifique

```bash
# Supprimer la sauvegarde "sauvegarde_initiale" sur le nœud courant
docker exec cassandra01 medusa delete-backup --backup-name=sauvegarde_initiale

# Répéter sur chaque nœud pour une suppression globale
docker exec cassandra02 medusa delete-backup --backup-name=sauvegarde_initiale
docker exec cassandra03 medusa delete-backup --backup-name=sauvegarde_initiale
docker exec cassandra04 medusa delete-backup --backup-name=sauvegarde_initiale
```

> Pour forcer la suppression immédiate des fichiers (sans attendre le délai de grâce de 10 jours) :
```bash
docker exec cassandra01 medusa \
  --backup-grace-period-in-days=0 \
  delete-backup --backup-name=sauvegarde_initiale
```

### 12.2 Purger les sauvegardes obsolètes

La purge supprime automatiquement les sauvegardes selon les règles `max_backup_age` et `max_backup_count` du medusa.ini.

```bash
docker exec cassandra01 medusa purge
```

---

## Étape 13 — Automatisation avec cron (optionnel)

Pour automatiser les sauvegardes quotidiennes, créer un script sur l'hôte :

```bash
cat > ${PWD}/backup_cluster.sh << 'SCRIPT'
#!/bin/bash
BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S)"
echo "=== Démarrage sauvegarde cluster : ${BACKUP_NAME} ==="

for NODE in cassandra01 cassandra02 cassandra03 cassandra04; do
  echo "--- Sauvegarde ${NODE} ---"
  docker exec ${NODE} medusa backup --backup-name=${BACKUP_NAME}
  if [ $? -eq 0 ]; then
    echo "✓ ${NODE} : succès"
  else
    echo "✗ ${NODE} : ÉCHEC"
  fi
done

echo "=== Vérification de la sauvegarde ==="
docker exec cassandra01 medusa verify --backup-name=${BACKUP_NAME}

echo "=== Liste des sauvegardes disponibles ==="
docker exec cassandra01 medusa list-backups --show-all

echo "=== Sauvegarde ${BACKUP_NAME} terminée ==="
SCRIPT

chmod +x ${PWD}/backup_cluster.sh
```

Ajouter une entrée cron pour une exécution quotidienne à 2h00 :

```bash
crontab -e
# Ajouter la ligne suivante :
# 0 2 * * * /chemin/complet/vers/backup_cluster.sh >> /var/log/cassandra_backup.log 2>&1
```

---

## Récapitulatif des commandes Medusa

| Commande | Description |
|---|---|
| `medusa backup --backup-name=NOM` | Sauvegarde différentielle du nœud local |
| `medusa backup --backup-name=NOM --mode=full` | Sauvegarde complète du nœud local |
| `medusa list-backups --show-all` | Lister toutes les sauvegardes |
| `medusa verify --backup-name=NOM` | Vérifier l'intégrité d'une sauvegarde |
| `medusa status --backup-name=NOM` | Résumé de l'état d'une sauvegarde |
| `medusa report-last-backup` | Informations sur la dernière sauvegarde |
| `medusa restore-node --backup-name=NOM` | Restaurer le nœud local |
| `medusa restore-node --backup-name=NOM --keyspace=KS` | Restaurer un keyspace spécifique |
| `medusa delete-backup --backup-name=NOM` | Supprimer une sauvegarde sur le nœud local |
| `medusa purge` | Purger les sauvegardes obsolètes |

---

## Points d'attention

**Persistance de l'installation :** L'installation pip3 dans le conteneur n'est pas persistée. Pour un environnement pérenne, créer un `Dockerfile` personnalisé basé sur `cassandra:latest` avec Medusa pré-installé.

**JMX et LOCAL_JMX=no :** Le cluster est configuré en mode JMX distant. Medusa se connecte via `nodetool_host` (l'IP du conteneur) et `nodetool_port = 7199`. Si nodetool ne répond pas, vérifier que les ports JMX sont bien accessibles depuis l'intérieur du conteneur.

**Chemin du cassandra.yaml :** Le volume `conf0X` monte la configuration Cassandra dans `/opt/cassandra/conf/`. Le paramètre `config_file` de medusa.ini doit pointer vers ce chemin.

**Sauvegarde cluster complète :** La commande `medusa backup-cluster` orchestre les sauvegardes de tous les nœuds via SSH. Dans un contexte Docker sans SSH configuré entre conteneurs, on préférera appeler `medusa backup` nœud par nœud comme illustré dans ce TP, ou scripter l'appel depuis l'hôte (Étape 13).

**Espace disque :** Les sauvegardes locales consomment de l'espace sur la machine hôte. Surveiller `${PWD}/docker/medusa_sauvegarde/` et configurer `max_backup_count` dans medusa.ini pour maîtriser la rétention.
