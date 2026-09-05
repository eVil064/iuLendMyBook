#!/usr/bin/env bash
set -e

DB_NAME="iulendmybook"
DB_USER="iuUser"
BASE_PATH="./init"

echo "Erstelle Datenbank"
psql -U ${DB_USER} -c "DROP DATABASE IF EXISTS ${DB_NAME};"
psql -U ${DB_USER} -c "CREATE DATABASE ${DB_NAME};"

echo "Erstelle Datenbankstruktur"
psql -U ${DB_USER} -d ${DB_NAME} -f "${BASE_PATH}/00_setup_database.sql"

echo "Füge Testdaten ein..."
psql -U ${DB_USER} -d ${DB_NAME} -f "${BASE_PATH}/01_create_testdata.sql"

echo "Erstellen von Prozeduren und Funktionen"
psql -U ${DB_USER} -d ${DB_NAME} -f "${BASE_PATH}/02_create_procedures_and_functions.sql"

echo "Lösche temporäre Tabellen"
psql -U ${DB_USER} -d ${DB_NAME} -f "${BASE_PATH}/03_cleanup.sql"

echo "Initialisierung abgeschlossen"
