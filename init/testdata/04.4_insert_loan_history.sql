/* Es erfolgt die Anlage beliebiger Historieneinträge für Ausleihvorgänge
   Dazu werden für alle abgeschlossenen Ausleihvorgänge fiktive Historieneinträge erzeugt. Der
   Zeitstempel für den Status 'REQUESTED' wird per random() auf eine zufällige Uhrzeit am Ausleihtag
   gesetzt, während das der Eintrag für die Rückgabe auf eine beliebige Uhrzeit am Rückgabetag festgelegt
   wird. Der Stempel für 'ON_LOAN' Status wird zufällig dazwischen gesetzt.
*/
------------------------------------------------------------------------------------------------------------------------
INSERT INTO loan_history (loan_id, loan_status, return_date, timestamp)
SELECT loan_id,
       status_name,
       CASE status_name WHEN 'RETURNED' THEN l.return_date END,
       CASE status.status_id
           WHEN 1 THEN l.loan_date + INTERVAL '1 minute' * 1440 * random()
           WHEN 2 THEN l.loan_date + INTERVAL '1 day' * random() * bc.loan_duration_days / 10
           WHEN 3 THEN l.return_date + INTERVAL '1 minute' * 1440 * random()
           END
from book_loan l
         CROSS JOIN (select status_id,
                            CASE status_id
                                WHEN 1 THEN 'REQUESTED'
                                WHEN 2 THEN 'ON_LOAN'
                                WHEN 3 THEN
                                    'RETURNED' END
                                status_name
                     from generate_series
                          (1, 3) status_id) status
         INNER JOIN book_copy bc on l.book_copy_id = bc.book_copy_id
WHERE l.status = 'RETURNED'
order by loan_id, status.status_id
SELECT *
from loan_history