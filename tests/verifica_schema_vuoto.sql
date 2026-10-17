-- =============================================================================
-- Verifica che lo schema non contenga oggetti residui (da lanciare dopo uninstall.sql)
-- Stampa: "Oggetti residui: N" (atteso 0)
-- =============================================================================
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT 'Oggetti residui: ' || COUNT(*) FROM user_objects;
SELECT object_type || ' ' || object_name FROM user_objects;
EXIT
