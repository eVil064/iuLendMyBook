/* Mit Hilfe der Prozedur wird ein Eintrag in der Tabelle genre erzeugt.
   Ist eine Bezeichnung bereits vorhanden wird die ID des bestehenden Eintrags zurückgegeben.
   Andernfalls wird ein neuer Eintrag angelegt und die ID dieses Eintrags als Ergebnis geliefert.
 */
CREATE OR REPLACE PROCEDURE getOrCreateGenre(p_name varchar(50),
                                             OUT p_id BIGINT)
    LANGUAGE plpgsql AS
$$
BEGIN
    INSERT INTO genre (name)
    VALUES (p_name)
    RETURNING genre_id INTO p_id;
    RAISE NOTICE 'New genre successfully created. ID: %', p_id;

EXCEPTION
    WHEN unique_violation THEN
        SELECT genre_id INTO p_id from genre g WHERE g.name = p_name;
        RAISE EXCEPTION 'Genre already exists. Return ID %', p_id;
END;
$$;

/* Mit Hilfe der Prozedur wird ein Eintrag in der Tabelle language gesucht und bei Bedarf neu erzeugt.
   Ist ein ISO-Code oder eine Bezeichnung bereits vorhanden, wird die ID des bestehenden Eintrags zurückgegeben.
   Andernfalls wird ein neuer Eintrag angelegt und die ID dieses Eintrags als Ergebnis geliefert.
 */
CREATE OR REPLACE PROCEDURE getOrCreateLanguage(p_name varchar(50), p_isoCode varchar(5),
                                                OUT p_id BIGINT)
    LANGUAGE plpgsql AS
$$
BEGIN
    INSERT INTO language (name, iso_code)
    VALUES (p_name, p_isoCode)
    RETURNING language_id INTO p_id;
    RAISE NOTICE 'New language successfully created. ID: %', p_id;

EXCEPTION
    WHEN unique_violation THEN
        SELECT language_id INTO p_id from language l WHERE l.name = p_name or l.iso_code = p_isoCode;
        RAISE EXCEPTION 'Language already exists. Return ID: %', p_id;
END;
$$;

/* Mit Hilfe der Prozedur wird ein Eintrag in der Tabelle country gesucht und bei Bedarf neu erzeugt.
   Ist ein ISO-Code bereits vorhanden, wird die ID des bestehenden Eintrags zurückgegeben.
   Andernfalls wird ein neuer Eintrag angelegt und die ID dieses Eintrags als Ergebnis geliefert.
 */
CREATE OR REPLACE PROCEDURE getOrCreateCountry(p_name varchar(50), p_iso_code varchar(2),
                                               OUT p_id BIGINT)
    LANGUAGE plpgsql AS
$$
BEGIN
    INSERT INTO country (name, iso_code)
    VALUES (p_name, p_iso_code)
    RETURNING country_id INTO p_id;
    RAISE NOTICE 'New country successfully created. ID: %', p_id;

EXCEPTION
    WHEN unique_violation THEN
        SELECT country_id INTO p_id from country c WHERE c.iso_code = p_iso_code;
        RAISE EXCEPTION 'ISO-Code already exists. Return ID: %', p_id;
END;
$$;

/* Mit Hilfe der Prozedur wird ein Eintrag in der Tabelle location gesucht und bei Bedarf neu erzeugt.
   Anhand der Angabe zum Land wird zunächst die ID des Landes aus der anderen Tabelle ermittelt.
   Kann das Land nicht gefunden werden, wird ein Fehler geworfen.
   Zudem wird geprüft, ob ein Eintrag aus Postleitzahl und Ort bereits besteht. In diesem Fall wird die ID des
   bestehenden Eintrags zurückgegeben. Andernfalls wird ein neuer Eintrag angelegt und die ID dieses Eintrags als
   Ergebnis geliefert.
 */
CREATE OR REPLACE PROCEDURE getOrCreateLocation(p_postal_code varchar(10), p_city varchar(50),
                                                p_country varchar(50),
                                                OUT p_location_id BIGINT)
    LANGUAGE plpgsql AS
$$
DECLARE
    v_country_id BIGINT;
    v_notice     text;
BEGIN
    SELECT country_id INTO v_country_id from country where name = p_country;

    IF v_country_id IS NULL THEN
        RAISE EXCEPTION 'Country "%" could not be found. Please insert country first', p_country;
    ELSE
        SELECT location_id
        INTO p_location_id
        FROM location l
        where l.postal_code = p_postal_code
          and l.city = p_city
          and l.country_id = v_country_id;

        IF p_location_id IS NULL THEN
            INSERT INTO location (postal_code, city, country_id)
            VALUES (p_postal_code, p_city, v_country_id)
            RETURNING location_id INTO p_location_id;
            v_notice := format('New location with ID %s successfully created.', p_location_id);
        ELSE
            v_notice := format('Found location with ID: %s', p_location_id);
        END IF;
    END IF;

    RAISE NOTICE '%', v_notice;
END;
$$;

