/* Es erfolgt die Verarbeitung der Abhol-Optionen
   - Zufällige Erstellung von Abholoptionen anhand der bereits erstellten Benutzeradressen und Zeitslogs
*/
------------------------------------------------------------------------------------------------------------------------
-- Abholoptionen
-- Die Erstellung der Abholoptionen erfolgt zufällig. Hierzu werden alle Benuzteradresse aus user_address mit den Adress-
-- typen 'Abholung' über einen CROSS JOIN mit den Zeitslots (timeslot) verknüpft. Um nicht für alle Benutzeradressen
-- die gleichen Zeitslots anzubieten, wird die Liste der Zeitslots zuvor zufällig sortiert.
-- Zum Ende werden die Ergebnisse des Kreuzprodukts ebenfalls zufällig sortiert und die ersten 100 Ergebnisse (LIMIT 100)
-- übernommen.
INSERT INTO pickup_option (user_address_id, timeslot_id)
SELECT ua.user_address_id, ts.timeslot_id
from user_address ua
         CROSS JOIN (SELECT timeslot_id from timeslot order by random()) ts
         INNER JOIN address_type a on ua.type_id = a.address_type_id AND a.name = 'PICK_UP'
ORDER BY random()
LIMIT 100
ON CONFLICT DO NOTHING;

