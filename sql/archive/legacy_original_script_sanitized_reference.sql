-- ARCHIVE DE REFERENCE UNIQUEMENT — NE PAS EXECUTER COMME SCRIPT DE DEPLOIEMENT.
-- Copie assainie du script SQL de travail historique, conservée pour tracer les requêtes initiales.
-- Les scripts maintenus pour installation/reproduction sont dans ../00 à ../08.
-- Ce script historique conserve des objets et opérations non idempotents et des choix de types antérieurs.
-- Les mots de passe originaux ont été retirés; ne jamais réinsérer de secret dans ce fichier.

--PROJET PRATIQUE DATA ANALYTICS
--Wind Power Operations Analytics

--Objectif du projet
--Mener une analyse SQL structurée de données de production éolienne : comprendre les données, contrôler leur qualité, préparer une couche analytique fiable, calculer des indicateurs de performance et produire des résultats interprétables par une équipe opérationnelle.

--Livrable attendu
--Un ensemble de requêtes PostgreSQL documentées, une démarche Bronze → Silver → Gold, des KPI métier défendables et une vue de reporting exploitable ultérieurement dans Power BI.

create table wind_power(
production_id int primary key,
date_ varchar (100),
time_ varchar (100),
turbine_name varchar(100),
capacity int,
location_name varchar (100),
latitude float,
longitude float,
region varchar (100),
status varchar (100),
responsible_department varchar (100),
wind_speed float,
wind_direction varchar (100),
energy_produced float
);

--PARTIE A — BRONZE : EXPLORATION

--1. Controle du volume de données
select count (*) as total_lignes  from wind_power; --requete etablissant le volume réel de la table wind_power après importation.

--2. Inspection des données : examen des premières observations
select * from wind_power limit 10;

--3. Perimètre metier : identification des catégories distinctes
--A. Identification des éoliennes présentes
select distinct turbine_name from wind_power order by turbine_name;
--B. Identification des régions représentées
select distinct region from wind_power order by region;
--C. Identification des états opérationnels enregistrés
select distinct status from wind_power order by status;

--4. Couverture temporelle : determination de la periode couverte par les données ainsi que le nombre de date distinctes
select min(date_) as premiere_date, 
	max(date_) as derniere_date, 
	count(distinct date_) as nombre_jours_distincts
	from wind_power;
	
-- PARTIE B — SILVER : QUALITÉ ET NETTOYAGE

--5. Valeurs manquantes : recherche des valeurs manquantes dans les colonnes essentielles
select
	count(*) as total_lignes,
	count(production_id) as id_non_null,
	count(date_) as date_non_null,
	count(time_) as heure_non_null,
	count (turbine_name) as turbine_non_null,
	count (status) as statut_non_null,
	count (wind_speed) as vent_non_null,
	count (energy_produced) as energie_non_null
	from wind_power;
select count(*) as ligne_concernees
from wind_power
where wind_speed is null or energy_produced is null;

--6. Détection des doublons
--A. Pour production_id
select 
	production_id, count(*) as nombre_occurences --Afficher chaque identifiant et le nombre de fois qu'il apparait
	from wind_power
	group by production_id --Regrouper les lignes qui possèdent le meme identifiant : chaque groupe correspond à un identifiant distinct
	having count(*)>1 --Filtrer les groupes après leur formation : Ne conserver que ceux qui contiennent au moins deux lignes
	order by nombre_occurences desc; --Trier les groupes du plus grand nombre d'occurence au plus petit
--B. Verification des doublons métier potentiels : pour date_, time_,turbine_name,location_name & region
select
	date_,
	time_,
	turbine_name,
	location_name,
	region,
	count(*) as nombre_occurences
	from wind_power
	group by
	date_,
	time_,
	turbine_name,
	location_name,
	region
	having count(*)>1
	order by nombre_occurences desc;
	
--7. Valeurs aberrantes : Rechercher les vitesses de vent négatives, énergies négatives et capacités nulles ou négatives
select * from wind_power
where wind_speed<0 or capacity <=0 or energy_produced < 0;

--8. Cohérence statut–production : vérification de la cohérence entre l'état et la production
select 
	production_id,
	date_,
	time_,
	turbine_name,
	status,
	energy_produced
	from wind_power
	where (
		status in ('Fault','Inspection','Offline','Preventive Maintenance','Reactive Maintenance')
		and energy_produced > 0
	)
	or (status='Online'
	and energy_produced=0
	)
	order by date_,time_,turbine_name;
	
--9. Standardisation des textes : Normalisation des valeurs textuelles
select count(*) as total_lignes,
	count(*) filter(
		where turbine_name <> trim (turbine_name)
	) as turbines_avec_espaces,
	count(*) filter(
		where region <> trim (region)
	) as regions_avec_espaces,
	count(*) filter (
		where status <> trim (status)
	
	) as statuts_avec_espaces,
	count(*)filter(
		where responsible_department <> trim(responsible_department)
		) as departements_avec_espaces
from wind_power
select
	status as valeur_originale,
	upper(trim(status)) as valeur_normalisee,
	count(*) as nombre_observations
	from wind_power
	group by 
	valeur_originale, valeur_normalisee
	order by valeur_originale;
	
--10.  Couche Silver : création de la vue nettoyée 
create or replace view vw_wind_power_silver as 
select
	production_id,
	date_::date as date_mesure,
	to_timestamp(time_,'HH24-MI-SS')::time as heure_mesure,
	upper(trim(turbine_name)) as turbine_name,
	capacity,
	trim(location_name) as location_name,
	latitude,
	longitude,
	upper(trim(region)) as region,
	upper(trim(status)) as status,
	trim(responsible_department) as responsible_department,
	wind_speed,
	upper(trim(wind_direction)) as wind_direction,
	energy_produced
from wind_power
select * from vw_wind_power_silver limit 10;

--PARTIE C — GOLD : ANALYSE ET KPI

--11. Production globale : calcul de la production énergétique globale
select
	count(*) as nombre_mesures,
	round(sum(energy_produced)::numeric,2) as production_totale,
	round(avg(energy_produced)::numeric,2) as production_moyenne,
	round(min(energy_produced)::numeric,2) as production_minimale,
	round(max(energy_produced)::numeric,2) as production_maximale
from vw_wind_power_silver;
select * from vw_wind_power_silver where energy_produced = 
										(select min(energy_produced)
										from vw_wind_power_silver);

--12.  Comparaison des turbines 
select
	turbine_name,
	count(*) as nombre_mesures,
	count(distinct region) as nombre_regions,
	round(sum(energy_produced)::numeric,2) as production_totale,
	round(avg(energy_produced)::numeric,2) as production_moyenne,
	count(*) filter (
		where energy_produced = 0
	) as mesures_zero
from vw_wind_power_silver
group by turbine_name
order by production_totale desc;

--13.  Performance régionale : Analyse de la production par région
select
	region,
	count(*) as nombre_observations,
	count(distinct turbine_name) as nombre_turbines,
	round(sum(energy_produced)::numeric,2) as production_totale,
	round(avg(energy_produced)::numeric,2) as production_moyenne
from vw_wind_power_silver
group by region
order by production_totale desc;

--14. Indisponibilité observée : Analyser les états opérationnels et distinguer le ratio d'isponibilité temporelle réelle.
select 
	turbine_name,
	status,
	count(*) as nombre_observations,
	round(
		100.0*count(*)
		/sum(count(*)) over (
			partition by turbine_name
		),
		2
	) as part_observations_pct
from vw_wind_power_silver
group by
	turbine_name,
	status
order by 
	turbine_name,
	part_observations_pct desc;
--Proportion globale des observations non opérationnelles
select 
	turbine_name,
	count(*) as nombre_observations,
	count(*) filter(
		where upper(trim(status)) <> 'ONLINE'
	) as observations_non_online,
	round(
		100.0 * count(*) filter (
			where upper(trim(status)) <> 'ONLINE'
		) / count (*),2
	) as part_non_online_pct
from vw_wind_power_silver
group by turbine_name
order by part_non_online_pct desc

--15. Production quotidienne : Calcul de la production totale et moyenne par date, puis classer les journées par production décroissante.
select
	date_mesure,
	count(*) as nombre_observations,
	round(sum(energy_produced)::numeric,2) as energie_totale,
	round(avg(energy_produced)::numeric,2) as energie_moyenne
	from vw_wind_power_silver
group by date_mesure
order by energie_totale desc;

--16. Analyser la production selon la vitesse du vent 
SELECT
	CASE
	WHEN wind_speed < 5 THEN '< 5'
 	WHEN wind_speed < 10 THEN '5 à < 10'
 	WHEN wind_speed < 15 THEN '10 à < 15'
 	ELSE '>= 15'
 	END AS classe_vent,
 	COUNT(*) AS nombre_mesures,
 	ROUND(AVG(energy_produced), 2) AS production_moyenne
FROM fact_wind_power
GROUP BY 1
ORDER BY 1;
   	
--17. Classement des turbines et contribution à la production
WITH production AS (
 SELECT dt.turbine_name,
 SUM(f.energy_produced) AS production_totale
 FROM fact_wind_power f
 JOIN dim_turbine dt ON f.turbine_id = dt.turbine_id
 GROUP BY dt.turbine_name
)
SELECT turbine_name,
 ROUND(production_totale, 2) AS production_totale,
 RANK() OVER (ORDER BY production_totale DESC) AS rang,
 ROUND(100.0 * production_totale /
 NULLIF(SUM(production_totale) OVER (), 0), 2)
 AS contribution_pct
 FROM production
ORDER BY rang;

--PARTIE D — SQL AVANCÉ ET REPORTING

--18. Modélisation en étoile et jointures SQL
--A. Vérification de grain des données
select
	 count(*) as nombre_lignes,
	 count(distinct production_id) as identifiants_distincts,
	 count(distinct (turbine_name, date_mesure,heure_mesure))
	 as combinaisons_turbine_date_heure
	from vw_wind_power_silver
--B. Vérification des dimensions
select
	count(distinct turbine_name) as nombre_turbines,
	count(distinct date_mesure) as nombre_dates,
	count(distinct status) as nombre_status,
	count(distinct region) as nombre_regions
from vw_wind_power_silver
select distinct
	turbine_name,
	capacity,
	location_name,
	region,
	latitude,
	longitude
from vw_wind_power_silver
order by turbine_name;
--C. Création des tables de dimensions : turbine, date & statut
--Table dimension turbine
create table dim_turbine(
	turbine_id int generated always as identity primary key,
	turbine_name varchar(100),
	capacity int,
	location_name varchar(100),
	region varchar(100),
	latitude double precision,
	longitude double precision		
);
--Table dimension date
create table dim_date(
	date_id int primary key,
	date_mesure date unique not null,
	jour int,
	mois int,
	annee int
);
--Table dimension statut
create table dim_status(
	status_id int generated always as identity primary key,
	status varchar (100) unique not null
);
select * from dim_turbine;
select * from dim_date;
select* from dim_status;
--C. Insertion des données dans les tables de dimensions
insert into dim_turbine(
	turbine_name,
	capacity,
	location_name,
	region,
	latitude,
	longitude
)
select distinct
	turbine_name,
	capacity,
	location_name,
	region,
	latitude,
	longitude
from vw_wind_power_silver
where turbine_name is not null;
select * from dim_turbine
order by turbine_id;

insert into dim_date(
	date_id,
	date_mesure,
	jour,
	mois,
	annee
)
select
	row_number() over (order by date_mesure)::int as date_id,
	date_mesure,
	extract(day from date_mesure)::int as jour,
	extract(month from date_mesure)::int as mois,
	extract(year from date_mesure)::int as annee
from(
	select distinct date_mesure
	from vw_wind_power_silver
	where date_mesure is not null) as dates;
select * from dim_date
order by date_mesure;

insert into dim_status(status)
select distinct status
from vw_wind_power_silver where status is not null;
select * from dim_status
order by status_id;
--D. Vérification de la structure du dataset pour créaction éventuelle de la table de fait
select
	table_name,
	column_name,
	data_type,
	is_nullable
from information_schema.columns
where table_schema='public'
	and table_name in (
		'dim_turbine',
		'dim_date',
		'dim_status'
	)
order by table_name, ordinal_position;
--E. Création de la table de faits
create table fact_wind_power(
	fact_id bigint generated always as identity primary key,
	production_id bigint,
	turbine_id int not null
		references dim_turbine(turbine_id),
	date_id int not null
		references dim_date(date_id),
	status_id int not null
		references dim_status(status_id),
	heure_mesure time,
	wind_speed numeric (10,2),
	wind_direction numeric(10,2),
	energy_produced numeric(12,2)
);
select * from fact_wind_power;

alter table fact_wind_power
alter column wind_direction type varchar(100);
select column_name,
	data_type,
	character_maximum_length
from information_schema.columns
where table_name='fact_wind_power'
	and column_name='wind_direction'
--F. Vérification de correspondances entre les tables
SELECT
    COUNT(*) AS observations_silver,
    COUNT(dt.turbine_id) AS correspondances_turbine,
    COUNT(dd.date_id) AS correspondances_date,
    COUNT(ds.status_id) AS correspondances_statut,
    COUNT(*) FILTER (
        WHERE dt.turbine_id IS NULL
           OR dd.date_id IS NULL
           OR ds.status_id IS NULL
    ) AS correspondances_manquantes
FROM vw_wind_power_silver s
LEFT JOIN dim_turbine dt
    ON s.turbine_name = dt.turbine_name
LEFT JOIN dim_date dd
    ON s.date_mesure = dd.date_mesure
LEFT JOIN dim_status ds
    ON s.status = ds.status;
--G. Insertion des données dans la table de faits
insert into fact_wind_power(
	production_id,
	turbine_id,
	date_id,
	status_id,
	heure_mesure,
	wind_speed,
	wind_direction,
	energy_produced
)
select
	s.production_id,
	dt.turbine_id,
	dd.date_id,
	ds.status_id,
	s.heure_mesure::time,
	s.wind_speed,
	s.wind_direction,
	s.energy_produced
from vw_wind_power_silver s
inner join dim_turbine dt
	on s.turbine_name = dt.turbine_name
INNER JOIN dim_date dd
    ON s.date_mesure = dd.date_mesure
INNER JOIN dim_status ds
    ON s.status = ds.status;
select * from fact_wind_power
order by fact_id;

select
	count(*) as nombre_lignes,
	count(distinct production_id) as productions_distinctes,
	count(distinct turbine_id) as turbines_distinctes,
	count(distinct date_id) as dates_distinctes,
	count(distinct status_id) as statuts_distincts
from fact_wind_power;

select
	production_id,
	count(*) as nombre_occurences
from fact_wind_power
group by production_id
having count(*)>1
order by nombre_occurences desc,
production_id limit 20;

select
	fact_id,
	production_id,
	turbine_id,
	date_id,
	status_id,
	heure_mesure,
	wind_speed,
	wind_direction,
	energy_produced
from fact_wind_power
where production_id in (1,2,3)
order by production_id, fact_id;

create table fact_wind_power_backup as 
select *
from fact_wind_power;

begin;
delete from fact_wind_power f
using fact_wind_power d
where f.production_id = d.production_id
	and f.fact_id > d.fact_id;
commit
select
	count(*) as nombre_lignes,
	count(distinct production_id) as productions_distinctes
from fact_wind_power;
select * from fact_wind_power
order by fact_id;
select *from dim_turbine;
--H. Production par turbine et région
select
	dt.turbine_name,
	dt.region,
	count(*) as nombre_mesures,
	round(sum(f.energy_produced),2) as production_totale,
	round(avg(f.energy_produced),2) as production_moyenne
from fact_wind_power f
inner join dim_turbine dt
	on f.turbine_id=dt.turbine_id
group by 
	dt.turbine_name,
	dt.region
order by production_totale desc;

--19. Détection des baisses de production
WITH comparaison AS (
    SELECT
        f.production_id,
        dt.turbine_name,
        dd.date_mesure,
        f.heure_mesure,
        f.energy_produced,
        LAG(f.energy_produced) OVER (
            PARTITION BY f.turbine_id
            ORDER BY
                dd.date_mesure,
                f.heure_mesure,
                f.production_id
        ) AS production_precedente
    FROM fact_wind_power f
    INNER JOIN dim_turbine dt
        ON f.turbine_id = dt.turbine_id
    INNER JOIN dim_date dd
        ON f.date_id = dd.date_id
)
SELECT
    turbine_name,
    date_mesure,
    heure_mesure,
    production_precedente,
    energy_produced AS production_actuelle,
    ROUND(
        100.0 * (production_precedente - energy_produced)
        / NULLIF(production_precedente, 0),
        2
    ) AS baisse_pourcentage
FROM comparaison
WHERE production_precedente > 0
  AND energy_produced < production_precedente * 0.5
ORDER BY
    turbine_name,
    date_mesure,
    heure_mesure;

SELECT
    turbine_name,
    COUNT(*) AS nombre_baisses,
    COUNT(*) FILTER (
        WHERE production_actuelle = 0
    ) AS baisses_vers_zero,
    ROUND(AVG(baisse_pourcentage), 2)
        AS baisse_moyenne_pct,
    ROUND(MAX(baisse_pourcentage), 2)
        AS baisse_maximale_pct
FROM (
    WITH comparaison AS (
        SELECT
            dt.turbine_name,
            f.energy_produced AS production_actuelle,
            LAG(f.energy_produced) OVER (
                PARTITION BY f.turbine_id
                ORDER BY
                    dd.date_mesure,
                    f.heure_mesure,
                    f.production_id
            ) AS production_precedente
        FROM fact_wind_power f
        JOIN dim_turbine dt
            ON f.turbine_id = dt.turbine_id
        JOIN dim_date dd
            ON f.date_id = dd.date_id
    )
    SELECT
        turbine_name,
        production_actuelle,
        production_precedente,
        100.0 * (
            production_precedente - production_actuelle
        ) / NULLIF(production_precedente, 0)
            AS baisse_pourcentage
    FROM comparaison
    WHERE production_precedente > 0
      AND production_actuelle < production_precedente * 0.5
) anomalies
GROUP BY turbine_name
ORDER BY nombre_baisses DESC;

--2O.  Livrable pour Power BI : Construction de la couche Gold
CREATE OR REPLACE VIEW vw_wind_power_gold_daily AS
SELECT
    dd.date_mesure,
    dt.turbine_name,
    dt.region,
    ROUND(SUM(f.energy_produced), 2)
        AS production_totale,
    ROUND(AVG(f.energy_produced), 2)
        AS production_moyenne,
    COUNT(*) AS nombre_mesures,
    COUNT(*) FILTER (
        WHERE f.energy_produced = 0
    ) AS mesures_nulles,
    COUNT(*) FILTER (
        WHERE UPPER(TRIM(ds.status))
              NOT IN ('ONLINE','OPERATIONNAL')
    ) AS observations_non_operationnelles
FROM fact_wind_power f
INNER JOIN dim_turbine dt
    ON f.turbine_id = dt.turbine_id
INNER JOIN dim_date dd
    ON f.date_id = dd.date_id
INNER JOIN dim_status ds
    ON f.status_id = ds.status_id
GROUP BY
    dd.date_mesure,
    dt.turbine_name,
    dt.region;
select * from vw_wind_power_gold_daily
order by date_mesure,turbine_name;

--21. Administration de la base de données wind power data
--A. Vérification de l'environnement
select
	current_database() as base_actuelle,
	current_user as utilisateur_actuel,
	current_schema() as schema_actuel;
select table_schema, table_name
from information_schema.views
where table_name = 'vw_wind_power_gold_daily';
--B. Création de deux comptes
-- Mot de passe supprimé : le définir séparément dans pgAdmin si nécessaire.
CREATE ROLE wind_admin LOGIN;
-- Mot de passe supprimé : le définir séparément dans pgAdmin si nécessaire.
CREATE ROLE wind_reader LOGIN;
--C. Permissions pour chaque utilisateur
grant connect on database "wind power data"
to wind_admin;
grant usage, create on schema public
to wind_admin;
grant all privileges 
on all tables in schema public
to wind_admin;
grant all privileges 
on all sequences in schema public
to wind_admin;

grant connect on database "wind power data"
to wind_reader;
grant usage on schema public
to wind_reader;
grant select 
on table public.vw_wind_power_gold_daily
to wind_reader;
select
	grantee,
	table_schema,
	table_name,
	privilege_type
from information_schema.role_table_grants
where grantee in ('wind_admin','wind_reader')
	and table_name = 'vw_wind_power_gold_daily'
order by grantee, privilege_type;





	

