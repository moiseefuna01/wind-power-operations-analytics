-- SILVER : nettoyage léger, typage et standardisation.
-- La source Bronze reste inchangée. Le CSV encode time_ comme HH-MM-SS.
-- REPLACE puis ::TIME évitent la conversion via TIMESTAMPTZ et un possible effet de fuseau.

CREATE OR REPLACE VIEW public.vw_wind_power_silver AS
SELECT
    production_id,
    BTRIM(date_)::DATE AS date_mesure,
    REPLACE(BTRIM(time_), '-', ':')::TIME AS heure_mesure,
    UPPER(BTRIM(turbine_name)) AS turbine_name,
    capacity,
    BTRIM(location_name) AS location_name,
    latitude,
    longitude,
    UPPER(BTRIM(region)) AS region,
    UPPER(BTRIM(status)) AS status,
    BTRIM(responsible_department) AS responsible_department,
    wind_speed,
    UPPER(BTRIM(wind_direction)) AS wind_direction,
    energy_produced
FROM public.wind_power;

-- Vérification rapide
SELECT *
FROM public.vw_wind_power_silver
ORDER BY production_id
LIMIT 10;
