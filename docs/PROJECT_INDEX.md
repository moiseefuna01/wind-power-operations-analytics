# Index du projet

## Parcours de lecture

1. `../README.md` — objectif, périmètre, architecture et résultats descriptifs.
2. `../data/wind_power_data.csv` — données sources (6 048 observations, 14 colonnes).
3. `../sql/00_create_raw_table.sql` — table d'ingestion Bronze.
4. `../sql/01_bronze_exploration.sql` — exploration de la source.
5. `../sql/02_data_quality.sql` — contrôles de qualité et contraintes.
6. `../sql/03_create_silver_view.sql` — standardisation et conversion des types.
7. `../sql/04_create_star_schema.sql` — dimensions et table de faits.
8. `../sql/05_analytics_kpis.sql` — indicateurs et comparaisons.
9. `../sql/06_advanced_analysis_and_gold.sql` — analyses chronologiques et agrégation Gold.
10. `../sql/08_validation_read_only.sql` — contrôles de validation en lecture seule.
11. `../powerbi/README.md` — description et captures des trois pages Power BI.
12. `data_dictionary.md` et `technical_report.md` — définitions des champs et rapport technique.
13. `../sql/archive/legacy_original_script_sanitized_reference.sql` — référence historique assainie; ne pas exécuter en bloc.

## Ordre d'exécution

Dans une base de test vierge : `00` → import CSV → `01` → `02` → `03` → `04` → `05` → `06` → `08`.

`07_security_permissions.sql` est optionnel et distinct du parcours analytique standard, car il modifie les rôles et permissions PostgreSQL.

## Validation

Les contrôles effectués dans l'environnement de travail ont confirmé les volumes et indicateurs communiqués pour la base initiale. La reproductibilité intégrale des scripts organisés doit néanmoins être confirmée par une exécution complète dans une base de test dédiée.
