## TP00a - Cassandra 5.0 avec Docker Compose (Cluster 4 nœuds) : environnement uniquement sans utilisation CQL

Cassandra 5.0 avec Docker Compose (Cluster 4 nœuds)

https://github.com/crystalloide/cassandra-tp00

Cluster Cassandra déployé via Docker Compose avec 4 nœuds sur 4 racks différents dans un seul datacenter DC1.

#### Vue d'ensemble du cluster

Le fichier `Cluster_4_noeuds_4_racks_1_DC.yml` déploie :

- **4 nœuds Cassandra** : cassandra01, cassandra02, cassandra03, cassandra04
- **1 datacenter** : DC1
- **4 racks** : Rack1, Rack2, Rack3, Rack4
- **Seeds** : cassandra01 et cassandra03
- **Réseau** : 192.168.100.0/24


#### Prérequis

- Docker et Docker Compose installés
- Au minimum 4 GB RAM disponible (1 GB par nœud)
- 2 CPU cores disponibles


#### Démarrage du cluster

#### Étape 1 : Préparation de l'environnement

```bash
cd ~
sudo rm -Rf ~/cassandra-tp00

#### Ici, on va simplement cloner le projet :
git clone https://github.com/crystalloide/cassandra-tp00

cd ~/cassandra-tp00
```
#### Vérifier le contenu ou créer le fichier docker compose de notre cluster 4 noeuds cassandra :
```bash
cat Cluster_4_noeuds_4_racks_1_DC.yml
```
#### Le fichier doit avoir le contenu suivant : 
```bash
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
    environment:
      - CASSANDRA_CLUSTER_NAME=formation
      - CASSANDRA_SEEDS=cassandra01,cassandra03
      - CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
      - CASSANDRA_DC=dc1
      - CASSANDRA_RACK=Rack1
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
    environment:
      - CASSANDRA_CLUSTER_NAME=formation
      - CASSANDRA_SEEDS=cassandra01,cassandra03
      - CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
      - CASSANDRA_DC=dc1
      - CASSANDRA_RACK=Rack2
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
    environment:
      - CASSANDRA_CLUSTER_NAME=formation
      - CASSANDRA_SEEDS=cassandra01,cassandra03
      - CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
      - CASSANDRA_DC=dc1
      - CASSANDRA_RACK=Rack3
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
    environment:
      - CASSANDRA_CLUSTER_NAME=formation
      - CASSANDRA_SEEDS=cassandra01,cassandra03
      - CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
      - CASSANDRA_DC=dc1
      - CASSANDRA_RACK=Rack4
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
```
#### Fin du fichier

#### Copier le fichier docker compose :
```bash
sudo rm docker-compose.yml
cp Cluster_4_noeuds_4_racks_1_DC.yml docker-compose.yml
```
#### Créer les répertoires de volumes :
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

#### Étape 2 : Démarrage du cluster avec Docker Compose

```bash
# Démarrer le cluster en arrière-plan
docker compose -f docker-compose.yml up  -d
```
#### Suivre les logs pour vérifier le démarrage (dans un autre terminal si besoin)
```bash
cd ~/cassandra-tp00
docker compose logs -f
```
##### Faire **\<CTRL>+\<C>** pour sortir

#### Dans un autre terminal, pour suivre  :
```bash
cd ~
docker ps -a 
```
#### Affichage (exemple) ': 
```bash
# 
# CONTAINER ID   IMAGE              COMMAND                  CREATED              STATUS                             PORTS                                                                                                                                                       NAMES
# 439bcb49160a   cassandra:latest   "docker-entrypoint.s…"   About a minute ago   Created                                                                                                                                                                                        cassandra04
# 7dd3d0d2bf79   cassandra:latest   "docker-entrypoint.s…"   About a minute ago   Created                                                                                                                                                                                        cassandra03
# cefc35985646   cassandra:latest   "docker-entrypoint.s…"   About a minute ago   Up 14 seconds (health: starting)   7001/tcp, 9160/tcp, 0.0.0.0:7200->7000/tcp, [::]:7200->7000/tcp, 0.0.0.0:7299->7199/tcp, [::]:7299->7199/tcp, 0.0.0.0:9242->9042/tcp, [::]:9242->9042/tcp   cassandra02
# 1e6d94687116   cassandra:latest   "docker-entrypoint.s…"   About a minute ago   Up About a minute (healthy)        7001/tcp, 9160/tcp, 0.0.0.0:7199->7199/tcp, [::]:7199->7199/tcp, 0.0.0.0:7100->7000/tcp, [::]:7100->7000/tcp, 0.0.0.0:9142->9042/tcp, [::]:9142->9042/tcp   cassandra01
```

**Note** : Le démarrage complet peut prendre 5-10 minutes car les nœuds démarrent séquentiellement avec healthchecks. L'ordre de démarrage est :

1. cassandra01 (1er seed, peut démarrer en 1er)
2. cassandra02 (attend cassandra01 healthy)
3. cassandra03 (2ème seed, attend cassandra02 healthy)
4. cassandra04 (attend cassandra03 healthy)


#### Pour visualiser les logs de cassandra01 : 
```bash
docker logs cassandra01
```

#### Étape 3 : Vérification du cluster (après 5-10 minutes)

#### Regarder les ports à l'écoute :
```bash
netstat -anl | grep 0:
```

#### Vérifier que les 4 conteneurs sont UP sinon attendre (non listé ou encore en train de joindre : 'UJ')
```bash
cd /home/user/cassandra-tp00
docker compose ps
```

#### Vérifier le statut du cluster via nodetool
```bash
docker exec -it cassandra01 nodetool status
```
#### Vous devriez voir finalement les 4 nœuds cassandra avec le statut "UN" (Up Normal)
#### Le résultat devrait ressembler à :

```bash
Datacenter: dc1
===============
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address          Load        Tokens  Owns (effective)  Host ID                               Rack
UN  192.168.100.154  80.06 KiB   16      52.0%             6747a2fb-3f5a-4342-91b5-1f1d177366af  Rack4
UN  192.168.100.151  119.82 KiB  16      48.5%             e2efa530-2ac0-4957-8827-60860279295b  Rack1
UN  192.168.100.152  80.06 KiB   16      48.8%             955ae8dc-40f6-4c7c-a534-4f99af4af5de  Rack2
UN  192.168.100.153  80.03 KiB   16      50.7%             21b3ae41-1e2a-4c7d-97d7-bcca250c85df  Rack3
```


#### Accès à cqlsh :

#### Option 1 : Via Docker exec (recommandé)
#### Se connecter à cqlsh sur cassandra01 :
```bash
docker exec -it cassandra01 cqlsh
```

#### Pour sortir du shell :
```bash
exit 
```

#### Ou spécifier l'adresse IP :
```bash
docker exec -it cassandra01 cqlsh 192.168.100.151 9042
```

#### Option 2 : Depuis l'hôte (via ports exposés)

Les ports CQL sont exposés sur l'hôte :

- cassandra01 : localhost:9142
- cassandra02 : localhost:9242
- cassandra03 : localhost:9342
- cassandra04 : localhost:9442

```bash
# Si cqlsh est installé sur votre machine hôte
cqlsh localhost 9142
```

#### Si on veut absolument accéder via CQLSH à partir de la machine hôte sans passer par docker :
#### Installer pyenv si ce n'est pas déjà fait
```bash
curl https://pyenv.run | bash
```
#### Ajouter pyenv au PATH (ajouter à ~/.bashrc)
```bash
gedit ~/.bashrc
```
#### Ajouter tout à la fin : 
```bash
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
```
#### Sauvegarder et quitter

#### Recharger le shell
```bash
source ~/.bashrc
```
#### Installer Python 3.11.7 :
```bash
pyenv install 3.11.7
```

#### Créer un environnement virtuel pour cqlsh :
```bash
pyenv virtualenv 3.11.7 cqlsh-env
pyenv activate cqlsh-env
```
#### Actualisation : 
```bash
python -m pip install --upgrade pip
```
#### Installer cqlsh dans cet environnement :
```bash
pip install cqlsh
```
#### Vérification :
```bash
python --version
```
#### Affichage en retour :  
```bash
Python 3.11.7
```
#### Maintenant, on va lancer cqlsh :
```bash
cqlsh localhost 9142
```

#### Et pour les prochaines fois, il n'y aura besoin que de faire  : 
#### Activer l'environnement
```bash
pyenv activate cqlsh-env
```
#### Lancer cqlsh
```bash
cqlsh localhost 9142
```