-- ============================================================
-- REQUÊTES ANALYTIQUES - Portefeuille Crédit Bancaire
-- Auteur : [Bleze TCHALLA] | Business Data Analyst Freelance
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. KPIs GLOBAUX - Vue Direction
-- ────────────────────────────────────────────────────────────

-- Encours total, taux de défaut, NPL Ratio
SELECT
    COUNT(DISTINCT c.credit_id)                          AS nb_credits,
    COUNT(DISTINCT c.client_id)                          AS nb_clients,
    ROUND(SUM(c.encours), 0)                             AS encours_total,
    ROUND(SUM(CASE WHEN c.statut = 'Défaut'  THEN c.encours ELSE 0 END), 0) AS encours_defaut,
    ROUND(SUM(CASE WHEN c.statut = 'Douteux' THEN c.encours ELSE 0 END), 0) AS encours_douteux,
    ROUND(SUM(CASE WHEN c.statut IN ('Défaut','Douteux') THEN c.encours ELSE 0 END)
          / SUM(c.encours) * 100, 2)                     AS npl_ratio_pct,
    ROUND(SUM(c.provisions), 0)                          AS total_provisions,
    ROUND(SUM(c.provisions) / NULLIF(SUM(CASE WHEN c.statut IN ('Défaut','Douteux')
          THEN c.encours ELSE 0 END), 0) * 100, 2)       AS taux_couverture_pct
FROM credits c
WHERE c.statut != 'Soldé';


-- ────────────────────────────────────────────────────────────
-- 2. RÉPARTITION PAR STATUT DE CRÉDIT
-- ────────────────────────────────────────────────────────────
SELECT
    statut,
    COUNT(*)                                AS nb_credits,
    ROUND(SUM(encours), 0)                  AS encours_total,
    ROUND(AVG(encours), 0)                  AS encours_moyen,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS part_pct
FROM credits
GROUP BY statut
ORDER BY encours_total DESC;


-- ────────────────────────────────────────────────────────────
-- 3. TAUX DE DÉFAUT PAR SEGMENT CLIENT
-- ────────────────────────────────────────────────────────────
SELECT
    cl.segment,
    COUNT(DISTINCT cl.client_id)            AS nb_clients,
    COUNT(cr.credit_id)                     AS nb_credits,
    ROUND(SUM(cr.encours), 0)               AS encours_total,
    COUNT(CASE WHEN cr.statut = 'Défaut'  THEN 1 END) AS nb_defauts,
    COUNT(CASE WHEN cr.statut = 'Douteux' THEN 1 END) AS nb_douteux,
    ROUND(COUNT(CASE WHEN cr.statut = 'Défaut' THEN 1 END) * 100.0
          / NULLIF(COUNT(cr.credit_id), 0), 2)          AS taux_defaut_pct,
    ROUND(AVG(cl.score_credit), 0)          AS score_credit_moyen
FROM clients cl
JOIN credits cr ON cl.client_id = cr.client_id
WHERE cr.statut != 'Soldé'
GROUP BY cl.segment
ORDER BY taux_defaut_pct DESC;


-- ────────────────────────────────────────────────────────────
-- 4. PERFORMANCE PAR AGENCE vs OBJECTIF
-- ────────────────────────────────────────────────────────────
SELECT
    a.nom_agence,
    a.region,
    a.objectif_encours,
    ROUND(SUM(cr.encours), 0)               AS encours_reel,
    ROUND(SUM(cr.encours) / a.objectif_encours * 100, 1) AS taux_realisation_pct,
    COUNT(DISTINCT cl.client_id)            AS nb_clients,
    COUNT(cr.credit_id)                     AS nb_credits,
    ROUND(SUM(CASE WHEN cr.statut IN ('Défaut','Douteux') THEN cr.encours ELSE 0 END)
          / NULLIF(SUM(cr.encours), 0) * 100, 2)        AS npl_ratio_pct
FROM agences a
JOIN clients cl ON a.agence_id = cl.agence_id
JOIN credits cr ON cl.client_id = cr.client_id
WHERE cr.statut != 'Soldé'
GROUP BY a.agence_id, a.nom_agence, a.region, a.objectif_encours
ORDER BY taux_realisation_pct DESC;


-- ────────────────────────────────────────────────────────────
-- 5. TOP 10 CLIENTS À RISQUE (score faible + crédits douteux/défaut)
-- ────────────────────────────────────────────────────────────
SELECT
    cl.client_id,
    cl.nom || ' ' || cl.prenom            AS client,
    cl.segment,
    cl.score_credit,
    a.nom_agence,
    cons.nom || ' ' || cons.prenom        AS conseiller,
    COUNT(cr.credit_id)                   AS nb_credits_problematiques,
    ROUND(SUM(cr.encours), 0)             AS encours_a_risque,
    ROUND(SUM(cr.provisions), 0)          AS provisions,
    MAX(cr.nb_jours_retard)               AS max_jours_retard
FROM clients cl
JOIN credits cr   ON cl.client_id   = cr.client_id
JOIN agences a    ON cl.agence_id   = a.agence_id
JOIN conseillers cons ON cl.conseiller_id = cons.conseiller_id
WHERE cr.statut IN ('Défaut', 'Douteux')
GROUP BY cl.client_id, cl.nom, cl.prenom, cl.segment,
         cl.score_credit, a.nom_agence, cons.nom, cons.prenom
ORDER BY encours_a_risque DESC
LIMIT 10;


-- ────────────────────────────────────────────────────────────
-- 6. RÉPARTITION PAR TYPE DE CRÉDIT
-- ────────────────────────────────────────────────────────────
SELECT
    cr.type_credit,
    COUNT(*)                              AS nb_credits,
    ROUND(SUM(cr.encours), 0)             AS encours_total,
    ROUND(AVG(cr.taux_interet) * 100, 3)  AS taux_moyen_pct,
    ROUND(AVG(cr.encours), 0)             AS encours_moyen,
    COUNT(CASE WHEN cr.statut = 'Défaut'  THEN 1 END) AS nb_defauts,
    COUNT(CASE WHEN cr.statut = 'Douteux' THEN 1 END) AS nb_douteux,
    ROUND(COUNT(CASE WHEN cr.statut IN ('Défaut','Douteux') THEN 1 END) * 100.0
          / COUNT(*), 2)                  AS taux_npl_pct
FROM credits cr
WHERE cr.statut != 'Soldé'
GROUP BY cr.type_credit
ORDER BY encours_total DESC;


-- ────────────────────────────────────────────────────────────
-- 7. SEGMENTATION CLIENTS PAR SCORE DE CRÉDIT
-- ────────────────────────────────────────────────────────────
SELECT
    CASE
        WHEN cl.score_credit >= 800 THEN 'AAA (800-1000) - Excellent'
        WHEN cl.score_credit >= 700 THEN 'BB  (700-799)  - Bon'
        WHEN cl.score_credit >= 600 THEN 'CC  (600-699)  - Moyen'
        ELSE                              'D   (<600)     - Risqué'
    END                                   AS classe_risque,
    COUNT(DISTINCT cl.client_id)          AS nb_clients,
    ROUND(AVG(cl.revenu_annuel), 0)       AS revenu_moyen,
    ROUND(SUM(cr.encours), 0)             AS encours_total,
    ROUND(COUNT(CASE WHEN cr.statut IN ('Défaut','Douteux') THEN 1 END) * 100.0
          / NULLIF(COUNT(cr.credit_id), 0), 2) AS taux_npl_pct
FROM clients cl
JOIN credits cr ON cl.client_id = cr.client_id
WHERE cr.statut != 'Soldé'
GROUP BY classe_risque
ORDER BY MIN(cl.score_credit) DESC;


-- ────────────────────────────────────────────────────────────
-- 8. PERFORMANCE CONSEILLERS - Vue Manager
-- ────────────────────────────────────────────────────────────
SELECT
    a.nom_agence,
    cons.nom || ' ' || cons.prenom        AS conseiller,
    COUNT(DISTINCT cl.client_id)          AS nb_clients,
    COUNT(cr.credit_id)                   AS nb_credits,
    ROUND(SUM(cr.encours), 0)             AS encours_total,
    ROUND(AVG(cl.score_credit), 0)        AS score_moyen_portefeuille,
    COUNT(CASE WHEN cr.statut = 'Défaut'  THEN 1 END) AS nb_defauts,
    ROUND(COUNT(CASE WHEN cr.statut IN ('Défaut','Douteux') THEN 1 END) * 100.0
          / NULLIF(COUNT(cr.credit_id), 0), 2) AS taux_npl_pct
FROM conseillers cons
JOIN agences a    ON cons.agence_id = a.agence_id
JOIN clients cl   ON cons.conseiller_id = cl.conseiller_id
JOIN credits cr   ON cl.client_id = cr.client_id
WHERE cr.statut != 'Soldé'
GROUP BY a.nom_agence, cons.conseiller_id, cons.nom, cons.prenom
ORDER BY a.nom_agence, taux_npl_pct DESC;
