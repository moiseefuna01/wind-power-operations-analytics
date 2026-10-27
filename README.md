# Wind Power Operations Analytics

## Présentation

Ce projet met en œuvre une chaîne d’analyse de données appliquée à des observations de turbines éoliennes, depuis l’ingestion d’un fichier CSV jusqu’à l’exploration, la préparation et la modélisation des données en SQL, puis la restitution des indicateurs dans Power BI.

Le travail couvre les principales étapes d’un processus analytique : contrôle de la qualité, standardisation des champs, création d’une vue Silver, modélisation en étoile, agrégations analytiques et suivi d’indicateurs opérationnels.

## Périmètre et données

- **Source :** `data/wind_power_data.csv`
- **Volume :** 6 048 observations et 14 colonnes
- **Période observée :** du 1er au 14 juin 2024
- **Périmètre :** trois turbines, avec 2 016 observations par turbine
- **Technologies :** PostgreSQL, SQL, pgAdmin, Visual Studio Code et Power BI

Les unités physiques de `energy_produced`, `wind_speed` et `capacity` ne sont pas documentées dans le fichier source. Aucune unité n’est donc supposée dans les analyses.

## Architecture analytique

```text
CSV source
   ↓
Bronze — public.wind_power
   ↓
Silver — public.vw_wind_power_silver
   ↓
Modèle en étoile — fact_wind_power + dim_turbine + dim_date + dim_status
   ↓
Gold — public.vw_wind_power_gold_daily
   ↓
Power BI — Executive Overview | Turbine Performance | Operational Reliability
```

- **Bronze :** conservation des colonnes de la source et ingestion des observations.
- **Silver :** nettoyage des espaces, standardisation des valeurs textuelles et conversion des champs de date et d’heure.
- **Modèle en étoile :** organisation des mesures et des dimensions pour faciliter l’analyse.
- **Gold :** agrégation quotidienne par turbine pour alimenter les indicateurs et les visualisations.
- **Power BI :** restitution synthétique, comparaison des turbines et suivi des signaux opérationnels.

## Résultats descriptifs

| Indicateur | Valeur |
|---|---:|
| Production totale calculée depuis la source | 6 847 971,30928 |
| Production totale affichée à deux décimales | 6 847 971,31 |
| Production moyenne par observation | 1 132,27 |
| Maximum par observation | 1 999,85 |
| Mesures à production nulle | 563 (9,31 %) |

Les mesures nulles et les baisses détectées dans les séries temporelles constituent des signaux à analyser. Elles ne démontrent pas, à elles seules, qu’une turbine est en panne.

## Organisation du dépôt

```text
wind-power-operations-analytics/
├── data/                  # Données sources
├── sql/                   # Scripts SQL ordonnés par étape
│   └── archive/           # Scripts historiques conservés à titre de référence
├── powerbi/               # Fichiers du projet Power BI et captures des pages
│   ├── screenshots/
│   ├── source_archive/
│   ├── source_project_files/
│   └── Projet1-SQL_power BI.Report/
├── docs/                  # Rapport technique, dictionnaire et index du projet
├── .gitignore
└── README.md
```

## Reproduire le pipeline SQL

Pour reproduire les traitements dans une base PostgreSQL de test :

1. Créer une base dédiée et ouvrir son éditeur SQL.
2. Exécuter `sql/00_create_raw_table.sql` pour préparer la table brute. Si la table existe déjà et contient les observations, ne pas la recréer ni réimporter les données.
3. Si la table est vide, importer `data/wind_power_data.csv` dans `public.wind_power` avec l’en-tête activé, le séparateur `,`, le guillemet `"` et l’encodage UTF-8.
4. Exécuter les scripts `01` à `06` dans l’ordre numérique.
5. Exécuter `sql/08_validation_read_only.sql` pour effectuer les contrôles en lecture seule.
6. `sql/07_security_permissions.sql` est optionnel et concerne l’administration des rôles et permissions PostgreSQL; il ne fait pas partie du parcours analytique principal.

Dans le CSV source, le champ `time_` est au format `HH-MM-SS`. La vue Silver remplace les tirets par des deux-points avant la conversion en type `TIME`.

## Rapport Power BI

Le rapport est organisé autour de trois pages complémentaires :

- **Executive Overview :** indicateurs globaux, filtres temporels et géographiques, et évolution quotidienne de la production.
- **Turbine Performance :** comparaison des productions totales et moyennes entre turbines.
- **Operational Reliability :** suivi des mesures nulles, des statuts et des variations importantes de production.

Les captures correspondantes sont disponibles dans `powerbi/screenshots/`. Les fichiers de projet Power BI fournis sont conservés dans `powerbi/`. Lors de l’ouverture du projet dans Power BI Desktop, la source de données PostgreSQL doit être configurée pour l’environnement utilisé et le rapport actualisé.

## Interprétation et limites de l’analyse

- La source couvre 14 jours et trois turbines; elle ne permet pas à elle seule de généraliser les résultats à une année complète ou à un parc entier.
- Les unités physiques ne sont pas précisées dans le fichier source.
- Les mesures à zéro et les baisses importantes sont des indicateurs de diagnostic, pas des preuves automatiques de défaillance.
- Les résultats décrivent les données disponibles et ne permettent pas d’établir la cause technique d’un écart sans investigation complémentaire.

## Technologies et compétences mobilisées

**PostgreSQL · SQL · pgAdmin · Visual Studio Code · Power BI · Qualité des données · Modélisation en étoile · Architecture Bronze/Silver/Gold · KPI · Fonctions de fenêtre · Analyse temporelle · Visualisation**
