-- 01.1 Genres
---------------------------
-- 01.1.1 Anlage eines neuen Genres
CALL getOrCreateGenre('Komödie', NULL);
-- 01.1.2 UNIQUE CONSTRAINT VIOLATION: Bestehendes Genre erneut anlegen
CALL getOrCreateGenre('Thriller', NULL);
-- 01.1.3 NOLL-NULL CONSTRAINT VIOLATION: Genre ohne Bezeichnung anlegen
CALL getOrCreateGenre(NULL, NULL);

-- 01.2 Sprachen
---------------------------
-- 01.2.1 Anlage einer neuen Sprache
CALL getOrCreateLanguage('Deutsch (Österreich)', 'de-AT', NULL);
-- 01.2.2 CHECK CONSTRAINT VIOLATION: Anlage einer Sprache mit ungültigem ISO-Code-Format
CALL getOrCreateLanguage('Slowakisch', 'sk_SK', NULL);

-- 01.3 Länder
---------------------------
-- 01.3.1 Anlage eines weiteren Landes
CALL getOrCreateCountry('Chile', 'CL', NULL);
-- 01.3.2 VALUE TOO LONG EXCEPTION: Anlage eines Eintrags mit zu langem ISO-Code
CALL getOrCreateCountry('Suisse', 'SUI', NULL);
-- 01.3.3 CHECK CONSTRAINT VIOLATION: Anlage eines Eintrags mit ungültigem ISO-Code-Format
CALL getOrCreateCountry('Morocco', 'M9', NULL);

-- 01.4 Orte
---------------------------
-- 01.4.1 Anlage eines neuen Ortes
CALL getOrCreateLocation('34225', 'Baunatal', 'Germany', NULL);
-- 01.4.2 Anlage eines neuen Ortes, Land nicht vorhanden
CALL getOrCreateLocation('11458', 'Cardiff', 'Wales', NULL);
