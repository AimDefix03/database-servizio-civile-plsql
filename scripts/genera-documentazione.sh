#!/usr/bin/env bash
# Genera docs/dizionario_dati.md e docs/diagramma_er.md dal catalogo del database installato.
# Uso: scripts/genera-documentazione.sh [nome-container]   (default: oracle-servizio-civile)
# Prerequisiti: container avviato e database installato (install.sql).
set -euo pipefail

C="${1:-oracle-servizio-civile}"
cd "$(dirname "$0")/.."

estrai() {
    docker exec -i "$C" sqlplus -s sc/LocalDevOnly1@//localhost/FREEPDB1 <<'SQL'
SET PAGESIZE 0 LINESIZE 4000 TRIMSPOOL ON FEEDBACK OFF HEADING OFF LONG 4000 VERIFY OFF
PROMPT ##TABELLE
SELECT t.table_name || '|' || NVL(c.comments, '')
FROM user_tables t
LEFT JOIN user_tab_comments c ON c.table_name = t.table_name
ORDER BY t.table_name;
PROMPT ##COLONNE
SELECT c.table_name || '|' || c.column_name || '|'
       || CASE
            WHEN c.data_type = 'VARCHAR2' THEN 'VARCHAR2(' || c.char_length || ')'
            WHEN c.data_type = 'NUMBER' AND c.data_precision IS NOT NULL
                THEN 'NUMBER(' || c.data_precision || ',' || NVL(c.data_scale, 0) || ')'
            WHEN c.data_type LIKE 'TIMESTAMP%' THEN 'TIMESTAMP'
            ELSE c.data_type
          END || '|' || c.nullable || '|' || NVL(cc.comments, '')
FROM user_tab_columns c
INNER JOIN user_tables t ON t.table_name = c.table_name
LEFT JOIN user_col_comments cc ON cc.table_name = c.table_name AND cc.column_name = c.column_name
ORDER BY c.table_name, c.column_id;
PROMPT ##VINCOLI
SELECT k.table_name || '|' || k.constraint_type || '|' || k.constraint_name || '|'
       || (SELECT LISTAGG(cc.column_name, ',') WITHIN GROUP (ORDER BY cc.position)
           FROM user_cons_columns cc WHERE cc.constraint_name = k.constraint_name) || '|'
       || NVL((SELECT r.table_name || '(' || LISTAGG(rc.column_name, ',') WITHIN GROUP (ORDER BY rc.position) || ')'
               FROM user_constraints r
               INNER JOIN user_cons_columns rc ON rc.constraint_name = r.constraint_name
               WHERE r.constraint_name = k.r_constraint_name
               GROUP BY r.table_name), '') || '|'
       || REPLACE(REPLACE(NVL(k.search_condition_vc, ''), CHR(10), ' '), CHR(13), ' ')
FROM user_constraints k
INNER JOIN user_tables t ON t.table_name = k.table_name
WHERE k.constraint_type IN ('P', 'U', 'R')
   OR (k.constraint_type = 'C' AND k.constraint_name NOT LIKE 'SYS\_C%' ESCAPE '\')
ORDER BY k.table_name, k.constraint_type, k.constraint_name;
EXIT
SQL
}

estrai | python3 scripts/genera_documentazione.py
