/* Dieser Testfall prüft den Lebenszyklus des Ausleihprozesses für beide Ausleihvarianten 'Versand' und
   'Abholung' ab. Er startet mitder Selektion eines verfügbaren Exemplars mit einem definierten Titel. Im
   Anschluss wird der Ausleihprozess über die Methode createBookLoan() erstellt. Der Ausleihprozess wird
   mit Hilfe von returnBook() wieder beendet. Im Anschluss erfolgt die Buchbewertung.

   Um den Verlauf darzustellen werden die Aktionen in einer separaten Historien-Tabelle gespeichert. Diese
   wird zum Ende der Transaktion ausgewertet und zeigt die entsprechenden Statuswechsel und die abgegebenen
   Bewertungen.

   Zur Wiederholbarkeit wird die Transaktion am Ende wieder zurückgerollt.
 */

BEGIN;

-- Anlage eines Ausleihprozesses vom Typ 'Abholung'
DO
$$
    DECLARE
        v_copy_id          BIGINT;
        v_fulfillment_type varchar := 'PICK_UP';
        v_borrower_id      BIGINT;
        v_borrowerMail     varchar := 'clara.neumann@example.org';
        v_owner_id         BIGINT;
        v_book_loan_id     BIGINT;
        v_rating_id        BIGINT;
        v_timeslot         TIME;
        v_weekday          INT;
    BEGIN
        v_borrower_id := getuserbyemail(v_borrowerMail);

        SELECT bc.book_copy_id,
               u.user_id
        INTO STRICT v_copy_id, v_owner_id
        FROM book_copy bc
                 INNER JOIN book b on bc.book_id = b.book_id
                 INNER JOIN language l on b.language_id = l.language_id
                 INNER JOIN book_copy_fulfillment bcf on bc.book_copy_id = bcf.book_copy_id
                 INNER JOIN fulfillment_type ft on bcf.fulfillment_type_id = ft.fulfillment_type_id
                 INNER JOIN user_account u on bc.owner_id = u.user_id
                 LEFT JOIN user_address ua on bc.owner_id = ua.user_id
                 LEFT JOIN address a on ua.address_id = a.address_id
                 INNER JOIN address_type t on ua.address_type_id = t.address_type_id AND t.name = ft.name
        WHERE (isborrowable(bc.book_copy_id) AND ft.name = v_fulfillment_type)
        LIMIT 1;

        SELECT t.begin_time, t.day_of_week
        INTO STRICT v_timeslot, v_weekday
        from pickup_option po
                 INNER JOIN user_address ua on po.user_address_id = ua.user_address_id
                 INNER JOIN timeslot t on po.timeslot_id = t.timeslot_id
        WHERE ua.user_id = v_owner_id
        LIMIT 1;

        CALL createBookLoan(v_copy_id, v_borrower_id,
                            v_timeslot, v_weekday, v_book_loan_id);
        CALL returnbook(NULL, NULL, (current_timestamp + INTERVAL '1 day')::date, v_book_loan_id);

        CALL createbookrating(v_book_loan_id, 5,
                              'Super netter Verleiher, tolles Buch. Immer wieder gerne', v_rating_id);
    END
$$;

-- Anlage eines Ausleihprozesses vom Typ 'Versand'
DO
$$
    DECLARE
        v_copy_id          BIGINT;
        v_fulfillment_type varchar := 'SHIPPING';
        v_title            varchar := 'Das Echo der stillen Stadt';
        v_borrower_id      BIGINT;
        v_borrowerMail     varchar := 'jonas.reuter@example.org';
        v_owner_id         BIGINT;
        v_book_loan_id     BIGINT;
        v_timeslot         TIME;
        v_weekday          INT;
        v_rating_id        BIGINT;
    BEGIN
        v_borrower_id := getuserbyemail(v_borrowerMail);

        SELECT bc.book_copy_id,
               u.user_id
        INTO STRICT v_copy_id, v_owner_id
        FROM book_copy bc
                 INNER JOIN book b on bc.book_id = b.book_id
                 INNER JOIN language l on b.language_id = l.language_id
                 INNER JOIN book_copy_fulfillment bcf on bc.book_copy_id = bcf.book_copy_id
                 INNER JOIN fulfillment_type ft on bcf.fulfillment_type_id = ft.fulfillment_type_id
                 INNER JOIN user_account u on bc.owner_id = u.user_id
                 LEFT JOIN user_address ua on bc.owner_id = ua.user_id
                 LEFT JOIN address a on ua.address_id = a.address_id
                 INNER JOIN address_type t on ua.address_type_id = t.address_type_id AND t.name = ft.name
        WHERE (isborrowable(bc.book_copy_id) AND ft.name = v_fulfillment_type)
        LIMIT 1;

        CALL createBookLoan(v_copy_id, v_borrower_id,
                            v_timeslot, v_weekday, v_book_loan_id);
        CALL returnbook(NULL, NULL, (current_timestamp + INTERVAL '1 day')::date,
                        v_book_loan_id);
        CALL createbookrating(v_book_loan_id, 3,
                              'Buch war super, aber der Versand war viel zu spät', v_rating_id);

    END
$$;

SELECT bl.loan_id                                                                                  loan_id,
       timestamp,
       Concat(u.last_name, ', ', u.first_name)                                                     borrower,
       b.title,
       lh.loan_status,
       CASE WHEN lh.loan_status = 'REQUESTED' THEN ft.name END                                     fulfillment_type,
       case
           WHEN ft.name = 'PICK_UP' AND lh.loan_status = 'REQUESTED' THEN concat(getWeekday(t.day_of_week),
                                                                                 ', ',
                                                                                 t.begin_time) END pickupslot,
       case
           WHEN ft.name = 'SHIPPING' AND lh.loan_status = 'REQUESTED' THEN
               CONCAT(a.street, ', ', l.postal_code, ' ', l.city) END                              shipping_address,
       lh.return_date,
       r.rating_score,
       r.comment
from loan_history lh
         INNER JOIN book_loan bl on lh.loan_id = bl.loan_id
         INNER JOIN
     book_copy bc on bl.book_copy_id = bc.book_copy_id
         INNER JOIN book b on bc.book_id = b.book_id
         INNER JOIN user_account u on bl.borrower_id = u.user_id
         INNER JOIN fulfillment_type ft on bl.fulfillment_type_id = ft.fulfillment_type_id
         LEFT JOIN pickup_option po on bl.pickup_option_id = po.pickup_option_id
         LEFT JOIN timeslot t on po.timeslot_id = t.timeslot_id
         LEFT JOIN address_type at ON at.name = 'SHIPPING'
         LEFT JOIN user_address ua on bl.borrower_id = ua.user_id AND ua.address_type_id = at.address_type_id
         LEFT JOIN address a on ua.address_id = a.address_id
         LEFT JOIN location l on a.location_id = l.location_id
         LEFT JOIN loan_rating r on bl.loan_id = r.loan_id AND lh.loan_status = 'RETURNED'
WHERE timestamp > current_date
ORDER BY bl.loan_id, timestamp;
ROLLBACK;