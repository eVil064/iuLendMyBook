/* Es erfolgt die Verarbeitung der eingelesenen Daten
   - Anlage der Personen aus 05_user_data.csv
   - Zuweisung der Rollen aus 05_user_data.csv
*/
------------------------------------------------------------------------------------------------------------------------
-- Personen erstellen
-- Die Personen werden aus der temporären Datenbanktabelle ausgelesen und in die Tabelle user_account übertragen.
INSERT INTO user_account (academic_title,
                          first_name,
                          last_name,
                          email,
                          phone)
SELECT raw.academic_title,
       raw.first_name,
       raw.last_name,
       raw.email,
       raw.phone
FROM user_raw_data raw
ON CONFLICT DO NOTHING;

-- Rollen je Person einfügen
-- Die Rollen werden aus der temporären Datenbanktabelle ausgelesen und in die Tabelle user_role übertragen.
-- Die Verknüpfung mit der Nachschlagetabelle role erfolgt über die Bezeichnung der Rolle während die User-ID über
-- die eindeutige E-Mailadresse aus der Tabelle user_account ermittelt wird.
INSERT INTO user_role (user_id,
                       role_id)
SELECT DISTINCT u.user_id, r.role_id
FROM user_raw_data raw
         JOIN role r ON raw.role_name = r.name
         JOIN user_account u ON raw.email = u.email
ON CONFLICT DO NOTHING;