/* Es erfolgt die Anlage beliebiger und fiktiver Ausleihdaten
   - Erstellung zufälliger Ausleihvorgänge für vorhandene Buchexemplare mit der Bereitstellungsart 'Versand'
   - Erstellung zufälliger Ausleihvorgänge für vorhandene Buchexemplare mit der Bereitstellungsart 'Abholung'
   - Aktualisierung der Ausleihdaten
*/
------------------------------------------------------------------------------------------------------------------------

-- Erstellung von Ausleihvorgängen über die die Bereitstellungsart 'Versand'
-- Über den CROSS JOIN wird eine Kreuztabelle erstellt, in der für jede Kombination aus book_copy und
-- user_account ein Eintrag erstellt wird. Damit es nicht zu viele Datensätze werden, werden über die 'random()'-Funktion
-- in Kombination LIMIT 5 beliebige User-IDs ermittelt und die Ergebnismenge darauf eingeschränkt. Des Weiteren werden
-- über den Adresstypen nur User-IDs ermittelt, die auch eine Versandadresse besitzen.

-- Die Menge der Buchexemplare ist über die WHERE-Bedinung auf die Einträge beschränkt, die auch zum Versand angeboten werden.

-- Als Ausleihdatum wird ein beliebiger Wert gesetzt. Dieser wird anhand des aktuellen Datums und einem Versatz ermittelt.
-- Dieser Versatz wird in Tagen angebenen (INTERVAL '1 day') und mit einer Zufallszahl von 1 - 60 multipliziert. Somit
-- wird ein Datum in den letzten 60 Tagen ermittelt
INSERT INTO book_loan (copy_id, borrowed_by, loan_date, fulfillment_type_id, user_address_id)
SELECT bc.book_copy_id,
       u.user_id,
       Current_date - (floor(random() * 60) + 1) * INTERVAL '1 day',
       t.fulfillment_type_id,
       ua.user_address_id
from book_copy bc
         INNER JOIN book_copy_fulfillment bcf on bc.book_copy_id = bcf.book_copy_id
         INNER JOIN fulfillment_type t on bcf.fulfillment_type_id = t.fulfillment_type_id
         CROSS JOIN user_account u
         INNER JOIN user_address ua on u.user_id = ua.user_id
         INNER JOIN address_type t2 on ua.address_type_id = t2.address_type_id AND t2.name = 'SHIPPING'
WHERE t.name = 'SHIPPING'
  and u.user_id in (SELECT user_id from user_account order by random() LIMIT 5);

-- Erstellung von Ausleihvorgängen über die die Bereitstellungsart 'Abholung'
-- Über den CROSS JOIN wird eine Kreuztabelle erstellt, in der für jede Kombination aus book_copy und
-- user_account ein Eintrag erstellt wird. Damit es nicht zu viele Datensätze werden, werden über die 'random()'-Funktion
-- in Kombination LIMIT 5 beliebige User-IDs ermittelt und die Ergebnismenge darauf eingeschränkt.

-- Die Menge der Buchexemplare ist über die WHERE-Bedinung auf die Einträge beschränkt, die auch zum Versand angeboten werden.
-- Zudem wird im JOIN auch darauf geachtet, dass der Besitzer auch eine Abholadresse besitzt.
-- Durch den LATERAL JOIN auf die 'pickup_option' wird nur die erste gefundene Option ermittelt, da ein Verleiher mehrere
-- Abholoptionen anbieten kann, in der Ausleihe aber nur eine gewählt werden kann. In den Testdaten wird daher zwar
-- zufällig ein Slot ausgewählt, jedoch ist dieser für alle Inhalte gleich.

-- Als Ausleidatum wird ein beliebiger Wert gesetzt. Dieser wird anhand des aktuellen Datums und einem Versatz ermittelt.
-- Dieser Versatz wird in Tagen angebenen (INTERVAL '1 day') und mit einer Zufallszahl von 1 - 60 multipliziert. Somit
-- wird ein Datum in den letzten 60 Tagen ermittelt
INSERT INTO book_loan (copy_id, borrowed_by, loan_date, fulfillment_type_id, pickup_option_id)
SELECT bc.book_copy_id,
       u.user_id,
       Current_date - (floor(random() * 60) + 1) * INTERVAL '1 day',
       t.fulfillment_type_id,
       pu.pickup_option_id
from book_copy bc
         INNER JOIN book_copy_fulfillment bcf on bc.book_copy_id = bcf.book_copy_id
         INNER JOIN fulfillment_type t on bcf.fulfillment_type_id = t.fulfillment_type_id
         INNER JOIN user_address ua on bc.owner_id = ua.user_id
         INNER JOIN address_type t2 on ua.address_type_id = t2.address_type_id AND t2.name = 'PICK_UP'
         INNER JOIN LATERAL (
    SELECT po.pickup_option_id
    FROM pickup_option po
    WHERE po.user_address_id = ua.user_address_id
    ORDER BY random()
    LIMIT 1
    ) pu ON TRUE
         CROSS JOIN user_account u
WHERE t.name = 'PICK_UP'
  and u.user_id in (SELECT user_id from user_account order by random() LIMIT 5);

-- Aktualisierung der Ausleihdaten
-- Ausgehend davon, dass die Bücher immer in der vorgesehenen Ausleihzeit zurückgegeben werden, wird auf Basis des
-- Ausleihdatums und der Leihdauer das Rückgabedatum berechnet. Für eine realistischere Darstellung wird per 'random()'
-- eine anteilge Ausleihzeit berechet.
-- Liegt das errechnete Datum vor dem aktuellen Datum, wird das Datum als 'return_date' persistiert und der Status auf
-- 'RETURNED' gesetzt. Falls nicht, wird der Status 'ON_LOAN' gesetzt und das Rückgabedatum bleibt offen.
UPDATE book_loan l
SET return_date = CASE
                      WHEN CURRENT_DATE > l.loan_date + floor(random() * bc.loan_duration_days) * INTERVAL '1 day' THEN
                          l.loan_date + floor(random() * bc.loan_duration_days) * INTERVAL '1 day' END,
    status      = CASE
                      WHEN CURRENT_DATE > l.loan_date + floor(random() * bc.loan_duration_days) * INTERVAL '1 day'
                          THEN 'RETURNED'
                      ELSE 'ON_LOAN' END
FROM book_copy bc
WHERE bc.book_copy_id = l.copy_id;
