/* Löscht die übergebenen Zeitslots und die betroffenen Abholoptionen zurück. Für diese IDs wird Aufgrund der Referenz-
   aktion in der Tabelle pickup_option der Zeitsloot auf NULL gesetzt
 */
CREATE OR REPLACE FUNCTION deleteTimeSlot(p_timeslot_id BIGINT[])
    RETURNS TABLE
            (
                pickup_option BIGINT,
                timeslot_id   BIGINT
            )
    LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN QUERY WITH affectedPickup AS (SELECT pickup_option_id
                                         from pickup_option po
                                         WHERE po.timeslot_id = ANY (p_timeslot_id)),
                      deletedTimeslots AS (DELETE from timeslot t WHERE t.timeslot_id = ANY (p_timeslot_id))
                 SELECT po2.pickup_option_id, po2.timeslot_id
                 from pickup_option po2
                 WHERE po2.pickup_option_id IN (SELECT pickup_option_id FROM affectedPickup);
END
$$;

-- Funktion, die anhand des aktuellen Ausleihstatus und dem Sperrstatus des Exemplars überprüft, ob ein Exemplar
-- aktuell zur Ausleihe bereitsteht
CREATE OR REPLACE FUNCTION isBorrowable(p_book_copy_id BIGINT) RETURNS BOOLEAN
    LANGUAGE plpgsql AS
$$
BEGIN
    RETURN NOT EXISTS (SELECT 1
                       FROM book_loan bl
                                INNER JOIN book_copy bc ON bl.book_copy_id = bc.book_copy_id
                       WHERE bc.book_copy_id = p_book_copy_id and status != 'RETURNED'
                          OR bc.is_blocked);
END
$$;

/* Erstellt einen neuen Eintrag für einen Ausleihvorgang. Dabei werden die ausleihende Person und das jeweilige
   Buchexemplar herangezogen. Werden Abholzeit und -tag angegeben, wird angenommen, dass die Bereitstellungart
   'Abholung' gewählt wurde. Mit Hilfe der Funktion getFirstPickupOption wird ermittelt, ob zum angegebenen Zeitpunkt eine
   Abholung möglich ist.
   Werden keine Abholdaten angegeben, wird Versand als Bereitstellungsart angenommen. Über die Methode
   getFirstShippingAddress wird eine Versandadresse ausgewählt. Für den Testfall wird hierbei nur die erste mögliche
   Adresse ausgewählt. In der Praxis würde der Entleiher eine konkrete Adresse angeben, die hier hinterlegt würde.

   Ist das Exemplar buchbar und Versandadresse bzw. Abholslot können ermittelt werden, wird ein neuer Ausleihvorgang
   erzeugt. Sofern das Exemplar nicht verfügbar ist, wird ein Fehler ausgegeben.
 */
CREATE OR REPLACE PROCEDURE createBookLoan(p_copy_id BIGINT, p_borrower_id BIGINT, p_pickup_time time,
                                           p_pickup_day INTEGER, OUT p_loan_id BIGINT)
    LANGUAGE plpgsql AS
$$
DECLARE
    v_owner_id         BIGINT;
    v_pickup_option_id BIGINT;
    v_shipping_address BIGINT;
    v_fulfillment_type BIGINT;
BEGIN
    IF p_copy_id IS NULL THEN
        RAISE EXCEPTION 'The selected book copy does not exist';
    END IF;
    IF p_pickup_time IS NOT NULL AND p_pickup_day IS NOT NULL THEN
        v_fulfillment_type := getFulfillmentTypID('PICK_UP');
        SELECT owner_id INTO v_owner_id FROM book_copy WHERE book_copy_id = p_copy_id;

        v_pickup_option_id := getFirstPickupOption(p_pickup_time, p_pickup_day, v_owner_id);

        IF v_pickup_option_id IS NULL THEN
            RAISE EXCEPTION 'The chosen timeslot is not available';
        END IF;
    ELSE
        v_fulfillment_type := getFulfillmentTypID('SHIPPING');
        v_shipping_address := getFirstShippingAddress(p_borrower_id);
        IF v_shipping_address IS NULL THEN
            RAISE EXCEPTION 'The user does not have a shipping address. Please create an address beforehand';
        END IF;
    END IF;

    IF isBorrowable(p_copy_id) THEN
        INSERT INTO book_loan (book_copy_id, loan_date, borrower_id, fulfillment_type_id, pickup_option_id,
                               user_address_id)
        VALUES (p_copy_id, CURRENT_DATE, p_borrower_id, v_fulfillment_type,
                v_pickup_option_id, v_shipping_address)
        RETURNING loan_id INTO p_loan_id;

        RAISE NOTICE 'Book loan with ID % was successfully created', p_loan_id;
    ELSE
        RAISE EXCEPTION 'The Book cannot be borrowed because it is not available';
    END IF;

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'The book copy is not offered for pick up. Pleas choose another fulfillment type';
END;
$$;

-- Aktualisiert einen bestehenden Ausleihprozess, indem der Status 'RETURNED' und das jeweilige Rückgabedatum gesetzt
-- werden. Zur Vereinfachung wird der Ausleihvorgang anhand der ISBN des Exemplars und der ausleihenden Person ermittelt.
-- In der Praxis würde das konkrete Exemplar oder die ID des Ausleihvorgangs übergeben, sodass der Vorgang unmittelbar
-- aktualisiert werden kann
CREATE OR REPLACE PROCEDURE returnBook(p_isbn varchar(13), p_borrower_id BIGINT, p_return_date date)
    LANGUAGE plpgsql AS
$$
DECLARE
    v_loan_id BIGINT;
BEGIN
    UPDATE book_loan bl
    SET return_date = p_return_date,
        status      = 'RETURNED'
    FROM book_copy bc
             INNER JOIN book b on bc.book_id = b.book_id
    WHERE b.isbn = p_isbn
      AND bl.status <> 'RETURNED'
      AND bl.borrower_id = p_borrower_id
      AND bl.book_copy_id = bc.book_copy_id
    RETURNING bl.loan_id INTO v_loan_id;

    IF v_loan_id IS NULL THEN
        RAISE EXCEPTION 'Loan could not be updated. Loan id % was not found', v_loan_id;
    ELSE
        RAISE NOTICE 'Book loan with ID % was successfully updated', v_loan_id;
    END IF;
END;
$$;

-- Ermittelt eine Versandadresse anhand der User-ID des ausleihenden Benutzers. Dabei wird berücksichtigt, dass die
-- Adresse des Benutzers den Typ 'Versand' aufweisen muss. Entsprechend der Modellierung wäre es möglich, dass ein Nutzer
-- mehrere Versandadressen angibt. Für den hier vorliegenden Testfall wird ausschließlich die erste Versandadresse zur
-- weiteren Verarbeitung herangezogen
CREATE OR REPLACE FUNCTION getFirstShippingAddress(p_user_id BIGINT)
    RETURNS BIGINT
    LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN (SELECT address_id
            FROM user_address a
                     INNER JOIN address_type t on a.address_type_id = t.address_type_id
            WHERE user_id = p_user_id
              AND t.name = 'SHIPPING'
            LIMIT 1);
END
$$;

-- Ermittelt eine Abholoption anhand der Abholzeit, des Abholtages und der User-ID des Besitzers des Buches.
-- Über ide Abholzeit und den -tag wird geprüft, ob es ein Zeitfenster gibt, das der angegebenen Zeit entspricht. Zudem
-- wird die die Abholadresse des Besitzers ermittelt. Auch hier erfolgt aus Gründen der Vereinfachung die Selektion der
-- ersten gefundenen Abholadresse, wenngleich die Person auch mehrere angeben könnte.
CREATE OR REPLACE FUNCTION getFirstPickupOption(p_pickup_time time, p_pickup_day integer, p_user_id BIGINT)
    RETURNS BIGINT
    LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN (SELECT pickup_option_id
            FROM pickup_option po
                     INNER JOIN user_address a on po.user_address_id = a.user_address_id
                     INNER JOIN timeslot t on po.timeslot_id = t.timeslot_id
                     INNER JOIN address_type adt on a.address_type_id = adt.address_type_id
            WHERE a.user_id = p_user_id AND t.begin_time <= p_pickup_time AND t.end_time >= p_pickup_time AND
                  t.day_of_week = p_pickup_day AND adt.name = 'PICK_UP'
               OR po.timeslot_id is NULL
            LIMIT 1);
END
$$;