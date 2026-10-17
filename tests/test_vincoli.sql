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
    v_idp    PROGETTO.id_progetto%TYPE;
    v_ida    ASSEGNAZIONE.id_assegnazione%TYPE;

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

    -- Esegue p_sql e controlla che riesca
    PROCEDURE attendi_ok(p_nome IN VARCHAR2, p_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
        DBMS_OUTPUT.PUT_LINE('[OK]   ' || p_nome);
        v_ok := v_ok + 1;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('[KO]   ' || p_nome || ' -> ' || SQLCODE || ' ' || SQLERRM);
            v_ko := v_ko + 1;
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

    -- ---- crea_progetto / modifica_progetto -----------------------------------
    crea_progetto(1, 'Progetto test', 'ASSISTENZA', 'test', DATE '2026-01-01', NULL, 'ATTIVO', '1,2', 3);
    SELECT seq_progetto.CURRVAL INTO v_idp FROM DUAL;
    SELECT COUNT(*) INTO v_n FROM PROGETTO_SEDE WHERE id_progetto = v_idp AND posti_disponibili = 3;
    esito('crea_progetto crea il progetto con le sue due sedi', v_n = 2);

    attendi_errore('crea_progetto: sede duplicata nella lista', -20151,
        q'[BEGIN crea_progetto(1,'T','ASSISTENZA','d',DATE '2026-01-01',NULL,'ATTIVO','1,1',3); END;]');
    attendi_errore('crea_progetto: sede di un altro ente', -20153,
        q'[BEGIN crea_progetto(1,'T','ASSISTENZA','d',DATE '2026-01-01',NULL,'ATTIVO','4',3); END;]');
    attendi_errore('crea_progetto: stato non valido', -20158,
        q'[BEGIN crea_progetto(1,'T','ASSISTENZA','d',DATE '2026-01-01',NULL,'XXX','1',3); END;]');
    attendi_errore('crea_progetto: ente inesistente', -20159,
        q'[BEGIN crea_progetto(9999,'T','ASSISTENZA','d',DATE '2026-01-01',NULL,'ATTIVO','1',3); END;]');

    modifica_progetto(v_idp, 'Progetto test 2', 'ASSISTENZA', 'test', DATE '2026-01-01', NULL, 'ATTIVO', '2', 5);
    SELECT COUNT(*) INTO v_n FROM PROGETTO_SEDE WHERE id_progetto = v_idp AND id_sede = 2 AND posti_disponibili = 5;
    esito('modifica_progetto aggiorna le sedi del progetto', v_n = 1);

    attendi_errore('modifica_progetto: rimozione di una sede gia'' usata', -20025,
        q'[BEGIN modifica_progetto(1,'T','ASSISTENZA','d',DATE '2025-01-10',NULL,'ATTIVO','2',3); END;]');

    -- ---- crea_assegnazione ---------------------------------------------------
    INSERT INTO VOLONTARIO (id_volontario, nome, cognome, codice_fiscale, data_nascita, email,
                            comune_residenza, stato_volontario)
    VALUES (9002, 'Test', 'Procedure', 'TSTPRC00A01H501Y', DATE '2000-01-01', 'test2@example.it',
            'Napoli', 'ATTIVO');

    attendi_errore('crea_assegnazione: sovrapposizione con assegnazione attiva', -20060,
        q'[BEGIN crea_assegnazione(1,1,1,DATE '2025-06-01',DATE '2025-09-30','ATTIVA',35,15,10,10); END;]');
    attendi_errore('crea_assegnazione: sede non associata al progetto', -20059,
        q'[BEGIN crea_assegnazione(9002,4,1,DATE '2026-01-01',DATE '2026-12-31','ATTIVA',35,15,10,10); END;]');
    attendi_errore('crea_assegnazione: stato diverso da ATTIVA', -20054,
        q'[BEGIN crea_assegnazione(9002,1,1,DATE '2026-01-01',DATE '2026-12-31','CONCLUSA',35,15,10,10); END;]');

    crea_progetto(1, 'Progetto sospeso', 'ASSISTENZA', 'test', DATE '2026-01-01', NULL, 'SOSPESO', '1', 2);
    SELECT seq_progetto.CURRVAL INTO v_idp FROM DUAL;
    attendi_errore('crea_assegnazione: progetto sospeso', -20057,
        'BEGIN crea_assegnazione(9002,' || v_idp || q'[,1,DATE '2026-01-01',DATE '2026-12-31','ATTIVA',35,15,10,10); END;]');

    crea_progetto(1, 'Progetto senza posti', 'ASSISTENZA', 'test', DATE '2026-01-01', NULL, 'ATTIVO', '1', 0);
    SELECT seq_progetto.CURRVAL INTO v_idp FROM DUAL;
    attendi_errore('crea_assegnazione: posti esauriti', -20066,
        'BEGIN crea_assegnazione(9002,' || v_idp || q'[,1,DATE '2026-01-01',DATE '2026-12-31','ATTIVA',35,15,10,10); END;]');

    crea_assegnazione(9002, 1, 1, DATE '2026-01-01', DATE '2026-12-31', 'ATTIVA', 35, 15, 10, 10);
    SELECT seq_assegnazione.CURRVAL INTO v_ida FROM DUAL;
    SELECT COUNT(*) INTO v_n FROM ASSEGNAZIONE
     WHERE id_assegnazione = v_ida AND stato_assegnazione = 'ATTIVA' AND data_fine_effettiva IS NULL;
    esito('crea_assegnazione crea un''assegnazione attiva', v_n = 1);

    -- ---- gestisci_richiesta_variazione ---------------------------------------
    INSERT INTO RICHIESTA_VARIAZIONE (id_richiesta, id_assegnazione, data_richiesta, tipo_variazione,
                                      motivazione, stato_richiesta)
    VALUES (9101, v_ida, DATE '2026-05-01', 'CAMBIO_SEDE', 'test', 'IN_ATTESA');
    INSERT INTO RICHIESTA_VARIAZIONE (id_richiesta, id_assegnazione, data_richiesta, tipo_variazione,
                                      motivazione, stato_richiesta)
    VALUES (9102, v_ida, DATE '2026-05-01', 'CAMBIO_PROGETTO', 'test', 'IN_ATTESA');

    attendi_errore('gestisci_richiesta: stato finale non valido', -20071,
        q'[BEGIN gestisci_richiesta_variazione(9101,'FORSE',DATE '2026-05-15'); END;]');
    attendi_errore('gestisci_richiesta: approvazione senza nuova sede', -20074,
        q'[BEGIN gestisci_richiesta_variazione(9101,'APPROVATA',DATE '2026-05-15',1,NULL,DATE '2026-06-01'); END;]');
    attendi_errore('gestisci_richiesta: tipo CAMBIO_PROGETTO con stesso progetto', -20078,
        q'[BEGIN gestisci_richiesta_variazione(9102,'APPROVATA',DATE '2026-05-15',1,2,DATE '2026-06-01'); END;]');

    gestisci_richiesta_variazione(9101, 'APPROVATA', DATE '2026-05-15', 1, 2, DATE '2026-06-01');
    SELECT COUNT(*) INTO v_n
    FROM ASSEGNAZIONE vecchia
    JOIN ASSEGNAZIONE nuova ON nuova.id_assegnazione_precedente = vecchia.id_assegnazione
    WHERE vecchia.id_assegnazione = v_ida
      AND vecchia.stato_assegnazione = 'CONCLUSA'
      AND vecchia.data_fine_effettiva = DATE '2026-05-31'
      AND nuova.id_sede = 2 AND nuova.data_inizio = DATE '2026-06-01' AND nuova.stato_assegnazione = 'ATTIVA';
    esito('gestisci_richiesta: approvazione chiude la vecchia assegnazione e ne crea una nuova', v_n = 1);

    SELECT COUNT(*) INTO v_n FROM RICHIESTA_VARIAZIONE
     WHERE id_richiesta = 9101 AND stato_richiesta = 'APPROVATA';
    esito('gestisci_richiesta: la richiesta risulta approvata', v_n = 1);

    attendi_errore('gestisci_richiesta: richiesta gia'' valutata', -20073,
        q'[BEGIN gestisci_richiesta_variazione(9101,'RIFIUTATA',DATE '2026-05-20'); END;]');

    gestisci_richiesta_variazione(9102, 'RIFIUTATA', DATE '2026-05-20');
    SELECT COUNT(*) INTO v_n FROM RICHIESTA_VARIAZIONE
     WHERE id_richiesta = 9102 AND stato_richiesta = 'RIFIUTATA' AND data_validazione = DATE '2026-05-20';
    esito('gestisci_richiesta: il rifiuto aggiorna solo la richiesta', v_n = 1);

    -- ---- inserisci_presenza / valida_presenza --------------------------------
    inserisci_presenza(1, DATE '2025-07-01', 'SERVIZIO', 6, 0, 'test');
    SELECT COUNT(*) INTO v_n FROM REGISTRO_SERVIZIO
     WHERE id_assegnazione = 1 AND data_servizio = DATE '2025-07-01' AND stato_validazione = 'DA_VALIDARE';
    esito('inserisci_presenza registra la giornata da validare', v_n = 1);

    attendi_errore('inserisci_presenza: giornata duplicata', -20146,
        q'[BEGIN inserisci_presenza(1,DATE '2025-07-01','SERVIZIO',6,0); END;]');
    attendi_errore('inserisci_presenza: volontario senza assegnazione attiva', -20145,
        q'[BEGIN inserisci_presenza(9002,DATE '2020-01-01','SERVIZIO',6,0); END;]');
    attendi_errore('inserisci_presenza: piu'' di 8 ore', -20147,
        q'[BEGIN inserisci_presenza(1,DATE '2025-07-02','SERVIZIO',9,0); END;]');
    attendi_errore('inserisci_presenza: tipo di giornata non valido', -20142,
        q'[BEGIN inserisci_presenza(1,DATE '2025-07-02','FERIE',0,0); END;]');

    attendi_errore('valida_presenza: esito non valido', -20091,
        q'[BEGIN valida_presenza(1,DATE '2025-07-01','BOH'); END;]');
    attendi_errore('valida_presenza: presenza inesistente', -20096,
        q'[BEGIN valida_presenza(1,DATE '2025-07-15','VALIDATA'); END;]');
    attendi_errore('valida_presenza: correzione con ore incoerenti', -20098,
        q'[BEGIN valida_presenza(1,DATE '2025-07-01','VALIDATA','PERMESSO_ORDINARIO',5,0); END;]');

    valida_presenza(1, DATE '2025-07-01', 'VALIDATA', NULL, 7, NULL, 'corretta');
    SELECT COUNT(*) INTO v_n FROM REGISTRO_SERVIZIO
     WHERE id_assegnazione = 1 AND data_servizio = DATE '2025-07-01'
       AND stato_validazione = 'VALIDATA' AND ore_svolte = 7 AND note = 'corretta';
    esito('valida_presenza valida e corregge le ore', v_n = 1);

    -- ---- copertura di ogni trigger ---------------------------------------------
    -- check_assegnazione_attiva: un periodo non sovrapposto e' ammesso
    attendi_ok('check_assegnazione_attiva: nuova assegnazione non sovrapposta',
        q'[INSERT INTO ASSEGNAZIONE (id_assegnazione, id_volontario, id_progetto, id_sede, data_inizio,
               data_fine_prevista, stato_assegnazione, ore_settimanali_previste)
           VALUES (9010, 1, 1, 1, DATE '2026-01-01', DATE '2026-06-30', 'ATTIVA', 35)]');

    -- check_progetto_sede_assegnazione: anche in aggiornamento
    attendi_errore('check_progetto_sede_assegnazione: aggiornamento verso sede non del progetto', -20002,
        'UPDATE ASSEGNAZIONE SET id_sede = 4 WHERE id_assegnazione = 1');

    -- check_permesso_straordinario_valido
    attendi_errore('check_permesso_straordinario_valido: nota vuota', -20009,
        q'[INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata,
               ore_svolte, stato_validazione, note)
           VALUES (9011, 1, DATE '2025-07-10', 'PERMESSO_STRAORDINARIO', 0, 'DA_VALIDARE', '   ')]');
    attendi_ok('check_permesso_straordinario_valido: con motivazione',
        q'[INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata,
               ore_svolte, stato_validazione, note)
           VALUES (9012, 1, DATE '2025-07-10', 'PERMESSO_STRAORDINARIO', 0, 'DA_VALIDARE', 'visita medica')]');

    -- check_coerenza_tipo_giornata_ore: permesso con ore
    attendi_errore('check_coerenza_tipo_giornata_ore: permesso con ore svolte', -20018,
        q'[INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata,
               ore_svolte, stato_validazione)
           VALUES (9013, 1, DATE '2025-07-11', 'PERMESSO_ORDINARIO', 5, 'DA_VALIDARE')]');

    -- check_monitoraggio_assegnazione_valida: caso di successo
    attendi_ok('check_monitoraggio_assegnazione_valida: monitoraggio nel periodo',
        q'[INSERT INTO MONITORAGGIO (id_monitoraggio, id_assegnazione, data_monitoraggio, tipo_monitoraggio)
           VALUES (9014, 1, DATE '2025-06-10', 'INTERMEDIO')]');

    -- check_limiti_assenze: decadenza per malattie retribuite e non retribuite
    INSERT INTO VOLONTARIO (id_volontario, nome, cognome, codice_fiscale, data_nascita, email,
                            comune_residenza, stato_volontario)
    VALUES (9003, 'Test', 'MalRetr', 'TSTMLR00A01H501Z', DATE '2000-01-01', 'test3@example.it',
            'Napoli', 'ATTIVO');
    INSERT INTO VOLONTARIO (id_volontario, nome, cognome, codice_fiscale, data_nascita, email,
                            comune_residenza, stato_volontario)
    VALUES (9004, 'Test', 'MalNonRetr', 'TSTMNR00A01H501W', DATE '2000-01-01', 'test4@example.it',
            'Napoli', 'ATTIVO');
    INSERT INTO ASSEGNAZIONE (id_assegnazione, id_volontario, id_progetto, id_sede, data_inizio,
                              data_fine_prevista, stato_assegnazione, ore_settimanali_previste,
                              max_malattie_retribuite)
    VALUES (9020, 9003, 1, 1, DATE '2025-03-01', DATE '2025-12-31', 'ATTIVA', 35, 0);
    INSERT INTO ASSEGNAZIONE (id_assegnazione, id_volontario, id_progetto, id_sede, data_inizio,
                              data_fine_prevista, stato_assegnazione, ore_settimanali_previste,
                              max_malattie_non_retribuite)
    VALUES (9021, 9004, 1, 1, DATE '2025-03-01', DATE '2025-12-31', 'ATTIVA', 35, 0);
    INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata,
                                   ore_svolte, stato_validazione)
    VALUES (9020, 9020, DATE '2025-03-10', 'MALATTIA_RETRIBUITA', 0, 'DA_VALIDARE');
    INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata,
                                   ore_svolte, stato_validazione)
    VALUES (9021, 9021, DATE '2025-03-10', 'MALATTIA_NON_RETRIBUITA', 0, 'DA_VALIDARE');

    SELECT stato_assegnazione INTO v_stato FROM ASSEGNAZIONE WHERE id_assegnazione = 9020;
    esito('check_limiti_assenze: decadenza per malattie retribuite', v_stato = 'DECADUTA');
    SELECT stato_assegnazione INTO v_stato FROM ASSEGNAZIONE WHERE id_assegnazione = 9021;
    esito('check_limiti_assenze: decadenza per malattie non retribuite', v_stato = 'DECADUTA');

    -- entro i limiti l'assegnazione resta attiva
    SELECT stato_assegnazione INTO v_stato FROM ASSEGNAZIONE WHERE id_assegnazione = 1;
    esito('check_limiti_assenze: un''assegnazione entro i limiti resta attiva', v_stato = 'ATTIVA');

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
