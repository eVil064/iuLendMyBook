# IU LendMyBook - Bücherausleihe

Bla Bla Context

# Installation

## Installation Windows

## Installation Linux

## Installation Docker

Voraussetzung für die Installation der Datenbank unter Docker ist das Vorhandensein einer Docker-Instanz. Die Plattform
ist dabei nicht ausschlaggebend.

1. Einrichten des Austauschverzeichnisses für die SQL-Skripte, z.B. `./postgres/init-scripts`
2. Einrichten eines Verzeichnisses zur Speicherung der Postgresdaten (Optional), `./postgres/data`
3. Erstellen des Postgres-Containers und Ausführen der Initialisierungs-Skripte
   `docker run --name iuLendMyBook -d -e POSTGERS_USER=admin -e POSTGRES_PASSWORD=* -v $PWD/init/:/docker-entrypoint-initdb.d/ -v $PWD/resources/:/var/lib/iu/data/test_data/ -p 5440:5432 postgres:latest`
   1. Erstellt einen Container mit der Bezeichnung `iuLendMyBook` auf Basis eines POSTGRES-Images in Version `LATEST`
   3. Für `POSTGRES_PASSWORD` ist ein beliebiges Passwort zu vergeben, z.B. die Kursnummer, der Admin-User wird mit dem
      Standard Postgres-User angelegt
   5. Mit Parameter `-p` wird der Port angegeben, über den der Server nach außen exponiert wird, ein Zugriff ist hier
      beispielsweise per `localhost:5440` möglich

# Betrieb und Testing

## Testfälle definieren

### Benutzer

- Anlegen eines UserAccounts

### Bücher und Exemplare

- Anlegen eines Buches
- Ändern eines Buches
- Löschen eines Buches

### Ausleihvorgänge

## Tests ausführen (Prozeduraufrufe)

Für jede Funktion der Datenbank ist eine Prozedur vorhanden. Die Testfälle können durch Ausführung der Prozeduren
abgeprüft werden
