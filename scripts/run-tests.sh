#!/usr/bin/env bash
# Installa il database in un container Oracle e lancia i test.
# Uso: scripts/run-tests.sh [nome-container]   (default: oracle-servizio-civile)
# Prerequisito: container avviato con `docker compose up -d --wait`.
set -euo pipefail

C="${1:-oracle-servizio-civile}"
CONN="sc/LocalDevOnly1@//localhost/FREEPDB1"
cd "$(dirname "$0")/.."

# Il tablespace/utente di default non ha tutti i privilegi necessari
docker exec "$C" bash -c "echo 'GRANT CREATE ROLE, CREATE VIEW, CREATE TRIGGER, CREATE PROCEDURE, CREATE SEQUENCE, CREATE TABLE TO sc;' | sqlplus -s system/LocalDevOnly1@//localhost/FREEPDB1" >/dev/null

DIR="/tmp/sc_$$"
docker exec -u root "$C" mkdir -p "$DIR"
tar cf - sql tests install.sql uninstall.sql 2>/dev/null | docker exec -i -u root "$C" tar xf - -C "$DIR" 2>/dev/null
docker exec -u root "$C" chmod -R a+rX "$DIR"

run() { docker exec "$C" bash -c "cd $DIR && sqlplus -s $CONN @$1"; }

run uninstall.sql >/dev/null
run install.sql | tee /tmp/sc_install.log
if grep -Eq "^(ORA|SP2|PLS)-|Warning:" /tmp/sc_install.log; then echo "Installazione con errori"; exit 1; fi

run tests/test_vincoli.sql | tee /tmp/sc_tests.log
grep -q "Falliti: 0" /tmp/sc_tests.log

# Test di sicurezza: utenti reali con ruoli e mappatura, connessi singolarmente
SYS_CONN="system/LocalDevOnly1@//localhost/FREEPDB1"
sql_as() { docker exec -i "$C" sqlplus -s "$1@//localhost/FREEPDB1"; }

echo "== Test di sicurezza =="
sql_as system/LocalDevOnly1 >/dev/null <<'SQL'
BEGIN
    FOR u IN (SELECT username FROM dba_users WHERE username LIKE 'TEST\_%' ESCAPE '\') LOOP
        EXECUTE IMMEDIATE 'DROP USER ' || u.username || ' CASCADE';
    END LOOP;
END;
/
CREATE USER test_vol1 IDENTIFIED BY LocalDevOnly1;
CREATE USER test_vol2 IDENTIFIED BY LocalDevOnly1;
CREATE USER test_ope IDENTIFIED BY LocalDevOnly1;
CREATE USER test_anon IDENTIFIED BY LocalDevOnly1;
GRANT CREATE SESSION TO test_vol1, test_vol2, test_ope, test_anon;
GRANT ruolo_volontario TO test_vol1, test_vol2, test_anon;
GRANT ruolo_operatore TO test_ope;
EXIT
SQL
sql_as sc/LocalDevOnly1 >/dev/null <<'SQL'
INSERT INTO UTENTE_APPLICATIVO (username, tipo_utente, id_volontario) VALUES ('TEST_VOL1', 'VOLONTARIO', 1);
INSERT INTO UTENTE_APPLICATIVO (username, tipo_utente, id_volontario) VALUES ('TEST_VOL2', 'VOLONTARIO', 2);
INSERT INTO UTENTE_APPLICATIVO (username, tipo_utente, id_operatore) VALUES ('TEST_OPE', 'OPERATORE', 1);
COMMIT;
EXIT
SQL

sicurezza() { # utente scenario id_proprio id_altro
    docker exec "$C" bash -c "cd $DIR && sqlplus -s $1/LocalDevOnly1@//localhost/FREEPDB1 @tests/test_sicurezza.sql $2 $3 $4" | tee -a /tmp/sc_sicurezza.log
}
: > /tmp/sc_sicurezza.log
sicurezza TEST_VOL1 VOLONTARIO 1 2
sicurezza TEST_VOL2 VOLONTARIO 2 1
sicurezza TEST_OPE OPERATORE 1 2
sicurezza TEST_ANON NON_REGISTRATO 1 2
if grep -q "\[KO\]" /tmp/sc_sicurezza.log || [ "$(grep -c 'Falliti: 0' /tmp/sc_sicurezza.log)" != "4" ]; then
    echo "Test di sicurezza falliti"; exit 1
fi

sql_as system/LocalDevOnly1 >/dev/null <<'SQL'
BEGIN
    FOR u IN (SELECT username FROM dba_users WHERE username LIKE 'TEST\_%' ESCAPE '\') LOOP
        EXECUTE IMMEDIATE 'DROP USER ' || u.username || ' CASCADE';
    END LOOP;
END;
/
EXIT
SQL

# Disinstallazione: lo schema deve restare vuoto, i ruoli devono sparire
run uninstall.sql >/dev/null
RESIDUI=$(run tests/verifica_schema_vuoto.sql | tee /tmp/sc_vuoto.log)
echo "$RESIDUI"
grep -q "Oggetti residui: 0" /tmp/sc_vuoto.log

RUOLI=$(docker exec "$C" bash -c "echo \"SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT COUNT(*) FROM dba_roles WHERE role LIKE 'RUOLO\\_%' ESCAPE '\\\\';\" | sqlplus -s system/LocalDevOnly1@//localhost/FREEPDB1" | tr -d '[:space:]')
echo "Ruoli residui: $RUOLI"
[ "$RUOLI" = "0" ]

# Reinstallazione dopo la disinstallazione
run install.sql | tee /tmp/sc_reinstall.log
if grep -Eq "^(ORA|SP2|PLS)-|Warning:" /tmp/sc_reinstall.log; then echo "Reinstallazione con errori"; exit 1; fi
grep -q "Installazione completata" /tmp/sc_reinstall.log
echo "Disinstallazione e reinstallazione verificate."
