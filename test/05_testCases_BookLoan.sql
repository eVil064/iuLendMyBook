-- 05.1 Zeitslots
---------------------------
-- 05.1.1 Erstellen eines Zeitslots
INSERT INTO timeslot (begin_time, end_time, day_of_week)
VALUES ('10:00:00', '12:00:00', 5);
-- 05.1.2 CHECK CONSTRAINT VIOLATION: Erstellen schlägt fehl, wenn Ende vor Beginn
INSERT INTO timeslot (begin_time, end_time, day_of_week)
VALUES ('10:00:00', '09:00:00', 2);
-- 05.1.3 CHECK CONSTRAINT VIOLATION: Erstellen schlägt fehl, wenn Wochentag ungültig
INSERT INTO timeslot (begin_time, end_time, day_of_week)
VALUES ('10:00:00', '09:00:00', 10);
-- 05.1.4 Löschen eines Zeitslots
DELETE
FROM timeslot ts
WHERE timeslot_id = 11;

-- 05.2 Abholoptionen
---------------------------
-- 05.2.1 Erstellen einer Abholoption
INSERT INTO pickup_option (user_address_id, timeslot_id)
VALUES (3, 12);
-- 05.2.2 Erstellen einer Abholoption ohne Zeitslot
INSERT INTO pickup_option (user_address_id, timeslot_id)
VALUES (8, NULL);
-- 05.2.3 UNIQUE Constraint Violation:  Einfügen eines bereits vorhanden Datensatzes
INSERT INTO pickup_option (user_address_id, timeslot_id)
VALUES (8, NULL);
-- 05.2.4 Löschen einer Abholoption, die nicht referenziert wird
DELETE
from pickup_option
WHERE pickup_option_id = 1;
-- 05.2.5 FOREIGN KEY Constraint Violation:  Löschen einer Abholoption, die nicht referenziert wird
DELETE
from pickup_option
WHERE pickup_option_id = 7;

-- 05.3 Erstellen einer Ausleihe
---------------------------
-- 05.3.1 Ausleihvorgang für ein Exemplar über die Bereitstellungsart Versand
CALL createBookLoan((getbookcopiesbyisbn('9783000001031'))[1],
                    getUserByEmail('clara.neumann@example.org'),
                    NULL, NULL, NULL);
-- 05.3.2 Ausleihvorgang für das gleiche Exemplar erneut auslösen
CALL createBookLoan((getbookcopiesbyisbn('9783000001031'))[1],
                    getUserByEmail('jonas.reuter@example.org'),
                    NULL, NULL, NULL);
-- 05.3.3 Ausleihvorgang beenden
CALL returnBook('9783000001031', getUserByEmail('clara.neumann@example.org'), CURRENT_DATE);
-- 05.3.4 Ausleihvorgang für ein Exemplar über die Bereitstellungsart Abholung
CALL createBookLoan((getbookcopiesbyisbn('9788400003012'))[1], getUserByEmail('jonas.reuter@example.org'),
                    '09:45:00', 1::smallint, NULL);
-- 05.3.5 CHECK CONSTRAINT VIOLATION: Ausleihvorgang beenden, Rückgabedatum liegt vor Ausleihdatum
CALL returnBook('9788400003012', getUserByEmail('jonas.reuter@example.org'),
                '2026-01-01');
-- 05.3.6 CHECK CONSTRAINT VIOLATION: Status auf 'Zurückgegeben' ändern, ohne eine Rückgabedatum
-- zu setzen
UPDATE book_loan
SET status = 'RETURNED'
WHERE status = 'REQUESTED';
-- 05.2.7 CHECK CONSTRAINT VIOLATION: Einen ungültigen Status setzen
UPDATE book_loan
SET status = 'OUTDATED'
WHERE status = 'REQUESTED';

-- 05.4 Suchen von Büchern
---------------------------
-- 05.4.1 Abfrage aller verfügbaren Bücher in der Sprache Englisch zum Versand oder zur Abholung
-- im Radius < 100 km
SELECT formatisbn(b.isbn)                      isbn,
       b.title,
       b.description,
       bc.condition,
       ft.name,
       concat(u.last_name, ', ', u.first_name) owner,
       getdistancekm(53.157, 9.993682,
                     a.latitude, a.longitude)  km
FROM book_copy bc
         INNER JOIN book b on bc.book_id = b.book_id
         INNER JOIN language l on b.language_id = l.language_id
         INNER JOIN book_copy_fulfillment bcf on bc.book_copy_id = bcf.book_copy_id
         INNER JOIN fulfillment_type ft on bcf.fulfillment_type_id = ft.fulfillment_type_id
         INNER JOIN user_account u on bc.owner_id = u.user_id
         LEFT JOIN user_address ua on bc.owner_id = ua.user_id
         LEFT JOIN address a on ua.address_id = a.address_id
         INNER JOIN address_type t on ua.address_type_id = t.address_type_id AND t.name = ft.name
WHERE (isborrowable(bc.book_copy_id) AND l.name LIKE 'English%')
  AND (ft.name = 'SHIPPING' OR (ft.name = 'PICK_UP' AND getdistancekm(53.157,
                                                                      9.993682, a.latitude,
                                                                      a.longitude) < 100))
ORDER BY name, b.isbn, owner_id
LIMIT 10;


-- 05.5 Erstellen von Bewertungen
---------------------------
-- 05.5.1 Einfügen eines Ratings
INSERT INTO loan_rating (loan_id, rating_score, comment)
VALUES ((SELECT loan_id
         FROM book_loan bl
         WHERE NOT EXISTS (SELECT 1 FROM loan_rating lr WHERE lr.loan_id = bl.loan_id)
           AND bl.status = 'RETURNED'
         LIMIT 1), 5, 'Fairly easy process; Quick delivery');
-- 05.5.2 CHECK CONSTRAINT VIOLATION: Fehler beim Einfügen - Falscher Score
INSERT INTO loan_rating (loan_id, rating_score, comment)
VALUES (5, 7, NULL);
-- 05.5.3 UNIQUE CONSTRAINT VIOLATION: Fehler beim Einfügen - Rating schon vorhanden
INSERT INTO loan_rating (loan_id, rating_score, comment)
VALUES (5, 3, NULL);

-- 05.5.4 Anonyme Auswertung des Durchschnitts der abgegebenen Bewertungen je Buchtitel
SELECT formatisbn(b.isbn)  ISBN,
       b.title,
       count(lr.rating_id) no_of_ratings,
       round(AVG(rating_score)::numeric, 2) average_rating
FROM loan_rating lr
         INNER JOIN book_loan bl on lr.loan_id = bl.loan_id
         INNER JOIN book_copy bc on bl.book_copy_id = bc.book_copy_id
         INNER JOIN book b on bc.book_id = b.book_id
GROUP BY b.isbn, b.title
ORDER BY AVG(rating_score) desc
