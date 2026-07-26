-- Mit Hilfe der Prozedur wird ein Eintrag in der Tabelle country erzeugt.
-- Ist ein ISO-Code bereits vorhanden, wird die ID des bestehenden Eintrags zurückgegeben.
-- Andernfalls wird ein neuer Eintrag angelegt und die ID dieses Eintrags als Ergebnis geliefert.
CREATE OR REPLACE PROCEDURE createCountry(p_name varchar(50), p_iso_code varchar(2))
    LANGUAGE plpgsql AS
$$
DECLARE
    id INTEGER;
BEGIN
    INSERT INTO country (name, iso_code)
    VALUES (p_name, p_iso_code)
    RETURNING country_id INTO id;
    RAISE NOTICE 'Creation successful. New id: %', id;

EXCEPTION
    WHEN unique_violation THEN
        SELECT country_id from country c WHERE c.iso_code = p_iso_code INTO id;
        RAISE NOTICE 'ISO-Code already present. Found id: %', id;
END;
$$;

-- Anlage eines neuen Eintrags
CALL createCountry('Honduras', 'HD');
-- Anlage eines bestehenden Eintrags
CALL createCountry('Greece', 'GR');
