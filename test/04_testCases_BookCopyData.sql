-- 04.1 Buch-Exemplare
---------------------------
-- 04.1.1 Anlage eines neuen Buchexemplars zu einem bestehenden Buch
CALL createBookCopy('9781000002003', getuserbyemail('clara.neumann@example.org'),
                    10::smallint, 'Guter Zustand', NULL);
-- 04.1.2 Aktualisierung eines Buchexemplars durch einen berechtigten User
CALL updateBookCopy(
        (getBookCopiesByUser('9781000002003', getuserbyemail('clara.neumann@example.org')))[1],
                    getuserbyemail('clara.neumann@example.org'), 60::smallint,
                    'Zustand OK -> eingerissene Seite 102');
-- 04.1.3 EXCEPTION: Aktualisierung eines Buchexemplars durch einen nicht berechtigten User
CALL updateBookCopy(
        (getBookCopiesByUser('9781000002003', getuserbyemail('clara.neumann@example.org')))[1],
                    getuserbyemail('jonas.reuter@example.org'), 60::smallint,
                    'Zustand OK -> eingerissene Seite 102');
-- 04.1.4 EXCEPTION: Löschversuch eines Exemplars durch einen unberechtigten User
CALL deleteBookCopy(
        (getBookCopiesByUser('9781000002003', getuserbyemail('clara.neumann@example.org')))[1],
                    getuserbyemail('jonas.reuter@example.org'));
-- 04.1.5 Löschversuch eines Exemplars durch einen berechtigten User
CALL deleteBookCopy(
        (getBookCopiesByUser('9781000002003', getuserbyemail('clara.neumann@example.org')))[1],
                    getuserbyemail('clara.neumann@example.org'));
-- 04.1.6 Löschversuch eines Exemplars mit vorhandenen Ausleihvorgängen
CALL deleteBookCopy(
        (getBookCopiesByUser('9783000001048', getuserbyemail('eva.brandt@example.org')))[1],
        getuserbyemail('eva.brandt@example.org'));
