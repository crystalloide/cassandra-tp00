#####  Savoir arrêter Cassandra
_____________________________________
#####  Les lignes préfixées par # sont des commentaires et à ne pas exécuter     
_____________________________________

##### 1°) Sur un lancement précédent, échoué ou non, si on veut repartir de "0" : 
```bash
cd ~/cassandra-tp00
docker compose -f docker-compose.yml down -v
sleep 30
```


###### Pour éviter tout lien/interférence avec un lancement précédent :  on supprime les répertoires C* persistés en local
###### (à faire pour de la formation uniquement !!!)
```bash
cd ~/cassandra-tp00
sudo rm -Rf docker/cassanda*
mkdir -p docker/cassandra01 docker/cassandra02 docker/cassandra03 docker/cassandra04
```

###### Puis on démarrer le cluster en arrière-plan :
```bash
docker compose -f docker-compose.yml up  -d
```

##### On vérifie quand le cluster est bien lancé : 
```bash
docker exec -it cassandra01 nodetool status
```

##### Pour un déploiement DataStax (DSE), on aurait fait  : 
###### docker exec -it cassandra01 dsetool status

    Datacenter: dc1
    ===============
    Status=Up/Down
    |/ State=Normal/Leaving/Joining/Moving
    --  Address          Load       Tokens  Owns (effective)  Host ID                               Rack
    UN  192.168.100.154  38.77 MiB  16      73.2%             3a11e986-d24f-46f3-83b2-bc0632ac5991  Rack4
    UN  192.168.100.151  39.5 MiB   16      74.7%             13473850-0ed8-4adb-9cc3-923efb56ecd9  Rack1
    UN  192.168.100.152  39.62 MiB  16      74.7%             67895141-9db1-467c-8c15-b0e57fe4fa72  Rack2
    UN  192.168.100.153  40.84 MiB  16      77.4%             2c0c4b8e-f221-4db2-9ead-4eb9030539cc  Rack3
    
_____________________________________

##### Pour arrêter Cassandra :
_____________________________________

###### Maintenant que Cassandra est lancé,  on peut vouloir l'arrêter :-) 

###### Une commande "stop-server" est présente dans le répertoire "bin" : /opt/cassandra/bin

###### Si on lance cette commande sur linux : 
```bash
docker exec -it cassandra01 stop-server
```
#### Commande équivalente à :
```bash
docker exec -it cassandra01 ./opt/cassandra/bin/stop-server
```
###### Affichage en retour : 
    Usage: /opt/cassandra/bin/stop-server [-p <pidfile>] | [-l] | [-e] | [-h]
    -p <pidfile>    Stop the process using the specified pidfile
    -l              Stop the process with the name like 'cassandra'
    -e              Stop the process with the name equal 'CassandraDaemon'
    -h              Show the help message

###### Le serveur n'a pas été arrêté, et on nous invite à lire le script. 
###### Le script suggère plusieurs techniques différentes pour arrêter C* : 
    La première technique consiste à démarrer Cassandra à l'aide de l'option "-p", 
    qui fournit à Cassandra le nom d'un fichier dans lequel sera écrit l'identifiant de processus (PID) au démarrage. 
    C'est sans doute l'approche la plus fiable pour s'assurer de killer le bon processus.

###### Si on veut retrouver le processus de cassandra sans connaître l Pid "p" :  
###### Il est possible d'utiliser "pgrep" pour localiser les processus de l'utilisateur actuel contenant le terme « cassandra » :
```bash
docker exec -it cassandra01 bash
```
```bash
user=`whoami`
ps aux | grep cassandra
```
##### Vous devriez voir quelque chose comme :
```
cassand+  1234  ... java -Dcassandra ...
```
###### On supposera ici que cassandra tourne sous le user "cassandra" : 
```bash
pgrep -u cassandra -f cassandra | xargs kill -9
```
```bash
exit
```
###### Notre cas est un peu particulier car on tourne sous docker, 
###### La bonne façon est donc d'agir sur le contenur lui-même, de l'extérieur : 

```bash
docker stop cassandra01
```

##### Avec l'option **-l** :
```bash
docker exec -it cassandra02 bash
```
```bash
/opt/cassandra/bin/stop-server -l
```
```bash
exit
```

##### Avec l'option **-e** :
```bash
docker exec -it cassandra03 bash
```
```bash
/opt/cassandra/bin/stop-server -e
```
```bash
exit
```

##### Avec l'option **-h** : affiche l'aide : 
```bash
docker exec -it cassandra04 bash
```
```bash
/opt/cassandra/bin/stop-server -h
```
```bash
exit
```


###### Et voilà :-)

_____________________________________

###### Remarque : 
###### Pour arrêter un cassandra DSE : 
docker exec -it cassandra01 dse cassandra-stop

_____________________________________


#####################################################################################################################
## FIN DU TP01f 

#####################################################################################################################



























