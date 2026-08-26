-- 04.1 Buch-Exemplare
---------------------------
-- 04.1.1 Anlage eines neuen Buchexemplars zu einem bestehenden Buch
-- Erstellen eines Buches
CALL createOrUpdateBook('Lord of the Rings - Fellowship of the Ring', '9780261102354',
                        'The first part of The Lord of the Rings. Frodo Baggins inherits the powerful One Ring ' ||
                        'and must leave the Shire to prevent it from falling into the hands of the Dark Lord Sauron. ' ||
                        'Together with a fellowship of companions, he begins a dangerous journey across Middle-earth.',
                        1977::smallint, 1::smallint, 'en-US',
                        'HarperCollins Publishers Ltd', ARRAY ['J.R.R Tolkien'],
                        ARRAY ['Science-Fiction'], NULL);
-- Erstellen eines Buchexemplars
CALL createBookCopy('9780261102354', getuserbyemail('clara.neumann@example.org'),
                    10::smallint, 'Guter Zustand', NULL);
-- 04.1.2 Aktualisierung eines Buchexemplars durch einen berechtigten User
CALL updateBookCopy((getBookCopiesByUser('9780261102354', getuserbyemail('clara.neumann@example.org')))[1],
                    getuserbyemail('clara.neumann@example.org'), 60::smallint,
                    'Zustand OK -> eingerissene Seite 102');
-- 04.1.3 EXCEPTION: Aktualisierung eines Buchexemplars durch einen nicht berechtigten User
CALL updateBookCopy((getBookCopiesByUser('9780261102354', getuserbyemail('clara.neumann@example.org')))[1],
                    getuserbyemail('jonas.reuter@example.org'), 60::smallint,
                    'Zustand OK -> eingerissene Seite 102');
-- 04.1.4 EXCEPTION: Löschversuch eines Exemplars durch einen unberechtigten User
CALL deleteBookCopy((getBookCopiesByUser('9780261102354', getuserbyemail('clara.neumann@example.org')))[1],
                    getuserbyemail('jonas.reuter@example.org'));
-- 04.1.5 Löschversuch eines Exemplars durch einen berechtigten User
CALL deleteBookCopy((getBookCopiesByUser('9780261102354', getuserbyemail('clara.neumann@example.org')))[1],
                    getuserbyemail('clara.neumann@example.org'));
-- 04.1.6 Löschen eines Users, löscht auch die Exemplare des Users
-- Erstellen eines Buchexemplars
CALL createBookCopy('9780261102354', getuserbyemail('max.mueller@web.de'),
                    20::smallint, 'Neu', NULL);
-- Prüfen, ob noch Exemplare vorhanden
SELECT EXISTS (SELECT deleteUserAndCheckCopies('max.mueller@web.de'));