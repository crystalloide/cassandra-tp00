________
#### TP N°4: Anneau / Ring
________
##### Comprendre le fonctionnement en anneau de Cassandra (ring) :
________
##### Création d'un cluster de 2 noeuds dans un cluster VNode = 1 (noeud physique)
________
##### Contexte :
##### L'un des secrets de la performance d'Apache Cassandra est l'utilisation d'un ring sur lesquels sont répartis les tokens
##### (token = clé partition transformée par le partitionneur). 
##### Chaque noeud Cassandra sait exactement quels sont les noeuds qui gèrent un token donné

________
#### Etapes : 
________
##### 1°) Tout d'abord, il faut arrêter le cluster, avec les commandes suivantes : 
________
```bash
docker stop cassandra01
docker stop cassandra02
docker stop cassandra03
docker stop cassandra04
```
________
##### 2°) Bien attendre que les noeuds s'arrêtent avant de continuer :
________
```bash
docker ps -a 
```

    CONTAINER ID   IMAGE              COMMAND                  CREATED        STATUS                            PORTS     NAMES
    0c1f10a8aa9e   cassandra:latest   "docker-entrypoint.s…"   21 hours ago   Exited (137) 42 seconds ago                 cassandra04
    ceb7188a4005   cassandra:latest   "docker-entrypoint.s…"   21 hours ago   Exited (137) 53 seconds ago                 cassandra03
    179b51d0ffbb   cassandra:latest   "docker-entrypoint.s…"   21 hours ago   Exited (137) About a minute ago             cassandra02
    56830c3eeb15   cassandra:latest   "docker-entrypoint.s…"   21 hours ago   Exited (143) About a minute ago             cassandra01
	
	
________
##### 3°) Pour comprendre la gestion de la répartition des token, nous allons créer un cluster à 2 noeuds
________
##### 	   On supprime les données chargées dans les TPs précédents ;
________
```bash
cd ~/cassandra-tp00/docker
sudo rm -Rf cassandra01/*			#### On supprime tout l'historique et les données sur cassandra01
sudo rm -Rf cassandra02/*			#### On supprime tout l'historique et les données sur cassandra02
sudo rm -Rf cassandra03/*			#### On supprime tout l'historique et les données sur cassandra03
sudo rm -Rf cassandra04/*			#### On supprime tout l'historique et les données sur cassandra04
ls cassandra0*/
cd ~/cassandra-tp00/
```

________
##### 	   Et on paramètre les 2 noeuds pour une gestion manuelle des tokens :
________
##### Sur cassandra01 : modifier cassandra.yaml
```bash
gedit ~/cassandra-tp00/docker/cassandra01-conf/cassandra.yaml
```

#####  Noeud 1 : Repassons en gestion manuelle des tokens en mettant num_tokens à '1': 
```bash
num_tokens: 1
```
#####  et décommentez initial_token : 
```bash
initial_token: 0
```


#####  Le paramètre initial_token permet de spécifier les tokens manuellement.

    Remarque : Il faut mettre en commentaire le paramètre initial_token
    si on utilise les vnodes (c'est à dire si num_tokens > 1) 
	
    Dans le cas présent, vous pouvez spécifier une liste séparée par des virgules.
	
    C'était en effet ainsi que l'on ajoutait originellement des noeuds au cluster déjà existants sans vnodes.

##### Sur cassandra02 : modifier cassandra.yaml
```bash
gedit ~/cassandra-tp00/docker/cassandra02-conf/cassandra.yaml
```

##### Noeud 2 : Repassons en gestion manuelle des tokens en mettant num_tokens à '1': 
```bash
num_tokens: 1
```
##### et décommentez initial_token : 
```bash
initial_token: 6228280314724367774
```

##### Modifiez la valeur de : initial_token à 6228280314724367774 (mettre un espace entre ':' et la valeur). 
##### Le 2nd noeud gèrera la seconde moitié du range de token positif.

    Remarque : si on tentait de démarrer le 2nd noeud avec lui-aussi un intial_token à '0', 
    le 2nd noeud ne démarrerait pas, en retournant l'erreur suivante : 
    Bootstrapping to existing token 0 is not allowed (decommission/removenode the old node first).
    Fatal configuration error; unable to start server.  See log for stacktrace.
    ERROR [main] 2018-11-27 00:00:38,141  CassandraDaemon.java:818 - Fatal configuration error
    

________
##### 4°) On lance le 1er noeud cassandra01 :
________
```bash
docker start cassandra01
docker logs cassandra01 
sleep 30
```
```bash
docker exec -it cassandra01 cat /opt/cassandra/logs/system.log | grep 'state jump to NORMAL'
```
##### Attendez que le premier noeud soit bien démarré (= affichage du message type 'state jump to NORMAL'),
##### puis appuyez sur <Entrée> pour récupérer la ligne de commande

________
##### 5°) Vérifiez que le noeud n°1 s'exécute correctement avec la commande :
________
```bash
docker exec -it cassandra01 nodetool status
```
##### Affichage :
     
     Datacenter: dc1
     ===============
     Status=Up/Down
     |/ State=Normal/Leaving/Joining/Moving
     --  Address          Load        Owns (effective)  Host ID                               Token  Rack
     UN  192.168.100.151  114.33 KiB  100.0%            465a3a80-e0a6-4518-aa98-231566a01e66  0      Rack1
     
	 
________
##### 6°) Relancez le second noeud avec la commande : 
```bash
docker start cassandra02
docker logs cassandra02 
sleep 30
```
```bash
docker exec -it cassandra02 cat /opt/cassandra/logs/system.log | grep 'state jump to NORMAL'
```
##### Remarque : Ce noeud mettra plus de temps à démarrer et rejoindre le cluster.
________
##### Attendez bien que le second noeud soit démarré avant de continuer le TP.
________

    Datacenter: Cassandra
    =====================
    Status=Up/Down
    |/ State=Normal/Leaving/Joining/Moving
    --  Address          Load       Tokens       Owns    Host ID                               Rack
    UJ  192.168.100.152  41,29 KiB  1            ?       4e430812-8aa9-48da-b30e-af662e6f50b1  rack1
    UN  192.168.100.151  87,97 KiB  1            ?       5d916655-7699-4615-aec7-4a10d5e94142  rack1


________
##### 7°) Lancez à nouveau la commande 'nodetool status' pour voir le statut du cluster
________
```bash
docker exec -it cassandra01 nodetool status
```
    
    Datacenter: dc1
    ===============
    Status=Up/Down
    |/ State=Normal/Leaving/Joining/Moving
    --  Address          Load        Tokens  Owns (effective)  Host ID                               Rack
    UN  192.168.100.151  119.47 KiB  1       100.0%            465a3a80-e0a6-4518-aa98-231566a01e66  Rack1
    UN  192.168.100.152  30.89 KiB   1       100.0%            c895162a-3887-4db4-9b84-e8eed1c2994a  Rack2


________
##### 8°) Objectif : sur notre cluster à 2 noeuds : 
#####     Nous allons déterminer quel noeud contient quelles partitions de la table cours_par_theme 
________
##### (Passer cette étape si la copie des données sur cassandra01 a déjà été faite précédemment) 
     A partir d'un terminal Linux, on alimente un des noeuds (ici cassandra01) 
     avec les fichiers que l'on va charger ensuite :
	 
```bash
cd ~/cassandra-tp00
docker exec -it cassandra01 mkdir -p /donnees
docker cp ./donnees/cours.csv cassandra01:/donnees/cours.csv
docker cp ./donnees/cours-par-theme.csv cassandra01:/donnees/cours-par-theme.csv
docker exec -it cassandra01 chmod 775 -Rf /donnees
docker exec -it cassandra01 ls /donnees
docker exec -it cassandra01 cqlsh
```
```sql
CREATE KEYSPACE IF NOT EXISTS EntrepriseFormation WITH replication = {'class':'SimpleStrategy', 'replication_factor': 1};
USE EntrepriseFormation;
```
________
##### 9°) On récrée et recharge la table 'cours':
________
```sql
USE EntrepriseFormation;
DROP TABLE IF EXISTS cours; 
CREATE TABLE IF NOT EXISTS cours (cours_id TIMEUUID, ajout_date TIMESTAMP,intitule TEXT, PRIMARY KEY (cours_id));
```

```sql
COPY cours(cours_id,ajout_date,intitule) FROM '/donnees/cours.csv' WITH HEADER=TRUE;
```

```sql
SELECT * FROM cours;
```

##### Résultat de la requête : 

     cours_id                             | ajout_date                      | intitule
    --------------------------------------+---------------------------------+--------------------------
     245e8024-14bd-11e5-9743-8238356b7e32 | 2012-04-03 01:00:00.000000+0000 |         Cassandra & SSDs
     3452f7de-14bd-11e5-855e-8738355b7e3a | 2013-03-17 01:00:00.000000+0000 | Introduction a Cassandra
     5645f8bd-14bd-11e5-af1a-8638355b8e3a | 2013-04-16 01:00:00.000000+0000 |         Qui sommes-nous?
     1645ea59-14bd-11e5-a993-8138354b7e31 | 2014-01-29 01:00:00.000000+0000 |    Histoire de Cassandra
     4845ed97-14bd-11e5-8a40-8338255b7e33 | 2013-10-16 01:00:00.000000+0000 |        Formation 1FORM@ 

##### Regardons de plus près les tokens impliqués :
```sql
SELECT token(cours_id),cours_id FROM cours;
```

      system.token(cours_id) | cours_id
     ------------------------+--------------------------------------
        -7805440677194688247 | 245e8024-14bd-11e5-9743-8238356b7e32
        -1963973032031712291 | 3452f7de-14bd-11e5-855e-8738355b7e3a
        -1613479371119279545 | 5645f8bd-14bd-11e5-af1a-8638355b8e3a
         3855558958565172223 | 1645ea59-14bd-11e5-a993-8138354b7e31
         7966101712501124149 | 4845ed97-14bd-11e5-8a40-8338255b7e33
     
     (5 rows)
 
  
________
##### 10°) Puis on recrée la table 'cours_par_theme' :
________
```sql
CREATE TABLE cours_par_theme (theme TEXT,cours_id UUID, ajout_date TIMESTAMP, intitule TEXT, PRIMARY KEY ((theme), cours_id));
```

```sql
COPY cours_par_theme(theme,cours_id,ajout_date,intitule) FROM '/donnees/cours-par-theme.csv' WITH HEADER = TRUE;
```

```sql
SELECT * FROM cours_par_theme;
```

     Résultat de la requête : 
    
      theme     | cours_id                             | ajout_date                      | intitule
     -----------+--------------------------------------+---------------------------------+--------------------------
      cassandra | 1645ea59-14bd-11e5-a993-8138354b7e31 | 2014-01-29 01:00:00.000000+0000 |    Histoire de Cassandra
      cassandra | 245e8024-14bd-11e5-9743-8238356b7e32 | 2012-04-03 01:00:00.000000+0000 |         Cassandra & SSDs
      cassandra | 3452f7de-14bd-11e5-855e-8738355b7e3a | 2013-03-17 01:00:00.000000+0000 | Introduction a Cassandra
         1FORM@ | 4845ed97-14bd-11e5-8a40-8338255b7e33 | 2013-10-16 01:00:00.000000+0000 |         Formation 1FORM@
         1FORM@ | 5645f8bd-14bd-11e5-af1a-8638355b8e3a | 2013-04-16 01:00:00.000000+0000 |         Qui sommes nous?
     
     (5 rows)

##### Regardons de plus près les tokens impliqués :
```sql
SELECT token(theme),theme FROM cours_par_theme;
```

     Affichage du résultat de la requête :
    
      system.token(theme) | theme
     ---------------------+-----------
       356242581507269238 | cassandra
       356242581507269238 | cassandra
       356242581507269238 | cassandra
      6228280314724367775 |    1FORM@
      6228280314724367775 |    1FORM@
     
     
     (5 rows)
     

________
##### Combien de partitions y-t-il pour la table cours ? 
________
##### Combien de partitions y-t-il pour la table cours_par_theme ? 
________
##### Pour cours_par_theme, sur quel(s) noeud(s) réside(nt) quelle(s) partition(s) ?
##### Vous pouvez vous aider pour savoir quel noeud contient quels ranges de token, en passant la commande "nodetool ring"

##### Allons-y :  
```sql
exit
```

##### Utilisons **nodetool** **ring** :
```bash
docker exec -it cassandra01 nodetool ring
```

```text
Datacenter: Cassandra
==========
Address          Rack        Status State   Load            Owns                Token                                       
                                                                                6228280314724367774                         
192.168.100.151  rack1       Up     Normal  117,46 KiB      ?                   0                                           
192.168.100.152  rack1       Up     Normal  168,03 KiB      ?                   6228280314724367774 
```


##### Si on était en mode VNodes (noeuds logiques), on aurait : 
```text
Datacenter: Cassandra
==========
Address          Rack        Status State   Load            Owns                Token                                       
                                                                                9182585498027392616                         
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   -9223245761691305015                        
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   -9001411233921878659                        
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   -6451529490400418319                        
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   -6331071059786887605                        
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   -5502462926403927906                        
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   -5151518716733954119                        
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   -4865812991487230911                        
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   -4686662117020609827                        
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   -4589277629902406520                        
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   -4519341955053524228                        
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   -4304966749874030721                        
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   -3790915448222356172                        
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   -3704192414321088699                        
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   -3679706412540035777                        
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   -3515774096211335643                        
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   -2830995281623314127                        
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   -2361040142479385241                        
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   -2259668643174869380                        
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   -2001112480839316975                        
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   -1475785154902851578                        
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   -1046441655995904749                        
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   -781762133627427892                         
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   -511354990042522884                         
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   -165242179514535119                         
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   617634041154420569                          
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   705115867777137798                          
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   1305579881792888544                         
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   1703455916127014425                         
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   1863981107510145969                         
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   2144796348157359734                         
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   2345889752805553007                         
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   2508204703233522005                         
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   3902767836011988747                         
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   3953880818003957065                         
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   4108804865486480678                         
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   5008367461230283388                         
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   5015708625222456861                         
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   5124950831994402647                         
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   5328981240691218918                         
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   5699458504309858975                         
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   6131771133382777229                         
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   6440536805859782722                         
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   6537345579050958631                         
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   7194333590110235974                         
192.168.100.151  rack1       Up     Normal  117,11 KiB      ?                   7292281132339750183                         
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   7902198687114673177                         
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   7920972135010754259                         
192.168.100.152  rack1       Up     Normal  122,57 KiB      ?                   9182585498027392616  
```

________
##### 12°) Vous pouvez aussi détailler quelles partitions résident sur quels noeuds,
#####     avec cette fois la commande suivante : nodetool
________
#####     Quel noeud gère la clé de partition **cassandra** : 
```bash
docker exec -it cassandra01 nodetool getendpoints entrepriseformation cours_par_theme 'cassandra'
```
##### Affichage du résultat retourné : 
    192.168.100.152

#####     Quel noeud gère la clé de partition **1FORM@** : 
```bash
docker exec -it cassandra01 nodetool getendpoints entrepriseformation cours_par_theme '1FORM@'
```
##### Affichage du résultat retourné : 
    192.168.100.151
	
#####     Quel noeud gère la clé de partition **1Data-Hexagone** : 
```bash
docker exec -it cassandra01 nodetool getendpoints entrepriseformation cours_par_theme '1Data-Hexagone'
```

##### Affichage du résultat retourné : 
    192.168.100.152
________
#### la commande getendpoints renvoie les adresses IP du (ou des) noeud(s) qui contiennent les données partitions
#### correspondants à la clé de partition : dernier argument entre quote : ici  'cassandra' and '1FORM@' respectivement
#### 
#### A noter : il faut fournir aussi le keyspace et la table concernés, 
#### du fait que le facteur de réplication est basé sur le keyspace. 
#### Nous approfondirons plus tard dans le cours cet aspect de la réplication.
##
________
```bash
docker exec -it cassandra01 nodetool getendpoints entrepriseformation cours '245e8024-14bd-11e5-9743-8238356b7e32'
```
##### Affichage du résultat retourné : 
    192.168.100.151

________
##### 13°) Connaisance de l'emplacement des tokens, même seux pas encore utilisés :
    Cassandra n'a pas besoin d'avoir une partition déjà existante (donc pour une valeur de clé donnée)
    pour déterminer quels nœuds stockeront quelle partition.
	
    Vous pouvez ainsi essayer avec n'importe quelle valeur de clé de partition, vous saurez quel noeud en sera l'hôte.

#####  Par exemple, essayez :
________
```bash
docker exec -it cassandra01 nodetool getendpoints entrepriseformation cours_par_theme 'cuisine'
```

________

##### Fin du TP N°4: Anneau / Ring
________
