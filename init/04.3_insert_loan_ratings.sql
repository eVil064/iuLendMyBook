/* Es erfolgt die Anlage beliebiger Bewertungen für Ausleihvorgänge
   Dazu werden über random() Ausleihvorgänge in zufälliger Reihenfolge abgefragt und die ersten 25 Ausleihvorgänge an den
   INSERT-Befehl übergeben. Der Score jeder Bewertung wird ebenfalls per random() ermittelt. Durch die Multiplikation
   mit 5 und die Kombination mit floor() (abrunden auf eine Ganzzahl) werden so Zahlenwerte zwischen 0 und 4 ermittelt.
   Durch Addition von 1 wird sichergestellt, dass der zulässige Wertebereich von 1-5 eingehalten wird.
*/
------------------------------------------------------------------------------------------------------------------------
INSERT INTO loan_rating (loan_id, rating_score, comment)
SELECT loan_id, floor(random() * 5) + 1, null
from book_loan l
order by loan_id * random()
LIMIT 25;
