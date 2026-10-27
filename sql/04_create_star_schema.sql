-- Modèle dimensionnel en étoile.
-- À exécuter après la création de vw_wind_power_silver.
-- Ce script est conçu pour une installation propre du projet.
-- Les types numériques conservent les 5 décimales du CSV.

CREATE TABLE IF NOT EXISTS public.dim_turbine (
    turbine_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    turbine_name VARCHAR(100) NOT NULL UNIQUE,
    capacity     NUMERIC(12,2),
    location_name VARCHAR(100),
    region       VARCHAR(100),
    latitude     NUMERIC(9,6),
    longitude    NUMERIC(9,6)
);

CREATE TABLE IF NOT EXISTS public.dim_date (
    date_id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_mesure  DATE NOT NULL UNIQUE,
    jour         INTEGER NOT NULL,
    mois         INTEGER NOT NULL,
    annee        INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS public.dim_status (
    status_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status    VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS public.fact_wind_power (
    fact_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    production_id  BIGINT NOT NULL UNIQUE,
    turbine_id     INTEGER NOT NULL REFERENCES public.dim_turbine(turbine_id),
    date_id        INTEGER NOT NULL REFERENCES public.dim_date(date_id),
    status_id      INTEGER NOT NULL REFERENCES public.dim_status(status_id),
    heure_mesure   TIME,
    wind_speed     NUMERIC(12,5),
    wind_direction VARCHAR(10),
    energy_produced NUMERIC(15,5) NOT NULL
);

-- Charger / actualiser les dimensions. Ces opérations sont idempotentes
-- pour les clés uniques du jeu de données.
INSERT INTO public.dim_turbine
    (turbine_name, capacity, location_name, region, latitude, longitude)
SELECT DISTINCT ON (turbine_name)
    turbine_name, capacity, location_name, region, latitude, longitude
FROM public.vw_wind_power_silver
WHERE turbine_name IS NOT NULL
ORDER BY turbine_name, capacity DESC, region
ON CONFLICT (turbine_name) DO UPDATE SET
    capacity = EXCLUDED.capacity,
    location_name = EXCLUDED.location_name,
    region = EXCLUDED.region,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude;

INSERT INTO public.dim_date (date_mesure, jour, mois, annee)
SELECT DISTINCT
    date_mesure,
    EXTRACT(DAY FROM date_mesure)::INTEGER,
    EXTRACT(MONTH FROM date_mesure)::INTEGER,
    EXTRACT(YEAR FROM date_mesure)::INTEGER
FROM public.vw_wind_power_silver
WHERE date_mesure IS NOT NULL
ON CONFLICT (date_mesure) DO UPDATE SET
    jour = EXCLUDED.jour,
    mois = EXCLUDED.mois,
    annee = EXCLUDED.annee;

INSERT INTO public.dim_status (status)
SELECT DISTINCT status
FROM public.vw_wind_power_silver
WHERE status IS NOT NULL
ON CONFLICT (status) DO NOTHING;

-- Charger / actualiser la table de faits à partir des dimensions.
-- UNIQUE(production_id) empêche de dupliquer une observation lors d'une relance.
INSERT INTO public.fact_wind_power (
    production_id, turbine_id, date_id, status_id,
    heure_mesure, wind_speed, wind_direction, energy_produced
)
SELECT
    s.production_id,
    dt.turbine_id,
    dd.date_id,
    ds.status_id,
    s.heure_mesure,
    s.wind_speed,
    s.wind_direction,
    s.energy_produced
FROM public.vw_wind_power_silver AS s
JOIN public.dim_turbine AS dt ON s.turbine_name = dt.turbine_name
JOIN public.dim_date AS dd ON s.date_mesure = dd.date_mesure
JOIN public.dim_status AS ds ON s.status = ds.status
ON CONFLICT (production_id) DO UPDATE SET
    turbine_id = EXCLUDED.turbine_id,
    date_id = EXCLUDED.date_id,
    status_id = EXCLUDED.status_id,
    heure_mesure = EXCLUDED.heure_mesure,
    wind_speed = EXCLUDED.wind_speed,
    wind_direction = EXCLUDED.wind_direction,
    energy_produced = EXCLUDED.energy_produced;

-- Contrôle du grain
SELECT
    COUNT(*) AS nombre_lignes,
    COUNT(DISTINCT production_id) AS productions_distinctes,
    COUNT(DISTINCT (turbine_id, date_id, heure_mesure)) AS combinaisons_turbine_date_heure
FROM public.fact_wind_power;
