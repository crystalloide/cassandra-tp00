# TP18 - Sécuriser un cluster Apache Cassandra 5.0 (4 nœuds, 2 datacenters, Docker Compose)

| | |
|---|---|
| **Version ciblée** | Apache Cassandra 5.0.x (image officielle `cassandra:5.0`) |
| **Point de départ** | Cluster 4 nœuds / 2 DC lancé avec `Cluster_4_noeuds_2_racks_2_DC.yml` |
| **Durée indicative** | 3 h 30 à 4 h (dont ~45 min de redémarrages progressifs) |
| **Niveau** | Administrateur Cassandra (bases CQL, `nodetool`, Docker Compose) |

---

## Objectifs pédagogiques

À l'issue de ce lab, vous saurez :

1. répliquer correctement le keyspace `system_auth` dans un cluster multi-datacenter, et comprendre les niveaux de cohérence utilisés par l'authentification ;
2. activer l'**authentification** par mot de passe sans interruption de service, puis neutraliser le compte par défaut `cassandra` ;
3. mettre en place un modèle d'**autorisations** par rôles (RBAC), restreindre un compte à un datacenter et **masquer** des colonnes sensibles (nouveauté 5.0) ;
4. activer la **journalisation d'audit** et l'exploiter ;
5. chiffrer en **TLS** les connexions clients (port 9042) puis inter-nœuds (port 7000, en TLS mutuel), en trois étapes sans coupure ;
6. sécuriser **JMX / nodetool** avec les rôles Cassandra, et durcir le fichier Docker Compose ;
7. contrôler l'ensemble avec un script de vérification.

## Prérequis

- Linux (ou WSL2) avec Docker Engine et le plugin `docker compose`, `sudo`, `python3` et environ 5 Go de RAM libres.
- Accès Internet pour tirer les images `cassandra:5.0` et `nicolaka/netshoot` (utilisée pour les captures réseau).
- Le fichier `Cluster_4_noeuds_2_racks_2_DC.yml` dans le dossier de travail (appelé **dossier du TP** ci-dessous). **Toutes les commandes se lancent depuis ce dossier.**

## Architecture de départ

| Conteneur | IP | Datacenter | Rack | CQL publié sur l'hôte | Seed |
|---|---|---|---|---|---|
| `cassandra01` | 192.168.100.151 | `Nord` | `Winterfell` | 9142 | oui |
| `cassandra02` | 192.168.100.152 | `Terres-de-la-Couronne` | `Port-Real` | 9242 | oui |
| `cassandra03` | 192.168.100.153 | `Nord` | `Winterfell` | 9342 | non |
| `cassandra04` | 192.168.100.154 | `Terres-de-la-Couronne` | `Port-Real` | 9442 | non |

Deux datacenters de **2 nœuds chacun**. Le répertoire de configuration de chaque nœud (`/etc/cassandra`, atteint par le lien `/opt/cassandra/conf`) est monté depuis `docker/cassandra0X-conf` : **on modifie donc `cassandra.yaml` directement sur l'hôte**, puis on redémarre le nœud.

> ℹ️ Ces fichiers appartiennent à l'UID 999 (utilisateur `cassandra` du conteneur) : leur modification sur l'hôte demande `sudo`.

## Feuille de route

| Partie | Couche de sécurité | Modification | Redémarrage |
|---|---|---|---|
| 0 | État des lieux | — | — |
| 1 | Réplication de `system_auth` | CQL + `nodetool repair` | aucun |
| 2 | Authentification | `authenticator` | progressif (rolling) |
| 3 | Autorisations, restriction par DC, masquage | `authorizer`, `network_authorizer`, `dynamic_data_masking_enabled` | progressif |
| 4 | Audit | `nodetool enableauditlog` | aucun |
| 5 | Chiffrement TLS client + inter-nœuds | `client_encryption_options`, `server_encryption_options` | 3 × progressif |
| 6 | JMX / nodetool + Compose durci | fichier Compose | progressif (recréation) |
| 7 | Contrôle final | script | — |

## Comptes et secrets du TP

| Compte / secret | Valeur de TP | Usage |
|---|---|---|
| `cassandra` | `cassandra` → neutralisé en partie 2 | superutilisateur par défaut |
| `dba_westeros` | `Dba-Westeros@2026` | superutilisateur nominatif |
| `app_winterfell` | `App-Winterfell@2026` | compte applicatif (lecture/écriture, DC `Nord` uniquement) |
| `analyste_mestre` | `Mestre-Citadelle@2026` | compte de lecture seule |
| `supervision` | `Supervision@2026` | JMX en lecture (partie 6) |
| Keystores / truststore / CA | `Westeros-KS-2026` / `Westeros-TS-2026` / `Westeros-CA-2026` | TLS (partie 5) |

> ⚠️ Ces valeurs sont **pédagogiques**. En dehors du TP, utilisez des secrets générés (`openssl rand -base64 24`) et stockés dans un coffre-fort.

---

## Partie 0 — Démarrage et état des lieux

### 0.1 Préparer le dossier du TP

```bash
mkdir -p docker/cassandra0{1..4} docker/cassandra0{1..4}-conf outils fragments certs client
chmod 700 client certs

# Recommandé : figer la version de l'image. « latest » pointe aujourd'hui sur 5.0.x
# mais basculera sur 6.0 à sa sortie, ce qui casserait le TP.
sed -i 's#cassandra:latest#cassandra:5.0#' Cluster_4_noeuds_2_racks_2_DC.yml
grep -n "image:" Cluster_4_noeuds_2_racks_2_DC.yml
```

### 0.2 Démarrer le cluster

```bash
docker compose -f Cluster_4_noeuds_2_racks_2_DC.yml up -d
# Les nœuds démarrent l'un après l'autre (depends_on + healthcheck) : comptez 5 à 8 minutes.
docker exec cassandra01 nodetool status
docker exec cassandra01 nodetool version
```

Résultat attendu : 4 lignes `UN` réparties dans `Datacenter: Nord` et `Datacenter: Terres-de-la-Couronne`, et une version `5.0.x`.

### 0.3 Créer le jeu de données

```bash
docker exec -it cassandra01 cqlsh
```

```cqlsh
CREATE KEYSPACE IF NOT EXISTS westeros
  WITH replication = {'class': 'NetworkTopologyStrategy', 'Nord': 2, 'Terres-de-la-Couronne': 2};

CREATE TABLE IF NOT EXISTS westeros.personnages (
  maison    text,
  nom       text,
  titre     text,
  email     text,
  telephone text,
  PRIMARY KEY ((maison), nom));

CREATE TABLE IF NOT EXISTS westeros.corbeaux (
  id          timeuuid PRIMARY KEY,
  expediteur  text,
  message     text);

INSERT INTO westeros.personnages (maison, nom, titre, email, telephone) VALUES ('Stark', 'Jon Snow', 'Lord Commandant', 'jon@winterfell.north', '06 00 00 00 01');
INSERT INTO westeros.personnages (maison, nom, titre, email, telephone) VALUES ('Stark', 'Arya Stark', 'Personne', 'arya@winterfell.north', '06 00 00 00 02');
INSERT INTO westeros.personnages (maison, nom, titre, email, telephone) VALUES ('Lannister', 'Cersei Lannister', 'Reine', 'cersei@portreal.crown', '06 00 00 00 03');
INSERT INTO westeros.personnages (maison, nom, titre, email, telephone) VALUES ('Lannister', 'Tyrion Lannister', 'Main du Roi', 'tyrion@portreal.crown', '06 00 00 00 04');
INSERT INTO westeros.personnages (maison, nom, titre, email, telephone) VALUES ('Targaryen', 'Daenerys Targaryen', 'Mère des dragons', 'dany@dragonstone.sea', '06 00 00 00 05');
```

```cqlsh
EXIT;
```

### 0.4 État des lieux : tout est ouvert

Exécutez les contrôles suivants et notez les résultats : vous les comparerez à ceux de la partie 7.

```bash
# a) Connexion CQL anonyme : aucune identification demandée
docker exec cassandra01 cqlsh -e "SELECT nom, email, telephone FROM westeros.personnages"

# b) Administration JMX à distance SANS mot de passe (LOCAL_JMX=no + authenticate=false) :
#    n'importe quel conteneur du réseau peut piloter cassandra01...
docker exec cassandra02 nodetool -h 192.168.100.151 status
#    ... y compris l'arrêter (NE PAS exécuter) : nodetool -h 192.168.100.151 stopdaemon

# c) Keyspace des comptes : SimpleStrategy, RF = 1 → un seul nœud détient les comptes
docker exec cassandra01 cqlsh -e "DESCRIBE KEYSPACE system_auth" | head -3

# d) Paramètres de sécurité effectifs (table virtuelle system_views.settings)
docker exec cassandra01 cqlsh -e "SELECT name, value FROM system_views.settings" \
  | grep -E "authenticator|authorizer|encryption_options\.(enabled|internode_encryption|optional)"

# e) Trafic inter-nœuds en clair
docker logs cassandra01 2>&1 | grep -E "Listening on|messaging connection established" | tail -3

# f) Ports publiés sur TOUTES les interfaces de l'hôte (0.0.0.0), dont 7000 (inter-nœuds) et 7199 (JMX)
docker port cassandra01
```

| Constat | Risque | Corrigé en |
|---|---|---|
| CQL sans authentification (`AllowAllAuthenticator`) | lecture/écriture/suppression par n'importe qui | partie 2 |
| Aucune autorisation (`AllowAllAuthorizer`) | pas de moindre privilège | partie 3 |
| `system_auth` en RF 1 / SimpleStrategy | perte d'un nœud = plus aucune connexion possible | partie 1 |
| Aucune trace des accès | pas d'imputabilité | partie 4 |
| CQL et inter-nœuds en clair (`unencrypted`) | mots de passe et données lisibles sur le réseau | partie 5 |
| JMX distant sans mot de passe, ports publiés en `0.0.0.0` | prise de contrôle / arrêt des nœuds | partie 6 |

### 0.5 Installer les outils du TP

**`outils/rolling_restart.sh`** redémarre les nœuds un par un et attend que chacun ait fini de démarrer avant de passer au suivant :

```bash
cat > outils/rolling_restart.sh <<'EOF'
#!/usr/bin/env bash
# rolling_restart.sh — redémarre les nœuds UN PAR UN, sans interruption de service.
#
#   ./outils/rolling_restart.sh                       # les 4 nœuds, via « docker restart »
#   ./outils/rolling_restart.sh cassandra02           # un seul nœud
#   COMPOSE_FICHIER=Cluster_4_noeuds_2_racks_2_DC_securise.yml ./outils/rolling_restart.sh
#                                                     # recrée les conteneurs (nouvelle config compose)
#
# Un nœud est considéré prêt quand « Startup complete » apparaît dans SES logs depuis
# le redémarrage (on n'utilise pas le healthcheck : après un « docker restart », l'ancien
# system.log contient déjà cette ligne et le conteneur passe « healthy » trop tôt).
set -euo pipefail
[ $# -eq 0 ] && set -- cassandra01 cassandra02 cassandra03 cassandra04
DELAI_MAX=600        # secondes max d'attente par nœud
PAUSE_GOSSIP=20      # laisse le temps au gossip de propager l'état UP

for n in "$@"; do
  depuis=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  if [ -n "${COMPOSE_FICHIER:-}" ]; then
    echo "=== $(date +%T) recréation de $n ($COMPOSE_FICHIER)"
    docker compose -f "$COMPOSE_FICHIER" up -d --no-deps --force-recreate "$n"
  else
    echo "=== $(date +%T) redémarrage de $n"
    docker restart -t 120 "$n" >/dev/null   # SIGTERM -> Cassandra draine proprement (120 s max)
  fi
  attente=0
  until docker logs --since "$depuis" "$n" 2>&1 | grep -q "Startup complete"; do
    sleep 5; attente=$((attente + 5))
    if [ "$attente" -ge "$DELAI_MAX" ]; then
      echo "!!! $n n'a pas démarré en ${DELAI_MAX}s — dernières erreurs :"
      docker logs --since "$depuis" "$n" 2>&1 | grep -E "ERROR|Exception" | tail -20
      exit 1
    fi
  done
  echo "    $n prêt en ${attente}s ; erreurs éventuelles au démarrage :"
  docker logs --since "$depuis" "$n" 2>&1 | grep -E "^ERROR|ERROR \[" | tail -5 || true
  sleep "$PAUSE_GOSSIP"
done
echo "=== $(date +%T) terminé — vérifiez : docker exec cassandra01 nodetool status  (après la partie 6 : nodetool -u ... -pwf ...)"
EOF
chmod +x outils/rolling_restart.sh
```

**`outils/yaml_bloc.py`** remplace un bloc de premier niveau de `cassandra.yaml` (par exemple tout `client_encryption_options:`) par le contenu d'un fichier fragment, sans toucher au reste du fichier (commentaires compris) et en gardant une sauvegarde `.bak` :

```bash
cat > outils/yaml_bloc.py <<'EOF'
#!/usr/bin/env python3
"""yaml_bloc.py — remplace un bloc de 1er niveau d'un cassandra.yaml, sans toucher au reste.

Usage : sudo python3 yaml_bloc.py <cassandra.yaml> <fragment.yaml>

Le fragment commence par la clé de 1er niveau (ex. « client_encryption_options: »).
Le bloc existant (de cette clé jusqu'à la clé de 1er niveau suivante) est remplacé ;
les commentaires d'en-tête de la section suivante sont conservés.
Une copie de sauvegarde <cassandra.yaml>.bak est créée.
"""
import re, shutil, sys

def main(cible, fragment):
    bloc = open(fragment, encoding="utf-8").read().rstrip("\n").splitlines()
    m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):", bloc[0])
    if not m:
        sys.exit(f"{fragment} : la 1re ligne doit être une clé de 1er niveau")
    cle = m.group(1)
    lignes = open(cible, encoding="utf-8").read().splitlines()
    debut = next((i for i, l in enumerate(lignes) if re.match(rf"^{cle}:", l)), None)
    if debut is None:
        sys.exit(f"{cible} : clé « {cle}: » introuvable")
    fin = next((i for i in range(debut + 1, len(lignes))
                if re.match(r"^[A-Za-z_]", lignes[i])), len(lignes))
    # on rend à la section suivante ses commentaires d'en-tête (colonne 0) et lignes vides
    while fin - 1 > debut and (lignes[fin - 1].startswith("#") or not lignes[fin - 1].strip()):
        fin -= 1
    shutil.copy2(cible, cible + ".bak")
    nouveau = lignes[:debut] + bloc + lignes[fin:]
    with open(cible, "w", encoding="utf-8") as f:   # réécriture en place (préserve propriétaire/droits)
        f.write("\n".join(nouveau) + "\n")
    print(f"{cible} : bloc « {cle} » remplacé ({fin - debut} lignes -> {len(bloc)} lignes)")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
EOF
chmod +x outils/yaml_bloc.py
```

> 💡 Pourquoi un redémarrage **progressif** ? Tant qu'au moins un réplica de chaque donnée reste disponible, le cluster continue de servir les clients pendant qu'on reconfigure les nœuds un par un. Avec RF = 2 par DC et un seul nœud arrêté à la fois, un client en `LOCAL_ONE` n'est jamais interrompu.

---

## Partie 1 — Répliquer `system_auth` *avant* d'activer l'authentification

Les rôles, mots de passe (hachés en bcrypt) et permissions sont stockés dans le keyspace `system_auth`. Par défaut : `SimpleStrategy`, **RF = 1**. Si l'unique nœud qui porte un rôle tombe, plus personne ne peut se connecter avec ce rôle.

On corrige **avant** d'activer l'authentification : ainsi, le rôle par défaut `cassandra` et les comptes créés ensuite sont immédiatement répliqués.

```bash
docker exec -i cassandra01 cqlsh <<'EOF'
ALTER KEYSPACE system_auth
  WITH replication = {'class': 'NetworkTopologyStrategy', 'Nord': 2, 'Terres-de-la-Couronne': 2};
-- Recommandé aussi pour les autres keyspaces système répliqués d'un cluster multi-DC :
ALTER KEYSPACE system_distributed
  WITH replication = {'class': 'NetworkTopologyStrategy', 'Nord': 2, 'Terres-de-la-Couronne': 2};
ALTER KEYSPACE system_traces
  WITH replication = {'class': 'NetworkTopologyStrategy', 'Nord': 2, 'Terres-de-la-Couronne': 2};
DESCRIBE KEYSPACE system_auth;
EOF

# Propager les données existantes vers les nouveaux réplicas.
# Depuis Cassandra 4.0, « nodetool repair » est INCRÉMENTAL par défaut : on force une réparation complète.
for n in cassandra01 cassandra02 cassandra03 cassandra04; do
  echo "== $n"; docker exec "$n" nodetool repair --full system_auth
done
```

**Points de cours**

- Les noms de DC dans la map de réplication doivent être **exactement** ceux de `nodetool status` (casse et tirets compris). Le `'dc1': 3, 'dc2': 2` des anciens supports n'est qu'un exemple.
- Le RF d'un DC ne peut pas dépasser le nombre de nœuds de ce DC : ici, **2 au maximum**. En production, visez **3 nœuds et RF 3 par DC**.
- Niveaux de cohérence utilisés par l'authentification en **Cassandra 5.0** :

| Opération | Niveau de cohérence | Conséquence ici (RF 2 par DC) |
|---|---|---|
| Connexion avec le rôle `cassandra` | `QUORUM` (global) | 3 réplicas sur 4 doivent répondre |
| Connexion avec tout autre rôle | `LOCAL_QUORUM` (`auth_read_consistency_level`) | les **2** nœuds du DC local doivent répondre |
| `CREATE/ALTER/DROP ROLE`, `GRANT`, `REVOKE` | `EACH_QUORUM` (`auth_write_consistency_level`) | les **4** nœuds doivent être disponibles |

> ⚠️ Correction d'une idée reçue (présente dans d'anciens supports) : « les autres utilisateurs s'authentifient en `LOCAL_ONE` ». C'était vrai jusqu'en 4.0. Depuis 4.1, c'est `LOCAL_QUORUM` par défaut, réglable dans `cassandra.yaml`. Vous en mesurerez l'effet en partie 3.5.

---

## Partie 2 — Authentification (`PasswordAuthenticator`)

### 2.1 Modifier la configuration des 4 nœuds

```bash
sudo sed -i -E 's/^authenticator:.*/authenticator: PasswordAuthenticator/' \
  docker/cassandra0{1..4}-conf/cassandra.yaml
sudo grep -H "^authenticator:" docker/cassandra0{1..4}-conf/cassandra.yaml
```

> `role_manager: CassandraRoleManager` est déjà la valeur par défaut : c'est lui qui stocke les rôles dans `system_auth`.

### 2.2 Redémarrer les nœuds un par un

```bash
./outils/rolling_restart.sh
docker exec cassandra01 nodetool status
```

Pendant le redémarrage, le cluster est **mixte** : les nœuds déjà redémarrés exigent un mot de passe, les autres acceptent encore les connexions anonymes. Cette fenêtre doit rester courte.

Au premier démarrage d'un nœud avec `PasswordAuthenticator`, Cassandra crée le rôle par défaut `cassandra` / `cassandra` (après ~10 s) **s'il n'existe encore aucun rôle**.

### 2.3 Vérifier que l'accès anonyme est refusé

```bash
docker exec cassandra01 cqlsh -e "SELECT * FROM westeros.personnages"
```

Attendu : `Connection error: ... AuthenticationFailed('Remote end requires authentication')`.

### 2.4 Créer un superutilisateur nominatif

```bash
docker exec -it cassandra01 cqlsh -u cassandra -p cassandra
```

```sql
CREATE ROLE dba_westeros WITH PASSWORD = 'Dba-Westeros@2026' AND SUPERUSER = true AND LOGIN = true;
LIST ROLES;
EXIT;
```

> Le warning `Using a password on the command line interface can be insecure` est normal : on le supprimera en 2.6.

### 2.5 Neutraliser le compte `cassandra`

Générez sur l'hôte un mot de passe aléatoire, que vous ne conserverez pas :

```bash
openssl rand -base64 24
```

Connectez-vous avec le **nouveau** superutilisateur :

```bash
docker exec -it cassandra01 cqlsh -u dba_westeros -p 'Dba-Westeros@2026'
```

```sql
ALTER ROLE cassandra WITH PASSWORD = '<collez ici le mot de passe aléatoire>'
  AND SUPERUSER = false AND LOGIN = false;

-- Les mots de passe ne sont jamais stockés en clair : hachage bcrypt ($2a$10$...)
SELECT role, is_superuser, can_login, salted_hash FROM system_auth.roles;
EXIT;
```

```bash
docker exec cassandra01 cqlsh -u cassandra -p cassandra -e "SELECT now() FROM system.local"
```

Attendu : échec de l'authentification.

> Contrairement à ce qu'affirment d'anciens supports, le rôle `cassandra` **peut être supprimé** (`DROP ROLE cassandra;`) par un autre superutilisateur ; il n'est pas recréé au redémarrage tant qu'il existe au moins un rôle. Le neutraliser (`LOGIN = false`, `SUPERUSER = false`) garde toutefois une trace et suffit.

### 2.6 Ne plus taper de mot de passe : le fichier `credentials`

```bash
cat > client/credentials <<'EOF'
[PlainTextAuthProvider]
username = dba_westeros
password = Dba-Westeros@2026
EOF
chmod 600 client/credentials

for n in cassandra01 cassandra02 cassandra03 cassandra04; do
  docker exec "$n" mkdir -p /root/.cassandra
  docker cp client/credentials "$n":/root/.cassandra/credentials
done

docker exec -it cassandra01 cqlsh        # l'invite devient : dba_westeros@cqlsh>
```

**Mini-exercice** : rendez le fichier lisible par tous et observez la réaction de `cqlsh`.

```bash
docker exec cassandra01 chmod 644 /root/.cassandra/credentials
docker exec cassandra01 cqlsh -e "SELECT now() FROM system.local"   # le fichier est ignoré → refus
docker exec cassandra01 chmod 600 /root/.cassandra/credentials
```

> ⚠️ `cqlsh` enregistre les commandes dans `~/.cassandra/cqlsh_history`, **y compris les `CREATE ROLE ... PASSWORD`**. Sur un poste partagé, utilisez `cqlsh --disable-history` pour ces opérations.

### 2.7 Caches d'authentification

Chaque nœud met en cache les rôles, permissions et identifiants (sous forme hachée) pour éviter une lecture de `system_auth` à chaque requête.

```bash
docker exec cassandra01 cqlsh -e "SELECT name, value FROM system_views.settings" \
  | grep -E "^ *(roles|permissions|credentials)_(validity|update_interval)|auth_(read|write)_consistency"
```

| Paramètre 5.0 (ancien nom, déprécié) | Défaut | Rôle |
|---|---|---|
| `roles_validity` (`roles_validity_in_ms`) | `2000ms` | durée de vie d'une entrée du cache des rôles |
| `roles_update_interval` (`roles_update_interval_in_ms`) | = validity | rafraîchissement asynchrone |
| `permissions_validity` / `permissions_update_interval` | `2000ms` | idem pour les permissions |
| `credentials_validity` / `credentials_update_interval` | `2000ms` | idem pour les identifiants |

- Augmenter ces valeurs réduit la charge sur `system_auth`, mais **retarde l'effet** d'un `REVOKE` ou d'un changement de mot de passe.
- Vider un cache immédiatement : `nodetool invalidatecredentialscache`, `invalidaterolescache`, `invalidatepermissionscache`, `invalidatenetworkpermissionscache`.
- Depuis la 4.1, les paramètres s'écrivent avec leur unité (`2000ms`, `1h`) : les noms `*_in_ms` sont encore acceptés en 5.0, mais dépréciés.

---
## Partie 3 — Autorisations, restriction par datacenter et masquage des données

Avec l'authentification seule, **tout compte connecté a tous les droits**. On active maintenant trois mécanismes :

- `CassandraAuthorizer` : permissions `GRANT`/`REVOKE` stockées dans `system_auth.role_permissions` ;
- `CassandraNetworkAuthorizer` : restreint un rôle à certains datacenters ;
- `dynamic_data_masking_enabled` (nouveauté 5.0) : masquage de colonnes à la lecture.

### 3.1 Activer les trois mécanismes

```bash
sudo sed -i -E \
  -e 's/^authorizer:.*/authorizer: CassandraAuthorizer/' \
  -e 's/^network_authorizer:.*/network_authorizer: CassandraNetworkAuthorizer/' \
  -e 's/^#? ?dynamic_data_masking_enabled:.*/dynamic_data_masking_enabled: true/' \
  docker/cassandra0{1..4}-conf/cassandra.yaml
sudo grep -HE "^(authenticator|authorizer|network_authorizer|dynamic_data_masking_enabled):" \
  docker/cassandra0{1..4}-conf/cassandra.yaml

./outils/rolling_restart.sh
```

> 💡 On active l'autorisation **avant** de créer les comptes applicatifs. Dans l'ordre inverse, un compte non-superutilisateur aurait tous les droits sur les nœuds encore en `AllowAllAuthorizer` pendant la transition.

### 3.2 Modèle de rôles

On attribue les permissions à des **rôles fonctionnels** (sans `LOGIN`), puis ces rôles aux **comptes de connexion**. Pour changer les droits d'une population, on modifie un seul rôle.

```
r_westeros_lecture  ──(SELECT sur westeros)
        ▲ hérité par
r_westeros_ecriture ──(+ MODIFY sur westeros)
        ▲                               ▲
  app_winterfell (DC Nord uniquement)   │
                                        │
  analyste_mestre ──────────────► r_westeros_lecture
```

```bash
docker exec -i cassandra01 cqlsh <<'EOF'
-- Rôles fonctionnels (non connectables)
CREATE ROLE IF NOT EXISTS r_westeros_lecture;
CREATE ROLE IF NOT EXISTS r_westeros_ecriture;
GRANT SELECT ON KEYSPACE westeros TO r_westeros_lecture;
GRANT r_westeros_lecture TO r_westeros_ecriture;          -- héritage de rôle
GRANT MODIFY ON KEYSPACE westeros TO r_westeros_ecriture; -- INSERT / UPDATE / DELETE / TRUNCATE

-- Comptes de connexion
CREATE ROLE IF NOT EXISTS app_winterfell WITH PASSWORD = 'App-Winterfell@2026'
  AND LOGIN = true AND ACCESS TO DATACENTERS {'Nord'};
CREATE ROLE IF NOT EXISTS analyste_mestre WITH PASSWORD = 'Mestre-Citadelle@2026'
  AND LOGIN = true;
GRANT r_westeros_ecriture TO app_winterfell;
GRANT r_westeros_lecture  TO analyste_mestre;

LIST ROLES;
LIST ROLES OF app_winterfell;
LIST ALL PERMISSIONS OF app_winterfell;   -- inclut les permissions héritées
EOF
```

> Ces écritures dans `system_auth` se font en `EACH_QUORUM` : les 4 nœuds doivent être `UN`.

### 3.3 Tester les permissions

```bash
AN="cqlsh -u analyste_mestre -p Mestre-Citadelle@2026"
APP="cqlsh -u app_winterfell -p App-Winterfell@2026"
# (ces deux variables resservent en parties 4 et 5 : redéfinissez-les si vous changez de terminal)

# a) L'analyste lit...
docker exec cassandra01 $AN -e "SELECT nom, titre FROM westeros.personnages"
# ... mais ne peut pas écrire (attendu : Unauthorized ... has no MODIFY permission)
docker exec cassandra01 $AN -e "INSERT INTO westeros.corbeaux (id, expediteur, message) VALUES (now(), 'Sam', 'test')"
# ... ni lire la table des comptes (attendu : Unauthorized)
docker exec cassandra01 $AN -e "SELECT role, salted_hash FROM system_auth.roles"

# b) L'application écrit via un nœud du DC Nord
docker exec cassandra01 $APP -e "INSERT INTO westeros.corbeaux (id, expediteur, message) VALUES (now(), 'Jon', 'L hiver arrive')"
docker exec cassandra03 $APP -e "SELECT count(*) FROM westeros.corbeaux"

# c) ... mais se voit refuser un nœud de l'autre DC
#    (attendu : You do not have access to this datacenter (Terres-de-la-Couronne))
docker exec cassandra02 $APP -e "SELECT count(*) FROM westeros.corbeaux"
```

Le contrôle de datacenter porte sur le **nœud coordinateur** auquel le client se connecte. Les superutilisateurs ne sont jamais restreints.

**Révocation et effet du cache :**

```bash
docker exec cassandra01 cqlsh -e "REVOKE MODIFY ON KEYSPACE westeros FROM r_westeros_ecriture"
sleep 3   # > permissions_validity (2 s)
docker exec cassandra01 $APP -e "INSERT INTO westeros.corbeaux (id, expediteur, message) VALUES (now(), 'Jon', 'refusé ?')"
docker exec cassandra01 cqlsh -e "GRANT MODIFY ON KEYSPACE westeros TO r_westeros_ecriture"
```

La révocation porte sur le rôle fonctionnel : **tous** les comptes qui en héritent perdent le droit en même temps.

> 💡 **Délégation.** Pour qu'un compte non-superutilisateur puisse lui-même accorder `SELECT` sur `westeros`, il lui faut `AUTHORIZE` sur ce keyspace **et** la permission `SELECT` elle-même. Évitez `GRANT ALL PERMISSIONS` : il inclut `AUTHORIZE`, `DROP` et `ALTER`.

### 3.4 Masquage dynamique des données (DDM, Cassandra 5.0)

Le masquage est appliqué **à la lecture**, selon les permissions de l'utilisateur. Les données restent stockées en clair.

```bash
docker exec -i cassandra01 cqlsh <<'EOF'
ALTER TABLE westeros.personnages ALTER email     MASKED WITH mask_inner(1, null);
ALTER TABLE westeros.personnages ALTER telephone MASKED WITH mask_default();
DESCRIBE TABLE westeros.personnages;
EOF

# Superutilisateur : UNMASK implicite → valeurs en clair
docker exec cassandra01 cqlsh -e "SELECT nom, email, telephone FROM westeros.personnages WHERE maison = 'Stark'"
# Analyste : valeurs masquées (email « j*** », téléphone « **** »)
docker exec cassandra01 $AN -e "SELECT nom, email, telephone FROM westeros.personnages WHERE maison = 'Stark'"
# Filtrer sur une colonne masquée exige UNMASK ou SELECT_MASKED → refusé (évite la recherche par force brute)
docker exec cassandra01 $AN -e "SELECT nom FROM westeros.personnages WHERE maison = 'Stark' AND email = 'jon@winterfell.north' ALLOW FILTERING"

# L'application a besoin des vraies valeurs : UNMASK sur le rôle fonctionnel
docker exec cassandra01 cqlsh -e "GRANT UNMASK ON TABLE westeros.personnages TO r_westeros_ecriture"
docker exec cassandra01 $APP -e "SELECT nom, email, telephone FROM westeros.personnages WHERE maison = 'Stark'"
```

| Fonction | Effet (colonne `text`) |
|---|---|
| `mask_null()` | renvoie `null` |
| `mask_default()` | valeur fixe du type (`****` pour du texte, `0` pour un nombre) |
| `mask_replace('XXX')` | remplace par la valeur fournie |
| `mask_inner(debut, fin)` | masque le milieu, laisse `debut` caractères au début et `fin` à la fin |
| `mask_outer(debut, fin)` | masque le début et la fin |

> ⚠️ Le masquage n'est **pas** du chiffrement : les SSTables, les sauvegardes et le trafic réseau contiennent les valeurs en clair. C'est une protection contre l'exposition accidentelle, à combiner avec le chiffrement réseau (partie 5) et la protection des disques.

### 3.5 Exercice — panne d'un nœud et authentification

Mesurez l'effet du `LOCAL_QUORUM` vu en partie 1 avec seulement 2 nœuds par DC.

```bash
docker stop cassandra03                      # le DC Nord n'a plus qu'un nœud
docker exec cassandra01 nodetool invalidatecredentialscache
docker exec cassandra01 nodetool invalidaterolescache

# 1) Connexion de l'analyste via cassandra01 (DC Nord)
docker exec cassandra01 $AN -e "SELECT count(*) FROM westeros.personnages"
# 2) Même compte via cassandra02 (DC Terres-de-la-Couronne, 2 nœuds sur 2 disponibles)
docker exec cassandra02 $AN -e "SELECT count(*) FROM westeros.personnages"
# 3) Même le superutilisateur dba_westeros, via cassandra01
docker exec cassandra01 cqlsh -e "SELECT count(*) FROM westeros.personnages"

docker start cassandra03
```

**Questions**

1. Pourquoi (1) et (3) échouent-ils alors que la requête elle-même (lue en `ONE`) aurait pu aboutir ?
2. Pourquoi (2) réussit-il ?
3. Quelles solutions envisager ?

<details>
<summary>Éléments de réponse</summary>

1. La **lecture du mot de passe** dans `system_auth` se fait en `LOCAL_QUORUM`, soit 2 réplicas sur 2 dans le DC Nord : un seul est disponible. Seul le rôle `cassandra` utilise `QUORUM`, et il est désactivé.
2. Dans le DC `Terres-de-la-Couronne`, les deux réplicas locaux répondent.
3. En production : **3 nœuds par DC et RF 3** pour `system_auth`, ce qui tolère une panne. Dans un petit cluster, on peut accepter `auth_read_consistency_level: LOCAL_ONE` dans `cassandra.yaml`, en sachant qu'un réplica en retard peut alors renvoyer un mot de passe ou un droit périmé. Le cache des identifiants ne protège que pendant `credentials_validity`.
</details>

Attendez que `cassandra03` soit revenu (`docker exec cassandra01 nodetool status` → 4 × `UN`) avant de continuer.

---

## Partie 4 — Journalisation d'audit

L'audit trace les connexions (réussies et échouées) et les requêtes CQL, **sur le nœud coordinateur** de chaque requête.

### 4.1 Activer l'audit à chaud

```bash
for n in cassandra01 cassandra02 cassandra03 cassandra04; do
  docker exec "$n" nodetool enableauditlog --included-categories AUTH,DCL,DDL,ERROR
done
docker exec cassandra01 nodetool getauditlog
```

| Catégorie | Contenu |
|---|---|
| `AUTH` | connexions réussies/échouées, tentatives non autorisées |
| `DCL` | `CREATE/ALTER/DROP ROLE`, `GRANT`, `REVOKE` |
| `DDL` | `CREATE/ALTER/DROP` de keyspaces, tables… |
| `DML` / `QUERY` | écritures / lectures (volumineux : à cibler avec `--included-keyspaces`) |
| `ERROR`, `PREPARE`, `OTHER` | erreurs, préparations, divers |

### 4.2 Générer des événements

```bash
docker exec cassandra01 cqlsh -u analyste_mestre -p mauvais_mdp -e "SELECT now() FROM system.local"   # échec de connexion
docker exec cassandra01 $AN -e "DELETE FROM westeros.corbeaux WHERE id = 50554d6e-29bb-11e5-b345-feff819cdc9f"  # tentative non autorisée
docker exec cassandra01 cqlsh -e "CREATE ROLE espion WITH PASSWORD = 'Varys-2026' AND LOGIN = true"     # DCL
docker exec cassandra01 cqlsh -e "GRANT SELECT ON TABLE westeros.corbeaux TO espion"                     # DCL
docker exec cassandra01 cqlsh -e "CREATE TABLE westeros.registre (id int PRIMARY KEY, note text)"       # DDL
```

### 4.3 Lire le journal

Le journal est binaire (Chronicle Queue). On le lit avec `auditlogviewer`, lancé sous l'utilisateur `cassandra` avec un petit tas pour ménager la mémoire du conteneur (1 Go) :

```bash
docker exec -u cassandra -e MAX_HEAP_SIZE=64M cassandra01 \
  /opt/cassandra/tools/bin/auditlogviewer /var/log/cassandra/audit
```

Repérez :

- `type:LOGIN_ERROR` pour `analyste_mestre` : adresse source, port, horodatage ;
- `type:UNAUTHORIZED_ATTEMPT` pour le `DELETE` ;
- `type:CREATE_ROLE` : le mot de passe est **masqué** (`*******`) dans le journal ;
- `type:GRANT` et `type:CREATE_TABLE`.

> Chaque nœud n'enregistre que les requêtes qu'il a **coordonnées**. Pour une vision globale, collectez les journaux des 4 nœuds (archivage via `archive_command`, puis centralisation).

### 4.4 Rendre l'audit permanent

`nodetool enableauditlog` ne survit pas à un redémarrage. La configuration permanente se fait dans `cassandra.yaml` ; elle sera appliquée au prochain redémarrage progressif (partie 5, étape 1). Préparez le fragment :

```bash
cat > fragments/audit.yaml <<'EOF'
audit_logging_options:
  enabled: true
  logger:
    - class_name: BinAuditLogger
  audit_logs_dir: /var/lib/cassandra/audit
  included_categories: AUTH,DCL,DDL,ERROR
  excluded_keyspaces: system,system_schema,system_virtual_schema
  roll_cycle: HOURLY
  block: true
  max_log_size: 1073741824           # 1 Gio max sur disque
EOF
```

> Le répertoire `/var/lib/cassandra/audit` est dans le volume de données monté depuis l'hôte (`docker/cassandra0X/audit`) : il **survit à la recréation** des conteneurs, contrairement à `/var/log/cassandra`.
>
> Alternative texte : `FileAuditLogger` écrit dans `audit/audit.log` via Logback. Il faut alors décommenter l'appender `AUDIT` dans `logback.xml`.

Nettoyez le rôle de test :

```bash
docker exec cassandra01 cqlsh -e "DROP ROLE espion; DROP TABLE westeros.registre;"
```

---
## Partie 5 — Chiffrement TLS (clients et inter-nœuds)

### 5.1 Constater le trafic en clair

Ouvrez **deux terminaux** dans le dossier du TP.

**Mot de passe CQL visible sur le réseau** (le mécanisme SASL PLAIN transmet `\0utilisateur\0motdepasse`) :

```bash
# Terminal A — capture sur l'interface de cassandra01, port 9042 (Ctrl+C pour arrêter)
docker run --rm --cap-add NET_ADMIN --cap-add NET_RAW --net container:cassandra01 nicolaka/netshoot \
  tcpdump -i eth0 -l -A -s0 'tcp port 9042' | grep --line-buffered -a -E "analyste|Mestre"

# Terminal B — connexion depuis cassandra03 vers cassandra01
docker exec cassandra03 cqlsh 192.168.100.151 -u analyste_mestre -p 'Mestre-Citadelle@2026' \
  -e "SELECT nom, titre FROM westeros.personnages"
```

Attendu dans le terminal A : une ligne du type `....analyste_mestre.Mestre-Citadelle@2026`.

**Données visibles entre nœuds** (port 7000). À l'intérieur d'un même DC, les messages ne sont pas compressés (`internode_compression: dc`) : ils passent en clair.

```bash
# Terminal A
docker run --rm --cap-add NET_ADMIN --cap-add NET_RAW --net container:cassandra01 nicolaka/netshoot \
  tcpdump -i eth0 -l -A -s0 'tcp port 7000' | grep --line-buffered -a "CORBEAU"

# Terminal B — cassandra01 coordonne l'écriture et l'envoie à cassandra03 (même DC)
docker exec cassandra01 cqlsh -e "CONSISTENCY ALL; INSERT INTO westeros.corbeaux (id, expediteur, message) VALUES (now(), 'Varys', 'CORBEAU-SECRET : le roi est mort');"
```

### 5.2 Construire la PKI du TP

Une **autorité de certification (CA)** de TP signe un certificat par nœud. Chaque nœud fait confiance à la CA, et non à chaque certificat individuellement : ajouter un nœud ne demande donc pas de modifier les autres.

| Fichier | Contenu | Destination |
|---|---|---|
| `ca.p12` | clé privée + certificat de la CA | **reste sur le poste d'administration** (idéalement hors ligne) |
| `ca.crt` | certificat public de la CA (PEM) | clients (`cqlsh`, pilotes) |
| `truststore.p12` | certificat de la CA | tous les nœuds |
| `cassandra0X-keystore.p12` | clé privée + certificat du nœud (SAN = nom + IP) | le nœud concerné uniquement |

```bash
cat > certs/gen-certs.sh <<'EOF'
#!/usr/bin/env bash
# gen-certs.sh — PKI de TP : 1 CA + 1 keystore par nœud + 1 truststore commun
set -euo pipefail
cd "$(dirname "$0")"

CA_PASS="${CA_PASS:-Westeros-CA-2026}"      # protège la clé privée de la CA
KS_PASS="${KS_PASS:-Westeros-KS-2026}"      # keystores des nœuds
TS_PASS="${TS_PASS:-Westeros-TS-2026}"      # truststore commun
VALIDITE=825                                # jours

declare -A NOEUDS=( [cassandra01]=192.168.100.151 [cassandra02]=192.168.100.152
                    [cassandra03]=192.168.100.153 [cassandra04]=192.168.100.154 )

rm -f ./*.p12 ./*.crt ./*.csr

# 1. Autorité de certification (CA) auto-signée
keytool -genkeypair -alias ca -keyalg RSA -keysize 3072 -validity 3650 \
  -dname "CN=Formation Cassandra CA, O=Formation, C=FR" \
  -ext bc:c -ext ku:c=keyCertSign,cRLSign \
  -keystore ca.p12 -storetype PKCS12 -storepass "$CA_PASS"
keytool -exportcert -rfc -alias ca -keystore ca.p12 -storepass "$CA_PASS" -file ca.crt

# 2. Truststore commun : ne contient QUE le certificat public de la CA
keytool -importcert -noprompt -alias ca -file ca.crt \
  -keystore truststore.p12 -storetype PKCS12 -storepass "$TS_PASS"

# 3. Un keystore par nœud : clé privée + certificat signé par la CA
for n in $(printf '%s\n' "${!NOEUDS[@]}" | sort); do
  ip="${NOEUDS[$n]}"
  san="dns:$n,dns:localhost,ip:$ip,ip:127.0.0.1"
  keytool -genkeypair -alias "$n" -keyalg RSA -keysize 2048 -validity "$VALIDITE" \
    -dname "CN=$n, OU=Cassandra, O=Formation, C=FR" -ext "SAN=$san" \
    -keystore "$n-keystore.p12" -storetype PKCS12 -storepass "$KS_PASS"
  keytool -certreq -alias "$n" -keystore "$n-keystore.p12" -storepass "$KS_PASS" -file "$n.csr"
  keytool -gencert -alias ca -keystore ca.p12 -storepass "$CA_PASS" -rfc \
    -infile "$n.csr" -outfile "$n.crt" -validity "$VALIDITE" -ext "SAN=$san" \
    -ext ku:c=digitalSignature,keyEncipherment -ext eku=serverAuth,clientAuth
  keytool -importcert -noprompt -alias ca -file ca.crt -keystore "$n-keystore.p12" -storepass "$KS_PASS"
  keytool -importcert -noprompt -alias "$n" -file "$n.crt" -keystore "$n-keystore.p12" -storepass "$KS_PASS"
  echo ">>> $n : certificat émis pour $san"
done
rm -f ./*.csr
ls -l
EOF
chmod +x certs/gen-certs.sh

# keytool est fourni par l'image Cassandra : aucun outil à installer sur l'hôte
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD/certs:/certs" --entrypoint bash \
  cassandra:5.0 /certs/gen-certs.sh
chmod 600 certs/*.p12
```

Contrôle (si `openssl` est présent sur l'hôte) :

```bash
openssl verify -CAfile certs/ca.crt certs/cassandra0*.crt
openssl x509 -in certs/cassandra01.crt -noout -subject -issuer -ext subjectAltName,extendedKeyUsage
```

Déployer les magasins sur chaque nœud, sans jamais copier `ca.p12` :

```bash
for i in 1 2 3 4; do
  d=docker/cassandra0$i-conf/certs
  sudo mkdir -p "$d"
  sudo cp certs/cassandra0$i-keystore.p12 "$d/keystore.p12"
  sudo cp certs/truststore.p12 "$d/truststore.p12"
  sudo chmod 600 "$d/keystore.p12" "$d/truststore.p12"
  sudo chown -R 999:999 "$d" && sudo chmod 700 "$d"
done
cp certs/ca.crt client/ca.crt
```

> Les mots de passe des magasins figurent en clair dans `cassandra.yaml`. Restreignez l'accès aux répertoires de configuration sur l'hôte (`sudo chmod 700 docker/cassandra0*-conf`).
> Un certificat renouvelé est rechargé à chaud : Cassandra contrôle les fichiers keystore/truststore toutes les 10 minutes, à mot de passe inchangé.

### 5.3 Stratégie de migration sans coupure

Si l'on passait directement en « TLS obligatoire », un nœud redémarré ne pourrait plus parler aux nœuds pas encore reconfigurés. On procède donc en **trois redémarrages progressifs** :

| Étape | Clients (9042) | Inter-nœuds (7000) émis | Inter-nœuds acceptés |
|---|---|---|---|
| 1 | clair **ou** TLS (`optional: true`) | clair (`internode_encryption: none`) | clair **ou** TLS (`optional: true`) |
| 2 | **TLS uniquement** | **TLS mutuel** (`all`, `require_client_auth`) | clair ou TLS |
| 3 | TLS uniquement | TLS mutuel | **TLS uniquement** (`optional: false`) |

Créez les fragments de configuration :

```bash
cat > fragments/tls-etape1-client.yaml <<'EOF'
client_encryption_options:
  enabled: true
  optional: true                     # transition : clair ET TLS acceptés sur 9042
  keystore: /etc/cassandra/certs/keystore.p12
  keystore_password: "Westeros-KS-2026"
  store_type: PKCS12
  require_client_auth: false         # les clients ne présentent pas de certificat
  accepted_protocols: [TLSv1.3, TLSv1.2]
EOF

cat > fragments/tls-etape1-server.yaml <<'EOF'
server_encryption_options:
  internode_encryption: none         # on n'émet pas encore en TLS...
  optional: true                     # ...mais on ACCEPTE déjà le TLS entrant sur 7000
  legacy_ssl_storage_port_enabled: false
  keystore: /etc/cassandra/certs/keystore.p12
  keystore_password: "Westeros-KS-2026"
  truststore: /etc/cassandra/certs/truststore.p12
  truststore_password: "Westeros-TS-2026"
  store_type: PKCS12
  require_client_auth: false
  require_endpoint_verification: false
  accepted_protocols: [TLSv1.3, TLSv1.2]
EOF

cat > fragments/tls-etape2-client.yaml <<'EOF'
client_encryption_options:
  enabled: true
  optional: false                    # TLS OBLIGATOIRE pour les clients CQL
  keystore: /etc/cassandra/certs/keystore.p12
  keystore_password: "Westeros-KS-2026"
  store_type: PKCS12
  require_client_auth: false
  accepted_protocols: [TLSv1.3, TLSv1.2]
EOF

cat > fragments/tls-etape2-server.yaml <<'EOF'
server_encryption_options:
  internode_encryption: all          # on émet désormais en TLS vers tous les pairs
  optional: true                     # on accepte encore le clair des nœuds non redémarrés
  legacy_ssl_storage_port_enabled: false
  keystore: /etc/cassandra/certs/keystore.p12
  keystore_password: "Westeros-KS-2026"
  truststore: /etc/cassandra/certs/truststore.p12
  truststore_password: "Westeros-TS-2026"
  store_type: PKCS12
  require_client_auth: true          # mTLS : le pair doit présenter un certificat signé par la CA
  require_endpoint_verification: true   # le certificat doit correspondre à l'IP du pair (SAN)
  accepted_protocols: [TLSv1.3, TLSv1.2]
EOF

cat > fragments/tls-etape3-server.yaml <<'EOF'
server_encryption_options:
  internode_encryption: all          # on émet désormais en TLS vers tous les pairs
  optional: false                    # plus AUCUNE connexion inter-nœuds en clair
  legacy_ssl_storage_port_enabled: false
  keystore: /etc/cassandra/certs/keystore.p12
  keystore_password: "Westeros-KS-2026"
  truststore: /etc/cassandra/certs/truststore.p12
  truststore_password: "Westeros-TS-2026"
  store_type: PKCS12
  require_client_auth: true          # mTLS : le pair doit présenter un certificat signé par la CA
  require_endpoint_verification: true   # le certificat doit correspondre à l'IP du pair (SAN)
  accepted_protocols: [TLSv1.3, TLSv1.2]
EOF
```

Les chemins `/etc/cassandra/certs/...` sont identiques sur tous les nœuds, puisque chaque nœud a son propre répertoire de configuration. Les fragments sont donc les mêmes partout.

### 5.4 Étape 1 — TLS accepté (optionnel) et audit permanent

```bash
for i in 1 2 3 4; do
  for f in audit tls-etape1-client tls-etape1-server; do
    sudo python3 outils/yaml_bloc.py docker/cassandra0$i-conf/cassandra.yaml fragments/$f.yaml
  done
done
./outils/rolling_restart.sh
```

Configurer `cqlsh` pour TLS (certificat de la CA, validation du certificat serveur) :

```bash
cat > client/cqlshrc <<'EOF'
[ssl]
certfile = /root/.cassandra/ca.crt
validate = true
EOF
for n in cassandra01 cassandra02 cassandra03 cassandra04; do
  docker cp client/cqlshrc "$n":/root/.cassandra/cqlshrc
  docker cp client/ca.crt  "$n":/root/.cassandra/ca.crt
done
```

Vérifications :

```bash
docker exec cassandra01 cqlsh -e "SELECT now() FROM system.local"          # en clair : encore accepté
docker exec -it cassandra01 cqlsh --ssl                                     # en TLS
```

```sql
SELECT address, port, username, ssl_enabled, ssl_protocol FROM system_views.clients;
EXIT;
```

```bash
docker logs cassandra01 2>&1 | grep "Listening on" | tail -1             # encryption: optionally encrypted(...)
docker exec cassandra01 nodetool getauditlog | head -4                    # audit_logs_dir = /var/lib/cassandra/audit
```

### 5.5 Étape 2 — TLS obligatoire pour les clients, TLS mutuel émis entre nœuds

```bash
for i in 1 2 3 4; do
  for f in tls-etape2-client tls-etape2-server; do
    sudo python3 outils/yaml_bloc.py docker/cassandra0$i-conf/cassandra.yaml fragments/$f.yaml
  done
done
./outils/rolling_restart.sh
```

`cqlsh` doit désormais toujours utiliser TLS :

```bash
cat > client/cqlshrc <<'EOF'
[connection]
ssl = true

[ssl]
certfile = /root/.cassandra/ca.crt
validate = true
EOF
for n in cassandra01 cassandra02 cassandra03 cassandra04; do docker cp client/cqlshrc "$n":/root/.cassandra/cqlshrc; done

docker exec -e HOME=/tmp cassandra01 cqlsh -u dba_westeros -p 'Dba-Westeros@2026' \
  -e "SELECT now() FROM system.local"                                                 # sans TLS : refusé
docker exec cassandra01 cqlsh -e "SELECT now() FROM system.local"                    # TLS : OK
docker logs cassandra01 2>&1 | grep "messaging connection established" | tail -4     # encryption = encrypted(...;protocol=TLSv1.3;...)
```

> `HOME=/tmp` fait croire à `cqlsh` qu'il n'a ni `cqlshrc` ni `credentials` : c'est une manière simple de tester un client « nu ».

### 5.6 Étape 3 — plus aucune connexion inter-nœuds en clair

```bash
for i in 1 2 3 4; do
  sudo python3 outils/yaml_bloc.py docker/cassandra0$i-conf/cassandra.yaml fragments/tls-etape3-server.yaml
done
./outils/rolling_restart.sh
docker exec cassandra01 nodetool status
docker logs cassandra01 2>&1 | grep "Listening on" | tail -1        # encryption: encrypted(...)
```

**Refaites les deux captures de la partie 5.1.** Pour le port 9042, il faut maintenant `--ssl` côté client. Le mot de passe comme le message `CORBEAU` n'apparaissent plus :

```bash
docker exec cassandra03 cqlsh 192.168.100.151 --ssl -u analyste_mestre -p 'Mestre-Citadelle@2026' \
  -e "SELECT nom FROM westeros.personnages"
```

**TLS mutuel** : un poste qui ne présente pas de certificat signé par la CA est rejeté sur le port 7000. Il voit le certificat du nœud, mais la poignée de main échoue :

```bash
docker run --rm --net container:cassandra02 nicolaka/netshoot sh -c \
  'openssl s_client -connect 192.168.100.151:7000 </dev/null 2>&1 | grep -E "subject=|issuer=|alert|error" | head'
```

> Depuis l'hôte, un client (pilote, `cqlsh` installé localement) doit désormais utiliser le port publié **en TLS**, avec `certs/ca.crt` comme autorité : par exemple `SSL_CERTFILE=certs/ca.crt cqlsh --ssl 127.0.0.1 9142 -u ...`.

---

## Partie 6 — JMX / nodetool et durcissement du Compose

Le fichier Compose d'origine active le JMX distant (`LOCAL_JMX=no`) **sans authentification** (`-Dcom.sun.management.jmxremote.authenticate=false`), et publie 7000/7199 sur toutes les interfaces. On passe à l'**authentification JMX intégrée** : les rôles Cassandra servent aussi pour JMX (module JAAS `CassandraLogin`), et les droits se donnent par `GRANT ... ON MBEAN`.

### 6.1 Préparer les droits JMX (avant la bascule)

```bash
docker exec -i cassandra01 cqlsh <<'EOF'
-- Rôle JMX en lecture (jconsole, nodetool status/info/tablestats...)
CREATE ROLE IF NOT EXISTS r_jmx_lecture;
GRANT SELECT   ON ALL MBEANS TO r_jmx_lecture;
GRANT DESCRIBE ON ALL MBEANS TO r_jmx_lecture;
GRANT EXECUTE  ON MBEAN 'java.lang:type=Threading' TO r_jmx_lecture;
GRANT EXECUTE  ON MBEAN 'com.sun.management:type=HotSpotDiagnostic' TO r_jmx_lecture;
GRANT EXECUTE  ON MBEAN 'org.apache.cassandra.db:type=EndpointSnitchInfo' TO r_jmx_lecture;
GRANT EXECUTE  ON MBEAN 'org.apache.cassandra.db:type=StorageService' TO r_jmx_lecture;

CREATE ROLE IF NOT EXISTS supervision WITH PASSWORD = 'Supervision@2026' AND LOGIN = true;
GRANT r_jmx_lecture TO supervision;
LIST ALL PERMISSIONS OF supervision;
EOF
```

> `EXECUTE` sur `StorageService` est nécessaire à `nodetool status`, mais ce MBean expose aussi des opérations d'administration. Le rôle est donc « lecture » au sens de la documentation, pas au sens strict. Affinez selon vos outils de supervision.

### 6.2 Fichiers clients montés dans les conteneurs

Jusqu'ici, les fichiers clients étaient copiés avec `docker cp` : ils disparaîtraient à la recréation des conteneurs. On les **monte** désormais depuis `./client`.

```bash
cat > client/nodetool.pwd <<'EOF'
dba_westeros Dba-Westeros@2026
supervision Supervision@2026
EOF
chmod 600 client/nodetool.pwd client/credentials client/cqlshrc
ls -l client/        # ca.crt  cqlshrc  credentials  nodetool.pwd
```

### 6.3 Le fichier Compose durci

Créez `Cluster_4_noeuds_2_racks_2_DC_securise.yml` :

```yaml
# Cluster_4_noeuds_2_racks_2_DC_securise.yml
# Version durcie du cluster de TP (Hands-on Lab sécurité Cassandra 5.0) :
#  - image figée (cassandra:5.0) au lieu de « latest »
#  - JMX authentifié (rôles Cassandra via JAAS) et autorisé (GRANT ... ON MBEAN)
#  - ports publiés uniquement sur 127.0.0.1 ; 7000 (inter-nœuds) et 7199 (JMX) non publiés
#  - fichiers clients (cqlshrc, credentials, ca.crt, nodetool.pwd) montés depuis ./client
networks:
  cassandra_network:
    ipam:
      config:
        - subnet: 192.168.100.0/24

services:

  cassandra01:
    image: docker.io/library/cassandra:5.0
    hostname: cassandra01
    container_name: cassandra01
    mem_limit: 1g
    cpus: 0.5
    restart: always
    networks:
      cassandra_network:
        ipv4_address: 192.168.100.151
    volumes:
      - ${PWD}/docker/cassandra01:/var/lib/cassandra
      - conf01:/opt/cassandra/conf
      - ${PWD}/client:/root/.cassandra
    environment:
      - CASSANDRA_CLUSTER_NAME=formation
      - CASSANDRA_SEEDS=cassandra01,cassandra02
      - CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
      - CASSANDRA_DC=Nord
      - CASSANDRA_RACK=Winterfell
      - CASSANDRA_BROADCAST_RPC_ADDRESS=192.168.100.151
      - CASSANDRA_NATIVE_TRANSPORT_PORT=9042
      - MAX_HEAP_SIZE=256m
      - HEAP_NEWSIZE=50m
      - LOCAL_JMX=no
      - >-
        JVM_EXTRA_OPTS=-Djava.rmi.server.hostname=192.168.100.151
        -Dcassandra.jmx.remote.login.config=CassandraLogin
        -Djava.security.auth.login.config=/etc/cassandra/cassandra-jaas.config
        -Dcassandra.jmx.authorizer=org.apache.cassandra.auth.jmx.AuthorizationProxy
        -Dcassandra.disable_auth_caches_remote_configuration=true
    ports:
      - "127.0.0.1:9142:9042"     # CQL (TLS obligatoire) — joignable depuis l'hôte uniquement
    healthcheck:
      test: ["CMD-SHELL", "grep -q 'Startup complete' /var/log/cassandra/system.log"]
      interval: 15s
      timeout: 10s
      retries: 50
      start_period: 180s

  cassandra02:
    depends_on:
      cassandra01:
        condition: service_healthy
    image: docker.io/library/cassandra:5.0
    hostname: cassandra02
    container_name: cassandra02
    mem_limit: 1g
    cpus: 0.5
    restart: always
    networks:
      cassandra_network:
        ipv4_address: 192.168.100.152
    volumes:
      - ${PWD}/docker/cassandra02:/var/lib/cassandra
      - conf02:/opt/cassandra/conf
      - ${PWD}/client:/root/.cassandra
    environment:
      - CASSANDRA_CLUSTER_NAME=formation
      - CASSANDRA_SEEDS=cassandra01,cassandra02
      - CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
      - CASSANDRA_DC=Terres-de-la-Couronne
      - CASSANDRA_RACK=Port-Real
      - CASSANDRA_BROADCAST_RPC_ADDRESS=192.168.100.152
      - CASSANDRA_NATIVE_TRANSPORT_PORT=9042
      - MAX_HEAP_SIZE=256m
      - HEAP_NEWSIZE=50m
      - LOCAL_JMX=no
      - >-
        JVM_EXTRA_OPTS=-Djava.rmi.server.hostname=192.168.100.152
        -Dcassandra.jmx.remote.login.config=CassandraLogin
        -Djava.security.auth.login.config=/etc/cassandra/cassandra-jaas.config
        -Dcassandra.jmx.authorizer=org.apache.cassandra.auth.jmx.AuthorizationProxy
        -Dcassandra.disable_auth_caches_remote_configuration=true
    ports:
      - "127.0.0.1:9242:9042"     # CQL (TLS obligatoire) — joignable depuis l'hôte uniquement
    healthcheck:
      test: ["CMD-SHELL", "grep -q 'Startup complete' /var/log/cassandra/system.log"]
      interval: 15s
      timeout: 10s
      retries: 50
      start_period: 180s

  cassandra03:
    depends_on:
      cassandra02:
        condition: service_healthy
    image: docker.io/library/cassandra:5.0
    hostname: cassandra03
    container_name: cassandra03
    mem_limit: 1g
    cpus: 0.5
    restart: always
    networks:
      cassandra_network:
        ipv4_address: 192.168.100.153
    volumes:
      - ${PWD}/docker/cassandra03:/var/lib/cassandra
      - conf03:/opt/cassandra/conf
      - ${PWD}/client:/root/.cassandra
    environment:
      - CASSANDRA_CLUSTER_NAME=formation
      - CASSANDRA_SEEDS=cassandra01,cassandra02
      - CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
      - CASSANDRA_DC=Nord
      - CASSANDRA_RACK=Winterfell
      - CASSANDRA_BROADCAST_RPC_ADDRESS=192.168.100.153
      - CASSANDRA_NATIVE_TRANSPORT_PORT=9042
      - MAX_HEAP_SIZE=256m
      - HEAP_NEWSIZE=50m
      - LOCAL_JMX=no
      - >-
        JVM_EXTRA_OPTS=-Djava.rmi.server.hostname=192.168.100.153
        -Dcassandra.jmx.remote.login.config=CassandraLogin
        -Djava.security.auth.login.config=/etc/cassandra/cassandra-jaas.config
        -Dcassandra.jmx.authorizer=org.apache.cassandra.auth.jmx.AuthorizationProxy
        -Dcassandra.disable_auth_caches_remote_configuration=true
    ports:
      - "127.0.0.1:9342:9042"     # CQL (TLS obligatoire) — joignable depuis l'hôte uniquement
    healthcheck:
      test: ["CMD-SHELL", "grep -q 'Startup complete' /var/log/cassandra/system.log"]
      interval: 15s
      timeout: 10s
      retries: 50
      start_period: 180s

  cassandra04:
    depends_on:
      cassandra03:
        condition: service_healthy
    image: docker.io/library/cassandra:5.0
    hostname: cassandra04
    container_name: cassandra04
    mem_limit: 1g
    cpus: 0.5
    restart: always
    networks:
      cassandra_network:
        ipv4_address: 192.168.100.154
    volumes:
      - ${PWD}/docker/cassandra04:/var/lib/cassandra
      - conf04:/opt/cassandra/conf
      - ${PWD}/client:/root/.cassandra
    environment:
      - CASSANDRA_CLUSTER_NAME=formation
      - CASSANDRA_SEEDS=cassandra01,cassandra02
      - CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
      - CASSANDRA_DC=Terres-de-la-Couronne
      - CASSANDRA_RACK=Port-Real
      - CASSANDRA_BROADCAST_RPC_ADDRESS=192.168.100.154
      - CASSANDRA_NATIVE_TRANSPORT_PORT=9042
      - MAX_HEAP_SIZE=256m
      - HEAP_NEWSIZE=50m
      - LOCAL_JMX=no
      - >-
        JVM_EXTRA_OPTS=-Djava.rmi.server.hostname=192.168.100.154
        -Dcassandra.jmx.remote.login.config=CassandraLogin
        -Djava.security.auth.login.config=/etc/cassandra/cassandra-jaas.config
        -Dcassandra.jmx.authorizer=org.apache.cassandra.auth.jmx.AuthorizationProxy
        -Dcassandra.disable_auth_caches_remote_configuration=true
    ports:
      - "127.0.0.1:9442:9042"     # CQL (TLS obligatoire) — joignable depuis l'hôte uniquement
    healthcheck:
      test: ["CMD-SHELL", "grep -q 'Startup complete' /var/log/cassandra/system.log"]
      interval: 15s
      timeout: 10s
      retries: 50
      start_period: 180s

volumes:
  conf01:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${PWD}/docker/cassandra01-conf
  conf02:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${PWD}/docker/cassandra02-conf
  conf03:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${PWD}/docker/cassandra03-conf
  conf04:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${PWD}/docker/cassandra04-conf
```

**Différences avec le fichier d'origine**

| Élément | Avant | Après |
|---|---|---|
| Image | `cassandra:latest` | `cassandra:5.0` (version figée) |
| Authentification JMX | `authenticate=false` | JAAS `CassandraLogin` → rôles Cassandra |
| Autorisation JMX | aucune | `AuthorizationProxy` → `GRANT ... ON MBEAN` |
| Reconfiguration des caches d'auth. via JMX | possible | interdite (`disable_auth_caches_remote_configuration`) |
| Ports publiés | 7000, 7199, 8081, 9042 sur `0.0.0.0` | 9042 seulement, sur `127.0.0.1` |
| Fichiers clients | copiés à la main | montés depuis `./client` |

### 6.4 Recréer les conteneurs un par un

```bash
docker compose -f Cluster_4_noeuds_2_racks_2_DC_securise.yml config -q && echo "Compose valide"
COMPOSE_FICHIER=Cluster_4_noeuds_2_racks_2_DC_securise.yml ./outils/rolling_restart.sh
```

Les données (`docker/cassandra0X`) et la configuration (`docker/cassandra0X-conf`) sont sur l'hôte : la recréation ne perd rien. **À partir d'ici, utilisez exclusivement le fichier `..._securise.yml`.**

### 6.5 Vérifier

```bash
NT="nodetool -u dba_westeros -pwf /root/.cassandra/nodetool.pwd"

docker exec cassandra01 nodetool status                                   # refusé : identifiants requis
docker exec cassandra01 $NT status                                        # OK
docker exec cassandra02 nodetool -h 192.168.100.151 status                # à distance sans identifiants : refusé

docker exec cassandra01 nodetool -u supervision -pwf /root/.cassandra/nodetool.pwd status             # OK
docker exec cassandra01 nodetool -u supervision -pwf /root/.cassandra/nodetool.pwd invalidatekeycache # Access Denied

docker port cassandra01                                                   # 9042/tcp -> 127.0.0.1:9142 uniquement
```

> ⚠️ L'authentification JMX intégrée n'est disponible qu'**après** que le nœud a rejoint l'anneau : `nodetool` échoue pendant le démarrage. C'est normal.
> Les outils qui utilisent JMX (Cassandra Reaper, `cassandra_exporter`, Medusa…) doivent recevoir un compte JMX, par exemple le rôle `supervision`, ou un rôle dédié avec les `GRANT ... ON MBEAN` nécessaires.

---

## Partie 7 — Contrôle final

```bash
cat > outils/verif_securite.sh <<'EOF'
#!/usr/bin/env bash
# verif_securite.sh — contrôle final de la sécurisation du cluster (Hands-on Lab Cassandra)
# Usage : ./outils/verif_securite.sh [cassandra01]
N="${1:-cassandra01}"
ECHECS=0
ok() { printf '  \033[32m[OK]\033[0m %s\n' "$1"; }
ko() { printf '  \033[31m[KO]\033[0m %s\n' "$1"; ECHECS=$((ECHECS + 1)); }
teste() {   # la commande DOIT réussir : teste "<libellé OK>" "<libellé KO>" commande...
  local si_ok="$1" si_ko="$2"; shift 2
  if "$@" >/dev/null 2>&1; then ok "$si_ok"; else ko "$si_ko"; fi
}
refuse() {  # la commande DOIT échouer : refuse "<libellé OK>" "<libellé KO>" commande...
  local si_ok="$1" si_ko="$2"; shift 2
  if "$@" >/dev/null 2>&1; then ko "$si_ko"; else ok "$si_ok"; fi
}
# cqlsh « nu » : HOME=/tmp => ni cqlshrc ni credentials
cqlsh_nu() { docker exec -e HOME=/tmp -e SSL_CERTFILE=/root/.cassandra/ca.crt "$N" cqlsh "$@"; }
# valeur d'un paramètre lu dans la table virtuelle system_views.settings
param() { docker exec "$N" cqlsh -e "SELECT value FROM system_views.settings WHERE name = '$1'" 2>/dev/null \
          | sed -n '/^-/{n;p;q}' | tr -d ' '; }
NT="nodetool -u dba_westeros -pwf /root/.cassandra/nodetool.pwd"

echo "== 1. Authentification (nœud $N)"
refuse "connexion anonyme refusée"          "connexion ANONYME ACCEPTÉE"         cqlsh_nu --ssl -e "SELECT now() FROM system.local"
refuse "cassandra/cassandra refusé"         "cassandra/cassandra FONCTIONNE"     cqlsh_nu --ssl -u cassandra -p cassandra -e "SELECT now() FROM system.local"
teste "connexion TLS de dba_westeros OK"     "connexion TLS authentifiée IMPOSSIBLE" docker exec "$N" cqlsh -e "SELECT now() FROM system.local"
[ "$(param authenticator.class_name | grep -c PasswordAuthenticator)" = 1 ] && ok "authenticator = PasswordAuthenticator" || ko "authenticator incorrect"
docker exec "$N" cqlsh -e "DESCRIBE KEYSPACE system_auth" 2>/dev/null | grep -q "NetworkTopologyStrategy" \
  && ok "system_auth répliqué en NetworkTopologyStrategy" || ko "system_auth PAS en NetworkTopologyStrategy"

echo "== 2. Autorisations"
[ "$(param authorizer.class_name | grep -c CassandraAuthorizer)" = 1 ] && ok "authorizer = CassandraAuthorizer" || ko "authorizer incorrect"
[ "$(param network_authorizer.class_name | grep -c CassandraNetworkAuthorizer)" = 1 ] && ok "network_authorizer = CassandraNetworkAuthorizer" || ko "network_authorizer incorrect"
[ "$(param dynamic_data_masking_enabled)" = "true" ] && ok "masquage dynamique activé" || ko "masquage dynamique désactivé"

echo "== 3. Chiffrement"
refuse "CQL en clair refusé"                "CQL en CLAIR ACCEPTÉ"               docker exec -e HOME=/tmp "$N" cqlsh -u dba_westeros -p 'Dba-Westeros@2026' -e "SELECT now() FROM system.local"
[ "$(param client_encryption_options.optional)" = "false" ] && ok "client_encryption_options.optional = false" || ko "TLS client encore optionnel"
[ "$(param server_encryption_options.internode_encryption)" = "all" ] && ok "internode_encryption = all" || ko "internode_encryption <> all"
[ "$(param server_encryption_options.optional)" = "false" ] && ok "server_encryption_options.optional = false" || ko "TLS inter-nœuds encore optionnel"
[ "$(param server_encryption_options.require_client_auth)" = "true" ] && ok "mTLS inter-nœuds (require_client_auth)" || ko "mTLS inter-nœuds non exigé"

echo "== 4. JMX / nodetool"
refuse "nodetool sans identifiants refusé"  "nodetool SANS identifiants ACCEPTÉ" docker exec "$N" nodetool status
teste "nodetool avec identifiants OK"       "nodetool authentifié en échec"      docker exec "$N" $NT status

echo "== 5. Audit"
docker exec "$N" $NT getauditlog 2>/dev/null | grep -Eq "^enabled +true" && ok "audit log actif" || ko "audit log INACTIF"

echo
if [ "$ECHECS" -eq 0 ]; then echo "Bilan : tous les contrôles sont au vert."; else echo "Bilan : $ECHECS contrôle(s) en échec."; fi
exit "$ECHECS"
EOF
chmod +x outils/verif_securite.sh

for n in cassandra01 cassandra02 cassandra03 cassandra04; do ./outils/verif_securite.sh "$n"; done
```

Tous les contrôles doivent être `[OK]`. Comparez avec l'état des lieux de la partie 0.4 :

| Couche | Partie 0 | Partie 7 |
|---|---|---|
| Authentification CQL | anonyme | mot de passe (bcrypt), `cassandra` neutralisé |
| Disponibilité des comptes | RF 1 | NTS, RF 2 par DC |
| Autorisations | aucune | RBAC + restriction par DC + masquage |
| Traçabilité | aucune | audit `AUTH, DCL, DDL, ERROR` persistant |
| Réseau client | clair | TLS 1.2/1.3 obligatoire |
| Réseau inter-nœuds | clair | TLS mutuel obligatoire, vérification des IP |
| JMX / nodetool | ouvert, sans mot de passe | rôles Cassandra + permissions par MBean |
| Exposition Docker | 0.0.0.0 : 7000, 7199, 8081, 9042 | 127.0.0.1 : 9042 |

---

## Annexe A — Dépannage

| Symptôme | Cause probable | Correction |
|---|---|---|
| Un nœud ne redémarre plus après une modification du YAML | erreur de syntaxe ou de valeur | `docker logs cassandra0X 2>&1 \| grep -iE "exception\|invalid" \| head`, puis restaurer `cassandra.yaml.bak` |
| `AuthenticationFailed('Remote end requires authentication')` | aucun identifiant fourni | `-u/-p` ou fichier `credentials` |
| `Credentials file ... exists but is not used` | fichier lisible par le groupe ou les autres | `chmod 600` |
| `Cannot achieve consistency level LOCAL_QUORUM` à la connexion | un réplica `system_auth` du DC local est arrêté | redémarrer le nœud (voir 3.5) |
| `Cannot achieve consistency level EACH_QUORUM` sur `CREATE ROLE` / `GRANT` | un nœud du cluster est arrêté | attendre 4 × `UN` |
| `You do not have access to this datacenter` | rôle limité par `ACCESS TO DATACENTERS` | se connecter à un nœud du bon DC, ou `ALTER ROLE ... WITH ACCESS TO ALL DATACENTERS` |
| `Validation is enabled; SSL transport factory requires a valid certfile` | `cqlsh --ssl` sans `certfile` | section `[ssl]` du `cqlshrc`, ou variable `SSL_CERTFILE` |
| Erreurs `PKIX path building failed` / `No subject alternative names matching IP` dans les logs | mauvais truststore, ou SAN du certificat sans l'IP du nœud | régénérer les certificats (SAN = nom + IP), redéployer |
| `FileNotFoundException` / `AccessDenied` sur `keystore.p12` | chemin erroné ou fichier illisible par l'UID 999 | `sudo chown -R 999:999 docker/cassandra0X-conf/certs` |
| `nodetool` : `Credentials required` / `Authentication failed` | JMX authentifié | `nodetool -u ... -pwf /root/.cassandra/nodetool.pwd` |
| `nodetool` : `Access Denied` | permission MBean manquante | `GRANT EXECUTE ON MBEAN '...'` au rôle |
| Conteneur tué (`OOMKilled`) pendant `auditlogviewer` ou un `repair` | `mem_limit: 1g` très juste | `MAX_HEAP_SIZE=64M` pour les outils, ou `mem_limit: 1536m` |
| Conteneur `healthy` juste après `docker restart` | le healthcheck relit l'ancien `system.log` | se fier à `outils/rolling_restart.sh`, qui lit les logs depuis le redémarrage |

## Annexe B — Écarts relevés dans les supports existants (TP18 et scripts associés)

| # | Support | Affirmation / pratique | Correction pour Cassandra 5.0 |
|---|---|---|---|
| 1 | TP18 §4 | Les rôles autres que `cassandra` s'authentifient en `LOCAL_ONE` | Vrai jusqu'en 4.0. Depuis 4.1 : `LOCAL_QUORUM` en lecture et `EACH_QUORUM` en écriture, réglables (`auth_read_consistency_level` / `auth_write_consistency_level`) |
| 2 | TP18 §4 | `{'dc1': 3, 'dc2': 2}` | Utiliser les **noms réels** des DC (`nodetool status`), avec RF ≤ nombre de nœuds du DC |
| 3 | TP18 §5 | `nodetool repair system_auth` | Réparation incrémentale par défaut depuis 4.0 : `nodetool repair --full system_auth` |
| 4 | TP18 §4–6 | RF de `system_auth` modifié **après** l'activation de l'authentification | Le faire **avant**, pour ne jamais fonctionner en RF 1 avec l'authentification active |
| 5 | TP18 §10 | Le superutilisateur `cassandra` ne peut pas être supprimé | `DROP ROLE cassandra` est possible depuis un autre superutilisateur ; le neutraliser reste une bonne option |
| 6 | TP18 §12–15 | `roles_validity_in_ms`, `credentials_update_interval_in_ms`… | Noms 4.1+ : `roles_validity: 2000ms`, etc. (anciens noms dépréciés) |
| 7 | TP18 §16 | Option à décommenter dans `jvm.options` | Fichiers `jvm-server.options` / `jvm17-server.options` en 4.0+ ; sous Docker, plus simple via `JVM_EXTRA_OPTS` (voir partie 6) |
| 8 | TP18 | Liens DataStax « cql-oss 3.3 » | Documentation Apache Cassandra 5.0 (voir Annexe E) |
| 9 | Compose 3 nœuds sécurisé | Variables `CASSANDRA_AUTHENTICATOR`, `CASSANDRA_AUTHORIZER`, `CASSANDRA_OPEN_JMX`, `JMXPORT` | **Sans effet** : l'entrypoint de l'image officielle ne traite que `CLUSTER_NAME`, `SEEDS`, `LISTEN/BROADCAST/RPC_ADDRESS`, `ENDPOINT_SNITCH`, `NUM_TOKENS`, `DC`, `RACK`. La sécurité se règle dans `cassandra.yaml` |
| 10 | Compose 3 nœuds sécurisé | Healthcheck `cqlsh -u cassandra -p cassandra` | Devient « unhealthy » dès que le rôle `cassandra` est neutralisé, ce qui bloque les `depends_on`. Préférer un test sans identifiant (log `Startup complete`, port 9042) |
| 11 | Compose (tous) | JMX distant avec `authenticate=false` et port 7199 publié | Voir partie 6 : JMX authentifié et port non publié |
| 12 | `initialisation*.sql` | `CREATE ROLE` avant `ALTER KEYSPACE system_auth` | Inverser l'ordre ; `CREATE ROLE` exige `EACH_QUORUM`, donc tous les nœuds disponibles |

## Annexe C — Nettoyage et réinitialisation

```bash
# Arrêt (conserve données et configuration)
docker compose -f Cluster_4_noeuds_2_racks_2_DC_securise.yml stop

# Remise à zéro complète du TP (supprime données, configuration, certificats et secrets clients)
docker compose -f Cluster_4_noeuds_2_racks_2_DC_securise.yml down -v
sudo rm -rf docker/cassandra0{1..4} docker/cassandra0{1..4}-conf certs/*.p12 certs/*.crt client/*
```

## Annexe D — Questions de contrôle

1. Pourquoi faut-il configurer la réplication de `system_auth` en `NetworkTopologyStrategy` dans ce cluster ?
2. Avec 2 nœuds par DC et `system_auth` en RF 2 par DC, que se passe-t-il pour les nouvelles connexions de `app_winterfell` si `cassandra03` tombe ?
3. Quelle différence entre `LOGIN = false` et la suppression d'un rôle ?
4. Pourquoi accorder les permissions à des rôles fonctionnels plutôt qu'aux comptes ?
5. Le masquage dynamique protège-t-il une sauvegarde de SSTables volée ?
6. Pourquoi la migration TLS inter-nœuds demande-t-elle trois redémarrages progressifs ?
7. Que vérifie `require_endpoint_verification: true`, et quelle conséquence sur la génération des certificats ?
8. Pourquoi l'authentification JMX intégrée n'est-elle pas utilisable pendant le démarrage d'un nœud ?

<details>
<summary>Réponses</summary>

1. `SimpleStrategy` ignore les datacenters : les réplicas pourraient tous se trouver dans un seul DC. NTS garantit des réplicas dans chaque DC, et donc des connexions possibles localement dans chacun.
2. Elles échouent dans le DC `Nord`, dès expiration du cache des identifiants, car `LOCAL_QUORUM` exige 2 réplicas sur 2. Elles restent possibles dans l'autre DC, mais `app_winterfell` y est interdit par `ACCESS TO DATACENTERS {'Nord'}`.
3. `LOGIN = false` conserve le rôle, ses permissions et son historique, et le rend réactivable. `DROP ROLE` le supprime avec ses permissions.
4. Pour gérer les droits par population (une modification = un rôle), limiter les erreurs, faciliter la revue des droits et la révocation.
5. Non. Le masquage n'intervient qu'à la lecture CQL ; les fichiers contiennent les valeurs en clair.
6. Un nœud qui émet du TLS ne peut joindre que des pairs qui l'acceptent déjà. On rend d'abord le TLS acceptable partout (étape 1), puis on l'émet (étape 2), enfin on interdit le clair (étape 3).
7. Que le certificat présenté par le pair correspond à son adresse (IP ou nom). Les certificats doivent donc contenir l'IP de chaque nœud dans le SAN.
8. Elle s'appuie sur l'authenticator et le role manager de Cassandra, qui ne sont opérationnels qu'une fois le nœud intégré à l'anneau.
</details>

## Annexe E — Pour aller plus loin

- **Cassandra Reaper sur ce cluster** : rôle CQL `reaper` avec `ALL PERMISSIONS` sur le keyspace `reaper_db`, compte JMX (bloc `jmxAuth` / `jmxCredentials` de Reaper) avec les `GRANT ... ON MBEAN` nécessaires, et le truststore si le CQL est en TLS.
- **Restriction par adresse IP (5.0)** : `cidr_authorizer: CassandraCIDRAuthorizer`, groupes gérés par `nodetool updatecidrgroup`, puis `ALTER ROLE ... WITH ACCESS FROM CIDRS {...}`. Commencer en mode `MONITOR` avant `ENFORCE`.
- **TLS mutuel côté clients** : `require_client_auth: true` dans `client_encryption_options`, avec `userkey`/`usercert` dans le `cqlshrc`. Voire `MutualTlsAuthenticator`, qui authentifie par certificat plutôt que par mot de passe.
- **Clés au format PEM** (`PEMBasedSslContextFactory`) plutôt que PKCS12.
- **JMX sur TLS** (`com.sun.management.jmxremote.ssl=true`) si JMX doit traverser un réseau non maîtrisé.
- **Chiffrement au repos** : `transparent_data_encryption_options` ne couvre que commitlog et hints. Pour les SSTables, chiffrer au niveau du disque ou du système de fichiers.

**Références**

- Apache Cassandra 5.0 — Security : https://cassandra.apache.org/doc/5.0/cassandra/managing/operating/security.html
- Apache Cassandra 5.0 — CQL Security (rôles, permissions) : https://cassandra.apache.org/doc/5.0/cassandra/developing/cql/security.html
- Apache Cassandra 5.0 — Dynamic Data Masking : https://cassandra.apache.org/doc/5.0/cassandra/developing/cql/dynamic-data-masking.html
- Apache Cassandra 5.0 — Audit Logging : https://cassandra.apache.org/doc/5.0/cassandra/managing/operating/audit_logging.html
- Image Docker officielle (entrypoint) : https://github.com/docker-library/cassandra
