-- =============================================================================
-- Test di sicurezza: va eseguito CONNESSI COME UTENTE DI TEST (non come proprietario)
-- Uso:  @tests/test_sicurezza.sql <scenario> <id_volontario_proprio> <id_altro_volontario>
--   scenari: VOLONTARIO | OPERATORE | NON_REGISTRATO
-- Lo orchestra scripts/run-tests.sh, che crea gli utenti e la mappatura UTENTE_APPLICATIVO.
-- =============================================================================
SET DEFINE ON
SET VERIFY OFF
SET SERVEROUTPUT ON
ALTER SESSION SET CURRENT_SCHEMA = sc;

DECLARE
    v_ok  PLS_INTEGER := 0;
    v_ko  PLS_INTEGER := 0;
    v_n   NUMBER;

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

    FUNCTION conta(p_sql IN VARCHAR2) RETURN NUMBER IS
        v NUMBER;
    BEGIN
        EXECUTE IMMEDIATE p_sql INTO v;
        RETURN v;
    END;

    -- L'accesso deve fallire con il codice atteso (ORA-00942: nessun privilegio sull'oggetto)
    PROCEDURE attendi_errore(p_nome IN VARCHAR2, p_codice IN PLS_INTEGER, p_sql IN VARCHAR2) IS
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
BEGIN
    DBMS_OUTPUT.PUT_LINE('Scenario &1 (utente ' || SYS_CONTEXT('USERENV', 'SESSION_USER') || ')');

    IF '&1' = 'VOLONTARIO' THEN
        -- Nessun accesso diretto alle tabelle con dati di persone
        attendi_errore('Nessun accesso diretto a ASSEGNAZIONE', -942, 'SELECT COUNT(*) FROM assegnazione');
        attendi_errore('Nessun accesso a VOLONTARIO', -942, 'SELECT COUNT(*) FROM volontario');
        attendi_errore('Nessun accesso a REGISTRO_SERVIZIO', -942, 'SELECT COUNT(*) FROM registro_servizio');
        attendi_errore('Nessuna scrittura diretta sul registro', -942,
            q'[INSERT INTO registro_servizio (id_registro, id_assegnazione, data_servizio, tipo_giornata,
                   ore_svolte, stato_validazione)
               VALUES (9990, 1, DATE '2025-08-01', 'SERVIZIO', 6, 'VALIDATA')]');
        attendi_errore('Nessun accesso all''anagrafica mascherata', -942,
            'SELECT COUNT(*) FROM v_volontari_mascherati');
        attendi_errore('Nessun accesso alla mappatura utenti', -942,
            'SELECT COUNT(*) FROM utente_applicativo');

        -- Le viste personali mostrano soltanto i propri dati
        v_n := conta('SELECT COUNT(*) FROM v_mie_assegnazioni');
        esito('Vede le proprie assegnazioni', v_n > 0);
        esito('Non vede assegnazioni altrui',
            conta('SELECT COUNT(*) FROM v_mie_assegnazioni WHERE id_volontario <> &2') = 0);
        esito('Il registro mostra solo le proprie giornate',
            conta('SELECT COUNT(*) FROM v_mio_registro
                    WHERE id_assegnazione NOT IN (SELECT id_assegnazione FROM v_mie_assegnazioni)') = 0);
        esito('Vede le proprie giornate di registro', conta('SELECT COUNT(*) FROM v_mio_registro') > 0);
        v_n := conta('SELECT COUNT(*) FROM v_miei_monitoraggi')
             + conta('SELECT COUNT(*) FROM v_mie_richieste_variazione')
             + conta('SELECT COUNT(*) FROM v_mie_partecipazioni_formazione');
        esito('Le altre viste personali sono interrogabili', v_n >= 0);

        -- Registrazione presenze: solo per sé
        EXECUTE IMMEDIATE 'BEGIN inserisci_presenza(&2, DATE ''2025-08-01'', ''SERVIZIO'', 6, 0); END;';
        esito('Registra una propria presenza',
            conta('SELECT COUNT(*) FROM v_mio_registro WHERE data_servizio = DATE ''2025-08-01''') = 1);
        attendi_errore('Non puo'' registrare la presenza di un altro volontario', -20148,
            'BEGIN inserisci_presenza(&3, DATE ''2025-08-02'', ''SERVIZIO'', 6, 0); END;');

    ELSIF '&1' = 'OPERATORE' THEN
        attendi_errore('Nessun accesso all''anagrafica in chiaro', -942, 'SELECT COUNT(*) FROM volontario');
        attendi_errore('Nessun accesso a OPERATORE', -942, 'SELECT COUNT(*) FROM operatore');
        attendi_errore('Nessun accesso alla mappatura utenti', -942,
            'SELECT COUNT(*) FROM utente_applicativo');
        attendi_errore('Nessuna scrittura sull''anagrafica', -942,
            q'[UPDATE volontario SET email = 'x@example.it']');
        attendi_errore('Nessuna vista personale del volontario', -942,
            'SELECT COUNT(*) FROM v_mie_assegnazioni');

        v_n := conta('SELECT COUNT(*) FROM v_volontari_mascherati');
        esito('Vede l''anagrafica mascherata', v_n > 0);
        esito('Codice fiscale mascherato',
            conta(q'[SELECT COUNT(*) FROM v_volontari_mascherati WHERE codice_fiscale NOT LIKE '___**********___']') = 0);
        esito('E-mail mascherata',
            conta(q'[SELECT COUNT(*) FROM v_volontari_mascherati WHERE email NOT LIKE '_***@%']') = 0);
        esito('Telefono mascherato',
            conta(q'[SELECT COUNT(*) FROM v_volontari_mascherati WHERE telefono IS NOT NULL AND telefono NOT LIKE '*%']') = 0);
        -- L'operatore non ha nemmeno EXECUTE sulla procedura (PLS-00201 via ORA-06550)
        attendi_errore('Un operatore non puo'' registrare presenze (nessun EXECUTE)', -6550,
            'BEGIN inserisci_presenza(&2, DATE ''2025-08-01'', ''SERVIZIO'', 6, 0); END;');

    ELSIF '&1' = 'NON_REGISTRATO' THEN
        esito('Senza mappatura le viste personali sono vuote',
            conta('SELECT COUNT(*) FROM v_mie_assegnazioni') = 0
            AND conta('SELECT COUNT(*) FROM v_mio_registro') = 0);
        attendi_errore('Un utente non registrato non puo'' registrare presenze', -20149,
            'BEGIN inserisci_presenza(&2, DATE ''2025-08-01'', ''SERVIZIO'', 6, 0); END;');
    END IF;

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('---');
    DBMS_OUTPUT.PUT_LINE('Superati: ' || v_ok || '  Falliti: ' || v_ko);
END;
/
EXIT
