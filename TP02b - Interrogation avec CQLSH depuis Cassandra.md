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
```
##### Affichage :

     peer            | data_center | host_id                              | preferred_ip | rack  | release_version | rpc_address     | schema_version                       | tokens
    -----------------+-------------+--------------------------------------+--------------+-------+-----------------+-----------------+--------------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     192.168.100.152 |         dc1 | 67895141-9db1-467c-8c15-b0e57fe4fa72 |         null | Rack2 |           5.0.6 | 192.168.100.152 | 295bd808-1a9a-3532-8165-1468fc8994e9 |  {'-1432528338599916308', '-174107747456263275', '-3554223238602151417', '-4611599755531109634', '-5961801582105787518', '-6388088083386916908', '-7422388730062321275', '-8680809446007764364', '-9078132298356477155', '2710237543296746519', '4587301872809732548', '5756256795988746927', '6805380596317938015', '7741293769109453435', '8156931428681093315', '890233242316800120'}
     192.168.100.153 |         dc1 | 2c0c4b8e-f221-4db2-9ead-4eb9030539cc |         null | Rack3 |           5.0.6 | 192.168.100.153 | 295bd808-1a9a-3532-8165-1468fc8994e9 | {'-1072509193968626543', '-1737017896145884617', '-2563864352883997887', '-3806302667564130039', '-410377687666385307', '-4863859352254178598', '-5530790101175119434', '-6678113809530796142', '-7656004665924284806', '-8288988489397418930', '1790101251393861223', '3622016980348943906', '4336312444746604899', '5453550895618302493', '651974712003966231', '8525274620307868633'}
     192.168.100.154 |         dc1 | 3a11e986-d24f-46f3-83b2-bc0632ac5991 |         null | Rack4 |           5.0.6 | 192.168.100.154 | 295bd808-1a9a-3532-8165-1468fc8994e9 |     {'-1584773117372900463', '-2820299004818103118', '-5397431384427239166', '-6174944832746352213', '-6860410389016871084', '-8879470872182120760', '1543682246558928848', '2412586358816546894', '3406354017955435357', '4796640714265077327', '52652044762653092', '6002878178694880503', '7011122200398743796', '7479078786794501506', '8341103024494480974', '9087740066173261338'}

    (3 rows)
	
```sql
SELECT * FROM system.compaction_history LIMIT 20;
```
##### Affichage : 
     id                                   | bytes_in | bytes_out | columnfamily_name   | compacted_at                    | compaction_properties             | keyspace_name | rows_merged
    --------------------------------------+----------+-----------+---------------------+---------------------------------+-----------------------------------+---------------+------------------------------------
     53b0d0d0-161f-11f1-8ffd-a97acb5ce2f8 |      204 |        51 |          aggregates | 2026-03-02 10:05:23.209000+0000 | {'compaction_type': 'Compaction'} | system_schema |                             {4: 2}
     ef814c8a-1627-11f1-81e9-a3342f18b42d |        0 |         0 | sstable_activity_v2 | 2026-03-02 11:07:00.349000+0000 | {'compaction_type': 'Compaction'} |        system |                               null
     1a2739f0-1627-11f1-81e9-a3342f18b42d |     4021 |      3936 |              tables | 2026-03-02 11:01:02.465000+0000 | {'compaction_type': 'Compaction'} | system_schema |                       {1: 7, 2: 1}
     0f8ed720-1620-11f1-81e9-a3342f18b42d |    13409 |      3491 |        column_masks | 2026-03-02 10:10:38.589000+0000 | {'compaction_type': 'Compaction'} | system_schema |                       {1: 1, 4: 2}
     a3bfa290-159d-11f1-a2a5-eb793db39d3d |  2062621 |   2086372 |   imdb.idx_director | 2026-03-01 18:37:04.568000+0000 | {'compaction_type': 'Compaction'} |     formation | {1: 11112, 2: 1362, 3: 298, 4: 37}
     53f18350-161f-11f1-8ffd-a97acb5ce2f8 |      204 |        51 |           functions | 2026-03-02 10:05:23.627000+0000 | {'compaction_type': 'Compaction'} | system_schema |                             {4: 2}
     61dfbc50-1630-11f1-81e9-a3342f18b42d |      910 |       752 |               local | 2026-03-02 12:07:28.273000+0000 | {'compaction_type': 'Compaction'} |        system |                             {4: 1}
     8a5cc590-164b-11f1-a651-a3342f18b42d |    10332 |      3474 |        column_masks | 2026-03-02 15:21:52.750000+0000 | {'compaction_type': 'Compaction'} | system_schema |                 {1: 1, 2: 2, 3: 2}
     53cff190-161f-11f1-8ffd-a97acb5ce2f8 |      204 |        51 |            triggers | 2026-03-02 10:05:23.331000+0000 | {'compaction_type': 'Compaction'} | system_schema |                             {4: 2}
     fedf6ca0-159d-11f1-a2a5-eb793db39d3d |  4059116 |   4125392 |       imdb.idx_year | 2026-03-01 18:39:38.824000+0000 | {'compaction_type': 'Compaction'} |     formation |        {1: 16, 2: 5, 3: 8, 4: 105}
     a7862560-162a-11f1-81e9-a3342f18b42d |     8490 |      8249 |             columns | 2026-03-02 11:26:28.169000+0000 | {'compaction_type': 'Compaction'} | system_schema |                 {1: 6, 2: 1, 3: 1}
     0b7a5a60-159e-11f1-a2a5-eb793db39d3d | 19797659 |  19938082 |                imdb | 2026-03-01 18:40:01.869000+0000 | {'compaction_type': 'Compaction'} |     formation |                        {1: 340429}
     34193220-162a-11f1-81e9-a3342f18b42d |      212 |       101 |               types | 2026-03-02 11:23:12.813000+0000 | {'compaction_type': 'Compaction'} | system_schema |                       {1: 2, 2: 2}
     6a7a0a60-1625-11f1-81e9-a3342f18b42d |      197 |        80 |            triggers | 2026-03-02 10:48:58.323000+0000 | {'compaction_type': 'Compaction'} | system_schema |                       {1: 1, 3: 2}
     ff7ae810-1647-11f1-a651-a3342f18b42d |        0 |         0 |    sstable_activity | 2026-03-02 14:56:31.044000+0000 | {'compaction_type': 'Compaction'} |        system |                               null
     f33bc540-159f-11f1-801f-539f6c47747a |     1028 |       709 |               local | 2026-03-01 18:53:35.395000+0000 | {'compaction_type': 'Compaction'} |        system |                             {5: 1}
     d5bc1bc0-1647-11f1-9526-f9f6314fde6a |     1092 |       754 |               local | 2026-03-02 14:55:21.296000+0000 | {'compaction_type': 'Compaction'} |        system |                             {5: 1}
     73dce5c0-15b0-11f1-a2f3-295a5859a2aa |     1021 |       708 |               local | 2026-03-01 20:51:42.966000+0000 | {'compaction_type': 'Compaction'} |        system |                             {4: 1}
     b70bd210-159d-11f1-a2a5-eb793db39d3d |  2638269 |   2673827 |   imdb.idx_director | 2026-03-01 18:37:37.307000+0000 | {'compaction_type': 'Compaction'} |     formation | {1: 14169, 2: 1572, 3: 232, 4: 16}
     10084ce0-1620-11f1-81e9-a3342f18b42d |     1051 |       711 |               local | 2026-03-02 10:10:39.063000+0000 | {'compaction_type': 'Compaction'} |        system |                             {5: 1}

    (20 rows)
	
#### Interrogation de la table keyspaces avec un ordre de SELECT :
```sql
SELECT * FROM system_schema.keyspaces;
```
##### Affichage sur un cluster Apache Cassandra : 
     keyspace_name       | durable_writes | replication
    ---------------------+----------------+-------------------------------------------------------------------------------------
             system_auth |           True | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '1'}
           system_schema |           True |                             {'class': 'org.apache.cassandra.locator.LocalStrategy'}
               formation |           True | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '3'}
      system_distributed |           True | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '3'}
                  system |           True |                             {'class': 'org.apache.cassandra.locator.LocalStrategy'}
           system_traces |           True | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '2'}
     entrepriseformation |           True | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '1'}
    
    (7 rows)

##### Affichage sur un cluster DSE : 
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
     
     (16 rows)


#### Interrogation de system_schema concernant une table précise : 
```sql
SELECT * FROM system_schema.tables WHERE keyspace_name = 'formation' AND table_name = 'formateurs';
```

##### Affichage : 
     keyspace_name | table_name | additional_write_policy | allow_auto_snapshot | bloom_filter_fp_chance | caching                                       | cdc  | comment | compaction                                                                                                                | compression                                                                             | crc_check_chance | dclocal_read_repair_chance | default_time_to_live | extensions | flags        | gc_grace_seconds | id                                   | incremental_backups | max_index_interval | memtable | memtable_flush_period_in_ms | min_index_interval | read_repair | read_repair_chance | speculative_retry
---------------+------------+-------------------------+---------------------+------------------------+-----------------------------------------------+------+---------+---------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------------------------------+------------------+----------------------------+----------------------+------------+--------------+------------------+--------------------------------------+---------------------+--------------------+----------+-----------------------------+--------------------+-------------+--------------------+-------------------
     formation | formateurs |                     99p |                null |                   0.01 | {'keys': 'ALL', 'rows_per_partition': 'NONE'} | null |         | {'class': 'org.apache.cassandra.db.compaction.SizeTieredCompactionStrategy', 'max_threshold': '32', 'min_threshold': '4'} | {'chunk_length_in_kb': '16', 'class': 'org.apache.cassandra.io.compress.LZ4Compressor'} |                1 |                          0 |                    0 |           {} | {'compound'} |           864000 | c44ffa10-164b-11f1-a651-a3342f18b42d |                null |               2048 |     null |                           0 |                128 |    BLOCKING |                  0 |               99p

    (1 rows)


##### Interrogation de schema_columns sur les colonnes d'une table : 

```sql
SELECT * FROM system_schema.columns WHERE keyspace_name = 'formation' AND table_name = 'formateurs';
```
##### Affichage : 

    ####  keyspace_name | table_name | column_name | clustering_order | column_name_bytes | kind          | position | required_for_liveness | type
     ---------------+------------+-------------+------------------+-------------------+---------------+----------+-----------------------+------
          formation | formateurs |       email |              asc |      0x656d61696c |    clustering |        1 |                 False | text
          formation | formateurs |          id |             none |            0x6964 | partition_key |        0 |                 False | uuid
          formation | formateurs |        name |              asc |        0x6e616d65 |    clustering |        0 |                 False | text
     
     (3 rows)
     


##### On sort du client shell cassandra CQLSH :
```sql
exit
```

_____________
#### Fin du TP02b : Interrogation avec CQLSH (suite)

_____________













