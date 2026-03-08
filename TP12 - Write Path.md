____
##### TP12 : Write Path
____

##### Dans ce TP, nous allons étudier la méthode d'écriture de Cassandra.
____
##### Contexte du TP : 
```text
    Cassandra utilise une méthode d'écriture optimisée. 
    Pour bien utiliser Cassandra, il est nécessaire de bien comprendre cette méthode d'écriture.
```
____
##### Etapes : 
____
##### 1°) Réinitialisation : 

```text
On démonte entièrement le cluster, on va lancer un seul noeud cassandra01 en solo
```

##### Arrêter et démonter le cluster 
```bash
cd ~/cassandra-tp00
docker compose -f Cluster_3_noeuds_2_racks_2_DC.yml down -v
```


#### Recréer les répertoires de volumes :
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

#### Dans un autre terminal, pour suivre  :
```bash
cd ~/cassandra-tp00
docker ps -a 
```
#### Affichage (exemple) ': 
```text
CONTAINER ID   IMAGE              COMMAND                  CREATED         STATUS                   PORTS                                                                                                                                                                                                    NAMES
9be7d93e24ef   cassandra:latest   "docker-entrypoint.s…"   2 minutes ago   Up 2 minutes (healthy)   7001/tcp, 9160/tcp, 0.0.0.0:7199->7199/tcp, [::]:7199->7199/tcp, 0.0.0.0:7100->7000/tcp, [::]:7100->7000/tcp, 0.0.0.0:8181->8081/tcp, [::]:8181->8081/tcp, 0.0.0.0:9142->9042/tcp, [::]:9142->9042/tcp   cassandra01
```

#### Pour visualiser les logs de cassandra01 : 
```bash
docker logs cassandra01
```

#### Regarder les ports à l'écoute :
```bash
netstat -anl | grep 0:
```

#### Vérifier le statut du cluster via nodetool
```bash
docker exec -it cassandra01 nodetool status
```
#### Vous devriez voir finalement le nœuds cassandra01 avec le statut "UN" (Up Normal) :

```text
Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address          Load        Tokens  Owns (effective)  Host ID                               Rack
UN  192.168.100.151  114.72 KiB  16      100.0%            c4d56bcd-1a2e-49c6-a90b-16782f40800a  rack1
```


____
##### 5°)Investiguons dans le répertoire "commitlog" :
____
```bash
docker exec -it cassandra01 ls -lh ~/cassandra-tp00/docker/cassandra01commitlog
```


##### [cassandra@cassandra01 data]$ docker exec -if cassandra01 ls -lh ~/cassandra-tp00/docker/cassandra01commitlog
##### total 216K
##### -rw-rw-r-- 1 cassandra cassandra 32M  3 déc.  11:49 CommitLog-6-1512298071579.log
##### -rw-rw-r-- 1 cassandra cassandra 32M  3 déc.  11:47 CommitLog-6-1512298071580.log
##### 
##### 
##### Bien que chaque fragment est alloué par block de 32 Mo, 
##### Cela ne signifie pas qu'il y a effectivement 32 Mo de données écrites
##### Notez que le total indiqué sur la première ligne de résultat correspond à la taille réelle des fichiers.


____
##### 6°) Regardez le répertoire pour voir comment il est modifié quand on écrit des données dans Cassandra. 
____

```bash
watch -n 1 -d "ls -lh ~/cassandra-tp00/docker/cassandra01/commitlog"
```

##### NOTE : Pour sortir de cette commande ensuite, faites "CTRL-C"

____
##### 8°) Nous allons utiliser l'outil "cassandra-stress" pour générer plusieurs centaines d'écritures sur le noeud. 
#####     Exécutez la commande suivante sur le premier terminal :
____
```bash
docker exec -it cassandra01 bash 
```

```bash
cd /opt/cassandra/tools/bin
```

```bash
./cassandra-stressd start -h 192.168.100.151
```

```bash
./cassandra-stressd status 
```

##### bash cassandra-stress write n=1000 -node 192.168.100.151
```bash
bash cassandra-stress write no-warmup n=25000 cl=one -rate threads=1 -node 192.168.100.151
```

##### Assurez-vous que le second terminal vous reste visible pendant l'exécution de cassandra-stress.
##### L'outil cassandra-stress va écrire 25 000 lignes sur le noeud.
##### 
##### Quelques éléments à regarder pendant l'insertion de ces enregistrements :
##### - La taille totale continue à augmenter.
##### - Le timestamp change pour le segment en cours d'écriture.
##### - Vous pouvez voir apparaître des fichiers de commitlog supplémentaires

____
##### 9°) Quand l'outil cassandra-stress a fini, sortez de la fenêtre en faisant "CTRL-C"
____


____
##### 10°) Lancez la commande suivante "nodetool" :
____
```bash
nodetool tablestats keyspace1.standard1
```bash

##### Remarque : cfstats est déprécié => On utilise depuis plusieurs versions : tablestats  

##### cassandra-stress a créé le KeySpace et la table Keyspace1.standard1, et l'a chargée.
##### tablestats donne les statistiques sur cette column family (table). 
##### Le terme "Column family" is le nom déprécié utilisé pour nommer une table.
##### 
##### [cassandra@cassandra01 ~]$ /node/bin/nodetool tablestats keyspace1.standard1
##### Total number of tables: 45
##### ----------------
##### Keyspace: keyspace1
##### 	Read Count: 0
##### 	Read Latency: NaN ms.
##### 	Write Count: 250000
##### 	Write Latency: 0.040414532 ms.
##### 	Pending Flushes: 0
##### 		Table: standard1
##### 		SSTable count: 2
##### 		Space used (live): 52403218
##### 		Space used (total): 52403218
##### 		Space used by snapshots (total): 0
##### 		Off heap memory used (total): 299966
##### 		SSTable Compression Ratio: 0.0
##### 		Number of keys (estimate): 250837
##### 		Memtable cell count: 39058
##### 		Memtable data size: 10897182
##### 		Memtable off heap memory used: 0
##### 		Memtable switch count: 2
##### 		Local read count: 0
##### 		Local read latency: NaN ms
##### 		Local write count: 250000
##### 		Local write latency: 0.037 ms
##### 		Pending flushes: 0
##### 		Bloom filter false positives: 0
##### 		Bloom filter false ratio: 0.00000
##### 		Bloom filter space used: 263704
##### 		Bloom filter off heap memory used: 263688
##### 		Index summary off heap memory used: 36278
##### 		Compression metadata off heap memory used: 0
##### 		Compacted partition minimum bytes: 180
##### 		Compacted partition maximum bytes: 258
##### 		Compacted partition mean bytes: 258
##### 		Average live cells per slice (last five minutes): NaN
##### 		Maximum live cells per slice (last five minutes): 0
##### 		Average tombstones per slice (last five minutes): NaN
##### 		Maximum tombstones per slice (last five minutes): 0
##### 		
##### Notez que "Write Count" correspond au nombre d'enregistrements insérés par cassandra-stress. 
##### tablestats affiche des informations également sur le nombre de SSTables, l'espace utilisé, et les statistiques de bloom filter.



____
##### 11°) Notez les stastistiques liées à la Memtable : 
____
##### Memtable cell count: 39058
##### Memtable data size: 10897182
##### Memtable off heap memory used: 0
##### Memtable switch count: 2



____
##### 12°) Exécutez la commande "nodetool" qui forcera l'écriture de la memtable sur disque (flush) : 
____
```bash
nodetool flush
```


____
##### 13°) Vérifiez maintenant les stats de la table à nouveau :
____
```bash
nodetool tablestats keyspace1.standard1
```

##### Notez que les statistiques de la memtable ont été mises à "0" du fait que nous avons flushé la memtable sur disque

```text
Memtable cell count: 0
Memtable data size: 0
Memtable off heap memory used: 0
Memtable switch count: 3
```


____
##### 14°) Dernier exercice : stopper le noeud et supprimez les logs : le fichier /node/log/system.log
##### 		( rappel : par défaut /var/log/cassandra/system.log), 
##### relancez le noeud, et recherchez "CommitLog.java" dans le nouveau fichier logs/system.log 
##### Vous devriez voir apparaître des lignes d'information sur le rejeu de commitlog au démarrage.
##### 
##### S'il n'y a pas de commit log trouvé lors du redémarrage, aucun rejeu ne sera effectué. 
##### Si Cassandra trouve un ou plusieurs fichiers commit log, Cassandra rejoue les mises à jours dans les memtables
##### puis flushe les memtables sur disque.


##### 15°) On démonte notre lcuster mononoeud une fois terminé
____

##### Arrêter et démonter le cluster 
```bash
docker compose -f Cluster_1_noeud_1_rack_1_DC.yml down -v
```


____
##### Fin du TP12 : Write Path

____




