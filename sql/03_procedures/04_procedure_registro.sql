-- =============================================================================
-- Procedure sul registro di servizio: inserisci_presenza, valida_presenza
-- Codici d'errore: -20140..-20149 (inserimento), -20090..-20098 (validazione)
-- =============================================================================

CREATE OR REPLACE PROCEDURE inserisci_presenza (
    p_id_volontario     IN NUMBER,
    p_data_servizio     IN DATE,
    p_tipo_giornata     IN VARCHAR2,
    p_ore_svolte        IN NUMBER,
    p_ore_da_recuperare IN NUMBER,
    p_note              IN VARCHAR2 DEFAULT NULL
)
AS
    v_count            NUMBER;
    v_id_assegnazione  ASSEGNAZIONE.id_assegnazione%TYPE;
    v_id_registro      NUMBER;
    v_tipo             VARCHAR2(30) := UPPER(TRIM(p_tipo_giornata));
    v_utente           VARCHAR2(128) := SYS_CONTEXT('USERENV', 'SESSION_USER');
    v_tipo_utente      UTENTE_APPLICATIVO.tipo_utente%TYPE;
    v_id_vol_utente    UTENTE_APPLICATIVO.id_volontario%TYPE;
BEGIN
    IF p_id_volontario IS NULL
       OR p_data_servizio IS NULL
       OR p_tipo_giornata IS NULL
       OR p_ore_svolte IS NULL
       OR p_ore_da_recuperare IS NULL THEN
        RAISE_APPLICATION_ERROR(-20140, 'Dati obbligatori mancanti per l''inserimento della presenza.');
    END IF;

    -- Autorizzazione: il proprietario dello schema e gli amministratori registrano per
    -- chiunque; un volontario solo per sé; operatori e utenti non registrati non possono.
    IF v_utente <> SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') THEN
        SELECT MAX(tipo_utente), MAX(id_volontario)
        INTO v_tipo_utente, v_id_vol_utente
        FROM UTENTE_APPLICATIVO
        WHERE username = v_utente;

        IF v_tipo_utente IS NULL OR v_tipo_utente = 'OPERATORE' THEN
            RAISE_APPLICATION_ERROR(-20149, 'L''utente non è autorizzato a registrare presenze.');
        END IF;

        IF v_tipo_utente = 'VOLONTARIO' AND v_id_vol_utente <> p_id_volontario THEN
            RAISE_APPLICATION_ERROR(-20148, 'Un volontario può registrare solo le proprie presenze.');
        END IF;
    END IF;

    SELECT COUNT(*) INTO v_count FROM VOLONTARIO WHERE id_volontario = p_id_volontario;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20141, 'Il volontario indicato non esiste.');
    END IF;

    IF v_tipo NOT IN ('SERVIZIO', 'PERMESSO_ORDINARIO', 'MALATTIA_RETRIBUITA',
                      'MALATTIA_NON_RETRIBUITA', 'PERMESSO_STRAORDINARIO') THEN
        RAISE_APPLICATION_ERROR(-20142, 'Tipo di giornata non valido.');
    END IF;

    IF p_ore_svolte < 0 OR p_ore_da_recuperare < 0 THEN
        RAISE_APPLICATION_ERROR(-20143, 'Le ore non possono essere negative.');
    END IF;

    IF p_ore_svolte > 8 THEN
        RAISE_APPLICATION_ERROR(-20147, 'Le ore svolte in una giornata non possono superare 8.');
    END IF;

    IF (v_tipo = 'SERVIZIO' AND p_ore_svolte <= 0)
       OR (v_tipo <> 'SERVIZIO' AND p_ore_svolte <> 0) THEN
        RAISE_APPLICATION_ERROR(-20144,
            'Il servizio richiede ore maggiori di zero; permessi e malattie richiedono zero ore.');
    END IF;

    -- Assegnazione attiva del volontario valida nella data indicata
    SELECT COUNT(*) INTO v_count
    FROM ASSEGNAZIONE
    WHERE id_volontario = p_id_volontario
      AND stato_assegnazione = 'ATTIVA'
      AND p_data_servizio >= data_inizio
      AND p_data_servizio <= NVL(data_fine_effettiva, NVL(data_fine_prevista, DATE '9999-12-31'));

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20145,
            'Il volontario non ha un''assegnazione attiva valida nella data indicata.');
    END IF;

    SELECT id_assegnazione INTO v_id_assegnazione
    FROM ASSEGNAZIONE
    WHERE id_volontario = p_id_volontario
      AND stato_assegnazione = 'ATTIVA'
      AND p_data_servizio >= data_inizio
      AND p_data_servizio <= NVL(data_fine_effettiva, NVL(data_fine_prevista, DATE '9999-12-31'));

    SELECT COUNT(*) INTO v_count
    FROM REGISTRO_SERVIZIO
    WHERE id_assegnazione = v_id_assegnazione AND data_servizio = p_data_servizio;
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20146, 'Esiste già una presenza per questa assegnazione e questa data.');
    END IF;

    SELECT seq_registro.NEXTVAL INTO v_id_registro FROM DUAL;

    INSERT INTO REGISTRO_SERVIZIO (
        id_registro, id_assegnazione, data_servizio, tipo_giornata,
        ore_svolte, ore_da_recuperare, stato_validazione, note
    )
    VALUES (
        v_id_registro, v_id_assegnazione, p_data_servizio, v_tipo,
        p_ore_svolte, p_ore_da_recuperare, 'DA_VALIDARE', p_note
    );

    DBMS_OUTPUT.PUT_LINE('Presenza registrata con successo. ID registro: ' || v_id_registro);
END;
/

CREATE OR REPLACE PROCEDURE valida_presenza (
    p_id_assegnazione    IN NUMBER,
    p_data_servizio      IN DATE,
    p_esito_validazione  IN VARCHAR2,
    p_tipo_giornata      IN VARCHAR2 DEFAULT NULL,
    p_ore_svolte         IN NUMBER   DEFAULT NULL,
    p_ore_da_recuperare  IN NUMBER   DEFAULT NULL,
    p_note               IN VARCHAR2 DEFAULT NULL
)
AS
    v_count        NUMBER;
    v_ass          ASSEGNAZIONE%ROWTYPE;
    v_reg          REGISTRO_SERVIZIO%ROWTYPE;
    v_esito        VARCHAR2(15) := UPPER(TRIM(p_esito_validazione));
    v_tipo         VARCHAR2(30);
    v_ore_svolte   NUMBER;
    v_ore_recupero NUMBER;
BEGIN
    IF p_id_assegnazione IS NULL OR p_data_servizio IS NULL OR p_esito_validazione IS NULL THEN
        RAISE_APPLICATION_ERROR(-20090, 'Dati obbligatori mancanti per la validazione della presenza.');
    END IF;

    IF v_esito NOT IN ('VALIDATA', 'RIFIUTATA') THEN
        RAISE_APPLICATION_ERROR(-20091, 'L''esito della validazione deve essere VALIDATA o RIFIUTATA.');
    END IF;

    SELECT COUNT(*) INTO v_count FROM ASSEGNAZIONE WHERE id_assegnazione = p_id_assegnazione;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20092, 'L''assegnazione indicata non esiste.');
    END IF;

    SELECT * INTO v_ass FROM ASSEGNAZIONE WHERE id_assegnazione = p_id_assegnazione; -- noqa: AM04

    IF p_data_servizio < v_ass.data_inizio THEN
        RAISE_APPLICATION_ERROR(-20093, 'L''assegnazione non è valida nella data indicata.');
    END IF;

    IF v_ass.data_fine_effettiva IS NOT NULL AND p_data_servizio > v_ass.data_fine_effettiva THEN
        RAISE_APPLICATION_ERROR(-20094,
            'La data del servizio è successiva alla fine effettiva dell''assegnazione.');
    END IF;

    IF v_ass.data_fine_effettiva IS NULL
       AND v_ass.data_fine_prevista IS NOT NULL
       AND p_data_servizio > v_ass.data_fine_prevista THEN
        RAISE_APPLICATION_ERROR(-20095,
            'La data del servizio è successiva alla fine prevista dell''assegnazione.');
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM REGISTRO_SERVIZIO
    WHERE id_assegnazione = p_id_assegnazione AND data_servizio = p_data_servizio;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20096, 'Presenza non trovata per assegnazione e data indicate.');
    END IF;

    SELECT * INTO v_reg -- noqa: AM04
    FROM REGISTRO_SERVIZIO
    WHERE id_assegnazione = p_id_assegnazione AND data_servizio = p_data_servizio;

    -- Valori finali: quelli di correzione, se forniti, altrimenti quelli già registrati
    v_tipo         := NVL(UPPER(TRIM(p_tipo_giornata)), v_reg.tipo_giornata);
    v_ore_svolte   := NVL(p_ore_svolte, v_reg.ore_svolte);
    v_ore_recupero := NVL(p_ore_da_recuperare, v_reg.ore_da_recuperare);

    IF v_tipo NOT IN ('SERVIZIO', 'PERMESSO_ORDINARIO', 'MALATTIA_RETRIBUITA',
                      'MALATTIA_NON_RETRIBUITA', 'PERMESSO_STRAORDINARIO') THEN
        RAISE_APPLICATION_ERROR(-20097, 'Tipo di giornata non valido.');
    END IF;

    IF v_ore_svolte < 0 OR v_ore_svolte > 8 OR v_ore_recupero < 0
       OR (v_tipo = 'SERVIZIO' AND v_ore_svolte <= 0)
       OR (v_tipo <> 'SERVIZIO' AND v_ore_svolte <> 0) THEN
        RAISE_APPLICATION_ERROR(-20098,
            'Ore non coerenti con il tipo di giornata (servizio: 1-8 ore; permessi e malattie: 0 ore).');
    END IF;

    UPDATE REGISTRO_SERVIZIO
    SET tipo_giornata = v_tipo,
        ore_svolte = v_ore_svolte,
        ore_da_recuperare = v_ore_recupero,
        stato_validazione = v_esito,
        note = NVL(p_note, note)
    WHERE id_registro = v_reg.id_registro;

    DBMS_OUTPUT.PUT_LINE('Presenza ' || v_reg.id_registro || ' aggiornata con esito ' || v_esito || '.');
END;
/
