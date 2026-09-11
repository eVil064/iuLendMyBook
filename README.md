# IU LendMyBook - Bücherausleihe

Dieses Projekt beinhaltet das Konzept und die Implementierung einer Buchtausch-App auf Basis einer
PostgreSQL-Datenbank. Die Kernfunktionen der App sind dabei die Verwaltung der Stammdaten von Büchern,
Buchexemplaren und Benutzern, sowie die Erstellung und Speicherung von Ausleihvorgängen inklusive deren
Bewertungen durch die entleihenden Personen.
Die zentralen Funktionen der App werden über Prozeduren abgebildet, die das Anlegen, Bearbeiten und
Löschen der Entitäten vollziehen. Durch Prüfungen z.B. auf notwendige Rollen oder Abhängigkeiten für die
Ausführung der Prozeduren werden so realitätsnah wesentliche Prozesse im Rahmen der Bereitstellung und
Ausleihe von Buchexemplaren simuliert.
Fiktive, aber plausible Testdatensätze schaffen eine Grundlage, die es ermöglicht die
Datenbankstruktur, Funktionen und Prozeduren zu testen.

Diese `README` enthält eine Installationsanleitung für die Plattformen Docker, Windows und Linux, sowie
eine Kurzbeschreibung der verfügbaren Testfälle. Dazu gehören die modulweisen Prüfungen der Prozeduren,
die End-to-End-Szenarien des Ausleihprozesses und die Performanceanalyse per SQL.

# Installation

## Docker

1. Installation von Docker (siehe https://docs.docker.com/desktop/)
2. Erstellen des Postgres-Containers und Ausführen der Initialisierungs-Skripte
     ```bash 
    docker run --restart=unless-stopped \
        --name iuLendMyBook -d \
        -e POSTGRES_USER=postgres \
        -e POSTGRES_PASSWORD="DLBDSPBDM01_D" \
        -e POSTGRES_DB=iulendmybook \
        -e BASE_PATH="/home/usr/iu/data" \
        -v $PWD/startup_docker.sh:/docker-entrypoint-initdb.d/startup_docker.sh \
        -v $PWD/init:/home/usr/iu/data/init \
        -v $PWD/resources:/home/usr/iu/data/resources \
        -v $PWD/test:/home/usr/iu/data/test \
        -p 5440:5432 postgres:18
    ```
3. Nach Abschluss der Initialisierung die Installation mit Hilfe einer Abfrage überprüfen:
   ```bash 
   docker exec -it iuLendMyBook psql -U postgres -d iulendmybook -c "SELECT count(*) from user_account;"
   ```
   Die Abfrage sollte als Ergebnis 20 Einträge in der Tabelle _user_account_ liefern.
4. Das Ausführen der Testfälle kann entweder über einen Postgres-Client wie `pgAdmin` oder über die
   Kommandozeile des Docker-Containers ausgeführt werden:
    - Über die Kommandozeile in die Shell des Containers wechseln:
      `docker exec -it iuLendMyBook bash`
        - Die Optionen `-i` und `-t` geben an, dass die Shell interaktiv geöffnet wird. Andernfalls
          wird die Shell nicht
          zur Bearbeitung geöffnet
        - Über die Angabe, die dem Containernamen folgt (hier `bash`) kann die Art der Shell
          angegeben werden, die geöffnet wird.
    - Ausführen der Prozedur per `psql`-Command, z.B.
   ```bash
   psql -U postgres -d iulendmybook -c "CALL getOrCreateLanguage('Danish','da-DK', NULL);"
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
3. Anlage eines Verzeichnisses für die Daten des Repositories , z.B. `/home/user/iu/`
   und klonen des Repositories; Voraussetzung hierfür ist das Vorhandensein von Git
   ```bash
   cd /home/user/iu/
   git clone 'https://github.com/eVil064/iuLendMyBook/'
   ```
4. Wechsel in das angelegte Verzeichnis und Ausführung von `startup_linux.sh` zur
   Initialisierung der Datenbank
     ```bash
    cd /home/user/iu/iuLendMyBook
    sudo -u postgres bash ./startup_linux.sh
    ```
5. Nach Abschluss der Initialisierung die Installation mit Hilfe einer Abfrage überprüfen:
   ```bash 
   sudo -u postgres psql -d iulendmybook -c "SELECT count(*) from user_account;"
   ```
Die Abfrage liefert als Ergebnis 20 Einträge in der Tabelle _user_account_.

6. Das Ausführen der Testfälle kann entweder über einen Postgres-Client wie `pgAdmin` oder über die
   Kommandozeile ausgeführt werden, z.B.
   ```bash
   sudo -u postgres psql -U postgres -d iulendmybook -c "CALL createOrUpdateBook(getUserByEmail('felix.brenner@example.org'), 'Herr der Ringe - Die
   Gefährten', '9783608989410','In einem ruhigen Dorf im Auenland bekommt der junge Frodo ein 
   Geschenk ... ', 2006::smallint, 6::smallint, 'de-DE', 'Der Verlag' , ARRAY['J.R.R. Tolkien'], 
   ARRAY['Fantasy'], NULL)"
   ```

## Windows

1. Download und Installation von Postgres-Installer (https://www.postgresql.org/download/windows/, Version 15
   oder höher)
2. Anlage eines Verzeichnisses für das die Daten des Repositorys , z.B. `C:\Users\IU\Datamart\`
   und klonen des Repositories; Voraussetzung hierfür ist das Vorhandensein von Git
   ```powershell
   cd C:\Users\IU\Datamart\
   git clone 'https://github.com/eVil064/iuLendMyBook/'
   cd C:\Users\IU\Datamart\iuLendMyBook
   ```
3. Wechsel in das angelegte Verzeichnis und Ausführung von `startup_windows.bat` zur
   Initialisierung der Datenbank
4. Nach Abschluss der Initialisierung die Installation mit Hilfe einer Abfrage überprüfen:
   ```bash 
   psql -U postgres -d iulendmybook -c "SELECT count(*) from user_account;"
   ```
   Die Abfrage liefert als Ergebnis 20 Einträge in der Tabelle _user_account_.
5. Das Ausführen der Testfälle kann entweder über einen Postgres-Client wie `pgAdmin`, über die
   Kommandozeile oder per PowerShell ausgeführt werden, z.B.
    ```shell
    psql -U postgres -d iulendmybook -c "CALL createOrUpdateBook(getUserByEmail('felix.brenner@example.org'),'Herr der Ringe - Die 
   Gefährten', '9783608989410','In einem ruhigen Dorf im Auenland bekommt der junge Frodo ein 
   Geschenk ... ', 2006::smallint, 6::smallint, 'de-DE', 'Der Verlag' , ARRAY['J.R.R. Tolkien], 
   ARRAY['Fantasy'], NULL)"
    ```

# Performanceanalyse

Die Nutzung von Indizes und die daraus resultierende Abfrageperformance lassen sich **direkt mit SQL**
prüfen. Eine externe Profiling- oder Monitoring-Umgebung ist nicht erforderlich: PostgreSQL liefert
mit `EXPLAIN (ANALYZE, BUFFERS)` den Ausführungsplan, die Laufzeit der einzelnen Schritte und die
verwendeten Indizes.

Das Skript `test/07_performance_analysis.sql` führt diese Analyse exemplarisch anhand der komplexen
Buchsuche aus Testfall 05.4.1 aus. Es vergleicht zwei Durchläufe innerhalb einer Transaktion:

1. **Mit vorhandenen Indizes** – der Optimizer nutzt angelegte Indizes, sofern sie günstiger sind
   als ein sequenzieller Scan. Der Index `idx_book_copy_book` wird bei der kleinen Tabelle
   `book_copy` (rund 50 Einträge) bewusst nicht verwendet; stattdessen erfolgt ein Sequential Scan.
2. **Nach dem Entfernen der Indizes** – dieselben Indizes werden per `DROP INDEX` entfernt. Die
   Ausführungszeit der identischen Abfrage steigt, während die Zeit zur Planerstellung in etwa
   gleich bleibt.

`ANALYZE` aktualisiert vor jedem Durchlauf die Tabellenstatistiken. Am Ende stellt `ROLLBACK` den
Ausgangszustand wieder her, sodass die gelöschten Indizes nicht dauerhaft verloren gehen.

```bash
psql -U postgres -d iulendmybook -f test/07_performance_analysis.sql
```

## Datenbankkennzahlen

Ergänzend zur Performanceanalyse liefert `test/08_database_measures.sql` Metadaten zur aktuellen
Datenbank: Größe und Tabellenanzahl, geschätzte Einträge je Tabelle, Constraint-Arten sowie die
Anzahl primärer, eindeutiger und sonstiger Indizes.
