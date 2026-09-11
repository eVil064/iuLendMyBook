/* Die Nutzung von Indizes und die daraus resultierende Performance lassen sich über eine
   Performanceanalyse abbilden. Diese erzeugt einen Ausführungsplan und zeigt somit nicht nur die Dauer
   einer Abfrage, sondern zerlegt die einzelnen Abfrageschritte, ermittelt Einzelzeiten und gibt Auskunft
   über verwendete Indizes.

   Die nachfolgende Analyse wird exemplarisch anhand der komplexen Buchsuche aus den Testfällen
   ausgeführt. Im ersten Durchlauf kann beobachtet werden, dass die angelegten Indizes (z.B.
   idx_book_copy_book) verwendet werden. Der Index idx_book_copy_book hingegen wird nicht genutzt.
   Stattdessen wird durch den Optimizer ein sequenzieller Scan durchgeführt. Da die Tabelle nur ca. 50
   Einträge besitzt ist dieser Weg günstiger, als die Verwendung des Index.

   Im zweiten Durchlauf werden die Indizes entfernt. Die Analyse zeigt nun, dass die Ausführungszeit der
   gleichen Abfrage deutlich ansteigt, während die Zeit zur Erstellung des Plans etwa gleichbleibt.
 */
BEGIN;
ANALYZE;
EXPLAIN (ANALYZE, BUFFERS)
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

DROP INDEX IF EXISTS idx_book_copy_book;
DROP INDEX IF EXISTS idx_book_copy_owner;
DROP INDEX IF EXISTS idx_book_genre_genre;
DROP INDEX IF EXISTS idx_book_author_author;
DROP INDEX IF EXISTS idx_user_role_user;
DROP INDEX IF EXISTS idx_book_loan_borrower_date;
DROP INDEX IF EXISTS idx_book_copy_fulfillment_copy;
DROP INDEX IF EXISTS idx_book_loan_activ_copy;

ANALYZE;
EXPLAIN (ANALYZE, BUFFERS)
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
ROLLBACK;