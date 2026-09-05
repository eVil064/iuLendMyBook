/* Es erfolgt die Verarbeitung der eingelesenen Buchexemplar-Daten
   - Anlage zufälliger Buchexemplare
   - Ergänzung der verfügbaren Bereitstellungsarten für die betreffenden Exemplare
*/
------------------------------------------------------------------------------------------------------------------------

-- Anlage der Exemplare
-- Die Buch-Exemplare werden zufällig aus den Buchdaten (book) und Benutzerdaten (user_account) ermittelt und angelegt.
-- Dazu werden über einen CROSS JOIN alle möglichen Kombinationen aus Buch und Benutzer ermittelt. Durch die Sortierung
-- über die Funktion random() * book_id werden die ermittelten Daten zufällig sortiert. Von dieser zufälligen Liste werden die
-- ersten 25 Einträg (LIMIT 25) übernommen.
-- Der Parameter loan_duration_days wird als Zufallswert einer Zahl zwischen 10 und 100 ermittelt. Durch das Dividieren
-- durch 5, das folgenden Abrunden und das erneute multiplizieren, werden Dauern ermittelt, die durch 5 teilbar sind.
-- Der Zustand aller Exemplare wird auf einen festen Wert gesetzt, um die Erstellung zu vereinfachen.
INSERT INTO book_copy (book_id, owner_id, loan_duration_days, condition)
SELECT b.book_id, u.user_id, floor((random() * (100 - 10) + 10) / 5) * 5, 'Gut'
FROM book b
         CROSS JOIN user_account u
ORDER BY random() * book_id
LIMIT 25
ON CONFLICT DO NOTHING;

INSERT INTO book_copy_fulfillment (book_copy_id, fulfillment_type_id)
SELECT bc.book_copy_id, t.fulfillment_type_id
FROM book_copy bc
         INNER JOIN user_address ua on bc.owner_id = ua.user_id
         INNER JOIN address_type a on ua.address_type_id = a.address_type_id
         INNER JOIN fulfillment_type t on t.name = a.name
ON CONFLICT DO NOTHING;