#!/usr/bin/env bash
set -e
DB_NAME="iulendmybook"
DB_USER="postgres"

# Setzen des Pfades der Skriptdatei als aktuellen BASE_PATH und Wechsel ins Verzeichnis 
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_PATH="$SCRIPT_DIR/init"
cd ${SCRIPT_DIR}

echo "-------------Erstelle Datenbank------------------"
psql -U ${DB_USER} -c "DROP DATABASE IF EXISTS ${DB_NAME};"
psql -U ${DB_USER} -c "CREATE DATABASE ${DB_NAME};"

echo "-------------Erstelle Datenbankstruktur, nutze BASE_PATH=${BASE_PATH}-----------------------"
psql -U ${DB_USER} -d ${DB_NAME} -f "${BASE_PATH}/00_setup_database.sql"

echo "-------------Erzeuge Testdaten aus Pfad "${PWD}/resources"----------------"
psql -U ${DB_USER} -d ${DB_NAME} -f "${BASE_PATH}/01_create_testdata.sql"

echo "-------------Erstelle Prozeduren und Funktionen---------------------"
psql -U ${DB_USER} -d ${DB_NAME} -f "${BASE_PATH}/02_create_procedures_and_functions.sql"

echo "-------------Lösche temporäre Tabellen----------------------"
psql -U ${DB_USER} -d ${DB_NAME} -f "${BASE_PATH}/03_cleanup.sql"

echo "--------------------------------------"
echo "Initialisierung abgeschlossen"
