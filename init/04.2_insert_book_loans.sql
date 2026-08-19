/* Es erfolgt die Anlage beliebiger und fiktiver Ausleihdaten
   - Erstellung zufälliger Ausleihvorgänge für vorhandene Buchexemplare
*/
------------------------------------------------------------------------------------------------------------------------
/* Zufällige Erstellung von Ausleihvorgängen über die Bereitstellungsarten 'Abholung' und 'Versand':
   Als Grundlage zur Erstellung der Ausleihvorgänge werden zunächst relevante Buchexemplare 'relevant_copies' selektiert.
   Dafür werden per random() und LIMIT 25 zufällige Exemplare ausgewählt. Mit floor(random()) wird zufällig die Anzahl
   der zu erstellenden Ausleihvorgänge je Exemplar festgelegt.

   Im zweiten Schritt werden in der Abfrage 'loans_to_insert' die konkreten Datensätze zum Einfügen in die Tabelle 'book_loan'
   berechnet. Hierzu wird aus den ermittelten Exemplaren und den Benutzeraccounts (user_account) über ein CROSS JOIN eine
   Kreuztabelle erstellt, die für jede Kombination aus beiden Tabellen einen Datensatz erzeugt. Um ausschließlich die zuvor
   festgelegte Anzahl an Datensätzen zu erzeugen, wird über das Schlüsselwort LATERAL nicht die Tabelle der Benutzer-Accounts
   verknüpft, sondern eine Unterabfrage. Diese selektiert nur jene User, die nicht gleich dem Eigentümer des Exemplars sind
   (um Leihvorgänge an sich selbst zuunterbinden) und für die eine Benutzeradresse mit dem Adresstyp besteht, der als
   Bereitstellungart für das Exemplar angegeben ist. Durch das LIMIT sichergestellt, dass je Exemplar die zuvor ermittelte
   Anzahl der Vorgänge resultiert. Für die einzufügenden Vorgänge, bei denen die Abholung als Option hinterlegt ist
   wird für jeden Vorgang dieser Buchungsart zufällig eine Abholoption ermittelt. Die Funktion 'row_number' fügt zudem
   eine weitere Spalte ein, die basierend auf der ID des Exemplars die Zeilennummer zurückggibt.

   Abschließend werden die so erzeugten Datensätze in die Tabelle 'book_loan' eingefügt. Anhand der Zeilennummer eines
   Vorgangs werden über das Attribut 'loan_duration_days' das loan_date und das return_date des Vorgangs ermittelt. Die
   Funktion random() steuert hier, wie lange der einzelne Ausleivorgang gedauert hat. Es wird dabei davon ausgegangen,
   dass für die Testdaten alle Vorgänge innerhalb der Leihfrist abgeschlossen wurden und keine Vorgänge offen sind.
   */
WITH relevant_copies AS (SELECT bc.owner_id,
                                bc.book_copy_id,
                                loan_duration_days,
                                ft.name,
                                ft.fulfillment_type_id,
                                floor(random() * 3) + 1 as no_loans
                         FROM book_copy bc
                                  INNER JOIN book_copy_fulfillment bcf on bc.book_copy_id = bcf.book_copy_id
                                  INNER JOIN fulfillment_type ft on bcf.fulfillment_type_id = ft.fulfillment_type_id
                         ORDER BY random()
                         LIMIT 25),
     loans_to_insert AS (SELECT book_copy_id,
                                borrower.user_id,
                                rc.fulfillment_type_id,
                                CASE WHEN rc.name = 'SHIPPING' THEN user_address_id END address_id,
                                pickup_option_id,
                                loan_duration_days,
                                row_number() over (partition by book_copy_id)           row
                         FROM relevant_copies rc
                                  CROSS JOIN LATERAL (SELECT u.user_id, a.user_address_id
                                                      FROM user_account u
                                                               INNER JOIN user_address a on u.user_id = a.user_id
                                                               INNER JOIN address_type t on a.address_type_id = t.address_type_id
                                                      WHERE u.user_id <> rc.owner_id
                                                        AND t.name = rc.name
                                                      order by random()
                                                      LIMIT rc.no_loans) borrower
                                  LEFT JOIN LATERAL (SELECT pickup_option_id
                                                     from pickup_option po
                                                              INNER JOIN user_address ua on po.user_address_id = ua.user_address_id
                                                     WHERE ua.user_id = rc.owner_id
                                                       and rc.name = 'PICK_UP'
                                                     ORDER BY random()
                                                     LIMIT 1) pickup on true)

INSERT
INTO book_loan (book_copy_id, borrower_id, loan_date, return_date, status, fulfillment_type_id, user_address_id,
                pickup_option_id)
SELECT book_copy_id,
       user_id,
       current_date - row * (loan_duration_days) * INTERVAL '1 day' AS loan_date,
       current_date - row * (loan_duration_days) * INTERVAL '1 day' +
       random() * loan_duration_days * INTERVAL '1 day',
       'RETURNED',
       fulfillment_type_id,
       address_id,
       pickup_option_id
FROM loans_to_insert;