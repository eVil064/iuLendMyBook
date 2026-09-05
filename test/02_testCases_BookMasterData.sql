-- 02.1 Adressen
---------------------------
-- 02.1.1 Anlage einer neuen Adresse und bestehendem Ort
CALL getOrCreateAddress('Musterstraße', '14a', 'Berlin', '10178'
    , 'Germany', 13.41321, 52.5219, NULL);
-- 02.1.3 Anlage einer neuen Adresse mit neuem Ort
CALL getOrCreateAddress('Lombard Street', '1', 'San Francisco', 'CA 94111',
                        'United States', -122.40277, 37.80413, NULL);
-- 02.1.2 CHECK-Constraint Violation: Anlage einer Adresse ungültigem Längen-/Breitengrad
CALL getOrCreateAddress('Kastanienallee', '12', 'Berlin', '10178'
    , 'Germany', 92.41321, -195.5219, NULL);

-- 02.2 Verlage
---------------------------
-- 02.2.1 Anlage eines Verlags mit vorhandener Adresse
CALL getOrCreatePublisher('HarperCollins Publishers Ltd', 'https://harpercollins.co.uk', 'Robroyston Gate',
                          '1', 'Glasgow', 'G33 1JN', 'United Kingdom', NULL);
-- 02.2.2 Anlage eines Verlags ohne Adresse
CALL getOrCreatePublisher('Das Verlagshaus', 'http://dasverlagshaus.de', NULL,
                          NULL, NULL, NULL, NULL, NULL);
-- 02.2.3 UNIQUE-Constraint Violation: Erneute Anlage des gleichen Verlags ohne Adresse
INSERT INTO publisher (name, website, address_id)
VALUES ('Das Verlagshaus', 'http://dasverlagshaus', NULL);
-- 02.2.4 Prüfung referentielle Integrietät: Löschen des Verlags löscht nicht die Adresse
SELECT deletepublisherandcheckaddress('Der Verlag');

-- 02.3 Autoren
---------------------------
-- 02.3.1 Anlage eines Autors
CALL getOrCreateAuthor('J.R.R', 'Tolkien', NULL, NULL);
-- 02.3.2 UNIQUE Constraint Violation: erneute Anlage des gleichen Autors
INSERT INTO author (academic_title, first_name, last_name)
VALUES (NULL, 'J.R.R', 'Tolkien');
-- 02.3.3 Abruf von Buchtiteln mit allen Autoren
SELECT isbn, title, string_agg(concat(a.last_name, ', ', a.first_name), '; ') authors
FROM author a
         INNER JOIN public.book_author ba on a.author_id = ba.author_id
         INNER JOIN public.book b on ba.book_id = b.book_id
GROUP BY title, isbn;

-- 02.4 Bücher
-- 02.4.1 Anlegen eines neuen Buches
CALL createOrUpdateBook('Lord of the Rings - Fellowship of the Ring', '9780261102354',
                        'The first part of The Lord of the Rings. Frodo Baggins inherits the powerful One Ring ' ||
                        'and must leave the Shire to prevent it from falling into the hands of the Dark Lord Sauron. ' ||
                        'Together with a fellowship of companions, he begins a dangerous journey across Middle-earth.',
                        1977::smallint, 1::smallint, 'en-US', 'HarperCollins Publishers Ltd',
                        ARRAY ['J.R.R. Tolkien'], ARRAY ['Science-Fiction'], NULL);
-- 02.4.2 Aktualisierung eines Buches
CALL createOrUpdateBook('Lord of the Rings - Fellowship of the Ring', '9780261102354',
                        'The first part of The Lord of the Rings. Frodo Baggins inherits the powerful One Ring ' ||
                        'and must leave the Shire to prevent it from falling into the hands of the Dark Lord Sauron. ' ||
                        'Together with a fellowship of companions, he begins a dangerous journey across Middle-earth.',
                        2007::smallint, 68::smallint, 'en-US', 'HarperCollins Publishers Ltd',
                        ARRAY ['J.R.R. Tolkien'], ARRAY ['Adventure', 'Science-Fiction'], NULL);
-- 02.4.3 EXCEPTION: Löschen eines Buchtitels als User
CALL deleteBook('9780261102354', 3);
-- 02.4.4 Löschen eines Buchtitels als Admin
CALL deleteBook('9780261102354', 1);
-- 02.4.5 EXCEPTION: Löschen eines Buchtitels, der nicht vorhanden ist
CALL deleteBook('9780261102354', 1);
