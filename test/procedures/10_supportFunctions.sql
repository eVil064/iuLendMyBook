-- Ermittelt eine Sprache anhand des ISO-Codes
CREATE OR REPLACE FUNCTION getLanguage(p_iso_code varchar(5)) RETURNS BIGINT
    LANGUAGE plpgsql AS
$$
DECLARE
    v_language_id BIGINT;
BEGIN
    SELECT language_id INTO v_language_id FROM language WHERE iso_code = p_iso_code;
    RETURN v_language_id;
END;
$$;

-- Ermittelt den Verlag anhand des Verlagsnamen oder erstellt einen neuen, wenn kein Verlag gefunden werden kann
CREATE OR REPLACE FUNCTION getPublisher(p_name varchar(255)) RETURNS BIGINT
    LANGUAGE plpgsql AS
$$
DECLARE
    v_publisher_id BIGINT;
BEGIN
    SELECT publisher_id INTO v_publisher_id FROM publisher p WHERE p.name = p_name and p.address_id IS NULL;

    IF v_publisher_id IS NULL THEN
        CALL getOrCreatePublisher(p_name, NULL, NULL, NULL, NULL, NULL, NULL, v_publisher_id);
    END IF;
    RETURN v_publisher_id;
END;
$$;

-- Extrahiert den Vornamen aus einem String
CREATE OR REPLACE FUNCTION getFirstname(p_complete_name varchar(110)) RETURNS varchar(50)
    LANGUAGE plpgsql AS
$$
BEGIN
    IF array_length(string_to_array(p_complete_name, ' '), 1) = 3 THEN
        RETURN split_part(p_complete_name, ' ', 2);
    ELSIF array_length(string_to_array(p_complete_name, ' '), 1) = 2 THEN
        RETURN split_part(p_complete_name, ' ', 1);
    ELSE
        RETURN NULL;
    END IF;
END;
$$;


-- Extrahiert den Nachnamen aus einem String
CREATE OR REPLACE FUNCTION getLastname(p_complete_name varchar(110)) RETURNS varchar(50)
    LANGUAGE plpgsql AS
$$
BEGIN
    IF array_length(string_to_array(p_complete_name, ' '), 1) = 3 THEN
        RETURN split_part(p_complete_name, ' ', 3);
    ELSIF array_length(string_to_array(p_complete_name, ' '), 1) = 2 THEN
        RETURN split_part(p_complete_name, ' ', 2);
    ELSE
        RETURN split_part(p_complete_name, ' ', 1);
    end if;
END;
$$;

-- Extrahiert den Titel aus einem String
CREATE OR REPLACE FUNCTION getTitle(p_complete_name varchar(110)) RETURNS varchar(10)
    LANGUAGE plpgsql AS
$$
BEGIN
    IF array_length(string_to_array(p_complete_name, ' '), 1) = 3 THEN
        RETURN split_part(p_complete_name, ' ', 1);
    ELSE
        RETURN NULL;
    end if;
END;
$$;

-- Ermittelt einen User mit eines Typs
CREATE OR REPLACE FUNCTION findAdminUser() RETURNS BIGINT
    LANGUAGE plpgsql AS
$$
DECLARE
    v_user_id BIGINT;
BEGIN
    SELECT ua.user_id
    INTO v_user_id
    FROM user_account ua
             INNER JOIN user_role ur on ua.user_id = ur.user_id
             INNER JOIN role r on ur.role_id = r.role_id
    WHERE r.name = 'ADMIN'
    LIMIT 1;
    RETURN v_user_id;
END;
$$;

-- Ermittelt ein Buch anhand der ISBN
CREATE OR REPLACE FUNCTION getBookByISBN(p_isbn varchar(13)) RETURNS BIGINT
    LANGUAGE plpgsql AS
$$
DECLARE
    v_book_id BIGINT;
BEGIN
    SELECT book_id INTO v_book_id FROM book WHERE isbn = p_isbn;
    RETURN v_book_id;
END;
$$;


/* Diese Funktion überprüft, dass durch das Löschen eines Verlags nicht kaskadierend die Adresse gelöscht wird, da diese
   einem weiteren Verlag oder einem Benutzer zugeordnet sein kann,
 */
CREATE OR REPLACE FUNCTION deletePublisherAndCheckAddress(p_name varchar(255)) RETURNS INTEGER
    LANGUAGE plpgsql AS
$$
DECLARE
    v_address_id BIGINT;
BEGIN
    DELETE FROM publisher WHERE name = p_name AND address_id IS NOT NULL RETURNING address_id INTO v_address_id;
    RETURN (SELECT count(address_id) from address where address_id = v_address_id);
END;
$$;

-- Ermittelt einen User anhand der Mailadresse
CREATE OR REPLACE FUNCTION getUserByEmail(p_email varchar(50)) RETURNS BIGINT
    LANGUAGE plpgsql AS
$$
BEGIN
    IF p_email IS NULL THEN
        RAISE EXCEPTION 'The email address must not be NULL';
    END IF;

    RETURN (SELECT user_id FROM user_account WHERE email = p_email);
END;
$$;

-- Ermittelt eine Addresse anhand von Straße, Hausnummer, Postleitzahl, Ort
CREATE OR REPLACE FUNCTION getAddress(p_street varchar(50), p_number varchar(10), p_postal_code varchar(10),
                                      p_city varchar(50), p_country_code varchar(2)) RETURNS BIGINT
    LANGUAGE plpgsql AS
$$
BEGIN
    RETURN (SELECT address_id
            FROM address a
                     INNER JOIN location l on a.location_id = l.location_id
                     INNER JOIN country c on l.country_id = c.country_id
            WHERE c.iso_code = p_country_code
              and l.postal_code = p_postal_code
              and l.city = p_city
              and a.street = p_street
              and a.number = p_number);
END;
$$;

/* Diese Funktion löscht einen User und überprüft, dass in der Adress-Zuordnungs-Tabelle kein Eintrag zum
   User mehr vorhanden ist.
 */
CREATE OR REPLACE FUNCTION deleteUserAccountAndCheckAddresses(p_email varchar(255)) RETURNS INTEGER
    LANGUAGE plpgsql AS
$$
DECLARE
    v_user_id BIGINT;
BEGIN
    v_user_id := getUserByEmail(p_email);
    DELETE FROM user_account WHERE user_id = v_user_id;
    RETURN (SELECT count(user_id) from user_address where user_id = v_user_id);
END;
$$;


-- Ermittelt ein Buchexemplar anhand der Buch-ID und der ID des Owners
CREATE OR REPLACE FUNCTION getBookCopy(p_book_id BIGINT, p_user_id BIGINT) RETURNS BIGINT
    LANGUAGE plpgsql AS
$$
BEGIN
    RETURN (SELECT book_copy_id FROM book_copy WHERE owner_id = p_user_id and book_id = p_book_id);
END;
$$;