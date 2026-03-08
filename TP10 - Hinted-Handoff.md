____
##### TP10 : Hinted-handoff
____
##### Dans cet exercice, nous allons observer comment le mécanisme de hinted/handoff 
##### permet à Cassandra de rester cohérent lors de l'écriture des données
____
##### Contexte du TP : 
##### La disponibilité peut avoir un impact sur la cohérence des données. 
##### Le mécanisme de rejeu "Hinted-handoff" permet à Cassandra de conserver la cohérence des données, 
##### tout particulièrement lorsqu'un noeud est arrêté.
____

____
##### ETAPES : 
____

____
##### 1°) Vérifiez que tous les 3 noeuds précédents sont actifs avant de débuter le TP.
____

##### Sur cassandra02 :
```bash
docker exec -it cassandra02 nodetool status
```

____
##### 2°) Identifiez quels noeuds sont responsables de la partition cassandra pour la table cours_par_theme 
#####    en lançant la commande en ligne : 
____
##### Sur cassandra01 :
```bash
docker exec -it cassandra01 nodetool getendpoints entrepriseformation cours_par_theme 'cassandra'
```

##### Dans notre cas ici ( mais c'est à adapter selon votre cas) :
```bash
192.168.100.153
192.168.100.152
```

____
##### 3°) Stoppez les deux noeuds gérant la clé de partition "cassandra" ( x et y). 
#####     Attendez bien leur arrêt avant de poursuivre.
____
##### On arrête Cassandra0x et Cassandra0y : ici x = 02 / y = 03
```bash
docker stop cassandra02
docker stop cassandra03
```


____
##### 4°) Sélectionnez le KeySpace EntrepriseFormation :
____
##### Sur cassandra0z restant : ici 0z = 01
```bash
docker exec -it cassandra0z cqlsh
```

##### C'est dans notre cas : 
```bash
docker exec -it cassandra01 cqlsh
```

```sql
USE EntrepriseFormation;
```

____
##### 5°) Modifiez le niveau de cohérence à "ANY":
____
```sql
CONSISTENCY ANY;
```
____
##### NOTE : quand un client écrit en niveau de cohérence ANY, 
##### le stockage d'un seul hint est suffisant pour que l'écriture soit considérée comme valide et réussie.
##### Le niveau de cohérence "ONE" exige qu'au moins un noeud ait acquitté une écriture, 
##### un seul hint n'est pas suffisant dans ce cas.

____
##### 6°) Exécutez la commande d'insertion suivante : 
____
```sql
INSERT INTO cours_par_theme(theme,ajout_date,cours_id,intitule)
VALUES ('cassandra', '2016-02-11',uuid(), 'Cassandra, Je veux rentrer chez moi');
```

##### L'écriture réussit même si les deux noeuds contenant les réplicas sont arrêtés. 
##### Le seul et unique noeud restant du cluster stocke les écritures sous forme de hints
##### à destination des deux noeuds portant les réplicas, jusqu'à ce qu'ils redeviennent actifs.


```sql
EXIT;
```
___
_

##### 7°) Vous pouvez vérifier que le seul noeud restant (encore actif) a bien stocké un hint,
#####     en allant dans le répertoire de ce noeud : /node/dse-data/hints/ 
____
##### dans le cas présent, si on suppose que c'est le noeud 1 
##### sur cassandra01 : Dans le répertorie de stockage des hints du noeud cassandra0z : 
```bash
ls -l /home/user/cassandra-tp00/docker/cassandra01/hints/
```
##### ou, ce qui revient au même : 
```bash
docker exec -it cassandra01 ls -l /opt/cassandra/data/hints
```

##### Affichage en retour :

total 8
-rw-r--r-- 1 999 systemd-journal 178 Mar  8 17:23 0d049785-4093-43df-958e-b9f7d1fd9200-1772987009198-2.hints
-rw-r--r-- 1 999 systemd-journal 178 Mar  8 17:23 b18bc462-22d2-45d8-8109-9354978f68a8-1772987009163-2.hints


##### Il y a deux fichiers, un fichier stockant tous les hints pour un noeud donné.
____



____
##### 8°) Vous pouvez vérifier également dans les répertoires des autres noeuds arrêtés,
#####      qu'il n'y a aucun hint stocké.
____
##### sur cassandra02 :
```bash
docker exec -it cassandra02 ls -l /opt/cassandra/data/hints
```
##### total 0

##### sur cassandra03 :
```bash
docker exec -it cassandra03 ls -l /opt/cassandra/data/hints
```
##### total 0
____



##### On se connecte en CQLSH sur le noeud restant : 192.168.100.15z

```bash
docker exec -it cassandra01 cqlsh
```

```sql
USE EntrepriseFormation;
```

____
##### 9°) Repositionnez le niveau de cohérence à "ONE":
____
```sql
CONSISTENCY ONE;
```

____
##### 10°) Essayez de lire le nouvel enregistrement avec la commande SELECT suivante : 
____
```sql
SELECT * FROM EntrepriseFormation.cours_par_theme;
```

##### La requête échoue du fait que même si un noeud est actif, 
##### ce noeud ne couvre pas entièrement la plage de tokens à lui tout seul.
##### Avec un niveau de cohérence à "ONE", Cassandra ne peut donc pas garantir que tous les enregistrements lui seront fournis .
____


____
##### 11°) Remettez en service un des noeuds contenant un réplica :  
____
##### sur cassandra02 ici : 
```bash
docker start cassandra02
```

##### Attendez le message "state jump to normal" avant de poursuivre. 


##### sur cassandra01 :
##### Allez dans le répertoire contenant les hints :  

```bash
docker exec -it cassandra01 ls -l /opt/cassandra/data/hints
```

##### vous allez constater que l'un des fichiers de hint a disparu.

##### ls -l /node/dse-data/hints/
##### total 4
##### -rw-r--r-- 1 root root 163 Nov  1 22:11 b56bb884-fb3d-4256-9e36-d...a-1478038274217-1.hints
____

##### Cela est dû au fait que le noeud actif a envoyé les hints en attente lors de la relance du noeud.


____
##### 12°) Relancez la requête de SELECT à nouveau : 
____
##### sur cassandra01 dans l'exemple : 

```bash
docker exec -it cassandra01 cqlsh
```

```sql
USE EntrepriseFormation;
```


```sql
SELECT * FROM EntrepriseFormation.cours_par_theme;
```

##### => La requête réussit cette fois et vous retourne l'enregistrement attendu.

____
##### 13°) Relancez enfin le dernier noeud inactif. Attendez le message "state jump to normal" avant de pursuivre.
____
##### sur cassandra03 ici : 
```bash
docker start cassandra03
```


##### A nouveau, vous allez constater de l'activité dans le répertoire Hints, et ensuite que ce répertoire s'est vidé.

##### sur cassandra01 : 

```bash
docker exec -it cassandra01 ls -l /opt/cassandra/data/hints
```

##### Affichage en retour : 
```text

```


##### Les deux noeuds chargés des réplicas ont bien récupérés les enregistrements "hints" en attente.


____
##### 14°) A noter : la requête suivante ne fonctionne plus dans les versions récentes de Cassandra : 

##### NOTE : Les versions Cassandra < 3.0 versions stockaient les hints dans des tables (déprécié) 

____
```bash
SELECT * FROM system.hints;
```

##### Affichage : 
```text
 target_id | hint_id | message_version | mutation
-----------+---------+-----------------+----------

```

##### Vous aurez toujours soit une erreur, soit un résultat vide dans les version de Cassandra 3.0 et supérieures. 

```text

Dans les versions précédents (avant 3.0), il n'y aurait pas eu de répertoire /hints par contre. 
Les hints auraient été stockés dans la table system.hints. Mais stocker les hints dans un fichier est plus performant.

Vous pouvez en savoir plus ici : http://www.datastax.com/dev/blog/whats-coming-to-cassandra-in-3-0-improved-hint-storage-and-delivery

```
____
##### Fin du TP10 : Hinted-handoff
____