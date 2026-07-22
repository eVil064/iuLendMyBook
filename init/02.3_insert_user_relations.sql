/* Es erfolgt die Verarbeitung der eingelesenen Daten
   - Verknüpfung von Personen und Adressen aus 05_user_data
   - Zuweisung des Adresstypen "SHIPPING" als Standard
*/
------------------------------------------------------------------------------------------------------------------------
-- User-Adressen erstellen
-- Die Adressen werden aus der temporären Datenbanktabelle ausgelesen. Anhand der Adressdaten (Ort, Postleitzahl, Straße,
-- Land) wird aus adress die Adress-ID ermittelt. Die User-ID wird aus der Tabelle user_account über die E-Mailadresse
-- der Person ermittelt.
-- Mit Hilfe des CROSS JOINS auf den Adresstypen werden zur Reduktion der Komplexität für jeden Nutzer eine Versand- und
-- eine Abholadresse angelegt.
INSERT INTO user_address (user_id,
                          address_id, type_id)
SELECT DISTINCT u.user_id, a.address_id, a2.address_type_id
FROM user_raw_data raw
         INNER JOIN user_account u ON raw.email = u.email
         INNER JOIN country c ON raw.country_code = c.iso_code
         INNER JOIN location l ON raw.city = l.city AND raw.postal_code = l.postal_code AND l.country_id = c.country_id
         INNER JOIN address a ON raw.street = a.street AND raw.number = a.number AND a.location_id = l.location_id
         CROSS JOIN address_type a2
ON CONFLICT DO NOTHING;

