_____________
#### TP02b : Interrogation avec CQLSH (suite) 
_____________

#### Commandes pratiques  
_____________

```sql
DESCRIBE CLUSTER;
```

```sql
DESCRIBE KEYSPACES;
```

```sql
DESCRIBE TABLES;
```

```sql
DROP KEYSPACE IF EXISTS formation;
```

```sql
CREATE KEYSPACE IF NOT EXISTS formation WITH replication = {'class': 'SimpleStrategy', 'replication_factor': '3'}  AND durable_writes = true;
```

```sql
DESCRIBE KEYSPACE formation;
```

```sql
USE formation;
```

```sql
CREATE TABLE formateurs(id uuid,name varchar,PRIMARY KEY(id, email));
#### InvalidRequest: Error from server: code=2200 [Invalid query] message="Unknown definition email referenced in PRIMARY KEY"
```

```sql
CREATE TABLE formateurs(id uuid,name varchar,PRIMARY KEY(id, name));
```

```sql
DESCRIBE table formateurs;
```

```sql
DROP TABLE formateurs;
```

```sql
CREATE TABLE formateurs(id uuid,name varchar,email varchar, PRIMARY KEY(id, name, email));
```

```sql
DESCRIBE table formateurs;
```

```sql
insert into formateurs (id,name,email) values (now(),'Steph','steph@gmail.com');
```

```sql
select * from formateurs ;
```

##### Affichage : 
     
    id                                   | name  | email
    --------------------------------------+-------+-----------------
    e65abf00-a2fa-11e7-8194-ef791791e2c9 | Steph | steph@gmail.com
    
    
```sql
help DESCRIBE
```

```sql
DESCRIBE formateurs;
```

```sql
##### Affichage :
     
     CREATE TABLE formation.formateurs (
         id uuid,
         name text,
         email text,
         PRIMARY KEY (id, name, email)
     ) WITH CLUSTERING ORDER BY (name ASC, email ASC)
         AND bloom_filter_fp_chance = 0.01
         AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
         AND comment = ''
         AND compaction = {'class': 'org.apache.cassandra.db.compaction.SizeTieredCompactionStrategy', 'max_threshold': '32', 'min_threshold': '4'}
         AND compression = {'chunk_length_in_kb': '64', 'class': 'org.apache.cassandra.io.compress.LZ4Compressor'}
         AND crc_check_chance = 1.0
         AND dclocal_read_repair_chance = 0.1
         AND default_time_to_live = 0
         AND gc_grace_seconds = 864000
         AND max_index_interval = 2048
         AND memtable_flush_period_in_ms = 0
         AND min_index_interval = 128
         AND read_repair_chance = 0.0
         AND speculative_retry = '99PERCENTILE';
     
```sql	
DESCRIBE FULL SCHEMA
```
```sql
SELECT * FROM system_auth.roles WHERE role = 'cassandra' ;
#### 
#### Reponse : 
#### 
####  role      | can_login | is_superuser | member_of | salted_hash
#### -----------+-----------+--------------+-----------+--------------------------------------------------------------
####  cassandra |      True |         True |      null | $2a$10$9WcE3xktKcy/fUyFrWz5/OAIkWXLigM/rr2uSABdu43ugj2c5uBT.
#### 
#### (1 rows)
#### 
#### 
```
```sql	
SELECT release_version from system.local;	
#### 
####  release_version
#### -----------------
####       4.0.0.690
#### 
#### (1 rows)
```
```sql
SELECT * FROM system.local;
####               
##
#### key   | bootstrapped | broadcast_address | cluster_name     | cql_version | data_center | dse_version | gossip_generation | graph | host_id                              | jmx_port | last_nodesync_checkpoint_time | listen_address  | native_protocol_version | native_transport_address | native_transport_port | native_transport_port_ssl | partitioner                                 | rack  | release_version | rpc_address     | schema_version                       | server_id         | storage_port | storage_port_ssl | tokens                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | truncated_at                                                                       | workload  | workloads
##-------+--------------+-------------------+------------------+-------------+-------------+-------------+-------------------+-------+--------------------------------------+----------+-------------------------------+-----------------+-------------------------+--------------------------+-----------------------+---------------------------+---------------------------------------------+-------+-----------------+-----------------+--------------------------------------+-------------------+--------------+------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+------------------------------------------------------------------------------------+-----------+---------------
#### local |    COMPLETED |   192.168.100.151 | ClusterFormation |       3.4.5 |   Cassandra |       6.9.0 |        1739117030 | False | f6d7a8da-ec7f-4929-8eaf-c6fddc6bd448 |     7199 |                 1739118428237 | 192.168.100.151 |                      66 |          192.168.100.151 |                  9042 |                      9042 | org.apache.cassandra.dht.Murmur3Partitioner | rack1 |       4.0.0.690 | 192.168.100.151 | 31312590-033e-34a4-b152-08ada0587bd4 | 08-00-27-9F-D6-EB |         7000 |             7001 | {'-2824562519468359799', '-3300300928521130035', '-3837220325168685120', '-4181642309827697127', '-4926078509190935726', '-5060418973508490534', '-6768492383777754259', '-6788591963689036863', '-764964159587288289', '-7800984295232408291', '-7949002462826125994', '2568224245856531587', '2860957674575838759', '3112305801193221207', '3191335179883227608', '3460876135151834595', '4299770232866265927', '4806181429991689662', '5131870838997658526', '5379998650194014366', '7623951828721033563', '7887209075905703537', '8377913880169477132', '8801958483900375577'} | {2b15a5f1-e700-11ef-9e86-994d0f5a37c9: 0x00000194eb73d90a001469d000000194eb7c6bac} | Cassandra | {'Cassandra'}
##
##(1 rows)
##
```
```sql
SELECT * FROM system.peers ;

#### Affichage :
##
#### peer            | data_center | dse_version | graph | host_id                              | jmx_port | native_transport_address | native_transport_port | native_transport_port_ssl | preferred_ip | rack  | release_version | rpc_address     | schema_version                       | server_id         | storage_port | storage_port_ssl | tokens                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | workload  | workloads
##-----------------+-------------+-------------+-------+--------------------------------------+----------+--------------------------+-----------------------+---------------------------+--------------+-------+-----------------+-----------------+--------------------------------------+-------------------+--------------+------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------+---------------
#### 192.168.100.152 |   Cassandra |       6.9.0 | False | d40c87b6-2c74-4b39-97a6-854d6b260977 |     7199 |          192.168.100.152 |                  9042 |                      9042 |         null | rack1 |       4.0.0.690 | 192.168.100.152 | 31312590-033e-34a4-b152-08ada0587bd4 | 08-00-27-88-AB-DB |         7000 |             7001 |  {'-1462183743673895177', '-2412101696198385058', '-2980593748435926622', '-4091935521210056232', '-4263150319929115437', '-4341768020588559468', '-5374264953821406431', '-6349847079363924025', '-6574336836186328343', '-6898707174049670627', '-7916178890966898833', '-8093124166766032880', '-8820758783353856101', '143751790938636540', '2198647525139090680', '239669782285519371', '3577491738806773744', '4112887262615108647', '5969468450737709962', '7360024699345338031', '7785936581073354093', '7788648710482429861', '8284622383564786125', '8766851559616562647'} | Cassandra | {'Cassandra'}
#### 192.168.100.153 |   Cassandra |       6.9.0 | False | 1fa8a490-dbb1-41f8-b632-10a123dfc928 |     7199 |          192.168.100.153 |                  9042 |                      9042 |         null | rack1 |       4.0.0.690 | 192.168.100.153 | 31312590-033e-34a4-b152-08ada0587bd4 | 08-00-27-FD-46-D4 |         7000 |             7001 |  {'-1381180389879975695', '-2144443592712495240', '-287979547834166874', '-3364486050124995310', '-4644371288245577914', '-5194236571203591767', '-5312717217442679434', '-6342096455870373996', '-6756721518646948642', '-6938884660418942604', '-6962571205330609111', '-9082866042896245054', '-9107947285685881723', '1742837411655575929', '1932237192768454977', '3427889303586857440', '3480259684461790882', '416860088715069051', '4670644742563166231', '5162110447849510888', '5850408226463962103', '7322589609158370265', '7418908232928114352', '8029724290408402689'} | Cassandra | {'Cassandra'}
#### 192.168.100.154 |   Cassandra |       6.9.0 | False | 768eed6c-ece9-42c1-a068-4fdcbac71984 |     7199 |          192.168.100.154 |                  9042 |                      9042 |         null | rack1 |       4.0.0.690 | 192.168.100.154 | 31312590-033e-34a4-b152-08ada0587bd4 | 08-00-27-E4-93-C4 |         7000 |             7001 | {'-2082892977374867779', '-2376182644184851286', '-3484521047206676749', '-370513920356477974', '-4057661378743841557', '-4338000272040355768', '-5395020945551427389', '-5606415705145558360', '-5748236348746221569', '-5901803264536605360', '-6060409975737967579', '-6523946152138459701', '-7512678050456324951', '-916099800689020887', '1522454276041964884', '2138215726731766668', '2370801765343565760', '6714804119621250847', '6978129136733598886', '8199526454566428200', '8227203468202707177', '8268297863680175784', '8943000271816296244', '9017252158268207759'} | Cassandra | {'Cassandra'}
##
##(1 rows)
##
```
```sql
SELECT * FROM system.compaction_history ;

#### Affichage : 
#### 
####  id                                   | bytes_in | bytes_out | columnfamily_name    | compacted_at                    | keyspace_name      | rows_merged
#### --------------------------------------+----------+-----------+----------------------+---------------------------------+--------------------+---------------
####  808df295-e6ff-11ef-9e86-994d0f5a37c9 |        0 |         0 |            functions | 2025-02-09 16:04:12.419000+0000 |      system_schema |          null
####  2009bca0-e700-11ef-9e86-994d0f5a37c9 |      887 |       528 |            keyspaces | 2025-02-09 16:08:39.616000+0000 |      system_schema | {1: 12, 2: 3}
####  808df293-e6ff-11ef-9e86-994d0f5a37c9 |        0 |         0 |           aggregates | 2025-02-09 16:04:12.348000+0000 |      system_schema |          null
####  19ba5f10-e702-11ef-9e86-994d0f5a37c9 |     4973 |      4166 |               tables | 2025-02-09 16:22:48.310000+0000 |      system_schema | {1: 15, 2: 1}
####  808df290-e6ff-11ef-9e86-994d0f5a37c9 |        0 |         0 |              indexes | 2025-02-09 16:04:12.194000+0000 |      system_schema |          null
####  19f2fb40-e702-11ef-9e86-994d0f5a37c9 |     1984 |      1248 |  prepared_statements | 2025-02-09 16:22:48.416000+0000 |             system |  {1: 7, 2: 9}
####  808da470-e6ff-11ef-9e86-994d0f5a37c9 |        0 |         0 |                edges | 2025-02-09 16:04:12.061000+0000 |      system_schema |          null
####  80ee6210-e6ff-11ef-9e86-994d0f5a37c9 |        0 |         0 |     sstable_activity | 2025-02-09 16:04:12.676000+0000 |             system |          null
####  80db7650-e6ff-11ef-9e86-994d0f5a37c9 |        0 |         0 |      nodesync_status | 2025-02-09 16:04:12.657000+0000 | system_distributed |          null
####  808df292-e6ff-11ef-9e86-994d0f5a37c9 |       98 |        78 |      dropped_columns | 2025-02-09 16:04:12.506000+0000 |      system_schema |        {1: 2}
####  808da471-e6ff-11ef-9e86-994d0f5a37c9 |        0 |         0 |                views | 2025-02-09 16:04:12.175000+0000 |      system_schema |          null
####  80f4cab0-e6ff-11ef-9e86-994d0f5a37c9 |     7109 |      4065 |               tables | 2025-02-09 16:04:12.802000+0000 |      system_schema | {1: 11, 2: 3}
####  808df291-e6ff-11ef-9e86-994d0f5a37c9 |        0 |         0 |             vertices | 2025-02-09 16:04:12.233000+0000 |      system_schema |          null
####  808ba8a0-e6ff-11ef-9e86-994d0f5a37c9 |        0 |         0 |       hidden_columns | 2025-02-09 16:04:12.084000+0000 |      system_schema |          null
####  0143b4e0-e702-11ef-9e86-994d0f5a37c9 |      919 |       551 |            keyspaces | 2025-02-09 16:22:06.979000+0000 |      system_schema | {1: 14, 2: 2}
####  80ef7380-e6ff-11ef-9e86-994d0f5a37c9 |        0 |         0 | nodesync_checkpoints | 2025-02-09 16:04:12.677000+0000 |             system |          null
####  80f31d00-e6ff-11ef-9e86-994d0f5a37c9 |    15764 |      9936 |              columns | 2025-02-09 16:04:12.876000+0000 |      system_schema | {1: 11, 2: 3}
####  19b94da0-e702-11ef-9e86-994d0f5a37c9 |    10297 |     10099 |              columns | 2025-02-09 16:22:48.351000+0000 |      system_schema | {1: 15, 2: 1}
####  810dd0f0-e6ff-11ef-9e86-994d0f5a37c9 |        0 |         0 |      nodesync_status | 2025-02-09 16:04:12.813000+0000 | system_distributed |          null
####  808df294-e6ff-11ef-9e86-994d0f5a37c9 |        0 |         0 |             triggers | 2025-02-09 16:04:12.382000+0000 |      system_schema |          null
#### 
#### (20 rows)
#### 
```
```sql
SELECT * FROM system_schema.keyspaces;

#### Affichage : 
##
####  keyspace_name       | durable_writes | graph_engine | replication
#### ---------------------+----------------+--------------+-------------------------------------------------------------------------------------
####          system_auth |           True |         null | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '1'}
####        system_schema |           True |         null |                             {'class': 'org.apache.cassandra.locator.LocalStrategy'}
####     dse_system_local |           True |         null |                             {'class': 'org.apache.cassandra.locator.LocalStrategy'}
####           dse_system |           True |         null |                        {'class': 'org.apache.cassandra.locator.EverywhereStrategy'}
####           dse_leases |           True |         null | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '1'}
####            formation |           True |         null | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '3'}
####           solr_admin |           True |         null |                        {'class': 'org.apache.cassandra.locator.EverywhereStrategy'}
####         dse_insights |           True |         null |                        {'class': 'org.apache.cassandra.locator.EverywhereStrategy'}
####   dse_insights_local |           True |         null |                             {'class': 'org.apache.cassandra.locator.LocalStrategy'}
####   system_distributed |           True |         null | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '3'}
####       system_backups |           True |         null |                        {'class': 'org.apache.cassandra.locator.EverywhereStrategy'}
####               system |           True |         null |                             {'class': 'org.apache.cassandra.locator.LocalStrategy'}
####             dse_perf |           True |         null | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '1'}
####        system_traces |           True |         null | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '2'}
####  entrepriseformation |           True |         null | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '1'}
####         dse_security |           True |         null | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '1'}
#### 
#### (16 rows)
#### 
```
```sql
#### Interrogation de la table keyspaces avec un ordre de SELECT :
SELECT * FROM system_schema.keyspaces;

#### Affichage : 

	 keyspace_name       | durable_writes | graph_engine | replication
	---------------------+----------------+--------------+-------------------------------------------------------------------------------------
			 system_auth |           True |         null | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '1'}
		   system_schema |           True |         null |                             {'class': 'org.apache.cassandra.locator.LocalStrategy'}
		dse_system_local |           True |         null |                             {'class': 'org.apache.cassandra.locator.LocalStrategy'}
			  dse_system |           True |         null |                        {'class': 'org.apache.cassandra.locator.EverywhereStrategy'}
			  dse_leases |           True |         null | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '1'}
			   formation |           True |         null | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '3'}
			  solr_admin |           True |         null |                        {'class': 'org.apache.cassandra.locator.EverywhereStrategy'}
			dse_insights |           True |         null |                        {'class': 'org.apache.cassandra.locator.EverywhereStrategy'}
	  dse_insights_local |           True |         null |                             {'class': 'org.apache.cassandra.locator.LocalStrategy'}
	  system_distributed |           True |         null | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '3'}
		  system_backups |           True |         null |                        {'class': 'org.apache.cassandra.locator.EverywhereStrategy'}
				  system |           True |         null |                             {'class': 'org.apache.cassandra.locator.LocalStrategy'}
				dse_perf |           True |         null | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '1'}
		   system_traces |           True |         null | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '2'}
	 entrepriseformation |           True |         null | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '1'}
			dse_security |           True |         null | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '1'}



```
```sql
#### Interrogation de system_schema concernant une table précise : 
_____________
SELECT * FROM system_schema.tables WHERE keyspace_name = 'formation' AND table_name = 'formateurs';

#### Affichage : 
#### 
####  keyspace_name | table_name | additional_write_policy | bloom_filter_fp_chance | caching                                       | cdc  | comment | compaction                                                                                                                | compression                                                                             | crc_check_chance | dclocal_read_repair_chance | default_time_to_live | extensions | flags        | gc_grace_seconds | id                                   | max_index_interval | memtable_flush_period_in_ms | min_index_interval | nodesync                                   | read_repair | read_repair_chance | speculative_retry
#### ---------------+------------+-------------------------+------------------------+-----------------------------------------------+------+---------+---------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------------------------------+------------------+----------------------------+----------------------+------------+--------------+------------------+--------------------------------------+--------------------+-----------------------------+--------------------+--------------------------------------------+-------------+--------------------+-------------------
####      formation | formateurs |            99PERCENTILE |                   0.01 | {'keys': 'ALL', 'rows_per_partition': 'NONE'} | null |         | {'class': 'org.apache.cassandra.db.compaction.SizeTieredCompactionStrategy', 'max_threshold': '32', 'min_threshold': '4'} | {'chunk_length_in_kb': '64', 'class': 'org.apache.cassandra.io.compress.LZ4Compressor'} |                1 |                          0 |                    0 |           {} | {'compound'} |           864000 | 22fafe40-e702-11ef-9e86-994d0f5a37c9 |               2048 |                           0 |                128 | {'enabled': 'true', 'incremental': 'true'} |    BLOCKING |                  0 |      99PERCENTILE
#### 
#### (1 rows)
#### 

```

#### Interrogation de schema_columns sur les colonnes d'une table : 

```sql
SELECT * FROM system_schema.columns WHERE keyspace_name = 'formation' AND table_name = 'formateurs';

#### Affichage : 
#### 
####  keyspace_name | table_name | column_name | clustering_order | column_name_bytes | kind          | position | required_for_liveness | type
#### ---------------+------------+-------------+------------------+-------------------+---------------+----------+-----------------------+------
####      formation | formateurs |       email |              asc |      0x656d61696c |    clustering |        1 |                 False | text
####      formation | formateurs |          id |             none |            0x6964 | partition_key |        0 |                 False | uuid
####      formation | formateurs |        name |              asc |        0x6e616d65 |    clustering |        0 |                 False | text
#### 
#### (3 rows)
#### 

```
```sql
#### On sort du client shell cassandra CQLSH :  
exit
```

_____________
#### Fin du TP02b : Interrogation avec CQLSH (suite)

_____________

