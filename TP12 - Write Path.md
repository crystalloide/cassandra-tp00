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

##### Démarrage du cluster avec Docker Compose :

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
##### 2°) Investiguons dans le répertoire "commitlog" :
____
```bash
docker exec -it cassandra01 ls -lh /opt/cassandra/data/commitlog
```
##### ou : 
```bash
ls -lh ~/cassandra-tp00/docker/cassandra01/commitlog/
```

##### Affichage en retour : 
```text
total 128K
-rw-r--r-- 1 999 systemd-journal 32M Mar  8 19:46 CommitLog-7-1772995254101.log
-rw-r--r-- 1 999 systemd-journal 32M Mar  8 19:40 CommitLog-7-1772995254102.log
```

##### Remarque :
```text
Bien que chaque fragment est alloué par block de 32 Mo, cela ne signifie pas qu'il y a effectivement 32 Mo de données écrites

Notez que le total indiqué sur la première ligne de résultat correspond à la taille réelle des fichiers.
```

____
##### 6°) Regardez le répertoire pour voir comment il est modifié quand on écrit des données dans Cassandra. 
____

```bash
watch -n 1 -d "ls -lh ~/cassandra-tp00/docker/cassandra01/commitlog"
```

##### NOTE : Pour sortir de cette commande ensuite, faites "CTRL-C"

____
##### 3°) Nous allons utiliser l'outil "cassandra-stress" pour générer plusieurs centaines d'écritures sur le noeud. 
#####     Exécutez la commande suivante sur le premier terminal :
____
```bash
docker exec -it cassandra01 bash 
```

```bash
cd /opt/cassandra/tools/bin
```

##### bash cassandra-stress write n=1000 -node 192.168.100.151
```bash
bash cassandra-stress write no-warmup n=25000 cl=one -rate threads=1 -node 192.168.100.151
```

##### Assurez-vous que le second terminal vous reste visible pendant l'exécution de cassandra-stress.
##### L'outil cassandra-stress va écrire 25 000 lignes sur le noeud.

###### Affichage en retour du benchmark : 
```text

******************** Stress Settings ********************
Command:
  Type: write
  Count: 25,000
  No Warmup: true
  Consistency Level: ONE
  Target Uncertainty: not applicable
  Key Size (bytes): 10
  Counter Increment Distibution: add=fixed(1)
Rate:
  Auto: false
  Thread Count: 1
  OpsPer Sec: 0
Population:
  Sequence: 1..25000
  Order: ARBITRARY
  Wrap: true
Insert:
  Revisits: Uniform:  min=1,max=1000000
  Visits: Fixed:  key=1
  Row Population Ratio: Ratio: divisor=1.000000;delegate=Fixed:  key=1
  Batch Type: not batching
Columns:
  Max Columns Per Key: 5
  Column Names: [C0, C1, C2, C3, C4]
  Comparator: AsciiType
  Timestamp: null
  Variable Column Count: false
  Slice: false
  Size Distribution: Fixed:  key=34
  Count Distribution: Fixed:  key=5
Errors:
  Ignore: false
  Tries: 10
Log:
  No Summary: false
  No Settings: false
  File: null
  Interval Millis: 1000
  Level: NORMAL
Mode:
  API: JAVA_DRIVER_NATIVE
  Connection Style: CQL_PREPARED
  Protocol Version: V5
  Username: null
  Password: null
  Auth Provide Class: null
  Max Pending Per Connection: 128
  Connections Per Host: 8
  Compression: NONE
Node:
  Nodes: [192.168.100.151]
  Is White List: false
  Datacenter: null
Schema:
  Keyspace: keyspace1
  Replication Strategy: org.apache.cassandra.locator.SimpleStrategy
  Replication Strategy Options: {replication_factor=1}
  Table Compression: null
  Table Compaction Strategy: null
  Table Compaction Strategy Options: {}
Transport:
  Truststore: null
  Truststore Password: null
  Keystore: null
  Keystore Password: null
  SSL Protocol: TLS
  SSL Algorithm: null
  SSL Ciphers: TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_AES_256_CBC_SHA
Port:
  Native Port: 9042
  JMX Port: 7199
JMX:
  Username: null
  Password: *not set*
Graph:
  File: null
  Revision: unknown
  Title: null
  Operation: WRITE
TokenRange:
  Wrap: false
  Split Factor: 1
Credentials file:
  File: *not set*
  CQL username: *not set*
  CQL password: *not set*
  JMX username: *not set*
  JMX password: *not set*
  Transport truststore password: *not set*
  Transport keystore password: *not set*
Reporting:
  Output frequency: 1s
  Header frequency: *not set*

Connected to cluster: formation, max pending requests per connection 128, max connections per host 8
Datacenter: datacenter1; Host: /192.168.100.151:9042; Rack: rack1
Created keyspaces. Sleeping 1s for propagation.
Sleeping 2s...
Running WRITE with 1 threads for 25000 iteration

type                                               total ops,    op/s,    pk/s,   row/s,    mean,     med,     .95,     .99,    .999,     max,   time,   stderr, errors,  gc: #,  max ms,  sum ms,  sdv ms,      mb
WARN  18:52:05,485 Query 'com.datastax.driver.core.Statement$1@63e6389a;' generated server side warning(s): `USE <keyspace>` with prepared statements is considered to be an anti-pattern due to ambiguity in non-qualified table names. Please consider removing instances of `Session#setKeyspace(<keyspace>)`, `Session#execute("USE <keyspace>")` and `cluster.newSession(<keyspace>)` from your code, and always use fully qualified table names (e.g. <keyspace>.<table>). Keyspace used: keyspace1, statement keyspace: keyspace1, statement id: e1d2f4aa887d02751110f92a52de4f20
total,                                                    36,      36,      36,      36,    14.0,     1.6,    90.6,    98.0,    98.0,    98.0,    1.0,  0.00000,      0,      0,       0,       0,       0,       0
...
....
......

total,                                                 23718,     794,     794,     794,     1.2,     0.5,     0.6,    57.1,    76.7,    76.7,   50.0,  0.07457,      0,      0,       0,       0,       0,       0
total,                                                 24660,     942,     942,     942,     1.1,     0.4,     0.6,    54.6,    58.4,    58.4,   51.0,  0.07400,      0,      0,       0,       0,       0,       0
total,                                                 25000,    1028,    1028,    1028,     1.0,     0.5,     0.6,     0.7,    59.1,    59.1,   51.3,  0.07521,      0,      0,       0,       0,       0,       0


Results:
Op rate                   :      487 op/s  [WRITE: 487 op/s]
Partition rate            :      487 pk/s  [WRITE: 487 pk/s]
Row rate                  :      487 row/s [WRITE: 487 row/s]
Latency mean              :    2.0 ms [WRITE: 2.0 ms]
Latency median            :    0.5 ms [WRITE: 0.5 ms]
Latency 95th percentile   :    0.8 ms [WRITE: 0.8 ms]
Latency 99th percentile   :   78.2 ms [WRITE: 78.2 ms]
Latency 99.9th percentile :   89.3 ms [WRITE: 89.3 ms]
Latency max               :   98.0 ms [WRITE: 98.0 ms]
Total partitions          :     25,000 [WRITE: 25,000]
Total errors              :          0 [WRITE: 0]
Total GC count            : 3
Total GC memory           : 215.107 MiB
Total GC time             :    0.1 seconds
Avg GC time               :   31.7 ms
StdDev GC time            :   35.0 ms
Total operation time      : 00:00:51

END
```

##### Quelques éléments à regarder pendant l'insertion de ces enregistrements :
##### - La taille totale continue à augmenter.
##### - Le timestamp change pour le segment en cours d'écriture.
##### - Vous pouvez voir apparaître des fichiers de commitlog supplémentaires (si le benchmark a été assez poussé)

____
##### 4°) Quand l'outil cassandra-stress a fini, sortez de la fenêtre en faisant "CTRL-C"
____

##### 5°) Lancez la commande suivante "nodetool tablestats xxxxx" :
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
##### 6°) Notez les stastistiques liées à la Memtable : 
____
##### Memtable cell count: 39058
##### Memtable data size: 10897182
##### Memtable off heap memory used: 0
##### Memtable switch count: 2



____
##### 7°) Exécutez la commande "nodetool" qui forcera l'écriture de la memtable sur disque (flush) : 
____
```bash
nodetool flush
```

____
##### 8°) Vérifiez maintenant les stats de la table à nouveau :
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
##### 9°) Dernier exercice : stopper le noeud et supprimez les logs : le fichier /node/log/system.log
##### 		( rappel : par défaut /var/log/cassandra/system.log), 
##### relancez le noeud, et recherchez "CommitLog.java" dans le nouveau fichier logs/system.log 
##### Vous devriez voir apparaître des lignes d'information sur le rejeu de commitlog au démarrage.
##### 
##### S'il n'y a pas de commit log trouvé lors du redémarrage, aucun rejeu ne sera effectué. 
##### Si Cassandra trouve un ou plusieurs fichiers commit log, Cassandra rejoue les mises à jours dans les memtables
##### puis flushe les memtables sur disque.

____
##### 10°) On démonte notre cluster mono-noeud une fois le TP terminé :
____

##### Arrêt et démontage  du cluster et des volumes :
```bash
docker compose -f Cluster_1_noeud_1_rack_1_DC.yml down -v
```

____
##### Fin du TP12 : Write Path

____




