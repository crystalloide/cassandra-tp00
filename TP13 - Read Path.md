____
#### TP13 : Read Path
____
#### Dans cet exercice, vous allez comprendre le read path ou chemin de lecture de Cassandra.
____
#### Contexte: Dans cet exercice, nous examinerons les filtres de bloom et les caches de clés.
____
#### ETAPES:

#### 1 °) Pour commencer, nous devons alimenter notre cluster à noeud unique avec une bonne quantité de données.
```text
Nous allons utiliser cassandra-stress pour le faire.
Exécutez la commande suivante dans une fenêtre de terminal.
Attendez que cassandra-stress soit terminé avant de continuer.
```

____
```bash
docker exec -it cassandra01 bash 
```

```bash
cd /opt/cassandra/tools/bin
```

##### bash cassandra-stress write n=1000 -node 192.168.100.151

```bash
bash cassandra-stress write no-warmup n=25000 cl=one -rate threads=2 -node 192.168.100.151
```

____
#### Faites une visite à la fontaine à eau ou à la machine à café ou machine à glace en attendant la fin...


____
#### 2°) Forcer maintenant Cassandra à flusher ses memtables courantes sur disque :
____

#### Sur cassandra01 : 
```bash
nodetool flush
```


____
#### 3°) A partir de votre session, accédez au répertoire de données de la table écrite par Cassandra-stress.
#### cassandra-stress crée un keyspace nommé keyspace1 et une table nommée standard1.
##
#### Vous trouverez le répertoire comme illustré ci-dessous, 
#### mais l'identifiant de table sera différent.
#### Utilisez la touche de tabulation du terminal pour utiliser la complétion automatique (utile). 
##

cd /node/dse-data/data/keyspace1/

ls
#### Affichage en retour des fichiers présents : par exemple : 
#### counter1-a73460b0e71211ef9b6a217f067ae36e  standard1-a6d79ab1e71211ef993499ff68342f4e

cd standard1-a6d79ab1e71211ef993499ff68342f4e

ls
#### Affichage en retour des fichiers présents : par exemple : 
#### backups  bb-1-bti-CRC.db  bb-1-bti-Data.db  bb-1-bti-Digest.crc32  bb-1-bti-Filter.db  bb-1-bti-Partitions.db  bb-1-bti-Rows.db  bb-1-bti-Statistics.db  bb-1-bti-TOC.txt



____
#### 4°) Exécuter la commande suivante pour lister les fichiers bloom filter des SSTables :
____
ls -lh *Filter.db

#### Affichage :
#### [cassandra@cassandra01 standard1-a6d79ab1e71211ef993499ff68342f4e]$ ls -lh *Filter.db
#### -rw-r--r-- 1 cassandra cassandra 9.1K Feb  9 18:22 bb-1-bti-Filter.db


#### Noter la taille  du ou des fichiers.

#### Nous allons maintenant diminuer la probabilité qu’un filtre de bloom renvoie un faux positif.
#### et voyons comment cela affecte la taille des fichiers de filtre de bloom.



____
#### 5°) Exécutons la commande pour visualiser les paramètres du filtre de bloom actuel :
____
DESCRIBE keyspace keyspace1;

#### Exemple d'Affichage :
#### 
#### 		cqlsh> DESCRIBE keyspace keyspace1;
#### 
#### 		CREATE KEYSPACE keyspace1 WITH replication = {'class': 'SimpleStrategy', 'replication_factor': '1'}  AND durable_writes = true;
#### 
#### 		CREATE TABLE keyspace1.counter1 (
#### 			key blob,
#### 			column1 text,
#### 			"C0" counter static,
#### 			"C1" counter static,
#### 			"C2" counter static,
#### 			"C3" counter static,
#### 			"C4" counter static,
#### 			value counter,
#### 			PRIMARY KEY (key, column1))
#### 			WITH COMPACT STORAGE
#### 			AND CLUSTERING ORDER BY (column1 ASC)
#### 			AND bloom_filter_fp_chance = 0.01
#### 			...
#### 			AND speculative_retry = '99PERCENTILE';
#### 
#### 		CREATE TABLE keyspace1.standard1 (
#### 			key blob PRIMARY KEY,
#### 			"C0" blob,
#### 			"C1" blob,
#### 			"C2" blob,
#### 			"C3" blob,
#### 			"C4" blob
#### 		) WITH COMPACT STORAGE
#### 			AND bloom_filter_fp_chance = 0.01
#### 			...
#### 			AND speculative_retry = '99PERCENTILE';
	
____
#### Notez que bloom_filter_fp_chance est 0.01, ce qui signifie une probabilité de 1% de faux positif.
#### C’est très bien, mais si nous voulons baisser encore ce taux, 
#### nous pouvons renoncer à un peu d'espace pour cela.
____



____
#### 6°) Executons la commande suivante :
____
ALTER TABLE keyspace1.standard1 WITH bloom_filter_fp_chance = 0.0001;

#### Maintenant que nous avons modifier le paramètre bloom_filter_fp_chance, 
#### nous devons mettre à jours les SSTables et les fichiers bloom filter correspondants



____
#### 7°) Retournons donc sur la session et exécutons la commande suivante : 
____
/node/resources/cassandra/bin/nodetool upgradesstables --include-all-sstables



____
#### nodetool upgradesstables reconstruit les SSTables pour un keyspace et une table spécifiés.
#### Nous faisons cela ici pour reconstruire également les filtres de Bloom.
#### Normalement, cette commande mettra à jour les sstables si celles-ci ne sont pas à la version la plus récente de SSTable.
#### le flag --include-all-sstables force la reconstruction.
#### Normalement, vous devriez exécuter nodetool upgradesstables sur chaque noeud.
#### Mais dans cet exercice, nous n’avons qu’un seul nœud.
____


____
#### 8°) Regardons maintenant la nouvelle taille des fichier bloom filter :
____
#### root@node1:/node/dse-data/data/keyspace1/standard1-7a86...06c25300ad# ls -lh *Filter.db
#### -rw-r--r-- 1 root root  96K Nov  2 22:05 mc-4-big-Filter.db
#### -rw-r--r-- 1 root root 258K Nov  2 22:05 mc-5-big-Filter.db
#### -rw-r--r-- 1 root root 255K Nov  2 22:05 mc-6-big-Filter.db
____
#### Notez que la taille de ces fichiers est plus grande.
#### Nous avons, moyennant un peu plus d'espace, diminué la probabilité de faux positif.
____


____
#### 9°) Exécutons maintenant la commande suivante :
____
ALTER TABLE keyspace1.standard1 WITH bloom_filter_fp_chance = 1.0;



____
#### 10°) Et mettons à jour à nouveau les SSTables :
____
/node/resources/cassandra/bin/nodetool upgradesstables --include-all-sstables

____
#### Maintenant, quelle est la taille de vos fichiers de filtre de bloom ?
#### Pourquoi? : °)
#### Les fichiers ont disparus! 
#### Bloom_filter_fp_chance = 1.0 signifie qu’aucun filtrage n’est en cours, 
#### il n’est donc pas nécessaire de stocker des fichiers filtre de bloom.
____



____
#### 11°) Exécutons maintenant la commande suivante :
____
/node/resources/cassandra/bin/nodetool cfstats keyspace1.standard1

____
#### Une partie des statistiques inclut des informations sur le filtre bloom.
#### Puisque nous n’avons pas lu encore les tables de cassandra-stress, les valeurs sont toutes égales à zéro.
#### Cependant, vous pouvez utiliser ces statistiques pour tuner Cassandra si nécessaire.
##
#### root@node1:~# /node/resources/cassandra/bin/nodetool cfstats keyspace1.standard1
#### Keyspace: keyspace1
#### 	Read Count: 0
#### 	Read Latency: NaN ms.
#### 	Write Count: 250000
#### 	Write Latency: 0.041335976 ms.
#### 	Pending Flushes: 0
#### 		Table: standard1
#### 		SSTable count: 3
#### 		Space used (live): 61790227
#### 		Space used (total): 61790227
#### 		Space used by snapshots (total): 0
#### 		Off heap memory used (total): 43010
#### 		SSTable Compression Ratio: 0.0
#### 		Number of keys (estimate): 249256
#### 		Memtable cell count: 0
#### 		Memtable data size: 0
#### 		Memtable off heap memory used: 0
#### 		Memtable switch count: 7
#### 		Local read count: 0
#### 		Local read latency: NaN ms
#### 		Local write count: 250000
#### 		Local write latency: NaN ms
#### 		Pending flushes: 0
#### 		Bloom filter false positives: 0
#### 		Bloom filter false ratio: 0.00000
#### 		Bloom filter space used: 0
#### 		Bloom filter off heap memory used: 0
#### 		Index summary off heap memory used: 43010
#### 		Compression metadata off heap memory used: 0
#### 		Compacted partition minimum bytes: 180
#### 		Compacted partition maximum bytes: 258
#### 		Compacted partition mean bytes: 258
#### 		Average live cells per slice (last five minutes): NaN
#### 		Maximum live cells per slice (last five minutes): 0
#### 		Average tombstones per slice (last five minutes): NaN
#### 		Maximum tombstones per slice (last five minutes): 0
____



____
#### Fin du TP13 : Read Path

____

