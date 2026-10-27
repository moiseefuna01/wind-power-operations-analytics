-- Analyses avancées et couche Gold pour Power BI.

-- 1. Mesures en baisse de plus de 50 % par rapport à l'observation précédente
-- d'une même turbine. Ce sont des signaux à investiguer, pas des pannes confirmées.
WITH comparaison AS (
    SELECT
        f.production_id,
        dt.turbine_name,
        dd.date_mesure,
        f.heure_mesure,
        f.energy_produced AS production_actuelle,
        LAG(f.energy_produced) OVER (
            PARTITION BY f.turbine_id
            ORDER BY dd.date_mesure, f.heure_mesure, f.production_id
        ) AS production_precedente
    FROM public.fact_wind_power AS f
    JOIN public.dim_turbine AS dt ON f.turbine_id = dt.turbine_id
    JOIN public.dim_date AS dd ON f.date_id = dd.date_id
)
SELECT
    turbine_name,
    date_mesure,
    heure_mesure,
    production_precedente,
    production_actuelle,
    ROUND(
        100.0 * (production_precedente - production_actuelle)
        / NULLIF(production_precedente, 0),
        2
    ) AS baisse_pourcentage
FROM comparaison
WHERE production_precedente > 0
  AND production_actuelle < production_precedente * 0.5
ORDER BY turbine_name, date_mesure, heure_mesure;

-- 2. Synthèse des baisses importantes par turbine
WITH comparaison AS (
    SELECT
        dt.turbine_name,
        f.energy_produced AS production_actuelle,
        LAG(f.energy_produced) OVER (
            PARTITION BY f.turbine_id
            ORDER BY dd.date_mesure, f.heure_mesure, f.production_id
        ) AS production_precedente
    FROM public.fact_wind_power AS f
    JOIN public.dim_turbine AS dt ON f.turbine_id = dt.turbine_id
    JOIN public.dim_date AS dd ON f.date_id = dd.date_id
),
baisses AS (
    SELECT
        turbine_name,
        production_actuelle,
        100.0 * (production_precedente - production_actuelle)
            / NULLIF(production_precedente, 0) AS baisse_pct
    FROM comparaison
    WHERE production_precedente > 0
      AND production_actuelle < production_precedente * 0.5
)
SELECT
    turbine_name,
    COUNT(*) AS nombre_baisses,
    COUNT(*) FILTER (WHERE production_actuelle = 0) AS baisses_vers_zero,
    ROUND(AVG(baisse_pct), 2) AS baisse_moyenne_pct,
    ROUND(MAX(baisse_pct), 2) AS baisse_maximale_pct
FROM baisses
GROUP BY turbine_name
ORDER BY nombre_baisses DESC;

-- 3. Gold : agrégation journalière par turbine et région.
-- Conserver la précision numérique ici; formater à 2 décimales dans Power BI / les requêtes.
CREATE OR REPLACE VIEW public.vw_wind_power_gold_daily AS
SELECT
    dd.date_mesure,
    dt.turbine_name,
    dt.region,
    SUM(f.energy_produced) AS production_totale,
    AVG(f.energy_produced) AS production_moyenne,
    COUNT(*) AS nombre_mesures,
    COUNT(*) FILTER (WHERE f.energy_produced = 0) AS mesures_a_zero,
    COUNT(*) FILTER (
        WHERE ds.status NOT IN ('ONLINE', 'OPERATIONAL')
    ) AS observations_non_operationnelles
FROM public.fact_wind_power AS f
JOIN public.dim_turbine AS dt ON f.turbine_id = dt.turbine_id
JOIN public.dim_date AS dd ON f.date_id = dd.date_id
JOIN public.dim_status AS ds ON f.status_id = ds.status_id
GROUP BY dd.date_mesure, dt.turbine_name, dt.region;

SELECT *
FROM public.vw_wind_power_gold_daily
ORDER BY date_mesure, turbine_name;
