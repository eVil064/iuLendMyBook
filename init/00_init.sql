/* Erstellen der Datenbanktabellen
-----------------------------------------------------------------
   Bei der Erstellung der Datenbanktabellen werden ausschließlich technische Schlüssel als Primärschlussel verwendet. Entgegen eines fachlichen
   Schlüssels bleiben die Beziehungen dadurch eindeutig und konsistent. Ausnahmen bilden Verknüpfungstabellen, bei denen sich der Primärschlüssel
   aus den Fremdschlüsseln der zu verknüpfenden Attribute zusammensetzt.
   Die Erzeugung der Primärschlüssel erfolgt durch Postgres bei Anlage durch die Option 'GENERATED ALWAYS AS IDENTITY PRIMARY KEY'.

   Fremdschlüsselbeziehungen (FOREIGN KEY), Eindeutigkeitsmerkmale (UNIQUE), Prüfkriterien (CHECKS) und Angaben zu Standardwerten werden
   ausschließlich als CONSTRAINT formuliert und nicht direkt am jeweiligen Attribut hinterlegt. Dies erleichtert die Lesbarkeit und ermöglicht
   es, die Einschränkungen eindeutig und semantisch zu benennen. Dies wiederum erleichtert spätere Änderungen an den Einschränkungen, falls notwendig.

   Neben den Kern-Entitäten für die Bücherausleihe werden Nachschlagetabellen für Sprachen, Länder, Verlage und Genres angelegt. Grundsätzlich
   könnten diese Attribute direkt innerhalb der jeweiligen Entität als Text-Attribut modelliert werden. Allerdings birgt dieses Vorgehen das Risiko,
   der Mehrfacherfassung, Rechtschreibfehlern und Fehleingaben. Zudem trägt die Überführung in eigene Entitäten zur Normalisierung der Datenbank bei.
----------------------------------------------------------------- */

/* Genre-Tabelle (genre)
   ----------------
   Bücher können mehreren Genres zugeordnet sein. Hier wird eine Nachschlage-Tabelle mit der Bezeichnung des
   Genres erstellt.

   Als Primärschlüssel wird eine eindeutige, technische ID verwendet, die bei Anlage durch die Postgres automatisch gesetzt wird.
   Die Bezeichnung des Genres ist erforderlich und wird daher als NOT NULL angelegt. Zudem sollte ein Genre sich nicht
   wiederholen, sodass zudem ein Unique-Constraint auf der Spalte gesetzt wird.
*/
CREATE TABLE genre
(
    genre_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name     varchar(50) NOT NULL,

    CONSTRAINT uc_genre UNIQUE (name)
);

/* Sprachen-Tabelle (language)
   ----------------
   Erstellt eine Nachschlage-Tabelle mit Sprachen und ISO-Codes, um z.B. die Buchsprache angeben zu können.
   Der ISO Code wird zusätzlich zur Bezeichnung verwendet, um auch Sprachvarianten (z.B. Englisch (USA) und Englisch (Australien)
   abbilden zu können.

   Für sinnvolle Verwendung der Sprache, sollte das Feld 'name' auch immer gefüllt sein (NOT NULL Constraint).
   Die ISO-Code ist optional, um Sprachvarianten unterscheiden zu können. Da die Kombination aus Name und Code aber nur
   einmal vorkommen kann, wird ein UNIQUE Constraint auf beide Spalten zusammen gesetzt.
   Zudem ist die Semantik der ISO-Codes eingrenzbar, sodass mit einem Check eingegebene Werte direkt überprüft werden können.
   Der reguläre Ausdruck lässt Codes mit 2 Kleinbuchstaben oder 2 Klein- und 2 Großbuchstaben (getrennt durch - ) zu, z.B. en-US

*/
CREATE TABLE language
(
    language_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        varchar(50) NOT NULL,
    iso_code    varchar(5),

    CONSTRAINT uc_lang UNIQUE (name, iso_code),
    CONSTRAINT chk_lang_isoCode CHECK (iso_code ~ '^[a-z]{2}(-[A-Z]{2})?$')
);

/* Länder-Tabelle (country)
   ----------------
   Erstellt eine Nachschlage-Tabelle mit Ländernamen und ISO-Codes, um diese als Angabe an Orten verwenden zu können.
   Der ISO Code dient neben der Bezeichnung des Landes dazu, in der Darstellung des Angebots oder in der Suche übersichtlich
   das jeweilige Land darzustellen.

   Für eine konsistente Anzeige sollten beide Felder ('name', 'iso_code') stets immer gefüllt sein, sodass beide mit einem NOT NULL-Constraint
   angelegt werden.
   Zudem ist die Semantik der ISO-Codes vorgegeben und kann über einen Check bei Eingabe überprüft werden. Das Prüfkriterium lässt Codes mit
   2 Großbuchstaben zu, z.B. US

*/
CREATE TABLE country
(
    country_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       varchar(50) NOT NULL,
    iso_code   varchar(2),

    CONSTRAINT uc_country_name UNIQUE (name),
    CONSTRAINT uc_country_iso UNIQUE (iso_code),
    CONSTRAINT chk_country_isoCode CHECK (iso_code ~ '^[A-Z]{2}$')
);

/* Ort-Tabelle (location)
   ----------------
   Erstellt eine Tabelle mit Postleitzahl, Ort und Land, sodass diese in Verbindung mit der Adresse verwendet werden können.
   Die Anlage einer eigenen Entität erfolgt an dieser Stelle, um strikt den Vorgaben zur Normalisierung der dritten Normalform zu dienen.

   Zieht man die Adresse zum Versand der Bücher heran, sollte diese vollständig sein. Aus diesem Grund wird für die Attribute Ort ('city') und
   Postleitzahl ('postal_code') das NOT NOLL-Constraint gesetzt.
   Darüber hinaus ist über eine Fremdschlüsselbeziehung zur Tabelle 'country' das jeweilige Land verknüpft.
   Da ein Ort mehreren Postleitzahlen zugeordnet sein kann, ist auf beiden Spalten kein UNIQUE-Constraint zu setzen. Da die Kombination aus
   beiden Attributen aber eindeutig sein muss, wird ein zusammengesetztes Constraint gesetzt.

*/
CREATE TABLE location
(
    location_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    postal_code varchar(10) NOT NULL,
    city        varchar(50) NOT NULL,
    country_id  bigint,

    CONSTRAINT uc_location_name UNIQUE (postal_code, city),
    CONSTRAINT fk_location_country FOREIGN KEY (country_id) REFERENCES country (country_id)
);

/* Adress-Tabelle (address)
   ----------------
   Erstellt eine Tabelle mit Adressen der Benutzer und Verlage. Diese Adressen werden im Prozess für die Abholung und/oder den Versand verwendet bzw.
   im Fall der Verlage als Information an der Entität 'publisher'. Die Adresse setzt sich aus der Straße und Hausnummer sowie über eine Fremd-
   schlüsselbeziehung den Ort zusammen. Die Attribute Längen- (longitude) und Breitengrad (latitude) sind zusätzliche Attribute, um bei für die Anzeige
   der Suchergebnisse auch eine lokale/regionale Suche zu unterstützen.

   Um einen Versand oder eine Abholdung durchführen zu können, sind die Informationen zu Straße und Ort als erforderliche Attribute gekennzeichnet, während
   die Hausnummer auch NULL-Werte annehmen darf, da es Adressen ohne Information zur Hausnummer geben kann

   Die Hausnummer wird als String angelegt, damit auch alphanummerische Eingaben wie 12a, möglich sind. Längen- und Breitengrad haben eine feste
   Syntax, sodass es sich dabei um Zahlwerte handelt, die maximal 9 Zeichen lang sein können (3 Vorkomma- und 6 Nachkommastellen). Da beide nur Werte in einem
   definierten Intervall (Breitengrad: -90 bis +90, Längengrad: -180 bis +180) annehmen können, werden zusätzlich Prüfkriterien gesetzt

*/
CREATE TABLE address
(
    address_id  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    street      varchar(255) NOT NULL,
    number      varchar(10),
    location_id bigint       NOT NULL,
    longitude   numeric(9, 6),
    latitude    numeric(9, 6),

    CONSTRAINT fk_address_location FOREIGN KEY (location_id) REFERENCES location (location_id),
    CONSTRAINT chk_address_longitude CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT chk_address_latitude CHECK (latitude BETWEEN -90 AND 90)
);

/* Adress_Typ (address_type)
   ----------------
   Erstellt eine Nachschlage-Tabelle mit Adresstypen. Diese ermöglicht es, die Art der Adresse (z.B. Abhol- oder Versandadresse) zu definieren.
   Die Nutzung einer eigenen Tabelle bietet den Vorteil, dass die Adresstypen flexibel erweitert werden können und somit individuell genutzt werden können.

   Für den vorliegenden Fall werden die Adresstypen Versandadresse (SHIPPING) und Abholadresse (PICKUP) angelegt. Die Angabe des Namens ist dabei Pflicht
   und muss eindeutig sein, damit der Typ im Weiteren Verwendung finden kann.

*/
CREATE TABLE address_type
(
    address_type_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name            varchar(50) NOT NULL,

    CONSTRAINT uc_address_type_name UNIQUE (name)
);


/* Verleger-Tabelle
   ----------------
   Erstellt eine Tabelle mit Name, Adresse und Webseite von Verlagen, um sie den Büchern zuordnen zu können.
   Während die Adresse und die Webseite des Verlages optionale Informationen sind, ist die Erfassung des Namens des Verlages Pflicht,
   sodass diese Spalte mit NOT NULL gekennzeichnet wird.

   Die Adresse wird als Fremdschlüsselbeziehung auf die Adress-Tabelle abgebildet.
*/
CREATE TABLE publisher
(
    publisher_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name         varchar(255) NOT NULL,
    website      varchar(255),
    address_id   bigint,

    CONSTRAINT fk_publisher_address FOREIGN KEY (address_id) REFERENCES address (address_id)
);


/* Autoren-Tabelle (author)
   ----------------
   Erstellt eine Tabelle mit Name und Titel von Autoren, um sie den Büchern zuordnen zu können.
   Die Spalte last_name ist als NOT NULL gekennzeichnet, da zumindest der Nachname für eine sinnvolle Zuorndung gefüllt
   sein sollte. Da die Namen von Autoren oder deren Kombination nicht eindeutig sind, wird auf ein UNIQUE-Constraint verzichtet.
*/
CREATE TABLE author
(
    author_id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    academic_title varchar(25),
    first_name     varchar(50),
    last_name      varchar(50) NOT NULL
);

/* Bücher-Tabelle (book)
   ------------------
   Erstellt eine Tabelle mit den Informationen zu Büchern, wie Titel, ISBN, Beschreibung oder Veröffentlichung.
   Für das leichte Auffinden von Büchern sind der Titel und die ISBN Nummer eindeutige Suchkriterien und werden daher als
   Pflichtfelder definiert. Darüber hinaus ist die ISBN eine global eindeutige Nummer, sodass das Attribut zusätzlich mit einem
   UNIQUE-CONSTRAINT versehen wird.
 */
CREATE TABLE book
(
    book_id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title            varchar(255) NOT NULL,
    isbn             varchar(13)  NOT NULL,
    description      text,
    publication_year smallint,
    edition          smallint,
    language_id      bigint,
    publisher_id     bigint,

    CONSTRAINT fk_book_language FOREIGN KEY (language_id) REFERENCES language (language_id),
    CONSTRAINT fk_book_publisher FOREIGN KEY (publisher_id) REFERENCES publisher (publisher_id),
    CONSTRAINT uc_book_isbn UNIQUE (isbn),
    CONSTRAINT chk_book_isbn CHECK ( isbn ~ '^[0-9]{13}$' )
);

/* Buch-Autor-Tabelle (book_author)
   ------------------
   Da Bücher von einem oder mehreren Autoren verfasst werden können und ein Autor zudem auch mehrere Bücher geschrieben haben kann,
   liegt eine n:m-Beziehung vor. Diese wird über diese Zwischentabelle aufgelöst und ordnet Autoren Büchern zu.

   Als Attribute hat diese Beziehungstabelle ausschließlich die Fremdschlüsselbeziehungen zu Buch (book) und Autor (author).
   Beide Attribute bilden zusammen den Primärschlüssel, da die Kombination aus Buch und Autor eindeutig ist.
 */

CREATE TABLE book_author
(
    book_id   bigint,
    author_id bigint,

    CONSTRAINT pk_book_author PRIMARY KEY (book_id, author_id),
    CONSTRAINT fk_book_author_author FOREIGN KEY (author_id) REFERENCES author (author_id),
    CONSTRAINT fk_book_author_book FOREIGN KEY (book_id) REFERENCES book (book_id)
);

/* Buch-Genre-Tabelle (book_genre)
   ------------------
   Da Bücher mehrere Genres besitzen können und ein Genre mehreren Büchern zugeordnet sein kann,
   liegt auch hier eine n:m-Beziehung vor. Diese wird über diese Zwischentabelle aufgelöst und ordnet Genres Büchern zu.

   Als Attribute hat diese Beziehungstabelle ausschließlich die Fremdschlüsselbeziehungen zu Buch (book) und Genre (genre).
   Beide Attribute bilden zusammen den Primärschlüssel, da die Kombination aus Buch und Genre eindeutig ist.
 */

CREATE TABLE book_genre
(
    book_id  bigint,
    genre_id bigint,

    CONSTRAINT pk_book_genre PRIMARY KEY (book_id, genre_id),
    CONSTRAINT fk_book_genre_author FOREIGN KEY (genre_id) REFERENCES genre (genre_id),
    CONSTRAINT fk_book_genre_book FOREIGN KEY (book_id) REFERENCES book (book_id)
);

/* Benutzer-Tabelle (user_account)
   ------------------
   Legt eine Tabelle für die Benutzer der Applikation an. Dabei werden Nachname und E-Mailadresse als Pflichtfelder erfasst,
   da beide für die Kommunikation benötigt werden. Der Vorname hingegen wird als optional definiert, um es so auch zu
   ermöglichen als Nutzer auch eine juristische Person angeben zu können.

   Der Status dient der Steuerung der Benutzerzugriffe im Prozess, sodass Benutzer nicht nur aktiv sein, sondern auch gesperrt
   werden können. Initial wird der Status jedes Benutzers über den DEFAULT auf aktiv ('ACTIVE') gesetzt. Da nur zwei Status
   möglich sein sollen und weitere Status nicht vorgesehen sind, wird das Attribut als String und nicht als Nachschlage-Tabelle
   angelegt. Die zulässigen Ausprägungen werden durch ein Prüfkriterium auf 'ACTIVE' und 'BLOCKER' festgelegt.

   Zudem werden für Telefonnummer und E-Mailadresse Prüfkriterien hinterlegt, die sicherstellen, dass die Eingaben im korrekten
   Format erfolgen. So werden bei Telefonnummern das internationale Format mit Leerzeichen und Bindestrichen (z.B. +1 555-2566-12)
   unterstützt und bei E-Mailadressen validiert, dass keine unzulässigen Sonderzeichen enthalten sind.
 */
CREATE TABLE user_account
(
    user_id        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    academic_title varchar(10),
    first_name     varchar(50),
    last_name      varchar(50)  NOT NULL,
    email          varchar(255) NOT NULL,
    phone          varchar(20),
    status         varchar(10) DEFAULT 'ACTIVE',

    CONSTRAINT chk_user_phone CHECK (phone ~ '^[+][0-9 -]+$'),
    CONSTRAINT chk_user_email CHECK (email ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_user_status CHECK (status IN ('ACTIVE', 'BLOCKED'))
);
/* Benutzer-Adresse-Tabelle (user_address)
   ----------------------
   Da Benutzer unterschiedliche Adressen im Kontext der Anwendung haben können, um zwischen Abhol- und Versandadresse zu unterscheiden
   oder den Versand auch an andere Adressen als die Wohnadresse zu ermöglichen, ist diese Zwischentabelle notwendig. Denn durch
   die Möglichkeit mehrere Adressen pro Benutzer angeben zu können und die Option, dass eine Adresse von mehreren Nutzern angegeben wird
   (Personen, die im gleichen Haus wohnen), liegt hier eine m:n Beziehung vor.

   Neben den beiden Fremdschlüsselbeziehungen zum Benutzer (user_account) und der Adresse (address) wird der Zwischentabelle das Attribut
   Adresstyp (address_type) hinzugefügt. Dieser Fremdschlüssel ermöglicht es, zu definieren, zu welchem Zweck eine Adresse verwendet wird (Versand- oder
   Abholadresse).

   Aufgrund der eindeutigen Fremdschlüsselbeziehungen könnte auch hier ein zusammengesetzter Primärschlüssel verwendet werden.
   Da die Adresszuordnungen zusammen mit den Abholorten verwendet werden, bietet es sich an, einen technischen Primärschlüssel
   zu definieren, da dieser als Fremdschlüssel leichter zu referenzieren ist. Durch diese Anpassung ist es aber notwendig,
   dass die weiteren Attribute aufgrund ihrer Abhängigkeiten als Pflicht definiert werden. Da eine Adresse, eines Users nicht
   mehrfach dem gleichen Adresstypen zugeordnet sein sollte, wird zudem ein zusammengesetztes UNIQUE-Constraint definiert.
 */
CREATE TABLE user_address
(
    user_address_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id         bigint NOT NULL,
    address_id      bigint NOT NULL,
    type_id         bigint NOT NULL,

    CONSTRAINT fk_user_address_user FOREIGN KEY (user_id) REFERENCES user_account (user_id),
    CONSTRAINT fk_user_address_address FOREIGN KEY (address_id) REFERENCES address (address_id),
    CONSTRAINT fk_user_address_type FOREIGN KEY (type_id) REFERENCES address_type (address_type_id),
    CONSTRAINT uc_user_address UNIQUE (user_id, address_id, type_id)
);

/* Buchexemplar-Tabelle (book_copy)
   ----------------------
   Während die Entität Buch (book) die globalen Metadaten des Buches verwalatet, wird mit dem Buchexemplar (book_copy) eine Tabelle
   angelegt, die die konkreten Expemplare eines Buches dem Inhaber zuordnet und weitere Attribute wie Zustand, Status oder Ausleihdauer
   definiert.

   Die Verknüpfung zu Buch (book) und Inhaber (user_account) werden über Fremdschlüsselbeziehungen hergestellt. Beides sind Pflichtfelder
   da ein Buchexemplar ohne beide Informationen nicht existieren kann.

   Zudem sind die Attribute 'gesperrt' (is_blocked) und Leihdauer (loan_duration_days) als Pflicht gekennzeichnet, da die Leihdauer für den
   Ausleihprozess relevant ist. Sie könnte zwar im Prozess individuell gesetzt werden, jedoch erscheint die Definition durch den Inhaber
   eines Exemplares als realitätsnäher. Zudem wird ein Prüfkriterium gesetzt, sodass sichergestellt ist, dass nur positive Zahlenwerte
   angegeben werden können.
   Der gesperrt-Status soll dazu dienen, einzelne Exemplare von der Leihe (temporär) ausnehmen zu können.
   Er ist nicht zu verwechseln mit dem Entleihstatus. Dieser wird durch den Ausleihprozess definiert und wird nicht am Exemplar persistiert.

   Das Feld Zustand (condition) kann durch den Inhaber genutzt werden, um den Zustand des Buches kurz zu beschreiben. Die Abbildung
   über eine Entität mit definierten Status wäre hier denkbar, wurde aber bewusst auf eine kurze textuale Beschreibung reduziert, um
   die Komplexität gering zu halten.
 */
CREATE TABLE book_copy
(
    book_copy_id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    book_id            bigint   NOT NULL,
    owner_id           bigint   NOT NULL,
    is_blocked         boolean  NOT NULL DEFAULT FALSE,
    loan_duration_days smallint NOT NULL,
    condition          varchar(50),

    CONSTRAINT fk_book_copy_book FOREIGN KEY (book_id) REFERENCES book (book_id),
    CONSTRAINT fk_book_copy_owner FOREIGN KEY (owner_id) REFERENCES user_account (user_id),
    CONSTRAINT chk_book_copy_duration CHECK (loan_duration_days > 0)
);

/* Bereitstellungsart-Tabelle (book_copy)
   ----------------------
   Während des Ausleihprozesses stehen mehrere Möglichkeiten für die Bereitstellung der Exemplare zur Verfügung (Versand, Abholung). Da ein Buch über
   eine oder mehrere dieser Optionen bereitgestellt werden kann, ist je Exemplar eine 1:n Beziehung möglich. Dafür ist eine Zwischentabelle notwendig
   In einer Zwischentabelle könnte man auf das Exemplar referenzieren und den Typ als String als weiteres Attribut der Zwischentabelle einfügen,
   jedoch würde das der Normalisierung entgegenstehen.
   Daher wird hier eine Tabelle mit den Bereitstellungarten erstellt. Diese die Typnamen der Bereitstellungsarten als Pflichtfeld auf. Weiterhin ist das
   Attribut eindeutig, da es nicht zwei gleichlautende Bereitstellungsarten geben sollt.

   Für den Start im Rahmen des Projektes werden die Buchungsarten auf Abholung und Versand eingeschränkt. Hierfür wird ein Prüfkriterium hinzugefügt,
   das nur die Werte Versand ('SHIPPING') und Abholung ('PICK_UP') zulässt.
*/

CREATE TABLE fulfillment_type
(
    fulfillment_type_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    type_name           varchar(50) NOT NULL,

    CONSTRAINT uk_fulfillment_type_name UNIQUE (type_name),
    CONSTRAINT chk_fulfillment_type CHECK ( type_name IN ('PICK_UP', 'SHIPPING'))
);

/* Exemplar-Bereitstellungsarten-Tabelle (book_copy_fulfillment)
   ----------------------
   Da eine Exemplar (book_copy) nicht nur über einen Weg bereitgestellt werden kann, wird eine Zuordnungstabelle für die
   Bereitstellungarten je Exemplar book_copy_fulfillment erstellt. Durch diese Zwischentabelle ist es möglich einem
   Exemplar unterschiedliche Bereitstellungsarten zuzuweisen.

   Die Tabelle besteht nur aus dn beiden Fremdschlüsseln auf das Exemplar (book_copy_id) und die Art zur Bereitstellung
   (fulfillment_type_id), die gleichzeitig den zusammengesetzten Primärschlüssel bilden.
*/

CREATE TABLE book_copy_fulfillment
(
    fulfillment_id bigint,
    copy_id        bigint,

    CONSTRAINT pk_book_copy_fulfillment PRIMARY KEY (fulfillment_id, copy_id),
    CONSTRAINT fk_book_copy_fulfillment_copy FOREIGN KEY (copy_id) REFERENCES book_copy (book_copy_id),
    CONSTRAINT book_copy_fulfillment_fulfillment FOREIGN KEY (fulfillment_id) REFERENCES fulfillment_type (fulfillment_type_id)
);

/* Rollen-Tabelle (role)
   ----------------------
   Die Entität Rolle (role) beschreibt die unterschiedlichen Rollen, die ein Benutzer innerhalb der Ausleih-App zuge-
   wiesen bekommen kann. Die Rolle besteht dabei nur aus der Bezeichnung (name) und einer eindeutigen ID (role_id). Der
   Rollenname darf dabei nicht mehrfach vorkommen, um Inkonsistenzen zu verhindern.

*/

CREATE TABLE role
(
    role_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name    varchar(20) NOT NULL,

    CONSTRAINT uk_role_name UNIQUE (name)
);

/* Benutzerrollen-Tabelle (user_role)
   ----------------------
   Benutzer können im Rahmen der Ausleih-App unterschiedliche Rollen zugewiesen bekommen. Da es in der Regel sinnvoll ist,
   dass ein Benutzer eine oder mehrere Rollen inne haben kann, wird eine Zuordnungstabelle von Benutzer und Rolle erstellt
   Diese enthält sowohl den Verweis auf den Benutzer (user_id) und die Rolle (role_id) als Fremdschlüssel.
   Beide Felder zusammen bilden den zusammengesetzten Primärschlüssel.
*/

CREATE TABLE user_role
(
    role_id bigint NOT NULL,
    user_id bigint NOT NULL,

    CONSTRAINT pk_user_role PRIMARY KEY (role_id, user_id),
    CONSTRAINT fk_user_role_role FOREIGN KEY (role_id) REFERENCES role (role_id),
    CONSTRAINT fk_user_role_user FOREIGN KEY (user_id) REFERENCES user_account (user_id)
);

/* Zeitslot-Tabelle (timeslot)
   ----------------------
   Buchexemplare sollen zur Abholung angeboten werden. Dabei soll es dem Anbieter möglich sein, Zeitfenster zu definieren
   in denen eine Abholung möglich ist. Daher wird hier eine Tabelle mit möglichen Zeitfenstern für die Abholung erstellt
   (timeslot). Sie entält neben einer eindeutigen ID (timeslot_id), die Beginn- (begin_time) und End-Uhrzeit (end_time)
   des Zeitfensters, sowie den zugehörigen Wochentag (day_of_week).

   Für das vorliegende Projekt wird vorausgesetzt, dass Uhrzeiten und Wochentag immer anzugeben sind. Es wäre aber auch
   denkbar, dass kein Wochentag angegeben wird, wenn beispielsweise die Zeitfenster an jedem Tag gleich sind. Oder es
   wäre möglich nur den Wochentag anzugeben, da eine konkrete Abholzeit nicht angegeben ist und eine ganztätige Abholung
   möglich ist. Für eine bessere Steuerbarkeit werden alle drei Attribute als Pflichtfelder markiert. Zudem werden die
   Zeitfenster zunächst zentral vorgegeben, sodass sie nicht individuell pflegbar sind.

   Da die Wochentage nummerisch in der Folge von 1 bis 7 anzugeben sind, wird eine entsprechende Prüfung vorgesehen. Zudem
   muss die Ende-Uhrzeit nach der Beginn-Uhrzeit liegen, um logisch zu sein. Hierfür wird eine weitere Prüfung ergänzt.
   Letztlich können Zeiten oder Wochentage mehrfach angegeben sein, die Kombination aus allen drei Werten ist jedoch
   einzigartig, sodass auf alle drei Attribute ein UNIQUE-Constraint gesetzt wird.

*/

CREATE TABLE timeslot
(
    timeslot_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    begin_time  time     NOT NULL,
    end_time    time     NOT NULL,
    day_of_week smallint NOT NULL,

    CONSTRAINT uk_timeslot UNIQUE (begin_time, end_time, day_of_week),
    CONSTRAINT chk_timeslot_dayOfWeek CHECK ( day_of_week BETWEEN 1 AND 7),
    CONSTRAINT chk_timeslot_endAfteBegin CHECK ( end_time > begin_time)
);

/* Abholoptionen-Tabelle (pickup_option)
   ----------------------
   Während zentral die möglichen Zeitfenster (timeslot) defniert werden können, legt jeder Verleiher eines Buches
   die Abholzeiten für die jeweils angegebene Abholadresse fest. Dafür wird eine Zuordnungstabelle für die Abhol-
   optionen (pickup_options) angelegt. Diese weist neben einer eindeutigen ID auch die zugeordnete Abholadresse (user_adress)
   sowie einen möglichen Zeitslot (timeslot) als Fremdschlüsselbeziehung auf.

   Da es für eine Abholadresse einen Zeitslot nicht mehrfacht geben kann, wird auf beide Attribute ein zusammengesetztes
   UNIQUE-Constraint gesetzt

*/

CREATE TABLE pickup_option
(
    pickup_option_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_address_id  bigint NOT NULL,
    timeslot_id      bigint,

    CONSTRAINT uk_pickup_option UNIQUE (user_address_id, timeslot_id),
    CONSTRAINT fk_pickup_option_timeslot FOREIGN KEY (timeslot_id) REFERENCES timeslot (timeslot_id),
    CONSTRAINT fk_pickup_option_user_adress FOREIGN KEY (user_address_id) REFERENCES user_address (user_address_id)
);


/* xxx-Tabelle (book_loan)
   ----------------------

*/

CREATE TABLE book_loan
(
    loan_id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    copy_id          bigint NOT NULL,
    borrowed_by      bigint NOT NULL,
    loan_date        date   NOT NULL,
    return_date      date,
    status           varchar(10) DEFAULT 'REQUESTED',
    fulfillment_id   bigint NOT NULL,
    user_address_id  bigint,
    pickup_option_id bigint,

    CONSTRAINT fk_book_loan_copy FOREIGN KEY (copy_id) REFERENCES book_copy (book_copy_id),
    CONSTRAINT fk_book_loan_fulfillment FOREIGN KEY (fulfillment_id) REFERENCES fulfillment_type (fulfillment_type_id),
    CONSTRAINT fk_book_loan_user_address FOREIGN KEY (user_address_id) REFERENCES user_address (user_address_id),
    CONSTRAINT fk_book_loan_pickup_option FOREIGN KEY (pickup_option_id) REFERENCES pickup_option (pickup_option_id),
    CONSTRAINT chk_book_loan_returnDate CHECK ( return_date >= loan_date),
    CONSTRAINT chk_book_loan_status CHECK ( status IN ('REQUESTED', 'ON_LOAN', 'RETURNED', 'CANCELED'))
);

/* xxx-Tabelle (loan_rating)
   ----------------------

*/

CREATE TABLE loan_rating
(
    rating_id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    loan_id      bigint   NOT NULL,
    rating_score smallint NOT NULL,
    comment      text,

    CONSTRAINT uk_loan_rating_loan UNIQUE (loan_id),
    CONSTRAINT fk_loan_rating_loan FOREIGN KEY (loan_id) REFERENCES book_loan (loan_id),
    CONSTRAINT chk_loan_rating_score CHECK ( rating_score BETWEEN 1 AND 5)
);


