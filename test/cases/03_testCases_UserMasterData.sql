-- 03.1 User-Accounts
---------------------------
-- 03.1.1 Anlage eines neuen User-Accounts
CALL getOrCreateUserAccount('Dr. Max Meier', 'max.meier@abc.de', '+49 1515 668899');
-- 03.1.2 Aktualisierung eines bestehenden User-Accounts
CALL updateUserAccount('Dr. Max Müller', 'max.meier@abc.de', 'max.mueller@web.de', NULL, NULL);
-- 03.1.3 Aktualisierung eines nicht vorhandenen Users-Accounts
CALL updateUserAccount('Christian Steffen', 'c.steffen@gmail.com', NULL, NULL, 'BLOCKED');
-- 03.1.4 CHECK CONSTRAINT VIOLATION: Anlage eines Users mit ungültiger E-Mailadresse
CALL getOrCreateUserAccount('Karla Karstens', 'k.karstens@#23w.de', NULL, NULL);
-- 03.1.5 CHECK CONSTRAINT VIOLATION: Aktualisierung eines Users mit falschem Status
CALL updateUserAccount(NULL, 'c.steffen@gmail.com', NULL, NULL, 'SUSPENDED', NULL);

-- 03.2 Benutzeradressen
---------------------------
-- 03.2.1 Anlage einer neuen Benutzeradresse
CALL createUserAddress(getUserByEMail('c.steffen@gmail.com'),
                       getAddress('Alexanderplatz', '1', '10178', 'Berlin', 'DE'),
                       'SHIPPING', NULL);
-- 03.2.2 UNIQUE CONSTRAINT VIOLATION: Anlage einer Benutzeradresse vom gleichen Typ
CALL createUserAddress(getUserByEMail('c.steffen@gmail.com'),
                       getAddress('Alexanderplatz', '1', '10178', 'Berlin', 'DE'),
                       'SHIPPING', NULL);
-- 03.2.3 Anlage einer Benutzeradresse enes anderen Typs
CALL createUserAddress(getUserByEMail('c.steffen@gmail.com'),
                       getAddress('Alexanderplatz', '1', '10178', 'Berlin', 'DE'),
                       'PICK_UP', NULL);

-- 03.3 Rollenmanagement
---------------------------
-- 03.3.1 Anlegen einer Rolle
INSERT INTO role (name)
VALUES ('New role');
-- 03.3.2 EXCEPTION: Löschen einer Rolle als User
SELECT deleterole('New role', getuserbyemail('max.meier@web.de'));
-- 03.3.3 Löschen einer Rolle als Admin
SELECT deleterole('New role', findadminuser());
-- 03.3.3 Löschen einer Rolle als Admin; Erfolgreich, da Zuordnung user_role kaskadierend mitgelöscht wird
SELECT deleterole('MISC', findadminuser());