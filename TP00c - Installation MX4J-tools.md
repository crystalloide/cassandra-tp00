## TP00c - Installation MX4J-tools : 

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
	cassandra01		8081							8181
	cassandra02		8081							8281
	cassandra03		8081							8383
	cassandra04		8081							8483
	
	
#### Installation de VisualVM  :


#### 1. Téléchargement :
```bash
wget "https://sourceforge.net/projects/mx4j/files/MX4J%20Binary/3.0.2/mx4j-3.0.2.zip/download" -O mx4j-3.0.2.zip 
```

#### 2. Décompression :
```bash
unzip mx4j-3.0.2.zip
chmod 777 -Rf ~/cassandra-tp00/mx4j-3.0.2/lib
```

#### 3. Copie dans chaque conteneur :
```bash
docker cp mx4j-3.0.2/lib/mx4j-tools.jar cassandra01:/opt/cassandra/lib/
docker cp mx4j-3.0.2/lib/mx4j-tools.jar cassandra02:/opt/cassandra/lib/
docker cp mx4j-3.0.2/lib/mx4j-tools.jar cassandra03:/opt/cassandra/lib/
docker cp mx4j-3.0.2/lib/mx4j-tools.jar cassandra04:/opt/cassandra/lib/
```

#### 4. Prise en compte dans chaque conteneur dans /etc/cassandra/cassandra-env.sh :

#### cassandra01 :
```bash
docker exec cassandra01 sed -i \
  's/#\s*MX4J_ADDRESS=.*/MX4J_ADDRESS="192.168.100.151"/' \
  /etc/cassandra/cassandra-env.sh
```
```bash
docker exec cassandra01 sed -i \
  's/#\s*MX4J_PORT=.*/MX4J_PORT="-Dmx4jport=8081"/' \
  /etc/cassandra/cassandra-env.sh
```

#### cassandra02 :
```bash
docker exec cassandra02 sed -i \
  's/#\s*MX4J_ADDRESS=.*/MX4J_ADDRESS="192.168.100.152"/' \
  /etc/cassandra/cassandra-env.sh
```
```bash
docker exec cassandra02 sed -i \
  's/#\s*MX4J_PORT=.*/MX4J_PORT="-Dmx4jport=8081"/' \
  /etc/cassandra/cassandra-env.sh
```

#### cassandra03 :
```bash
docker exec cassandra03 sed -i \
  's/#\s*MX4J_ADDRESS=.*/MX4J_ADDRESS="192.168.100.153"/' \
  /etc/cassandra/cassandra-env.sh
```
```bash
docker exec cassandra03 sed -i \
  's/#\s*MX4J_PORT=.*/MX4J_PORT="-Dmx4jport=8081"/' \
  /etc/cassandra/cassandra-env.sh
```

#### cassandra04 :
```bash
docker exec cassandra04 sed -i \
  's/#\s*MX4J_ADDRESS=.*/MX4J_ADDRESS="192.168.100.154"/' \
  /etc/cassandra/cassandra-env.sh
```
```bash
docker exec cassandra04 sed -i \
  's/#\s*MX4J_PORT=.*/MX4J_PORT="-Dmx4jport=8081"/' \
  /etc/cassandra/cassandra-env.sh
```

#### 5. Prise en compte avec le redémarrage tour à tour des 4 noeuds cassnadra :
```bash
##### cassandra01 :
docker restart cassandra01 
sleep 15
```
```bash
##### cassandra02 :
docker restart cassandra02 
sleep 15
```
```bash
##### cassandra03 :
docker restart cassandra03 
sleep 15
```
```bash
##### cassandra04 :
docker restart cassandra04 
sleep 15
```

##### On vérifie que le cluster est bien "UN" pour les 4 noeuds :
```bash
docker exec -it cassandra01 nodetool status
```


#### Visualisation avec un navigateur web des informations des 4 noeuds du cluster Cassandra :

```bash
netstat -anl | grep :8

firefox http://192.168.100.151:8081/
firefox http://192.168.100.152:8081/
firefox http://192.168.100.153:8081/
firefox http://192.168.100.154:8081/
```
#### Ou :
```bash
firefox http://localhost:8181
firefox http://localhost:8281
firefox http://localhost:8381
firefox http://localhost:8481
```
