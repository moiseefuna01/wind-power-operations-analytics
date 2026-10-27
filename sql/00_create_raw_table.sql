-- Wind Power Operations Analytics
-- Bronze : table d'ingestion conforme aux 14 en-têtes réels du CSV.
-- Dans une nouvelle base, exécuter ce script avant l'importation.
-- Si public.wind_power existe déjà, CREATE TABLE IF NOT EXISTS ne la remplace pas.
-- Ne réimporter le CSV que si la table est vide ou si vous avez vérifié son état.

CREATE TABLE IF NOT EXISTS public.wind_power (
    production_id          BIGINT PRIMARY KEY,
    date_                  VARCHAR(10) NOT NULL,
    time_                  VARCHAR(8) NOT NULL,
    turbine_name           VARCHAR(100) NOT NULL,
    capacity               NUMERIC(12,2),
    location_name          VARCHAR(100),
    latitude               NUMERIC(10,6),
    longitude              NUMERIC(10,6),
    region                 VARCHAR(100),
    status                 VARCHAR(100),
    responsible_department VARCHAR(100),
    wind_speed             NUMERIC(12,5),
    wind_direction         VARCHAR(10),
    energy_produced        NUMERIC(15,5)
);

-- Contrôle post-import. Pour le dataset fourni, le résultat attendu est 6 048.
SELECT COUNT(*) AS total_lignes
FROM public.wind_power;
