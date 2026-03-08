_____
##### TP08 : Réplication
_____
##### Dans cet exercice, vous allez comprendre le mécanisme de la réplication,
##### et comprendre en quoi la réplication acontribue à la fiabilité et résilience de Cassandra
##### 
##### Contexte: Cassandra permet la scalabilité et la tolérance aux pannes.
##### La réplication est l'ingrédient magique qui permet cela.
##### Dans cet exercice, nous allons ajouter un troisième noeud à notre cluster,
##### et utiliser différents paramètres de la réplication.
_____


##### Nous allons maintenant arrêter et relancer un cluster à 3 noeuds :
##### les 2 précédents + un 3ème noeud cassandra03 situé sur le même datacenter et le rack de cassandra01)


##### 1°) On nettoie l'environnement précédent : 
________

```bash
docker compose -f Cluster_2_noeuds_2_racks_2_DC.yml down -v
```

```bash
docker ps -a 
```

##### Recréation des répertoires de volumes (dat + conf)  :

```bash
sudo rm -Rf ~/cassandra-tp00/docker/cassandra*
mkdir -p ~/cassandra-tp00/docker/cassandra01 ~/cassandra-tp00/docker/cassandra02 ~/cassandra-tp00/docker/cassandra03 ~/cassandra-tp00/docker/cassandra04
mkdir -p ~/cassandra-tp00/docker/cassandra01-conf ~/cassandra-tp00/docker/cassandra02-conf ~/cassandra-tp00/docker/cassandra03-conf ~/cassandra-tp00/docker/cassandra04-conf
```

##### On affiche les répertoires re-créés :

```bash
ls ~/cassandra-tp00/docker
```

________
##### 2°) On relance le nouveau cluster à 3 noeuds : 
________

##### Lancement du cluster  : 

```bash
cd ~/cassandra-tp00/
docker compose -f Cluster_3_noeuds_2_racks_2_DC.yml up -d
sleep 60
```

```bash
docker exec -it cassandra01 nodetool status

```
##### Affichage en retour quand le cluster est bien lancé et opérationnel : 
```bash
Datacenter: Nord
================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address          Load        Tokens  Owns (effective)  Host ID                               Rack
UN  192.168.100.151  119.82 KiB  16      61.1%             6ceb7b98-12d7-4c3d-b74e-41f12cc5284e  Winterfell
UN  192.168.100.153  80.05 KiB   16      67.5%             ae4e8761-8f8a-46e4-adc6-93adbb194d16  Winterfell

Datacenter: Terres-de-la-Couronne
=================================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address          Load        Tokens  Owns (effective)  Host ID                               Rack
UN  192.168.100.152  85.11 KiB   16      71.4%             6fb77427-ad69-4dc6-bd44-1eec66fe40f7  Port-Real

```

##### 3°) Regardons les paramètres définis :


##### Vérifier que la valeur de num_tokens est à 16 
##### Pour voir la configuration sur cassandra01 :

```bash
docker exec -it cassandra01 cat /opt/cassandra/conf/cassandra.yaml | grep "num_tokens"
```

##### Vérifier le nom du cluster : cluster_name: 'ClusterFormation'
##### Pour voir la configuration sur cassandra03 :

```bash
docker exec -it cassandra03 cat /opt/cassandra/conf/cassandra.yaml | grep "cluster_name"
```


##### Pour voir la configuration de cassandra03 :
```bash
docker exec -it cassandra03 cat /opt/cassandra/conf/cassandra.yaml | grep "endpoint_snitch"
```

###### Ou ici (c'est la même chose dans notre contexte de disques des consteneurs persistés en local  ) : 
```bash
cat ~/cassandra-tp00/docker/cassandra03-conf/cassandra.yaml | grep "endpoint_snitch"
```

##### Affichage en retour : 
```bash
# endpoint_snitch -- Set this to a class that implements
endpoint_snitch: SimpleSnitch
```


##### Pour voir la configuration de cassandra03 :
```bash
docker exec -it cassandra03 head -n 21 /opt/cassandra/conf/cassandra-rackdc.properties
```

###### Ou ici (c'est la même chose dans notre contexte de disques des consteneurs persistés en local  ) : 
```bash
head -n 21 ~/cassandra-tp00/docker/cassandra03-conf/cassandra-rackdc.properties
```

##### On remarque les valeurs définies pour cassandra03 :
```bash
...
dc=Nord
rack=Winterfell
```




_____
##### 4°) Une fois le 3ème noeud lancé, vérifiez que les 3 noeuds sont bien 'up', avec la commande :

##### Sur un des noeuds cassandra, ici on choisit arbitrairement le noeud cassandra03 :

```bash
docker exec -it cassandra03 nodetool status
```


##### Vous pouvez lancer cette commande nodetool à partir de n'importe quel noeud actif .
##### 
##### Résultat de la commande : 
##### 
##### 	[cassandra@cassandra03 ~]$ dsetool status
##### 	DC: Nord            Workload: Cassandra       Graph: no     
##### 	======================================================
##### 	Status=Up/Down
##### 	|/ State=Normal/Leaving/Joining/Moving
##### 	--   Address          Load             Effective-Ownership  VNodes                                       Rack         Health [0,1] 
##### 	UN   192.168.100.151  128.68 KiB       70.21%               24                                           Winterfell   0.50         
##### 	UN   192.168.100.153  123.63 KiB       63.05%               24                                           Winterfell   0.00         
##### 
##### 	DC: Terres-de-la-Couronne Workload: Cassandra       Graph: no     
##### 	============================================================
##### 	Status=Up/Down
##### 	|/ State=Normal/Leaving/Joining/Moving
##### 	--   Address          Load             Effective-Ownership  VNodes                                       Rack         Health [0,1] 
##### 	UN   192.168.100.152  101.62 KiB       66.75%               24                                           Port-Real    0.50         
##### 



_____
##### 5°) Vous allez réimporter les données des cours :  
#####    accédez à cqlsh : 
cqlsh 192.168.100.153

##### Exécutez la commande CQL CREATE KEYSPACE avec le paramètre de réplication 'NetworkTopologyStrategy' 
##### afin de stocker un réplica par datacenter :

CREATE KEYSPACE EntrepriseFormation
WITH replication = {
    'class': 'NetworkTopologyStrategy',
    'Nord': 1,
    'Terres-de-la-Couronne': 1
};



_____
##### 6°) Sélectionnez le keyspace EntrepriseFormation : 
_____
USE EntrepriseFormation;



_____
##### 7°) Recréez la table cours_par_theme table et réimportez les données, 
#####     avec les commandes suivantes : A faire sur cassandra01 :  

CREATE TABLE cours_par_theme (
    theme text,
    cours_id uuid,
    ajout_date timestamp,
    intitule text,
    PRIMARY KEY ((theme), ajout_date, cours_id))
    WITH CLUSTERING ORDER BY(ajout_date DESC, cours_id DESC);


COPY cours_par_theme(theme, cours_id, ajout_date, intitule)
FROM '/sources/donnees/cours-par-theme.csv'
WITH HEADER=TRUE;

##### On vérifie le bon chargement de la table : 
SELECT * FROM cours_par_theme;

##### Et on sort : 
exit



_____
##### 8°) Regardez sur quels noeuds les réplicas ont été répartis et positionnés,  
#####     avec les commandes suivantes :
##### /node/resources/cassandra/bin/nodetool getendpoints entrepriseformation cours_par_theme 'cassandra'
##### /node/resources/cassandra/bin/nodetool getendpoints entrepriseformation cours_par_theme '1FORM@'
##### Sur cassandra01 : 
nodetool getendpoints entrepriseformation cours_par_theme 'cassandra'
nodetool getendpoints entrepriseformation cours_par_theme '1FORM@'


_____
##### NOTE : nodetool retourne l'adresse IP des noeuds contenant les données
_____

##### Affichage en retour : /node/resources/cassandra/bin/nodetool getendpoints entrepriseformation cours_par_theme 'cassandra'
192.168.100.153
192.168.100.152

##### Affichage en retour : /node/resources/cassandra/bin/nodetool getendpoints entrepriseformation cours_par_theme '1FORM@'
192.168.100.151
192.168.100.152

_____
##### Remarque : Cassandra stocke chaque réplica deux fois et sur un datacenter distinct. 
#####            Les résultats peuvent varier du fait du choix aléatoire des tokens attribués aux VNodes répartis sur les noeuds.
_____



_____
##### 09°) Cassandra n'a pas besoin d'avoir une partition déjà existante (donc pour une valeur de clé donnée)
#####      pour déterminer quels nœuds stockeront quelle partition (Par contre, le keyspace et la table doivent exister)
#####      Vous pouvez ainsi essayer avec n'importe quelle valeur de clé de partition, vous saurez quel noeud en sera l'hôte.
#####      Par exemple, essayez :
_____
nodetool getendpoints entrepriseformation cours_par_theme 'cuisine'
nodetool getendpoints entrepriseformation cours_par_theme 'wing_suit'
nodetool getendpoints entrepriseformation cours_par_theme 'Dark_Vador'
##
_____
#####  
##### Affichage du résultat :
##### 
##### [cassandra@cassandra03 ~]$ nodetool getendpoints entrepriseformation cours_par_theme 'cuisine'
##### 192.168.100.153
##### 192.168.100.152
##### 
##### 
##### [cassandra@cassandra03 ~]$ nodetool getendpoints entrepriseformation cours_par_theme 'wing_suit'
##### 192.168.100.152
##### 192.168.100.151
##
##### [cassandra@cassandra03 ~]$ nodetool getendpoints entrepriseformation cours_par_theme 'Dark_Vador'
##### 192.168.100.151
##### 192.168.100.152
##

_____



