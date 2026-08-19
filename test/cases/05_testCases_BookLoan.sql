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
-- 05.3.1 Abfrage aller verfügbaren Bücher in der Sprache Englisch
SELECT formatisbn(b.isbn)                                                                                                isbn,
       b.title,
       b.description,
       bc.condition,
       EXISTS (SELECT 1
               from book_copy_fulfillment bcf
                        INNER JOIN fulfillment_type t
                                   on bcf.fulfillment_type_id = t.fulfillment_type_id AND type_name = 'PICK_UP')         Pickup,
       EXISTS (SELECT 1
               from book_copy_fulfillment bcf
                        INNER JOIN fulfillment_type t on bcf.fulfillment_type_id = t.fulfillment_type_id AND type_name =
                                                                                                             'SHIPPING') Shipping,
       concat(ua.last_name, ', ', ua.first_name)                                                                         owner
FROM book_copy bc
         INNER JOIN book b on bc.book_id = b.book_id
         INNER JOIN user_account ua on bc.owner_id = ua.user_id
         INNER JOIN language l on b.language_id = l.language_id
WHERE l.name like 'English%'
  AND isborrowable(bc.book_copy_id)
ORDER BY b.isbn, owner_id;

-- 05.3.2 Ermittlung aller Exemplare inkl. Verleihstatus in einem Radius von 100 km vom angegebenen Standort
SELECT b.description,
       formatisbn(b.isbn),
       b.title,
       l.name                                                                        language,
       bc.condition,
       concat(u.last_name, ', ', u.first_name)                                       owner,
       getdistancekm(52.5162, 13.377, owneraddress.latitude, owneraddress.longitude) distance_km,
       bl.status
FROM book_copy bc
         INNER JOIN book b on bc.book_id = b.book_id
         INNER JOIN language l on b.language_id = l.language_id
         INNER JOIN user_address ua on bc.owner_id = ua.user_id
         INNER JOIN user_account u on ua.user_id = u.user_id
         INNER JOIN address owneraddress on ua.address_id = owneraddress.address_id
    AND address_type_id = (SELECT address_type_id from address_type where name = 'PICK_UP')
         INNER JOIN book_copy_fulfillment bcf on bc.book_copy_id = bcf.book_copy_id
         INNER JOIN fulfillment_type t on bcf.fulfillment_type_id = t.fulfillment_type_id AND type_name = 'PICK_UP'
         LEFT JOIN book_loan bl on bc.book_copy_id = bl.book_copy_id
WHERE getdistancekm(52.5162, 13.377, owneraddress.latitude, owneraddress.longitude) < 5
  AND (bl.loan_date = (SELECT MAX(loan_date) FROM book_loan WHERE book_copy_id = bc.book_copy_id) OR
       bl.loan_date IS NULL);

-- 05.4 Erstellen von Bewertungen
---------------------------
-- 05.4.1 Einfügen eines Ratings
INSERT INTO loan_rating (loan_id, rating_score, comment)
VALUES ((SELECT loan_id
         FROM book_loan bl
         WHERE NOT EXISTS (SELECT 1 FROM loan_rating lr WHERE lr.loan_id = bl.loan_id)
           AND bl.status = 'RETURNED'
         LIMIT 1), 5, 'Fairly easy process; Quick delivery');
-- 05.4.2 Fehler beim Einfügen - Falscher Score
INSERT INTO loan_rating (loan_id, rating_score, comment)
VALUES (5, 7, NULL);
-- 05.4.3 Fehler beim Einfügen - Rating schon vorhanden
INSERT INTO loan_rating (loan_id, rating_score, comment)
VALUES (5, 3, NULL);

-- 05.4.3 Anonyme Auswertung des Durchschnitts der abgegebenen Bewertungen je Buchtitel
SELECT formatisbn(b.isbn)                   ISBN,
       b.title,
       count(lr.rating_id)                  no_of_ratings,
       round(AVG(rating_score)::numeric, 2) average_rating
FROM loan_rating lr
         INNER JOIN book_loan bl on lr.loan_id = bl.loan_id
         INNER JOIN book_copy bc on bl.book_copy_id = bc.book_copy_id
         INNER JOIN book b on bc.book_id = b.book_id

GROUP BY b.isbn, b.title
ORDER BY AVG(rating_score) desc
