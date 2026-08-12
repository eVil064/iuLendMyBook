/* Ermittelt mit Hilfe der Funktion getUserByEmail eine User-ID anhand der E-Mailadresse. Wird dort keine E-Mailadresse
   übergeben, wirft die Funktion eine Exception. Wird hingegeben der User nicht gefunden, wird er mit Hilfe der
   übergebenen Daten neu angelegt. Sollte der Name nicht angegeben werden, so wird bei der Anlage eine 'violates not-null
   constraint'-Exception geworfen, da der Nachname bei Anlage Pflicht ist.
*/
CREATE OR REPLACE PROCEDURE getOrCreateUserAccount(p_fullname varchar(110), p_email varchar(255), p_phone varchar(20),
                                                   OUT p_user_id BIGINT)
    LANGUAGE plpgsql AS
$$
BEGIN
    p_user_id := getUserByEmail(p_email);

    IF p_user_id IS NULL THEN
        INSERT INTO user_account (academic_title, first_name, last_name, email, phone)
        VALUES (getTitle(p_fullname), getFirstname(p_fullname),
                getLastname(p_fullname), p_email, p_phone)
        RETURNING user_id INTO p_user_id;
        RAISE NOTICE 'New user successfully created. ID: %', p_user_id;
    END IF;
END;
$$;


/* Diese Prozedur aktualisiert einen User-Account anhand der E-Mailadresse. Dazu wird zunächst mit der Prozedur
   getOrCreateUserAccount ein bestehender Account ermittelt oder bei Bedarf neu angelegt.
   Im Anschluss werden die Daten aktualisiert, sofern notwendig.
 */
CREATE OR REPLACE PROCEDURE updateUserAccount(p_fullname varchar(110), p_email varchar(255), p_newEmail varchar(255),
                                              p_phone varchar(20), p_status varchar(10),
                                              OUT p_user_id BIGINT)
    LANGUAGE plpgsql AS
$$
BEGIN
    CALL getOrCreateUserAccount(p_fullname, p_email, p_phone, p_user_id);

    UPDATE user_account
    SET first_name     = CASE WHEN p_fullname IS NOT NULL THEN getFirstName(p_fullname) ELSE first_name END,
        last_name      = CASE WHEN p_fullname IS NOT NULL THEN getLastName(p_fullname) ELSE last_name END,
        academic_title = CASE WHEN p_fullname IS NOT NULL THEN getTitle(p_fullname) ELSE academic_title END,
        email          = CASE WHEN p_newEmail IS NULL THEN email ELSE p_newEmail END,
        phone          = CASE WHEN p_phone IS NULL THEN phone ELSE p_phone END,
        status         = CASE WHEN p_status IS NULL THEN status ELSE p_status END
    WHERE user_id = p_user_id;
    RAISE NOTICE 'User with ID % updated successfully.', p_user_id;
END;
$$;

CREATE OR REPLACE PROCEDURE createUserAddress(p_user_id BIGINT, p_address_id BIGINT, p_address_type varchar(10),
                                              OUT p_user_address_id BIGINT)
    LANGUAGE plpgsql AS
$$
DECLARE
    v_type_id BIGINT;
BEGIN
    SELECT address_type_id INTO v_type_id FROM address_type WHERE name = p_address_type;

    INSERT INTO user_address (user_id, address_id, address_type_id)
    VALUES (p_user_id, p_address_id, v_type_id)
    RETURNING address_id INTO p_user_address_id;
    RAISE NOTICE 'User address with ID % updated successfully.', p_user_address_id;
END;
$$;

CALL getOrCreateUserAccount('Manfred Mitarbeiter', 'manni@mitarbieter.de', NULL, NULL)
