@echo off

set DB_NAME=iulendmybook
set DB_USER=postgres

REM Setzen des Skript-Pfades als BASE_PATH
set SCRIPT_DIR=%~dp0
set BASE_PATH=%SCRIPT_DIR%\init

cd %SCRIPT_DIR%

echo Starte Postgres-Server
net start postgresql-x64-18

echo Erstelle Datenbank
psql -U %DB_USER% -c "DROP DATABASE IF EXISTS %DB_NAME%;"
psql -U %DB_USER% -c "CREATE DATABASE %DB_NAME%;"

echo Erstelle Datenbankstruktur
psql -U %DB_USER% -d %DB_NAME% -f "%BASE_PATH%\00_create_database.sql"

echo Erzeuge Testdaten aus Pfad %~dp0resources
psql -U %DB_USER% -d %DB_NAME% -f "%BASE_PATH%\01_create_testdata.sql"

echo Erstelle Prozeduren und Funktionen
psql -U %DB_USER% -d %DB_NAME% -f "%BASE_PATH%\02_create_procedures_and_functions.sql"

echo Entferne temporären Tabellen
psql -U %DB_USER% -d %DB_NAME% -f "%BASE_PATH%\03_cleanup.sql"

echo Initialisierung abgeschlossen
pause
