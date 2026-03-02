________
##### TP N°03 : Partitions 
________

##### Vérifier que Cassandra est en cours d'exécution avant de faire le TP :  
________
```bash
docker exec -it cassandra01 nodetool status
```
________ 
##### Etapes du TP : 
________

##### 1°) Lancer CQLSH en ligne de commande : 
```bash
docker exec -it cassandra01 cqlsh
```
________
2) Sélectionner le Keyspace EntrepriseFormation avec la commande USE :
________
```sql
USE EntrepriseFormation;
```

________
##### 3) Lancez la commande suivante pour visualiser les métadonnées de la table des cours créée précédemment : 
________
```sql
DESCRIBE TABLE cours;
```

##### Résultat de la commande : 

    CREATE TABLE entrepriseformation.cours (
        cours_id timeuuid PRIMARY KEY,
        ajout_date timestamp,
        intitule text
    ) WITH additional_write_policy = '99p'
        AND allow_auto_snapshot = true
        AND bloom_filter_fp_chance = 0.01
        AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
        AND cdc = false
        AND comment = ''
        AND compaction = {'class': 'org.apache.cassandra.db.compaction.SizeTieredCompactionStrategy', 'max_threshold': '32', 'min_threshold': '4'}
        AND compression = {'chunk_length_in_kb': '16', 'class': 'org.apache.cassandra.io.compress.LZ4Compressor'}
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


________
##### Question 1 : Quelle est la clé de partition ?
##### Réponse 1 :  La clé de partition est : cours_id
________
##### Question 2 : Combien de partitions possède cette table ?
##### Réponse 2 : 	Autant qu'il y a de valeurs distinctes de la clé primaire.

________
##### 4°) Lancer la requête suivante pour les valeurs de tokens pour chaque valeur de cours_id :
________
```sql
SELECT token(cours_id), cours_id FROM cours;
```

##### Résultat de la requête : 

     cqlsh:entrepriseformation> SELECT token(cours_id), cours_id FROM cours;
 
     system.token(cours_id) | cours_id
     ------------------------+--------------------------------------
        -7805440677194688247 | 245e8024-14bd-11e5-9743-8238356b7e32
        -1963973032031712291 | 3452f7de-14bd-11e5-855e-8738355b7e3a
        -1613479371119279545 | 5645f8bd-14bd-11e5-af1a-8638355b8e3a
         3855558958565172223 | 1645ea59-14bd-11e5-a993-8138354b7e31
         7966101712501124149 | 4845ed97-14bd-11e5-8a40-8338255b7e33
   

________
##### 5°) Quitter cqlsh et regarder le contenu du fichier ./donnees/cours-par-theme.csv :
________
```sql
exit
```

```bash
cat ./donnees/cours-par-theme.csv
```

##### Résultat de la commande : 
    
    tag,cours id,ajout date,intitule
    cassandra,1645ea59-14bd-11e5-a993-8138354b7e31,2014-01-29,Histoire de Cassandra
    cassandra,245e8024-14bd-11e5-9743-8238356b7e32,2012-04-03,Cassandra & SSDs
    cassandra,3452f7de-14bd-11e5-855e-8738355b7e3a,2013-03-17,Introduction a Cassandra
    1FORM@,4845ed97-14bd-11e5-8a40-8338255b7e33,2013-10-16,Formation 1FORM@
    1FORM@,5645f8bd-14bd-11e5-af1a-8638355b8e3a,2013-04-16,Qui sommes nous?

##### Remarque : Ces enregistrements sont composés des informations suivantes : tag, cours_id, ajout_date, intitule


##### Le fichier .csv est trié par tag (thème) : cassandra et 1FORM@


##### 6°) Relancer cqlsh et sélectionner le keyspace EntrepriseFormation
________
```bash
docker exec -it cassandra01 cqlsh
```
```sql
USE EntrepriseFormation;
```


________
##### 7°) Exécuter une requête avec la commande CREATE TABLE pour enregistrer les données partitionnées par 'themes'. 
________
##### Avec le jeu de données fourni, cela devrait donner deux partitions, une partition pour chaque 'theme'. 
##### Nommez votre table "cours_par_theme".

```sql
CREATE TABLE cours_par_theme (theme TEXT,cours_id UUID, ajout_date TIMESTAMP, intitule TEXT, PRIMARY KEY ((theme), cours_id));
```

________
##### 8°) Lancer la commande COPY pour importer les données du fichier cours-par-theme.csv
________
```sql
COPY cours_par_theme(theme,cours_id,ajout_date,intitule) FROM './donnees/cours-par-theme.csv' WITH HEADER = TRUE;
```

________
##### 9°) Vérifier que le CQL a importé effectivement les données avec une requête de type SELECT *
________

```sql
SELECT * FROM cours_par_theme;
```

##### Résultat de la requête : 
    
     theme     | cours_id                             | ajout_date                      | intitule
    -----------+--------------------------------------+---------------------------------+--------------------------
     cassandra | 1645ea59-14bd-11e5-a993-8138354b7e31 | 2014-01-29 00:00:00.000000+0000 |    Histoire de Cassandra
     cassandra | 245e8024-14bd-11e5-9743-8238356b7e32 | 2012-04-03 00:00:00.000000+0000 |         Cassandra & SSDs
     cassandra | 3452f7de-14bd-11e5-855e-8738355b7e3a | 2013-03-17 00:00:00.000000+0000 | Introduction a Cassandra
        1FORM@ | 4845ed97-14bd-11e5-8a40-8338255b7e33 | 2013-10-16 00:00:00.000000+0000 |         Formation 1FORM@
        1FORM@ | 5645f8bd-14bd-11e5-af1a-8638355b8e3a | 2013-04-16 00:00:00.000000+0000 |         Qui sommes nous?
    
    (5 rows)

________
##### Si la clé primaire n'avait contenu que le champ "theme", 
##### alors la table ne contiendrait plus que 2 enregistrements. 
##### C'est pour cette raison que l'on inclut le champ 'cours_id' comme colonne cluster.
________

________
##### Refaire les étapes 8 et 9 : voyez-vous une différence ? Pourquoi ?
________

________
##### 10°) Requête de SELECT pour retrouver tous les enregistrements en relation avec le theme 'cassandra'
________
```sql
SELECT * FROM cours_par_theme WHERE theme = 'cassandra';
```
	
________
##### 11) On extrait tous les cours concernant le thème 1FORM@ : 
________
```sql
SELECT * FROM cours_par_theme WHERE theme = '1FORM@';
```

________
##### 12) On recherche maintenant les cours qui contiennent les mots "Introduction a Cassandra"
________
```sql
SELECT * FROM cours_par_theme WHERE intitule = 'Introduction a Cassandra';
```

##### Remarque importante : cette requête échoue !!!  
##### Cassandra n'autorise que les requêtes sur la clé de partition (et les colonnes clusters qui seront vues plus tard dans le cours) 
##### Puisque 'intitule' n'est pas la clé de partitionnement, Cassandra retourne une erreur sur la requête. 
##### Si Cassandra autorisait les requêtes sur des colonnes qui ne sont pas "de partitionnement", 
##### Cassandra devrait alors scanner toutes les partitions (tous les noeuds) afin de produire la liste de résultats, 
##### ce qui est contraire au principe de base de Cassandra.
________


```sql
SELECT * FROM cours_par_theme WHERE intitule = 'Introduction a Cassandra' ALLOW FILTERING ;
```

##### Résulat de la requête : 

#####  theme     | cours_id                             | ajout_date               | intitule
##### -----------+--------------------------------------+--------------------------+-----------------
#####  cassandra | 3452f7de-14bd-11e5-855e-8738355b7e3a | 2013-03-17 00:00:00+0000 | Introduction a Cassandra
##### 
##### (1 rows)
##### 
________

```sql
DESCRIBE entrepriseformation.cours_par_theme ;
```

##### Résulat de la requête : 
CREATE TABLE entrepriseformation.cours_par_theme (
    theme text,
    cours_id uuid,
    ajout_date timestamp,
    intitule text,
    PRIMARY KEY (theme, cours_id)


________
##### Synthèse : 
________
##### - On ne peut (doit) requêter qu'en spécifiant la clé de partition 
##### - et on peut trier uniquement sur une clé de clustering ( = partie de la clé primaire autre que la clé de partition): 
________
```sql
SELECT * FROM entrepriseformation.cours_par_theme
WHERE theme = 'cassandra'
ORDER BY ajout_date ASC;
```

```sql
SELECT * FROM entrepriseformation.cours_par_theme
WHERE theme = 'cassandra'
ORDER BY cours_id ASC;
```

##### Affichage :
  
##### cqlsh:entrepriseformation> SELECT * FROM entrepriseformation.cours_par_theme
#####                        ... WHERE theme = 'cassandra'
#####                        ... ORDER BY cours_id ASC;
##### 
#####  theme     | cours_id                             | ajout_date                      | intitule
##### -----------+--------------------------------------+---------------------------------+--------------------------
#####  cassandra | 1645ea59-14bd-11e5-a993-8138354b7e31 | 2014-01-29 00:00:00.000000+0000 |    Histoire de Cassandra
#####  cassandra | 245e8024-14bd-11e5-9743-8238356b7e32 | 2012-04-03 00:00:00.000000+0000 |         Cassandra & SSDs
#####  cassandra | 3452f7de-14bd-11e5-855e-8738355b7e3a | 2013-03-17 00:00:00.000000+0000 | Introduction a Cassandra
##### 


________
##### On ne peut faire un GROUP BY que sur une colonne de la clé primaire (autre que la clé de partition =>  clé de clustering ): 
________
```sql
SELECT COUNT(*)
FROM entrepriseformation.cours_par_theme
WHERE theme = 'cassandra'
GROUP BY ajout_date;
```

```sql
SELECT COUNT(*)
FROM entrepriseformation.cours_par_theme
WHERE theme = 'cassandra'
GROUP BY cours_id;
```

##### Affichage :  

##### cqlsh:entrepriseformation> SELECT COUNT(*)
#####                        ... FROM entrepriseformation.cours_par_theme
#####                        ... WHERE theme = 'cassandra'
#####                        ... GROUP BY cours_id;
##### 
#####  count
##### -------
#####      1
#####      1
#####      1
##### 
##### (3 rows)
##### 



________
##### On peut faire un COUNT(*) : 
________
```sql
SELECT COUNT(*) FROM entrepriseformation.cours_par_theme;
```

##### Affichage :  
##### 
##### count
##### -------
#####      5
##### 
##### (1 rows)
##### 
##### Warnings :
##### Aggregation query used without partition key
##### 


________
##### Sortir de CQLSH : 
________
```sql
exit
```


________
##### Utilisation de nodetool describering "nom du keyspace" :
________ 
```bash
docker exec -it cassandra01 nodetool describering entrepriseformation
```

##### Affichage :  

##### 	Schema Version:c84df29c-1102-36e8-83de-8437cef1df24
##### 	Keyspace: entrepriseformation
##### 	TokenRange: 
		TokenRange(start_token:7623951828721033563, end_token:7785936581073354093endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:7785936581073354093, end_token:7788648710482429861endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-6788591963689036863, end_token:-6768492383777754259endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:4299770232866265927, end_token:4670644742563166231endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:1742837411655575929, end_token:1932237192768454977endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-5748236348746221569, end_token:-5606415705145558360endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:2568224245856531587, end_token:2860957674575838759endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:7360024699345338031, end_token:7418908232928114352endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:7418908232928114352, end_token:7623951828721033563endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-5901803264536605360, end_token:-5748236348746221569endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:3460876135151834595, end_token:3480259684461790882endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-7800984295232408291, end_token:-7512678050456324951endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:4670644742563166231, end_token:4806181429991689662endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:3480259684461790882, end_token:3577491738806773744endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-3484521047206676749, end_token:-3364486050124995310endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:2370801765343565760, end_token:2568224245856531587endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-370513920356477974, end_token:-287979547834166874endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:2198647525139090680, end_token:2370801765343565760endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:1522454276041964884, end_token:1742837411655575929endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-4263150319929115437, end_token:-4181642309827697127endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-9082866042896245054, end_token:-8820758783353856101endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-5312717217442679434, end_token:-5194236571203591767endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:8377913880169477132, end_token:8766851559616562647endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-4091935521210056232, end_token:-4057661378743841557endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-7512678050456324951, end_token:-6962571205330609111endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-8093124166766032880, end_token:-7949002462826125994endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-6768492383777754259, end_token:-6756721518646948642endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:3427889303586857440, end_token:3460876135151834595endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:4806181429991689662, end_token:5131870838997658526endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-2376182644184851286, end_token:-2144443592712495240endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-6898707174049670627, end_token:-6788591963689036863endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-5395020945551427389, end_token:-5374264953821406431endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-2824562519468359799, end_token:-2412101696198385058endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-287979547834166874, end_token:143751790938636540endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:1932237192768454977, end_token:2138215726731766668endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:8284622383564786125, end_token:8377913880169477132endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:8029724290408402689, end_token:8199526454566428200endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-4338000272040355768, end_token:-4263150319929115437endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-2980593748435926622, end_token:-2824562519468359799endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-5374264953821406431, end_token:-5312717217442679434endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-2144443592712495240, end_token:-2082892977374867779endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:5162110447849510888, end_token:5379998650194014366endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-6342096455870373996, end_token:-6060409975737967579endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-8820758783353856101, end_token:-8093124166766032880endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-2412101696198385058, end_token:-2376182644184851286endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:4112887262615108647, end_token:4299770232866265927endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:7322589609158370265, end_token:7360024699345338031endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:2860957674575838759, end_token:3112305801193221207endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:143751790938636540, end_token:239669782285519371endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:5850408226463962103, end_token:5969468450737709962endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:9017252158268207759, end_token:-9107947285685881723endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:3191335179883227608, end_token:3427889303586857440endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-1462183743673895177, end_token:-1381180389879975695endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:3577491738806773744, end_token:4112887262615108647endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-6523946152138459701, end_token:-6349847079363924025endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:6714804119621250847, end_token:6978129136733598886endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-5606415705145558360, end_token:-5395020945551427389endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-1381180389879975695, end_token:-916099800689020887endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-4181642309827697127, end_token:-4091935521210056232endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:8943000271816296244, end_token:9017252158268207759endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:7788648710482429861, end_token:7887209075905703537endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:6978129136733598886, end_token:7322589609158370265endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:5131870838997658526, end_token:5162110447849510888endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-764964159587288289, end_token:-370513920356477974endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-5060418973508490534, end_token:-4926078509190935726endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:8766851559616562647, end_token:8801958483900375577endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:416860088715069051, end_token:1522454276041964884endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-3300300928521130035, end_token:-2980593748435926622endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-9107947285685881723, end_token:-9082866042896245054endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-2082892977374867779, end_token:-1462183743673895177endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-4341768020588559468, end_token:-4338000272040355768endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-6349847079363924025, end_token:-6342096455870373996endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:8801958483900375577, end_token:8943000271816296244endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-7916178890966898833, end_token:-7800984295232408291endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:7887209075905703537, end_token:8029724290408402689endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-6574336836186328343, end_token:-6523946152138459701endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:5969468450737709962, end_token:6714804119621250847endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:8227203468202707177, end_token:8268297863680175784endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-6060409975737967579, end_token:-5901803264536605360endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-6962571205330609111, end_token:-6938884660418942604endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-4644371288245577914, end_token:-4341768020588559468endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-6756721518646948642, end_token:-6574336836186328343endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:8268297863680175784, end_token:8284622383564786125endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:3112305801193221207, end_token:3191335179883227608endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:2138215726731766668, end_token:2198647525139090680endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:239669782285519371, end_token:416860088715069051endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:5379998650194014366, end_token:5850408226463962103endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-3364486050124995310, end_token:-3300300928521130035endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-4057661378743841557, end_token:-3837220325168685120endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-6938884660418942604, end_token:-6898707174049670627endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-5194236571203591767, end_token:-5060418973508490534endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-3837220325168685120, end_token:-3484521047206676749endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-7949002462826125994, end_token:-7916178890966898833endpoints:[192.168.100.152]rpc_endpoints:[192.168.100.152]endpoint_details:[EndpointDetails(host:192.168.100.152, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-916099800689020887, end_token:-764964159587288289endpoints:[192.168.100.151]rpc_endpoints:[192.168.100.151]endpoint_details:[EndpointDetails(host:192.168.100.151, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:8199526454566428200, end_token:8227203468202707177endpoints:[192.168.100.154]rpc_endpoints:[192.168.100.154]endpoint_details:[EndpointDetails(host:192.168.100.154, datacenter:Cassandra, rack:rack1)])
		TokenRange(start_token:-4926078509190935726, end_token:-4644371288245577914endpoints:[192.168.100.153]rpc_endpoints:[192.168.100.153]endpoint_details:[EndpointDetails(host:192.168.100.153, datacenter:Cassandra, rack:rack1)])


________
##### Fin du TP N°03 : Partitions 

________




