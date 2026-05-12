-- ============================================================
-- PORTFOLIO BANCAIRE - Analyse Risque Crédit & Pilotage
-- Auteur : [Bleze TCHALLA] | Business Data Analyst Freelance
-- Stack  : SQL + Power BI
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- TABLE 1 : AGENCES
-- ────────────────────────────────────────────────────────────
CREATE TABLE agences (
    agence_id       INTEGER PRIMARY KEY,
    nom_agence      TEXT NOT NULL,
    region          TEXT NOT NULL,
    directeur       TEXT NOT NULL,
    objectif_encours DECIMAL(15,2) -- Objectif encours crédit annuel (€)
);

-- ────────────────────────────────────────────────────────────
-- TABLE 2 : CONSEILLERS
-- ────────────────────────────────────────────────────────────
CREATE TABLE conseillers (
    conseiller_id   INTEGER PRIMARY KEY,
    nom             TEXT NOT NULL,
    prenom          TEXT NOT NULL,
    agence_id       INTEGER REFERENCES agences(agence_id),
    date_embauche   DATE NOT NULL
);

-- ────────────────────────────────────────────────────────────
-- TABLE 3 : CLIENTS
-- ────────────────────────────────────────────────────────────
CREATE TABLE clients (
    client_id       INTEGER PRIMARY KEY,
    nom             TEXT NOT NULL,
    prenom          TEXT NOT NULL,
    age             INTEGER NOT NULL,
    revenu_annuel   DECIMAL(12,2) NOT NULL,
    score_credit    INTEGER NOT NULL,   -- Score interne 0-1000
    segment         TEXT NOT NULL,      -- 'Particulier', 'Professionnel', 'Entreprise'
    agence_id       INTEGER REFERENCES agences(agence_id),
    conseiller_id   INTEGER REFERENCES conseillers(conseiller_id),
    date_entree     DATE NOT NULL
);

-- ────────────────────────────────────────────────────────────
-- TABLE 4 : CREDITS
-- ────────────────────────────────────────────────────────────
CREATE TABLE credits (
    credit_id       INTEGER PRIMARY KEY,
    client_id       INTEGER REFERENCES clients(client_id),
    type_credit     TEXT NOT NULL,      -- 'Immobilier', 'Consommation', 'Professionnel', 'Revolving'
    montant         DECIMAL(15,2) NOT NULL,
    encours         DECIMAL(15,2) NOT NULL, -- Capital restant dû
    taux_interet    DECIMAL(5,3) NOT NULL,
    duree_mois      INTEGER NOT NULL,
    date_octroi     DATE NOT NULL,
    date_echeance   DATE NOT NULL,
    statut          TEXT NOT NULL,      -- 'Sain', 'Douteux', 'Défaut', 'Soldé'
    nb_jours_retard INTEGER DEFAULT 0,
    provisions      DECIMAL(15,2) DEFAULT 0 -- Provisions pour risque (€)
);

-- ────────────────────────────────────────────────────────────
-- TABLE 5 : MOUVEMENTS MENSUELS (pour suivi temporel)
-- ────────────────────────────────────────────────────────────
CREATE TABLE mouvements_mensuels (
    mouvement_id    INTEGER PRIMARY KEY,
    credit_id       INTEGER REFERENCES credits(credit_id),
    annee           INTEGER NOT NULL,
    mois            INTEGER NOT NULL,
    encours_debut   DECIMAL(15,2) NOT NULL,
    remboursement   DECIMAL(15,2) NOT NULL,
    encours_fin     DECIMAL(15,2) NOT NULL,
    statut_mois     TEXT NOT NULL
);
