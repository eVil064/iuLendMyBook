-- Größe der Datenbank (9,08 MB) inkl. Anzahl Tabellen
SELECT count(*)                                                                     no_of_tables,
       round(pg_database_size(current_database()) / 1024.0 / 1024.0, 2) || ' MB' as database_size
from information_schema.tables
where table_schema = 'public';

-- Anzahl Einträge je Tabelle
SELECT relname as tablename, n_live_tup as est_entries
from pg_stat_user_tables
ORDER by est_entries ASC;

-- Durchschnittliche Anzahl Einträge je Tabelle
SELECT CASE WHEN n_live_tup > 10 THEN 'other tables' ELSE relname END tables,
       count(*)                                                       no_of_tables,
       round(AVG(n_live_tup), 0) as                                   avg_records
from pg_stat_user_tables
group by tables
ORDER BY avg_records;

-- Metadaten für die Constraints
SELECT COUNT(*)                              AS constraints_total,
       COUNT(*) FILTER (WHERE contype = 'p') AS primary_keys,
       COUNT(*) FILTER (WHERE contype = 'f') AS foreign_keys,
       COUNT(*) FILTER (WHERE contype = 'u') AS unique_constraints,
       COUNT(*) FILTER (WHERE contype = 'c') AS check_constraints,
       COUNT(*) FILTER (WHERE contype = 'n') AS not_null
FROM pg_constraint c
         INNER JOIN pg_catalog.pg_namespace pn on c.connamespace = pn.oid
WHERE pn.nspname = 'public';

-- Metadaten für Indizes
SELECT COUNT(*)                                                 AS indices_total,
       COUNT(*) FILTER (WHERE indisprimary)                     AS primary_keys,
       COUNT(*) FILTER (WHERE indisunique AND NOT indisprimary) AS unique_indices,
       COUNT(*) FILTER (WHERE NOT indisunique)                  AS other_indices
FROM pg_index i
         JOIN pg_class idx
              ON i.indexrelid = idx.oid
         JOIN pg_namespace n
              ON idx.relnamespace = n.oid
WHERE n.nspname = 'public';


