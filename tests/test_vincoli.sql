-- =============================================================================
-- Test dei vincoli applicativi (trigger, CHECK, procedure)
-- Da eseguire DOPO install.sql:   @tests/test_vincoli.sql
-- Ogni caso verifica che l'operazione venga rifiutata con il codice d'errore
-- atteso (o che l'effetto atteso si verifichi). Al termine viene eseguito un
-- ROLLBACK: il database non viene modificato.
-- =============================================================================
SET SERVEROUTPUT ON
SET DEFINE OFF
SET SQLBLANKLINES ON

DECLARE
    v_ok     PLS_INTEGER := 0;
    v_ko     PLS_INTEGER := 0;
    v_stato  ASSEGNAZIONE.stato_assegnazione%TYPE;

    -- Esegue p_sql e controlla che fallisca con ORA-<p_codice>
    PROCEDURE attendi_errore(p_nome IN VARCHAR2, p_codice IN PLS_INTEGER, p_sql IN VARCHAR2) IS
    BEGIN
        BEGIN
            EXECUTE IMMEDIATE p_sql;
            DBMS_OUTPUT.PUT_LINE('[KO]   ' || p_nome || ' -> nessun errore');
            v_ko := v_ko + 1;
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE = p_codice THEN
                    DBMS_OUTPUT.PUT_LINE('[OK]   ' || p_nome);
                    v_ok := v_ok + 1;
                ELSE
                    DBMS_OUTPUT.PUT_LINE('[KO]   ' || p_nome || ' -> ' || SQLCODE || ' ' || SQLERRM);
                    v_ko := v_ko + 1;
                END IF;
        END;
    END;
BEGIN
    attendi_errore('Assegnazione sovrapposta per lo stesso volontario', -20001,
        'INSERT INTO ASSEGNAZIONE (id_assegnazione, id_volontario, id_progetto, id_sede, data_inizio,
            data_fine_prevista, stato_assegnazione, ore_settimanali_previste)
         VALUES (9001, 1, 1, 1, DATE ''2025-06-01'', DATE ''2025-09-30'', ''ATTIVA'', 35)');

    attendi_errore('Sede non associata al progetto', -20002,
        'INSERT INTO ASSEGNAZIONE (id_assegnazione, id_volontario, id_progetto, id_sede, data_inizio,
            data_fine_prevista, stato_assegnazione, ore_settimanali_previste)
         VALUES (9002, 2, 4, 1, DATE ''2026-01-01'', DATE ''2026-12-31'', ''ATTIVA'', 35)');

    attendi_errore('Registro su data fuori dal periodo dell''assegnazione', -20004,
        'INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata,
            ore_svolte, stato_validazione)
         VALUES (9001, 1, DATE ''2020-01-01'', ''SERVIZIO'', 6, ''DA_VALIDARE'')');

    attendi_errore('Permesso straordinario senza motivazione', -20009,
        'INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata,
            ore_svolte, stato_validazione)
         VALUES (9002, 1, DATE ''2025-07-01'', ''PERMESSO_STRAORDINARIO'', 0, ''DA_VALIDARE'')');

    attendi_errore('Piu di 8 ore giornaliere (CHECK)', -2290,
        'INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata,
            ore_svolte, stato_validazione)
         VALUES (9003, 1, DATE ''2025-07-02'', ''SERVIZIO'', 9, ''DA_VALIDARE'')');

    attendi_errore('Servizio con zero ore', -20017,
        'INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata,
            ore_svolte, stato_validazione)
         VALUES (9004, 1, DATE ''2025-07-03'', ''SERVIZIO'', 0, ''DA_VALIDARE'')');

    attendi_errore('Disattivazione progetto con assegnazioni attive', -20043,
        'BEGIN disattiva_progetto(1, ''test''); END;');

    attendi_errore('Formazione con tipologia non valida', -20111,
        'BEGIN registra_formazione(''T'', ''XXX'', ''d'', DATE ''2025-01-01'', 2, 1); END;');

    -- Decadenza automatica: assegnazione con 0 permessi ordinari consentiti
    INSERT INTO VOLONTARIO (id_volontario, nome, cognome, codice_fiscale, data_nascita, email,
                            comune_residenza, stato_volontario)
    VALUES (9001, 'Test', 'Decadenza', 'TSTDCD00A01H501X', DATE '2000-01-01', 'test@example.it',
            'Napoli', 'ATTIVO');
    INSERT INTO ASSEGNAZIONE (id_assegnazione, id_volontario, id_progetto, id_sede, data_inizio,
                              data_fine_prevista, stato_assegnazione, ore_settimanali_previste,
                              max_permessi_ordinari)
    VALUES (9003, 9001, 1, 1, DATE '2025-03-01', DATE '2025-12-31', 'ATTIVA', 35, 0);
    INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata,
                                   ore_svolte, stato_validazione)
    VALUES (9005, 9003, DATE '2025-03-10', 'PERMESSO_ORDINARIO', 0, 'DA_VALIDARE');

    SELECT stato_assegnazione INTO v_stato FROM ASSEGNAZIONE WHERE id_assegnazione = 9003;
    IF v_stato = 'DECADUTA' THEN
        DBMS_OUTPUT.PUT_LINE('[OK]   Decadenza al superamento del limite permessi');
        v_ok := v_ok + 1;
    ELSE
        DBMS_OUTPUT.PUT_LINE('[KO]   Decadenza al superamento del limite permessi -> stato ' || v_stato);
        v_ko := v_ko + 1;
    END IF;

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('---');
    DBMS_OUTPUT.PUT_LINE('Superati: ' || v_ok || '  Falliti: ' || v_ko);
END;
/
