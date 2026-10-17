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
