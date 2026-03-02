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
##### 2°) Bien attendre que les noeuds s'arrêtent avant de continuer :
________
```bash
docker ps -a 
```

    CONTAINER ID   IMAGE              COMMAND                  CREATED             STATUS                        PORTS     NAMES
    fc54bf7dbe3b   cassandra:latest   "docker-entrypoint.s…"   About an hour ago   Exited (137) 53 minutes ago             cassandra04
    b82c5a66de6c   cassandra:latest   "docker-entrypoint.s…"   About an hour ago   Exited (137) 53 minutes ago             cassandra03
    fe6612364f4e   cassandra:latest   "docker-entrypoint.s…"   About an hour ago   Exited (137) 19 seconds ago             cassandra02
    4426dfad9fbe   cassandra:latest   "docker-entrypoint.s…"   About an hour ago   Exited (137) 30 seconds ago             cassandra01
	
	
________
##### 3°) Pour comprendre la gestion de la répartition des token, nous allons créer un cluster à 2 noeuds
________
##### 	   On supprime les données chargées dans le TP précédent :
________
```bash
cd ~/cassandra-tp00/docker
sudo rm -Rf cassandra01/*			#### On supprime tout l'historique et les données sur cassandra01
sudo rm -Rf cassandra02/*			#### On supprime tout l'historique et les données sur cassandra02
ls cassandra0*/
cd ~/cassandra-tp00/
```


_______
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

##### Remarque : Ce noeud mettra un peu plus de temps à démarrer et rejoindre le cluster.
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


_______

##### Affichage en réponse à la commande dsetool status :
##
##### On remarque bien que chaque noeud a désormais 24 VNodes :
##### 
##### root@cassandra01:~# /node/bin/dsetool status
##### DC: Cassandra       Workload: Cassandra       Graph: no
##### ======================================================
##### Status=Up/Down
##### |/ State=Normal/Leaving/Joining/Moving
##### --   Server ID          Address            Load             Owns                 VNodes            Rack         Health [0,1]
##### UN   08-00-27-A8-A6-C3  192.168.1.151      95.97 KB         ?                    24                rack1        0.00
##### UN   08-00-27-A8-A6-C3  192.168.1.152      106.89 KB        ?                    24       	       	rack1        0.00
##### 
_______


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