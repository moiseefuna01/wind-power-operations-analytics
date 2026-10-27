-- SILVER : contrôles de qualité sur la source brute
-- Les résultats signalent des points à examiner; ils ne corrigent pas les données.

-- 1. Valeurs absentes ou chaînes vides sur les champs essentiels
SELECT
    COUNT(*) AS total_lignes,
    COUNT(*) FILTER (WHERE production_id IS NULL) AS id_manquant,
    COUNT(*) FILTER (WHERE date_ IS NULL OR BTRIM(date_) = '') AS date_manquante,
    COUNT(*) FILTER (WHERE time_ IS NULL OR BTRIM(time_) = '') AS heure_manquante,
    COUNT(*) FILTER (WHERE turbine_name IS NULL OR BTRIM(turbine_name) = '') AS turbine_manquante,
    COUNT(*) FILTER (WHERE status IS NULL OR BTRIM(status) = '') AS statut_manquant,
    COUNT(*) FILTER (WHERE wind_speed IS NULL) AS vitesse_vent_manquante,
    COUNT(*) FILTER (WHERE energy_produced IS NULL) AS production_manquante
FROM public.wind_power;

-- 2. Identifiants source en double (normalement aucune ligne)
SELECT production_id, COUNT(*) AS occurrences
FROM public.wind_power
GROUP BY production_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC, production_id;

-- 3. Doublons potentiels au grain métier date-heure-turbine
SELECT
    date_,
    time_,
    turbine_name,
    COUNT(*) AS occurrences
FROM public.wind_power
GROUP BY date_, time_, turbine_name
HAVING COUNT(*) > 1
ORDER BY occurrences DESC, date_, time_, turbine_name;

-- 4. Contrôles physiques simples
SELECT *
FROM public.wind_power
WHERE wind_speed < 0
   OR energy_produced < 0
   OR capacity IS NULL
   OR capacity <= 0
ORDER BY production_id;

-- 5. Production nulle et distribution
SELECT
    COUNT(*) AS total_mesures,
    COUNT(*) FILTER (WHERE energy_produced = 0) AS mesures_a_zero,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE energy_produced = 0)
        / NULLIF(COUNT(*), 0),
        2
    ) AS taux_mesures_a_zero_pct
FROM public.wind_power;

-- 6. Cohérence statut-production : heuristique à examiner, pas preuve de panne
SELECT
    production_id, date_, time_, turbine_name, status, energy_produced
FROM public.wind_power
WHERE (
        UPPER(BTRIM(status)) IN
            ('FAULT', 'INSPECTION', 'OFFLINE',
             'PREVENTIVE MAINTENANCE', 'REACTIVE MAINTENANCE')
        AND energy_produced > 0
      )
   OR (
        UPPER(BTRIM(status)) IN ('ONLINE', 'OPERATIONAL')
        AND energy_produced = 0
      )
ORDER BY date_, time_, turbine_name;

-- 7. Espaces superflus / standardisation des champs texte
SELECT
    COUNT(*) FILTER (WHERE turbine_name <> BTRIM(turbine_name)) AS turbines_avec_espaces,
    COUNT(*) FILTER (WHERE region <> BTRIM(region)) AS regions_avec_espaces,
    COUNT(*) FILTER (WHERE status <> BTRIM(status)) AS statuts_avec_espaces,
    COUNT(*) FILTER (WHERE responsible_department <> BTRIM(responsible_department))
        AS departements_avec_espaces
FROM public.wind_power;

SELECT
    status AS valeur_originale,
    UPPER(BTRIM(status)) AS valeur_normalisee,
    COUNT(*) AS nombre_observations
FROM public.wind_power
GROUP BY status, UPPER(BTRIM(status))
ORDER BY valeur_originale;
