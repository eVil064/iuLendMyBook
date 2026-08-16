CREATE OR REPLACE PROCEDURE createOrUpdateBookCopy(p_isbn varchar(13), p_user_id BIGINT, p_loan_duration smallint,
                                                   p_condition varchar(50), p_update boolean,
                                                   OUT p_copy_id BIGINT)
    LANGUAGE plpgsql AS
$$
DECLARE
    p_book_id BIGINT;
BEGIN
    p_book_id := getBookByIsbn(p_isbn);

    IF p_book_id IS NULL THEN
        RAISE EXCEPTION 'Copy cannot be created as the book title does not exist. Please create book first';
    END IF;

    IF p_update THEN
        p_copy_id := getbookcopy(p_book_id, p_user_id);
        IF p_copy_id IS NOT NULL THEN
            UPDATE book_copy
            SET loan_duration_days = p_loan_duration,
                condition          = p_condition
            WHERE book_copy_id = p_copy_id;
            RAISE NOTICE 'Book copy with ISBN % for user % successfully updated', p_isbn, p_user_id;
        ELSE
            RAISE EXCEPTION 'No copy for this user found. Copy cannot be updated';
        END IF;
    ELSE
        INSERT INTO book_copy (book_id, owner_id, loan_duration_days, condition)
        VALUES (p_book_id, p_user_id, p_loan_duration, p_condition)
        RETURNING book_copy_id INTO p_copy_id;
        RAISE NOTICE 'Book copy with ISBN % for user % successfully created', p_isbn, p_user_id;
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE deleteBookCopy(p_isbn varchar(13), p_user_id BIGINT)
    LANGUAGE plpgsql AS
$$
DECLARE
    v_book_copy_id BIGINT;
BEGIN
    v_book_copy_id := getBookCopy(getBookByIsbn(p_isbn), p_user_id);
    IF v_book_copy_id IS NULL THEN
        RAISE NOTICE 'Book copy with ISBN % for user % does not exist and cannot be deleted', p_isbn, p_user_id;
    END IF;
    DELETE FROM book_copy WHERE book_copy_id = v_book_copy_id;
END;
$$;

CALL createOrUpdateBook('Lord of the Rings - Fellowship of the Ring', '9780261102354',
                        'The first part of The Lord of the Rings. Frodo Baggins inherits the powerful One Ring ' ||
                        'and must leave the Shire to prevent it from falling into the hands of the Dark Lord Sauron. ' ||
                        'Together with a fellowship of companions, he begins a dangerous journey across Middle-earth.',
                        1977::smallint, 1::smallint, 'en-US', 'HarperCollins Publishers Ltd',
                        ARRAY ['J.R.R Tolkien'], ARRAY ['Science-Fiction'], NULL);
-- Erstellen eines Buchexemplars
CALL createOrUpdateBookCopy('9780261102354', getuserbyemail('clara.neumann@example.org'), 10::smallint, 'Guter Zustand',
                            false, NULL);
-- Aktualisierung eines Buchexemplars durch einen berechtigten User
CALL createOrUpdateBookCopy('9780261102354', getuserbyemail('clara.neumann@example.org'), 60::smallint, 'Guter Zustand',
                            true, NULL);
-- Aktualisierung eines Buchexemplars durch einen nicht berechtigten User
CALL createOrUpdateBookCopy('9780261102354', getuserbyemail('joerg.reuter@example.org'), 10::smallint, 'Guter Zustand',
                            true, NULL);
-- Löschversuch eines Exemplars durch einen unberechtigten User
CALL deleteBookCopy('9780261102354', getuserbyemail('jonas.reuter@example.org'));