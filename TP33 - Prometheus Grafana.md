## TP33 - Prometheus Grafana

Cassandra 5.0 avec Docker Compose (Cluster 4 nœuds)

https://github.com/crystalloide/cassandra-tp00

Cluster Cassandra déployé via Docker Compose avec 4 nœuds sur 2 racks différents dans 2 datacenters.



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
cat Cluster_4_noeuds_2_racks_2_DC_Prometheus_Grafana.yml
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
docker compose -f Cluster_4_noeuds_2_racks_2_DC_Prometheus_Grafana.yml up  -d
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