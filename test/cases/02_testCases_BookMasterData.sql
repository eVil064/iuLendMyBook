-- 02.1 Verlage
---------------------------
-- 02.1.1 Anlage eines Verlags mit vorhandener Adresse
CALL getOrCreatePublisher('HarperCollins Publishers Ltd', 'https://harpercollins.co.uk', 'Robroyston Gate',
                          '1', 'Glasgow', 'G33 1JN', 'United Kingdom', NULL);
-- 02.1.2 Anlage eines Verlags ohne Adresse
CALL getOrCreatePublisher('Das Verlagshaus', 'http://dasverlagshaus.de', NULL,
                          NULL, NULL, NULL, NULL, NULL);
-- 02.1.3 Verlag ohne Adresse auffinden
CALL getOrCreatePublisher('Das Verlagshaus', 'http://dasverlagshaus.de', NULL,
                          NULL, NULL, NULL, NULL, NULL);

CALL getOrCreatePublisher('Der Verlag', 'http://dasverlagshaus.info', 'Waldstrasse',
                          '27', 'Leipzig', '04109', 'Deutschland', NULL);
-- 02.1.4 Prüfung referentielle Integrietät: Löschen des Verlags löscht nicht die Adresse
SELECT deletepublisherandcheckaddress('Das Verlagshaus');

-- 02.2 Autoren
---------------------------
-- 02.2.1 Anlage eines Autors
CALL getOrCreateAuthor('J.R.R', 'Tolkien', NULL, NULL);

-- 02.3 Bücher
-- 02.3.1 Anlegen eines neuen Buches
CALL createOrUpdateBook('Lord of the Rings - Fellowship of the Ring', '9780261102354',
                        'The first part of The Lord of the Rings. Frodo Baggins inherits the powerful One Ring ' ||
                        'and must leave the Shire to prevent it from falling into the hands of the Dark Lord Sauron. ' ||
                        'Together with a fellowship of companions, he begins a dangerous journey across Middle-earth.',
                        1977::smallint, 1::smallint, 'en-US', 'HarperCollins Publishers Ltd',
                        ARRAY ['J.R.R Tolkien'], ARRAY ['Science-Fiction'], NULL);
-- 02.3.2 Aktualisierung eines Buches
CALL createOrUpdateBook('Lord of the Rings - Fellowship of the Ring', '9780261102354',
                        'The first part of The Lord of the Rings. Frodo Baggins inherits the powerful One Ring ' ||
                        'and must leave the Shire to prevent it from falling into the hands of the Dark Lord Sauron. ' ||
                        'Together with a fellowship of companions, he begins a dangerous journey across Middle-earth.',
                        2007::smallint, 68::smallint, 'en-US', 'HarperCollins Publishers Ltd',
                        ARRAY ['J.R.R Tolkien'], ARRAY ['Adventure', 'Science-Fiction'], NULL);
-- 02.3.3 Löschen eines Buchtitels als Admin
CALL deleteBook('9780261102354', 1);
-- 02.3.4 Löschen eines Buchtitels, der nicht vorhanden ist
CALL deleteBook('9780261102354', 1);
-- 02.3.5 Löschen eines Buchtitels als User
CALL deleteBook('9783000001000', 3);
