____
##### TP15a : Index secondaire                                 
____


##### Etapes : sur un cluster lancé au complet : 


____
##### 1°) A partir d'une session CQL :
____
```bash
docker exec -it cassandra01 cqlsh 192.168.100.151 
```
____
##### 2°) Remarque : si on avait activé l'authentification, la commande serait : cqlsh 192.168.100.151 -u cassandra -p cassandra  
____

###### 3°) Dans cqlsh, nous allons recréer notre keyspace nommé EntrepriseFormation. 
____

```cql
DROP KEYSPACE IF EXISTS EntrepriseFormation;
```

```cql
CREATE KEYSPACE EntrepriseFormation WITH replication = {'class':'SimpleStrategy', 'replication_factor': 1};
```

____

###### 4°) Dans cqlsh, sélectionnez le keyspace récemment créé avec la commande USE :
____
```cql
USE EntrepriseFormation;
```

____
###### 5°) Créez une table simple nommée "cours" avec la structure indiquée ci-dessus. "cours_id" sera la clé primaire.
____
```cql
CREATE TABLE cours (
  cours_id TIMEUUID,
  ajout_date TIMESTAMP,
  intitule TEXT,
  PRIMARY KEY (cours_id)
);
```

```cql
EXIT;
```

____
###### 6°) Exécutez la commande suivante pour importer les données dans la tables des Cours
____
```bash
cd ~/cassandra-tp00
docker exec -it cassandra01 mkdir -p /donnees
docker cp ./donnees/cours.csv cassandra01:/donnees/cours.csv
docker cp ./donnees/cours-par-theme.csv cassandra01:/donnees/cours-par-theme.csv
docker exec -it cassandra01 chmod 775 -Rf /donnees
docker exec -it cassandra01 ls /donnees
docker exec -it cassandra01 cqlsh
```

```bash
docker exec -it cassandra01 cqlsh 192.168.100.151 
```

```sql
USE entrepriseformation;
COPY cours(cours_id,ajout_date,intitule)
FROM '/donnees/cours.csv'
WITH HEADER=TRUE;
```


____
###### 7°) Utilisez la commande SELECT pour vérifier pour les données ont été effectivement chargées
____
```sql
SELECT * FROM cours;
```

```text
cqlsh:entrepriseformation> SELECT * FROM cours;

 cours_id                             | ajout_date                      | intitule
--------------------------------------+---------------------------------+--------------------------
 245e8024-14bd-11e5-9743-8238356b7e32 | 2012-04-03 01:00:00.000000+0000 |         Cassandra & SSDs
 3452f7de-14bd-11e5-855e-8738355b7e3a | 2013-03-17 01:00:00.000000+0000 | Introduction a Cassandra
 5645f8bd-14bd-11e5-af1a-8638355b8e3a | 2013-04-16 01:00:00.000000+0000 |         Qui sommes-nous?
 1645ea59-14bd-11e5-a993-8138354b7e31 | 2014-01-29 01:00:00.000000+0000 |    Histoire de Cassandra
 4845ed97-14bd-11e5-8a40-8338255b7e33 | 2013-10-16 01:00:00.000000+0000 |        Formation 1FORM@

 (5 rows)
 
```
____
###### 8°) Utilisez la commande SELECT COUNT(*) pour compter le nombre de lignes importées.
###### Le nombre doit correspondre au nombre de lignes que la commande d'import (COPY) a indiqué.
____
```sql
SELECT COUNT(*) FROM cours;
```

```text
La table cours est définie ainsi : 

Nom de col :		Type :

cours_id			timeuuid
ajout_date	     	timestamp
intitule			text

Clé primaire : 	cours_id

```

____

```sql
USE EntrepriseFormation;

DESCRIBE EntrepriseFormation.cours ;
```

```text 

	CREATE TABLE entrepriseformation.cours (
		cours_id timeuuid PRIMARY KEY,
		ajout_date timestamp,
		intitule text
	) WITH bloom_filter_fp_chance = 0.01
		AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
		AND comment = ''
		AND compaction = {'class': 'org.apache.cassandra.db.compaction.SizeTieredCompactionStrategy', 'max_threshold': '32', 'min_threshold': '4'}
		AND compression = {'chunk_length_in_kb': '64', 'class': 'org.apache.cassandra.io.compress.LZ4Compressor'}
		AND crc_check_chance = 1.0
		AND dclocal_read_repair_chance = 0.1
		AND default_time_to_live = 0
		AND gc_grace_seconds = 864000
		AND max_index_interval = 2048
		AND memtable_flush_period_in_ms = 0
		AND min_index_interval = 128
		AND read_repair_chance = 0.0
		AND speculative_retry = '99PERCENTILE';
```


____
###### 9°) Creation d'un index 
____
```text
Sans index,  la Clause WHERE doit permettre de préciser le noeud visé 
et donc doit impérativement indiquer la (ou les) colonne(s) de la clé de partitionnement 

Ici on va donc créer un index pour pouvoir utiliser la clause WHERE en recherchant un intitule précis : 
CREATE INDEX index_intitule_cours on cours (intitule);
```


____
###### 10°) Regardons l'effet de la creation de l'index 
____

```cql
DESCRIBE EntrepriseFormation.cours ;
```

```text
CREATE TABLE entrepriseformation.cours (
    cours_id timeuuid PRIMARY KEY,
    ajout_date timestamp,
    intitule text
) WITH bloom_filter_fp_chance = 0.01
    AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
    AND comment = ''
    AND compaction = {'class': 'org.apache.cassandra.db.compaction.SizeTieredCompactionStrategy', 'max_threshold': '32', 'min_threshold': '4'}
    AND compression = {'chunk_length_in_kb': '64', 'class': 'org.apache.cassandra.io.compress.LZ4Compressor'}
    AND crc_check_chance = 1.0
    AND dclocal_read_repair_chance = 0.1
    AND default_time_to_live = 0
    AND gc_grace_seconds = 864000
    AND max_index_interval = 2048
    AND memtable_flush_period_in_ms = 0
    AND min_index_interval = 128
    AND read_repair_chance = 0.0
    AND speculative_retry = '99PERCENTILE';
CREATE INDEX index_intitule_cours on cours (intitule);
```


____
###### 11°) Utilisons l'index 
____

```cql
SELECT * FROM entrepriseformation. cours WHERE intitule = 'Qui sommes-nous?';
```

```text
 cours_id                             | ajout_date                      | intitule
--------------------------------------+---------------------------------+------------------
 5645f8bd-14bd-11e5-af1a-8638355b8e3a | 2013-04-16 01:00:00.000000+0000 | Qui sommes-nous?
 
(1 rows)
```


____
###### 12°) Cas d'usage des index secondaires :
```text

Utilisation sur des colonnes à faible cardinalité :
=> C'est à dire des colonnes qui contiennent relativement peu de valeurs distinctes

Exemple : 
- Sur une grande quantité de livres, mais répartis en quelques genres seulement (12 types : thriller, policier ,etc)
- Permet de rechercher tous les livres d'un certain genre :
  => requête potentiellement très coûteuse car susceptible de retourner un grand nombre de résultat)

=> A utiliser sur des petits jeux de données ou pour du prototypage

A ne surtout pas utiliser : 
- Sur des colonnes à fortes cardinalités (beaucoup de valeurs distinctes : exemple sur une colonne avec des adresses mail) 
- Sur des tables avec des colonnes de type compteur
- Sur des colonnes fréquemment mises à jour ou deletées
- Pour requêter dans une rangée sur une grande partition, sauf si la recherche porte sur la clé de partition et une colonne indexée
```


____
###### 13°) Drop d'un index 
____

```cql
DROP INDEX index_intitule_cours;
```


____
###### 14°) Rappel de quelques commandes : 
____

```cql
DESCRIBE CLUSTER;
```

```cql
DESCRIBE KEYSPACES;
```

```cql
DESCRIBE TABLES;
```
 
 
____
###### 15°) Pour quitter CQLSH, entrez la commande : 
____
###### 
```cql
QUIT
```
######  ou :
```cql
EXIT
```


____
###### 16°) Allons plus loin : 
____

###### Prenons cet exemple : 
```cql
CREATE TABLE restaurants_par_ville (
    nom TEXT,
    ville TEXT,
    cuisine TEXT,
    prix int,
    PRIMARY KEY ((ville), nom)
);
```
  
  
###### Quel index secondaire permet de faire la requête suivante : 
```cql
SELECT * FROM restaurants_par_ville
  WHERE ville = 'Sydney'
  AND cuisine = 'sushi';
```


###### Solution : 
```cql
CREATE INDEX cuisine_restaurants_par_ville_2i
  ON restaurants_par_ville (cuisine);
```

###### Remarque : des index secondaires portant sur des colonnes multiples ne sont pas possibles dans Cassandra 

____
##### Fin du TP15a : Index secondaire                                 
____
