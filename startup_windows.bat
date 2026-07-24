@echo off

set DB_NAME=iulendmybook
set DB_USER=postgres
set BASE_PATH=.\init

echo Starte Postgres-Server
net start postgresql-x64-18

echo Erstelle Datenbank"
psql -U %DB_USER% -c "DROP DATABASE IF EXISTS %DB_NAME%;"
psql -U %DB_USER% -c "CREATE DATABASE %DB_NAME%;"

echo Erstelle Datenbankstruktur
psql -U %DB_USER% -d iuLendMyBook -f "%BASE_PATH%\00_init.sql"

echo Füge Testdaten ein...
echo 1/6: Nachschlagetabellen
psql -U %DB_USER% -d iuLendMyBook -f "%BASE_PATH%\01.1_insert_plain_test_data.sql"

echo 2/6: Temporäre Tabellen
psql -U %DB_USER% -d iuLendMyBook -f "%BASE_PATH%\01.2_read_complex_test_data.sql"

echo 3/6: Benutzerdaten
psql -U %DB_USER% -d iuLendMyBook -f "%BASE_PATH%\02.1_insert_adresses.sql"
psql -U %DB_USER% -d iuLendMyBook -f "%BASE_PATH%\02.2_insert_users.sql"
psql -U %DB_USER% -d iuLendMyBook -f "%BASE_PATH%\02.3_insert_user_relations.sql"

echo 4/6 Buchdaten
psql -U %DB_USER% -d iuLendMyBook -f "%BASE_PATH%\03.1_insert_publisher.sql"
psql -U %DB_USER% -d iuLendMyBook -f "%BASE_PATH%\03.2_insert_authors.sql"
psql -U %DB_USER% -d iuLendMyBook -f "%BASE_PATH%\03.3_insert_books.sql"
psql -U %DB_USER% -d iuLendMyBook -f "%BASE_PATH%\03.4_insert_book_copies.sql"

echo 5/6 Ausleihdaten
psql -U %DB_USER% -d iuLendMyBook -f "%BASE_PATH%\04.1_insert_pickup_options.sql"
psql -U %DB_USER% -d iuLendMyBook -f "%BASE_PATH%\04.2_insert_book_loans.sql"
psql -U %DB_USER% -d iuLendMyBook -f "%BASE_PATH%\04.3_insert_loan_ratings.sql"

echo 6/6: Entfernen der temporären Tabellen
psql -U %DB_USER% -d iuLendMyBook -f "%BASE_PATH%\05_cleanup.sql"

echo Initialisierung abgeschlossen
pause
