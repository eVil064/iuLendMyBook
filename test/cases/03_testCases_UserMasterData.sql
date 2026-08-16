-- 03.1 User-Accounts
---------------------------
-- 03.1.1 Anlage eines neuen User-Accounts
CALL getOrCreateUserAccount('Dr. Max Meier', 'max.meier@abc.de', '+49 1515 668899', NULL);
-- 03.1.2 Aktualisierung eines bestehenden User-Accounts
CALL updateUserAccount('Dr. Max Müller', 'max.meier@abc.de', 'max.mueller@web.de', NULL, NULL, NULL);
-- 03.1.3 Aktualisierung eines nicht vorhandenen Users-Accounts
CALL updateUserAccount('Christian Steffen', 'c.steffen@gmail.com', NULL, NULL, 'BLOCKED', NULL);
-- 03.1.4 Anlage eines Users mit ungültiger E-Mailadresse
CALL getOrCreateUserAccount('Karla Karstens', 'k.karstens@#23w.de', NULL, NULL);
-- 03.1.5 Aktualisierung eines Users mit falschem Status
CALL updateUserAccount(NULL, 'c.steffen@gmail.com', NULL, NULL, 'SUSPENDED', NULL);

-- 03.2 Benutzeradressen
---------------------------
-- 03.2.1 Anlage einer neuen Benutzeradresse
CALL createUserAddress(getUserByEMail('c.steffen@gmail.com'),
                       getAddress('Alexanderplatz', '1', '10178', 'Berlin', 'DE'),
                       'SHIPPING', NULL);
-- 03.2.2 Anlage einer Benutzeradresse vom gleichen Typ
CALL createUserAddress(getUserByEMail('c.steffen@gmail.com'),
                       getAddress('Alexanderplatz', '1', '10178', 'Berlin', 'DE'),
                       'SHIPPING', NULL);
-- 03.2.3 Anlage einer Benutzeradresse enes anderen Typs
CALL createUserAddress(getUserByEMail('c.steffen@gmail.com'),
                       getAddress('Alexanderplatz', '1', '10178', 'Berlin', 'DE'),
                       'PICK_UP', NULL);
-- 03.2.4 Löschen eines Benutzers (löscht auch Benutzer-Adress-Zuordnung, ohne Fehler)
SELECT deleteUserAccountAndCheckAddresses('c.steffen@gmail.com');



