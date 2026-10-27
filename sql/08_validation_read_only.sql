-- Audit final en lecture seule : aucun INSERT / UPDATE / DELETE / DDL.

-- 1. Volumes entre les couches
SELECT
    (SELECT COUNT(*) FROM public.wind_power) AS lignes_bronze,
    (SELECT COUNT(*) FROM public.vw_wind_power_silver) AS lignes_silver,
    (SELECT COUNT(*) FROM public.fact_wind_power) AS lignes_fact,
    (SELECT COUNT(*) FROM public.vw_wind_power_gold_daily) AS lignes_gold;

-- 2. Identifiants dupliqués dans la table de faits (aucune ligne attendue)
SELECT production_id, COUNT(*) AS occurrences
FROM public.fact_wind_power
GROUP BY production_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

-- 3. Références orphelines dans la table de faits (valeurs attendues : 0)
SELECT
    COUNT(*) AS nombre_faits,
    COUNT(*) FILTER (WHERE dt.turbine_id IS NULL) AS faits_sans_turbine,
    COUNT(*) FILTER (WHERE dd.date_id IS NULL) AS faits_sans_date,
    COUNT(*) FILTER (WHERE ds.status_id IS NULL) AS faits_sans_statut
FROM public.fact_wind_power AS f
LEFT JOIN public.dim_turbine AS dt ON f.turbine_id = dt.turbine_id
LEFT JOIN public.dim_date AS dd ON f.date_id = dd.date_id
LEFT JOIN public.dim_status AS ds ON f.status_id = ds.status_id;

-- 4. Contrôles qualité simples dans la source
SELECT
    COUNT(*) AS nombre_lignes,
    COUNT(*) FILTER (WHERE date_ IS NULL OR BTRIM(date_) = '') AS dates_manquantes,
    COUNT(*) FILTER (WHERE time_ IS NULL OR BTRIM(time_) = '') AS heures_manquantes,
    COUNT(*) FILTER (WHERE turbine_name IS NULL OR BTRIM(turbine_name) = '') AS turbines_manquantes,
    COUNT(*) FILTER (WHERE energy_produced IS NULL) AS productions_manquantes,
    COUNT(*) FILTER (WHERE wind_speed < 0) AS vitesses_negatives,
    COUNT(*) FILTER (WHERE energy_produced < 0) AS productions_negatives,
    COUNT(*) FILTER (WHERE capacity <= 0) AS capacites_non_positives
FROM public.wind_power;

-- 5. Réconciliation de la somme à 5 décimales (le CSV conserve jusqu'à 5 décimales)
SELECT
    ROUND((SELECT SUM(energy_produced) FROM public.wind_power), 5) AS total_bronze,
    ROUND((SELECT SUM(energy_produced) FROM public.fact_wind_power), 5) AS total_fact,
    ROUND((SELECT SUM(production_totale) FROM public.vw_wind_power_gold_daily), 5) AS total_gold;

-- 6. Totaux par turbine pour la comparaison avec les KPI du rapport
SELECT
    dt.turbine_name,
    COUNT(*) AS nombre_mesures,
    ROUND(SUM(f.energy_produced), 2) AS production_totale,
    ROUND(AVG(f.energy_produced), 2) AS production_moyenne,
    COUNT(*) FILTER (WHERE f.energy_produced = 0) AS mesures_a_zero
FROM public.fact_wind_power AS f
JOIN public.dim_turbine AS dt ON f.turbine_id = dt.turbine_id
GROUP BY dt.turbine_name
ORDER BY dt.turbine_name;
