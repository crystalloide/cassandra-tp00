____
##### TP14 : Compaction
____

##### Dans ce TP, nous allons étudier les stratégies de base pour la compaction dans Cassandra
____
##### Contexte du TP : 
##### Au fur et à mesure que les MEMTABLEs se remplissent, Cassandra les écrit sur le disque sous la forme de SSTables.
##### Si c’était la fin de l’histoire, le nombre de fichiers de données utilisés 
##### pour contenir des tables SSTables deviendrait très important
##### et ralentirait les performances de lecture de Cassandra.
##### Par conséquent, Cassandra doit consolider ces fichiers de temps en temps.
##### Cette consolidation s'appelle la compaction.
##### Dans cet exercice, nous observons les effets de la compaction.

____
##### Etapes : 

____
##### 1°) Réinitialisation : 

```text
On doit avoir en pré-requis un cluster mono-noeud en cours d'éxécution 
C'est normalement déjà le cas, sinon exécuter les étapes suivantes 

```

##### Arrêt et démontage du cluster 
```bash
cd ~/cassandra-tp00
docker compose -f Cluster_3_noeuds_2_racks_2_DC.yml down -v
```


##### Recréer les répertoires de volumes :
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

##### 2°) Démarrage du cluster avec Docker Compose :

##### Démarrer le cluster mono-noeud en arrière-plan
```bash
docker compose -f Cluster_1_noeud_1_rack_1_DC.yml up  -d
```

#### Suivre les logs pour vérifier le démarrage (dans un autre terminal si besoin)
```bash
cd ~/cassandra-tp00
docker compose -f Cluster_1_noeud_1_rack_1_DC.yml logs
```
##### Faire **\<CTRL>+\<C>** pour sortir

##### Dans un autre terminal, pour suivre  :
```bash
cd ~/cassandra-tp00
docker ps -a 
```
##### Affichage (exemple) ': 
```text
CONTAINER ID   IMAGE              COMMAND                  CREATED         STATUS                   PORTS                                                                                                                                                                                                    NAMES
9be7d93e24ef   cassandra:latest   "docker-entrypoint.s…"   2 minutes ago   Up 2 minutes (healthy)   7001/tcp, 9160/tcp, 0.0.0.0:7199->7199/tcp, [::]:7199->7199/tcp, 0.0.0.0:7100->7000/tcp, [::]:7100->7000/tcp, 0.0.0.0:8181->8081/tcp, [::]:8181->8081/tcp, 0.0.0.0:9142->9042/tcp, [::]:9142->9042/tcp   cassandra01
```

##### Pour visualiser les logs de cassandra01 : 
```bash
docker logs cassandra01
```

##### Regarder les ports à l'écoute :
```bash
netstat -anl | grep 0:
```

##### Vérifier le statut du cluster via nodetool
```bash
docker exec -it cassandra01 nodetool status
```
##### Vous devriez voir finalement le nœuds cassandra01 avec le statut "UN" (Up Normal) :

```text
Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address          Load        Tokens  Owns (effective)  Host ID                               Rack
UN  192.168.100.151  114.72 KiB  16      100.0%            c4d56bcd-1a2e-49c6-a90b-16782f40800a  rack1
```


____
##### 5°) Lancer cqlsh et recréation du KeySpace entrepriseformation et la table cours_par_theme :
____

```bash
docker exec -it cassandra01 cqlsh
```

```cql

CREATE KEYSPACE entrepriseformation WITH replication = {'class':'SimpleStrategy', 'replication_factor': 1};

USE entrepriseformation;

CREATE TABLE entrepriseformation.cours_par_theme (
  theme TEXT,
  cours_id UUID,
  ajout_date TIMESTAMP,
  intitule TEXT,
  PRIMARY KEY ((theme), cours_id)
);
```

____
##### 6°) Insertion d'un simple enregistrement dans la table :
____
```cql
INSERT INTO cours_par_theme (theme,ajout_date,cours_id,intitule)
    VALUES ('cassandra', dateof(now()), uuid(), 'Cassandra Master');
```	
	
	
____	
##### 7°) On quitte cqlsh et on force Cassandra à flusher la memtable sur une SSTable :
____
```cql
exit 
```

```bash
docker exec -it cassandra01 nodetool flush
```


____
##### 8°) Investiguez sur la SSTable dans le répertoire /data du noeud. 
#####    Rappelez-vous que le nom actuel du répertoire est une valeur aléatoire unique 
#####    dans /opt/cassandra/data/data/entrepriseformation/  :
____

```bash
ls -lh /opt/cassandra/data/data/entrepriseformation/cours_par_theme-*
```

##### Vous noterez plusieurs fichiers dont les noms commencent ici par "bb-1-bti-"
##### Attention, les noms de fichier varient : 
##### Dans votre cas, cela sera un autre préfixe (ce préfixe varie suivant la version de cassandra) 
##### Ce sont les fichiers associés avec la 1ère SSTable.
____



____
##### 9°) Création d'une seconde SSTable. Pour cela,  on ajoute un second enregistrement avant de flusher  : 
____

```cql
INSERT INTO entrepriseformation.cours_par_theme (theme,ajout_date,cours_id,intitule)
    VALUES ('cassandra', dateof(now()), uuid(), 'Cassandra Genius');
	
```

```cql	
exit 
```

____	
##### 10°) Flushez cette seconde memtable sur disque :
____
```bash
nodetool flush
```


____
##### 11°) Regardez à nouveau le répertoire "data" pour voir les fichiers associés avec les deux SSTables :
____
```bash
ls -lh /opt/cassandra/data/data/entrepriseformation/cours_par_theme-*
```


____
##### 12°) Créez une 3ème SSTable en insérant la ligne suivante : 
____

```bash
docker exec -it cassandra01 bash
```

```bash
cqlsh -e "INSERT INTO entrepriseformation.cours_par_theme (theme,ajout_date,cours_id,intitule)VALUES ('cassandra', dateof(now()), uuid(), 'Cassandra Wizard');"
```

```bash
cqlsh -e "use entrepriseformation; SELECT count(*) FROM cours_par_theme;"
```

```bash
cqlsh -e "SELECT * FROM entrepriseformation.cours_par_theme LIMIT 10;"
```

```bash
cqlsh -e "use entrepriseformation; tracing on; SELECT * FROM cours_par_theme LIMIT 10 ;"
```
	
	
____
##### 13°) A nouveau, flushez la memtable sur disque et investiguez dans le répertoire : 
____

```bash
nodetool flush
```

```bash
ls -lh /opt/cassandra/data/data/entrepriseformation/cours_par_theme-*
```

##### NOTE : Quand Cassandra va créer la 4ème SSTable, Cassandra va alors effectuer une opération de compaction.


____
##### 14°) Insérez une 4ème ligne :
____
```bash
cqlsh -e "tracing on; INSERT INTO entrepriseformation.cours_par_theme (theme,ajout_date,cours_id,intitule) VALUES ('cassandra', dateof(now()), uuid(), 'Cassandra Ninja');"
```

```bash
cqlsh -e "tracing on; INSERT INTO entrepriseformation.cours_par_theme (theme,ajout_date,cours_id,intitule) VALUES ('cassandra', dateof(now()), uuid(), 'Cassandra NinjaPlus');"
```


____	
##### 15°) Flushez puis investiguez dans le répertoire data à nouveau :
____
```bash
docker exec -it cassandra01 nodetool flush
```

```bash
ls -lh /opt/cassandra/data/data/entrepriseformation/cours_par_theme-*
```

____
##### Notez que les fichiers des 3 précédentes SSTable ont disparu, et qu'un nouveau jeu de fichier est apparu.
##### Notez aussi que les noms de fichiers sont passés de mc-3-big à mc-5-big. 
##### C'est le résultat de la compaction. 
##### Cassandra a créé la 4ème SSTable et les a ensuite compacté tous les 4 dans une 5ème SSTable unique.
____
```bash
cqlsh -e "use entrepriseformation; SELECT count(*) FROM cours_par_theme;"
```

```bash
cqlsh -e "use entrepriseformation; tracing on; SELECT * FROM cours_par_theme LIMIT 10 ;"
```


____
##### Si on veut provoquer une compaction manuellement : 
____
```bash
ls -lh /opt/cassandra/data/data/entrepriseformation/cours_par_theme-*
```

```bash
cqlsh -e "tracing on; INSERT INTO entrepriseformation.cours_par_theme (theme,ajout_date,cours_id,intitule) VALUES ('cassandra', dateof(now()), uuid(), 'Cassandra Ninja2');"
```

```bash
cqlsh -e "tracing on; INSERT INTO entrepriseformation.cours_par_theme (theme,ajout_date,cours_id,intitule) VALUES ('cassandra', dateof(now()), uuid(), 'Cassandra Ninja3');"
```

```bash
cqlsh -e "use entrepriseformation; SELECT count(*) FROM cours_par_theme;"
```

```bash
cqlsh -e "use entrepriseformation; tracing on; SELECT * FROM cours_par_theme LIMIT 10 ;"
```

```bash
nodetool flush
```

```bash
ls -lh /opt/cassandra/data/data/entrepriseformation/cours_par_theme-*
```

```bash
nodetool -h 192.168.100.151 -p 7199 compact
```

```bash
ls -lh /opt/cassandra/data/data/entrepriseformation/cours_par_theme-*
```


____
##### Fin TP14 : gestion des compactions des SSTables
____