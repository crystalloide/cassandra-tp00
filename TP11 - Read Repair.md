____ 
##### TP11 : Read Repair
____ 

##### Dans cet exercice, vous allez comprendre comment Cassandra effectue des opérations des read-repairs sur les données incohérentes.

##### Contexte du TP :  
```text
La cohérence des données représente un véritable challenge pour des systèmes distribués. 
Puisque les systèmes distribués privilégient la performance à la cohérence, certains noeuds d'un cluster peuvent devenir incohérents. 
Quand Cassandra identifie des incohérences, Cassandra entreprend de résoudre ces incohérences. 
Cette résolution s'appuie sur le principe du "Read-Repair".
```
____ 

```text
https://cassandra.apache.org/doc/latest/cassandra/managing/operating/read_repair.html
La réparation de lecture consiste à réparer les réplicas de données lors d'une requête de lecture. 
Si tous les réplicas impliqués dans une requête de lecture sont cohérents au niveau de cohérence donné, 
les données sont renvoyées au client et aucune réparation n'est nécessaire. 
En revanche, si les réplicas impliqués dans une requête de lecture ne sont pas cohérents au niveau de cohérence donné, 
une réparation est effectuée pour les rendre cohérents. 
Les données les plus récentes sont renvoyées au client. 
La réparation de lecture s'exécute en premier plan et est bloquante : 
aucune réponse n'est renvoyée au client tant que la réparation n'est pas terminée et que les données à jour ne sont pas générées.
```
____ 
##### ETAPES : 

____ 
##### 1°) Vérifiez que les trois noeuds sont opérationnels.

____ 
##### 2°) Nous allons stopper un des noeuds portant les réplicas de l'enregistrement "cassandra". 
____ 
##### En pré-requis, nous allons identifier quels sont ces noeuds, avec la commande suivante :
____ 
##### Sur cassandra01 :
```bash
docker exec -it cassandra01 nodetool getendpoints entrepriseformation cours_par_theme 'cassandra'
```

##### >> Conservez bien ces informations

##### Pour ce TP, on suppose la réponse en retour suivante :

```bash
192.168.100.153
192.168.100.152
```


____ 
##### 3°) Choisissez un de ces noeuds (x) et arrêtez-le. 
#####     Pour ce TP, on choisit le noeud 2 (192.168.100.152) :
#####     Mais auparavant, déclenchez un "flush" avec la commande suivante :
____ 

##### sur cassandra02 :
```bash
docker exec -it cassandra02 nodetool drain
```

____ 
##### 4°) Stoppez le noeud choisi (responsable d'un des réplicas de l'enregistrement 'cassandra') 
____ 
#####     Attendez l'arrêt effectif du noeud avant de continuer.
#####     Conservez bien le nom du noeud que vous avez arrêté.
____ 

##### sur cassandra02 :
```bash
docker stop cassandra02
```


____ 
##### 5°) Dans le répertoire /data/ du noeud stoppé, 
#####     trouvez le répertoire qui contient les données de la table "cours_par_theme". 

##### On va supprimez ce répertoire au complet.
____ 
##### sur cassandra02 :
```bash
ls -l /home/user/cassandra-tp00/docker/cassandra02/data/
```

##### ou, ce qui revient au même : 

```bash
docker exec -it cassandra02 ls -l /opt/cassandra/data/data
```
##### Affichage en retour : 
 
```text
total 24
drwxr-xr-x  3 cassandra cassandra 4096 Mar  8 14:59 entrepriseformation
drwxr-xr-x 26 cassandra cassandra 4096 Mar  8 14:47 system
drwxr-xr-x 10 cassandra cassandra 4096 Mar  8 14:47 system_auth
drwxr-xr-x  6 cassandra cassandra 4096 Mar  8 14:47 system_distributed
drwxr-xr-x 13 cassandra cassandra 4096 Mar  8 14:47 system_schema
drwxr-xr-x  4 cassandra cassandra 4096 Mar  8 14:47 system_traces
```


##### on supprime les données de la table sur ce noeud : 
```bash
ls /home/user/cassandra-tp00/docker/cassandra02/data/entrepriseformation/
```

```bash
cours_par_theme-6c5776901aff11f19734abd4487c5fc7
```

```bash
ls  /home/user/cassandra-tp00/docker/cassandra02/data/entrepriseformation/cours_par_theme-6c5776901aff11f19734abd4487c5fc7/
```

##### Affichage en retour : 
```text
nb-1-big-CompressionInfo.db  nb-1-big-Filter.db      nb-1-big-Summary.db          nb-2-big-Data.db       nb-2-big-Index.db       nb-2-big-TOC.txt             nb-3-big-Digest.crc32  nb-3-big-Statistics.db
nb-1-big-Data.db             nb-1-big-Index.db       nb-1-big-TOC.txt             nb-2-big-Digest.crc32  nb-2-big-Statistics.db  nb-3-big-CompressionInfo.db  nb-3-big-Filter.db     nb-3-big-Summary.db
nb-1-big-Digest.crc32        nb-1-big-Statistics.db  nb-2-big-CompressionInfo.db  nb-2-big-Filter.db     nb-2-big-Summary.db     nb-3-big-Data.db             nb-3-big-Index.db      nb-3-big-TOC.txt
```

```bash
sudo rm -rf /home/user/cassandra-tp00/docker/cassandra02/data/entrepriseformation/cours_par_theme-6c5776901aff11f19734abd4487c5fc7/
```


```bash
ls  /home/user/cassandra-tp00/docker/cassandra02/data/entrepriseformation/cours_par_theme-6c5776901aff11f19734abd4487c5fc7/
```

____ 
##### 6°) Lancez cqlsh sur l'un des noeuds actifs : 
____ 

```bash
docker exec -it cassandra01 cqlsh
```

##### Sélectionnez le KeySpace EntrepriseFormation. 
```sql
USE EntrepriseFormation;
```

##### On précise le niveau de cohérence fixé à "ONE".

```sql
CONSISTENCY ONE;
```


____ 
##### 7°) Lancez la requête suivante :
____ 

```sql
SELECT *
FROM EntrepriseFormation.cours_par_theme
WHERE theme = 'cassandra';
```

##### A quel résultat vous attendez-vous ? 

##### Nous avons bien tous les enregistrements en retour,
##### car un noeud portant les réplicas pour "cassandra" est toujours actif et contient les informations. 
##### Et la requête réussit car le niveau de cohérence est fixé à "ONE".

____ 
##### 8°) Stoppez maintenant l'autre noeud porteur du réplica de "cassandra" de la table cours_par_theme. 
#####     Attendez que le noeud s'arrête avant de poursuivre. Dans l'exemple, c'est cassandra03 :
____ 

##### Penser à forcer un flush pour matérialiser sur disque les éléments de la table : nodetool flush

##### sur cassandra03 :
```bash
docker exec -it cassandra03 nodetool flush
```

```bash
docker exec -it cassandra03 nodetool drain
```


##### sur cassandra03 :
```bash
docker stop cassandra03
```


____ 
##### 9°) Relancez le premier noeud stoppé (celui dont on a supprimé le répertoire). 
#####     Dans l'exemple, c'est cassandra02 :
#####     Attendez que le noeud soit complètement opérationnel avant de poursuivre.
____ 
##### sur cassandra02 :
```bash
docker start cassandra02
```

____ 
##### 10°) Dans l'interpréteur cqlsh du noeud relancé (celui dont on a supprimé les données), 

```bash
docker exec -it cassandra02 cqlsh
```

##### On va exécuter les requêtes suivantes : 

##### Sélectionnez le KeySpace EntrepriseFormation. 
```sql
USE EntrepriseFormation;
```

##### On précise le niveau de cohérence fixé à "ONE" (défaut).
```sql
CONSISTENCY ONE;
```

```sql
SELECT * FROM EntrepriseFormation.cours_par_theme WHERE theme = 'cassandra';
```


##### A quel résultat vous attendez-vous ? 


###### Résultat : 

```text

 theme | ajout_date | cours_id | intitule
-------+------------+----------+----------

(0 rows)

```

##### Le résultat est vide car les informations sur ce noeud concernant la table "cours_par_theme" étaient dans le répertoire supprimé 

____ 
##### 11°) Relancez le dernier noeud arrêté : (cassandra03 dans notre exemple)
#####      Attendez que le noeud soit complètement opérationnel avant de poursuivre. 

##### sur cassandra03 :
```bash
docker start cassandra03
```
____ 
##### 		Rappelez vous de quel noeud il s'agit, car nous allons l'arrêter à nouveau juste après avoir déclenché un "read repair"". 
##### 		Ce noeud que l'on relance contient toutes les données de la partition "cassandra".
____ 

##### sur cassandra03 :
```bash
docker exec -it cassandra03 nodetool status
```


____ 
##### 12°) On lance cqlsh : 
____

##### client CSQLSh en passant par le noeud cassandr03 :
```bash
docker exec -it cassandra03 cqlsh
```

##### On va exécuter les requêtes suivantes : 

##### Sélectionnez le KeySpace EntrepriseFormation. 
```sql
USE EntrepriseFormation;
```

##### On précise le niveau de cohérence fixé à "TWO"
```sql
CONSISTENCY TWO;
```
 
##### Le niveau de cohérence positionnée à "two" va obliger Cassandra à lire les deux réplicas, 
##### à identifier la différence de checksum, et donc à détecter que les données ne sont pas en phase entre les deux noeuds. 
##### Cassandra va alors déclencher un "read repair" afin de corriger le noeud sur lequel nous avons supprimé les données.



____ 
##### 13°) Exécutez la requête suivante:
____ 

```sql
SELECT * FROM EntrepriseFormation.cours_par_theme
WHERE theme = 'cassandra';
```

##### Les données sont bien revenues sur les deux noeuds.

____ 
##### 14°) Maintenant, stoppez le noeud récemment relancé (celui qui avait toutes les données de la table cours_par_theme.)
#####      (cassandra03 dans notre exemple)
____ 
##### sur cassandra03 :
```bash
docker stop cassandra03
```

____ 
##### 15°) Dans cqlsh, positionnnez la cohérence à "ONE" : 
____ 

##### On lance un client CQLsh vers cassandra01 :
```bash
docker exec -it cassandra01 cqlsh
```

##### Sélectionnez le KeySpace EntrepriseFormation. 
```sql
USE EntrepriseFormation;
```

##### On précise le niveau de cohérence fixé à "TWO"
```sql
CONSISTENCY ONE;
```

____ 
##### 16°) Exécutez la requête suivante : 
____ 
```sql
SELECT * FROM EntrepriseFormation.cours_par_theme WHERE theme = 'cassandra';
```sql


##### Cette fois-ci, les données proviennent exclusivement du noeud qui a été "réparé",
##### du fait de la précédente requête qui avait déclenché un ""read repair".

____ 
##### Fin du TP11 : Read Repair

____ 

