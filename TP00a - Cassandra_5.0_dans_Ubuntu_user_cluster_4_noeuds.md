## TP00 - Cassandra 5.0 avec Docker Compose (Cluster 4 nœuds)

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

#### Ici, on va simpleemnt cloner le projet :
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
    - ~/cassandra-tp00/docker/cassandra01:/var/lib/cassandra
    environment:
      - CASSANDRA_CLUSTER_NAME=formation
      - CASSANDRA_SEEDS=cassandra01,cassandra03
      - CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
      - CASSANDRA_DATACENTER=DC1
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
      test:
      - CMD-SHELL
      - grep -q "Startup complete" /var/log/cassandra/system.log
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
    - ~/cassandra-tp00/docker/cassandra02:/var/lib/cassandra
    environment:
      - CASSANDRA_CLUSTER_NAME=formation
      - CASSANDRA_SEEDS=cassandra01,cassandra03
      - CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
      - CASSANDRA_DATACENTER=DC1
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
      test:
      - CMD-SHELL
      - grep -q "Startup complete" /var/log/cassandra/system.log
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
    - ~/cassandra-tp00/docker/cassandra03:/var/lib/cassandra
    environment:
      - CASSANDRA_CLUSTER_NAME=formation
      - CASSANDRA_SEEDS=cassandra01,cassandra03
      - CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
      - CASSANDRA_DATACENTER=DC1
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
      test:
      - CMD-SHELL
      - grep -q "Startup complete" /var/log/cassandra/system.log
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
    - ~/cassandra-tp00/docker/cassandra04:/var/lib/cassandra
    environment:
      - CASSANDRA_CLUSTER_NAME=formation
      - CASSANDRA_SEEDS=cassandra01,cassandra03
      - CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
      - CASSANDRA_DATACENTER=DC1
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
      test:
      - CMD-SHELL
      - grep -q "Startup complete" /var/log/cassandra/system.log
      interval: 15s
      timeout: 10s
      retries: 50
      start_period: 180s
```
#### Fin du fichier

#### Copier le fichier docker compose
```bash
sudo rm docker-compose.yml
cp Cluster_4_noeuds_4_racks_1_DC.yml docker-compose.yml
```
#### Créer les répertoires de volumes (optionnel)
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

#### Affichage : cassandra01  cassandra02  cassandra03  cassandra04
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

#### Exercices CQL avec données IMDB

#### 1. Création du keyspace formation
```sql
DROP KEYSPACE IF EXISTS formation;

CREATE KEYSPACE formation 
WITH replication = {
  'class': 'NetworkTopologyStrategy', 
  'dc1': 3
};

USE formation;

DESCRIBE formation;

```

#### la commande DESCRIBE devrait afficher :  
CREATE KEYSPACE formation WITH replication = {'class': 'NetworkTopologyStrategy', 'dc1': '3'}  AND durable_writes = true;

**Note** : 
Nous utilisons `NetworkTopologyStrategy`, avec un facteur de réplication de 3 pour le datacenter "dc1", 
`NetworkTopologyStrategy` est conseillé en production (cluster multi-rack et multi-datacenter)

#### 2. Création de la TABLE formation.imdb

```sql
DROP TABLE IF EXISTS formation.imdb;

CREATE TABLE formation.imdb (
  movie_id TEXT PRIMARY KEY,
  title TEXT,
  year INT,
  genre TEXT,
  director TEXT,
  rating DOUBLE,
  votes INT,
  budget TEXT,
  length INT
);

DESCRIBE TABLE formation.imdb;
```

#### 3. Chargement de films

#### Insertion manuelle de quelques films

```sql
-- Film 1
INSERT INTO formation.imdb (movie_id, title, year, genre, director, rating, votes, budget, length) 
VALUES ('1', 'The Shawshank Redemption', 1994, 'Drama', 'Frank Darabont', 9.3, 2500000, '25000000', 142);

-- Film 2
INSERT INTO formation.imdb (movie_id, title, year, genre, director, rating, votes, budget, length) 
VALUES ('2', 'The Godfather', 1972, 'Crime', 'Francis Ford Coppola', 9.2, 1800000, '6000000', 175);

-- Film 3
INSERT INTO formation.imdb (movie_id, title, year, genre, director, rating, votes, budget, length) 
VALUES ('3', 'The Dark Knight', 2008, 'Action', 'Christopher Nolan', 9.0, 2600000, '185000000', 152);

-- Film 4
INSERT INTO formation.imdb (movie_id, title, year, genre, director, rating, votes, budget, length) 
VALUES ('4', 'Pulp Fiction', 1994, 'Crime', 'Quentin Tarantino', 8.9, 2000000, '8000000', 154);

-- Film 5
INSERT INTO formation.imdb (movie_id, title, year, genre, director, rating, votes, budget, length) 
VALUES ('5', 'Forrest Gump', 1994, 'Drama', 'Robert Zemeckis', 8.8, 2100000, '55000000', 142);

-- Film 6
INSERT INTO formation.imdb (movie_id, title, year, genre, director, rating, votes, budget, length) 
VALUES ('6', 'Inception', 2010, 'Sci-Fi', 'Christopher Nolan', 8.8, 2300000, '160000000', 148);

-- Film 7
INSERT INTO formation.imdb (movie_id, title, year, genre, director, rating, votes, budget, length) 
VALUES ('7', 'The Matrix', 1999, 'Sci-Fi', 'Wachowski Brothers', 8.7, 1900000, '63000000', 136);

-- Film 8
INSERT INTO formation.imdb (movie_id, title, year, genre, director, rating, votes, budget, length) 
VALUES ('8', 'Goodfellas', 1990, 'Crime', 'Martin Scorsese', 8.7, 1200000, '25000000', 146);

-- Film 9
INSERT INTO formation.imdb (movie_id, title, year, genre, director, rating, votes, budget, length) 
VALUES ('9', 'Fight Club', 1999, 'Drama', 'David Fincher', 8.8, 2100000, '63000000', 139);

-- Film 10
INSERT INTO formation.imdb (movie_id, title, year, genre, director, rating, votes, budget, length) 
VALUES ('10', 'Interstellar', 2014, 'Sci-Fi', 'Christopher Nolan', 8.6, 1800000, '165000000', 169);

-- On sort de CQLSH pour le moment : 
EXIT;
```


#### Chargement en masse avec COPY

Pour charger des films, allons récupérer les fichiers CSV sur votre machine hôte :

**Fichier : imdb_movies.csv**   https://www.kaggle.com/datasets/hoomch/imdb-full-dataset

#### Conseil : on utilise gdown : 
```bash
pip install gdown
```
#### Les fichiers sont disponibles aussi dans Google Drive : 

#### imdb_movies_extrait.csv (14,3 Ko)
```bash
gdown 1KZdUmJkw-dlihqlrQWrR56qVcqzmUrmI
```
#### IMDB_movies.zip (197 Mo)
```bash
gdown 1q6v-PEHu8UYfDONajVujqoTTGhRUAPHl
```
#### imdb_movies.csv (362 Mo)
```bash
gdown 16uJWq5N465U9rYvTCR1lKIBPHeNfd-oK
```
#### Voici un extrait de imdb_movies.csv :
```csv
movie_id,title,year,genre,director,rating,votes,budget,length
"11","The Lord of the Rings",2001,"Fantasy","Peter Jackson",8.8,1800000,"93000000",178
"12","Star Wars",1977,"Sci-Fi","George Lucas",8.6,1400000,"11000000",121
...
```

#### Nous allons charger des fichiers de données en .csv dans un des 4 conteneurs et ensuite charger ces données dans le cluster cassandra :

#### Copier les fichiers CSV dans le conteneur cassandra01 qui nous servira de passerelle pour les charger ensuite dans le cluster Cassandra :
```bash
docker cp imdb_movies.csv cassandra01:/tmp/imdb_movies.csv
docker cp imdb_movies_extrait.csv cassandra01:/tmp/imdb_movies_extrait.csv
```

#### # 1°) Affichage du contenu en local du conteneur cassandra01 pour le fichier imdb_movies.csv : 
```bash
docker exec -it cassandra01 tail -5 /tmp/imdb_movies.csv
```
#### Affichage en retour de 5 lignes :   
```bash
	tt14330672,Goodbye Julia,Goodbye Julia,2020-01-01,2020.0,,0.0,,0.0,0.0,wridir_not_provided,wridir_not_provided,story_line_not_provided,Issraa El-Kogali,Drama,"Sudan,Sweden",Arabic,,,,,Station Films,,,,0.9955575702629192,/name/nm4754706/,0,0,0,1.0,1.0,keys_not_provided
	tt14337116,Macbeth,Macbeth,2020-01-01,2020.0,,0.0,,0.0,0.0,wridir_not_provided,wridir_not_provided,story_line_not_provided,Sergei Tsimbalenko,Drama,Russia,Russian,$10000,,,,company_not_provided,10000.0,,,0.9955575702629192,/name/nm12440622/,0,0,0,1.0,1.0,keys_not_provided
	tt14325500,Les fantômes du sanatorium,Les fantômes du sanatorium,2020-01-01,2020.0,,0.0,,0.0,0.0,wridir_not_provided,wridir_not_provided,story_line_not_provided,casts_not_provided,genre_not_provided,France,French,,,,59.0,Les Films-Cabanes,,,,0.9955575702629192,castIDs_not_provided,0,0,0,1.0,1.0,keys_not_provided
	tt14332642,Predators,Khishchniki,2021-02-18,2020.0,,0.0,,0.0,0.0,wridir_not_provided,wridir_not_provided,"An ambitious personal growth coach, author of the Predator Psychology manual, unexpectedly finds himself drawn into a confrontation with a millionaire who wants to demolish the garage complex where he keeps his Jaguar.","Elena Babenko,Sergey Byzgu,Irina Osnovina,Arseny Popov,Aleksey Shevchenkov,Vladimir Sychyov,Alan Tomaev,Ekaterina Zorina,Oksana Bazilevich,Fyodor Lavrov,Andrey Pogrebinskiy,Maxim Sevrinovsky,Sergey Styopin,Oleg Taktarov,Yuliya Topolnitskaya","Comedy,Crime",Russia,Russian,,,,88.0,"Taganka Film,Zebra Film",,,,0.9955575702629192,"/name/nm1461130/,/name/nm1531240/,/name/nm0652148/,/name/nm12439283/,/name/nm1169445/,/name/nm0842962/,/name/nm9989842/,/name/nm6864539/,/name/nm1480626/,/name/nm1655031/,/name/nm11159329/,/name/nm12439282/,/name/nm2672605/,/name/nm0847727/,/name/nm8290348/",0,0,0,2.0,18.0,keys_not_provided
	tt14331300,Nareul guhaji maseyo,Nareul guhaji maseyo,2020-09-10,2020.0,,0.0,,0.0,0.0,wridir_not_provided,wridir_not_provided,story_line_not_provided,"Seo-Yun Cho,Hwi-Jong Lee,So-min Yang,Ro-Woon Choi,Seon-hee Lee",Drama,South Korea,Korean,,,,93.0,Aura Pictures,,,,0.9955575702629192,"/name/nm12438883/,/name/nm12438884/,/name/nm1789399/,/name/nm6857341/,/name/nm3786371/",0,0,0,9.0,10.0,keys_not_provided
```

#### # 2°) Affichage du contenu en local du conteneur cassandra01 pour le fichier imdb_movies_extrait.csv : 

##### Affichage en retour des 5 premières lignes :
```bash
docker exec -it cassandra01 tail -5 /tmp/imdb_movies_extrait.csv
```
##### Affichage en retour des 5 dernières lignes :
```bash
	196,Hachi: A Dog's Tale,2009,Drama,Lasse Hallström,8.1,300000,16000000,93
	197,Incendies,2010,Drama,Denis Villeneuve,8.3,180000,6800000,131
	198,Wild Tales,2014,Comedy,Damián Szifron,8.1,200000,3300000,122
	199,The 400 Blows,1959,Drama,François Truffaut,8.1,120000,75000,99
	200,Catch Me If You Can,2002,Crime,Steven Spielberg,8.1,1000000,52000000,141
```
##### Affichage des 5 premières lignes :   
```bash
docker exec -it cassandra01 head -5 /tmp/imdb_movies.csv
```
##### Affichage en retour des 5 premières lignes :
```bash
movie_id,name,org_name,date,title_year,point,point_volume,metascore,user_reviews,critic_reviews,director,writer,story_line,cast,genres,country,language,budget,world_gross,usa_gross,runtime,production_companies,dollar_budget,w_gross_money,u_gross_money,inflation_coeff,casts_id,BlogPage,CompPage,HomePage,release_month,release_day,keywords
tt0000009,Miss Jerry,Miss Jerry,1894-10-09,1894.0,5.9,154.0,,1.0,2.0,Alexander Black,Alexander Black,"Geraldine (Jerry) Holbrook, a girl of Eastern birth, decides to start a career in journalism in the heart of New York, after she feels that her father is close to a financial crush. In the process she falls in love with the editor of her paper, Mr. Hamilton. After the first successful article, she leads Hamilton into doubting her love for him, and this makes him accept a job in London. But his worries prove wrong when Jerry accepts to marry him and leave to London.","Blanche Bayliss,Chauncey Depew,William Courtenay",Romance,USA,English,,,,45.0,Alexander Black Photoplays,,,,,castIDs_not_provided,0,0,0,10.0,9.0,"character-name-as-title,two-word-title,nickname-as-title,photoplay,reporter,editor,lost-film"
tt0000147,The Corbett-Fitzsimmons Fight,The Corbett-Fitzsimmons Fight,1897-05-22,1897.0,5.2,356.0,,4.0,0.0,wridir_not_provided,wridir_not_provided,"This legendary fight was filmed on March 17, 1897, using 63mm film that produced an aspect ratio of about 1.75:1. Using three adjacent cameras, Enoch Rector recorded the entire fight, simultaneously creating the world's first known feature film, as the resulting footage lasted over 90 minutes in length. About a quarter of the film survives today.","James J. Corbett,Billy Madden,John L. Sullivan,Bob Fitzsimmons,George Siler","Documentary,News,Sport",USA,English,,,,20.0,Veriscope Company,,,,,castIDs_not_provided,0,0,0,5.0,22.0,"national-film-registry,first-of-its-kind,partially-lost-film,year-1897,1890s,19th-century,bare-chested-male,boxing"
tt0000335,Soldiers of the Cross,Soldiers of the Cross,1900-09-13,1900.0,6.1,41.0,,1.0,0.0,wridir_not_provided,wridir_not_provided,"The plot outlined the story of the early Christian martyrs with a compendium of horrors guaranteed to jolt audiences into an awareness of terrible suffering for the sake of Christianity. Contained maulings at the Colosseum, crucifixions, beheadings, savage hackings and burnings at the stake, burnings in the limepit, the spectacle of human torches in Nero's garden. Overall ""soul stirring stories of the martyrs, illustrated by the most beautiful living pictures by kinematograph and limelight and never before witnessed in this or any other country.","Beatrice Day,Mr. Graham,Orrie Perry,Harold Graham,John Jones,Reg Perry","Biography,Drama",Australia,English,,,,,"Limelight Department of the Salvation Army, Melbourne,Salvation Army",,,,31.374285714285712,castIDs_not_provided,0,0,0,9.0,13.0,keys_not_provided
tt0000502,Bohemios,Bohemios,1905-01-01,1905.0,3.8,6.0,,0.0,0.0,wridir_not_provided,"Ricardo de Baños,Miguel de Palacios",story_line_not_provided,"Antonio del Pozo,El Mochuelo",genre_not_provided,Spain,Spanish,,,,100.0,Gaumont Española,,,,29.678378378378376,castIDs_not_provided,0,0,0,1.0,1.0,keys_not_provided
```
	
#### On se connecte  à cqlsh sur le conteneur cassandra01 :
```bash
docker exec -it cassandra01 cqlsh
```
#### Dans cqlsh, et on charge les données :
```bash
COPY formation.imdb (movie_id, title, year, genre, director, rating, votes, budget, length) 
FROM '/tmp/imdb_movies_extrait.csv' 
WITH HEADER = TRUE AND DELIMITER = ',';
```

#### 4. Qualques requêtes :

```sql
-- Compter le nombre total de films :
SELECT COUNT(*) FROM formation.imdb;
```

```sql
-- Lecture des 10 premiers films :
SELECT * FROM formation.imdb LIMIT 100;
```

```sql
-- Requêter un film avec un id précis  :
SELECT * FROM formation.imdb WHERE movie_id = '1';
SELECT * FROM formation.imdb WHERE movie_id = '200';
```

```sql
-- Afficher seulement certaines colonnes :
SELECT title, year, rating, director FROM formation.imdb LIMIT 10;
```

```sql
-- extrait de 15 des meilleurs films :
SELECT title, rating, year, director 
FROM formation.imdb 
WHERE rating >= 8.8 
LIMIT 15
ALLOW FILTERING;
```

```sql
-- Créer un index secondaire sur l'année :
CREATE INDEX IF NOT EXISTS idx_year ON formation.imdb(year);
```

```sql
-- Recherche par année :
SELECT title, year, rating, director 
FROM formation.imdb 
WHERE year = 1994 
ALLOW FILTERING;
```

```sql
-- Créer un index sur le genre :
CREATE INDEX IF NOT EXISTS idx_genre ON formation.imdb(genre);
```

```sql
-- Films par genre :
SELECT title, genre, rating, director
FROM formation.imdb 
WHERE genre = 'Drama' 
ALLOW FILTERING;
```

```sql
-- Films par genre pour une année précise : 
SELECT title, genre, rating, director
FROM formation.imdb 
WHERE genre = 'Drama' AND year= 2014
ALLOW FILTERING;
```

```sql
-- Films Sci-Fi
SELECT title, year, rating 
FROM formation.imdb 
WHERE genre = 'Sci-Fi' 
ALLOW FILTERING;
```


#### 5. Modification de films

```sql
-- Mise à jour du rating d'un film
UPDATE formation.imdb SET rating = 9.4 WHERE movie_id = '1';
```

```sql
-- Vérification de la modification
SELECT title, rating FROM formation.imdb WHERE movie_id = '1';
```

```sql
-- Mise à jour de plusieurs colonnes
UPDATE formation.imdb 
SET rating = 9.1, votes = 2700000 
WHERE movie_id = '3';
```

```sql
-- Ajout d'une nouvelle colonne à la table
ALTER TABLE formation.imdb ADD country TEXT;
```

```sql
-- Mise à jour avec la nouvelle colonne
UPDATE formation.imdb SET country = 'USA' WHERE movie_id = '1';
UPDATE formation.imdb SET country = 'USA' WHERE movie_id = '2';
UPDATE formation.imdb SET country = 'UK' WHERE movie_id = '3';
```

```sql
-- Vérification
SELECT title, country FROM formation.imdb WHERE movie_id IN ('1','2','3') ALLOW FILTERING;
```


#### 6. Suppression de films

```sql
-- Suppression d'un film spécifique
DELETE FROM formation.imdb WHERE movie_id = '4';
```

```sql
-- Vérification de la suppression
SELECT * FROM formation.imdb WHERE movie_id = '4';
```

```sql
-- Suppression de plusieurs films (une par une en Cassandra)
DELETE FROM formation.imdb WHERE movie_id = '6';
DELETE FROM formation.imdb WHERE movie_id = '7';
```

```sql
-- Suppression d'une colonne spécifique (mise à NULL)
UPDATE formation.imdb SET budget = NULL WHERE movie_id = '1';
```

```sql
-- Vérification
SELECT title, budget FROM formation.imdb WHERE movie_id = '1';
```


#### 7. Requêtes avancées et statistiques

```sql
-- Comptage total de films
SELECT COUNT(*) FROM formation.imdb;
```

```sql
-- Films avec les meilleures notes (> 8.5)
SELECT title, rating, year, genre 
FROM formation.imdb 
WHERE rating > 8.5 
ALLOW FILTERING;
```

```sql
-- Films récents (après 2000)
SELECT title, year, rating, director 
FROM formation.imdb 
WHERE year > 2000 
ALLOW FILTERING;
```

```sql
-- Créer un index sur le réalisateur
CREATE INDEX IF NOT EXISTS idx_director ON formation.imdb(director);
```

```sql
-- Films de Christopher Nolan
SELECT title, year, rating 
FROM formation.imdb 
WHERE director = 'Christopher Nolan' 
ALLOW FILTERING;
```


#### 8. Commandes de maintenance et diagnostic

```sql
-- Afficher la structure de la table
DESCRIBE TABLE formation.imdb;
```

```sql
-- Afficher tous les keyspaces ( ~ databases, et porte en + la notion de réplication mono ou multi-DC)
DESCRIBE KEYSPACES;
```

```sql
-- Efface pour y voir plus clair
CLEAR
```

```sql
-- Afficher le schéma complet du keyspace
DESCRIBE KEYSPACE formation;
```

```sql
-- Vérifier le niveau de cohérence actuel
CONSISTENCY;
```

```sql
-- Changer le niveau de cohérence
CONSISTENCY QUORUM;
CONSISTENCY ONE;
CONSISTENCY ALL;
```

```sql
-- Active le tracing sur le noeud où est connecté le client CQLSH pour voir le détail des étapes d'exécution des requêtes
TRACING ON;
SELECT * FROM formation.imdb WHERE movie_id = '1';
TRACING OFF;
```

```sql
-- Afficher les informations de pagination
PAGING 10;
SELECT * FROM formation.imdb;
```

```sql
-- On sort maintenant du CQLSH pour pouvoir arrêter des noeuds Cassandra et voir les effets :
EXIT;
```

#### 9. Exercices supplémentaires avec le cluster

#### Tester la réplication et la tolérance aux pannes :

##### On va maintenant arrêter un nœud :
```bash
# Arrêt du nœud cassandra02 :
docker stop cassandra02
```

#### Retourner dans cqlsh 
```bash
docker exec -it cassandra01 cqlsh

```

#### et vérifier que les requêtes fonctionnent toujours :
#### (avec CONSISTENCY QUORUM ou ONE)


```sql
CONSISTENCY QUORUM;
SELECT * FROM formation.imdb WHERE movie_id = '1';
```

```sql
CONSISTENCY ALL;
SELECT * FROM formation.imdb WHERE movie_id = '1';
```

```sql
CONSISTENCY QUORUM;
```

```sql
-- On sort maintenant du CQLSH pour lancer des commandes nodetool :
EXIT;
```

#### Vérifier le statut du cluster :
```bash
docker exec -it cassandra01 nodetool status
```

#### cassandra02 devrait apparaître comme "DN" (= Down Normal) :

#### Redémarrer le nœud :
```bash
docker start cassandra02
```

#### Attendre 60 secondes et vérifier à nouveau :
```bash
docker exec -it cassandra01 nodetool status
```

#### Vérifier la distribution des données

```bash
# Voir la distribution des tokens et des données
docker exec -it cassandra01 nodetool ring
```
#### Statistiques de chaque nœud :
```bash
docker exec -it cassandra01 nodetool info
```

```bash
docker exec -it cassandra02 nodetool info
```

```bash
docker exec -it cassandra03 nodetool info
```

```bash
docker exec -it cassandra04 nodetool info
```

#### Voir les métriques de performances :
```bash
docker exec -it cassandra01 nodetool tablestats formation.imdb
```


#### Commandes Docker Compose utiles ( => à ne pas faire ici, juste pour montrer)

##### Afficher les logs d'un nœud spécifique
```bash
#### Afficher les logs d'un nœud spécifique
docker compose logs -f cassandra01
#### Faire <CTRL>+>C> pour sortir
```

##### Arrêter le cluster :
```bash
docker compose down
```

##### Arrêter et supprimer les volumes (supprime toutes les données) :
```bash
docker compose down -v
```

##### Redémarrer le cluster :
```bash
docker compose restart
```

##### Voir l'utilisation des ressources :
```bash
docker stats cassandra01 cassandra02 cassandra03 cassandra04
```

##### Accès shell à un conteneur :
```bash
docker exec -it cassandra01 /bin/bash
```


#### Exercice avancé : on travaille désormais avec le fichier le plus complet : imdb_movies.csv

#### 1. Identifier les colonnes du fichier CSV
```bash
# Afficher la première ligne du fichier imdb_movies.csv
docker exec -it cassandra01 head -1 /tmp/imdb_movies.csv
```
#### Affichage en retour :
```bash
movie_id,name,org_name,date,title_year,point,point_volume,metascore,user_reviews,critic_reviews,director,writer,story_line,cast,genres,country,language,budget,world_gross,usa_gross,runtime,production_companies,dollar_budget,w_gross_money,u_gross_money,inflation_coeff,casts_id,BlogPage,CompPage,HomePage,release_month,release_day,keywords
```
#### On voit qu'il y a bcp trop d'information par rapport à notre table cible 
#### Malheureusement, la commande COPY de Cassandra ne permet pas de sélectionner des colonnes spécifiques du fichier CSV. 
#### Elle s'attend à ce que les colonnes du fichier correspondent exactement (dans l'ordre) aux colonnes spécifiées dans la commande.


#### L'utilitaire DSBulk permet le mapping de colonnes :
#### Récupération de l'utilitaire :
```bash
wget https://downloads.datastax.com/dsbulk/dsbulk-1.11.0.tar.gz
```

#### Copie dans le conteneur cassandra01 : 
```bash
docker cp dsbulk-1.11.0.tar.gz cassandra01:/tmp/dsbulk-1.11.0.tar.gz
```

#### Installer DSBulk dans le conteneur :
```bash
docker exec -it cassandra01 bash
```
```bash
cd /tmp
```
```bash
tar -xzf dsbulk-1.11.0.tar.gz
```
```bash
ls dsbulk-1.11.0/bin
```
```bash
export PATH=$PATH:/tmp/dsbulk-1.11.0/bin
```

#### Lancer l'import :
```bash
dsbulk load \
  -url /tmp/imdb_movies.csv \
  -k formation \
  -t imdb \
  -header true \
  -m "0=movie_id, 1=title, 4=year, 14=genre, 10=director, 5=rating, 6=votes, 17=budget, 20=length"
```

#### Si besoin de diagnostiquer les erreurs de chargement : les logs sont ici : (exemple à adapter à votre cas) :
##### : regardons avant le nom exact des fichiers disponibles dans notre cas : 
```bash
ls /tmp/logs/
```
```bash
cat /tmp/logs/LOAD_20260221-164858-592667/mapping-errors.log |grep Suppressed
```
```bash
cat /tmp/logs/LOAD_20260221-164858-592667/mapping-errors.log |grep InvalidMapping
```
```bash
cat /tmp/logs/LOAD_20260221-170143-031056/operation.log |grep Error
```
```bash
cat /tmp/logs/LOAD_20260221-172956-413471/connector-errors.log
```
```bash
cat /tmp/logs/LOAD_20260221-170143-031056/connector-errors.log |grep IllegalArgumentException
```
```bash
head -5 /tmp/logs/LOAD_20260221-172956-413471/connector-errors.log
```

#### Exemple de relance de l'import en entier : 
```bash
 dsbulk load \
  -url /tmp/imdb_movies.csv \
  -k formation \
  -t imdb \
  -header true \
  -m "0=movie_id, 1=title, 4=year, 14=genre, 10=director, 5=rating, 6=votes, 17=budget, 20=length"  \
  -escape '\"'  
```

#### Exemple de relance de l'import à partir du dernier arrêt :
```bash
dsbulk load \
  -url /tmp/imdb_movies.csv \
  -k formation \
  -t imdb \
  -header true \
  -m "0=movie_id, 1=title, 4=year, 14=genre, 10=director, 5=rating, 6=votes, 17=budget, 20=length" \
  -escape '\\"' \
  --connector.csv.maxCharsPerColumn 10000 \
  --dsbulk.log.checkpoint.file=/tmp/logs/LOAD_20260221-171717-693590/checkpoint.csv
```

#### Pour charger notre fichier, voici la commande complète :  
#### (~10% lignes en erreur pour des problèmes de format, échappement, etc)
#### A savoir : pour tester un chargement à blanc dans écrire les données : option --dryRun 
#### **https://docs.datastax.com/en/dsbulk/reference/schema-options.html**
```bash
dsbulk load \
  -url /tmp/imdb_movies.csv \
  -k formation \
  -t imdb \
  -header true \
  -m "0=movie_id, 1=title, 4=year, 14=genre, 10=director, 5=rating, 6=votes, 17=budget, 20=length" \
  --connector.csv.maxCharsPerColumn -1 \
  --connector.csv.normalizeLineEndingsInQuotes true \
  --continueOnError true \
  --log.maxErrors 30000
```

#### Synthèse du chargement : 

	total 	| failed | rows/s | p50ms | p99ms | p999ms | batches
	481,342 | 25,890 |  1,498 |  4.76 | 91.23 | 179.31 |    1.00
	
	Operation LOAD_20260221-174310-370255 completed with 25,890 errors in 5 minutes and 3 seconds.


	| ----------------- | ------------ | ------------------------------------------------------- |
	| Option            | Valeur HOCON | Signification                                           |
	| ----------------- | ------------ | ------------------------------------------------------- |
	| quote             | \"           | Caractère de quote = " datastax​                         |
	| escape            | \"           | Échappement des quotes internes par \\" github​          |
	| maxCharsPerColumn | 10000        | Limite champ = 10k caractères (pour keywords) datastax​  |
	| ----------------- | ------------ | ------------------------------------------------------- |


#### Paramètres essentiels

	--connector.csv.maxCharsPerColumn -1           		# Redimensionne dynamiquement (pas de limite fixe)
	--connector.csv.normalizeLineEndingsInQuotes true  	# \n → espace dans champs quotés
	--connector.csv.schema.allowExtraFields true    	# Ignore colonnes supplémentaires
	--connector.csv.quote '\"'                     		# Quote = "
	--connector.csv.escape '\"'                    		# Escape des quotes internes


#### Tolérance erreurs/performance

	--continueOnError true   		                   # Continue malgré erreurs
	--log.maxErrors 5000            	               # Tolère 5000 erreurs max
	--driver.threads 8                  	           # 8 threads parallèles (ajuste CPU)
	--batch.maxSize.rows 500                	       # Batch de 500 lignes


#### Comptage du nombre de ligne : 
```bash
dsbulk count -k formation -t imdb --dsbulk.log.dir /tmp/dsbulk-count
```
#### Affichage en retour : 
	Operation directory: /tmp/logs/COUNT_20260221-175434-996579
	total | failed | rows/s | p50ms |  p99ms | p999ms
	456,029 |      0 | 46,319 | 90.82 | 402.65 | 402.65


	
#### L'utilitaire DSBulk est intéressant car il n'est pas soumis au timeout que l'on recontre en CQL sur des requêtes trop lourdes : 	
#### DSBulk effectue l'opéraiton en la répartissant sous forme d'actions distinctes (multi-thread et multiples accès répartis sur le cluster) 

	| Aspect          | CQL COUNT(*)                | DSBulk count                                      |
	| --------------- | --------------------------- | ------------------------------------------------- |
	| Méthode         | Scan complet 1 requête      | Token range splitting (1000s requêtes parallèles) |
	| Coordinateur    | 1 node attend TOUS          | Round-robin + retries automatiques                |
	| Timeout         | range_request_timeout_in_ms | Configurable + heartbeat                          |
	| Perf 34k lignes | 1-5min (timeout)            | 5-10s                                             |
	| Parallélisme    | 1 thread                    | --driver.threads 8 auto                           |	


#### Si on veut augmenter temporairement et dynamiquenent sur un noeud cassandra la durée de timeout : 
```bash
nodetool settimeout read 120000
nodetool settimeout range 300000
```

#### Si on veut connaitres les seuils de timeout en cours sur un noeud cassandra : 
```bash
nodetool gettimeout read
nodetool gettimeout range
```

#### Poursuivons :  
###### On sort du conteneur : 
```bash
###### On sort du conteneur : 
exit
```
###### Et on recherche l'information telle qu'elle est codée dans cassandra.yaml d'un des noeuds (ici cassandra01) : 
```bash
docker exec -it cassandra01 cat /etc/cassandra/cassandra.yaml | grep 'read_request_timeout'
```

#### Afichage en retour : 
    read_request_timeout: 5000ms

#### On lance le client CQL : 
```bash
docker exec -it cassandra01 cqlsh
```

#### Nouvelles requêtes :  

```sql
-- Comptage total de films : ~40k+ lignes
SELECT COUNT(*) FROM formation.imdb ALLOW FILTERING;
```

```sql
SELECT movie_id, title, rating FROM formation.imdb LIMIT 5;
```

```sql
-- Films avec les meilleures notes (> 9.8)
SELECT title, rating, year, genre 
FROM formation.imdb 
WHERE rating > 9.8
ALLOW FILTERING;
```

```sql
-- Films récents (après 2024)
SELECT title, year, rating, director 
FROM formation.imdb 
WHERE year > 2024
ALLOW FILTERING;
```

```sql
-- Créer un index sur le réalisateur
CREATE INDEX IF NOT EXISTS idx_director ON formation.imdb(director);
```

```sql
-- Films de Ernst Lubitsch
SELECT title, year, rating 
FROM formation.imdb 
WHERE director = 'Ernst Lubitsch' 
ALLOW FILTERING;
```


#### Nettoyage de l'environnement :

##### Pour arrêter et supprimer tous les conteneurs et volumes :
```bash
docker compose down -v
```

##### Et pour -en plus- supprimer les répertoires de données persistés en local :
```bash
rm -rf docker/cassandra01 docker/cassandra02 docker/cassandra03 docker/cassandra04
```


#### Exercices pratiques recommandés

1. **Test de cohérence** : Insérer des données avec différents niveaux de cohérence (ONE, QUORUM, ALL) et observer les différences
2. **Tolérance aux pannes** : Arrêter progressivement 1, 2, puis 3 nœuds et observer le comportement
3. **Performance** : Insérer 1000 films et mesurer le temps avec `TRACING ON`
4. **Index secondaires** : Créer différents index et comparer les performances de requêtes
5. **Modélisation de données** : Créer une table supplémentaire pour les acteurs avec une clé composite

#### Ressources additionnelles

- Documentation officielle Cassandra : https://cassandra.apache.org/doc/latest/
- Guide CQL : https://cassandra.apache.org/doc/latest/cassandra/cql/
- Dataset IMDB : https://www.kaggle.com/datasets/hoomch/imdb-full-dataset
- Nodetool commands : https://cassandra.apache.org/doc/latest/cassandra/tools/nodetool/nodetool.html

***

**Remarques importantes** :

- Le cluster utilise NetworkTopologyStrategy qui est recommandé pour la production
- Les 4 racks permettent une meilleure résilience et distribution des données
- Les healthchecks garantissent un démarrage ordonné du cluster
- Le facteur de réplication de 3 assure la disponibilité même si un nœud tombe

Bon travail avec Cassandra ! 🚀

<div align="center">:-)</div>
