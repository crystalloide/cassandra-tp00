## TP00 - Cassandra 5.0 avec Docker Compose (Cluster 4 nœuds)

Cassandra 5.0 avec Docker Compose (Cluster 4 nœuds)

https://github.com/crystalloide/cassandra-tp00

Cluster Cassandra déployé via Docker Compose avec 4 nœuds sur 4 racks différents dans un seul datacenter DC1.

#### Vue d'ensemble du cluster

Le fichier `Cluster_4_noeuds_4_racks_1_DC.yml` déploie :

- **4 nœuds Cassandra** : cassandra01, cassandra02, cassandra03, cassandra04
- **1 datacenter** : dc1
- **4 racks** : Rack1, Rack2, Rack3, Rack4
- **Seeds** : cassandra01 et cassandra03
- **Réseau** : 192.168.100.0/24


#### Prérequis

- Docker et Docker Compose installés
- Au minimum 4 GB RAM disponible (1 GB par nœud)
- 2 CPU cores disponibles

#### Ressources additionnelles

- Documentation officielle Cassandra : https://cassandra.apache.org/doc/latest/
- Guide CQL : https://cassandra.apache.org/doc/latest/cassandra/cql/
- Dataset IMDB : https://www.kaggle.com/datasets/hoomch/imdb-full-dataset
- Nodetool commands : https://cassandra.apache.org/doc/latest/cassandra/tools/nodetool/nodetool.html

***

**Remarques importantes** :

- Le cluster utilise NetworkTopologyStrategy qui est recommandé pour la production
- Les 4 racks permettent une meilleure résilience et distribution des données
- Les healthchecks garantissent un démarrage ordonné du cluster
- Le facteur de réplication de 3 assure la disponibilité même si un nœud tombe

Bon travail avec Cassandra ! 🚀

<div align="center">:-)</div>
