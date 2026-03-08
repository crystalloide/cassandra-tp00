____
##### TP09 : degrés ou niveaux de cohérence (Consistency Levels)
____

##### Dans cet exercice, vous allez comprendre : 
    - les différences entre la notion de consistance (cohérence) et le facteur de réplication
    - les différences entre la notion de consistance en Lecture vs en mise à jour
     
##### Contexte:
    L'un des défis d'un système distribué comme Cassandra est de savoir comment conserver les réplicas de données.
    Le maintien de la cohérence nécessite un subtil équilibre entre disponibilité et partitionnement.
    Cassandra permet de régler cet équilibre selon les besoins.
    
    Dans ce TP, nous manipulerons donc les différents niveaux de cohérence,
    pour des opérations de lecture et d'écriture.
    (Cluster à 3 noeuds)
____
##### ETAPES : 
____

##### 1°) Assurez-vous que les 3 noeuds existants sont bien actifs   
____
#####    Dans le terminal, lancez les commandes suivantes :
____

```bash
docker exec -it cassandra01 nodetool status

```

##### Accédez à cqlsh  : 
```bash
docker exec -it cassandra01 cqlsh
```

____
##### 2°) Sélectionnez le keyspace EntrepriseFormation : 
____

```sql
USE EntrepriseFormation;
```

____
##### 3°) Vérifiez le niveau de cohérence actuel avec la commande CONSISTENCY : 
____
```sql
CONSISTENCY;
```

    Current consistency level is ONE.


##### Notez que la cohérence (consistance) est à 1, ce qui signifie qu'il faut simplement :
    - qu'un seul noeud acquitte l'écriture lors d'une requête d'écriture,
    - qu'un seul nœud réponde (en renvoyant les résultats au client applicatif) pour satisfaire à une demande en lecture.
	

____
##### 4°) Repositionnez maintenant le niveau de consistance à 2 avec la commande suivante : 
____
```sql
CONSISTENCY TWO;
```

##### Affichage en retour :      
     Consistency level set to TWO.


##### Remarque : 
     Dans ce cas, le positionnement à 'TWO' est identique à 'ALL' : 
     En effet, les paramètres de réplication actuels stockent une réplique par datacenter, et il y a 2 datacenters.


____
##### 5°) Récupérons la partition contenant le cours cassandra dans la table cours_par_theme table  : 
____
```sql
SELECT *
FROM cours_par_theme
WHERE theme = 'cassandra';
```
##### Affichage en retour : 

```text

 theme     | ajout_date                      | cours_id                             | intitule
-----------+---------------------------------+--------------------------------------+--------------------------
 cassandra | 2014-01-29 00:00:00.000000+0000 | 1645ea59-14bd-11e5-a993-8138354b7e31 |    Histoire de Cassandra
 cassandra | 2013-03-17 00:00:00.000000+0000 | 3452f7de-14bd-11e5-855e-8738355b7e3a | Introduction a Cassandra
 cassandra | 2012-04-03 00:00:00.000000+0000 | 245e8024-14bd-11e5-9743-8238356b7e32 |         Cassandra & SSDs

(3 rows)

```
____
```sql
exit
```

____
##### 6°) Déterminez quels noeuds contiennent les réplicas pour la clé 'cassandra' de la table cours_par_theme 
#####    avec la commande suivante :
____
##### En interrogeant cassandra01 :
```bash 
docker exec -it cassandra01 nodetool getendpoints entrepriseformation cours_par_theme 'cassandra'
```

##### Affichage en retour :
    192.168.100.153
    192.168.100.152


____
##### 7°) On stoppe un des noeuds en lançant la commande :
____
```bash 
docker stop cassandra02
```

##### Le Numéro du noeud est corrélé avec le dernier champ de l'adresse IP listée. 
##### Ici, on choisit le noeud 2 (192.168.100.152) 

##### Sur cassandra01 : 

```bash 
docker exec -it cassandra01 nodetool status
```

##### Affichage : 
```text 
Datacenter: Nord
================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address          Load        Tokens  Owns (effective)  Host ID                               Rack
UN  192.168.100.151  96.17 KiB   16      48.8%             4a19a534-f295-430d-911b-49697d61709e  Winterfell
UN  192.168.100.153  108.39 KiB  16      51.2%             b18bc462-22d2-45d8-8109-9354978f68a8  Winterfell

Datacenter: Terres-de-la-Couronne
=================================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address          Load        Tokens  Owns (effective)  Host ID                               Rack
DN  192.168.100.152  108.4 KiB   16      100.0%            0d049785-4093-43df-958e-b9f7d1fd9200  Port-Real

```
##### Remarque :
```text 
On voit bien le statut 'DN' de l'adresse IP 192.168.100.152, le noeud 2 est donc "Down" avec une situation "Normale". 
On peut retrouver le statut 'DS' si le statut est Down Stopped (sur Cassandra DSE)

```

____
##### 8°) A nouveau, retournez dans cqlsh : 

##### Accédez à cqlsh depuis cassandra03 : 
```bash
docker exec -it cassandra03 cqlsh 192.168.100.153
```
____
##### 9°) Sélectionnez le keyspace EntrepriseFormation : 
____

```sql
USE EntrepriseFormation;
```

____
##### 10°) Positionnez le niveau de consistance à 2 : 
____
```sql
CONSISTENCY TWO;
```

##### Consistency level set to TWO.

```sql
SELECT *
FROM EntrepriseFormation.cours_par_theme
WHERE theme = 'cassandra';
```

##### Affichage en retour : 
```text
NoHostAvailable: ('Unable to complete the operation against any hosts', {<Host: 192.168.100.153:9042 Nord>: Unavailable('Error from server: code=1000 [Unavailable exception] message="Cannot achieve consistency level TWO" info={\'consistency\': \'TWO\', \'required_replicas\': 2, \'alive_replicas\': 1}')})

```
##### La requête échoue car vous ne pouvez plus obtenir le niveau de consistance 'TWO', du fait qu'un des noeuds nécessaire a été arrêté.


____
##### 11°) Ramenez le niveau de consistance à 'ONE':
____
```sql
CONSISTENCY ONE;
```

____
##### 12°) Retentez la même requête : 
____
```sql
SELECT *
FROM EntrepriseFormation.cours_par_theme
WHERE theme = 'cassandra';
```

##### 
##### La requête réussit car il y a bien au moins un réplica disponible pour pouvoir apporter une réponse.
##### 

____
##### 13°) Ramenez le niveau de consistance à 'TWO':
____
```sql
CONSISTENCY TWO;
```

____
##### 14°) Maintenant, essayez d'insérer un nouvel enregistrement dans la partition cassandra :
____
```sql
INSERT INTO EntrepriseFormation.cours_par_theme (theme, ajout_date, cours_id, intitule)
VALUES ('cassandra', '2016-02-08', uuid(), 'J adore Cassandra');
```

##### Remarquez que l'écriture va échouer car il n'est pas possible d'apporter le niveau de cohérence demandé (2).

____
##### 15°) Ramenez le niveau de consistance à 'ONE':
____
```sql
CONSISTENCY ONE;
```

____
##### 16°) Retentons la même requête d'insertion : 
____

```sql
INSERT INTO cours_par_theme (theme, ajout_date, cours_id, intitule)
VALUES ('cassandra', '2016-02-08', uuid(), 'J adore Cassandra');
```

##### => L'écriture réussit cette fois.
____

```sql
exit
```

____
##### 17°) Relancez le noeud qui avait été arrêté :
#####     Attendez bien qu'il soit complètement relancé
____

##### On relance le noeud cassandra02 :
```bash
docker restart cassandra02
```

##### Sur cassandra01 :
dsetool status
```bash
docker exec -it cassandra01 nodetool status
```


____
##### 18°) Accédez à cqlsh : 
____
##### Accédez à cqlsh depuis cassandra03 : 
```bash
docker exec -it cassandra03 cqlsh 192.168.100.153
```


____
##### 19°) Ramenez le niveau de consistance à 'TWO':
____
```sql
CONSISTENCY TWO;
```


____
##### 20°) Refaites la requête de select :
____

```sql
SELECT *
FROM EntrepriseFormation.cours_par_theme
WHERE theme = 'cassandra';
```

```text

 theme     | ajout_date               | cours_id                             | intitule
 -----------+--------------------------+--------------------------------------+-------------------
 cassandra | 2016-02-08 00:00:00+0000 | ec690d01-0e7e-4cdb-9e86-305be9a35b71 | J adore Cassandra
 cassandra | 2014-01-29 00:00:00+0000 | 1645ea59-14bd-11e5-a993-8138354b7e31 | Cassandra History
 cassandra | 2013-03-17 00:00:00+0000 | 3452f7de-14bd-11e5-855e-8738355b7e3a |   Cassandra Intro
 cassandra | 2012-04-03 00:00:00+0000 | 245e8024-14bd-11e5-9743-8238356b7e32 |  Cassandra & SSDs

 (4 rows)

Notez que le nouvel enregistrement est bien présent. 
Cela est dû à l'action de "read repair" qui sera vue un peu plus loin

```


____
##### 21°) Maintenant, pour jouer un peu : ramenez le niveau de consistance à 'ONE':
____

```sql
CONSISTENCY ONE;
```

```sql
exit
```


____
##### 22°) Stoppez le noeud qui était actif quand vous avez réalisé la mise à jour. 
#####     (dans le cas choisi ici : le noeud 3 a fait la mise à jour, on choisit donc le noeud 3 qui sera arrêté) 
#####     Attendez bien que le noeud soit stoppé avant de poursuivre.
____

##### Sur cassandra03 :
```bash
docker stop cassandra03
```

##### Sur cassandra02 :
```bash
docker exec -it cassandra02 nodetool status
```

____
##### 23°) Lancez cqlsh à nouveau :
____

##### Accédez à cqlsh depuis cassandra02 : 
```bash
docker exec -it cassandra02 cqlsh
```

____
##### 24°) Ré-exécutez la commande de SELECT
____
```sql
SELECT *
FROM EntrepriseFormation.cours_par_theme
WHERE theme = 'cassandra';
```

##### => Remarquez que la requête réussit et que le nouvel enregistrement est toujours présent. 
##### C'est encore une fois grâce au mécanisme de 'read repair', qui sera explicité plus tard.
____



____
##### 25°) Mettez à jour l'enregistrement avec un nouveau titre en exécutant la requête CQL suivante. 
#####    (Copiez/collez le cours_id du résultat défini ci-dessus dans la clause WHERE de la requête d'UPDATE.)
____

```sql
UPDATE EntrepriseFormation.cours_par_theme
SET intitule = 'J adore vraiment Cassandra'
WHERE theme = 'cassandra' AND ajout_date = '2016-02-08' AND cours_id = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;     ( UUID !!!)
```

##### soit donc dans le cas présent pour le TP :
```sql 
UPDATE EntrepriseFormation.cours_par_theme
SET intitule = 'J adore vraiment Cassandra'
WHERE theme = 'cassandra' AND ajout_date = '2016-02-08' AND cours_id = ec690d01-0e7e-4cdb-9e86-305be9a35b71;
```


____
##### 26°) Vérifiez le succès de la mise à jour : :
____
```sql
SELECT *
FROM EntrepriseFormation.cours_par_theme
WHERE theme = 'cassandra';
```

```sql
exit
```

##### Sur cassandra02 :
```bash
docker exec -it cassandra02 nodetool getendpoints entrepriseformation cours_par_theme 'cassandra'
```

#####  Affichage en retour pour la clé de partition 'cassandra'
    192.168.100.153
    192.168.100.152


____
##### 26°) Stoppez le noeud contenant le replica : 
#####     Notez bien le noeud en question. 
#####     Attendez bien l'arrêt complet du noeud.
#####     Utiliser 'nodetool' ('dsetool' sur un noeud DSE) pour vérifier que les deux noeuds avec les réplicas sont down. 
#####     ( = les noeuds en charge du theme 'cassandra').
____

##### Sur cassandra0x : (02 ici)

```bash
docker stop cassandra02
```

____
##### 28°) Maintenant, relancez le noeud avec l'autre réplica (celui qui a été arrêté normalement) 
#####     Attendez que le noeud soit effectivement complètement lancé.
____
##### Sur cassandra0x : (03 ici)
```bash
docker start cassandra03
```


##### 29°) Lancez cqlsh à nouveau
____
##### Accédez à cqlsh depuis cassandra03 : 
```bash
docker exec -it cassandra03 cqlsh
```

____
##### 30°) Exécutez la requête de SELECT :
____
```sql
SELECT *
FROM EntrepriseFormation.cours_par_theme
WHERE theme = 'cassandra';
```

____
##### Le titre du cours peut être : 'J adore Cassandra' ou 'J adore vraiment Cassandra',
##### en fonction de quels noeuds étaient coordinateurs sur les écritures précédentes,
##### et également s'ils ont effectué le proccessus de 'hinted handoff' que nous verrons juste après.

____
##### Fin du TP09 : degrés ou niveaux de cohérence (Consistency Levels)

____









