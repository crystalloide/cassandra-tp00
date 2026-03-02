_______
##### TP05 : VNodes : Comprendre comment est gérée la distribution par partitionnement avec les Vnodes
_______
##### Contexte : 

##### L'anneau basé sur des tokens et les nœuds rendent Cassandra extensible et résistant aux pannes, 
##### mais la gestion du partitionnement, basé uniquement sur des nœuds physiques, pose problème.
##### Par exemple, lorsqu'un noeud physique devient inopérant, il est alors nécessaire de redistribuer les partitions qu'il hébergeait.
##### C'est là où les noeuds virtuels (ou VNodes) entrent en jeu.
##### L'utilisation de VNodes aide à répartir la charge lors de la redistribution de partitions sur l'ensemble des noeuds physiques restants.
##### 
##### Dans cet exercice, nous allons passer de l'utilisation de nœuds ou token simples à l'utilisation de Vnodes.

##### Cassandra ne permet pas de modifier les paramètres 'num_tokens' après qu'un nœud ait rejoint le cluster,

##### Nous devrons donc "travailler" un peu pour que cela fonctionne.
________
#### Etapes : 
________
##### 1°) Tout d'abord, il faut arrêter le cluster à 2 noeuds, avec les commandes suivantes : 
________
```bash
docker stop cassandra01
docker stop cassandra02
```
________
##### 2°) On nettoie tout l'environnement : 
________
```bash
docker compose down -v
```

```bash
docker ps -a 
```

    CONTAINER ID   IMAGE              COMMAND                  CREATED             STATUS                        PORTS     NAMES
	
	
________
##### 3°) Pour comprendre la gestion de la répartition des token, nous allons créer un cluster à 2 noeuds
________
##### 	  On supprime les données chargées dans le TP précédent : on recrée à vide les répertoires :
________
```bash
cd ~/cassandra-tp00/docker
sudo rm -Rf ~/cassandra-tp00/docker/cassandra*
mkdir -p ~/cassandra-tp00/docker/cassandra01 ~/cassandra-tp00/docker/cassandra02 ~/cassandra-tp00/docker/cassandra03 ~/cassandra-tp00/docker/cassandra04
```

```bash
mkdir -p ~/cassandra-tp00/docker/cassandra01-conf ~/cassandra-tp00/docker/cassandra02-conf ~/cassandra-tp00/docker/cassandra03-conf ~/cassandra-tp00/docker/cassandra04-conf
```
##### 4°) On affiche les répertoires créés :
```bash
ls ~/cassandra-tp00/docker
```
##### Affichage :
    cassandra01  cassandra01-conf  cassandra02  cassandra02-conf  cassandra03  cassandra03-conf  cassandra04  cassandra04-conf

```bash
cd ~/cassandra-tp00/docker
```
_______
##### 5°) Remarque importante : 

    En supprimant les répertoires de configuration des noeuds cassandra01 et cassandra02 (cassandra0x-conf), 
	on réinitialise les fichiers cassandra.yaml avec leurs valeurs par défaut
	et donc l'usage en VNodes.
	Cela nous évite d'aller remettre les valeurs modifiée à l'état initial  (Vnode = 16  et 'Initial Token' en commentaire)

_______
##### 6°) On lance le cluster de 2 noeuds cassandra01 et cassandra02 en VNodes : :
________
```bash
cd ~/cassandra-tp00
# Démarrer le cluster en arrière-plan
docker compose -f Cluster_2_noeuds_2_racks_1_DC.yml up  -d
```

________
##### 7°) Lancez la commande 'nodetool status' pour voir le statut du cluster
________
```bash
docker exec -it cassandra01 nodetool status
```
    Datacenter: dc1
    ===============
    Status=Up/Down
    |/ State=Normal/Leaving/Joining/Moving
    --  Address          Load        Tokens  Owns (effective)  Host ID                               Rack
    UN  192.168.100.151  114.68 KiB  16      100.0%            aad76b9d-b975-4942-8772-d36896124cb3  Rack1
    UJ  192.168.100.152  30.89 KiB   16      ?                 86cf0dbf-7778-48b0-b8c8-044effc1735e  Rack2


##### Au bout de plusieurs minutes : 

    Datacenter: dc1
    ===============
    Status=Up/Down
    |/ State=Normal/Leaving/Joining/Moving
    --  Address          Load        Tokens  Owns (effective)  Host ID                               Rack
    UN  192.168.100.151  119.82 KiB  16      100.0%            aad76b9d-b975-4942-8772-d36896124cb3  Rack1
    UN  192.168.100.152  119.65 KiB  16      100.0%            86cf0dbf-7778-48b0-b8c8-044effc1735e  Rack2

_______
##### 6°) Exécuter la commande : 
_______

##### Sur cassandra01
```bash
docker exec -it cassandra01 nodetool ring
```

##### Et vous constatez que chaque noeud gère davantage de ranges de tokens, mais avec des ranges plus petits désormais :
_______
```text
Datacenter: dc1
==========
Address               Rack        Status State   Load            Owns                Token
                                                                                     8956661515134890508
192.168.100.152       Rack2       Up     Normal  85.08 KiB       100.00%             -8872101526672461030
192.168.100.151       Rack1       Up     Normal  119.82 KiB      100.00%             -8418581942234628294
192.168.100.152       Rack2       Up     Normal  85.08 KiB       100.00%             -7807760536899397632
192.168.100.151       Rack1       Up     Normal  119.82 KiB      100.00%             -7400730537492201278
192.168.100.151       Rack1       Up     Normal  119.82 KiB      100.00%             -6583058604879850484
192.168.100.152       Rack2       Up     Normal  85.08 KiB       100.00%             -5987756235919451233
192.168.100.151       Rack1       Up     Normal  119.82 KiB      100.00%             -5507302723654270944
192.168.100.151       Rack1       Up     Normal  119.82 KiB      100.00%             -4771387030943377303
192.168.100.152       Rack2       Up     Normal  85.08 KiB       100.00%             -4110691906406465204
192.168.100.151       Rack1       Up     Normal  119.82 KiB      100.00%             -3692014223495775646
192.168.100.152       Rack2       Up     Normal  85.08 KiB       100.00%             -2941736983227450824
192.168.100.151       Rack1       Up     Normal  119.82 KiB      100.00%             -2448494217815183672
192.168.100.152       Rack2       Up     Normal  85.08 KiB       100.00%             -1892613182898259736
192.168.100.151       Rack1       Up     Normal  119.82 KiB      100.00%             -1481129974736648174
192.168.100.152       Rack2       Up     Normal  85.08 KiB       100.00%             -956700010106744316
192.168.100.152       Rack2       Up     Normal  85.08 KiB       100.00%             -541062350535104437
192.168.100.151       Rack1       Up     Normal  119.82 KiB      100.00%             108874577777250463
192.168.100.152       Rack2       Up     Normal  85.08 KiB       100.00%             670617996136876707
192.168.100.152       Rack2       Up     Normal  85.08 KiB       100.00%             1067940848485589498
192.168.100.151       Rack1       Up     Normal  119.82 KiB      100.00%             1727897873474293760
192.168.100.152       Rack2       Up     Normal  85.08 KiB       100.00%             2326361564431032586
192.168.100.151       Rack1       Up     Normal  119.82 KiB      100.00%             2706043325990407836
192.168.100.152       Rack2       Up     Normal  85.08 KiB       100.00%             3360662211106436953
192.168.100.152       Rack2       Up     Normal  85.08 KiB       100.00%             3786948712387566343
192.168.100.151       Rack1       Up     Normal  119.82 KiB      100.00%             4484677626813994964
192.168.100.152       Rack2       Up     Normal  85.08 KiB       100.00%             5137150538962244226
192.168.100.151       Rack1       Up     Normal  119.82 KiB      100.00%             5580719527048933253
192.168.100.152       Rack2       Up     Normal  85.08 KiB       100.00%             6194527055891202443
192.168.100.151       Rack1       Up     Normal  119.82 KiB      100.00%             6672016637741145512
192.168.100.151       Rack1       Up     Normal  119.82 KiB      100.00%             7516393285232307270
192.168.100.152       Rack2       Up     Normal  85.08 KiB       100.00%             8316221955893437552
192.168.100.151       Rack1       Up     Normal  119.82 KiB      100.00%             8956661515134890508

  Warning: "nodetool ring" is used to output all the tokens of a node.
  To view status related info of a node use "nodetool status" instead.
```

_______
##### Fin du TP05 : VNodes : Comprendre comment est gérée la distribution par partitionnement avec les Vnodes

_______










