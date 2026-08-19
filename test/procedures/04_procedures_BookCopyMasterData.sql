/* Ermittelt zunächst anhand der ISBN die ID des Buches, zu dem ein Exemplar erstellt werden soll.
   Kann die ID nicht ermittelt werden, wird ein Fehler ausgegeben. Andernfalls wird eine neues Exemplar des Buches für
   den angegebenen User angelegt.
*/
CREATE OR REPLACE PROCEDURE createBookCopy(p_isbn varchar(13), p_user_id BIGINT, p_loan_duration smallint,
                                           p_condition varchar(50), OUT p_copy_id BIGINT)
    LANGUAGE plpgsql AS
$$
DECLARE
    p_book_id BIGINT;
BEGIN
    p_book_id := getBookByIsbn(p_isbn);

    IF p_book_id IS NULL THEN
        RAISE EXCEPTION 'Copy cannot be created as the book title does not exist. Please create book first';
    END IF;

    INSERT INTO book_copy (book_id, owner_id, loan_duration_days, condition)
    VALUES (p_book_id, p_user_id, p_loan_duration, p_condition)
    RETURNING book_copy_id INTO p_copy_id;
    RAISE NOTICE 'Book copy with ISBN % for user % successfully created', p_isbn, p_user_id;
END;
$$;

-- Löscht ein Buchexemplar, prüft jedoch zunächst anhand der Funktion isActionAllowed, ob die Löschung zulässig ist.
-- Die Funktion prüft dabei, ob das Exemplar dem User zugeordnet ist oder der User eine ADMIN-Rolle besitzt.
CREATE OR REPLACE PROCEDURE deleteBookCopy(p_book_copy_id BIGINT, p_user_id BIGINT)
    LANGUAGE plpgsql AS
$$
BEGIN
    IF isActionAllowed(p_book_copy_id, p_user_id) THEN
        DELETE FROM book_copy WHERE book_copy_id = p_book_copy_id;
        RAISE NOTICE 'Book copy was deleted successfully';
    END IF;
END;
$$;

-- Aktualisiert ein Buchexemplar, prüft jedoch zunächst anhand der Funktion isActionAllowed, ob die Aktualisierung zulässig ist.
-- Die Funktion prüft dabei, ob das Exemplar dem User zugeordnet ist oder der User eine ADMIN-Rolle besitzt.
CREATE OR REPLACE PROCEDURE updateBookCopy(p_book_copy_id BIGINT, p_user_id BIGINT, p_loan_duration smallint,
                                           p_condition varchar(50))
    LANGUAGE plpgsql AS
$$
BEGIN
    IF isActionAllowed(p_book_copy_id, p_user_id) THEN
        UPDATE book_copy
        SET loan_duration_days = p_loan_duration,
            condition          = p_condition
        WHERE book_copy_id = p_book_copy_id;
        RAISE NOTICE 'Book copy was updated successfully';
    END IF;
END;
$$;

-- Prüft, ob der übergebene User der Besitzer des Exemplars ist oder die ADMIN-Rolle inne hat und ob das Exemplar vorhanden ist
CREATE OR REPLACE FUNCTION isActionAllowed(p_book_copy_id BIGINT, p_user_id BIGINT) RETURNS BOOLEAN
    LANGUAGE plpgsql AS
$$
DECLARE
    v_isAllowed BOOLEAN;
BEGIN
    v_isAllowed := EXISTS (SELECT 1 FROM book_copy where book_copy_id = p_book_copy_id AND owner_id = p_user_id)
        OR isAdmin(p_user_id);
    IF NOT v_isAllowed THEN
        RAISE EXCEPTION 'Action cannot be performed. The copy may not exist or you are not allowd to perform the selected action';
    END IF;

    RETURN v_isAllowed;
END;
$$;

-- Ermittelt die Buchexemplare eines Users anhand der ISBN und der ID des Owners
CREATE OR REPLACE FUNCTION getBookCopiesByUser(p_isbn varchar(13), p_user_id BIGINT) RETURNS BIGINT[]
    LANGUAGE plpgsql AS
$$
BEGIN
    RETURN ARRAY((SELECT book_copy_id
                  FROM book_copy bc
                           INNER JOIN book b on bc.book_id = b.book_id
                  WHERE owner_id = p_user_id
                    and b.isbn = p_isbn));
END;
$$;

-- Ermittelt die Buchexemplare eines Buchtitels und gibt die IDs zurück
CREATE OR REPLACE FUNCTION getBookCopiesByISBN(p_isbn varchar(13)) RETURNS BIGINT[]
    LANGUAGE plpgsql AS
$$
BEGIN
    RETURN ARRAY(SELECT book_copy_id
                 FROM book_copy bc
                          INNER JOIN book b on bc.book_id = b.book_id
                 WHERE b.isbn = p_isbn);
END;
$$;
