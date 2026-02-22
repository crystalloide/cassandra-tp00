-- Schéma Cassandra pour l'application de gestion vétérinaire
-- À exécuter sur le cluster Cassandra

DROP KEYSPACE IF EXISTS veterinary;

-- Créer le keyspace avec réplication sur les 4 nœuds
CREATE KEYSPACE IF NOT EXISTS veterinary
WITH replication = {
    'class': 'NetworkTopologyStrategy',
    'dc1': 3
};

USE veterinary;

-- Table des vétérinaires
CREATE TABLE IF NOT EXISTS veterinaires (
    id UUID PRIMARY KEY,
    nom TEXT,
    prenom TEXT,
    specialite TEXT,
    telephone TEXT,
    email TEXT,
    actif BOOLEAN
);

-- Table des espèces animales
CREATE TABLE IF NOT EXISTS especes (
    id UUID PRIMARY KEY,
    nom TEXT,
    description TEXT
);

-- Table des animaux
CREATE TABLE IF NOT EXISTS animaux (
    id UUID PRIMARY KEY,
    nom TEXT,
    espece_id UUID,
    espece_nom TEXT,
    proprietaire_nom TEXT,
    proprietaire_telephone TEXT,
    proprietaire_email TEXT,
    date_naissance DATE,
    notes TEXT
);

-- Table des rendez-vous
CREATE TABLE IF NOT EXISTS rendezvous (
    id UUID PRIMARY KEY,
    animal_id UUID,
    animal_nom TEXT,
    veterinaire_id UUID,
    veterinaire_nom TEXT,
    date_heure TIMESTAMP,
    motif TEXT,
    statut TEXT,
    notes TEXT
);

-- Index pour recherches
CREATE INDEX IF NOT EXISTS ON animaux (espece_id);
CREATE INDEX IF NOT EXISTS ON rendezvous (animal_id);
CREATE INDEX IF NOT EXISTS ON rendezvous (veterinaire_id);
CREATE INDEX IF NOT EXISTS ON rendezvous (date_heure);

-- Insérer quelques données de test
INSERT INTO veterinaires (id, nom, prenom, specialite, telephone, email, actif)
VALUES (uuid(), 'Dupont', 'Marie', 'Généraliste', '0601020304', 'marie.dupont@clinic.fr', true);

INSERT INTO veterinaires (id, nom, prenom, specialite, telephone, email, actif)
VALUES (uuid(), 'Martin', 'Pierre', 'Chirurgien', '0605060708', 'pierre.martin@clinic.fr', true);

INSERT INTO especes (id, nom, description)
VALUES (uuid(), 'Chat', 'Félin domestique');

INSERT INTO especes (id, nom, description)
VALUES (uuid(), 'Chien', 'Canidé domestique');

INSERT INTO especes (id, nom, description)
VALUES (uuid(), 'Lapin', 'Lagomorphe');

INSERT INTO especes (id, nom, description)
VALUES (uuid(), 'Oiseau', 'Volatiles divers');
