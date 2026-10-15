-- =============================================================================
-- Installazione completa del database Servizio Civile
-- Uso (da SQL*Plus / SQLcl, nella cartella del repository):
--   @install.sql
-- Requisiti: Oracle 12c+ (testato su sintassi Oracle XE), utente con privilegi
-- CREATE TABLE / SEQUENCE / VIEW / TRIGGER / PROCEDURE / ROLE.
-- =============================================================================
SET DEFINE OFF
SET SQLBLANKLINES ON
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

PROMPT == Schema ==
@sql/01_schema/01_tables.sql
@sql/01_schema/02_indexes.sql

PROMPT == Dati di esempio (caricati prima dei trigger) ==
@sql/02_seed/01_ente.sql
@sql/02_seed/02_sede.sql
@sql/02_seed/03_progetto.sql
@sql/02_seed/04_operatore.sql
@sql/02_seed/05_volontario.sql
@sql/02_seed/06_progetto_sede.sql
@sql/02_seed/07_formazione.sql
@sql/02_seed/08_assegnazione.sql
@sql/02_seed/09_assegnazione_formazione.sql
@sql/02_seed/10_registro_servizio.sql
@sql/02_seed/11_monitoraggio.sql
@sql/02_seed/12_richiesta_variazione.sql
COMMIT;

PROMPT == Procedure, trigger, viste ==
@sql/03_procedures/01_procedures.sql
@sql/04_triggers/01_triggers.sql
@sql/05_views/01_presenze_da_validare.sql

PROMPT == Sicurezza ==
@sql/06_security/01_security.sql

PROMPT Installazione completata.
