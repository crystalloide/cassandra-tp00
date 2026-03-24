_____
##### TP06 : les échanges avec le protocole Gossip
_____
##### Dans cet exercice, vous allez :
##### - Comprendre comment Cassandra utilise le protocole Gossip
##### - Comprendre comment les informations Gossip se propagent à travers un cluster
##### - Comprendre comment fonctionne un échange Gossip
_____
##### Contexte : 
##### 
##### Dans un système entièrement distribué tel que Cassandra, il n'y a pas de référentiel unique qui contienne l'état de tous les noeuds du cluster.
##### 
##### De toute évidence, un tel dépôt constituerait un SPOF.
##### 
##### Au lieu de cela, Cassandra utilise le protocole Gossip pour distribuer l'état des noeuds parmi ses pairs
##### 
##### Dans cet exercice, nous examinerons les informations Gossip pour notre cluster composé de deux noeuds.
_____
##### Etapes :
_____


##### 1°) Assurez-vous que les deux nœuds sont opérationnels en utilisant la commande 'nodetool status' sur les noeuds cassandra01 et cassandra02 : 
```bash
docker exec -it cassandra01 nodetool status
```

##### 2°) Exécutez la commande suivante: cassandra01 
```bash
docker exec -it cassandra01 nodetool gossipinfo
```

##### Et notez les informations Gossip pour les deux noeuds :

##### Affichage 1 : 
```bash
/192.168.100.152
  generation:1739121550
  heartbeat:183
  STATUS:81:NORMAL,-301076390668640482
  LOAD:162:108958.0
  SCHEMA:25:3d95894c-d62c-3d60-86f3-a13ef398cfde
  DC:13:Cassandra
  RACK:16:rack1
  RELEASE_VERSION:4:4.0.0.690
  NATIVE_TRANSPORT_ADDRESS:3:192.168.100.152
  DSE_GOSSIP_STATE:165:{"graph":false,"active":"true","dse_version":"6.9.0","workloads":"Cassandra","workload":"Cassandra","server_id":"08-00-27-88-AB-DB","health":0.2}
  NET_VERSION:1:1280
  HOST_ID:2:19780d73-626b-44aa-bda1-8cd157f4849c
  NATIVE_TRANSPORT_READY:100:true
  NATIVE_TRANSPORT_PORT:6:9042
  NATIVE_TRANSPORT_PORT_SSL:7:9042
  STORAGE_PORT:8:7000
  STORAGE_PORT_SSL:9:7001
  JMX_PORT:10:7199
  SCHEMA_COMPATIBILITY_VERSION:5:2
  TOKENS:80:<hidden>
/192.168.100.151
  generation:1739121362
  heartbeat:408
  STATUS:50:NORMAL,4851789387404451633
  LOAD:382:131763.0
  SCHEMA:96:3d95894c-d62c-3d60-86f3-a13ef398cfde
  DC:14:Cassandra
  RACK:17:rack1
  RELEASE_VERSION:4:4.0.0.690
  NATIVE_TRANSPORT_ADDRESS:3:192.168.100.151
  DSE_GOSSIP_STATE:354:{"graph":false,"active":"true","dse_version":"6.9.0","workloads":"Cassandra","workload":"Cassandra","server_id":"08-00-27-9F-D6-EB","health":0.4}
  NET_VERSION:1:1280
  HOST_ID:2:f5c592ab-bcf0-4df5-8699-7d10d2dead27
  NATIVE_TRANSPORT_READY:98:true
  NATIVE_TRANSPORT_PORT:7:9042
  NATIVE_TRANSPORT_PORT_SSL:8:9042
  STORAGE_PORT:9:7000
  STORAGE_PORT_SSL:10:7001
  JMX_PORT:11:7199
  SCHEMA_COMPATIBILITY_VERSION:5:2
  TOKENS:49:<hidden>
```

_____
##### Notez que même si nous avons exécuté cette commande sur le node cassandra01, ce noeud connaît aussi l'état "gossip" du noeud cassandra02.
##### Notez également que l'état du noeud se compose de paires "clé-valeurs".

_____
##### 3°) Réexécutez la même commande 'nodetool gossipinfo' à nouveau deux ou trois fois 
```bash
docker exec -it cassandra01 nodetool gossipinfo
```

##### Remarquez que les valeurs du battement de coeur augmentent pour les deux noeuds.

##### Sur cassandra01 :
```bash
docker exec -it cassandra01 nodetool gossipinfo
```

##### Affichage 2 : 
```bash

/192.168.100.152
  generation:1739121550
>>heartbeat:265 <<<<<<<<<<<<<<<<<<<<<<
  STATUS:81:NORMAL,-301076390668640482
  LOAD:226:108958.0
  SCHEMA:25:3d95894c-d62c-3d60-86f3-a13ef398cfde
  DC:13:Cassandra
  RACK:16:rack1
  RELEASE_VERSION:4:4.0.0.690
  NATIVE_TRANSPORT_ADDRESS:3:192.168.100.152
  DSE_GOSSIP_STATE:229:{"graph":false,"active":"true","dse_version":"6.9.0","workloads":"Cassandra","workload":"Cassandra","server_id":"08-00-27-88-AB-DB","health":0.3}
  NET_VERSION:1:1280
  HOST_ID:2:19780d73-626b-44aa-bda1-8cd157f4849c
  NATIVE_TRANSPORT_READY:100:true
  NATIVE_TRANSPORT_PORT:6:9042
  NATIVE_TRANSPORT_PORT_SSL:7:9042
  STORAGE_PORT:8:7000
  STORAGE_PORT_SSL:9:7001
  JMX_PORT:10:7199
  SCHEMA_COMPATIBILITY_VERSION:5:2
  TOKENS:80:<hidden>
/192.168.100.151
  generation:1739121362
>>heartbeat:491 <<<<<<<<<<<<<<<<<<<<<<
  STATUS:50:NORMAL,4851789387404451633
  LOAD:445:131763.0
  SCHEMA:96:3d95894c-d62c-3d60-86f3-a13ef398cfde
  DC:14:Cassandra
  RACK:17:rack1
  RELEASE_VERSION:4:4.0.0.690
  NATIVE_TRANSPORT_ADDRESS:3:192.168.100.151
  DSE_GOSSIP_STATE:354:{"graph":false,"active":"true","dse_version":"6.9.0","workloads":"Cassandra","workload":"Cassandra","server_id":"08-00-27-9F-D6-EB","health":0.4}
  NET_VERSION:1:1280
  HOST_ID:2:f5c592ab-bcf0-4df5-8699-7d10d2dead27
  NATIVE_TRANSPORT_READY:98:true
  NATIVE_TRANSPORT_PORT:7:9042
  NATIVE_TRANSPORT_PORT_SSL:8:9042
  STORAGE_PORT:9:7000
  STORAGE_PORT_SSL:10:7001
  JMX_PORT:11:7199
  SCHEMA_COMPATIBILITY_VERSION:5:2
  TOKENS:49:<hidden>
```


_____
##### 4°) Exécutez 'nodetool gossipinfo' sur cassandra02 au lieu de cassandra01. Notez que les données de Gossip sont identiques : 
_____

##### Sur cassandra02 :
```bash
docker exec -it cassandra02 nodetool gossipinfo
```

_____
##### 5°) Stoppez le 2nd noeud (cassandra02) en exécutant la commande :
_____
```bash
docker stop cassandra02
```

_____
##### 6°) Relancez la commande d'interrogation des informations gossip sur le node1.
#####    Les informations gossip sur le nœud2 sont toujours présentes car il fait partie du cluster, mais son STATUT est shutdown :

##### Sur cassandra01 :
```bash
docker exec -it cassandra01 nodetool gossipinfo
```

##### Affichage : 
```bash
/192.168.100.152
  generation:1739122036
  heartbeat:2147483647
>>STATUS:123:shutdown,true<<<<<<<<<<<<<<<<<<<<<<
  LOAD:95:287691.0
  SCHEMA:19:3d95894c-d62c-3d60-86f3-a13ef398cfde
  DC:14:Cassandra
  RACK:17:rack1
  RELEASE_VERSION:4:4.0.0.690
  NATIVE_TRANSPORT_ADDRESS:3:192.168.100.152
  DSE_GOSSIP_STATE:111:{"graph":false,"active":"false","dse_version":"6.9.0","workloads":"Cassandra","workload":"Cassandra","server_id":"08-00-27-88-AB-DB"}
  NET_VERSION:1:1280
  HOST_ID:2:19780d73-626b-44aa-bda1-8cd157f4849c
  NATIVE_TRANSPORT_READY:124:false
  NATIVE_TRANSPORT_PORT:7:9042
  NATIVE_TRANSPORT_PORT_SSL:8:9042
  STORAGE_PORT:9:7000
  STORAGE_PORT_SSL:10:7001
  JMX_PORT:11:7199
  SCHEMA_COMPATIBILITY_VERSION:5:2
  TOKENS:59:<hidden>
/192.168.100.151
  generation:1739122032
  heartbeat:126
  STATUS:45:NORMAL,4851789387404451633
  LOAD:95:265902.0
  SCHEMA:19:3d95894c-d62c-3d60-86f3-a13ef398cfde
  DC:14:Cassandra
  RACK:17:rack1
  RELEASE_VERSION:4:4.0.0.690
  NATIVE_TRANSPORT_ADDRESS:3:192.168.100.151
  DSE_GOSSIP_STATE:65:{"graph":false,"active":"true","dse_version":"6.9.0","workloads":"Cassandra","workload":"Cassandra","server_id":"08-00-27-9F-D6-EB"}
  NET_VERSION:1:1280
  HOST_ID:2:f5c592ab-bcf0-4df5-8699-7d10d2dead27
  NATIVE_TRANSPORT_READY:63:true
  NATIVE_TRANSPORT_PORT:7:9042
  NATIVE_TRANSPORT_PORT_SSL:8:9042
  STORAGE_PORT:9:7000
  STORAGE_PORT_SSL:10:7001
  JMX_PORT:11:7199
  SCHEMA_COMPATIBILITY_VERSION:5:2
  TOKENS:44:<hidden>

```

_____
##### 7°) Redémarrez le 2nd noeud cassandra02 :
```bash
docker start cassandra02
```
_____
##### 8°) Re-exécutez la commande 'nodetool gossipinfo' sur l'un ou l'autre nœud, 
#####    et notez que la valeur du champ 'génération' est restée inchangée pour le noeud 1, 
#####    mais que la valeur 'génération' a changé pour le noeud 2, depuis que nous l'avons redémarré : 

##### Sur cassandra01 :
```bash
docker exec -it cassandra01 nodetool gossipinfo
```

##### Affichage : 
```bash

/192.168.100.152
>>generation:1739122192<<<<<<<<<<<<<<< Nouveau
  heartbeat:32
  STATUS:6:hibernate,true
  LOAD:23:293162.0
  SCHEMA:19:3d95894c-d62c-3d60-86f3-a13ef398cfde
  DC:14:Cassandra
  RACK:17:rack1
  RELEASE_VERSION:4:4.0.0.690
  NATIVE_TRANSPORT_ADDRESS:3:192.168.100.152
  DSE_GOSSIP_STATE:12:{"graph":false,"active":false,"dse_version":"6.9.0","workloads":"Cassandra","workload":"Cassandra","server_id":"08-00-27-88-AB-DB"}
  NET_VERSION:1:1280
  HOST_ID:2:19780d73-626b-44aa-bda1-8cd157f4849c
  NATIVE_TRANSPORT_PORT:7:9042
  NATIVE_TRANSPORT_PORT_SSL:8:9042
  STORAGE_PORT:9:7000
  STORAGE_PORT_SSL:10:7001
  JMX_PORT:11:7199
  SCHEMA_COMPATIBILITY_VERSION:5:2
  TOKENS: not present
/192.168.100.151
>>generation:1739122032<<<<<<<<<<<<<<< Inchangé
  heartbeat:213
  STATUS:45:NORMAL,4851789387404451633
  LOAD:161:265902.0
  SCHEMA:19:3d95894c-d62c-3d60-86f3-a13ef398cfde
  DC:14:Cassandra
  RACK:17:rack1
  RELEASE_VERSION:4:4.0.0.690
  NATIVE_TRANSPORT_ADDRESS:3:192.168.100.151
  DSE_GOSSIP_STATE:195:{"graph":false,"active":"true","dse_version":"6.9.0","workloads":"Cassandra","workload":"Cassandra","server_id":"08-00-27-9F-D6-EB","health":0.3}
  NET_VERSION:1:1280
  HOST_ID:2:f5c592ab-bcf0-4df5-8699-7d10d2dead27
  NATIVE_TRANSPORT_READY:63:true
  NATIVE_TRANSPORT_PORT:7:9042
  NATIVE_TRANSPORT_PORT_SSL:8:9042
  STORAGE_PORT:9:7000
  STORAGE_PORT_SSL:10:7001
  JMX_PORT:11:7199
  SCHEMA_COMPATIBILITY_VERSION:5:2
  TOKENS:44:<hidden>
```



9°) Démarrez cqlsh et exécutez la requête suivante de la table system.peers qui stocke certaines données de discussion gossip sur les peers d'un noeud.
```bash
docker exec -it cassandra01 cqlsh
```

```sql
SELECT peer, data_center, host_id, preferred_ip, rack, release_version, rpc_address, schema_version
FROM system.peers;
```

##### Affichage : sur cassandra01, on obtient: 
```sql
    
     peer            | data_center | host_id                              | preferred_ip | rack  | release_version | rpc_address     | schema_version
    -----------------+-------------+--------------------------------------+--------------+-------+-----------------+-----------------+--------------------------------------
     192.168.100.151 | datacenter1 | aad76b9d-b975-4942-8772-d36896124cb3 |         null | rack1 |           5.0.6 | 192.168.100.151 | d03783d7-b468-3c1a-82f1-8e30b2edde8b
    
    (1 rows)

```
_____

```bash
docker exec -it cassandra01 cqlsh
```

```sql
SELECT peer, data_center, host_id, preferred_ip, rack, release_version, rpc_address, schema_version
FROM system.peers;
```

##### Affichage : sur cassandra02, on obtient: 
```sql
    
     peer            | data_center | host_id                              | preferred_ip | rack  | release_version | rpc_address     | schema_version
    -----------------+-------------+--------------------------------------+--------------+-------+-----------------+-----------------+--------------------------------------
     192.168.100.152 | datacenter1 | 86cf0dbf-7778-48b0-b8c8-044effc1735e |         null | rack1 |           5.0.6 | 192.168.100.152 | d03783d7-b468-3c1a-82f1-8e30b2edde8b

    (1 rows)

 ```

_____
##### Fin du TP06 : les échanges avec le protocole Gossip
_____

