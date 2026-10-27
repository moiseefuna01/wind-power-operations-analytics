-- BRONZE : exploration de la source brute
-- Requêtes en lecture seule.

-- 1. Volume
SELECT COUNT(*) AS total_lignes
FROM public.wind_power;

-- 2. Aperçu des observations
SELECT *
FROM public.wind_power
ORDER BY production_id
LIMIT 10;

-- 3. Catégories métier
SELECT DISTINCT turbine_name
FROM public.wind_power
ORDER BY turbine_name;

SELECT DISTINCT region
FROM public.wind_power
ORDER BY region;

SELECT DISTINCT status
FROM public.wind_power
ORDER BY status;

-- 4. Couverture temporelle
SELECT
    MIN(date_::DATE) AS premiere_date,
    MAX(date_::DATE) AS derniere_date,
    COUNT(DISTINCT date_::DATE) AS nombre_jours_distincts
FROM public.wind_power;

-- 5. Répartition par turbine et statut
SELECT
    turbine_name,
    status,
    COUNT(*) AS nombre_observations
FROM public.wind_power
GROUP BY turbine_name, status
ORDER BY turbine_name, nombre_observations DESC;
