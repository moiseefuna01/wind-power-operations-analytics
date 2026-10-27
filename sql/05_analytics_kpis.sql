-- KPI et analyses SQL sur les couches Silver / modèle en étoile.

-- 1. Production globale
SELECT
    COUNT(*) AS nombre_mesures,
    ROUND(SUM(energy_produced), 2) AS production_totale,
    ROUND(AVG(energy_produced), 2) AS production_moyenne_par_mesure,
    ROUND(MIN(energy_produced), 2) AS production_minimale,
    ROUND(MAX(energy_produced), 2) AS production_maximale
FROM public.vw_wind_power_silver;

-- 2. Comparaison des turbines
SELECT
    turbine_name,
    COUNT(*) AS nombre_mesures,
    ROUND(SUM(energy_produced), 2) AS production_totale,
    ROUND(AVG(energy_produced), 2) AS production_moyenne,
    COUNT(*) FILTER (WHERE energy_produced = 0) AS mesures_a_zero,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE energy_produced = 0)
        / NULLIF(COUNT(*), 0),
        2
    ) AS taux_zero_pct
FROM public.vw_wind_power_silver
GROUP BY turbine_name
ORDER BY production_totale DESC;

-- 3. Analyse régionale
SELECT
    region,
    COUNT(*) AS nombre_observations,
    COUNT(DISTINCT turbine_name) AS nombre_turbines,
    ROUND(SUM(energy_produced), 2) AS production_totale,
    ROUND(AVG(energy_produced), 2) AS production_moyenne
FROM public.vw_wind_power_silver
GROUP BY region
ORDER BY production_totale DESC;

-- 4. Répartition des statuts par turbine
SELECT
    turbine_name,
    status,
    COUNT(*) AS nombre_observations,
    ROUND(
        100.0 * COUNT(*) /
        NULLIF(SUM(COUNT(*)) OVER (PARTITION BY turbine_name), 0),
        2
    ) AS part_observations_pct
FROM public.vw_wind_power_silver
GROUP BY turbine_name, status
ORDER BY turbine_name, nombre_observations DESC;

-- 5. Proportion d'observations avec un statut autre que ONLINE / OPERATIONAL.
-- Ce ratio porte sur les observations, pas sur une durée d'indisponibilité réelle.
SELECT
    turbine_name,
    COUNT(*) AS nombre_observations,
    COUNT(*) FILTER (
        WHERE status NOT IN ('ONLINE', 'OPERATIONAL')
    ) AS observations_non_operationnelles,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE status NOT IN ('ONLINE', 'OPERATIONAL')
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS part_non_operationnelle_pct
FROM public.vw_wind_power_silver
GROUP BY turbine_name
ORDER BY part_non_operationnelle_pct DESC;

-- 6. Production quotidienne
SELECT
    date_mesure,
    COUNT(*) AS nombre_observations,
    ROUND(SUM(energy_produced), 2) AS production_totale,
    ROUND(AVG(energy_produced), 2) AS production_moyenne
FROM public.vw_wind_power_silver
GROUP BY date_mesure
ORDER BY date_mesure;

-- 7. Production selon la classe de vitesse du vent
WITH mesures_classees AS (
    SELECT
        CASE
            WHEN wind_speed < 5 THEN '< 5'
            WHEN wind_speed < 10 THEN '5 à < 10'
            WHEN wind_speed < 15 THEN '10 à < 15'
            ELSE '>= 15'
        END AS classe_vent,
        CASE
            WHEN wind_speed < 5 THEN 1
            WHEN wind_speed < 10 THEN 2
            WHEN wind_speed < 15 THEN 3
            ELSE 4
        END AS ordre_classe,
        energy_produced
    FROM public.vw_wind_power_silver
)
SELECT
    classe_vent,
    COUNT(*) AS nombre_mesures,
    ROUND(AVG(energy_produced), 2) AS production_moyenne
FROM mesures_classees
GROUP BY classe_vent, ordre_classe
ORDER BY ordre_classe;

-- 8. Rang et contribution à la production
WITH production AS (
    SELECT turbine_name, SUM(energy_produced) AS production_totale
    FROM public.vw_wind_power_silver
    GROUP BY turbine_name
)
SELECT
    turbine_name,
    ROUND(production_totale, 2) AS production_totale,
    RANK() OVER (ORDER BY production_totale DESC) AS rang,
    ROUND(
        100.0 * production_totale / NULLIF(SUM(production_totale) OVER (), 0),
        2
    ) AS contribution_pct
FROM production
ORDER BY rang;
