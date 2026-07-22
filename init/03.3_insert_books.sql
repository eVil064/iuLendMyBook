/* Es erfolgt die Verarbeitung der eingelesenen Bibliografie-Daten
   - Anlage der Genres aus 03_books.csv
   - Anlage der Adressen aus 05_user_data und Verknüpfung mit Orten
*/
------------------------------------------------------------------------------------------------------------------------

-- Genres erstellen
-- Die Genres werden aus der temporären Datenbanktalle der Bücher ermittelt und in genre angelegt. Durch die Verwendung
-- des DISTINCT-Schlüsselwortes wird sichergestellt, dass jedes genre nur einmalig angelegt wird.
INSERT INTO genre (name)
SELECT DISTINCT genre
FROM book_raw_data
ON CONFLICT DO NOTHING;


-- Einfügen der Buchdaten mit Verweis auf Sprache
-- Der Verlag wird über die Anbagabe ISBN der temporären Verlagstabelle und der Verwendung von Bezeichnung und Webseite
-- als Schlüssel auf die Verlagstabelle ermittelt.
-- Zwar ist der Schlüssel nicht zwingend eindeutig, da die Webseite keien Pflichtangabe ist und gleiche Verlagsnamen
-- vorkommen können. Dies wird für das Einlesen der Testdaten aber außer Acht gelassen.
INSERT INTO book (title,
                  isbn,
                  description,
                  publication_year,
                  edition,
                  language_id,
                  publisher_id)
SELECT b.title,
       b.isbn,
       b.description,
       extract(YEAR FROM b.publishing_date),
       b.edition,
       l.language_id,
       p.publisher_id
FROM book_raw_data b
         LEFT JOIN language l on b.language = l.iso_code
         LEFT JOIN publisher_raw_data p_raw on b.isbn = p_raw.isbn
         LEFT JOIN publisher p on p_raw.name = p.name and p_raw.website = p.website
ON CONFLICT DO NOTHING;

-- Einfügen der Autoren der Bücher
-- Die Verknüfung von Buch und Autor wird über den Schlüssel ISBN der temporären Autorentabelle hergestellt. Die
-- Zuweisung zur Autorentabelle erfolgt letztlich über die den Schlüssel aus Titel, Vorname und Nachname des Autors
-- Zwar ist der Schlüssel nicht zwingend eindeutig, da die Kombination der drei Attribute nicht eineindeutig ist
-- Dies wird für das Einlesen der Testdaten aber außer Acht gelassen.
INSERT INTO book_author (book_id,
                         author_id)
SELECT book_id, a.author_id
FROM book b
         LEFT JOIN author_raw_data a_raw on b.isbn = a_raw.isbn
         LEFT JOIN author a on a_raw.first_name = a.first_name and a_raw.last_name = a.last_name and
                               a_raw.academic_title = a.academic_title
ON CONFLICT DO NOTHING;

-- Einfügen der Genres der Bücher
-- Da sich das Genre nur über die Bezeichnung ermitteln lässt, wird es aus der Genre-Tabelle anhand des Felds 'name'
-- ermittelt. Die entsprechende Buch-ID kann über die ISBN eindeutig bestimmt werden.
-- Ein Buch könnte mehreren Genres zugewiesen sein, jedoch wird die Zuordnung in den Testdaten auf ein Genre reduziert
-- um die Komplexität einzuschränken.
INSERT INTO book_genre (book_id,
                        genre_id)
SELECT b.book_id, g.genre_id
FROM book_raw_data raw
         INNER JOIN book b on raw.isbn = b.isbn
         INNER JOIN genre g on raw.genre = g.name
ON CONFLICT DO NOTHING;



