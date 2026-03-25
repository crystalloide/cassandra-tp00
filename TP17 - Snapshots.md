____
##### TP17 : Snapshots : 00H15 environ                                 
____

##### 1°) Pré-requis : il faut avoir un keyspace et une table chargée : 
```text
On exécute la commande CQL CREATE KEYSPACE 
avec le paramètre de réplication 'NetworkTopologyStrategy' 
afin de stocker 1 réplica sur chacun des 2 datacenters :
```

```text
**On ouvre une session CQLSH :**  
```

```bash
docker exec -it cassandra01 cqlsh 
```

```sql
CREATE KEYSPACE EntrepriseFormation
WITH replication = {
    'class': 'NetworkTopologyStrategy',
    'Nord': 1,
    'Terres-de-la-Couronne': 1
};
```

____
##### 2°) On sélectionne le keyspace EntrepriseFormation : 

```sql
USE EntrepriseFormation;
```

____
##### 3°) On crée une table simple nommée "cours" avec la structure indiquée ci-dessus. "cours_id" sera la clé primaire.

```sql
CREATE TABLE cours (
  cours_id TIMEUUID,
  ajout_date TIMESTAMP,
  intitule TEXT,
  PRIMARY KEY (cours_id)
);
```


##### 4°)  Si besoin, en cas d'erreur, pour supprimer la table cours du Keyspace EntrepriseFormation : 
```sql
DROP TABLE EntrepriseFormation.cours;
```

____
##### 5°) On importe les données dans la tables cours :
```text
A partir d'un terminal Linux, on alimente un des noeuds (ici cassandra01) avec les fichiers que l'on va charger ensuite :
```

```bash
cd ~/cassandra-tp00
docker exec -it cassandra01 mkdir -p /donnees
docker cp ./donnees/cours.csv cassandra01:/donnees/cours.csv
docker cp ./donnees/cours-par-theme.csv cassandra01:/donnees/cours-par-theme.csv
docker exec -it cassandra01 chmod 775 -Rf /donnees
docker exec -it cassandra01 ls /donnees
```

```text
**On retourne dans une session CQLSH ou on ouvre une nouvelle session CQLSH :**  
```

```bash
docker exec -it cassandra01 cqlsh 
```

```sql
USE entrepriseformation;
COPY cours(cours_id,ajout_date,intitule)
FROM '/donnees/cours.csv'
WITH HEADER=TRUE;
```

```text
Affichage :
cqlsh:entrepriseformation> COPY cours(cours_id, ajout_date, intitule) FROM '/sources/donnees/cours.csv' WITH HEADER=TRUE; Using 1 child processes

Starting copy of entrepriseformation.cours with columns [cours_id, ajout_date, intitule].
Processed: 5 rows; Rate:       9 rows/s; Avg. rate:      14 rows/s
5 rows imported from 1 files in 0.368 seconds (0 skipped).
```

____
##### 6°) Utilisez la commande SELECT pour vérifier pour les données ont été effectivement chargées
____

```sql
SELECT * FROM cours;
```

____
##### 7°) On peut commencer à prendre des snapshots maintenant que les objets sont créés et chargés : 
____


##### Sur cassandra01 :

```bash
docker exec -it cassandra01 nodetool snapshot
``` 

```text
**Affichage :**
cassandra@cassandra01 ~]$ nodetool snapshot
Requested creating snapshot(s) for [all keyspaces] with snapshot name [1548371198289] and options {skipFlush=false}
Snapshot directory: 1548371198289
```


____
##### 8°) Pour un snapshot sur une table (ciblage plus précis donc) : 
____
```bash
docker exec -it cassandra01 nodetool snapshot entrepriseformation.cours
```

```text
**Affichage :**
[cassandra@cassandra01 ~]$ nodetool snapshot entrepriseformation.cours
Requested creating snapshot(s) for [entrepriseformation.cours] with snapshot name [1548371417673] and options {skipFlush=false}
Snapshot directory: 1548371417673
```


____
##### 9°) On force l'écriture des Memtable sur disque sous forme de SSTable : 

```bash
docker exec -it cassandra01 nodetool flush
```


```bash
docker exec -it cassandra01 nodetool snapshot --table cours_par_theme entrepriseformation
```


```text
**Affichage :**
[cassandra@cassandra01 ~]$ nodetool snapshot --table cours entrepriseformation
Requested creating snapshot(s) for [entrepriseformation] with snapshot name [1548371680166] and options {skipFlush=false}
Snapshot directory: 1548371680166
```

##### 9°) Ancienne méthode de restauration dépréciée : 
```text
A noter : l'ancienne méthode qui a été dépréciée :
**nodetool refresh entrepriseformation cours**
```

##### 10°) Nouvelle méthode de restauration à utilser : 
nodetool import entrepriseformation cours /node/dse-data/data/entrepriseformation/cours-f7f796e0d42c11ebbec0d39876a2987e/snapshots/1624458195159/

```bash
docker exec -it cassandra01 nodetool import entrepriseformation cours /node/dse-data/data/entrepriseformation/cours-f7f796e0d42c11ebbec0d39876a2987e/snapshots/1624458195159/
```

____
##### Fin du TP
____



##### ANNEXE : SAUVEGARDES et RESTAURATION :
____
```text

Il existe 3 niveaux de granularité de sauvegarde disponibles :

1°) Snapshots : 
Lien physique vers les fichiers sstable présents dans le répertoire de données concernant une table, 
au moment où la capture snapshot est exécutée.

2°) Sauvegardes incrémentielles :
Lien physique distinct vers une sstable, 
créé en même temps que la sstable d'origine est écrite sur le disque dans le répertoire de données.

3°) Archives de Commitlog :
Copie -ou lien vers- un commitlog individuel. 
Le commitlog contient le journal transactionnel du noeud d'où il provient 
et est requis pour la restauration au niveau transactionnel.

En utilisant les 3 niveaux résumés ci-dessus, l’idée est de : 
- prendre des snapshots régulièrement, 
- effectuer des sauvegardes incrémentielles entre les snapshots 
- créer des archives de commitlog qui contiennent les écritures de l’application en cours sur le nœud.

Ces couches sont additives, inclusives et redondantes: 
Cela signifie que : 
- les snapshots incluent toutes les données des sauvegardes incrémentielles 
- les sauvegardes incrémentielles constituent des enregistrements persistants des validations du commitlog (journal de validation). 

Ainsi, conceptuellement, lorsqu'une sauvegarde incrémentielle est effectuée, 
vous pouvez supprimer tous les commitlogs archivés précédents, 
et lorsqu'un snapshot est pris, vous pouvez supprimer toutes les sauvegardes incrémentielles antérieures. 
Ou, vous pouvez uniquement sauvegarder des ensembles de sauvegardes incrémentielles et de commitlogs 
et obtenir le même résultat qu'avec l'utilisation de snapshots comme base. 

Mais le but ici est uniquement d’illustrer le chevauchement des sauvegardes 
et non de recommander des règles de conservation ou une politique de traitement des données.

Pour bien comprendre cela, nous pouvons examiner comment Cassandra écrit et stocke les données, 
dans le contexte des sauvegardes:

Une fois qu'un commit est persisté (écrit sur disque), 
une sauvegarde incrémentielle est effectuée, et lorsque la sstable est écrite, 
le segment de commitlog d'origine n'est plus nécessaire :
l'état des données est conservé dans les sstables, dont vous disposez d'une copie, 
et une copie de sauvegarde qui sont en fait des liens en dur des mêmes données sur le disque. 
L’archive de commitlog sera où l’application transactionnelle de données, 
la mutation, sera stockée, 
tandis que les commitlogs en direct seront reportés par configuration, 
comme ils le feraient normalement, qu’il s’agisse ou non de sauvegardes.

Une fois le snapshot pris, toutes les données présentes dans les sauvegardes incrémentielles le seront également. 
afin que les sauvegardes incrémentielles puissent être nettoyées. 
Les sstables du répertoire de données seront les mêmes fichiers que celles servant de sauvegardes, 
et seront donc situés dans le sous-dossier contenant le snapshot, 
tandis que le répertoire live continuera à compacter normalement les différentes générations de sstable.

Ensuite, au moment de la restauration, vous devrez:
- chargez le snapshot le plus récent dont vous disposez juste avant l'heure de restauration souhaitée;
- chargez également les sauvegardes incrémentielles datant d'après le snapshot dans les répertoires de données actives du keyspace ou de la table en cours de restauration.
- Enfin, chargez les archives de commitlog à partir de la date la plus récente couverte par les sstables, 
dans l'emplacement de stockage du commitlog : elles seront rejouées au démarrage du noeud. 

Cela permettra de combler le vide temporel de la couche de persistance, les sstables, 
afin de ramener les données sur ce nœud dans le même état que celui dans lequel il se trouvait, à l'heure demandée.

Remarque importante : 
Une restauration PITR (à un moment donné) nécessite un redémarrage de cluster pour que la relecture de commitlog soit effectuée.


Outre les points ci-dessus, il est utile de préciser certaines opérations:

Les snapshots constituent les moyens de base de la restauration. 
Un snapshot contient toutes les données stockées sur le disque au moment de sa prise. 
Une fois ce cliché pris, vous pouvez le déplacer vers un autre emplacement, et DSE ne s'en occupe plus.

Il est important que les snapshots de différents nœuds ne soient pas stockés dans le même dossier. 
Les sstables ne sont pas écrits avec des noms de fichiers uniques par nœud, 
ce qui signifie qu’ils s'écraseront si deux fichiers ou plus du même nom de fichier sont enregistrés au même emplacement.

Les sauvegardes incrémentielles prennent des copies des sstables au fur et à mesure de leur création 
et peuvent également être déplacés vers d'autres emplacements une fois qu'elles ont été créées. 
Les mêmes règles concernant les noms de fichiers uniques s'appliquent à elles.
Les sauvegardes incrémentielles sont utiles pour ajouter à la collection de fichiers inclus dans un snapshot, 
afin de vous rapprocher au maximum du point de départ de la restauration :
Elles compensent l'écart entre le dernier snapshot que vous avez pris 
et le dernier sstable qui a été écrit sur disque pour cette sauvegarde de keyspace.

Le journal de commandes réalisera une relecture de toutes les transactions qui étaient en mémoire lorsque le nœud s'est arrêté. 
La relecture de commitlog est la partie la plus coûteuse de la restauration, 
mais c’est la manière qui permet d'obtenir une restauration à un moment précis avec une précision de l'ordre de la milliseconde.
Les Commitlogs d’un nœud ne peuvent pas être lus sur un nœud ou un cluster différent. 
Ce sont des transactions spécifiques au nœud d'où elles proviennent.
Les Commitlogs de différents nœuds doivent également être stockés séparément les uns des autres, 
sinon ils s'écraseront de la même manière que pour les sstables, et les transactions seront perdues.







Restauration de snapshots :

Restaurer à partir d'un snapshot est assez simple : 

Lorsqu'un nœud démarre, il lit tous les sstables dans ses répertoires de données 
et commence à répondre aux demandes en fonction des plages de jetons qu'il possède. 

Le noeud ne s’intéresse pas beaucoup aux sstables, 
mis à part s’assurer que c’est une sstable qui correspond au range de données qu'il gère pour cette table. 

Si le nom correspond à la table, les fichiers deviendront le point de chargement initial pour l'ensemble de données. 
Cependant, pour que les réponses soient renvoyées, les clés tokens de la sstable doivent être dans une plage que le nœud possède.

Pour restaurer des snapshots, il y a 3 méthodes :
Elles supposent toutes que le répertoire de données a été vidé, 
soit avec la commande truncate, soit en supprimant manuellement les fichiers lorsque le nœud est en panne.

Il est ainsi possible de :

- Charger les fichiers depuis un snapshot dans un répertoire de données de n'importe quel noeud, 
puis démarrez / redémarrez le nœud. Les sstables seront validées et chargées au démarrage, quelle que soit la source. 
Le nœud qui les charge n'a aucun moyen de connaître la source des SSTables.

- Avec un répertoire de données vidé, on peut y charger un snapshot 
et exécuter "nodetool refresh" pour forcer la lecture des sstables dans le nœud.

- On peut exécuter sstableloader pour diffuser des sstables depuis un dossier vers un cluster cible. 
Sstableloader lit tout répertoire contenant des sstables qu’il a reçu en argument, 
puis contacte le cluster cible, détermine les plages de jetons de chaque nœud et streame les sstable vers les nœuds appropriés. 

C’est un moyen de contourner la complexité de la gestion des jetons lors du chargement d’un ensemble de données.

Les snapshots sont une vue de l'ensemble de données sur un nœud à un moment précis. 
Ainsi, un snapshot pris à 10 heures peut être utilisé pour restaurer le nœud,
dans l'état dans lequel il se trouvait à 10 heures ce jour-là.

Si vous prenez un snapshot tous les jours à 10 heures, vous savez donc que vous pouvez restaurer à 10 heures sans problème. 

Mais que faire si vous avez besoin de restaurer à 10h30? 

Vous avez besoin des modifications qui ont été appliquées à l'ensemble de données au cours de la période écoulée. 

Il existe deux manières de réappliquer ces modifications et de modifier l'état des données: 
- les sauvegardes incrémentielles 
- les archives de commitlog.


Restauration de sauvegardes incrémentielles :
En réalité, la restauration de sauvegardes incrémentielles n’est pas différente de la restauration de snapshots. 
Ce ne sont que des sstables : 
Tout ce qui se trouve dans le répertoire de données sera validé et ensuite lu : 
- lors du redémarrage du nœud. 
- lorsque vous exécuterez nodetool refresh <keyspace> <table>
- ou encore : les sstables peuvent être streamées avec sstableloader.

Puisqu'une sauvegarde incrémentielle est une copie d'un fichier sstable créé lors du vidage, 
un snapshot est une collection de fichiers sstable constituant un ensemble de données au moment où le snapshot a été pris. 
vous pouvez les appliquer ensemble pour rapprocher l'ensemble de données du point où vous souhaitez effectuer la restauration.

Cela signifie que vous pouvez prendre un snapshot à 10 heures, 
avoir des sauvegardes incrémentielles générées chaque fois qu'une table flushe et génère donc une sstable, 
puis combiner les deux ensembles de fichiers pour vous rapprocher du point de restauration souhaité. 
La vitesse à laquelle les sauvegardes incrémentielles sont créées dépend de plusieurs facteurs, 
mais dans une base de données utilisée, vous les verrez probablement générées toutes les deux secondes au moins. 
Cela donne une granularité assez fine pour la restauration. 

Si vous avez besoin de niveaux de restauration à la transaction près, 
vous devez relire les transactions pour tous les nœuds, nœud par nœud. 

Pour ce faire, vous utiliserez les archives commitlog.


Restaurer les commitlogs :

La restauration des commitlogs consiste à effacer le répertoire du commitlog, 
à charger un ou plusieurs fichiers de commitlog, 
à partir de l'emplacement de sauvegarde dans lequel vous l'avez stocké avec la commande archive_command: 
ou à prendre toute autre copie des commitlogs que vous avez éventuellement créés, 
puis à redémarrer le noeud.

Au démarrage du nœud, le comportement normal d'un nœud, en ce qui concerne les commitlogs, 
consiste à rechercher des instructions dans commitlog_archiving.properties, 
à charger l'outillage approprié pour l'archivage ou à appliquer les instructions de restauration, 
puis à réexécuter tout ce qui se trouve dans le commitlog concernant des transactions sur les données. 

c'est dans les sstables dans le répertoire de données en direct.

Si vous avez rempli la section de restauration du fichier commitlog_archiving.properties 
et que vous avez démarré le noeud, 
le noeud suivra ces instructions avant de passer à la relecture du commitlog.

Celles-ci sont très similaires à la commande archive_command :
en ce sens que la commande transmet les variables,%from et %to, en les faisant "echo" dans la commande 
ou le script indiqué dans la commande restore_command :.

La variable %from sera ce que vous aurez mis dans le répertoire restore_directories: dans le fichier properties. 
Notez que le répertoire de restauration ne doit pas nécessairement être associé au répertoire d'archivage. 
La variable %to sera automatiquement définie dans le répertoire du commitlog et ne pourra pas être modifiée.

Ainsi, en exécutant une commande pour tout copier de l’emplacement d’un emplacement de sauvegarde 
vers l’emplacement du commitlog paramétré pour le noeud, 
vous pouvez faire rejouer divers commitlogs archivés.

En utilisant cela, avec les snapshots et les sstables incrémentales, 
vous pouvez restaurer avec une précision à la milliseconde, au niveau même d'une transaction. 

Vous faites cela en chargeant les sstables à partir de votre snapshot et de toutes les sauvegardes incrémentielles entre
le snapshot et la fenêtre de restauration, 
puis définissez le moment à partir duquel vous voulez que les journaux de commit soient rejoués, 
ce qui amènera le nœud à l'horodatage indiqué dans le paramètre restore_point_in_time:, 
qui doit être défini sous la forme d'une chaîne au format YYYY: MM: JJ HH: MM: SS et GMT.



Exemple : commitlog_archiving.properties :

archive_command=cp %path /cassandra/commitlog_archiving/%name
restore_command=/bin/cp -f %from %to
restore_directories=/cassandra/restore/
restore_point_in_time=2020:01:22 10:44:00

## En heure GMT !


```
