/* Für den Aufbau einer Testbasis werden zunächst die Nachschlagetabellen angelegt. Die Werte werden dabei aus den
   beigefügten Demodaten im Pfad ../resources/.. per COPY-Befehl eingelesen.

   - Für Zeitslots werden feste Werte mit Stundenrhythmus vorgeben.
   - Länder und Sprachen sind als Auswahl dargestellt und könnten ergänzt werden
   - Adresstypen beschränken sich zunächst auf Abholung- und Versandadressen
 */
------------------------------------------------------------------------------------------------------------------------
-- Länder einfügen
-- Quelle: Schweizer Bundesamt für Statistik. (2026). ISO Ländercodes.
-- https://dam-api.bfs.admin.ch/hub/api/dam/assets/10687502/master, Abruf am 22.07.2026 14:26 Uhr
COPY country (name, iso_code)
    FROM '/var/lib/iu/data/test_data/02_countries.csv'
    WITH (FORMAT CSV, HEADER true, DELIMITER ',');

-- Sprachen einfügen
-- Quelle: Auswärtiges Amt. (2026).  Verzeichnis von Sprachkennungen und Sprachennamen auf Deutsch.
-- https://www.auswaertiges-amt.de/resource/blob/2732426/0c706d352b2aeff5862a1bdf3968044a/sprachkennungen-data.pdf, Abruf am 21.07.2026 11:06 Uhr
COPY language (name, iso_code)
    FROM '/var/lib/iu/data/test_data/04_languages.csv'
    WITH (FORMAT CSV, HEADER true, DELIMITER ',');

-- Zeitslots einfügen
-- Quelle: OpenAI. (2026). ChatGPT (Version GPT-5.6 Sol) .
-- https://chat.openai.com
-- Prompt:
COPY timeslot (begin_time, end_time, day_of_week)
    FROM '/var/lib/iu/data/test_data/06_timeslots.csv'
    WITH (FORMAT CSV, HEADER true, DELIMITER ',');

-- Adresstypen hinzufügen
-- Es werden die für die Testdaten die Adresstypen Versand- und Abholadresse angelegt.
INSERT INTO address_type(name)
VALUES ('SHIPPING'),
       ('PICK_UP');

-- Status hinzufügen
-- Es werden die für die Testdaten die Status aktiv, inaktiv und blockiert hinzugefügt.
INSERT INTO status(name)
VALUES ('ACTIVE'),
       ('INACTIVE'),
       ('BLOCKED');

-- Bereitstellungsarten hinzufügen
-- Es werden die für die Testdaten die Bereitstellungsarten Versand und Abholung angelegt.
-- Diese sind zur Vereinfachung analog der Adresstypen ausgestaltet.
INSERT INTO fulfillment_type(name)
VALUES ('SHIPPING'),
       ('PICK_UP')
ON CONFLICT DO NOTHING;

-- Rollen hinzufügen
-- Es werden drei Standard-Rollen gemäß der Restriktionen angelegt.
INSERT INTO role(name)
VALUES ('USER'),
       ('ADMIN'),
       ('MODERATOR'),
       ('MISC')
ON CONFLICT DO NOTHING;