# Dictionnaire de données

Dictionnaire établi à partir des en-têtes réels de `data/wind_power_data.csv`. Les unités qui ne sont pas indiquées dans le fichier source ne sont pas supposées.

| Colonne | Description |
|---|---|
| `production_id` | Identifiant unique de l’observation. |
| `date_` | Date de mesure au format YYYY-MM-DD. |
| `time_` | Heure de mesure au format HH-MM-SS dans le fichier source; la vue Silver convertit les tirets en deux-points avant le typage TIME. |
| `turbine_name` | Nom de la turbine. |
| `capacity` | Capacité déclarée de la turbine; unité à confirmer dans la documentation source. |
| `location_name` | Nom du site ou de la localisation. |
| `latitude` | Latitude géographique. |
| `longitude` | Longitude géographique. |
| `region` | Région opérationnelle. |
| `status` | État opérationnel enregistré dans la source. |
| `responsible_department` | Département responsable. |
| `wind_speed` | Vitesse du vent; unité non documentée dans le fichier. |
| `wind_direction` | Direction du vent; codage source conservé. |
| `energy_produced` | Production énergétique par observation; unité non documentée dans le fichier. |

**Profil du fichier :** 6 048 lignes et 14 colonnes. Période observée : 2024-06-01 au 2024-06-14.
