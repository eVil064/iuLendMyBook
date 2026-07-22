/* Es erfolgt die Verarbeitung der eingelesenen Autoren-Daten
   - Anlage der Autoren aus 01_authors.csv
*/
------------------------------------------------------------------------------------------------------------------------
-- Anlage der Autoren
-- Die Autoren werden aus der temporären Datenbanktabelle übernommen und in die Tabelle author überführt.
INSERT INTO author (academic_title,
                    first_name,
                    last_name)
SELECT DISTINCT raw.academic_title,
                raw.first_name,
                raw.last_name
FROM author_raw_data raw
ON CONFLICT DO NOTHING;
