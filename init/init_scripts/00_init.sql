-- Erstellen der Datenbanktabellen
-----------------------------------------------------------------
/* Genre-Tabelle (genre)
   ----------------
   Da Bücher mehreren Genres zugeordnet sein können, wird zunächst eine Nachschlagetabelle mit der
   Bezeichnung (name) des Genres und die eindeutige technische ID (genre_id).
   
   Die Bezeichnung des Genres ist erforderlich und wird daher als NOT NULL angelegt. Zudem
   sollten die Werte in einer Nachschlagetabelle eindeutig sein, um bei Zuordnungen konsistente
   Ergebnisse sicherzustellen. Daher wird das Attribut name zudem mit einem UNIQUE-Constraint
   versehen.
*/
CREATE TABLE genre  
(
    genre_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name     varchar(50) NOT NULL,

    CONSTRAINT uc_genre UNIQUE (name)
);

/* Sprachen-Tabelle (language)
   ----------------
   Für eine zielgerichtet Suche soll die Selektion nach Sprachen möglich sein. Daher wird eine
   weitere Nachschlagetabelle erstellt, die die Buchsprachen repräsentiert. Neben der technischen
   ID und der Sprachbezeichnung, wird zudem der ISO-Code der Sprache erfasst.

   Für sinnvolle Verwendung der Sprache sollten die Felder 'name' und 'iso-code' immer gefüllt
   sein (NOT NULL Constraint). Um Sprachvarianten unterscheiden zu können, aber dennoch
   Doppelungen abzusichern werden beide Felder mit einem UNIQUE-Constraint belegt. Varianten
   können somit über einen Zusatz im Feld name, z.B. Englisch (USA) - en-US oder  Englisch (UK) -
   en-GB, erstellt werden. Zudem ist die Semantik der ISO-Codes eingrenzbar, sodass mit einem
   Check eingegebene Werte direkt überprüft werden können.  Der reguläre Ausdruck lässt Codes mit
   2 Kleinbuchstaben oder 2 Klein- und 2 Großbuchstaben (getrennt durch - ) zu, z.B. en-US
*/
CREATE TABLE language
(
    language_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        varchar(50) NOT NULL,
    iso_code varchar(5) NOT NULL,

    CONSTRAINT uc_lang UNIQUE (name),
    CONSTRAINT uc_lang_iso UNIQUE (iso_code),
    CONSTRAINT chk_lang_isoCode CHECK (iso_code ~ '^[a-z]{2}(-[A-Z]{2})?$')
);

/* Länder-Tabelle (country)
   ----------------
   Zur korrekten Angabe von Adressen wird eine Nachschlagetabelle mit Ländernamen und ISO-Codes
   erstellt. Die Angaben zu Ländern könnte zwar auch in der Adresse selbst erfolgen, jedoch
   entspricht dies nicht einen konsequenten Normalisierung.

   Für eine effiziente Suche und eine konsistente Anzeige sollten beide Felder ('name',
   'iso_code') stets gefüllt sein, sodass beide mit einem NOT NULL-Constraint angelegt werden.
   Zudem ist die Semantik der ISO-Codes vorgegeben und kann über einen Check bei Eingabe
   überprüft werden. Das Prüfkriterium lässt Codes mit 2 Großbuchstaben zu, z.B. US.
*/
CREATE TABLE country
(
    country_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       varchar(50) NOT NULL,
    iso_code varchar(2) NOT NULL,

    CONSTRAINT uc_country_name UNIQUE (name),
    CONSTRAINT uc_country_iso UNIQUE (iso_code),
    CONSTRAINT chk_country_isoCode CHECK (iso_code ~ '^[A-Z]{2}$')
);

/* Ort-Tabelle (location)
   ----------------
   Neben der Nachschlagetabelle für Länder, wird eine weitere Tabelle mit Orten angelegt, sodass
   auch bei wiederkehrende Orten in den Adressen die Normalisierung eingehalten werden kann. Die
   Tabelle verweist dabei per Fremdschlüsselbeziehung auf die zuvor angelegte Ländertabelle
   (country). Darüber hinaus werden die Postleitzahl (postal_code) und Ort (city) als
   Tabellenspalten angelegt.

   Um diese in Adressen sinnvoll verwenden zu können, werden beide Spalten als Pflichtfelder (NOT
   NOLL-Constraint) angelegt. Da ein Ort mehreren Postleitzahlen zugeordnet sein kann, ist auf
   beiden Spalten kein UNIQUE-Constraint zu setzen. Da die Kombination aus beiden Attributen aber
   eindeutig sein muss, wird ein zusammengesetztes Constraint gesetzt.

*/
CREATE TABLE location
(
    location_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    postal_code varchar(10) NOT NULL,
    city        varchar(50) NOT NULL,
    country_id bigint NOT NULL,

    CONSTRAINT uc_location_name UNIQUE (postal_code, city, country_id),
    CONSTRAINT fk_location_country FOREIGN KEY (country_id) REFERENCES country (country_id)
);

/* Adress-Tabelle (address)
   ----------------
   Erstellt eine Tabelle mit Adressen der Benutzer und Verlage. Diese Adressen werden im Prozess
   für die Abholung und/oder den Versand verwendet bzw. im Fall der Verlage als Information an
   der Entität 'publisher'. Die Adresse setzt sich aus der Straße und Hausnummer sowie über eine
   Fremdschlüsselbeziehung den Ort zusammen. Die Attribute Längen- (longitude) und Breitengrad
   (latitude) sind zusätzliche Attribute, um bei für die Anzeige der Suchergebnisse auch eine
   lokale/regionale Suche zu unterstützen.

   Um einen Versand oder eine Abholdung durchführen zu können, sind die Informationen zu Straße
   und Ort als erforderliche Attribute gekennzeichnet, während die Hausnummer auch NULL-Werte
   annehmen darf, da es Adressen ohne Information zur Hausnummer geben kann.

   Die Hausnummer wird als String angelegt, damit auch alphanummerische Eingaben wie 12a, möglich
   sind. Längen- und Breitengrad haben eine feste Syntax, sodass es sich dabei um Zahlwerte
   handelt, die maximal 9 Zeichen lang sein können (3 Vorkomma- und 6 Nachkommastellen).
   Da beide nur Werte in einem definierten Intervall (Breitengrad: -90 bis +90, Längengrad: -180
   bis +180) annehmen können, werden zusätzlich Prüfkriterien gesetzt.
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
   Erstellt eine Nachschlagetabelle mit Adresstypen. Diese ermöglicht es, die Art der Adresse
   (z.B. Abhol- oder Versandadresse) zu definieren. Die Nutzung einer eigenen Tabelle bietet den
   Vorteil, dass die Adresstypen flexibel erweitert werden können und somit individuell genutzt
   werden können.

   Für den vorliegenden Fall werden die Adresstypen Versandadresse (SHIPPING) und Abholadresse
   (PICK_UP) angelegt. Die Angabe des Namens ist dabei Pflicht und muss eindeutig sein, damit der
   Typ im Weiteren Verwendung finden kann.
*/
CREATE TABLE address_type
(
    address_type_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name            varchar(50) NOT NULL,

    CONSTRAINT uc_address_type_name UNIQUE (name)
);


/* Verleger-Tabelle
   ----------------
   Erstellt eine Tabelle mit Name, Adresse und Webseite von Verlagen, um sie den Büchern zuordnen
   zu können. Während die Adresse und die Webseite des Verlages optionale Informationen sind, ist
   die Erfassung des Namens des Verlages Pflicht, sodass diese Spalte mit NOT NULL
   gekennzeichnet wird.

   Die Adresse wird als Fremdschlüsselbeziehung auf die Adress-Tabelle abgebildet. Um einen Verlag
   bei der Anlage oderZuweisung eines Buches identifizieren zu können, wird festgelegt, dass die
   Kombination aus Verlagsname und der Adresse als eindeutiges Merkmal verwendet wird. Wird keine
   Adresse angegeben, so ist die Bezeichnung alleine das eindeutige Merkmal. Daher wird das
   UNIQUE Constraint um NULLS NOT DISTINCT ergänzt. Andernfalls würde die fehlende Angaben einer
   Adresse bei gleicher Verlagsbezeichnung einen neuen Eintrag anlegen, auch wenn bereits der
   gleiche Name ohne Adresse besteht.
*/
CREATE TABLE publisher
(
    publisher_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name         varchar(255) NOT NULL,
    website      varchar(255),
    address_id   bigint,

    CONSTRAINT uk_publisher UNIQUE NULLS NOT DISTINCT (name, address_id),
    CONSTRAINT fk_publisher_address FOREIGN KEY (address_id) REFERENCES address (address_id)
);

/* Autoren-Tabelle (author)
   ----------------
   Erstellt eine Tabelle mit Name und Titel von Autoren, um sie den Büchern zuordnen zu können.
   Die Spalte last_name ist als NOT NULL gekennzeichnet, da zumindest der Nachname für eine
   sinnvolle Zuorndung gefüllt sein sollte. Um einen Autoren bei z.B. der Erstellung eines Buches
   wiederfinden zu können, wird ein zusammengesetztes UNIQUE-Constraint auf alle Tabellenspalten
   gesetzt. Ein nicht gesetzter akademischer Titel soll nicht implizieren, dass es sich um einen
   neuen Eintrag handelt, daher wird das Constraint um NULLS NOT DISTINCT ergänzt.
*/
CREATE TABLE author
(
    author_id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    academic_title varchar(10),
    first_name     varchar(50),
    last_name varchar(50) NOT NULL,

    CONSTRAINT uk_author UNIQUE NULLS NOT DISTINCT (academic_title, first_name, last_name)
);

/* Bücher-Tabelle (book)
   ------------------
   Erstellt eine Tabelle mit den Informationen zu Büchern, wie Titel, ISBN, Beschreibung oder
   Veröffentlichung. Für das leichte Auffinden von Büchern sind der Titel und die ISBN Nummer
   eindeutige Suchkriterien und werden daher als Pflichtfelder definiert. Darüber hinaus ist die
   ISBN eine global eindeutige Nummer, sodass das Attribut zusätzlich mit einem UNIQUE-CONSTRAINT
   versehen wird. Um sicherzustellen, dass nur gültige ISBN eingetragen werden können, wird beim
   Anlegen und Ändern abgeprüft, dass die ISBN exakt 13 Zeichen lang ist und nur nummerische
   Zeichen enthält.

   Zudem werden das Erscheinungsjahr und die Auflage um eine Prüfung ergänzt, sodass
   ausschließlich realistische Daten eigetragen werden können.

   Verlag und Sprache sind über eine Fremdschlüsselbeziehung mit der Bibliografie verknüpft. Da
   beide Attribute kein Pflichtangaben sind, sollte bei einer Löschung eines Verlags oder einer
   Sprache die Bibliografie nicht beeinträchtigt werden. Daher wird jeweils die
   Fremdschlüsseleigenschaft ON DELETE SET NULL gesetzt, sodass lediglich die Referenz aufgelöst
   wird.
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

    CONSTRAINT fk_book_language FOREIGN KEY (language_id) REFERENCES language (language_id)
        ON DELETE SET NULL,
    CONSTRAINT fk_book_publisher FOREIGN KEY (publisher_id) REFERENCES publisher (publisher_id)
        ON DELETE SET NULL,
    CONSTRAINT uc_book_isbn UNIQUE (isbn),
    CONSTRAINT chk_book_isbn CHECK ( isbn ~ '^[0-9]{13}$' ),
    CONSTRAINT chk_book_publication_year CHECK ( publication_year BETWEEN 1000 AND 3000),
    CONSTRAINT chk_book_editon CHECK ( edition > 0 )
);

/* Buch-Autor-Tabelle (book_author)
   ------------------
   Da Bücher von einem oder mehreren Autoren verfasst werden können und ein Autor zudem auch
   mehrere Bücher geschrieben haben kann, liegt eine n:m-Beziehung vor. Diese wird über diese
   Zwischentabelle aufgelöst und ordnet Autoren Büchern zu.

   Als Attribute hat diese Beziehungstabelle ausschließlich die Fremdschlüsselbeziehungen zu Buch
   (book) und Autor (author). Beide Attribute bilden zusammen den Primärschlüssel, da die
   Kombination aus Buch und Autor eindeutig ist.

   Wird die Bibliografie eines Buches entfernt, so ist auch die Zuordnung der Autoren zu dieser
   Bibliografie obselet. Entsprechend wird über die Fremdschlüsseleigenschaft ON DELETE CASCASE
   sichergestellt, dass verwaiste Zuweisungen entfernt werden.
 */

CREATE TABLE book_author
(
    book_id   bigint,
    author_id bigint,

    CONSTRAINT pk_book_author PRIMARY KEY (book_id, author_id),
    CONSTRAINT fk_book_author_author FOREIGN KEY (author_id) REFERENCES author (author_id),
    CONSTRAINT fk_book_author_book FOREIGN KEY (book_id) REFERENCES book (book_id)
        ON DELETE CASCADE
);

/* Buch-Genre-Tabelle (book_genre)
   ------------------
   Da Bücher mehrere Genres besitzen können und ein Genre mehreren Büchern zugeordnet sein kann,
   liegt auch hier eine n:m-Beziehung vor. Diese wird über diese Zwischentabelle aufgelöst und
   ordnet Genres Büchern zu.

   Als Attribute hat diese Beziehungstabelle ausschließlich die Fremdschlüsselbeziehungen zu Buch
   (book) und Genre (genre). Beide Attribute bilden zusammen den Primärschlüssel, da die Kombination
   aus Buch und Genre eindeutig ist.

   Analog zur Behandlung der Beziehung zwischen Bibliografie und Autoren eines Buches, kann auch die
   Zuweisung der Genres zum Buch entfernt werden, sobald dieses gelöscht wird. Daher wird auch
   in diesem Fall die Fremdschlüsseleigenschaft ON DELETE CASCASE auf die Fremdschlüsselbeziehung
   zu book gesetzt.
 */

CREATE TABLE book_genre
(
    book_id  bigint,
    genre_id bigint,

    CONSTRAINT pk_book_genre PRIMARY KEY (book_id, genre_id),
    CONSTRAINT fk_book_genre_author FOREIGN KEY (genre_id) REFERENCES genre (genre_id),
    CONSTRAINT fk_book_genre_book FOREIGN KEY (book_id) REFERENCES book (book_id)
        ON DELETE CASCADE
);

/* Benutzer-Tabelle (user_account)
   ------------------
   Neben den Büchern stellt die Entität Benutzer (user_account) ein zentrales Element der
   Buchtausch-App dar. In der Tabelle werden Nachname und E-Mailadresse als Pflichtfelder (NOT
   NULL) erfasst, da sie für die Identifikation und die die Kommunikation benötigt werden. Der
   Vorname hingegen wird als optional definiert. So ist es auch möglich z.B. juristische Personen
   als Nutzer anzugeben.

   Zudem wird ein Benutzerstatus angelegt. Dieser ermöglicht es im Betrieb
   der App Nutzer zu sperren, ohne sie und ihre Historie zu löschen. Bei Anlage eines Benutzers
   wird davon ausgegangen, dass dieser stets aktiv ist. Daher als Standardwert die Status-ID des Status mit
   dem Wert 'ACTIVE' gesetzt.

   Für Telefonnummer und E-Mailadresse werden weitere Prüfkriterien hinterlegt. Vor allem bei der
   E-Mailadresse wird so sichergestellt, dass sie in einem gültigen Format ohne Sonderzeichen,
   mit @-Zeichen und einer abschließenden Domain gespeichert wird.
   Da die E-Mailadresse in der Regel für die Authentifizierung und die Kommunikation verwendet
   wird, wird ein UNIQUE-Constraint ergänzt.
 */
CREATE TABLE user_account
(
    user_id        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    academic_title varchar(10),
    first_name     varchar(50),
    last_name      varchar(50)  NOT NULL,
    email          varchar(255) NOT NULL,
    phone          varchar(20),
    status_id bigint NOT NULL DEFAULT 1,

    CONSTRAINT uc_user_email UNIQUE (email),
    CONSTRAINT fk_user_status FOREIGN KEY (status_id) REFERENCES status (status_id),
    CONSTRAINT chk_user_phone CHECK (phone ~ '^[+][0-9 -]+$'),
    CONSTRAINT chk_user_email CHECK (email ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[A-Za-z]{2,}$')
);
/* Benutzer-Adresse-Tabelle (user_address)
   ----------------------
   Da Benutzer unterschiedliche Adressen im Kontext der Anwendung haben können, um zwischen Abhol-
   und Versandadresse zu unterscheiden oder den Versand auch an andere Adressen als die
   Wohnadresse zu ermöglichen, ist diese Zwischentabelle notwendig. Denn durch die Möglichkeit
   mehrere Adressen pro Benutzer angeben zu können und die Option, dass eine Adresse von mehreren
   Nutzern angegeben wird (Personen, die im gleichen Haus wohnen), liegt hier eine m:n Beziehung
   vor.

   Neben den beiden Fremdschlüsselbeziehungen zum Benutzer (user_account) und der Adresse
   (address) wird der Zwischentabelle das Attribut Adresstyp (address_type) hinzugefügt. Dieser
   Fremdschlüssel ermöglicht es, zu definieren, zu welchem Zweck eine Adresse verwendet wird
   (Versand- oder Abholadresse).

   Aufgrund der eindeutigen Fremdschlüsselbeziehungen könnte auch hier ein zusammengesetzter
   Primärschlüssel verwendet werden. Da die Adresszuordnungen zusammen mit den Abholorten
   verwendet werden, bietet es sich an, einen technischen Primärschlüssel zu definieren, da
   dieser als Fremdschlüssel leichter zu referenzieren ist. Durch diese Anpassung ist es aber
   notwendig, dass die weiteren Attribute aufgrund ihrer Abhängigkeiten als Pflicht definiert
   werden. Da eine Adresse, eines Users nicht mehrfach dem gleichen Adresstypen zugeordnet sein
   sollte, wird zudem ein zusammengesetztes UNIQUE-Constraint definiert.

   Wird eine Benutzer aus der Datenbank entfernt, so sind die Zuordnungen von Adressen zum
   Benutzer nicht mehr relevant und können aufgelöst werden. Dies wird durch ein ON DELETE
   CASCADE auf der Fremdschlüsselbeziehung erwirkt. Beim Löschen einer Adresse sollten die
   Zuordnungen hingegen nicht aufgelöst werden, da eine Adresse mehreren Benutzern zugeordnet
   sein könnte. Somit würden alle Zuordnungen verloren gehen, obwohl nur die Adresse für eine
   Person gelöscht werden soll. Daher wird keine Fremdschlüsseleigenschaft explizit gesetzt,
   sodass das Löschen einer Adresse verhindert wird, sofern diese noch referenziert wird.
 */
CREATE TABLE user_address
(
    user_address_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id         bigint NOT NULL,
    address_id      bigint NOT NULL,
    address_type_id bigint NOT NULL,

    CONSTRAINT fk_user_address_user FOREIGN KEY (user_id) REFERENCES user_account (user_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_user_address_address FOREIGN KEY (address_id) REFERENCES address (address_id),
    CONSTRAINT fk_user_address_type FOREIGN KEY (address_type_id) REFERENCES address_type
        (address_type_id),
    CONSTRAINT uc_user_address UNIQUE (user_id, address_id, address_type_id)
);

/* Status-Tabelle (status)
   ----------------------
   Der Status ist eine Nachschlagetabelle, die unterschiedliche Status-Werte aufnimmt. Im Standard sind
   dies zunächst aktiv (ACTIVE), inaktiv (INACTIVE) und gesperrt (BLOCKED). Diese Werte werden bei
   Initialisierung der Datenbank erstellt.

   Der Status dient als Grundlage für das (De-)Aktivieren und Sperren von Einträgen wie Benutzern und
   Buchexemplaren. So ist es möglich Datensätze aus den Geschäftsprozessen zu entfernen, ohne die Historien
   wie z.B. die Ausleihvorgänge mitlöschen zu müssen. Durch das Setzen eines nicht aktiven Status können
   die Objekte wo nötig ausgefiltern werden.
*/
CREATE TABLE status
(
    status_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name      varchar(10) NOT NULL,

    CONSTRAINT uc_status_name UNIQUE (name)
);


/* Buchexemplar-Tabelle (book_copy)
   ----------------------
   Während die Entität Buch (book) die globalen Metadaten des Buches verwaltet, wird mit dem
   Buchexemplar (book_copy) eine Tabelle angelegt, die die konkreten Expemplare eines Buches dem
   Inhaber zuordnet und weitere Attribute wie Zustand, Status oder Ausleihdauer definiert.

   Die Verknüpfung zu Buch (book) und Inhaber (user_account) werden über
   Fremdschlüsselbeziehungen hergestellt. Beides sind Pflichtfelder da ein Buchexemplar ohne
   beide Informationen nicht existieren kann.

   Zudem sind die Attribute Status (status) und Leihdauer (loan_duration_days) als
   Pflicht gekennzeichnet, da die Leihdauer für den Ausleihprozess relevant ist. Sie könnte zwar
   im Prozess individuell gesetzt werden, jedoch erscheint die Definition durch den Inhaber eines
   Exemplares als realitätsnäher. Zudem wird ein Prüfkriterium gesetzt, sodass sichergestellt
   ist, dass nur positive Zahlenwerte angegeben werden können. Der Status soll dazu
   dienen, einzelne Exemplare temporär (BLOCKED) oder dauerhaft (INACTIVE) von der Leihe ausnehmen zu
   können. Insbesondere der inaktiv-Status ist hilfreich, um nicht mehr verfügbare Exemplare nicht mehr
   anzubieten, aber dennoch die verknüpfte Historie zu behalten. Als CHECK-Constraint werden die zulässigen
   Status aktiv (ACTIVE), inaktiv (INACTIVE) und gesperrt (BLOCKED) hinterlegt.

   Das Feld Zustand (condition) kann durch den Inhaber genutzt werden, um den Zustand des Buches
   kurz zu beschreiben. Die Abbildung über eine Entität mit definierten Status wäre hier denkbar,
   wurde aber bewusst auf eine kurze textuale Beschreibung reduziert, um die Komplexität gering
   zu halten.

   Sollte der Eigentümer aus der Datenbank entfernt werden, sind in der Regel auch die Exemplare,
   die durch die Person verliehen werden, nicht mehr sinnvoll abbildbar. Dies wird durch ON
   DELETE CASCADE auf der Fremdschlüsselbeziehung zum user_account sichergestellt. Hierbei ist zu
   berücksichtigen, dass aufgrund der Abhängigkeiten zu den Ausleihvorgängen eine Löschung nur
   möglich ist, wenn keine Ausleihvorgänge bestehen.
 */
CREATE TABLE book_copy
(
    book_copy_id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    book_id            bigint   NOT NULL,
    owner_id           bigint   NOT NULL,
    status_id bigint NOT NULL DEFAULT 1,
    loan_duration_days smallint NOT NULL,
    condition          varchar(50),

    CONSTRAINT fk_book_copy_book FOREIGN KEY (book_id) REFERENCES book (book_id),
    CONSTRAINT fk_book_copy_status FOREIGN KEY (status_id) REFERENCES status (status_id),
    CONSTRAINT fk_book_copy_owner FOREIGN KEY (owner_id) REFERENCES user_account (user_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_book_copy_duration CHECK (loan_duration_days > 0)
);

/* Bereitstellungsart-Tabelle (book_copy)
   ----------------------
   Während des Ausleihprozesses stehen mehrere Möglichkeiten für die Bereitstellung der Exemplare
   zur Verfügung (Versand, Abholung). Damit diese entsprechend einer ordentlichen Normalisierung
   Ausleihvorgänge und Bereitstellarten miteinander verknüpft werden können, wird eine
   Nachschlagetabelle für die Bereitstellungsarten erstellt. Diese enthält die technische ID
   sowie eine eindeutige Bezeichnung (UNIQUE-Constraint) und wird als Pflichtfeld erstellt (NOT
   NULL-Constraint). Dies eröffnet auch die Möglichkeit, beliebiege weitere Bereitstellungsarten
   (z.B. digital) zu erweitern.

   Für den Start werden die Buchungsarten jedoch zunächst auf Abholung und Versand eingeschränkt.
   Hierfür wird ein Prüfkriterium hinzugefügt, das nur die Werte Versand ('SHIPPING') und Abholung
   ('PICK_UP') zulässt.
*/

CREATE TABLE fulfillment_type
(
    fulfillment_type_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(50) NOT NULL,

    CONSTRAINT uk_fulfillment_type_name UNIQUE (name),
    CONSTRAINT chk_fulfillment_type CHECK ( name IN ('PICK_UP', 'SHIPPING'))
);

/* Exemplar-Bereitstellungsarten-Tabelle (book_copy_fulfillment)
   ----------------------
   Da eine Exemplar (book_copy) nicht nur über einen Weg bereitgestellt werden kann, wird eine
   Zuordnungstabelle für die Bereitstellungarten je Exemplar book_copy_fulfillment erstellt.
   Durch diese Zwischentabelle ist es möglich einem Exemplar unterschiedliche
   Bereitstellungsarten gleichzeitig zuzuweisen.

   Die Tabelle besteht nur aus den Fremdschlüsseln auf das Exemplar (book_copy_id) und die Art
   zur Bereitstellung (fulfillment_type_id), die gleichzeitig den zusammengesetzten
   Primärschlüssel bilden.

   Da die Zuordnung der Bereitstellungsart nicht mehr relevant ist, wenn ein Buchexemplar
   gelöscht wird, wird zum Verhindern verwaister Einträge die Fremdschlüsselbeziehung zum
   Exemplar auf ON DELETE CASCADE gesetzt.
*/

CREATE TABLE book_copy_fulfillment
(
    fulfillment_type_id bigint,
    book_copy_id        bigint,

    CONSTRAINT pk_book_copy_fulfillment PRIMARY KEY (fulfillment_type_id, book_copy_id),
    CONSTRAINT fk_book_copy_fulfillment_copy FOREIGN KEY (book_copy_id) REFERENCES book_copy (book_copy_id)
        ON DELETE CASCADE,
    CONSTRAINT book_copy_fulfillment_fulfillment FOREIGN KEY (fulfillment_type_id) REFERENCES
        fulfillment_type (fulfillment_type_id)
);

/* Rollen-Tabelle (role)
   ----------------------
   Die Entität Rolle (role) beschreibt die unterschiedlichen Rollen, die ein Benutzer innerhalb
   der Ausleih-App zugewiesen bekommen kann. Die Rolle besteht dabei nur aus der Bezeichnung
   (name) und einer eindeutigen ID (role_id). Da der Rollenname für eine eindeutige Zuordnung
   nicht mehrfach vorkommen darf, wird auf der Spalte ein NOT NULL-Constraint
   gesetzt.
*/

CREATE TABLE role
(
    role_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name    varchar(20) NOT NULL,

    CONSTRAINT uk_role_name UNIQUE (name)
);

/* Benutzerrollen-Tabelle (user_role)
   ----------------------
   Benutzer können im Rahmen der Ausleih-App unterschiedliche Rollen zugewiesen bekommen. Da es in
   der Regel sinnvoll ist, dass ein Benutzer eine oder mehrere Rollen inne haben kann, wird eine
   Zuordnungstabelle von Benutzer und Rolle erstellt. Diese enthält sowohl den Verweis auf den
   Benutzer (user_id) und die Rolle (role_id) als Fremdschlüssel. Beide Felder zusammen bilden
   den zusammengesetzten Primärschlüssel.

   Die Beziehung kann letztlich aufgelöst werden, wenn ein Benutzer oder die zugehörige Rolle
   gelöscht wird. Somit wird der Fremdschlüssel auf user_account mit einem ON DELETE CASCADE
   versehen.
*/

CREATE TABLE user_role
(
    role_id bigint NOT NULL,
    user_id bigint NOT NULL,

    CONSTRAINT pk_user_role PRIMARY KEY (role_id, user_id),
    CONSTRAINT fk_user_role_role FOREIGN KEY (role_id) REFERENCES role (role_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_user_role_user FOREIGN KEY (user_id) REFERENCES user_account (user_id)
        ON DELETE CASCADE
);

/* Zeitslot-Tabelle (timeslot)
   ----------------------
   Buchexemplare sollen zur Abholung angeboten werden, wobei es dem Anbieter möglich sein soll,
   Zeitfenster zu definieren in denen eine Abholung möglich ist. Hierfür wird eine Tabelle mit
   möglichen Zeitfenstern (timeslot) für die Abholung angelegt. Sie enthält die Beginn-
   (begin_time) und End-Uhrzeit (end_time) des Zeitfensters  sowie den zugehörigen Wochentag
   (day_of_week).

   Fachlich wird vorausgesetzt, dass alle drei Attribute für die Erstellung eines Zeitfensters
   notwendig sind. Daher werden alle Attribute mit Hilfe von NOT NULL als Pflichtfelder
   gekennzeichnet. Da ein Zeitfenster im Verlauf einer Woche mehrfach vorkommen kann, ist nur die
   Kombination aller drei Felder eindeutig, sodass das UNIQUE-Constraint auf die Kombination der
   Attribute gesetzt wird.

   Um sicherzustellen, dass bei der Eingabe nur zulässige Zeitfenster entstehen, werden zwei
   Prüfkriterien festgelegt. So können die Wochentage nur als Zahlenwerte zwischen 1 und 7
   angegeben werden. Zudem sollte das Ende eines Zeitfensters nicht nach dem Beginn liegen,
   sodass die dies als weiteres Kriterium ergänzt wird.
*/

CREATE TABLE timeslot
(
    timeslot_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    begin_time  time     NOT NULL,
    end_time    time     NOT NULL,
    day_of_week smallint NOT NULL,

    CONSTRAINT uk_timeslot UNIQUE (begin_time, end_time, day_of_week),
    CONSTRAINT chk_timeslot_dayOfWeek CHECK ( day_of_week BETWEEN 1 AND 7),
    CONSTRAINT chk_timeslot_endAfterBegin CHECK ( end_time > begin_time)
);

/* Abholoptionen-Tabelle (pickup_option)
   ----------------------
   Während die möglichen Zeitfenster (timeslot) zentral definiert werden können, kann jeder
   Verleiher festlegen, zu welchen dieser Zeitfenster Abholungungen an einer Abholadresse möglich
   sind. Die  Zuordnungstabelle Abholoptionen (pickup_option) verknüpft über
   Fremdschlüsselbeziehungen die Ids von Abholadressen (user_adress) und Zeitslots (timeslot).

   Da eine Kombination aus Abholadresse und Zeitslot nicht mehrfach auftreten können, wird für
   beide gemeinsam ein UNIQUE-Constraint gesetzt. Da der Zeitslot kein Pflichtfeld ist, wird
   durch den Zusatz NULLS NOT DISTINCT sichergestellt, dass es je Benutzeradresse nur einmal die
   Angabe kein Zeitslot geben kann.

   Aufgrund der Pflichtangabe einer Benutzeradresse innerhalb der Abholoption ist es sinnvoll,
   die Abholoption zu entfernen, sobald die Benutzeradresse gelöscht wird. Dies wird durch die
   Aktion ON DELETE CASCADE erreicht. Da der Zeitslot nicht verpflichtend ist, muss eine Löschung
   dort nicht so restriktiv gehandhabt werden. Bei einer Löschung wird über die Aktion ON DELETE
   SET NULL die Referenz lediglich aufgelöst, die Abholoption bleibt aber weiterhin bestehen. Zu
   beachten ist hierbei, dass beim Löschen eines Zeitslot eine UNIQUE-Constraint Verletzung
   auftreten kann, sofern es bereits eine Abholoption gibt, bei der einer Adresse kein Zeitslot
   zugewiesen ist.
*/

CREATE TABLE pickup_option
(
    pickup_option_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_address_id  bigint NOT NULL,
    timeslot_id      bigint,

    CONSTRAINT uk_pickup_option UNIQUE NULLS NOT DISTINCT (user_address_id, timeslot_id),
    CONSTRAINT fk_pickup_option_timeslot FOREIGN KEY (timeslot_id) REFERENCES timeslot (timeslot_id),
    CONSTRAINT fk_pickup_option_user_adress FOREIGN KEY (user_address_id) REFERENCES
        user_address (user_address_id)
        ON DELETE CASCADE
);

/* Ausleihvorgang-Tabelle (book_loan)
   ----------------------
   Die Tabelle book_loan bildet die konkreten Ausleihvorgänge innerhalb der Buchtausch-App ab.
   Jeder Ausleihvorgang bezieht sich auf ein bestimmtes Buchexemplar (book_copy) und einen
   Benutzer (user_account), der dieses Exemplar ausleiht.

   Um sicherzustellen, dass in der Ausleihe nur die Bereitstellungsarten (fulfillment_type)
   gewählt werden, die auch für das jeweilige Exemplar freigegeben sind, wird ein weiterer
   Fremdschlüssel definiert, der auf die Kombination von Exemplar (book_copy) und den
   Bereitstellungstyp (fulfillment-type) in der Zuordnungstabelle book_copy_fulfillment_type
   verweist.

   Die beiden Attribute user_address_id und pickup_option_id werden nicht als Pflichtfelder
   deklariert, da sie abhängig von der gewählten Bereitstellungsart gefüllt werden. Um
   sicherzustellen, dass sie gesetzt werden, wird als Prüfkriterium festgelegt, dass je nach
   Bereitstellungsart das betreffend Feld gefüllt sein muss.

   Der Status eines neu angelegten Ausleihvorgangs wird durch den DEFAULT-Wert zunächst auf
   REQUESTED gesetzt. Mithilfe eines CHECK-Constraints wird sichergestellt, dass nur die
   vorgesehenen Status REQUESTED, ON_LOAN, RETURNED und CANCELED gespeichert werden können.

   Ein weiteres CHECK-Constraint verhindert, dass das Rückgabedatum zeitlich vor dem Ausleihdatum
   liegen darf.
*/

CREATE TABLE book_loan
(
    loan_id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    book_copy_id        bigint      NOT NULL,
    borrower_id         bigint      NOT NULL,
    loan_date           date        NOT NULL,
    return_date         date,
    status              varchar(10) NOT NULL DEFAULT 'REQUESTED',
    fulfillment_type_id bigint      NOT NULL,
    user_address_id     bigint,
    pickup_option_id    bigint,

    CONSTRAINT fk_book_loan_copy FOREIGN KEY (book_copy_id) REFERENCES book_copy (book_copy_id),
    CONSTRAINT fk_book_loan_borrowerid FOREIGN KEY (borrower_id) REFERENCES user_account (user_id),
    CONSTRAINT fk_book_loan_fulfillment FOREIGN KEY (fulfillment_type_id, book_copy_id)
        REFERENCES book_copy_fulfillment (fulfillment_type_id, book_copy_id),
    CONSTRAINT fk_book_loan_user_address FOREIGN KEY (user_address_id) REFERENCES user_address
        (user_address_id),
    CONSTRAINT fk_book_loan_pickup_option FOREIGN KEY (pickup_option_id) REFERENCES
        pickup_option (pickup_option_id),
    CONSTRAINT chk_book_loan_returnDate CHECK ( return_date >= loan_date),
    CONSTRAINT chk_book_loan_status CHECK ( status IN ('REQUESTED', 'ON_LOAN', 'RETURNED', 'CANCELED')),
    CONSTRAINT chk_book_loan_return_status CHECK ((status = 'RETURNED' AND return_date IS NOT NULL) OR
        (status <> 'RETURNED' AND return_date IS NULL))
);


/* Bewertungs-Tabelle (loan_rating)
   ----------------------
   Nach Abschluss eines Ausleihvorgangs kann dieser durch den ausleihenden Benutzer bewertet
   werden. Zu diesem Zweck wird die Tabelle loan_rating angelegt. Sie enthält neben einem
   künstlichen Primärschlüssel Fremdschlüsselbeziehung zum bewerteten Ausleihvorgang (book_loan),
   eine numerische Bewertung sowie einen optionalen Kommentar.

   Da jeder Ausleihvorgang höchstens einmal bewertet werden soll, wird das Fremdschlüsselattribut
   loan_id  mit einem UNIQUE-Constraint versehen. So wird verhindert, dass mehrere Bewertungen
   für denselben Ausleihvorgang angelegt werden. Die eigentliche Bewertung ist eine Pflichtangabe
   und wird durch ein CHECK-Constraint auf Werte zwischen eins und fünf begrenzt. Im Gegensatz
   dazu ist der Kommentar optional und kann für eine ausführlichere Begründung verwendet werden.

   Da eine Bewertung unmittelbar von dem zugehörigen Ausleihvorgang abhängig ist und ein
   Fortbestehen ohne diesen fachlich nicht sinnvoll ist, wir über die referenzielle Aktion ON
   DELETE CASCADE sichergestellt, dass verwaiste Einträge in loan_rating entfernt werden,
   sobald der Ausleihvorgang gelöscht wird.
*/

CREATE TABLE loan_rating
(
    rating_id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    loan_id      bigint   NOT NULL,
    rating_score smallint NOT NULL,
    comment      text,

    CONSTRAINT uk_loan_rating_loan UNIQUE (loan_id),
    CONSTRAINT fk_loan_rating_loan FOREIGN KEY (loan_id) REFERENCES book_loan (loan_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_loan_rating_score CHECK ( rating_score BETWEEN 1 AND 5)
);

/*Erstellt einen Index auf jene Ausleihvorgänge, bei denen sich das Buchexemplar in Ausleihe befindet.
  Der Indext bietet die Möglichkeit, z.B. im Rahmen der Funktion 'isBorrowable' aktuell verfügbare
  Exemplare schneller zu finden*/
CREATE INDEX idx_book_loan_activ_copy ON book_loan (book_copy_id) WHERE status IN ('REQUESTED', 'ON_LOAN');

/*Indizes auf Fremdschlüsselbeziehungen erleichtern die Suche nach Einträgen entgegen der
  Verknüpfungsrichtung. So kann ein Buchtitel über das Exemplar schnell gefunden werden, alle Exemplare zu
  einem Buchtitel werden jedoch nur über eine sequenzielle Suche gefunden.
 */
CREATE INDEX idx_book_copy_book ON book_copy (book_id);
CREATE INDEX idx_book_copy_owner ON book_copy (owner_id);
CREATE INDEX idx_book_genre_genre ON book_genre (genre_id);
CREATE INDEX idx_book_author_author ON book_author (author_id);
CREATE INDEX idx_user_role_user ON user_role (user_id);
CREATE INDEX idx_book_loan_borrower_date ON book_loan (borrower_id, loan_date DESC);