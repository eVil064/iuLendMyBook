# IU LendMyBook - Bücherausleihe

Bla Bla Context

# Installation

## Installation Windows

1. Download und Installation von Postgres-Installer (https://www.postgresql.org/download/windows/, Version 18)
2. Anlage eines Verzeichnisses für das die Daten des Repositories , z.B. `C:\Users\IU\Datamart\`
3. Wechsel in das angelegte Verzeichnis und Ausführung von `startup_windows.bat`
4. Die Prozeduren für die Testfälle können über die Kommandozeile oder per PowerShell ausgeführt werden, z.B.
   `psql -U postgres createBook('Herr der Ringe - Die Gefährten',  '9783608989410','In einem ruhigen Dorf im Auenland bekommt der junge Frodo ein Geschenk ... ', 'de-DE', , [Tollkien; JRR])`

## Installation Linux

## Installation Docker

1. Installation von Docker (siehe https://docs.docker.com/desktop/)
2. Erstellen des Postgres-Containers und Ausführen der Initialisierungs-Skripte
   `docker run --name iuLendMyBook -d -e POSTGERS_USER=admin -e POSTGRES_PASSWORD=* -e POSTGRES_DB=iuLendMyBook -v $PWD/init/:/docker-entrypoint-initdb.d/ -v $PWD/resources/:/var/lib/iu/data/test_data/ -p 5440:5432 postgres:latest`
    1. Erstellt einen Container mit der Bezeichnung `iuLendMyBook` auf Basis eines POSTGRES-Images in Version `LATEST`
    2. Für `POSTGRES_PASSWORD` ist ein beliebiges Passwort zu vergeben, z.B. die Kursnummer, der Admin-User wird mit dem
       Standard Postgres-User angelegt
    3. Mit Parameter `-p` wird der Port angegeben, über den der Server nach außen exponiert wird, ein Zugriff ist hier
       beispielsweise per `localhost:5440` möglich

# Testing

## Prozeduren installieren

## Testfälle ausführen
### Benutzerverwaltung

| # | Bezeichnung          | Beschreibung | Erwartetes Ergebnis | Prozeduraufruf | 
|---|----------------------|--------------|---------------------|----------------|
| 1 | Anlegen eines Buches | asd          | asd                 | `createBook    |
|   | Ändern eines Buches  | asd          | asd                 | asd            |
|   | Löschen eines Buches | asd          | asd                 | ad             |

### Stammdatenverwaltung

| # | Bezeichnung          | Beschreibung | Erwartetes Ergebnis | Prozeduraufruf | 
|---|----------------------|--------------|---------------------|----------------|
| 1 | Anlegen eines Buches | asd          | asd                 | asd            |
|   | Ändern eines Buches  | asd          | asd                 | asd            |
|   | Löschen eines Buches | asd          | asd                 | ad             |

### Bücher (Bibliografie und Stammdaten)

| # | Bezeichnung          | Beschreibung | Erwartetes Ergebnis | Prozeduraufruf | 
|---|----------------------|--------------|---------------------|----------------|
| 1 | Anlegen eines Buches | asd          | asd                 | asd            |
|   | Ändern eines Buches  | asd          | asd                 | asd            |
|   | Löschen eines Buches | asd          | asd                 | ad             |

### Ausleihvorgänge

| # | Bezeichnung          | Beschreibung | Erwartetes Ergebnis | Prozeduraufruf | 
|---|----------------------|--------------|---------------------|----------------|
| 1 | Anlegen eines Buches | asd          | asd                 | asd            |
|   | Ändern eines Buches  | asd          | asd                 | asd            |
|   | Löschen eines Buches | asd          | asd                 | ad             |
