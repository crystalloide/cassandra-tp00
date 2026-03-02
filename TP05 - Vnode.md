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
    UN  192.168.100.151  119.47 KiB  1       100.0%            465a3a80-e0a6-4518-aa98-231566a01e66  Rack1
    UN  192.168.100.152  30.89 KiB   1       100.0%            c895162a-3887-4db4-9b84-e8eed1c2994a  Rack2


_______
##### 6°) Exécuter la commande : 
_______

##### Sur cassandra01
```bash
docker exec -it cassandra01 nodetool ring
```

##### Et vous constatez que chaque noeud gère davantage de ranges de tokens, mais avec des ranges plus petits désormais :
_______
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



_______
##### Fin du TP05 : VNodes : Comprendre comment est gérée la distribution par partitionnement avec les Vnodes

_______







