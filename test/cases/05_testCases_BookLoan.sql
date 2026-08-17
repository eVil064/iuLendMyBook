-- 05.1 Zeitslots
---------------------------
-- 05.1.1 Erstellen eines Zeitslots
INSERT INTO timeslot (begin_time, end_time, day_of_week)
VALUES ('10:00:00', '12:00:00', 5);
-- 05.1.2 Erstellen schlägt fehl, wenn Ende vor Beginn
INSERT INTO timeslot (begin_time, end_time, day_of_week)
VALUES ('10:00:00', '09:00:00', 2);
-- 05.1.3 Erstellen schlägt fehl, wenn Wochentag ungültig
INSERT INTO timeslot (begin_time, end_time, day_of_week)
VALUES ('10:00:00', '09:00:00', 10);
-- 05.1.4 Löschen eines Zeitslots
DELETE
FROM timeslot
WHERE day_of_week = 5
  and begin_time = '10:00:00';
-- 05.1.4 Löschen eines Zeitslots, der bereits zugeordnet ist
SELECT deleteTimeSlot(ARRAY((SELECT t.timeslot_id FROM timeslot t WHERE begin_time = '09:00:00' AND day_of_week = 5)));

-- 05.2 Erstellen einer Ausleihe
---------------------------
-- 05.2.1 Ausleihvorgang für ein Exemplar über die Bereitstellungsart Versand
CALL createBookLoan((getbookcopiesbyisbn('9780261102354'))[1], getUserByEmail('clara.neumann@example.org'),
                    NULL, NULL, NULL);
-- 05.2.2 Ausleihvorgang für das gleiche Exemplar erneut auslösen
CALL createBookLoan((getbookcopiesbyisbn('9780261102354'))[1], getUserByEmail('clara.neumann@example.org'),
                    NULL, NULL, NULL);
-- 05.2.3 Ausleihvorgang beenden
CALL returnBook('9780261102354', getUserByEmail('clara.neumann@example.org'), CURRENT_DATE);
-- 05.2.4 Ausleihvorgang für ein Exemplar über die Bereitstellungsart Abholung
CALL createBookLoan((getbookcopiesbyisbn('9780261102354'))[1], getUserByEmail('jonas.reuter@example.org'),
                    '09:30:00', 4::smallint, NULL);
CALL createBookLoan((getbookcopiesbyisbn('9780261102354'))[1], getUserByEmail('jonas.reuter@example.org'),
                    '10:30:00', 1::smallint, NULL);
-- 05.2.5 Ausleihvorgang beenden, Rückgabedatum liegt vor Ausleihdatum
CALL returnBook('9780261102354', getUserByEmail('jonas.reuter@example.org'),
                '2026-01-01');
-- 05.2.6 Status auf 'Zurückgegeben' ändern, ohne eine Rückgabedatum zu setzen
UPDATE book_loan
SET status = 'RETURNED'
WHERE status = 'REQUESTED';
-- 05.2.7 Einen ungültigen Status setzen
UPDATE book_loan
SET status = 'OUTDATED'
WHERE status = 'REQUESTED';

-- 05.3 Suchen von Büchern
---------------------------
-- 05.3.1 Einfache Abfrage alle verfügbaren Bücher in der Sprache Englisch
SELECT DISTINCT b.title,
                b.description,
                b.isbn,
                bc.condition,
                EXISTS (SELECT 1
                        from book_copy_fulfillment bcf
                                 INNER JOIN fulfillment_type t
                                            on bcf.fulfillment_type_id = t.fulfillment_type_id AND type_name = 'PICK_UP') Pickup,
                EXISTS (SELECT 1
                        from book_copy_fulfillment bcf
                                 INNER JOIN fulfillment_type t on bcf.fulfillment_type_id = t.fulfillment_type_id AND
                                                                  type_name =
                                                                  'SHIPPING')                                             Shipping,
                concat(ua.last_name, ', ', ua.first_name)                                                                 owner
FROM book_copy bc
         INNER JOIN book b on bc.book_id = b.book_id
         INNER JOIN user_account ua on bc.owner_id = ua.user_id
         INNER JOIN language l on b.language_id = l.language_id
WHERE is_blocked = false
  AND l.name like 'English%'
  AND NOT EXISTS (SELECT 1
                  FROM book_loan bl
                  WHERE bl.status <> 'RETURNED'
                    and bl.book_copy_id = bc.book_copy_id);

SELECT getdistancekm(a.latitude, a.longitude, a.latitude, a.longitude)
from book_copy bc
         INNER JOIN user_address ua ON ua.user_id = bc.owner_id
         INNER JOIN address a on ua.address_id = a.address_id
-- TODO Bücher zur Abholung in kleiner 20 km