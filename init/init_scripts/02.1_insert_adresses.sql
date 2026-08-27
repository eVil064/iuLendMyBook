/* Es erfolgt die Verarbeitung der eingelesenen Daten
   - Anlage der Orte aus 05_user_data
   - Anlage der Adressen aus 05_user_data und Verknüpfung mit Orten
*/
------------------------------------------------------------------------------------------------------------------------
-- Orte erstellen
-- Die Orte werden aus der temporären Datenbanktabelle ausgelesen und in die Tabelle location übertragen.
-- Die Verknüpfung mit der Nachschlagetabelle country erfolgt anhand des ISO-Codes.
INSERT INTO location (postal_code,
                      city,
                      country_id)
SELECT DISTINCT raw.postal_code,
                raw.city,
                c.country_id
FROM user_raw_data raw
         JOIN country c ON raw.country_code = c.iso_code
ON CONFLICT DO NOTHING;

-- Adressen erstellen
-- Die Adressen und Geodaten werden aus der temporären Datenbanktabelle ausgelesen und in die Tabelle address übertragen.
-- Die Verknüpfung mit der angelegten Tabelle location erfolgt über die eindeutigen Merkmale postal_code, city und country
INSERT INTO address (street,
                     number,
                     location_id,
                     latitude,
                     longitude)
SELECT DISTINCT raw.street, raw.number, l.location_id, raw.latitude, raw.longitude
FROM user_raw_data raw
         JOIN country c ON raw.country_code = c.iso_code
         JOIN location l ON raw.city = l.city AND raw.postal_code = l.postal_code AND l.country_id = c.country_id
ON CONFLICT DO NOTHING;
