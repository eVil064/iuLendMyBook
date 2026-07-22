/* In diesem Schritt werden die temporär angelegten Tabellen zum Einlesen und verarbeiten der Testdaten wieder entfernt*/
------------------------------------------------------------------------------------------------------------------------
-- Entfernen der temporären User-Daten
DROP TABLE IF EXISTS user_raw_data;

-- Entfernen der temporären Bibliografie
DROP TABLE IF EXISTS book_raw_data;

-- Entfernen der temporären Verlagsdaten
DROP TABLE IF EXISTS publisher_raw_data;

-- Entfernen der temporären Autorendaten
DROP TABLE IF EXISTS author_raw_data;
