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
    v_n      PLS_INTEGER;
    v_idf    FORMAZIONE.id_formazione%TYPE;

    PROCEDURE esito(p_nome IN VARCHAR2, p_condizione IN BOOLEAN) IS
    BEGIN
        IF p_condizione THEN
            DBMS_OUTPUT.PUT_LINE('[OK]   ' || p_nome);
            v_ok := v_ok + 1;
        ELSE
            DBMS_OUTPUT.PUT_LINE('[KO]   ' || p_nome);
            v_ko := v_ko + 1;
        END IF;
    END;

    -- Esegue p_sql e controlla che fallisca con il codice atteso
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

    attendi_errore('Monitoraggio fuori dal periodo dell''assegnazione', -20016,
        'INSERT INTO MONITORAGGIO (id_monitoraggio, id_assegnazione, data_monitoraggio, tipo_monitoraggio)
         VALUES (9001, 1, DATE ''2020-01-01'', ''INTERMEDIO'')');

    attendi_errore('Procedura: monitoraggio prima dell''inizio assegnazione', -20132,
        'BEGIN registra_monitoraggio(1, DATE ''2020-01-01'', ''INTERMEDIO'', ''POSITIVO''); END;');

    attendi_errore('Approvazione variazione senza nuova assegnazione', -20003,
        'DECLARE BEGIN
            INSERT INTO RICHIESTA_VARIAZIONE (id_richiesta, id_assegnazione, data_richiesta,
                tipo_variazione, motivazione, stato_richiesta)
            VALUES (9001, 1, DATE ''2025-06-01'', ''CAMBIO_SEDE'', ''test'', ''IN_ATTESA'');
            UPDATE RICHIESTA_VARIAZIONE SET stato_richiesta = ''APPROVATA'' WHERE id_richiesta = 9001;
         END;');

    -- Casi di successo (le procedure non fanno COMMIT: tutto viene annullato dal ROLLBACK finale)
    registra_formazione('Test sicurezza', 'GENERALE', 'Formazione di test', DATE '2025-03-01', 4, 1);
    SELECT seq_formazione.CURRVAL INTO v_idf FROM DUAL;
    SELECT COUNT(*) INTO v_n FROM FORMAZIONE WHERE id_formazione = v_idf AND tipologia = 'GENERALE';
    esito('Procedura registra_formazione inserisce la formazione', v_n = 1);

    attendi_errore('Partecipazione ASSENTE con ore frequentate', -20126,
        'BEGIN registra_partecipazione_formazione(1, ' || v_idf || ', ''ASSENTE'', 2); END;');

    registra_partecipazione_formazione(1, v_idf, 'PRESENTE', 4);
    SELECT COUNT(*) INTO v_n FROM ASSEGNAZIONE_FORMAZIONE WHERE id_assegnazione = 1 AND id_formazione = v_idf;
    esito('Procedura registra_partecipazione_formazione inserisce la partecipazione', v_n = 1);

    attendi_errore('Partecipazione gia registrata', -20123,
        'BEGIN registra_partecipazione_formazione(1, ' || v_idf || ', ''PRESENTE'', 4); END;');

    registra_monitoraggio(1, DATE '2025-06-01', 'INTERMEDIO', 'POSITIVO', 'ok');
    SELECT COUNT(*) INTO v_n FROM MONITORAGGIO WHERE id_assegnazione = 1 AND data_monitoraggio = DATE '2025-06-01';
    esito('Procedura registra_monitoraggio inserisce il monitoraggio', v_n = 1);

    INSERT INTO PROGETTO (id_progetto, id_ente, titolo, area_intervento, descrizione, data_inizio, stato_progetto)
    VALUES (9001, 1, 'Progetto test', 'ASSISTENZA', 'test', DATE '2025-01-01', 'ATTIVO');
    disattiva_progetto(9001, 'test');
    SELECT COUNT(*) INTO v_n FROM PROGETTO WHERE id_progetto = 9001 AND stato_progetto = 'SOSPESO';
    esito('Procedura disattiva_progetto sospende un progetto senza assegnazioni', v_n = 1);

    -- Storico: una giornata nel periodo di un'assegnazione conclusa e' ammessa
    INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata,
                                   ore_svolte, stato_validazione)
    VALUES (9006, 3, DATE '2025-03-03', 'SERVIZIO', 6, 'VALIDATA');
    esito('Giornata nel periodo di un''assegnazione conclusa (storico)', TRUE);

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
