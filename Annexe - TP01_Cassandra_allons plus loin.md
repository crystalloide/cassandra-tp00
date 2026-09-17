# Cassandra : 
## Pour aller plus loin avec **5 exercices pratiques détaillés** et le fichier CSV de 200 films :

***

# Exercices pratiques détaillés

## Exercice 1 : Test des Niveaux de Cohérence

### Objectif

Comprendre l'impact des différents niveaux de cohérence (ONE, QUORUM, ALL) sur les performances et la disponibilité.

### Instructions

**Partie A : Insertion avec différents niveaux de cohérence**

```sql
-- Se connecter à cqlsh
docker exec -it cassandra01 cqlsh
```

```sql
-- Utiliser le keyspace formation
USE formation;

-- Test avec CONSISTENCY ONE
CONSISTENCY ONE;
INSERT INTO imdb (movie_id, title, year, genre, director, rating, votes, budget, length) 
VALUES (201, 'Test Movie ONE', 2024, 'Drama', 'Test Director', 8.0, 100000, 5000000, 120);

-- Vérifier l'insertion
SELECT * FROM imdb WHERE movie_id = 201;

-- Test avec CONSISTENCY QUORUM
CONSISTENCY QUORUM;
INSERT INTO imdb (movie_id, title, year, genre, director, rating, votes, budget, length) 
VALUES (202, 'Test Movie QUORUM', 2024, 'Action', 'Test Director', 8.1, 110000, 6000000, 125);

-- Activer le tracing pour voir la distribution
TRACING ON;
SELECT * FROM imdb WHERE movie_id = 202;
TRACING OFF;

-- Test avec CONSISTENCY ALL
CONSISTENCY ALL;
INSERT INTO imdb (movie_id, title, year, genre, director, rating, votes, budget, length) 
VALUES (203, 'Test Movie ALL', 2024, 'Sci-Fi', 'Test Director', 8.2, 120000, 7000000, 130);

TRACING ON;
SELECT * FROM imdb WHERE movie_id = 203;
TRACING OFF;
```

**Partie B : Impact de la cohérence avec un nœud arrêté**

```bash
# Dans un autre terminal, arrêter cassandra02
docker stop cassandra02

# Attendre 10 secondes
sleep 10

# Vérifier le statut du cluster
docker exec -it cassandra01 nodetool status
```

# Retourner dans cqlsh :

```sql
-- Test lecture avec CONSISTENCY ONE (devrait fonctionner)
CONSISTENCY ONE;
SELECT * FROM imdb WHERE movie_id = 1;

-- Test lecture avec CONSISTENCY QUORUM (devrait fonctionner - 2/3 nœuds disponibles)
CONSISTENCY QUORUM;
SELECT * FROM imdb WHERE movie_id = 1;

-- Test lecture avec CONSISTENCY ALL (devrait échouer)
CONSISTENCY ALL;
SELECT * FROM imdb WHERE movie_id = 1;
-- Erreur attendue: Unavailable exception

-- Redémarrer le nœud
```

```bash
docker start cassandra02
# Attendre 30 secondes pour que le nœud rejoigne le cluster
sleep 30
docker exec -it cassandra01 nodetool status
```

**Questions à répondre :**

1. Quel niveau de cohérence est le plus rapide ? Pourquoi ?
2. Quel niveau de cohérence offre la meilleure disponibilité ?
3. Avec 3 répliques et QUORUM, combien de nœuds peuvent tomber tout en maintenant la disponibilité ?

***

## Exercice 2 : Test de Tolérance aux Pannes

### Objectif

Tester la résilience du cluster Cassandra en simulant des pannes de nœuds.

### Instructions

**Scénario 1 : Panne d'un seul nœud**

```bash
# Terminal 1 : Surveiller le cluster
watch -n 2 'docker exec cassandra01 nodetool status'

# Terminal 2 : Arrêter cassandra03
docker stop cassandra03

# Attendre 30 secondes et observer le statut
```

Dans cqlsh :

```sql
CONSISTENCY QUORUM;

-- Insérer des données pendant la panne
INSERT INTO imdb (movie_id, title, year, genre, director, rating, votes, budget, length) 
VALUES (204, 'Resilience Test 1', 2024, 'Thriller', 'Test Director', 8.3, 130000, 8000000, 135);

-- Lire des données
SELECT * FROM imdb WHERE movie_id = 204;

-- Compter les films
SELECT COUNT(*) FROM imdb;
```

**Scénario 2 : Panne de deux nœuds**

```bash
# Arrêter cassandra04 également
docker stop cassandra04

# Observer le statut - 2 nœuds DOWN
```

Dans cqlsh :

```sql
-- Essayer avec CONSISTENCY ALL (devrait échouer - besoin des réponses des 4 nœuds sur 4)
CONSISTENCY ALL;
SELECT * FROM imdb WHERE movie_id = 1;
-- Erreur attendue avec RF=3

-- Passer à CONSISTENCY QUORUM (Note : c'est équivalent à "CONSISTENCY TWO" puisque RF=3) ) 
-- => résultat variable : ok ou ko :
-- les réponses de 2 noeuds sont nécessaires sur 3 noeuds au max (RF3) et 2 noeuds sur 4 sont indisponibles)
CONSISTENCY QUORUM;
SELECT * FROM imdb WHERE movie_id = 100;

-- => résultat variable : ok ou ko :
-- les réponses de 2 noeuds sont nécessaires sur 3 noeuds au max (RF3) et 2 noeuds sur 4 sont indisponibles)
INSERT INTO imdb (movie_id, title, year, genre, director, rating, votes, budget, length) 
VALUES (205, 'Resilience Test 2', 2024, 'Horror', 'Test Director', 8.4, 140000, 9000000, 140);
-- On change la valeur 205 -> 211 et cela peut fonctionner .. ou pas..
```

**Scénario 3 : Récupération après panne**

```bash
# Redémarrer les nœuds
docker start cassandra03
docker start cassandra04

# Attendre 60 secondes
sleep 60

# Vérifier le statut
docker exec -it cassandra01 nodetool status
```


# Vérifier que les données insérées pendant la panne sont présentes :

```SQL
CONSISTENCY ALL;
SELECT * FROM formation.imdb WHERE movie_id IN (204, 205) ALLOW FILTERING;
```

```bash
docker exec -it cassandra01 cqlsh -e "SELECT * FROM formation.imdb WHERE movie_id IN (204, 205) ALLOW FILTERING;"
```


**Commandes de diagnostic avancées :**

```bash
# Vérifier le service en charge de gérer les hints (= données en attente de synchronisation si un noeud a manqué des mises à jours)
docker exec -it cassandra01 nodetool statushandoff

# Forcer une réparation du keyspace
docker exec -it cassandra01 nodetool repair formation

# Vérifier les streams de données
docker exec -it cassandra01 nodetool netstats
```

**Questions à répondre :**

1. Avec RF=3 et QUORUM, combien de nœuds peuvent tomber simultanément ?
2. Que se passe-t-il avec les données insérées pendant qu'un nœud est DOWN ?
3. Comment Cassandra garantit-il la cohérence après la récupération ?

***

## Exercice 3 : Performance et Chargement en Masse

### Objectif

Charger 200 films, mesurer les performances et analyser la distribution des données.

### Instructions

**Partie A : Chargement des 200 films**

```bash
# On l'a déjà fait au TP précédent, mais si besoin on recharge le fichier CSV dans le conteneur cassandra01
docker cp imdb_movies.csv cassandra01:/tmp/

# Se connecter en cqlsh en passant par cassandra01 
docker exec -it cassandra01 cqlsh
```

# Dans cqlsh :

```sql
USE formation;

-- Mesurer le temps de chargement
-- Activer le tracing
TRACING ON;

-- Charger les 200 films
COPY formation.imdb (movie_id, title, year, genre, director, rating, votes, budget, length) 
FROM '/tmp/imdb_movies.csv' 
WITH HEADER = TRUE AND DELIMITER = ',';

-- Désactiver le tracing
TRACING OFF;

-- Vérifier le nombre de films chargés
SELECT COUNT(*) FROM imdb;

-- Résultat attendu : >200+

-- Afficher quelques films aléatoires
SELECT * FROM imdb LIMIT 20;
EXIT
```

**Partie B : Analyse de la distribution des données**

```bash
# Vérifier la charge de données sur chaque nœud
echo "=== Cassandra01 ==="
docker exec -it cassandra01 nodetool status formation

echo "=== Statistiques de la table imdb ==="
docker exec -it cassandra01 nodetool tablestats formation.imdb

echo "=== Distribution des tokens ==="
docker exec -it cassandra01 nodetool ring formation

# Vérifier la taille des données sur chaque nœud
docker exec -it cassandra01 bash 
cat /etc/cassandra/cassandra.yaml | grep /data
## Dans chaque noeud cassandra, les données sont donc stockées ici : /var/lib/cassandra/data
ls /var/lib/cassandra/data
## On ressort du conteneur cassandra01
exit 


docker exec -it cassandra04 ls /var/lib/cassandra/data/formation/
## Affichage en retour (exemple) : imdb-0baf8050090a11f1b49851578082683e

## On regarde la taille des données correspondantes au keyspace imdb et stockées sur les 4 noeuds : 
docker exec -it cassandra01 du -sh /var/lib/cassandra/data/formation/imdb-0baf8050090a11f1b49851578082683e
docker exec -it cassandra02 du -sh /var/lib/cassandra/data/formation/imdb-0baf8050090a11f1b49851578082683e
docker exec -it cassandra03 du -sh /var/lib/cassandra/data/formation/imdb-0baf8050090a11f1b49851578082683e
docker exec -it cassandra04 du -sh /var/lib/cassandra/data/formation/imdb-0baf8050090a11f1b49851578082683e

## Affichage en retour (exemple) :
## 276K    /var/lib/cassandra/data/formation/imdb-0baf8050090a11f1b49851578082683e
## 452K    /var/lib/cassandra/data/formation/imdb-0baf8050090a11f1b49851578082683e
## 452K    /var/lib/cassandra/data/formation/imdb-0baf8050090a11f1b49851578082683e
## 416K    /var/lib/cassandra/data/formation/imdb-0baf8050090a11f1b49851578082683e

docker exec -it cassandra01 nodetool status formation
## Affichage en retour (exemple) :
## Datacenter: dc1
## ===============
## Status=Up/Down
## |/ State=Normal/Leaving/Joining/Moving
## --  Address          Load        Tokens  Owns (effective)  Host ID                               Rack
## UN  192.168.100.151  258.79 KiB  16      74.7%             e2efa530-2ac0-4957-8827-60860279295b  Rack1
## UN  192.168.100.152  335.35 KiB  16      74.7%             955ae8dc-40f6-4c7c-a534-4f99af4af5de  Rack2
## UN  192.168.100.153  295.77 KiB  16      77.4%             21b3ae41-1e2a-4c7d-97d7-bcca250c85df  Rack3
## UN  192.168.100.154  297.19 KiB  16      73.2%             6747a2fb-3f5a-4342-91b5-1f1d177366af  Rack4

## On provoque un nettoyage : 
docker exec -it cassandra01 nodetool cleanup
docker exec -it cassandra02 nodetool cleanup
docker exec -it cassandra03 nodetool cleanup
docker exec -it cassandra04 nodetool cleanup

## Et on regarde le résultat :
docker exec -it cassandra01 nodetool status formation

## Affichage en retour (exemple) :
## Datacenter: dc1
## ===============
## Status=Up/Down
## |/ State=Normal/Leaving/Joining/Moving
## --  Address          Load        Tokens  Owns (effective)  Host ID                               Rack
## UN  192.168.100.151  258.79 KiB  16      74.7%             e2efa530-2ac0-4957-8827-60860279295b  Rack1
## UN  192.168.100.152  335.35 KiB  16      74.7%             955ae8dc-40f6-4c7c-a534-4f99af4af5de  Rack2
## UN  192.168.100.153  295.77 KiB  16      77.4%             21b3ae41-1e2a-4c7d-97d7-bcca250c85df  Rack3
## UN  192.168.100.154  297.19 KiB  16      73.2%             6747a2fb-3f5a-4342-91b5-1f1d177366af  Rack4
```

**Partie C : Tests de performance de lecture**

```sql
-- Test de lecture séquentielle
CONSISTENCY QUORUM;
TRACING ON;

-- Lecture par clé primaire (très rapide)
SELECT * FROM imdb WHERE movie_id = 50;
SELECT * FROM imdb WHERE movie_id = 100;
SELECT * FROM imdb WHERE movie_id = 150;

TRACING OFF;

-- Test de lecture avec index secondaire
CONSISTENCY ONE;
TRACING ON;

-- Recherche par année
SELECT title, year, rating FROM imdb WHERE year = 1994 ALLOW FILTERING;

-- Recherche par genre
SELECT title, genre, rating FROM imdb WHERE genre = 'Sci-Fi' ALLOW FILTERING;

TRACING OFF;
```

**Partie D : Benchmark d'insertion**

```sql
-- Créer une table de test pour le benchmark
CREATE TABLE IF NOT EXISTS benchmark_test (
  id INT PRIMARY KEY,
  data TEXT,
  timestamp TIMESTAMP
);

```

-- Script Python pour benchmark (à exécuter sur l'hôte)


```bash
# Créer un script Python pour tester les insertions
cat > benchmark_insert.py << 'EOF'
from cassandra.cluster import Cluster
from cassandra.policies import RoundRobinPolicy
import time

# Connexion au cluster
cluster = Cluster(['localhost'], port=9142, load_balancing_policy=RoundRobinPolicy())
session = cluster.connect('formation')

# Préparer la requête
insert_stmt = session.prepare("INSERT INTO benchmark_test (id, data, timestamp) VALUES (?, ?, toTimestamp(now()))")

# Benchmark : 1000 insertions
start_time = time.time()
for i in range(1000, 2000):
    session.execute(insert_stmt, (i, f"Test data {i}"))
end_time = time.time()

duration = end_time - start_time
throughput = 1000 / duration

print(f"Temps total: {duration:.2f} secondes")
print(f"Débit: {throughput:.2f} insertions/sec")

cluster.shutdown()
EOF

# Environnement virtuel Python + dépendances et enfin exécution du script :
pyenv activate cqlsh-env
pip3 install cassandra-driver
python3 benchmark_insert.py

## Affichage (exemple) : 
## Temps total: 3.89 secondes
## Débit: 256.92 insertions/sec

```

**Questions à répondre :**

1. Quelle est la différence de temps entre une lecture par clé primaire et une recherche avec ALLOW FILTERING ?
2. Comment les données sont-elles réparties entre les 4 nœuds ?
3. Quel est le débit d'insertion que vous avez mesuré ?

***

## Exercice 4 : Modélisation de Données Avancée - Table Acteurs

### Objectif

Créer une table pour gérer les acteurs avec une clé composite et explorer les requêtes avancées.

### Instructions

**Partie A : Création de la table acteurs**

```sql
USE formation;

-- Table avec clé composite : (movie_id, actor_name)
CREATE TABLE IF NOT EXISTS movie_actors (
  movie_id INT,
  actor_name TEXT,
  role TEXT,
  billing_order INT,
  PRIMARY KEY (movie_id, actor_name)
) WITH CLUSTERING ORDER BY (actor_name ASC);

DESCRIBE TABLE movie_actors;

-- Insertion de données pour plusieurs films
-- Film 1: The Shawshank Redemption
INSERT INTO movie_actors (movie_id, actor_name, role, billing_order) VALUES (1, 'Tim Robbins', 'Andy Dufresne', 1);
INSERT INTO movie_actors (movie_id, actor_name, role, billing_order) VALUES (1, 'Morgan Freeman', 'Ellis Boyd Redding', 2);
INSERT INTO movie_actors (movie_id, actor_name, role, billing_order) VALUES (1, 'Bob Gunton', 'Warden Norton', 3);

-- Film 2: The Godfather
INSERT INTO movie_actors (movie_id, actor_name, role, billing_order) VALUES (2, 'Marlon Brando', 'Vito Corleone', 1);
INSERT INTO movie_actors (movie_id, actor_name, role, billing_order) VALUES (2, 'Al Pacino', 'Michael Corleone', 2);
INSERT INTO movie_actors (movie_id, actor_name, role, billing_order) VALUES (2, 'James Caan', 'Sonny Corleone', 3);

-- Film 3: The Dark Knight
INSERT INTO movie_actors (movie_id, actor_name, role, billing_order) VALUES (3, 'Christian Bale', 'Bruce Wayne / Batman', 1);
INSERT INTO movie_actors (movie_id, actor_name, role, billing_order) VALUES (3, 'Heath Ledger', 'Joker', 2);
INSERT INTO movie_actors (movie_id, actor_name, role, billing_order) VALUES (3, 'Aaron Eckhart', 'Harvey Dent', 3);
INSERT INTO movie_actors (movie_id, actor_name, role, billing_order) VALUES (3, 'Michael Caine', 'Alfred', 4);
INSERT INTO movie_actors (movie_id, actor_name, role, billing_order) VALUES (3, 'Morgan Freeman', 'Lucius Fox', 5);

-- Film 6: Inception
INSERT INTO movie_actors (movie_id, actor_name, role, billing_order) VALUES (6, 'Leonardo DiCaprio', 'Dom Cobb', 1);
INSERT INTO movie_actors (movie_id, actor_name, role, billing_order) VALUES (6, 'Joseph Gordon-Levitt', 'Arthur', 2);
INSERT INTO movie_actors (movie_id, actor_name, role, billing_order) VALUES (6, 'Ellen Page', 'Ariadne', 3);
INSERT INTO movie_actors (movie_id, actor_name, role, billing_order) VALUES (6, 'Tom Hardy', 'Eames', 4);
INSERT INTO movie_actors (movie_id, actor_name, role, billing_order) VALUES (6, 'Michael Caine', 'Professor Miles', 5);

-- Film 10: Interstellar
INSERT INTO movie_actors (movie_id, actor_name, role, billing_order) VALUES (10, 'Matthew McConaughey', 'Cooper', 1);
INSERT INTO movie_actors (movie_id, actor_name, role, billing_order) VALUES (10, 'Anne Hathaway', 'Brand', 2);
INSERT INTO movie_actors (movie_id, actor_name, role, billing_order) VALUES (10, 'Jessica Chastain', 'Murph', 3);
INSERT INTO movie_actors (movie_id, actor_name, role, billing_order) VALUES (10, 'Michael Caine', 'Professor Brand', 4);
```

**Partie B : Requêtes avec clé composite**

```sql
-- Lister tous les acteurs d'un film (efficient - utilise la partition key)
SELECT * FROM movie_actors WHERE movie_id = 3;

-- Trouver un acteur spécifique dans un film (très efficient - clé complète)
SELECT * FROM movie_actors WHERE movie_id = 3 AND actor_name = 'Heath Ledger';

-- Lister les acteurs par ordre alphabétique pour un film
SELECT actor_name, role FROM movie_actors WHERE movie_id = 6;

-- Compter les acteurs d'un film
SELECT COUNT(*) FROM movie_actors WHERE movie_id = 3;
```

**Partie C : Table inversée pour rechercher par acteur**

```sql
-- Créer une table inversée pour trouver les films d'un acteur
CREATE TABLE IF NOT EXISTS actor_movies (
  actor_name TEXT,
  movie_id INT,
  title TEXT,
  role TEXT,
  year INT,
  PRIMARY KEY (actor_name, movie_id)
) WITH CLUSTERING ORDER BY (movie_id DESC);

-- Insérer les données (pattern de dénormalisation)
INSERT INTO actor_movies (actor_name, movie_id, title, role, year) 
VALUES ('Morgan Freeman', 1, 'The Shawshank Redemption', 'Ellis Boyd Redding', 1994);

INSERT INTO actor_movies (actor_name, movie_id, title, role, year) 
VALUES ('Morgan Freeman', 3, 'The Dark Knight', 'Lucius Fox', 2008);

INSERT INTO actor_movies (actor_name, movie_id, title, role, year) 
VALUES ('Michael Caine', 3, 'The Dark Knight', 'Alfred', 2008);

INSERT INTO actor_movies (actor_name, movie_id, title, role, year) 
VALUES ('Michael Caine', 6, 'Inception', 'Professor Miles', 2010);

INSERT INTO actor_movies (actor_name, movie_id, title, role, year) 
VALUES ('Michael Caine', 10, 'Interstellar', 'Professor Brand', 2014);

-- Trouver tous les films d'un acteur (efficient)
SELECT * FROM actor_movies WHERE actor_name = 'Morgan Freeman';
SELECT * FROM actor_movies WHERE actor_name = 'Michael Caine';

-- Compter les films d'un acteur
SELECT COUNT(*) FROM actor_movies WHERE actor_name = 'Michael Caine';
```

**Partie D : Jointure manuelle (simulation)**

```sql
-- Cassandra ne supporte pas les JOINs, il faut faire des requêtes séparées

-- 1. Trouver les acteurs d'un film
SELECT actor_name FROM movie_actors WHERE movie_id = 3;

-- 2. Pour chaque acteur, trouver ses autres films
SELECT title, year FROM actor_movies WHERE actor_name = 'Aaron Eckhart';
SELECT title, year FROM actor_movies WHERE actor_name = 'Christian Bale';
SELECT title, year FROM actor_movies WHERE actor_name = 'Heath Ledger';
SELECT title, year FROM actor_movies WHERE actor_name = 'Michael Caine';
SELECT title, year FROM actor_movies WHERE actor_name = 'Morgan Freeman';
```

**Partie E : Requêtes avancées avec collections**

```sql
-- Ajouter une colonne de type LIST pour les récompenses
ALTER TABLE movie_actors ADD awards LIST<TEXT>;

-- Mettre à jour avec des récompenses
UPDATE movie_actors SET awards = ['Oscar Best Actor', 'Golden Globe'] 
WHERE movie_id = 3 AND actor_name = 'Heath Ledger';

UPDATE movie_actors SET awards = ['BAFTA Best Actor', 'SAG Award'] 
WHERE movie_id = 1 AND actor_name = 'Morgan Freeman';

-- Lire les récompenses
SELECT actor_name, role, awards FROM movie_actors WHERE movie_id = 3;

-- Ajouter une récompense à la liste existante
UPDATE movie_actors SET awards = awards + ['Critics Choice Award'] 
WHERE movie_id = 3 AND actor_name = 'Heath Ledger';

SELECT actor_name, awards FROM movie_actors WHERE movie_id = 3 AND actor_name = 'Heath Ledger';
```

**Questions à répondre :**

1. Pourquoi avons-nous créé deux tables (movie_actors et actor_movies) ?
2. Quelle est la différence entre une partition key et une clustering key ?
3. Pourquoi Cassandra ne supporte-t-il pas les JOINs natifs ?

***

## Exercice 5 : Index Secondaires et Recherche Avancée

### Objectif

Explorer les index secondaires, comprendre leurs limitations et utiliser des stratégies de recherche alternatives.

### Instructions

**Partie A : Créer des index secondaires**

```sql
USE formation;

-- Vérifier les index existants
SELECT * FROM system_schema.indexes WHERE keyspace_name = 'formation';

-- Créer des index sur différentes colonnes
CREATE INDEX IF NOT EXISTS idx_year ON imdb(year);
CREATE INDEX IF NOT EXISTS idx_genre ON imdb(genre);
CREATE INDEX IF NOT EXISTS idx_director ON imdb(director);
CREATE INDEX IF NOT EXISTS idx_rating ON imdb(rating);

-- Vérifier que les index sont créés
SELECT * FROM system_schema.indexes WHERE keyspace_name = 'formation';

-- Attendre que les index soient construits (quelques secondes)
```

**Partie B : Requêtes avec index secondaires**

```sql
-- Recherche par année (utilise idx_year)
TRACING ON;
SELECT title, year, rating, director FROM imdb WHERE year = 1994 ALLOW FILTERING;
TRACING OFF;

-- Recherche par genre (utilise idx_genre)
TRACING ON;
SELECT title, genre, rating FROM imdb WHERE genre = 'Sci-Fi' ALLOW FILTERING;
TRACING OFF;

-- Recherche par réalisateur (utilise idx_director)
TRACING ON;
SELECT title, year, rating FROM imdb WHERE director = 'Christopher Nolan' ALLOW FILTERING;
TRACING OFF;

-- Recherche films avec rating élevé (utilise idx_rating)
SELECT title, rating, year FROM imdb WHERE rating >= 8.5 ALLOW FILTERING;

-- Recherche combinée (moins efficient)
SELECT title, year, rating FROM imdb 
WHERE year >= 2000 AND genre = 'Action' 
ALLOW FILTERING;
```

**Partie C : Analyser les performances des index**

```bash
# Vérifier les statistiques des index
docker exec -it cassandra01 nodetool tablestats formation.imdb

# Vérifier la construction des index
docker exec -it cassandra01 nodetool compactionstats

# Voir les métriques de performance
docker exec -it cassandra01 nodetool cfstats formation.imdb
```

**Partie D : Dépprécié : Vues matérialisées (alternative déconseillée aux index secondaires)**

## Je vous déconseille les vues matérialisées il faut actuiver un paramètre dans cassandra.yaml pour permettre ces usages :
```sql
-- Créer une vue matérialisée pour rechercher par genre
CREATE MATERIALIZED VIEW IF NOT EXISTS imdb_by_genre AS
  SELECT movie_id, title, year, genre, director, rating, votes
  FROM imdb
  WHERE genre IS NOT NULL AND movie_id IS NOT NULL
  PRIMARY KEY (genre, rating, movie_id)
  WITH CLUSTERING ORDER BY (rating DESC, movie_id ASC);

-- Attendre quelques secondes pour que la vue soit construite

-- Rechercher les meilleurs films Sci-Fi (très efficient)
SELECT title, rating, year FROM imdb_by_genre WHERE genre = 'Sci-Fi' LIMIT 10;

-- Rechercher les meilleurs films Drama
SELECT title, rating, year FROM imdb_by_genre WHERE genre = 'Drama' LIMIT 10;

-- Comparer avec l'index secondaire
TRACING ON;
SELECT title, rating, year FROM imdb WHERE genre = 'Sci-Fi' LIMIT 10 ALLOW FILTERING;
TRACING OFF;

TRACING ON;
SELECT title, rating, year FROM imdb_by_genre WHERE genre = 'Sci-Fi' LIMIT 10;
TRACING OFF;
```

**Partie E : Table de recherche dénormalisée**

```sql
-- Créer une table optimisée pour rechercher par année
CREATE TABLE IF NOT EXISTS imdb_by_year (
  year INT,
  movie_id INT,
  title TEXT,
  genre TEXT,
  director TEXT,
  rating DECIMAL,
  PRIMARY KEY (year, rating, movie_id)
) WITH CLUSTERING ORDER BY (rating DESC, movie_id ASC);

-- Copier les données (en production, utiliser Spark ou un batch)
-- Pour cet exercice, on insère manuellement quelques exemples
INSERT INTO imdb_by_year (year, movie_id, title, genre, director, rating) 
SELECT year, movie_id, title, genre, director, rating FROM imdb WHERE year = 1994 ALLOW FILTERING;

INSERT INTO imdb_by_year (year, movie_id, title, genre, director, rating) 
SELECT year, movie_id, title, genre, director, rating FROM imdb WHERE year = 2008 ALLOW FILTERING;

INSERT INTO imdb_by_year (year, movie_id, title, genre, director, rating) 
SELECT year, movie_id, title, genre, director, rating FROM imdb WHERE year = 2010 ALLOW FILTERING;

-- Rechercher les meilleurs films de 1994 (très efficient)
SELECT title, rating, genre FROM imdb_by_year WHERE year = 1994 LIMIT 10;

-- Rechercher les meilleurs films de 2008
SELECT title, rating, director FROM imdb_by_year WHERE year = 2008 LIMIT 5;
```

**Partie F : Statistiques et agrégations**

```sql
-- Compter les films par genre (nécessite de scanner toute la table)
SELECT genre, COUNT(*) as nb_films FROM imdb GROUP BY genre ALLOW FILTERING;
## Erreur en retour : 
## InvalidRequest: Error from server: code=2200 [Invalid query] 
## message="Group by is currently only supported on the columns of the PRIMARY KEY, got genre"

-- Films par décennie
SELECT title, year FROM imdb WHERE year >= 1990 AND year < 2000 ALLOW FILTERING;
SELECT title, year FROM imdb WHERE year >= 2000 AND year < 2010 ALLOW FILTERING;
SELECT title, year FROM imdb WHERE year >= 2010 AND year < 2020 ALLOW FILTERING;

-- Top 20 des films les mieux notés
SELECT title, rating, year, director FROM imdb WHERE rating >= 8.5 LIMIT 20 ALLOW FILTERING;
```

**Partie G : Nettoyage et optimisation**

```bash
# Vérifier la fragmentation (nombre de SSTables)
docker exec -it cassandra01 nodetool tablestats formation

# Compacter manuellement pour optimiser
docker exec -it cassandra01 nodetool compact formation imdb

# Reconstruire les index
docker exec -it cassandra01 nodetool rebuild_index formation imdb idx_genre

# Vérifier l'utilisation du disque
docker exec -it cassandra01 nodetool status formation
```

**Questions à répondre :**

1. Quelle est la différence entre un index secondaire et une vue matérialisée ?
2. Pourquoi ALLOW FILTERING est-il nécessaire dans certaines requêtes ?
3. Dans quel cas préférer une table dénormalisée à un index secondaire ?
4. Quel est l'impact des vues matérialisées sur les performances d'écriture ?

***

## Exercice Bonus : Monitoring et JMX

### Objectif

Explorer les outils de monitoring et les métriques JMX de Cassandra.

### Instructions

```bash
# Connexion JMX aux nœuds (ports exposés: 7199, 7299, 7399, 7499)

# Utiliser VisualVM : https://visualvm.github.io/

 
# Alternative : 
# Installer JMXTerm pour interagir avec JMX
wget https://github.com/jiaqi/jmxterm/releases/download/v1.0.4/jmxterm-1.0.4-uber.jar

# Se connecter à cassandra01 via JMX
java -jar jmxterm-1.0.4-uber.jar -l 192.168.100.151:7199

# Ou depuis l'hôte
java -jar jmxterm-1.0.4-uber.jar -l localhost:7199
```

Commandes JMX à tester :

```
# Lister les domaines
domains

# Naviguer vers org.apache.cassandra.metrics
domain org.apache.cassandra.metrics

# Lister les beans disponibles
beans

# Voir les latences de lecture
# On utilise -a pour spécifier l'attribut
get -b org.apache.cassandra.metrics:type=ClientRequest,scope=Read,name=Latency Count

# Ou avec -a explicitement
get -a Count -b org.apache.cassandra.metrics:type=ClientRequest,scope=Read,name=Latency


# Voir les métriques de compaction
bean org.apache.cassandra.metrics:type=Compaction,name=PendingTasks
get Value

exit 

```

#### Métriques utiles via nodetool :

# Statistiques globales
docker exec -it cassandra01 nodetool info

# Statistiques de compaction
docker exec -it cassandra01 nodetool compactionstats

# Statistiques de gossip
docker exec -it cassandra01 nodetool gossipinfo

# Statistiques de performances (Thread Pool)
docker exec -it cassandra01 nodetool tpstats

# Statistiques de table
docker exec -it cassandra01 nodetool tablestats formation.imdb

# Informations générales du nœud
docker exec -it cassandra01 nodetool info

# Statistiques de proxyhistograms (latences read/write/range)
docker exec -it cassandra01 nodetool proxyhistograms

# Statistiques du cache
docker exec -it cassandra01 nodetool info | grep -i cache

## Métriques importantes à surveiller :

# Latences de lecture/écriture
docker exec -it cassandra01 nodetool proxyhistograms

# Compactions en cours
docker exec -it cassandra01 nodetool compactionstats

# Charge de chaque nœud
docker exec -it cassandra01 nodetool status

# Statistiques détaillées d'un keyspace
docker exec -it cassandra01 nodetool tablestats -- formation



***

## Résumé des Commandes Importantes

```bash
# Démarrage/arrêt du cluster
docker compose up -d
docker compose down
docker compose restart

# Logs
docker compose logs -f cassandra01

# Status du cluster
docker exec -it cassandra01 nodetool status

# Accès cqlsh
docker exec -it cassandra01 cqlsh

# Copier des fichiers
docker cp fichier.csv cassandra01:/tmp/

# Réparation du cluster
docker exec -it cassandra01 nodetool repair formation

# Statistiques
docker exec -it cassandra01 nodetool tablestats formation.imdb
docker exec -it cassandra01 nodetool ring
docker exec -it cassandra01 nodetool info
```


***

Bon travail ! Ces exercices vous permettront de maîtriser les concepts avancés de Cassandra : cohérence, tolérance aux pannes, modélisation de données, et optimisation des performances. 🚀

<div align="center">⁂</div>


