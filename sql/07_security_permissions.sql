-- SCRIPT OPTIONNEL D'ADMINISTRATION : ne pas exécuter dans le parcours analytique normal.
-- Exécuter uniquement avec un compte autorisé, connecté à la base visée.
-- Les rôles PostgreSQL sont globaux au serveur. Aucun mot de passe n'est stocké ici.
-- Après création, définir les mots de passe séparément dans pgAdmin si la connexion
-- par mot de passe est souhaitée. Ne jamais publier ces secrets dans Git.

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'wind_admin') THEN
        EXECUTE 'CREATE ROLE wind_admin LOGIN';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'wind_reader') THEN
        EXECUTE 'CREATE ROLE wind_reader LOGIN';
    END IF;

    EXECUTE format('GRANT CONNECT ON DATABASE %I TO wind_admin', current_database());
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO wind_reader', current_database());
END;
$$;

GRANT USAGE, CREATE ON SCHEMA public TO wind_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO wind_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO wind_admin;

GRANT USAGE ON SCHEMA public TO wind_reader;
GRANT SELECT ON TABLE public.vw_wind_power_gold_daily TO wind_reader;

-- Vérification des permissions accordées sur la vue Gold
SELECT grantee, table_schema, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN ('wind_admin', 'wind_reader')
  AND table_name = 'vw_wind_power_gold_daily'
ORDER BY grantee, privilege_type;
