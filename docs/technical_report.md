# Rapport technique — Wind Power Operations Analytics

## 1. Résumé du projet

Ce projet met en œuvre une chaîne d’analyse de données de bout en bout à partir d’observations de turbines éoliennes. Il couvre l’ingestion d’un fichier CSV, l’exploration et les contrôles de qualité, la standardisation des données en SQL, la modélisation en étoile, les agrégations analytiques et la visualisation des indicateurs dans Power BI.

- **Données source :** `data/wind_power_data.csv`
- **Volume :** 6 048 lignes et 14 colonnes
- **Période :** du 1er au 14 juin 2024
- **Périmètre :** trois turbines, 2 016 observations chacune
- **Technologies :** PostgreSQL, SQL, pgAdmin, Visual Studio Code et Power BI

Les unités physiques de `energy_produced`, `wind_speed` et `capacity` ne sont pas définies dans le CSV; aucune unité n’est donc attribuée dans ce rapport.

## 2. Architecture et traitements

1. **Bronze — `public.wind_power` :** ingestion des 14 colonnes de la source. Les champs `date_` et `time_` sont conservés sous forme textuelle à l’ingestion afin de traiter explicitement leur format dans l’étape suivante.
2. **Silver — `public.vw_wind_power_silver` :** nettoyage des espaces, standardisation des valeurs textuelles, conversion de `date_` en `DATE` et conversion du format source `HH-MM-SS` en type `TIME`.
3. **Modèle en étoile :** `fact_wind_power`, `dim_turbine`, `dim_date` et `dim_status` organisent les mesures et les dimensions analytiques.
4. **Gold — `public.vw_wind_power_gold_daily` :** agrégation par date et turbine, avec production totale et moyenne, nombre de mesures, mesures à zéro et observations dont le statut est non opérationnel.
5. **Power BI :** restitution des indicateurs à travers trois pages : Executive Overview, Turbine Performance et Operational Reliability.

## 3. Résultats descriptifs calculés depuis le CSV

| Indicateur | Résultat |
|---|---:|
| Production totale, somme source | 6 847 971,30928 |
| Production totale affichée à deux décimales | 6 847 971,31 |
| Production moyenne par observation | 1 132,27 |
| Maximum d’une observation | 1 999,85 |
| Mesures à production nulle | 563 / 6 048 (9,31 %) |

### Résultats par turbine

| Turbine | Mesures | Production totale (2 décimales) | Moyenne par mesure | Mesures à zéro |
|---|---:|---:|---:|---:|
| Turbine A | 2 016 | 2 329 587,54 | 1 155,55 | 182 |
| Turbine B | 2 016 | 2 257 536,24 | 1 119,81 | 178 |
| Turbine C | 2 016 | 2 260 847,53 | 1 121,45 | 203 |

La somme source conserve jusqu’à cinq décimales. Le schéma préparé pour le modèle en étoile utilise `NUMERIC(15,5)` pour `energy_produced`, afin de préserver cette précision et d’éviter l’arrondi individuel à deux décimales de l’ancien schéma. Le script de validation permet de comparer les totaux entre les faits et Gold.

## 4. Analyse opérationnelle

Les observations à production nulle représentent 9,31 % du dataset. Les comptes sont de 182 mesures pour la turbine A, 178 pour la turbine B et 203 pour la turbine C. Les baisses supérieures à 50 % détectées à l’aide de `LAG()` sont des signaux de variation à investiguer; elles ne constituent pas une preuve de panne. La période de 14 jours ne suffit pas à tirer des conclusions sur la performance annuelle ou sur une cause mécanique.

## 5. Rapport Power BI

Le rapport comprend trois pages complémentaires :

- **Executive Overview :** indicateurs de production totale, production moyenne, mesures à zéro et taux non opérationnel; filtres par date, région et turbine; évolution quotidienne de la production.
- **Turbine Performance :** indicateurs de production totale, moyenne, maximum et part de production; comparaisons entre turbines et évolution quotidienne.
- **Operational Reliability :** nombre et taux de mesures nulles, observations non opérationnelles et taux correspondant; visualisations par turbine et évolution quotidienne des signaux.

Les fichiers du projet Power BI et les captures de ces trois pages sont organisés dans `powerbi/`. Les définitions du rapport référencent `public.vw_wind_power_gold_daily`; cette vue doit donc être disponible dans la source PostgreSQL configurée avant l’actualisation du rapport.

## 6. Qualité, reproductibilité et sécurité

- Les contrôles effectués sur la base de travail ont indiqué 6 048 lignes, 6 048 identifiants distincts, aucune référence orpheline parmi les relations dimensionnelles contrôlées et une égalité des totaux entre la table de faits et la vue Gold.
- Les scripts organisés doivent être exécutés dans l’ordre indiqué dans le README, dans une base de test PostgreSQL adaptée.
- Si `public.wind_power` contient déjà les 6 048 observations, ne pas réimporter le CSV dans cette table.
- `sql/07_security_permissions.sql` est optionnel et modifie des rôles et permissions PostgreSQL; il n’est pas requis pour reproduire le pipeline analytique principal.
- Les scripts publiés ne doivent contenir aucun mot de passe ni secret de connexion.

## 7. Organisation du projet

Le dépôt rassemble les scripts SQL, les données sources, le projet et les captures Power BI, ainsi que le dictionnaire des données et la documentation technique. Cette organisation rend les étapes du traitement repérables et permet de comprendre le passage des données brutes aux indicateurs et aux visualisations.
