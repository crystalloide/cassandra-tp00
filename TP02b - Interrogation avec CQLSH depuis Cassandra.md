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
```
    InvalidRequest: Error from server: code=2200 [Invalid query] message="Unknown definition email referenced in PRIMARY KEY"

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
##### Affichage :
         
    CREATE TABLE formation.formateurs (
        id uuid,
        name text,
        email text,
        PRIMARY KEY (id, name, email)
    ) WITH CLUSTERING ORDER BY (name ASC, email ASC)
        AND additional_write_policy = '99p'
        AND allow_auto_snapshot = true
        AND bloom_filter_fp_chance = 0.01
        AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
        AND cdc = false
        AND comment = ''
        AND compaction = {'class': 'org.apache.cassandra.db.compaction.SizeTieredCompactionStrategy', 'max_threshold': '32', 'min_threshold': '4'}
        AND compression = {'chunk_length_in_kb': '16', 'class': 'org.apache.cassandra.io.compress.LZ4Compressor'}
        AND memtable = 'default'
        AND crc_check_chance = 1.0
        AND default_time_to_live = 0
        AND extensions = {}
        AND gc_grace_seconds = 864000
        AND incremental_backups = true
        AND max_index_interval = 2048
        AND memtable_flush_period_in_ms = 0
        AND min_index_interval = 128
        AND read_repair = 'BLOCKING'
        AND speculative_retry = '99p';
     
```sql	
DESCRIBE FULL SCHEMA
```

```sql
SELECT * FROM system_auth.roles WHERE role = 'cassandra' ;
```

#### Retour : 
     
      role      | can_login | is_superuser | member_of | salted_hash
     -----------+-----------+--------------+-----------+--------------------------------------------------------------
      cassandra |      True |         True |      null | $2a$10$9WcE3xktKcy/fUyFrWz5/OAIkWXLigM/rr2uSABdu43ugj2c5uBT.
     
     (1 rows)
     
     
```sql	
SELECT release_version from system.local;
```
     
      release_version
     -----------------
            5.0.6
     
     (1 rows)

```sql
SELECT * FROM system.local;
```
####   Très verbeux en sortie :-)            
     key   | bootstrapped | broadcast_address | broadcast_port | cluster_name | cql_version | data_center | gossip_generation | host_id                              | listen_address  | listen_port | native_protocol_version | partitioner                                 | rack  | release_version | rpc_address     | rpc_port | schema_version                       | tokens                                                                                                                                                                                                                                                                                                                                                                                | truncated_at
-------+--------------+-------------------+----------------+--------------+-------------+-------------+-------------------+--------------------------------------+-----------------+-------------+-------------------------+---------------------------------------------+-------+-----------------+-----------------+----------+--------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 local |    COMPLETED |   192.168.100.151 |           7000 |    formation |       3.4.7 |         dc1 |        1772463383 | 13473850-0ed8-4adb-9cc3-923efb56ecd9 | 192.168.100.151 |        7000 |                       5 | org.apache.cassandra.dht.Murmur3Partitioner | Rack1 |           5.0.6 | 192.168.100.151 |     9042 | 295bd808-1a9a-3532-8165-1468fc8994e9 | {'-2232357009261046592', '-3076733656752208348', '-4168030767444420608', '-5264072667679358897', '-7042706968502946026', '-792088779358463353', '-8020852421019060102', '1297263241723996474', '2114935174336347269', '279411836981569459', '3190691055561926808', '3926606748272820449', '5005979555720422107', '6249499561401014079', '7216863804479549578', '8806868356993448216'} | {176c39cd-b93d-33a5-a218-8eb06a56f66e: 0x0000019caf0ca785000077dd0000019caf0cd98a, 618f817b-005f-3678-b8a4-53f3930b8e86: 0x0000019caf0ca785000076cd0000019caf0cd877, 62efe31f-3be8-310c-8d29-8963439c1288: 0x0000019caa692b40000001c60000019caa69407f, a9ef3620-162a-11f1-81e9-a3342f18b42d: 0x0000019cae06e0b60008cccc0000019cae723c15}

(1 rows)    

```sql
SELECT * FROM system.peers ;

#### Affichage :
     peer            | data_center | host_id                              | preferred_ip | rack  | release_version | rpc_address     | schema_version                       | tokens
-----------------+-------------+--------------------------------------+--------------+-------+-----------------+-----------------+--------------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     192.168.100.152 |         dc1 | 67895141-9db1-467c-8c15-b0e57fe4fa72 |         null | Rack2 |           5.0.6 | 192.168.100.152 | 295bd808-1a9a-3532-8165-1468fc8994e9 |  {'-1432528338599916308', '-174107747456263275', '-3554223238602151417', '-4611599755531109634', '-5961801582105787518', '-6388088083386916908', '-7422388730062321275', '-8680809446007764364', '-9078132298356477155', '2710237543296746519', '4587301872809732548', '5756256795988746927', '6805380596317938015', '7741293769109453435', '8156931428681093315', '890233242316800120'}
     192.168.100.153 |         dc1 | 2c0c4b8e-f221-4db2-9ead-4eb9030539cc |         null | Rack3 |           5.0.6 | 192.168.100.153 | 295bd808-1a9a-3532-8165-1468fc8994e9 | {'-1072509193968626543', '-1737017896145884617', '-2563864352883997887', '-3806302667564130039', '-410377687666385307', '-4863859352254178598', '-5530790101175119434', '-6678113809530796142', '-7656004665924284806', '-8288988489397418930', '1790101251393861223', '3622016980348943906', '4336312444746604899', '5453550895618302493', '651974712003966231', '8525274620307868633'}
     192.168.100.154 |         dc1 | 3a11e986-d24f-46f3-83b2-bc0632ac5991 |         null | Rack4 |           5.0.6 | 192.168.100.154 | 295bd808-1a9a-3532-8165-1468fc8994e9 |     {'-1584773117372900463', '-2820299004818103118', '-5397431384427239166', '-6174944832746352213', '-6860410389016871084', '-8879470872182120760', '1543682246558928848', '2412586358816546894', '3406354017955435357', '4796640714265077327', '52652044762653092', '6002878178694880503', '7011122200398743796', '7479078786794501506', '8341103024494480974', '9087740066173261338'}

    (3 rows)

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






