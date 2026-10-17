-- =============================================================================
-- Rimozione di tutti gli oggetti creati da install.sql
-- Gli errori "oggetto inesistente" vengono ignorati, quindi lo script e'
-- rieseguibile.
-- =============================================================================
SET SERVEROUTPUT ON

BEGIN
    FOR o IN (
        SELECT 'DROP ' || t || ' ' || n AS stmt FROM (
            SELECT 'ROLE' t, 'ruolo_amministratore' n FROM DUAL UNION ALL
            SELECT 'ROLE', 'ruolo_operatore' FROM DUAL UNION ALL
            SELECT 'ROLE', 'ruolo_volontario' FROM DUAL UNION ALL
            SELECT 'VIEW', 'Presenze_Da_Validare' FROM DUAL UNION ALL
            SELECT 'VIEW', 'v_volontari_mascherati' FROM DUAL UNION ALL
            SELECT 'VIEW', 'v_mie_assegnazioni' FROM DUAL UNION ALL
            SELECT 'VIEW', 'v_mio_registro' FROM DUAL UNION ALL
            SELECT 'VIEW', 'v_mie_partecipazioni_formazione' FROM DUAL UNION ALL
            SELECT 'VIEW', 'v_miei_monitoraggi' FROM DUAL UNION ALL
            SELECT 'VIEW', 'v_mie_richieste_variazione' FROM DUAL UNION ALL
            SELECT 'PROCEDURE', 'disattiva_progetto' FROM DUAL UNION ALL
            SELECT 'PROCEDURE', 'registra_formazione' FROM DUAL UNION ALL
            SELECT 'PROCEDURE', 'registra_partecipazione_formazione' FROM DUAL UNION ALL
            SELECT 'PROCEDURE', 'registra_monitoraggio' FROM DUAL UNION ALL
            SELECT 'SEQUENCE', 'seq_formazione' FROM DUAL UNION ALL
            SELECT 'SEQUENCE', 'seq_monitoraggio' FROM DUAL UNION ALL
            SELECT 'SEQUENCE', 'seq_progetto' FROM DUAL UNION ALL
            SELECT 'SEQUENCE', 'seq_assegnazione' FROM DUAL UNION ALL
            SELECT 'SEQUENCE', 'seq_registro' FROM DUAL UNION ALL
            SELECT 'SEQUENCE', 'seq_audit' FROM DUAL UNION ALL
            SELECT 'FUNCTION', 'parse_lista_sedi' FROM DUAL UNION ALL
            SELECT 'PROCEDURE', 'crea_progetto' FROM DUAL UNION ALL
            SELECT 'PROCEDURE', 'modifica_progetto' FROM DUAL UNION ALL
            SELECT 'PROCEDURE', 'crea_assegnazione' FROM DUAL UNION ALL
            SELECT 'PROCEDURE', 'gestisci_richiesta_variazione' FROM DUAL UNION ALL
            SELECT 'PROCEDURE', 'inserisci_presenza' FROM DUAL UNION ALL
            SELECT 'PROCEDURE', 'valida_presenza' FROM DUAL
        )
    ) LOOP
        BEGIN EXECUTE IMMEDIATE o.stmt; EXCEPTION WHEN OTHERS THEN NULL; END;
    END LOOP;

    -- Tabelle in ordine inverso di dipendenza (i trigger cadono con le tabelle)
    FOR t IN (
        SELECT column_value AS n FROM TABLE(SYS.ODCIVARCHAR2LIST(
            'AUDIT_LOG', 'UTENTE_APPLICATIVO', 'RICHIESTA_VARIAZIONE', 'MONITORAGGIO', 'REGISTRO_SERVIZIO',
            'ASSEGNAZIONE_FORMAZIONE', 'FORMAZIONE', 'ASSEGNAZIONE', 'VOLONTARIO',
            'PROGETTO_SEDE', 'PROGETTO', 'OPERATORE', 'SEDE', 'ENTE'))
    ) LOOP
        BEGIN EXECUTE IMMEDIATE 'DROP TABLE ' || t.n || ' CASCADE CONSTRAINTS PURGE';
        EXCEPTION WHEN OTHERS THEN NULL; END;
    END LOOP;
END;
/

PROMPT Disinstallazione completata.
