-- =============================================================================
-- Procedure sulle assegnazioni: crea_assegnazione, gestisci_richiesta_variazione
-- Codici d'errore: -20050..-20067 (crea), -20070..-20079 (variazione)
-- =============================================================================

CREATE OR REPLACE PROCEDURE crea_assegnazione (
    p_id_volontario               IN NUMBER,
    p_id_progetto                 IN NUMBER,
    p_id_sede                     IN NUMBER,
    p_data_inizio                 IN DATE,
    p_data_fine_prevista          IN DATE,
    p_stato_assegnazione          IN VARCHAR2,
    p_ore_settimanali_previste    IN NUMBER,
    p_max_permessi_ordinari       IN NUMBER,
    p_max_malattie_retribuite     IN NUMBER,
    p_max_malattie_non_retribuite IN NUMBER,
    p_id_assegnazione_precedente  IN NUMBER DEFAULT NULL
)
AS
    v_count             NUMBER;
    v_id_assegnazione   NUMBER;
    v_stato_progetto    PROGETTO.stato_progetto%TYPE;
    v_posti             PROGETTO_SEDE.posti_disponibili%TYPE;
    v_id_volontario_pre ASSEGNAZIONE.id_volontario%TYPE;
    v_stato_pre         ASSEGNAZIONE.stato_assegnazione%TYPE;
    v_fine_eff_pre      ASSEGNAZIONE.data_fine_effettiva%TYPE;
BEGIN
    IF p_id_volontario IS NULL
       OR p_id_progetto IS NULL
       OR p_id_sede IS NULL
       OR p_data_inizio IS NULL
       OR p_data_fine_prevista IS NULL
       OR p_stato_assegnazione IS NULL
       OR p_ore_settimanali_previste IS NULL
       OR p_max_permessi_ordinari IS NULL
       OR p_max_malattie_retribuite IS NULL
       OR p_max_malattie_non_retribuite IS NULL THEN
        RAISE_APPLICATION_ERROR(-20050, 'Dati obbligatori mancanti per la creazione dell''assegnazione.');
    END IF;

    IF p_data_inizio > p_data_fine_prevista THEN
        RAISE_APPLICATION_ERROR(-20051, 'La data di inizio non può essere successiva alla data di fine prevista.');
    END IF;

    IF p_ore_settimanali_previste <= 0 THEN
        RAISE_APPLICATION_ERROR(-20052, 'Le ore settimanali previste devono essere maggiori di zero.');
    END IF;

    IF p_max_permessi_ordinari < 0
       OR p_max_malattie_retribuite < 0
       OR p_max_malattie_non_retribuite < 0 THEN
        RAISE_APPLICATION_ERROR(-20053, 'I massimali di permessi e malattie non possono essere negativi.');
    END IF;

    -- Una nuova assegnazione nasce sempre attiva, senza data di fine effettiva
    IF UPPER(TRIM(p_stato_assegnazione)) <> 'ATTIVA' THEN
        RAISE_APPLICATION_ERROR(-20054, 'Una nuova assegnazione può essere creata solo nello stato ATTIVA.');
    END IF;

    SELECT COUNT(*) INTO v_count FROM VOLONTARIO WHERE id_volontario = p_id_volontario;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20055, 'Il volontario indicato non esiste.');
    END IF;

    SELECT COUNT(*) INTO v_count FROM PROGETTO WHERE id_progetto = p_id_progetto;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20056, 'Il progetto indicato non esiste.');
    END IF;

    SELECT stato_progetto INTO v_stato_progetto FROM PROGETTO WHERE id_progetto = p_id_progetto;
    IF v_stato_progetto = 'SOSPESO' THEN
        RAISE_APPLICATION_ERROR(-20057, 'Il progetto indicato è sospeso e non accetta nuove assegnazioni.');
    END IF;

    SELECT COUNT(*) INTO v_count FROM SEDE WHERE id_sede = p_id_sede;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20058, 'La sede indicata non esiste.');
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM PROGETTO_SEDE
    WHERE id_progetto = p_id_progetto AND id_sede = p_id_sede;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20059, 'La sede indicata non è associata al progetto scelto.');
    END IF;

    -- Il volontario non può avere un'altra assegnazione attiva nello stesso periodo
    -- (esclusa l'eventuale assegnazione precedente, che viene chiusa dalla variazione)
    SELECT COUNT(*) INTO v_count
    FROM ASSEGNAZIONE a
    WHERE a.id_volontario = p_id_volontario
      AND a.stato_assegnazione = 'ATTIVA'
      AND (p_id_assegnazione_precedente IS NULL OR a.id_assegnazione <> p_id_assegnazione_precedente)
      AND p_data_inizio <= NVL(a.data_fine_effettiva, NVL(a.data_fine_prevista, DATE '9999-12-31'))
      AND p_data_fine_prevista >= a.data_inizio;
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20060,
            'Il volontario ha già un''assegnazione attiva nello stesso periodo.');
    END IF;

    -- Posti disponibili sulla coppia progetto-sede (assegnazioni attive sovrapposte)
    SELECT posti_disponibili INTO v_posti
    FROM PROGETTO_SEDE
    WHERE id_progetto = p_id_progetto AND id_sede = p_id_sede;

    SELECT COUNT(*) INTO v_count
    FROM ASSEGNAZIONE a
    WHERE a.id_progetto = p_id_progetto
      AND a.id_sede = p_id_sede
      AND a.stato_assegnazione = 'ATTIVA'
      AND (p_id_assegnazione_precedente IS NULL OR a.id_assegnazione <> p_id_assegnazione_precedente)
      AND p_data_inizio <= NVL(a.data_fine_effettiva, NVL(a.data_fine_prevista, DATE '9999-12-31'))
      AND p_data_fine_prevista >= a.data_inizio;
    IF v_count >= v_posti THEN
        RAISE_APPLICATION_ERROR(-20066, 'Non ci sono posti disponibili per il progetto e la sede indicati.');
    END IF;

    IF p_id_assegnazione_precedente IS NOT NULL THEN
        SELECT COUNT(*) INTO v_count
        FROM ASSEGNAZIONE WHERE id_assegnazione = p_id_assegnazione_precedente;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20061, 'L''assegnazione precedente indicata non esiste.');
        END IF;

        SELECT id_volontario, stato_assegnazione, data_fine_effettiva
        INTO v_id_volontario_pre, v_stato_pre, v_fine_eff_pre
        FROM ASSEGNAZIONE
        WHERE id_assegnazione = p_id_assegnazione_precedente;

        IF v_id_volontario_pre <> p_id_volontario THEN
            RAISE_APPLICATION_ERROR(-20062, 'L''assegnazione precedente appartiene a un altro volontario.');
        END IF;

        IF v_stato_pre <> 'CONCLUSA' THEN
            RAISE_APPLICATION_ERROR(-20063, 'L''assegnazione precedente deve essere conclusa.');
        END IF;

        IF v_fine_eff_pre IS NULL THEN
            RAISE_APPLICATION_ERROR(-20064, 'L''assegnazione precedente non ha una data di fine effettiva.');
        END IF;

        IF v_fine_eff_pre > p_data_inizio THEN
            RAISE_APPLICATION_ERROR(-20065,
                'La fine effettiva dell''assegnazione precedente è successiva alla nuova data di inizio.');
        END IF;
    END IF;

    SELECT seq_assegnazione.NEXTVAL INTO v_id_assegnazione FROM DUAL;

    INSERT INTO ASSEGNAZIONE (
        id_assegnazione, id_volontario, id_progetto, id_sede, id_assegnazione_precedente,
        data_inizio, data_fine_prevista, data_fine_effettiva, stato_assegnazione,
        ore_settimanali_previste, max_permessi_ordinari, max_malattie_retribuite,
        max_malattie_non_retribuite
    )
    VALUES (
        v_id_assegnazione, p_id_volontario, p_id_progetto, p_id_sede, p_id_assegnazione_precedente,
        p_data_inizio, p_data_fine_prevista, NULL, 'ATTIVA',
        p_ore_settimanali_previste, p_max_permessi_ordinari, p_max_malattie_retribuite,
        p_max_malattie_non_retribuite
    );

    DBMS_OUTPUT.PUT_LINE('Assegnazione creata con successo. ID assegnazione: ' || v_id_assegnazione);
END;
/

CREATE OR REPLACE PROCEDURE gestisci_richiesta_variazione (
    p_id_richiesta      IN NUMBER,
    p_stato_richiesta   IN VARCHAR2,
    p_data_validazione  IN DATE,
    p_id_nuovo_progetto IN NUMBER DEFAULT NULL,
    p_id_nuova_sede     IN NUMBER DEFAULT NULL,
    p_data_decorrenza   IN DATE   DEFAULT NULL
)
AS
    v_count            NUMBER;
    v_stato_richiesta  RICHIESTA_VARIAZIONE.stato_richiesta%TYPE;
    v_tipo_variazione  RICHIESTA_VARIAZIONE.tipo_variazione%TYPE;
    v_data_richiesta   RICHIESTA_VARIAZIONE.data_richiesta%TYPE;
    v_id_assegnazione  ASSEGNAZIONE.id_assegnazione%TYPE;
    v_ass              ASSEGNAZIONE%ROWTYPE;
    v_esito            VARCHAR2(20) := UPPER(TRIM(p_stato_richiesta));
BEGIN
    IF p_id_richiesta IS NULL OR p_stato_richiesta IS NULL OR p_data_validazione IS NULL THEN
        RAISE_APPLICATION_ERROR(-20070, 'Dati obbligatori mancanti per la gestione della richiesta.');
    END IF;

    IF v_esito NOT IN ('APPROVATA', 'RIFIUTATA') THEN
        RAISE_APPLICATION_ERROR(-20071, 'Lo stato finale della richiesta deve essere APPROVATA o RIFIUTATA.');
    END IF;

    SELECT COUNT(*) INTO v_count FROM RICHIESTA_VARIAZIONE WHERE id_richiesta = p_id_richiesta;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20072, 'La richiesta indicata non esiste.');
    END IF;

    SELECT stato_richiesta, tipo_variazione, data_richiesta, id_assegnazione
    INTO v_stato_richiesta, v_tipo_variazione, v_data_richiesta, v_id_assegnazione
    FROM RICHIESTA_VARIAZIONE
    WHERE id_richiesta = p_id_richiesta;

    IF v_stato_richiesta <> 'IN_ATTESA' THEN
        RAISE_APPLICATION_ERROR(-20073, 'La richiesta risulta già valutata.');
    END IF;

    IF p_data_validazione < v_data_richiesta THEN
        RAISE_APPLICATION_ERROR(-20077, 'La data di validazione non può precedere la data della richiesta.');
    END IF;

    IF v_esito = 'APPROVATA' THEN
        IF p_id_nuovo_progetto IS NULL OR p_id_nuova_sede IS NULL OR p_data_decorrenza IS NULL THEN
            RAISE_APPLICATION_ERROR(-20074,
                'Per approvare servono nuovo progetto, nuova sede e data di decorrenza.');
        END IF;

        SELECT * INTO v_ass FROM ASSEGNAZIONE WHERE id_assegnazione = v_id_assegnazione;

        IF v_ass.stato_assegnazione <> 'ATTIVA' THEN
            RAISE_APPLICATION_ERROR(-20075, 'L''assegnazione corrente non è attiva.');
        END IF;

        IF p_data_decorrenza <= v_ass.data_inizio THEN
            RAISE_APPLICATION_ERROR(-20076,
                'La data di decorrenza deve essere successiva all''inizio dell''assegnazione corrente.');
        END IF;

        IF v_ass.data_fine_prevista IS NULL OR p_data_decorrenza > v_ass.data_fine_prevista THEN
            RAISE_APPLICATION_ERROR(-20079,
                'La data di decorrenza supera la fine prevista dell''assegnazione corrente.');
        END IF;

        -- Coerenza con il tipo di variazione richiesto
        IF (v_tipo_variazione = 'CAMBIO_SEDE'
                AND (p_id_nuovo_progetto <> v_ass.id_progetto OR p_id_nuova_sede = v_ass.id_sede))
           OR (v_tipo_variazione = 'CAMBIO_PROGETTO' AND p_id_nuovo_progetto = v_ass.id_progetto)
           OR (v_tipo_variazione = 'CAMBIO_ENTRAMBI'
                AND (p_id_nuovo_progetto = v_ass.id_progetto OR p_id_nuova_sede = v_ass.id_sede)) THEN
            RAISE_APPLICATION_ERROR(-20078,
                'Progetto e sede indicati non sono coerenti con il tipo di variazione richiesto.');
        END IF;

        -- Chiude l'assegnazione corrente il giorno prima della decorrenza
        UPDATE ASSEGNAZIONE
        SET stato_assegnazione = 'CONCLUSA',
            data_fine_effettiva = p_data_decorrenza - 1
        WHERE id_assegnazione = v_id_assegnazione;

        -- Crea la nuova assegnazione, collegata alla precedente e con la stessa dotazione
        crea_assegnazione(
            p_id_volontario               => v_ass.id_volontario,
            p_id_progetto                 => p_id_nuovo_progetto,
            p_id_sede                     => p_id_nuova_sede,
            p_data_inizio                 => p_data_decorrenza,
            p_data_fine_prevista          => v_ass.data_fine_prevista,
            p_stato_assegnazione          => 'ATTIVA',
            p_ore_settimanali_previste    => v_ass.ore_settimanali_previste,
            p_max_permessi_ordinari       => v_ass.max_permessi_ordinari,
            p_max_malattie_retribuite     => v_ass.max_malattie_retribuite,
            p_max_malattie_non_retribuite => v_ass.max_malattie_non_retribuite,
            p_id_assegnazione_precedente  => v_id_assegnazione
        );
    END IF;

    -- Per ultimo: il trigger check_storico_variazione verifica lo storico già creato
    UPDATE RICHIESTA_VARIAZIONE
    SET stato_richiesta = v_esito,
        data_validazione = p_data_validazione
    WHERE id_richiesta = p_id_richiesta;

    DBMS_OUTPUT.PUT_LINE('Richiesta ' || p_id_richiesta || ' gestita con esito ' || v_esito || '.');
END;
/
