______
##### TP07 : Snitches
______
##### Dans cet exercice : nous allons regarder comment Cassandra se tient informé de la topologie du cluster, en utilisant des Snitches.
______
##### Contexte : 
##### Pour améliorer la tolérance aux pannes, les systèmes distribués doivent tenir compte de la topologie du cluster.
##### Cassandra utilise cette information topologique pour répliquer les données dans des zones "géographiques" distinctes du réseau,
##### ce qui augmente la disponibilité des données.
______
##### Dans cet exercice, nous changerons les assignations de panneaux et de rack pour nos deux nœuds.
##### Nous arrêterons chaque noeud (en le supprimant du cluster), réinitialiserons les données du noeud, etc.

______
##### Etapes:
______

##### Dans notre cluster basique en cours d'exécution, regardons les valeurs par défaut utilisées :

##### 1°) Valeur de 'endpoint_snitch' par défaut :

##### Pour voir la configuration de cassandra01 :
```bash
docker exec -it cassandra01 cat /opt/cassandra/conf/cassandra.yaml | grep "endpoint_snitch"
```

###### Ou ici (c'est la même chose dans notre contexte de disques des consteneurs persistés en local  ) : 
```bash
cat ~/cassandra-tp00/docker/cassandra01-conf/cassandra.yaml | grep "endpoint_snitch"
```

##### Affichage en retour : 
```bash
# endpoint_snitch -- Set this to a class that implements
endpoint_snitch: SimpleSnitch
```

##### 2°) Valeur de 'cassandra-rackdc.properties' par défaut :

##### Pour voir la configuration de cassandra01 :
```bash
docker exec -it cassandra01 head -n 21 /opt/cassandra/conf/cassandra-rackdc.properties
```

###### Ou ici (c'est la même chose dans notre contexte de disques des consteneurs persistés en local  ) : 
```bash
head -n 21 ~/cassandra-tp00/docker/cassandra01-conf/cassandra-rackdc.properties
```

##### On remarque les valeurs définies pour cassandra01 :
```bash
...
dc=dc1
rack=rack1
```

##### Nous allons maintenant arrêter et relancer un cluster avec des valeurs modifiées plus intéressantes que les valeurs par défaut :

##### 3°) On nettoie tout l'environnement : 
________

```bash
docker compose -f Cluster_2_noeuds_1_rack_1_DC.yml down -v
```

```bash
docker ps -a 
```

________
##### 4°) On relance un nouveau cluster à 2 noeuds mais cette fois qui seront répartis sur des racks et des Datacenters (DC) différents : 
________

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

##### Lancement du cluster 2 DC 2 racks : 

```bash
cd ~/cassandra-tp00/
docker compose -f Cluster_2_noeuds_2_racks_2_DC.yml up -d
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
UN  192.168.100.151  119.84 KiB  16      100.0%            3aa6222b-2507-44a2-a0da-cdab4704f6ef  Winterfell

Datacenter: Terres-de-la-Couronne
=================================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address          Load        Tokens  Owns (effective)  Host ID                               Rack
UN  192.168.100.152  85.12 KiB   16      100.0%            646d0ad2-b6e3-46f1-9f4b-4b240f772566  Port-Real

```

##### Précision dit le pramètre 'prefer_local=true' : 
```bash
Quand prefer_local=true, Cassandra préfère utiliser l'adresse IP locale (interne) d'un nœud pour communiquer avec lui lorsqu'il est dans le même datacenter,
plutôt que son adresse broadcast (qui peut être une IP externe/publique).
- Même DC  →  utilise l'IP locale             : économie de bande passante, latence réduite
- DC différent →  utilise l'IP broadcast      : nécessaire pour traverser le réseau
```

______
##### 5°) On va maintenant s'intéresser aux modifications apportées dans cassandra.yaml :
______

    Notamment au paramètre endpoint_snitch 
    
    NOTE: En modifiant la valeur par défaut du paramètre 'endpoint_snitch'  
    cela place le noeud dans une configuration de datacenter spécialisé (selon le type de workload par exemple).
    
    On utilise un Snitch personnalisé en le spécifiant dans le nom complet de la classe du snitch, 
    et qui sera supposé être stocké sur votre classpath.


##### Pour voir la configuration de cassandra01 :
```bash
docker exec -it cassandra01 cat /opt/cassandra/conf/cassandra.yaml | grep "endpoint_snitch"
```

###### Ou ici (c'est la même chose dans notre contexte de disques des consteneurs persistés en local  ) : 
```bash
cat ~/cassandra-tp00/docker/cassandra01-conf/cassandra.yaml | grep "endpoint_snitch"
```


##### De même, pour voir la configuration de cassandra02 :
```bash
docker exec -it cassandra02 cat /opt/cassandra/conf/cassandra.yaml | grep "endpoint_snitch"
```

###### Ou ici (c'est la même chose dans notre contexte de disques des consteneurs persistés en local  ) : 
```bash
cat ~/cassandra-tp00/docker/cassandra02-conf/cassandra.yaml | grep "endpoint_snitch"
```

#### On voit qu'on a changé la valeur par défaut du endpoint_snitch de 'SimpleSnitch' à 'GossipingPropertyFileSnitch'

##### Remarque : pour un noeud DSE, le snitch par défaut est "DseSimpleSnitch"


______
##### 6°) De la même façon, on regarde maintenant le fichier de configuration rack + DC de chaque noeud : "cassandra-rackdc.properties"
______

```text
Ce fichier contient les paramètres complémentaires utilisés avec 'GossipingPropertyFileSnitch'
Ils servent à préciser le rack et le datacenter (dc) auquel appartient ce noeud précis :

dc=dc1
rack=rack1

REMARQUE: Les rack et les datacenters sont des notions purement "logiques" pour Cassandra.
Vous devrez vous assurer que vos racks et datacenters (au sens "logiques" restent bien en phase avec la réalité physique de vos zones.
Ces zones correspondent à des risques de panne précis (perte d'un rack, d'un datacenter, etc)

```

##### Le nom du DataCenter a été modifié en indiquant la valeur 'Nord', et la valeur du paramètre rack en indiquant 'Winterfell'.

```text
Ces paramètres seront utilisés par le snitch avec la stratégie 'GossipingPropertyFileSnitch',
et indiqueront le DataCenter et le rack d'appartenance du noeud considéré.
```

##### Pour voir la configuration de cassandra01 :
```bash
docker exec -it cassandra01 head -n 21 /opt/cassandra/conf/cassandra-rackdc.properties
```

###### Ou ici (c'est la même chose dans notre contexte de disques des consteneurs persistés en local  ) : 
```bash
head -n 21 ~/cassandra-tp00/docker/cassandra01-conf/cassandra-rackdc.properties
```

##### On remarque les valeurs définies pour cassandra01 :
```bash
dc=Nord
rack=Winterfell
```

##### Pour voir la configuration de cassandra02 :
```bash
docker exec -it cassandra02 head -n 21 /opt/cassandra/conf/cassandra-rackdc.properties
```

###### Ou ici (c'est la même chose dans notre contexte de disques des consteneurs persistés en local  ) : 
```bash
head -n 21 ~/cassandra-tp00/docker/cassandra02-conf/cassandra-rackdc.properties
```
##### On remarque les valeurs définies pour cassandra02 :
```bash
dc=Terres-de-la-Couronne
rack=Port-Real
```

______
##### 7°) Une fois les deux noeuds opérationnels, lancez la commande : 
______
##### node/bin/dsetool status
```bash
docker exec -it cassandra nodsetool status
```

##### Et notez les assignations pour les différents noeuds, qui sont désormais :
##### Affichage : 

```text
Datacenter: Nord
================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving/Stopped
--  Address          Load       Tokens       Owns (effective)  Host ID                               Rack
UN  192.168.100.151  128.68 KiB  24           100.0%            0ab2eea0-adc1-4338-a92d-890e4508c242  Winterfell
Datacenter: Terres-de-la-Couronne
=================================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving/Stopped
--  Address          Load       Tokens       Owns (effective)  Host ID                               Rack
UN  192.168.100.152  0 bytes    24           100.0%            b7ec5a87-fdcb-46fe-96e7-60424ba73e62  Port-Real

```

______
##### Fin du TP07 : Snitches

______






