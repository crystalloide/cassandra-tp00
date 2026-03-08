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
```text
cassandra-stress crée un keyspace nommé keyspace1 et une table nommée standard1.

Vous trouverez le répertoire comme illustré ci-dessous, 
mais l'identifiant de table sera différent.

Tips : Utilisez la touche de tabulation du terminal pour utiliser la complétion automatique (utile). 
```

```bash
cd /opt/cassandra/data/data/keyspace1/
```

```bash
ls
```

#### Affichage en retour des fichiers présents : par exemple : 
```text
counter1-e444db501b1f11f19be8cd186ae03d17  standard1-e3bc4a601b1f11f19be8cd186ae03d17
```

#### Allons dans le répertoire : 
```bash
cd standard1-e3bc4a601b1f11f19be8cd186ae03d17
```

```bash
ls
```
#### Affichage en retour des fichiers présents : par exemple : 
```text
backups  nb-5-big-CRC.db  nb-5-big-Data.db  nb-5-big-Digest.crc32  nb-5-big-Filter.db  nb-5-big-Index.db  nb-5-big-Statistics.db  nb-5-big-Summary.db  nb-5-big-TOC.txt
```

____
#### 4°) Exécuter la commande suivante pour lister les fichiers bloom filter des SSTables :
____
```bash
ls -lh *Filter.db
```

#### Affichage :
```text
-rw-r--r-- 1 cassandra cassandra 31K Mar  8 19:25 nb-5-big-Filter.db
```text

#### Noter la taille  du ou des fichiers.

#### Nous allons maintenant diminuer la probabilité qu’un filtre de bloom renvoie un faux positif.
#### et voyons comment cela affecte la taille des fichiers de filtre de bloom.

____
#### 5°) Exécutons la commande pour visualiser les paramètres du filtre de bloom actuel :
____

##### Dans un autre terminal, allons en cqlsh sur cassandra :

```bash
docker exec -it cassandra01 cqlsh
```

```cql
DESCRIBE keyspace keyspace1;
```

##### Exemple d'Affichage :
```text
CREATE KEYSPACE keyspace1 WITH replication = {'class': 'SimpleStrategy', 'replication_factor': '1'}  AND durable_writes = true;

CREATE TABLE keyspace1.counter1 (
    key blob PRIMARY KEY,
    "C0" counter,
    "C1" counter,
    "C2" counter,
    "C3" counter,
    "C4" counter
) WITH additional_write_policy = '99p'
    AND allow_auto_snapshot = true
    AND bloom_filter_fp_chance = 0.01
    AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
    AND cdc = false
    AND comment = ''
    AND compaction = {'class': 'org.apache.cassandra.db.compaction.SizeTieredCompactionStrategy', 'max_threshold': '32', 'min_threshold': '4'}
    AND compression = {'enabled': 'false'}
    AND memtable = 'default'
    AND crc_check_chance = 1.0
    AND default_time_to_live = 0
    AND extensions = {}
    AND gc_grace_seconds = 864000
    AND incremental_backups = true
    AND max_index_interval = 2048
    AND memtable_flush_period_in_ms = 0
    AND min_index_interval = 128
    AND read_repair = 'BLOCKING'
    AND speculative_retry = '99p';

CREATE TABLE keyspace1.standard1 (
    key blob PRIMARY KEY,
    "C0" blob,
    "C1" blob,
    "C2" blob,
    "C3" blob,
    "C4" blob
) WITH additional_write_policy = '99p'
    AND allow_auto_snapshot = true
    AND bloom_filter_fp_chance = 0.01
    AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
    AND cdc = false
    AND comment = ''
    AND compaction = {'class': 'org.apache.cassandra.db.compaction.SizeTieredCompactionStrategy', 'max_threshold': '32', 'min_threshold': '4'}
    AND compression = {'enabled': 'false'}
    AND memtable = 'default'
    AND crc_check_chance = 1.0
    AND default_time_to_live = 0
    AND extensions = {}
    AND gc_grace_seconds = 864000
    AND incremental_backups = true
    AND max_index_interval = 2048
    AND memtable_flush_period_in_ms = 0
    AND min_index_interval = 128
    AND read_repair = 'BLOCKING'
    AND speculative_retry = '99p';
```
	
____
#### Remarque sur les filtres de bloom : 
```text
Notez que bloom_filter_fp_chance est 0.01, ce qui signifie une probabilité de 1% de faux positif.
C’est très bien, mais si nous voulons baisser encore ce taux, 
nous pouvons renoncer à un peu d'espace pour cela.
```
____


____
#### 6°) Executons la commande suivante :
____
```sql
ALTER TABLE keyspace1.standard1 WITH bloom_filter_fp_chance = 0.0001;
```

```sql
exit;
```

#### Maintenant que nous avons modifié le paramètre bloom_filter_fp_chance, 
#### mais nous devons encore mettre à jour les SSTables et les fichiers bloom filter correspondants


____
#### 7°) Retournons donc sur la session dans le copnteneur et exécutons la commande suivante : 
____
```bash
nodetool upgradesstables --include-all-sstables
```

____

###### Remarque : 
```text
nodetool upgradesstables reconstruit les SSTables pour un keyspace et une table spécifiés.

Nous faisons cela ici pour reconstruire également les filtres de Bloom.

Normalement, cette commande mettra à jour les sstables si celles-ci ne sont pas à la version la plus récente de SSTable.

le flag --include-all-sstables force la reconstruction.

Normalement, vous devriez exécuter nodetool upgradesstables sur chaque noeud.

Mais dans cet exercice, nous n’avons qu’un seul nœud.
```

____
#### 8°) Regardons maintenant la nouvelle taille des fichier bloom filter :
____
```bash
ls -lh *Filter.db
```
##### Affichage en retour : 
```text
-rw-r--r-- 1 cassandra cassandra 62K Mar  8 19:33 nb-6-big-Filter.db
```

##### Notez que la taille du ou des fichiers est plus grande.
##### Nous avons, moyennant un peu plus d'espace, diminué la probabilité de faux positif.

____
#### 9°) Exécutons maintenant la commande suivante sur le terminal CQLSH :
____
```sql
ALTER TABLE keyspace1.standard1 WITH bloom_filter_fp_chance = 1.0;
```

____
#### 10°) Et mettons à jour à nouveau les SSTables sur le terminal dans le conteneur :
____
```bash
nodetool upgradesstables --include-all-sstables
```

#### Maintenant, quelle est la taille de vos fichiers de filtre de bloom ?
#### Pourquoi? : °)

#### Les fichiers ont disparus! 
```bash
ls -lh *Filter.db
```
##### Affichage en retour : 
```text
ls: cannot access '*Filter.db': No such file or directory
```
#### Bloom_filter_fp_chance = 1.0 signifie qu’aucun filtrage n’est en cours 
#### => il n’est donc pas nécessaire de stocker des fichiers "filtre de bloom".

____
#### 11°) Exécutons maintenant la commande suivante :
____
```bash
nodetool tablestats keyspace1.standard1
```
____
##### Une partie des statistiques inclut des informations sur le filtre bloom.
##### Puisque nous n’avons pas lu encore les tables de cassandra-stress, les valeurs sont toutes égales à zéro.
##### Cependant, vous pouvez utiliser ces statistiques pour tuner Cassandra si nécessaire.

##### Affichage en retour : 
```text
Total number of tables: 1
----------------
Keyspace: keyspace1
        Read Count: 0
        Read Latency: NaN ms
        Write Count: 25000
        Write Latency: 0.01274704 ms
        Pending Flushes: 0
                Table: standard1
                SSTable count: 1
                Old SSTable count: 0
                Max SSTable size: 5.870MiB
                Space used (live): 6154753
                Space used (total): 6154753
                Space used by snapshots (total): 0
                Off heap memory used (total): 4312
                SSTable Compression Ratio: -1.00000
                Number of partitions (estimate): 25272
                Memtable cell count: 0
                Memtable data size: 0
                Memtable off heap memory used: 0
                Memtable switch count: 4
                Speculative retries: 0
                Local read count: 0
                Local read latency: NaN ms
                Local write count: 25000
                Local write latency: NaN ms
                Local read/write ratio: 0.00000
                Pending flushes: 0
                Percent repaired: 0.0
                Bytes repaired: 0B
                Bytes unrepaired: 5.459MiB
                Bytes pending repair: 0B
                Bloom filter false positives: 0
                Bloom filter false ratio: 0.00000
                Bloom filter space used: 0
                Bloom filter off heap memory used: 0
                Index summary off heap memory used: 4312
                Compression metadata off heap memory used: 0
                Compacted partition minimum bytes: 180
                Compacted partition maximum bytes: 258
                Compacted partition mean bytes: 258
                Average live cells per slice (last five minutes): NaN
                Maximum live cells per slice (last five minutes): 0
                Average tombstones per slice (last five minutes): NaN
                Maximum tombstones per slice (last five minutes): 0
                Droppable tombstone ratio: 0.00000

----------------
```
____
#### Fin du TP13 : Read Path
____
