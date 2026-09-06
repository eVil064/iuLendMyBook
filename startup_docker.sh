#!/usr/bin/env bash
set -e

DB_NAME="iulendmybook"
DB_USER="postgres"
BASE_PATH="${BASE_PATH:-/home/usr/iu/data}"

cd "${BASE_PATH}"

echo "-------------Erstelle Datenbankstruktur, nutze BASE_PATH=${BASE_PATH}-----------------------"
psql -U ${DB_USER} -d ${DB_NAME} -f "${BASE_PATH}/init/00_setup_database.sql"

echo "-------------Erzeuge Testdaten aus Pfad ${PWD}/resources----------------"
psql -U ${DB_USER} -d ${DB_NAME} -f "${BASE_PATH}/init/01_create_testdata.sql"

echo "-------------Erstelle Prozeduren und Funktionen---------------------"
psql -U ${DB_USER} -d ${DB_NAME} -f "${BASE_PATH}/init/02_create_procedures_and_functions.sql"

echo "-------------Lösche temporäre Tabellen----------------------"
psql -U ${DB_USER} -d ${DB_NAME} -f "${BASE_PATH}/init/03_cleanup.sql"

echo "--------------------------------------"
echo "Initialisierung abgeschlossen"
