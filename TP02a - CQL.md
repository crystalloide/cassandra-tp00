_____________
####  TP N°2: CQL
#####  Création d'un keyspace pour EntrepriseFormation
#####  Création d'une table pour stocker les métadonnées des cours
#####  Chargement des données de la table des cours à partir d'un fichier en format .csv
_____________
####  Contexte du TP : 
#####  Bienvenue dans l'entreprise de formation : "EntrepriseFormation" 
#####  Vous avez été engagé pour construire la plus récente et performante entreprise de MOOC (ou cours) sur Internet 
#####  Votre mission est de monter en compétences sur ce sujet et devenir familier avec l'usage de Cassandra. 
#####  Pour débuter, vous décidez de créer une table et d'y charger des données sur les premiers cours.
_____________

#####   La table cours est définie ainsi : 

     Nom de colonne :		Type :
     
     cours_id				timeuuid
     ajout_date			timestamp
     intitule				text
_____________

####  Etapes : 
_____________

####  1°) Vérifier que Cassandra est bien en cours d'exécution, 
####  Dans un terminal, sur un des noeuds du cluster C*, avec la commande : 
```bash
docker exec -it cassandra01 bash
```
#### Affichons les logs sur le noeud cassandra01 :
```bash
cat /opt/cassandra/logs/system.log
nodetool status
```

#### équivalent à la commande :
```bash
/opt/cassandra/bin/nodetool status
exit
```

#### équivalent à la commande :
```bash
docker exec -it cassandra01 nodetool status 
```

_____________
####  Si C* n'est pas démarré sur le noeud que l'on veut interroger : un message de type suivant va apparaître :
     Connection refused to host: 127.0.0.1; nested exception is:
     java.net.ConnectException: Connection refused (Connection refused)
	 
#####  On peut vérifier si le noeud cassandra à bien démarré, utile si on a reçu le message "connection refused"
```bash
docker exec -it cassandra01 cat /opt/cassandra/logs/system.log | grep '151:7000 state jump to'
```
####  Le message suivant est signe que le démarrage est ok : 
     INFO  [main] 2026-03-02 10:10:29,989 StorageService.java:3281 - Node /192.168.100.151:7000 state jump to NORMAL

_____________
####  
####  Pour visualiser les paramètres définis dans le fichier de configuration cassandra.yaml du noeud cassandra01 : 
```bash
docker exec -it cassandra01 cat /opt/cassandra/conf/cassandra.yaml
```

```bash
docker exec -it cassandra01 cat /opt/cassandra/conf/cassandra.yaml | grep native_transport_port
```

####  Pour visualiser les logs du noeud cassandra01 : (par défaut : /var/log/cassandra/system.log)
```bash
docker exec -it cassandra01 cat /opt/cassandra/logs/system.log | tail -50
```

####  On regarde les options et niveaux de logging définis (toujours cassandra01 en exemple ici) :
```bash
docker exec -it cassandra01 nodetool getlogginglevels
```
##### Affichage en retour : 
     Logger Name                                        Log Level
     ROOT                                                    INFO
     org.apache.cassandra                                   DEBUG
	 
	 
#### Pour information, pour un Cassandra DSE : on aurait eu plus de composants et donc plus d'informations : 
     [cassandra@cassandra01 ~]$ nodetool getlogginglevels
     
     Logger Name                                        				Log Level
     ROOT                                                    			INFO
     DroppedAuditEventLogger                                 			INFO
     SLF4JAuditWriter                                        			INFO
     SolrValidationErrorLogger                              			ERROR
     com.cryptsoft                                            		    OFF
     com.datastax.bdp.search.solr.metrics.MetricsWriteEventListener    DEBUG
     com.thinkaurelius.thrift                               			ERROR
     org.apache.cassandra                                   			DEBUG
     org.apache.lucene.index                                 			INFO
     org.apache.solr.core.CassandraSolrConfig                			WARN
     org.apache.solr.core.RequestHandlers                	 	 	   	WARN
     org.apache.solr.core.SolrCore                          			WARN
     org.apache.solr.handler.component                       			WARN
     org.apache.solr.search.SolrIndexSearcher                			WARN
     org.apache.solr.update                                  			WARN

_____________

####  2°) On lance maintenant cqlsh :  (situé dans /opt/cassandra/bin/)
_____________

##### avec le client cqlsh installé en local (attention aux versions !!!) : 

```bash
pyenv activate cqlsh-env
cqlsh localhost 9142
```

     Exemple de warning possible en retour : 
     WARNING: cqlsh was built against 5.0.0, but this server is 5.0.6.  All features may not work!
	 
```bash
exit    # on sort de cqlsh et on revient sur la machine hôte
```

##### Méthode conseillée pour utiliser la version CQLSH adaptée à la version du cluster :  
```bash
docker exec -it cassandra01 cqlsh 
```
```bash
exit    # on sort de cqlsh et on revient sur la machine hôte
```

##### la commande précédente est équivalente à : 
```bash
docker exec -it cassandra01 cqlsh cassandra01 9042
```
```bash
exit    # on sort de cqlsh et on revient sur la machine hôte
```

##### équivalent à : 
```bash
docker exec -it cassandra01 cqlsh 127.0.0.1 9042
```
```bash
exit    # on sort de cqlsh et on revient sur la machine hôte
```


_____________
####  Une fois le client CQLSH lancé, l'invite de commande apparaît : 
     Connected to formation at localhost:9142
     [cqlsh 6.2.1 | Cassandra 5.0.6 | CQL spec 3.4.7 | Native protocol v5]
     Use HELP for help.
     cqlsh> exit
  

_____________
####  3°) Dans cqlsh, nous allons créer un keyspace nommé **EntrepriseFormation** 
_____________
####  Utilisons ici "SimpleStrategy" pour le type de réplication, avec un FR (Facteur de Réplication) de 1.
_____________
####  Dans une session shell CQLSH à partir d'un des 4 noeuds Cassandra : 
```sql
CREATE KEYSPACE IF NOT EXISTS "EntrepriseFormation" WITH replication = {'class':'SimpleStrategy', 'replication_factor': 1};
```

```sql
DESCRIBE KEYSPACES;
```

```sql
DESCRIBE KEYSPACE "EntrepriseFormation";
```

####  Remarque : si nécessaire, pour supprimer un KeySpace déjà existant : 
```sql
DROP KEYSPACE "EntrepriseFormation";
```

```sql
CREATE KEYSPACE EntrepriseFormation WITH replication = {'class':'SimpleStrategy', 'replication_factor': 1};
```

```sql
DESCRIBE KEYSPACES;
```

```sql
DESCRIBE KEYSPACE entrepriseformation;
---- Equivalent à : 
DESCRIBE KEYSPACE EntrepriseFormation;
```
_____________
####  4°) Dans cqlsh, sélectionnez le keyspace récemment créé avec la commande USE :
_____________
```sql
USE EntrepriseFormation;
```
####  L'invite de saisie de commande est changée :
####  cqlsh:entrepriseformation> ....

_____________
####  5°) Créez une table simple nommée "cours" avec la structure indiquée ci-dessus. "cours_id" sera la clé primaire.
_____________
```sql
DROP TABLE IF EXISTS cours;

CREATE TABLE cours (
  cours_id TIMEUUID,
  ajout_date TIMESTAMP,
  intitule TEXT,
  PRIMARY KEY (cours_id)
);
```
_____________
####      Si besoin, en cas d'erreur, pour supprimer la table cours du Keyspace EntrepriseFormation, 
####      exécutez la requête suivante : 
####      DROP TABLE EntrepriseFormation.cours;
_____________

_____________
####  6°) Insérez manuellement un enregistrement dans la table avec la commande INSERT :  
####  Insérez la première rangée de la table ci-dessous : 
_____________

     cours_id									ajout_date					intitule
     1645ea59-14bd-11e5-a993-8138354b7e31		2014-01-28					Histoire de Cassandra
     245e8024-14bd-11e5-9743-8238356b7e32		2012-04-03					Cassandra & SSDs
     3452f7de-14bd-11e5-855e-8738355b7e3a		2013-03-17					Introduction a Cassandra
     4845ed97-14bd-11e5-8a40-8338255b7e33		2013-10-16					Formation 1FORM@
     5645f8bd-14bd-11e5-af1a-8638355b8e3a		2013-04-16					Qui sommes-nous ?

```sql
INSERT INTO cours (cours_id,ajout_date,intitule)
VALUES (1645ea59-14bd-11e5-a993-8138354b7e31, '2014-01-28', 'Histoire de Cassandra');
```

_____________
####  7°) Exécutez une commande SELECT pour vérifier que l'enregistrement a bien été inséré : 
_____________
```sql
SELECT * FROM cours;
```

#####  La requête affiche en retour : 

     cours_id                             | ajout_date               | intitule
     --------------------------------------+--------------------------+-------------------
     1645ea59-14bd-11e5-a993-8138354b7e31 | 2014-01-28 00:00:00+0000 | Histoire de Cassandra
     
     (1 rows)


_____________
####  8°) Insérez le second enregistrement et vérifiez qu'il a bien été enregistré : 
_____________
```sql
INSERT INTO cours (cours_id, ajout_date, intitule)
VALUES (245e8024-14bd-11e5-9743-8238356b7e32, '2012-04-03', 'Cassandra & SSDs');
```

```sql
SELECT * FROM cours;
```

#####  NOTE : Vous devez retrouvez deux enregistrements dans la table des cours : 
     
####  La requête affiche bien en retour : 
      
     cours_id                             | ajout_date               | intitule
     -------------------------------------+--------------------------+-------------------
     245e8024-14bd-11e5-9743-8238356b7e32 | 2012-04-03 00:00:00+0000 |  Cassandra & SSDs
     1645ea59-14bd-11e5-a993-8138354b7e31 | 2014-01-28 00:00:00+0000 | Histoire de Cassandra
     

_____________
####  Pour récupérer le timestamp associé par Cassandra lors de l'écriture de la cellule : 
_____________
```sql
SELECT WRITETIME(intitule) FROM cours WHERE cours_id = 245e8024-14bd-11e5-9743-8238356b7e32;
```

####  Retourne une valeur de timestamp (EPOCH) 


_____________
####  Pour récupérer en JSON les informations : 
_____________
```sql
SELECT JSON * FROM cours WHERE cours_id = 245e8024-14bd-11e5-9743-8238356b7e32;
```

_____________
####  Utilisation de fonctions : CAST :  
_____________
```sql
SELECT CAST(ajout_date AS text) FROM cours WHERE cours_id = 245e8024-14bd-11e5-9743-8238356b7e32;
```

_____________
####  Utilisation d'alias : "as"  
_____________
```sql
SELECT CAST(ajout_date AS text) as dateajout FROM cours WHERE cours_id = 245e8024-14bd-11e5-9743-8238356b7e32;
```

_____________
####  Récupération d'un UUID avec la fonction NOW() :  
_____________
```sql
SELECT NOW() FROM cours;
```

_____________
####  Récupération de la date courante dans un format date :  
_____________
```sql
SELECT CurrentDate() FROM cours;
```

_____________
####  Récupération de l'heure courante dans un format horaire :  
_____________
```sql
SELECT CurrentTime() FROM cours;
```

_____________
####  Récupération du Timestamp courant :  
####  permet de récupérer l'heure système du noeud qui répond (avant de faire une insertion par exemple)  
_____________
```sql
SELECT CurrentTimestamp() FROM cours;
```

_____________
####  Possibilité de créer ses propres fonctions (UDF) : Java ou JavaScript (python nécessite un interpréteur)
####  Voir ici : https://cassandra.apache.org/doc/stable/cassandra/cql/functions.html
_____________


_____________
####  Pour récupérer des informations en spécifiant une égalité sur une ou plusieurs clés de partition :
_____________
```sql
SELECT intitule FROM cours WHERE cours_id IN (245e8024-14bd-11e5-9743-8238356b7e32, 1645ea59-14bd-11e5-a993-8138354b7e31);
```

_____________
####  ! A proscrire ! récupérer des informations en ne spécifiant pas d'égalité sur la clé de partition :
_____________
```sql
SELECT intitule FROM cours WHERE cours_id > 245e8024-14bd-11e5-9743-8238356b7e32
ALLOW FILTERING ;
```

_____________
####  Pour supprimer une cellule précise : 
_____________
```sql
DELETE intitule FROM cours WHERE cours_id = 245e8024-14bd-11e5-9743-8238356b7e32;
```

_____________
####  Pour forcer une lecture avant un update : 
_____________
```sql
UPDATE cours 
SET intitule = 'Cassandra & SSDs'
WHERE cours_id = 245e8024-14bd-11e5-9743-8238356b7e32
IF EXISTS;
```

####  Transaction distribuée avec un protocole de consensus de type Paxos
####  ! Impact significatif sur la performance !

####  Les clauses "IF EXISTS" ou "IF NOT EXISTS" sont utilisables sur un INSERT, UPDATE, DELETE
####  La clauses "IF EXISTS" est souvent utilisablée lors d'un UPDATE ou un DELETE
####  La clause "IF NOT EXISTS" est souvent utilisée lors d'un INSERT

```sql
UPDATE cours 
SET intitule = 'Cassandra & SSDs & Divers'
WHERE cours_id = 245e8024-14bd-11e5-9743-8238356b7e32
IF intitule = 'Cassandra & SSDs';
```
_____________
####  Pour supprimer une ligne complète : 
_____________
```sql
DELETE FROM cours WHERE cours_id = 245e8024-14bd-11e5-9743-8238356b7e32;
```

_____________
####  9) Pour supprimer toutes les données enregistrées de la table avec la commande TRUNCATE : 
_____________
```sql
TRUNCATE cours;
```
```sql
SELECT * FROM cours;
```
_____________
####  NOTE : la table des cours est maintenant vidée de ses enregistrements : 
####  La requête affiche en retour : 

     cours_id | ajout_date | intitule
     ----------+------------+-------
     
     (0 rows)
     


_____________
####  10°) Pour importer les données dans la table "cours" à partir d'un fichier cette fois : 
_____________
```sql
COPY cours(cours_id,ajout_date,intitule)
FROM '/sources/donnees/cours.csv'
WITH HEADER=TRUE;
```

####  
     cqlsh:entrepriseformation> COPY cours(cours_id, ajout_date, intitule) FROM '/sources/donnees/cours.csv' WITH HEADER=TRUE; Using 1 child processes
      
     Starting copy of entrepriseformation.cours with columns [cours_id, ajout_date, intitule].
     Processed: 5 rows; Rate:       9 rows/s; Avg. rate:      14 rows/s
     5 rows imported from 1 files in 0.368 seconds (0 skipped).
     

_____________
####  11°) Utilisation de la commande SELECT pour vérifier pour les données ont été effectivement chargées
_____________
```sql
SELECT * FROM cours;
```

     cqlsh:entrepriseformation> SELECT * FROM cours;
      
     cours_id                             | ajout_date                      | intitule
     --------------------------------------+---------------------------------+--------------------------
     245e8024-14bd-11e5-9743-8238356b7e32 | 2012-04-03 01:00:00.000000+0000 |         Cassandra & SSDs
     3452f7de-14bd-11e5-855e-8738355b7e3a | 2013-03-17 01:00:00.000000+0000 | Introduction a Cassandra
     5645f8bd-14bd-11e5-af1a-8638355b8e3a | 2013-04-16 01:00:00.000000+0000 |         Qui sommes-nous?
     1645ea59-14bd-11e5-a993-8138354b7e31 | 2014-01-29 01:00:00.000000+0000 |    Histoire de Cassandra
     4845ed97-14bd-11e5-8a40-8338255b7e33 | 2013-10-16 01:00:00.000000+0000 |        Formation 1FORM@
     
     (5 rows)
     



_____________
####  12°) Utilisation de la commande SELECT COUNT(*) pour compter le nombre de lignes importées.
####  Le nombre doit correspondre au nombre de lignes que la commande d'import (COPY) a indiqué.
_____________
```sql
SELECT COUNT(*) FROM cours;
```

     
     cqlsh:entrepriseformation> SELECT COUNT(*) FROM cours;
      
     count
     ------
       5
     
     (1 rows)
     
     Warnings :
     Aggregation query used without partition key
     

```sql
DESCRIBE CLUSTER;
```

```sql
DESCRIBE KEYSPACES;
```

```sql
DESCRIBE TABLES;
```

_____________
####  13°) Pour quitter CQLSH, entrez la commande : 
_____________
```sql
QUIT
```
#####  ou 
```sql
EXIT
```

_____________
####  Fin du TP N°2: CQL

_____________







