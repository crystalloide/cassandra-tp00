## TP00b - Installation VisualVM - JMX

Cassandra 5.0 avec Docker Compose (Cluster 4 nœuds)

https://github.com/crystalloide/cassandra-tp00

Cluster Cassandra déployé via Docker Compose avec 4 nœuds sur 4 racks différents dans un seul datacenter DC1.

#### Vue d'ensemble du cluster

Le fichier `Cluster_4_noeuds_4_racks_1_DC.yml` déploie :

- **4 nœuds Cassandra** : cassandra01, cassandra02, cassandra03, cassandra04
- **1 datacenter** : DC1
- **4 racks** : Rack1, Rack2, Rack3, Rack4
- **Seeds** : cassandra01 et cassandra03
- **Réseau** : 192.168.100.0/24


#### Prérequis

- Cluster Cassandra lancé 

#### Informations : 

- Configuration JMX activée via les variables d'environnement :
	LOCAL_JMX=no → autorise les connexions JMX distantes
	JVM_EXTRA_OPTS → fixe le hostname RMI et désactive l'authentification

- Ports exposés sur l'hôte :
	Nœud			Port JMX dans le conteneur		Port exposé sur l'hôte
	cassandra01		7199							7199
	cassandra02		7199							7299
	cassandra03		7199							7399
	cassandra04		7199							7499
	
	
#### Installation de VisualVM  :

```bash
# Télécharger depuis GitHub
wget https://github.com/oracle/visualvm/releases/download/2.2.1/visualvm_221.zip
unzip visualvm_221.zip
cd visualvm_221/bin
./visualvm
```


#### Paramétrage des connextions avec les 4 noeuds du cluster Cassandra :

```bash
> File > Add JMX connexion :
Dans le champs "Connexion" :  cassandra01:7199
Dans le champs "Display name" : cassandra01

> File > Add JMX connexion :
Dans le champs "Connexion" :  cassandra02:7199
Dans le champs "Display name" : cassandra02

> File > Add JMX connexion :
Dans le champs "Connexion" :  cassandra03:7199
Dans le champs "Display name" : cassandra03

> File > Add JMX connexion :
Dans le champs "Connexion" :  cassandra04:7199
Dans le champs "Display name" : cassandra04

```