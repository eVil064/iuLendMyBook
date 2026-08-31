# IU LendMyBook - Bücherausleihe

Dieses Projekt beinhaltet das Konzept und die Implementierung einer Buchtausch-App auf Basis einer
PostgreSQL-Datenbank. Die Kernfunktionen der App sind dabei die Verwaltung der Stammdaten von Büchern,
Buchexemplaren und Benutzern, sowie die Erstellung und Speicherung von Ausleihvorgängen inklusive deren
Bewertungen durch die entleihenden Personen.
Die zentralen Funktionen der App werden über Prozeduren abgebildet, die das Anlegen, Bearbeiten und
Löschen der Entitäten vollziehen. Duch Prüfungen z.B. auf notwendige Rollen oder Abhängigkeiten für die
Ausführung der Prozeduren werden so realitätsnah wesentliche Prozesse im Rahmen der Bereitstellung und
Ausleihe von Buchexemplaren simuliert.
Fiktive, aber plausible Testdatensätze schaffen eine Grundlage, die es ermöglicht die
Datenbankstruktur, Funktionen und Prozeduren zu testen.

Diese `README` enthält eine Installationsanleitung für die Plattformen Docker, Windows und Linux, sowie
eine Kurzbeschreibung der verfügbaren Testfälle.

# Installation

## Docker

1. Installation von Docker (siehe https://docs.docker.com/desktop/)
2. Erstellen des Postgres-Containers und Ausführen der Initialisierungs-Skripte
     ```bash 
    docker run --restart=unless-stopped --name iuLendMyBook -d -e POSTGRES_USER=iuUser \ 
        -e POSTGRES_PASSWORD=* 
        -e POSTGRES_DB=iuLendMyBook \
        -v $PWD/init/:/docker-entrypoint-initdb.d/ 
        -v $PWD/resources/:/var/lib/iu/data/test_data/ \
        -p 5440:5432 postgres:latest
    ```
1. Erstellt einen Container mit der Bezeichnung `iuLendMyBook` auf Basis eines
   POSTGRES-Images in Version `LATEST`
2. Für `POSTGRES_PASSWORD` ist ein beliebiges Passwort zu vergeben, z.B. die Kursnummer, der
   Admin-User wird mit dem
   Standard Postgres-User angelegt
3. Mit Parameter `-p` wird der Port angegeben, über den der Server nach außen exponiert wird, ein
   Zugriff ist hier
   beispielsweise per `localhost:5440` möglich
4. Um sicherzustellen, dass der Container nach Beenden von Docker beim nächsten Start erneut
   startet, wird die Policy
   `restart=unless-stopped`angewendet. Sofern der Container nicht gestopped wurde, wird er bei
   Neustart von Docker
   direkt neu gestartet.
5. Das Ausführen der Testfälle kann entweder über einen Postgres-Client wie `pgAdmin` oder über die
   Kommandozeile des
   Docker-Containers ausgeführt werden:
    - Über die Kommandozeile in die Shell des Containers wechseln:
      `docker exec -it iuLendMyBook bash`
        - Die Optionen `-i` und `-t` geben an, dass die Shell interaktiv geöffnet wird. Andernfalls
          wird die Shell nicht
          zur Bearbeitung geöffnet
        - Über die Angabe, die dem Containernamen folgt (hier `bash`) kann die Art der Shell
          angegeben werden, die
          geöffnet wird.
    - Ausführen der Prozedur per `psql`-Command, z.B.
   ```bash
   psql -U iuUser -d iuLendMyBook -c "CALL createLanguage('Danish','da-DK');"
   ```

## Linux

1. Installation von Postgres-Server und Postgres-Client (Version 15 oder höher)
    ``` bash
    sudo apt update
    sudo apt install postgresql postgresql-client
    ```
2. Postgres-Dienste aktivieren
    ``` bash
    sudo systemctl enable postgresql
    sudo systemctl start postgresql
    ``` 
3. Anlage eines Verzeichnisses für das die Daten des Repositories , z.B. `/opt/`
   und klonen des Repositories
5. Wechsel in das angelegte Verzeichnis und Ausführung von `startup_linux.sh` zur
   Initialisierung der Datenbank
     ```bash
    sudo -u postgres ./startup_linux.sh
    ```

## Windows

1. Download und Installation von Postgres-Installer (https://www.postgresql.
   org/download/windows/, Version 15 oder höher)
2. Anlage eines Verzeichnisses für das die Daten des Repositories , z.B. `C:\Users\IU\Datamart\`
   und klonen des Repositories
3. Wechsel in das angelegte Verzeichnis und Ausführung von `startup_windows.bat` zur
   Initialisierung der Datenbank
4. Das Ausführen der Testfälle kann entweder über einen Postgres-Client wie `pgAdmin`, über die Kommandozeile oder per
   PowerShell ausgeführt werden, z.B.
    ```shell
    psql -U postgres -d iuLendMyBook -c "CALL createOrUpdateBook('Herr der Ringe - Die 
   Gefährten', '9783608989410','In einem ruhigen Dorf im Auenland bekommt der junge Frodo ein 
   Geschenk ... ', 2006::smallint, 6::smallint, 'de-DE', 'Der Verlag' , ARRAY['J.R.R. Tolkien], 
   ARRAY['Fantasy'], NULL)"
    ```

# Testing

## Prozeduren installieren

Zur Installation der Prozeduren auf der Datenbank sind die SQL-Dateien im Ordner `init/procedures/`
auszuführen.
Da sie im Installationsverzeichnis liegen, werden sie im Rahmen der Dockerinstallation beim
Start nach den Initialisierungsskripten eingelesen. Für Windows und Linux sind sie separat
auszuführen.

## Testfälle ausführen

Die Testfälle sind im Ordner `test/` hinterlegt und werden nachfolgend zusammengefasst.

### 01 – LookUp-Tabellen (`01_testCases_LookUpTables.sql`)

#### 01.1 Genres

| #      | Bezeichnung                      | Beschreibung                     | Erwartetes Ergebnis                                      | Prozedur           |
|--------|----------------------------------|----------------------------------|----------------------------------------------------------|--------------------|
| 01.1.1 | Anlegen eines Genres             | Neues Genre `Comedy` anlegen     | Neuer Datensatz, NOTICE mit Genre-ID                     | `getOrCreateGenre` |
| 01.1.2 | Bestehendes Genre erneut anlegen | Genre `Thriller` erneut anlegen  | Unique Violation abgefangen, bestehende ID zurückgegeben | `getOrCreateGenre` |
| 01.1.3 | Genre ohne Bezeichnung anlegen   | Genre mit `NULL` als Bezeichnung | NOT-NULL-Constraint-Verletzung                           | `getOrCreateGenre` |

#### 01.2 Sprachen

| #      | Bezeichnung                     | Beschreibung                                    | Erwartetes Ergebnis                     | Prozedur              |
|--------|---------------------------------|-------------------------------------------------|-----------------------------------------|-----------------------|
| 01.2.1 | Anlegen einer Sprache           | Sprache `German (Austria)` mit ISO-Code `de-AT` | Neuer Datensatz, NOTICE mit Language-ID | `getOrCreateLanguage` |
| 01.2.2 | Sprache mit ungültigem ISO-Code | Sprache `Slovak` mit ISO-Code `sk_SK`           | CHECK-Constraint-Verletzung             | `getOrCreateLanguage` |

#### 01.3 Länder

| #      | Bezeichnung                  | Beschreibung                                 | Erwartetes Ergebnis                    | Prozedur             |
|--------|------------------------------|----------------------------------------------|----------------------------------------|----------------------|
| 01.3.1 | Anlegen eines Landes         | Land `Chile` mit ISO-Code `CL`               | Neuer Datensatz, NOTICE mit Country-ID | `getOrCreateCountry` |
| 01.3.2 | Land mit zu langem ISO-Code  | Land `Suisse` mit ISO-Code `SUI` (3 Zeichen) | Wert zu lang (Exception)               | `getOrCreateCountry` |
| 01.3.3 | Land mit ungültigem ISO-Code | Land `Morocco` mit ISO-Code `M9`             | CHECK-Constraint-Verletzung            | `getOrCreateCountry` |

#### 01.4 Orte

| #      | Bezeichnung                               | Beschreibung                                    | Erwartetes Ergebnis                     | Prozedur              |
|--------|-------------------------------------------|-------------------------------------------------|-----------------------------------------|-----------------------|
| 01.4.1 | Anlegen eines Ortes                       | Ort `Baunatal` mit PLZ `34225` in `Germany`     | Neuer Datensatz, NOTICE mit Location-ID | `getOrCreateLocation` |
| 01.4.2 | Anlegen eines Ortes ohne vorhandenes Land | Ort `Cardiff` in `Wales` (Land nicht vorhanden) | Exception: `Country could not be found` | `getOrCreateLocation` |

### 02 – Buch-Stammdaten (`02_testCases_BookMasterData.sql`)

#### 02.1 Adressen

| #      | Bezeichnung                               | Beschreibung                                                    | Erwartetes Ergebnis                          | Prozedur             |
|--------|-------------------------------------------|-----------------------------------------------------------------|----------------------------------------------|----------------------|
| 02.1.1 | Anlegen einer Adresse mit bestehendem Ort | Adresse `Musterstraße 14a` in `Berlin` / `Germany`              | Neue Adresse angelegt, NOTICE mit Address-ID | `getOrCreateAddress` |
| 02.1.3 | Anlegen einer Adresse mit neuem Ort       | Adresse `Lombard Street 1` in `San Francisco` / `United States` | Ort und Adresse angelegt                     | `getOrCreateAddress` |
| 02.1.2 | Anlegen mit ungültigen Koordinaten        | Adresse mit ungültigem Längen-/Breitengrad                      | CHECK-Constraint-Verletzung                  | `getOrCreateAddress` |

#### 02.2 Verlage

| #      | Bezeichnung                        | Beschreibung                                                    | Erwartetes Ergebnis                      | Prozedur                         |
|--------|------------------------------------|-----------------------------------------------------------------|------------------------------------------|----------------------------------|
| 02.2.1 | Anlegen eines Verlags mit Adresse  | Verlag `HarperCollins Publishers Ltd` mit vollständiger Adresse | Verlag und Adresse angelegt              | `getOrCreatePublisher`           |
| 02.2.2 | Anlegen eines Verlags ohne Adresse | Verlag `Das Verlagshaus` ohne Adressangaben                     | Verlag ohne `address_id` angelegt        | `getOrCreatePublisher`           |
| 02.2.3 | Doppelter Verlag ohne Adresse      | Gleichen Verlag `Das Verlagshaus` per Insert erneut anlegen     | UNIQUE-Constraint-Verletzung             | `INSERT INTO publisher`          |
| 02.2.4 | Löschen eines Verlags              | Verlag `Der Verlag` löschen und Adresse prüfen                  | Verlag gelöscht, Adresse bleibt erhalten | `deletePublisherAndCheckAddress` |

#### 02.3 Autoren

| #      | Bezeichnung                      | Beschreibung                                     | Erwartetes Ergebnis                            | Prozedur                |
|--------|----------------------------------|--------------------------------------------------|------------------------------------------------|-------------------------|
| 02.3.1 | Anlegen eines Autors             | Autor `J.R.R. Tolkien` anlegen                   | Neuer Autor, NOTICE mit Author-ID              | `getOrCreateAuthor`     |
| 02.3.2 | Doppelter Autor                  | Autor `J.R.R. Tolkien` per Insert erneut anlegen | UNIQUE-Constraint-Verletzung                   | `INSERT INTO author`    |
| 02.3.3 | Abruf von Buchtiteln mit Autoren | Alle Bücher mit zugeordneten Autoren abfragen    | Ergebnisliste mit ISBN, Titel und Autorenliste | `SELECT` / `string_agg` |

#### 02.4 Bücher

| #      | Bezeichnung                            | Beschreibung                                                             | Erwartetes Ergebnis                                                | Prozedur             |
|--------|----------------------------------------|--------------------------------------------------------------------------|--------------------------------------------------------------------|----------------------|
| 02.4.1 | Anlegen eines Buches                   | Buch `Lord of the Rings - Fellowship of the Ring` (ISBN `9780261102354`) | Neuer Titel inkl. Genre- und Autorzuordnung                        | `createOrUpdateBook` |
| 02.4.2 | Aktualisieren eines Buches             | Erscheinungsjahr, Auflage und Genres des bestehenden Titels ändern       | Update erfolgreich, NOTICE                                         | `createOrUpdateBook` |
| 02.4.3 | Löschen eines Buches als User          | Buch mit ISBN `9780261102354` durch User (User-ID 3) löschen             | Exception: `Only administrators are allowed to delete book titles` | `deleteBook`         |
| 02.4.4 | Löschen eines Buches als Admin         | Buch mit ISBN `9780261102354` durch Admin (User-ID 1) löschen            | Löschung erfolgreich                                               | `deleteBook`         |
| 02.4.5 | Löschen eines nicht vorhandenen Buches | Buch mit ISBN `9780261102354` erneut löschen                             | Exception: `does not exist`                                        | `deleteBook`         |

### 03 – Benutzer-Stammdaten (`03_testCases_UserMasterData.sql`)

#### 03.1 User-Accounts

| #      | Bezeichnung                                         | Beschreibung                                                                            | Erwartetes Ergebnis                               | Prozedur                 |
|--------|-----------------------------------------------------|-----------------------------------------------------------------------------------------|---------------------------------------------------|--------------------------|
| 03.1.1 | Anlegen eines User-Accounts                         | Neuer Benutzer `Dr. Max Meier` mit E-Mail und Telefonnummer                             | Neuer Datensatz wird angelegt, NOTICE mit User-ID | `getOrCreateUserAccount` |
| 03.1.2 | Aktualisieren eines User-Accounts                   | Bestehender Benutzer `max.meier@abc.de` wird umbenannt und E-Mail geändert              | Update erfolgreich, NOTICE mit User-ID            | `updateUserAccount`      |
| 03.1.3 | Aktualisieren eines nicht vorhandenen User-Accounts | Nicht vorhandener Benutzer `c.steffen@gmail.com` wird mit Status `BLOCKED` aktualisiert | Account wird angelegt und aktualisiert            | `updateUserAccount`      |
| 03.1.4 | Anlegen mit ungültiger E-Mail                       | Benutzer mit ungültiger E-Mail `k.karstens@#23w.de`                                     | CHECK-Constraint-Verletzung                       | `getOrCreateUserAccount` |
| 03.1.5 | Aktualisieren mit ungültigem Status                 | Status `SUSPENDED` für bestehenden Benutzer                                             | CHECK-Constraint-Verletzung                       | `updateUserAccount`      |

#### 03.2 Benutzeradressen

| #      | Bezeichnung                            | Beschreibung                                         | Erwartetes Ergebnis                        | Prozedur                 |
|--------|----------------------------------------|------------------------------------------------------|--------------------------------------------|--------------------------|
| 03.2.1 | Anlegen einer Benutzeradresse          | Adresse vom Typ `SHIPPING` für `c.steffen@gmail.com` | Zuordnung wird angelegt, NOTICE mit ID     | `getOrCreateUserAddress` |
| 03.2.2 | Doppelte Benutzeradresse gleichen Typs | Gleiche Adresse erneut als `SHIPPING` zuordnen       | Bestehende ID zurückgegeben, kein Duplikat | `getOrCreateUserAddress` |
| 03.2.3 | Benutzeradresse anderer Typs           | Gleiche Adresse als `PICK_UP` zuordnen               | Zweite Zuordnung erfolgreich               | `getOrCreateUserAddress` |
| 03.2.4 | Anlegen mit ungültigem Adresstyp       | Adresse mit Typ `OTHER` zuordnen                     | Exception: `Invalid addresstype`           | `getOrCreateUserAddress` |

#### 03.3 Rollenmanagement

| #      | Bezeichnung                   | Beschreibung                                     | Erwartetes Ergebnis                                           | Prozedur           |
|--------|-------------------------------|--------------------------------------------------|---------------------------------------------------------------|--------------------|
| 03.3.1 | Anlegen einer Rolle           | Neue Rolle `New role` einfügen                   | Insert erfolgreich                                            | `INSERT INTO role` |
| 03.3.2 | Löschen einer Rolle als User  | Rolle `New role` durch normalen Benutzer löschen | Exception: `You are not allowed to delete a role`             | `deleteRole`       |
| 03.3.3 | Löschen einer Rolle als Admin | Rolle `New role` durch Admin löschen             | Rolle erfolgreich gelöscht                                    | `deleteRole`       |
| 03.3.4 | Löschen der Rolle ADMIN       | Rolle `ADMIN` durch Admin löschen                | Rolle gelöscht, `user_role`-Zuordnungen kaskadierend entfernt | `deleteRole`       |
| 03.3.5 | Löschen der Rolle MISC        | Rolle `MISC` durch Admin löschen                 | Rolle gelöscht, `user_role`-Zuordnungen kaskadierend entfernt | `deleteRole`       |

### 04 – Buch-Exemplare (`04_testCases_BookCopyData.sql`)

#### 04.1 Buch-Exemplare

| #      | Bezeichnung                           | Beschreibung                                                          | Erwartetes Ergebnis                                                  | Prozedur         |
|--------|---------------------------------------|-----------------------------------------------------------------------|----------------------------------------------------------------------|------------------|
| 04.1.1 | Anlegen eines Buchexemplars           | Exemplar zu ISBN `9781000002003` für `clara.neumann@example.org`      | Exemplar angelegt, NOTICE mit Copy-ID                                | `createBookCopy` |
| 04.1.2 | Aktualisieren eines Buchexemplars     | Exemplar durch berechtigten Besitzer aktualisieren                    | Update erfolgreich                                                   | `updateBookCopy` |
| 04.1.3 | Aktualisieren durch Unberechtigten    | Exemplar durch `jonas.reuter@example.org` aktualisieren               | Exception: `Action cannot be performed`                              | `updateBookCopy` |
| 04.1.4 | Löschen durch Unberechtigten          | Exemplar durch `jonas.reuter@example.org` löschen                     | Exception: `Action cannot be performed`                              | `deleteBookCopy` |
| 04.1.5 | Löschen durch Besitzer                | Exemplar durch berechtigten Besitzer löschen                          | Löschung erfolgreich                                                 | `deleteBookCopy` |
| 04.1.6 | Löschen eines Exemplars mit Ausleihen | Exemplar zu ISBN `9783000001048` von `eva.brandt@example.org` löschen | Exemplar nicht gelöscht, Status `INACTIVE` (referenzierte Ausleihen) | `deleteBookCopy` |

### 05 – Ausleihvorgänge (`05_testCases_BookLoan.sql`)

#### 05.1 Zeitslots

| #      | Bezeichnung                       | Beschreibung                                     | Erwartetes Ergebnis         | Prozedur               |
|--------|-----------------------------------|--------------------------------------------------|-----------------------------|------------------------|
| 05.1.1 | Anlegen eines Zeitslots           | Zeitslot Freitag (Tag 5) von 10:00 bis 12:00 Uhr | Insert erfolgreich          | `INSERT INTO timeslot` |
| 05.1.2 | Zeitslot mit Ende vor Beginn      | Zeitslot mit `end_time` vor `begin_time`         | CHECK-Constraint-Verletzung | `INSERT INTO timeslot` |
| 05.1.3 | Zeitslot mit ungültigem Wochentag | Zeitslot mit `day_of_week = 10`                  | CHECK-Constraint-Verletzung | `INSERT INTO timeslot` |
| 05.1.4 | Löschen eines Zeitslots           | Zeitslot mit `timeslot_id = 11` löschen          | Datensatz entfernt          | `DELETE FROM timeslot` |

#### 05.2 Abholoptionen

| #      | Bezeichnung                                    | Beschreibung                                                 | Erwartetes Ergebnis               | Prozedur                    |
|--------|------------------------------------------------|--------------------------------------------------------------|-----------------------------------|-----------------------------|
| 05.2.1 | Anlegen einer Abholoption                      | Abholoption mit `user_address_id = 3` und `timeslot_id = 12` | Insert erfolgreich                | `INSERT INTO pickup_option` |
| 05.2.2 | Abholoption ohne Zeitslot                      | Abholoption mit `timeslot_id = NULL`                         | Insert erfolgreich                | `INSERT INTO pickup_option` |
| 05.2.3 | Doppelte Abholoption                           | Gleiche Abholoption erneut einfügen                          | UNIQUE-Constraint-Verletzung      | `INSERT INTO pickup_option` |
| 05.2.4 | Löschen einer nicht referenzierten Abholoption | Abholoption mit `pickup_option_id = 1` löschen               | Datensatz entfernt                | `DELETE FROM pickup_option` |
| 05.2.5 | Löschen einer referenzierten Abholoption       | Abholoption mit `pickup_option_id = 7` löschen               | FOREIGN-KEY-Constraint-Verletzung | `DELETE FROM pickup_option` |

#### 05.3 Erstellen einer Ausleihe

| #      | Bezeichnung                          | Beschreibung                                                     | Erwartetes Ergebnis                      | Prozedur           |
|--------|--------------------------------------|------------------------------------------------------------------|------------------------------------------|--------------------|
| 05.3.1 | Ausleihe per Versand                 | Ausleihvorgang für Exemplar ISBN `9783000001031` ohne Abholdaten | Vorgang angelegt, NOTICE mit Loan-ID     | `createBookLoan`   |
| 05.3.2 | Erneute Ausleihe desselben Exemplars | Gleiches Exemplar erneut ausleihen                               | Exception: `not available`               | `createBookLoan`   |
| 05.3.3 | Ausleihe beenden                     | Rückgabe mit `CURRENT_DATE`                                      | Status `RETURNED`, Rückgabedatum gesetzt | `returnBook`       |
| 05.3.4 | Ausleihe per Abholung                | Ausleihvorgang mit Abholzeit `09:45` und Wochentag 1             | Vorgang mit Pickup-Option angelegt       | `createBookLoan`   |
| 05.3.5 | Rückgabe vor Ausleihdatum            | Rückgabedatum `2026-01-01` setzen                                | CHECK-Constraint-Verletzung              | `returnBook`       |
| 05.3.6 | Status ohne Rückgabedatum            | Status direkt auf `RETURNED` setzen ohne `return_date`           | CHECK-Constraint-Verletzung              | `UPDATE book_loan` |
| 05.3.7 | Ungültiger Ausleihstatus             | Status auf `OUTDATED` setzen                                     | CHECK-Constraint-Verletzung              | `UPDATE book_loan` |

#### 05.4 Suchen von Büchern

| #      | Bezeichnung              | Beschreibung                                                                    | Erwartetes Ergebnis                                | Prozedur                                      |
|--------|--------------------------|---------------------------------------------------------------------------------|----------------------------------------------------|-----------------------------------------------|
| 05.4.1 | Suche verfügbarer Bücher | Englische Bücher per Versand oder Abholung im Radius < 100 km (max. 10 Treffer) | Ergebnisliste mit ISBN, Titel, Zustand, Entfernung | `SELECT` mit `isBorrowable` / `getDistanceKM` |

#### 05.5 Erstellen von Bewertungen

| #      | Bezeichnung                            | Beschreibung                                                                      | Erwartetes Ergebnis                                                       | Prozedur                   |
|--------|----------------------------------------|-----------------------------------------------------------------------------------|---------------------------------------------------------------------------|----------------------------|
| 05.5.1 | Bewertung einfügen                     | Rating für zurückgegebenen Ausleihvorgang (Loan-ID 25, Score 5)                   | Bewertung gespeichert, NOTICE mit Rating-ID                               | `createBookRating`         |
| 05.5.2 | Bewertung ohne abgeschlossenen Vorgang | Bewertung für nicht existierenden oder nicht zurückgegebenen Vorgang (Loan-ID 35) | Exception: `Loan process cannot be rated as it is not completed yet`      | `createBookRating`         |
| 05.5.3 | Bewertung mit ungültigem Score         | Rating mit Score `7` (außerhalb 1–5)                                              | CHECK-Constraint-Verletzung                                               | `createBookRating`         |
| 05.5.4 | Doppelte Bewertung                     | Zweites Rating für denselben Ausleihvorgang (Loan-ID 4)                           | UNIQUE-Constraint-Verletzung                                              | `createBookRating`         |
| 05.5.5 | Durchschnittsbewertung je Titel        | Anonyme Auswertung als Moderator (User-ID 11)                                     | Aggregierte Liste mit ISBN, Titel, Anzahl und Durchschnitt                | `analyzeRatingsAnonymized` |
| 05.5.6 | Auswertung ohne Moderator-Rolle        | Auswertung durch User ohne Rolle `MODERATOR` (User-ID 1)                          | Exception: `You do not have the permission to analyse rating information` | `analyzeRatingsAnonymized` |
