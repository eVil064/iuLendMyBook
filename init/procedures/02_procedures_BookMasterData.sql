/* Mit Hilfe der Prozedur wird ein Eintrag in der Tabelle address gesucht. Wird dieser nicht gefunden,
   so wird ein neuer Eintrag erzeugt. Dazu wird zunächst anhand der Angaben zum Ort der zugehörige Ort aus der Tabelle
   location ermittelt. Ist dieser nicht vorhanden, wird versucht anhand der Daten einen neuen Ort anzulegen.
   Ist der Ort vorhanden oder wird erfolgreich angelegt, wird eine neue Adresse erstellt.
*/
CREATE OR REPLACE PROCEDURE getOrCreateAddress(p_street varchar(255), p_number varchar(10), p_city varchar(50),
                                               p_postal_code varchar(10), p_country varchar(50),
                                               p_longitude numeric(9, 6), p_latitude numeric(9, 6),
                                               OUT p_address_id BIGINT)
    LANGUAGE plpgsql AS
$$
DECLARE
    v_location_id BIGINT;
BEGIN
    CALL getOrCreateLocation(p_postal_code, p_city, p_country, v_location_id);
    SELECT address_id
    INTO p_address_id
    FROM address a
    WHERE a.street = p_street
      and a.number = p_number
      and a.location_id = v_location_id;

    IF p_address_id IS NULL THEN
        INSERT INTO address (street, number, location_id, longitude, latitude)
        VALUES (p_street, p_number, v_location_id, p_longitude,
                p_latitude)
        RETURNING address_id INTO p_address_id;
        RAISE NOTICE 'New address successfully created. ID: %', p_address_id;
    ELSE
        RAISE NOTICE 'Address with ID % found.', p_address_id;
    END IF;
END;
$$;

/* Mit Hilfe der Prozedur wird anhand der Bezeichnung und der Adresse ein Verlag gesucht. Wird kein Verlag gefunden,
   wird dieser neu erstellt. Durch Aufruf der Methode getOrCreateAddress wird eine bestehende Adresse gesucht oder
   ggf. neu angelegt und dem Verlag zugewiesen
 */
CREATE OR REPLACE PROCEDURE getOrCreatePublisher(p_name varchar(255), p_website varchar(255), p_street varchar(255),
                                                 p_number varchar(10), p_city varchar(50), p_postal_code varchar(10),
                                                 p_country varchar(50),
                                                 OUT v_publisher_id BIGINT)
    LANGUAGE plpgsql AS
$$
DECLARE
    v_address_id BIGINT;
BEGIN
    IF p_city IS NOT NULL THEN
        CALL getOrCreateAddress(p_street, p_number, p_city, p_postal_code, p_country, NULL, NULL, v_address_id);
    END IF;

    IF v_address_id IS NULL THEN
        SELECT publisher_id INTO v_publisher_id FROM publisher p WHERE p.name = p_name and p.address_id IS NULL;
    ELSE
        SELECT publisher_id INTO v_publisher_id FROM publisher p WHERE p.name = p_name and p.address_id = v_address_id;
    END IF;

    IF v_publisher_id IS NULL THEN
        INSERT INTO publisher (name, website, address_id)
        VALUES (p_name, p_website, v_address_id)
        RETURNING publisher_id INTO v_publisher_id;
        RAISE NOTICE 'New publisher successfully created. ID: %', v_publisher_id;
    ELSE
        RAISE NOTICE 'Found publisher with ID %', v_publisher_id;
    end if;
END;
$$;

/* Mit Hilfe der Prozedur wird anhand des vollständigen Namens ein Autor gesucht. Wird kein Autor gefunden,
   wird dieser neu erstellt.
 */
CREATE OR REPLACE PROCEDURE getOrCreateAuthor(p_firstname varchar(50), p_lastname varchar(50),
                                              p_academic_title varchar(10),
                                              OUT v_author_id BIGINT)
    LANGUAGE plpgsql AS
$$
BEGIN

    INSERT INTO author (last_name, first_name, academic_title)
    VALUES (p_lastname, p_firstname, p_academic_title)
    RETURNING author_id INTO v_author_id;
    RAISE NOTICE 'New author successfully created. ID: %', v_author_id;

EXCEPTION
    WHEN unique_violation THEN
        SELECT author_id
        INTO v_author_id
        FROM author a
        WHERE a.first_name = p_firstname
          and a.last_name = p_lastname
          and a.academic_title IS NOT DISTINCT FROM p_academic_title;
        RAISE NOTICE 'Found author with ID %', v_author_id;
END;
$$;

/* Erstellt oder aktualisiert einen Buchtitel. Dazu wird zunächst anhand der FUNCTION getBookByIsbn geprüft, ob der
   Buchtitel vorhanden ist. Ist der Titel noch nicht vorhanden, wird dieser neu angelegt. Dazu werden der Verlag und
   die Sprache anhand des Namens bzw. des ISO-Codes ermittelt.
   Ist der Titel bereits vorhanden werden zunächst die bereits vorhandenen Zuordnungen zu Genres und Autoren entfernt,
   um zu verhindern, dass die Zuordnungstabelle durch Änderungen an den beiden Parametern unbegrenzt weiterwächst.
   Unabhängig von der Anlage oder der Aktualisierung werden die beiden Verknüpfungstabellen book_genre und book_author
   aus den Parametern befüllt. Ist ein Autor oder ein Genre noch nicht vorhanden, wird der Datensatz neu angelegt und
   anschließend zugeordnet. Die Ermittlung eines vorhanden Datensatzes folgt dabei der jeweiligen Definitionen der UNIQUE
   Constraints
 */
CREATE OR REPLACE PROCEDURE createOrUpdateBook(p_user_id bigint, p_title varchar(255), p_isbn varchar(13),
                                               p_description text,
                                               p_year smallint,
                                               p_edition smallint, p_language_iso_code varchar(5),
                                               p_publisher_name varchar(255),
                                               p_author_array varchar(110)[],
                                               p_genre_array varchar(50)[], OUT p_book_id BIGINT)
    LANGUAGE plpgsql AS
$$
DECLARE
    v_publisher_id   BIGINT;
    v_language_id    BIGINT;
    v_genre          varchar(50);
    v_genre_id       BIGINT;
    v_author         varchar(110);
    v_author_id      BIGINT;
    v_firstname      varchar(50);
    v_lastname       varchar(50);
    v_academic_title varchar(10);
    v_userCanEdit BOOLEAN;
BEGIN
    p_book_id := getBookByIsbn(p_isbn);
    v_userCanEdit := EXISTS (SELECT 1 from book_copy where book_id = p_book_id and owner_id = p_user_id) OR
                     isadmin(p_user_id);
    v_language_id := getLanguage(p_language_iso_code);
    v_publisher_id := getPublisher(p_publisher_name);

    IF p_book_id IS NULL THEN
        INSERT INTO book (title, isbn, description, publication_year, edition, language_id, publisher_id)
        VALUES (p_title, p_isbn, p_description, p_year, p_edition,
                v_language_id, v_publisher_id)
        RETURNING book_id INTO p_book_id;
        RAISE NOTICE 'Book "%" with ID % successfully created', p_title, p_book_id;
    ELSIF v_userCanEdit THEN
        DELETE from book_genre WHERE book_id = p_book_id;
        DELETE from book_author WHERE book_id = p_book_id;
        UPDATE book
        SET title            = p_title,
            description      = p_description,
            publication_year = p_year,
            edition          = p_edition,
            language_id      = v_language_id,
            publisher_id     = v_publisher_id
        WHERE book_id = p_book_id
        RETURNING book_id INTO p_book_id;
        RAISE NOTICE 'Book "%" with ID % successfully updated', p_title, p_book_id;
    ELSE
        RAISE EXCEPTION 'You are not allowed to edit this title';
    END IF;

    FOREACH v_genre IN ARRAY p_genre_array
        LOOP
            CALL getOrCreateGenre(v_genre, v_genre_id);
            INSERT INTO book_genre
            VALUES (p_book_id, v_genre_id)
            ON CONFLICT DO NOTHING;
        END LOOP;

    FOREACH v_author IN ARRAY p_author_array
        LOOP
            v_academic_title := getTitle(v_author);
            v_firstname := getFirstname(v_author);
            v_lastname := getLastname(v_author);

            CALL getOrCreateAuthor(v_firstname, v_lastname, v_academic_title, v_author_id);

            INSERT INTO book_author
            VALUES (p_book_id, v_author_id)
            ON CONFLICT DO NOTHING;
        END LOOP;
END;
$$;

/* Die Prozedur löscht einen Buchtitel anhand der übergebenen ISBN. Dabei wird zunächst anhand der Funktion getBookByISBN
   geprüft, ob die ISBN existiert. Ist das Buch vorhanden, wird im Anschluss überprüft, ob der User eine  über die Rolle
   'ADMIN' verfügt. Ist dies nicht der Fall, wird das Löschen unterbunden.
   Wird ein Fremdschlüssel verletzt, da es z.B. noch verknüpfte Exemplare gibt, wird eine Meldung ausgegeben.
*/
CREATE OR REPLACE PROCEDURE deleteBook(p_isbn varchar(13), p_current_userid BIGINT)

    LANGUAGE plpgsql AS
$$
BEGIN

    IF getBookByIsbn(p_isbn) IS NULL THEN
        RAISE EXCEPTION 'Book with ISBN % cannot be deleted as it does not exist', p_isbn;
    ELSE
        IF NOT EXISTS (SELECT 1
                       FROM user_account ua
                                INNER JOIN user_role ur on ua.user_id = ur.user_id
                                INNER JOIN role r on ur.role_id = r.role_id
                       WHERE r.name = 'ADMIN'
                         and ua.user_id = p_current_userid) THEN
            RAISE EXCEPTION 'Only administrators are allowed to delete book titles';
        END IF;

        DELETE FROM book b WHERE isbn = p_isbn;
        RAISE NOTICE 'Book with ISBN % successfully deleted', p_isbn;
    END IF;

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Book may not be deleted. At least one copy is referenced';

END;
$$;

/* Diese Funktion überprüft, dass durch das Löschen eines Verlags nicht kaskadierend die Adresse gelöscht wird, da diese
   einem weiteren Verlag oder einem Benutzer zugeordnet sein kann,
 */
CREATE OR REPLACE FUNCTION deletePublisherAndCheckAddress(p_name varchar(255))
    RETURNS TABLE
            (
                address_id     BIGINT,
                publisher_name varchar
            )
    LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN QUERY WITH deleted_publishers AS
                          (DELETE FROM publisher p WHERE p.name = p_name AND p.address_id IS NOT NULL
                              RETURNING p.address_id, p.name)
                 SELECT a.address_id, dp.name
                 from address a
                          INNER JOIN deleted_publishers dp on a.address_id = dp.address_id;
END;
$$;