/* Es erfolgt die Verarbeitung der eingelesenen Verlagsdaten-Daten
   - Anlage der Orte aus 07_publisher.csv
   - Anlage der Adressen aus aus 07_publisher.csv und Verknüpfung mit Orten
   - Verknüfung des Verlags mit den Adressdaten
*/
------------------------------------------------------------------------------------------------------------------------
-- Anlage des Ortes
-- Die Orte werden aus der temporären Datenbanktabelle ausgelesen und in die Tabelle location übertragen. Die Einschränkung
-- ON CONFLICT DO NOTHING stellt dabei sicher, dass bereits bei der Übernahme von Personenadressen angelegte Orte nicht
-- ein weiteres Mal hinzugefügt werden.
-- Auch hier erfolgt die Verknüpfung mit der Nachschlagetabelle country über den ISO-Code, der in der temporären
-- Datenbanktabelle übernommen wurde.
INSERT INTO location (postal_code,
                      city,
                      country_id)
SELECT DISTINCT raw.postal_code,
                raw.city,
                c.country_id
FROM publisher_raw_data raw
         JOIN country c ON raw.country_code = c.iso_code
ON CONFLICT DO NOTHING;


-- Anlage der Verlagsadresse
-- Die Adressen werden aus der temporären Datenbanktabelle ausgelesen und in die Tabelle address übertragen.
-- Die Verknüpfung mit der angelegten Tabelle location erfolgt über die eindeutigen Merkmale postal_code, city und country
-- Auf den Import der Geodaten wird an dieser Stelle verzichtet, da sie für die Angaben am Verlag zu vernachlässigen sind.
INSERT INTO address (street,
                     number,
                     location_id)
SELECT DISTINCT raw.street, raw.number, l.location_id
FROM publisher_raw_data raw
         JOIN country c ON raw.country_code = c.iso_code
         JOIN location l ON raw.city = l.city AND raw.postal_code = l.postal_code AND l.country_id = c.country_id
ON CONFLICT DO NOTHING;


-- Anlage der Verlagsdaten
-- Die Verlagsinformationen name und website werden aus der temporären Datei übernommen und in die Tabelle publisher übertragen
-- Die Verknüpfung mit der angelegten Adresse erfolgt über die eindeutigen Merkmale postal_code, city und country
INSERT INTO publisher (name, website, address_id)
SELECT DISTINCT raw.name, raw.website, a.address_id
FROM publisher_raw_data raw
         JOIN country c ON raw.country_code = c.iso_code
         JOIN location l ON raw.postal_code = l.postal_code AND raw.city = l.city AND l.country_id = c.country_id
         JOIN address a ON raw.street = a.street AND raw.number = a.number AND a.location_id = l.location_id
ON CONFLICT DO NOTHING;