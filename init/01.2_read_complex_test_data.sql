/* In diesem Schritt werden komplexere Testdaten in die Datenbank übernommen.
   Die komplexen Daten werden aus den CSV-Dateien zunächst in temporäre Datenbanktabellen eingelesen, um diese im Verlauf
   für UPDATE und INSERT-Methoden verwenden zu können. Dazu werden zunächst die Tabellen erstellt, sollten sie noch nicht
   existieren und anschließend über den COPY-Befehl aus den CSV-Dateien befüllt.
 */
------------------------------------------------------------------------------------------------------------------------

-- Bibliografie
CREATE TABLE IF NOT EXISTS book_raw_data
(
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    isbn            varchar(13)  NOT NULL,
    title           varchar(255) NOT NULL,
    description     text,
    publishing_date date,
    edition         smallint,
    language        char(2),
    genre           varchar(50)
);

-- Verlagsdaten
CREATE TABLE IF NOT EXISTS publisher_raw_data
(
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    isbn         varchar(13),
    name         varchar(50),
    website      varchar(50),
    street       varchar(255) NOT NULL,
    number       varchar(10),
    postal_code  varchar(10)  NOT NULL,
    city         varchar(50)  NOT NULL,
    country_code char(2)
);

-- Personendaten und Adressen
CREATE TABLE IF NOT EXISTS user_raw_data
(
    id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    academic_title varchar(10),
    first_name     varchar(50),
    last_name      varchar(50)  NOT NULL,
    email          varchar(255) NOT NULL,
    phone          varchar(20),
    street         varchar(255) NOT NULL,
    number         varchar(10),
    longitude      numeric(9, 6),
    latitude       numeric(9, 6),
    postal_code    varchar(10)  NOT NULL,
    city           varchar(50)  NOT NULL,
    country_code   char(2),
    role_name      varchar(255)
);

-- Autoreninformationen
CREATE TABLE IF NOT EXISTS author_raw_data
(
    id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    isbn           varchar(13) NOT NULL,
    academic_title varchar(20),
    first_name     varchar(50) NOT NULL,
    last_name      varchar(50) NOT NULL
);

-- Einlesen der fiktven Buchdaten
-- Quelle: OpenAI. (2026). ChatGPT (Version GPT-5.6 Sol) .
-- https://chat.openai.com
COPY book_raw_data (isbn, title, description, publishing_date, edition, language, genre) FROM '/var/lib/iu/data/test_data/03_books.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER true, QUOTE '"');
COPY publisher_raw_data (isbn, name, website, street, number, postal_code, city, country_code) FROM '/var/lib/iu/data/test_data/07_publisher.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER true, QUOTE '"');
COPY author_raw_data (isbn, academic_title, first_name, last_name) FROM '/var/lib/iu/data/test_data/01_authors.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER true, QUOTE '"');

-- Einlesen der fiktven User-Daten
-- Quelle: OpenAI. (2026). ChatGPT (Version GPT-5.6 Sol) .
-- https://chat.openai.com
COPY user_raw_data (academic_title, first_name, last_name, email, phone, street, number, longitude, latitude,
                    postal_code, city,
                    country_code,
                    role_name) FROM '/var/lib/iu/data/test_data/05_user_data.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER true, QUOTE '"');