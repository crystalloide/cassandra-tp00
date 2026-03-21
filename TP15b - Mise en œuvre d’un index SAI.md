____
##### TP15b - Mise en œuvre d’index SAI
____

##### Temps estimé : 10 minutes

____
##### La fonctionnalité Storage-Attached Indexing (SAI) permet de créer un ou plusieurs index secondaires sur la même table de base de données, 
##### chaque index SAI étant basé sur n'importe quelle colonne. 
____
##### SAI offre plus de fonctionnalités par rapport aux index secondaires Cassandra, 
##### est plus rapide en écriture par rapport à n'importe quel index de recherche Cassandra ou DSE 
##### et utilise beaucoup moins d'espace disque.
____

____
##### Dans ce TP, nous allons :
##### 	- Créer des index SAI sur des colonnes
##### 	- Effectuer des requêtes SELECT basées sur des colonnes indexées
____

____
##### Quand utiliser SAI :
```text
 Les index vous permettent d'interroger des colonnes en dehors de la clé de partition Cassandra sans utiliser "ALLOW FILTERING" 
 ou devoir créer des tables personnalisées pour chaque modèle de requête, 
 comme vous le feriez selon les meilleures pratiques classiques de modélisation de données Cassandra . 
 
 Vous pouvez créer une table qui vous convient le mieux, écrire uniquement dans cette table et l'interroger comme vous le souhaitez. 
 vos requêtes ne sont pas limitées par votre clé primaire.
```
____
##### Définition des index SAI :
##### Après avoir créé votre base de données, un espace de clés et une ou plusieurs tables, 
##### utilisez les commandes DDL CREATE CUSTOM INDEX ... USING 'StorageAttachedIndex' pour définir un ou plusieurs index SAI 
##### sur la table que vous souhaitez indexer.

____
##### Interroger votre table :
##### Une fois l'index créé, il suffit d'interroger la table et de spécifier les colonnes indexées SAI.

```bash
docker exec -it cassandra01 cqlsh
```

```sql
CREATE KEYSPACE formation WITH replication = {'class':'SimpleStrategy', 'replication_factor': 1} AND durable_writes = true;
```

```sql
describe keyspace formation;
```

```sql
use formation ;
```

```text
cqlsh:formation> CREATE TABLE IF NOT EXISTS products (
             ...   product_id uuid,
             ...   product_name text,
             ...   description text,
             ...   price decimal,
             ...   created timestamp,
             ...   PRIMARY KEY (product_id)
             ... );
```			 
			 
```sql
CREATE TABLE formation.products (
    product_id uuid PRIMARY KEY,
    created timestamp,
    description text,
    price decimal,
    product_name text
) WITH additional_write_policy = '99PERCENTILE'
    AND bloom_filter_fp_chance = 0.01
    AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
    AND comment = ''
    AND compaction = {'class': 'org.apache.cassandra.db.compaction.UnifiedCompactionStrategy'}
    AND compression = {'chunk_length_in_kb': '64', 'class': 'org.apache.cassandra.io.compress.LZ4Compressor'}
    AND crc_check_chance = 1.0
    AND default_time_to_live = 0
    AND gc_grace_seconds = 864000
    AND max_index_interval = 2048
    AND memtable_flush_period_in_ms = 0
    AND min_index_interval = 128
    AND read_repair = 'BLOCKING'
    AND speculative_retry = '99PERCENTILE';
```

##### Il est prudent de mettre en place des garde-fous 
##### pour que les développeurs nouveaux/expérimentés prennent un bon départ lorsqu'ils utilisent Cassandra. 
##### L'une de ces meilleures pratiques consiste à utiliser un niveau de cohérence élevé lors de l'écriture des données. 
##### Par conséquent, avant de commencer à insérer des enregistrements, 
##### nous nous assurerons que le niveau de cohérence est défini sur LOCAL_QUORUM.

```cql
CONSISTENCY LOCAL_QUORUM
```

```text
Consistency level set to LOCAL_QUORUM.
```


##### Contenu de products.cql :
```cql
INSERT INTO products ( product_id , product_name , description, price, created ) VALUES (31047029-2175-43ce-9fdd-b3d568b19bb0,'Heavy Lift Arms', 'Heavy lift arms capable of lifting 1,250 lbs of weight per arm. Sold as a set.',4199.99,'2019-01-10 09:48:31.020+0040')IF NOT EXISTS;
INSERT INTO products ( product_id , product_name , description, price, created ) VALUES (31047029-2175-43ce-9fdd-b3d568b19bb1,'Precision Action Arms','Arms for precision activities in manufacturing or repair. Sold as a set.',12199.99,'2019-01-10 09:28:31.020+0040') IF NOT EXISTS;
INSERT INTO products ( product_id , product_name , description, price, created ) VALUES (31047029-2175-43ce-9fdd-b3d568b19bb2,'Medium Lift Arms','Medium lift arms capable of lifting 850 lbs of weight per arm. Sold as a set.',3199.99,'2019-01-10 09:23:31.020+0040') IF NOT EXISTS;
INSERT INTO products ( product_id , product_name , description, price, created ) VALUES (31047029-2175-43ce-9fdd-b3d568b19bb3,'Drill Arms','Arms for drilling into surface material. Sold as a set. Does not include drill bits.',2199.99,'2019-01-10 09:12:31.020+0040') IF NOT EXISTS;
INSERT INTO products ( product_id , product_name , description, price, created ) VALUES (31047029-2175-43ce-9fdd-b3d568b19bb4,'High Process AI CPU','Head processor unit for robot with heavy AI job process capabilities.',2199.99,'2019-01-10 18:48:31.020+0040') IF NOT EXISTS;
INSERT INTO products ( product_id , product_name , description, price, created ) VALUES (31047029-2175-43ce-9fdd-b3d568b19bb5,'Basic Task CPU','Head processor unit for robot with basic process tasks.',899.99,'2019-01-10 18:48:31.020+0040') IF NOT EXISTS;
INSERT INTO products ( product_id , product_name , description, price, created ) VALUES (31047029-2175-43ce-9fdd-b3d568b19bb6,'High Strength Torso','Robot body with reinforced plate to handle heavy workload and weight during jobs.',2199.99,'2019-01-10 18:48:31.020+0040') IF NOT EXISTS;
INSERT INTO products ( product_id , product_name , description, price, created ) VALUES (31047029-2175-43ce-9fdd-b3d568b19bb7,'Medium Strength Torso','Robot body to handle general jobs.',1999.99,'2019-01-10 18:48:31.020+0040') IF NOT EXISTS;
INSERT INTO products ( product_id , product_name , description, price, created ) VALUES (31047029-2175-43ce-9fdd-b3d568b19bb8,'Precision Torso','Robot torso built to handle precision jobs with extra stability and accuracy reinforcement.',8199.99,'2019-01-10 18:48:31.020+0040') IF NOT EXISTS;
```

##### 

```cql
SELECT * FROM products;
```

```text

	token@cqlsh:formation> SELECT * FROM products;

	 product_id                           | created                         | description                                                                                 | price    | product_name
	--------------------------------------+---------------------------------+---------------------------------------------------------------------------------------------+----------+-----------------------
	 31047029-2175-43ce-9fdd-b3d568b19bb1 | 2019-01-10 08:48:31.020000+0000 |                    Arms for precision activities in manufacturing or repair. Sold as a set. | 12199.99 | Precision Action Arms
	 31047029-2175-43ce-9fdd-b3d568b19bb3 | 2019-01-10 08:32:31.020000+0000 |        Arms for drilling into surface material. Sold as a set. Does not include drill bits. |  2199.99 |            Drill Arms
	 31047029-2175-43ce-9fdd-b3d568b19bb6 | 2019-01-10 18:08:31.020000+0000 |           Robot body with reinforced plate to handle heavy workload and weight during jobs. |  2199.99 |   High Strength Torso
	 31047029-2175-43ce-9fdd-b3d568b19bb0 | 2019-01-10 09:08:31.020000+0000 |              Heavy lift arms capable of lifting 1,250 lbs of weight per arm. Sold as a set. |  4199.99 |       Heavy Lift Arms
	 31047029-2175-43ce-9fdd-b3d568b19bb8 | 2019-01-10 18:08:31.020000+0000 | Robot torso built to handle precision jobs with extra stability and accuracy reinforcement. |  8199.99 |       Precision Torso
	 31047029-2175-43ce-9fdd-b3d568b19bb2 | 2019-01-10 08:43:31.020000+0000 |               Medium lift arms capable of lifting 850 lbs of weight per arm. Sold as a set. |  3199.99 |      Medium Lift Arms
	 31047029-2175-43ce-9fdd-b3d568b19bb4 | 2019-01-10 18:08:31.020000+0000 |                       Head processor unit for robot with heavy AI job process capabilities. |  2199.99 |   High Process AI CPU
	 31047029-2175-43ce-9fdd-b3d568b19bb7 | 2019-01-10 18:08:31.020000+0000 |                                                          Robot body to handle general jobs. |  1999.99 | Medium Strength Torso
	 31047029-2175-43ce-9fdd-b3d568b19bb5 | 2019-01-10 18:08:31.020000+0000 |                                     Head processor unit for robot with basic process tasks. |   899.99 |        Basic Task CPU

	(9 rows)
```


##### Création et utilisation d'un index : 

##### Essayons maintenant une petite expérience. 
##### Supposons que la seule connaissance que nous ayons d'un produit particulier soit son nom. 
##### Par exemple, que faire si nous voulons en savoir plus sur le produit "Drill Arms" ? 
##### Nous lançons une requête basée sur ce nom là (exécutez et essayez) :

```cql
SELECT * FROM products WHERE product_name = 'Drill Arms';
```
##### Qu'est-ce qui vient juste de se passer ? 

##### Vous devriez voir un message d'erreur :
```text
		token@cqlsh:formation> SELECT * FROM products WHERE product_name = 'Drill Arms';
		InvalidRequest: Error from server: code=2200 [Invalid query] message="Cannot execute this query as it might involve data filtering and thus may have unpredictable performance. 
		If you want to execute this query despite the performance unpredictability, use ALLOW FILTERING"
```

##### Qu'est-ce que "ALLOW FILTERING" :

##### Si nous jetons un autre coup d'œil à notre modèle de données, 
##### il devient évident pourquoi cela s'est produit :
```text
CREATE TABLE IF NOT EXISTS products (
  product_id uuid,
  product_name text,
  description text,
  price decimal,
  created timestamp,
  PRIMARY KEY (product_id)
);
```

##### Cette table est destinée à être interrogée en spécifiant sa clé primaire, product_id. 
##### Mais que faire si nous ne voulons pas être limités par cela? 
##### Nous pourrions créer différentes tables avec une clé primaire basée sur la colonne sur laquelle nous voulons interroger, 
##### mais cela créerait beaucoup de redondance de données. 

##### La solution ici serait d'utiliser des index secondaires ; plus précisément, les SAI (Storage Attached Indexes), 
##### qui sont disponibles dans DSE 6.8 et Astra DB.

##### La création d'index SAI est simple. Créons un index sur la colonne de clé non primaire "product_name" dans CQLSH :
```cql
CREATE CUSTOM INDEX products_name_idx ON products (product_name) USING 'StorageAttachedIndex' WITH OPTIONS = {'case_sensitive': false, 'normalize': true };
```
##### Quelles sont les options ?
##### Vous devriez maintenant pouvoir rechercher/filtrer la table "products" en fonction de colonne "product_name". 
##### Essayons:
```cql
SELECT * FROM products WHERE product_name = 'Drill Arms';
```

##### Vous pouvez voir comment cela pourrait être très utile!
##### Vous avez créé votre premier index SAI !


##### Essayez les opérateurs de requête :
##### Vous pouvez utiliser SAI pour ajouter des index au niveau des colonnes à n'importe quelle colonne 
##### et à presque tous les types de données Cassandra, y compris les types numériques, de texte et de collection. 
##### Cela vous permet de filtrer les requêtes à l'aide de l'égalité CQL, de la plage (numérique uniquement) et de la sémantique CONTAINs.


##### Maintenant que vous avez eu un 1er aperçu des index SAI à utiliser, 
##### Essayons quelques-uns des opérateurs pris en charge.

##### Opérateurs de requête pris en charge pour les tables avec des index SAI :

	Chiffres : =, <, >, <=, >=, ET
	Chaînes : =, CONTIENT, CONTIENT la clé, CONTIENT DES VALEURS ET
	Non pris en charge : LIKE, IN, OR

##### Créons un autre index, cette fois sur la colonne "created" : 
```cql
CREATE CUSTOM INDEX products_created_idx ON products (created) USING 'StorageAttachedIndex';
```

##### Essayez maintenant de sélectionner les produits qui ont été créés à un moment précis : 
```cql
SELECT * FROM products WHERE created = '2019-01-10 18:48:31.020+0040';
```

##### Ensuite, nous sélectionnerons dans products ce qui a été créé entre deux heures différentes de la journée le 2019-01-10 :
```cql
SELECT * FROM products WHERE created >= '2019-01-10 09:12:31.020+0040' AND created <= '2019-01-10 18:48:31.020+0040';
```
##### Tous les produits créés entre 2019-01-10 09:12:31.020+0040 et 2019-01-10 18:48:31.020+0040 sont bien retournés.

##### Enfin, essayez de sélectionner un produit créé à un moment précis, avec un certain nom de produit : 
```cql
SELECT * FROM products WHERE created = '2019-01-10 18:48:31.020+0040' AND product_name = 'Precision Torso';
```

##### Si jamais vous devez supprimer un index, utilisez la commande DROP INDEX : 
```cql
DROP INDEX IF EXISTS products_created_idx;
```

____
##### Fin du TP
____
