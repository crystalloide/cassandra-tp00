const express = require('express');
const cassandra = require('cassandra-driver');
const bodyParser = require('body-parser');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(express.static('public'));

// Configuration Cassandra - connexion au cluster avec les 4 nœuds
const client = new cassandra.Client({
    contactPoints: [
        'cassandra01',
        'cassandra02',
        'cassandra03',
        'cassandra04'
    ],
    localDataCenter: 'dc1',
    keyspace: 'veterinary',
    pooling: {
        coreConnectionsPerHost: {
            [cassandra.types.distance.local]: 2,
            [cassandra.types.distance.remote]: 1
        }
    }
});

// Connexion au cluster
client.connect()
    .then(() => console.log('✓ Connecté au cluster Cassandra (4 nœuds)'))
    .catch(err => console.error('Erreur de connexion Cassandra:', err));

// ==================== VÉTÉRINAIRES ====================

// Récupérer tous les vétérinaires
app.get('/api/veterinaires', async (req, res) => {
    try {
        const result = await client.execute('SELECT * FROM veterinaires WHERE actif = true ALLOW FILTERING');
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Ajouter un vétérinaire
app.post('/api/veterinaires', async (req, res) => {
    try {
        const { nom, prenom, specialite, telephone, email } = req.body;
        const id = uuidv4();
        const query = 'INSERT INTO veterinaires (id, nom, prenom, specialite, telephone, email, actif) VALUES (?, ?, ?, ?, ?, ?, true)';
        await client.execute(query, [id, nom, prenom, specialite, telephone, email], { prepare: true });
        res.json({ id, nom, prenom, specialite, telephone, email, actif: true });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Modifier un vétérinaire
app.put('/api/veterinaires/:id', async (req, res) => {
    try {
        const { nom, prenom, specialite, telephone, email } = req.body;
        const query = 'UPDATE veterinaires SET nom = ?, prenom = ?, specialite = ?, telephone = ?, email = ? WHERE id = ?';
        await client.execute(query, [nom, prenom, specialite, telephone, email, req.params.id], { prepare: true });
        res.json({ id: req.params.id, nom, prenom, specialite, telephone, email });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Supprimer un vétérinaire (soft delete)
app.delete('/api/veterinaires/:id', async (req, res) => {
    try {
        const query = 'UPDATE veterinaires SET actif = false WHERE id = ?';
        await client.execute(query, [req.params.id], { prepare: true });
        res.json({ message: 'Vétérinaire désactivé' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ==================== ESPÈCES ====================

// Récupérer toutes les espèces
app.get('/api/especes', async (req, res) => {
    try {
        const result = await client.execute('SELECT * FROM especes');
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Ajouter une espèce
app.post('/api/especes', async (req, res) => {
    try {
        const { nom, description } = req.body;
        const id = uuidv4();
        const query = 'INSERT INTO especes (id, nom, description) VALUES (?, ?, ?)';
        await client.execute(query, [id, nom, description], { prepare: true });
        res.json({ id, nom, description });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Modifier une espèce
app.put('/api/especes/:id', async (req, res) => {
    try {
        const { nom, description } = req.body;
        const query = 'UPDATE especes SET nom = ?, description = ? WHERE id = ?';
        await client.execute(query, [nom, description, req.params.id], { prepare: true });
        res.json({ id: req.params.id, nom, description });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Supprimer une espèce
app.delete('/api/especes/:id', async (req, res) => {
    try {
        const query = 'DELETE FROM especes WHERE id = ?';
        await client.execute(query, [req.params.id], { prepare: true });
        res.json({ message: 'Espèce supprimée' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ==================== ANIMAUX ====================

// Récupérer tous les animaux
app.get('/api/animaux', async (req, res) => {
    try {
        const result = await client.execute('SELECT * FROM animaux');
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Ajouter un animal
app.post('/api/animaux', async (req, res) => {
    try {
        const { nom, espece_id, proprietaire_nom, proprietaire_telephone, proprietaire_email, date_naissance, notes } = req.body;
        
        // Vérifier que l'espèce existe et récupérer son nom
        const especeResult = await client.execute('SELECT nom FROM especes WHERE id = ?', [espece_id], { prepare: true });
        if (especeResult.rows.length === 0) {
            return res.status(400).json({ error: 'Espèce non trouvée' });
        }
        const espece_nom = especeResult.rows[0].nom;
        
        const id = uuidv4();
        const query = 'INSERT INTO animaux (id, nom, espece_id, espece_nom, proprietaire_nom, proprietaire_telephone, proprietaire_email, date_naissance, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)';
        await client.execute(query, [id, nom, espece_id, espece_nom, proprietaire_nom, proprietaire_telephone, proprietaire_email, date_naissance, notes], { prepare: true });
        res.json({ id, nom, espece_id, espece_nom, proprietaire_nom, proprietaire_telephone, proprietaire_email, date_naissance, notes });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Modifier un animal
app.put('/api/animaux/:id', async (req, res) => {
    try {
        const { nom, espece_id, proprietaire_nom, proprietaire_telephone, proprietaire_email, date_naissance, notes } = req.body;
        
        // Vérifier que l'espèce existe et récupérer son nom
        const especeResult = await client.execute('SELECT nom FROM especes WHERE id = ?', [espece_id], { prepare: true });
        if (especeResult.rows.length === 0) {
            return res.status(400).json({ error: 'Espèce non trouvée' });
        }
        const espece_nom = especeResult.rows[0].nom;
        
        const query = 'UPDATE animaux SET nom = ?, espece_id = ?, espece_nom = ?, proprietaire_nom = ?, proprietaire_telephone = ?, proprietaire_email = ?, date_naissance = ?, notes = ? WHERE id = ?';
        await client.execute(query, [nom, espece_id, espece_nom, proprietaire_nom, proprietaire_telephone, proprietaire_email, date_naissance, notes, req.params.id], { prepare: true });
        res.json({ id: req.params.id, nom, espece_id, espece_nom, proprietaire_nom, proprietaire_telephone, proprietaire_email, date_naissance, notes });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Supprimer un animal
app.delete('/api/animaux/:id', async (req, res) => {
    try {
        const query = 'DELETE FROM animaux WHERE id = ?';
        await client.execute(query, [req.params.id], { prepare: true });
        res.json({ message: 'Animal supprimé' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ==================== RENDEZ-VOUS ====================

// Récupérer tous les rendez-vous
app.get('/api/rendezvous', async (req, res) => {
    try {
        const result = await client.execute('SELECT * FROM rendezvous');
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Ajouter un rendez-vous
app.post('/api/rendezvous', async (req, res) => {
    try {
        const { animal_id, veterinaire_id, date_heure, motif, statut, notes } = req.body;
        
        // Vérifier que l'animal existe et récupérer son nom
        const animalResult = await client.execute('SELECT nom FROM animaux WHERE id = ?', [animal_id], { prepare: true });
        if (animalResult.rows.length === 0) {
            return res.status(400).json({ error: 'Animal non trouvé' });
        }
        const animal_nom = animalResult.rows[0].nom;
        
        // Vérifier que le vétérinaire existe et récupérer son nom
        const vetResult = await client.execute('SELECT nom, prenom FROM veterinaires WHERE id = ?', [veterinaire_id], { prepare: true });
        if (vetResult.rows.length === 0) {
            return res.status(400).json({ error: 'Vétérinaire non trouvé' });
        }
        const veterinaire_nom = `${vetResult.rows[0].prenom} ${vetResult.rows[0].nom}`;
        
        const id = uuidv4();
        const query = 'INSERT INTO rendezvous (id, animal_id, animal_nom, veterinaire_id, veterinaire_nom, date_heure, motif, statut, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)';
        await client.execute(query, [id, animal_id, animal_nom, veterinaire_id, veterinaire_nom, new Date(date_heure), motif, statut, notes], { prepare: true });
        res.json({ id, animal_id, animal_nom, veterinaire_id, veterinaire_nom, date_heure, motif, statut, notes });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Modifier un rendez-vous
app.put('/api/rendezvous/:id', async (req, res) => {
    try {
        const { animal_id, veterinaire_id, date_heure, motif, statut, notes } = req.body;
        
        // Vérifier que l'animal existe et récupérer son nom
        const animalResult = await client.execute('SELECT nom FROM animaux WHERE id = ?', [animal_id], { prepare: true });
        if (animalResult.rows.length === 0) {
            return res.status(400).json({ error: 'Animal non trouvé' });
        }
        const animal_nom = animalResult.rows[0].nom;
        
        // Vérifier que le vétérinaire existe et récupérer son nom
        const vetResult = await client.execute('SELECT nom, prenom FROM veterinaires WHERE id = ?', [veterinaire_id], { prepare: true });
        if (vetResult.rows.length === 0) {
            return res.status(400).json({ error: 'Vétérinaire non trouvé' });
        }
        const veterinaire_nom = `${vetResult.rows[0].prenom} ${vetResult.rows[0].nom}`;
        
        const query = 'UPDATE rendezvous SET animal_id = ?, animal_nom = ?, veterinaire_id = ?, veterinaire_nom = ?, date_heure = ?, motif = ?, statut = ?, notes = ? WHERE id = ?';
        await client.execute(query, [animal_id, animal_nom, veterinaire_id, veterinaire_nom, new Date(date_heure), motif, statut, notes, req.params.id], { prepare: true });
        res.json({ id: req.params.id, animal_id, animal_nom, veterinaire_id, veterinaire_nom, date_heure, motif, statut, notes });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Supprimer un rendez-vous
app.delete('/api/rendezvous/:id', async (req, res) => {
    try {
        const query = 'DELETE FROM rendezvous WHERE id = ?';
        await client.execute(query, [req.params.id], { prepare: true });
        res.json({ message: 'Rendez-vous supprimé' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Démarrage du serveur
app.listen(PORT, () => {
    console.log(`✓ Serveur démarré sur http://localhost:${PORT}`);
    console.log(`✓ Cluster Cassandra : 4 nœuds (192.168.100.151-154)`);
});

// Gestion de la fermeture propre
process.on('SIGINT', async () => {
    await client.shutdown();
    process.exit(0);
});
