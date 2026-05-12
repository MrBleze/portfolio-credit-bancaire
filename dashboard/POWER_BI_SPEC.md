# 📊 Spécification Dashboard Power BI
## Analyse Risque Crédit & Pilotage de Portefeuille Bancaire

---

## Architecture du rapport (3 pages)

---

### PAGE 1 — Vue Direction : KPIs Globaux

**Objectif** : Donner au CODIR une lecture instantanée de la santé du portefeuille.

#### Visuels à créer

| Visual | Type Power BI | Données |
|--------|--------------|---------|
| Encours total | Carte KPI | SUM(credits[encours]) |
| NPL Ratio | Jauge (0-15%) | Encours douteux+défaut / Encours total |
| Taux de couverture | Carte KPI | SUM(provisions) / Encours NPL |
| Nb crédits actifs | Carte KPI | COUNTROWS credits sain+douteux+défaut |
| Répartition par statut | Graphique en anneau | Encours par statut |
| Encours par type de crédit | Barres horizontales | Encours par type_credit |
| Encours par agence | Carte choroplèthe ou barres | Encours par region |
| Évolution mensuelle encours | Courbe | Table mouvements_mensuels |

#### Mesures DAX à créer

```dax
// Encours Total
Encours Total = 
CALCULATE(SUM(credits[encours]), credits[statut] <> "Soldé")

// NPL Ratio
NPL Ratio = 
DIVIDE(
    CALCULATE(SUM(credits[encours]), credits[statut] IN {"Défaut","Douteux"}),
    CALCULATE(SUM(credits[encours]), credits[statut] <> "Soldé")
)

// Taux de Couverture
Taux Couverture = 
DIVIDE(
    SUM(credits[provisions]),
    CALCULATE(SUM(credits[encours]), credits[statut] IN {"Défaut","Douteux"})
)

// Nb Clients à Risque
Clients à Risque = 
CALCULATE(
    DISTINCTCOUNT(credits[client_id]),
    credits[statut] IN {"Défaut","Douteux"}
)
```

#### Filtres (slicers)
- Agence (liste déroulante)
- Segment client (Particulier / Professionnel / Entreprise)
- Type de crédit
- Période (date_octroi — slider)

---

### PAGE 2 — Vue Agence : Performance & Objectifs

**Objectif** : Permettre aux directeurs d'agence de suivre leurs équipes et leur portefeuille.

#### Visuels à créer

| Visual | Type Power BI | Données |
|--------|--------------|---------|
| Réalisation vs Objectif | Barres groupées | Encours réel vs objectif_encours |
| Classement agences | Table avec barres de données | Encours, NPL, nb clients |
| Performance conseillers | Matrice | Agence > Conseiller > KPIs |
| Encours par segment | Barres empilées 100% | Segment par agence |
| Clients à risque par agence | Graphique à bulles | NPL Ratio vs Encours |

#### Mesures DAX à créer

```dax
// Taux de Réalisation Objectif
Taux Réalisation = 
DIVIDE([Encours Total], MAX(agences[objectif_encours]))

// Écart Objectif
Ecart Objectif = 
[Encours Total] - MAX(agences[objectif_encours])

// Encours Moyen par Client
Encours / Client = 
DIVIDE([Encours Total], DISTINCTCOUNT(credits[client_id]))
```

#### Mise en forme conditionnelle
- Colonne NPL Ratio : vert < 5%, orange 5-10%, rouge > 10%
- Colonne Taux Réalisation : rouge < 80%, orange 80-95%, vert > 95%

---

### PAGE 3 — Vue Risque : Segmentation & Scoring

**Objectif** : Identifier les poches de risque et les clients prioritaires.

#### Visuels à créer

| Visual | Type Power BI | Données |
|--------|--------------|---------|
| Matrice risque | Scatter plot | Score crédit (X) vs Encours (Y), couleur = statut |
| Pyramide des classes de risque | Barres horizontales | AAA / BB / CC / D |
| Top 10 clients à risque | Table détaillée | Client, encours, jours retard, conseiller |
| Heatmap NPL par agence x type | Matrice couleur | Agence vs type_credit |
| Distribution score crédit | Histogramme | Score crédit par tranche de 50 |

#### Mesures DAX à créer

```dax
// Classe de Risque
Classe Risque = 
SWITCH(TRUE(),
    MAX(clients[score_credit]) >= 800, "AAA - Excellent",
    MAX(clients[score_credit]) >= 700, "BB - Bon",
    MAX(clients[score_credit]) >= 600, "CC - Moyen",
    "D - Risqué"
)

// Taux de Défaut par Segment
Taux Défaut = 
DIVIDE(
    CALCULATE(COUNTROWS(credits), credits[statut] = "Défaut"),
    CALCULATE(COUNTROWS(credits), credits[statut] <> "Soldé")
)

// Provisions / Encours NPL
Ratio Provision = 
DIVIDE(SUM(credits[provisions]),
    CALCULATE(SUM(credits[encours]), 
    credits[statut] IN {"Défaut","Douteux"}))
```

---

## Modèle de données Power BI

```
agences (1) ──────< clients (N)
                       │
conseillers (1) ───────┘
                       │
                       └──< credits (N)
                                │
                                └──< mouvements_mensuels (N)
```

**Relations à créer dans Power BI :**
- agences[agence_id] → clients[agence_id] (1 à N)
- conseillers[conseiller_id] → clients[conseiller_id] (1 à N)
- clients[client_id] → credits[client_id] (1 à N)
- credits[credit_id] → mouvements_mensuels[credit_id] (1 à N)

---

## Charte graphique recommandée

| Élément | Couleur | Usage |
|---------|---------|-------|
| Primaire | #1B4F8A | Titres, en-têtes |
| Sain | #27AE60 | Statut sain |
| Douteux | #F39C12 | Statut douteux |
| Défaut | #E74C3C | Statut défaut |
| Soldé | #95A5A6 | Statut soldé |
| Fond | #F8F9FA | Arrière-plan pages |

---

## Import des données

1. Ouvrir Power BI Desktop
2. **Obtenir les données** → SQLite (ou coller les CSV générés)
3. Charger les 4 tables : `agences`, `conseillers`, `clients`, `credits`
4. Aller dans **Vue Modèle** et créer les relations ci-dessus
5. Créer les mesures DAX dans une table de mesures dédiée
