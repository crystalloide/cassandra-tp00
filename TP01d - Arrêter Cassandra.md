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

#####
```bash
docker exec -it cassandra01 nodetool status
```

##### Pour un déploiement DataStax (DSE), on aurait fait  : 
    docker exec -it cassandra01 dsetool status

_____________________________________

###### Pour arrêter Cassandra :
###### Maintenant que Cassandra est lancé,  on peut vouloir l'arrêter :-) 

###### Une commande "stop-server" est présente dans le répertoire "bin"

###### Si on lance cette commande sur linux : 
docker exec -it cassandra01 ./stop-server

###### Affichage en retour : 
###### veuillez lire le script d'arrêt du serveur avant utilisation

###### Le serveur n'a pas été arrêté, et on nous invite à lire le script. 
###### En regardant à l'intérieur avec son éditeur de code préféré, 
###### Il apparaît que la façon d'arrêter Cassandra est de "killer" le process JVM qui exécute Cassandra. 
###### Le script suggère plusieurs techniques différentes pour identifier le process JVM et pouvoir le killer : 

###### La première technique consiste à démarrer Cassandra à l'aide de l'option "-p", 
###### qui fournit à Cassandra le nom d'un fichier dans lequel sera écrit l'identifiant de processus (PID) au démarrage. 
###### C'est sans doute l'approche la plus fiable pour s'assurer de killer le bon processus.

###### Cependant, si, comme dans notre cas, on n'a pas démarré Cassandra avec l'option "-p", il faut retrouver le processus. 
## Il est suggérer d'utiliser "pgrep" pour localiser les processus de l'utilisateur actuel contenant le terme « cassandra » :

utilisateur=`whoami`
pgrep -u $user -f cassandra | xargs kill −9

###### Et voilà :-)

_____________________________________

###### Remarque : 
###### Pour arrêter un cassandra DSE : 
docker exec -it cassandra01 dse cassandra-stop

_____________________________________


#####################################################################################################################
## FIN DU TP01f 

#####################################################################################################################




