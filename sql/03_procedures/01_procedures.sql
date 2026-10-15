-- =============================================================================
-- Procedure di gestione (PL/SQL)
-- Ogni procedura valida gli input, esegue l'operazione e conferma con COMMIT.
-- =============================================================================

CREATE OR REPLACE PROCEDURE disattiva_progetto (
    p_id_progetto   IN NUMBER,
    p_motivazione   IN VARCHAR2
)
AS
    v_count                 NUMBER;
    v_stato_progetto        PROGETTO.stato_progetto%TYPE;
    v_count_assegnazioni    NUMBER;
    v_count_sedi            NUMBER;
BEGIN
    IF p_id_progetto IS NULL OR p_motivazione IS NULL OR TRIM(p_motivazione) IS NULL THEN
        RAISE_APPLICATION_ERROR(-20040, 'Identificativo progetto o motivazione mancanti.');
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM PROGETTO
    WHERE id_progetto = p_id_progetto;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20041, 'Il progetto indicato non esiste.');
    END IF;

    SELECT stato_progetto
    INTO v_stato_progetto
    FROM PROGETTO
    WHERE id_progetto = p_id_progetto;

    IF UPPER(TRIM(v_stato_progetto)) = 'SOSPESO' THEN
        RAISE_APPLICATION_ERROR(-20042, 'Il progetto risulta già disattivato.');
    END IF;

    SELECT COUNT(*)
    INTO v_count_assegnazioni
    FROM ASSEGNAZIONE
    WHERE id_progetto = p_id_progetto
      AND stato_assegnazione = 'ATTIVA';

    IF v_count_assegnazioni > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20043,
            'Non è possibile disattivare il progetto: esistono assegnazioni attive collegate.'
        );
    END IF;

    SELECT COUNT(*)
    INTO v_count_sedi
    FROM PROGETTO_SEDE
    WHERE id_progetto = p_id_progetto;

    UPDATE PROGETTO
    SET stato_progetto = 'SOSPESO'
    WHERE id_progetto = p_id_progetto;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE(
        'Progetto disattivato con successo. ID progetto: ' || p_id_progetto ||
        '. Sedi collegate mantenute: ' || v_count_sedi ||
        '. Motivazione: ' || p_motivazione
    );

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

CREATE OR REPLACE PROCEDURE registra_formazione (
    p_titolo_formazione        IN VARCHAR2,
    p_tipologia_formazione     IN VARCHAR2,
    p_descrizione_formazione   IN VARCHAR2,
    p_data_formazione          IN DATE,
    p_durata_ore               IN NUMBER,
    p_id_operatore             IN NUMBER
)
AS
    v_count            NUMBER;
    v_id_formazione    NUMBER;
BEGIN
    IF p_titolo_formazione IS NULL
       OR p_tipologia_formazione IS NULL
       OR p_descrizione_formazione IS NULL
       OR p_data_formazione IS NULL
       OR p_durata_ore IS NULL
       OR p_id_operatore IS NULL THEN
        RAISE_APPLICATION_ERROR(-20110, 'Dati obbligatori mancanti per la registrazione della formazione.');
    END IF;

    IF UPPER(TRIM(p_tipologia_formazione)) NOT IN ('GENERALE', 'SPECIFICA', 'INTEGRATIVA') THEN
        RAISE_APPLICATION_ERROR(-20111, 'Tipologia della formazione non valida.');
    END IF;

    IF p_durata_ore <= 0 THEN
        RAISE_APPLICATION_ERROR(-20112, 'La durata della formazione deve essere maggiore di zero.');
    END IF;

    IF p_data_formazione > TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20114, 'La data della formazione non può esserè successiva alla data corrente.');
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM OPERATORE
    WHERE id_operatore = p_id_operatore;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20113, 'L''operatore indicato non esiste.');
    END IF;

    SELECT seq_formazione.NEXTVAL
    INTO v_id_formazione
    FROM DUAL;

    INSERT INTO FORMAZIONE (
        id_formazione,
        id_operatore,
        titolo,
        tipologia,
        data_formazione,
        durata_ore,
        descrizione
    )
    VALUES (
        v_id_formazione,
        p_id_operatore,
        p_titolo_formazione,
        UPPER(TRIM(p_tipologia_formazione)),
        p_data_formazione,
        p_durata_ore,
        p_descrizione_formazione
    );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE(
        'Formazione registrata con successo. ID formazione: ' || v_id_formazione
    );

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

CREATE OR REPLACE PROCEDURE registra_partecipazione_formazione (
    p_id_assegnazione    IN NUMBER,
    p_id_formazione      IN NUMBER,
    p_presenza           IN VARCHAR2,
    p_ore_frequentate    IN NUMBER,
    p_note               IN VARCHAR2 DEFAULT NULL
)
AS
    v_count NUMBER;
BEGIN
    IF p_id_assegnazione IS NULL
       OR p_id_formazione IS NULL
       OR p_presenza IS NULL
       OR p_ore_frequentate IS NULL THEN
        RAISE_APPLICATION_ERROR(
            -20120,
            'Dati obbligatori mancanti per la registrazione della partecipazione alla formazione.'
        );
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM ASSEGNAZIONE
    WHERE id_assegnazione = p_id_assegnazione;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20121,
            'L''assegnazione indicata non esiste.'
        );
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM FORMAZIONE
    WHERE id_formazione = p_id_formazione;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20122,
            'La formazione indicata non esiste.'
        );
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM ASSEGNAZIONE_FORMAZIONE
    WHERE id_assegnazione = p_id_assegnazione
      AND id_formazione = p_id_formazione;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20123,
            'La partecipazione alla formazione risulta già registrata.'
        );
    END IF;

    IF UPPER(TRIM(p_presenza)) NOT IN ('PRESENTE', 'ASSENTE', 'PARZIALE') THEN
        RAISE_APPLICATION_ERROR(
            -20124,
            'Valore di presenza non valido.'
        );
    END IF;

    IF p_ore_frequentate < 0 THEN
        RAISE_APPLICATION_ERROR(
            -20125,
            'Le ore frequentate non possono essere negative.'
        );
    END IF;

    IF UPPER(TRIM(p_presenza)) = 'ASSENTE'
       AND p_ore_frequentate <> 0 THEN
        RAISE_APPLICATION_ERROR(
            -20126,
            'In caso di assenza, le ore frequentate devono essere pari a zero.'
        );
    END IF;

    IF UPPER(TRIM(p_presenza)) IN ('PRESENTE', 'PARZIALE')
       AND p_ore_frequentate <= 0 THEN
        RAISE_APPLICATION_ERROR(
            -20127,
            'In caso di presenza o presenza parziale, le ore frequentate devono essere maggiori di zero.'
        );
    END IF;

    INSERT INTO ASSEGNAZIONE_FORMAZIONE (
        id_assegnazione,
        id_formazione,
        presenza,
        ore_frequentate,
        note_partecipazione
    )
    VALUES (
        p_id_assegnazione,
        p_id_formazione,
        UPPER(TRIM(p_presenza)),
        p_ore_frequentate,
        p_note
    );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE(
        'Partecipazione alla formazione registrata con successo. Assegnazione: '
        || p_id_assegnazione ||
        ', formazione: ' || p_id_formazione
    );

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

CREATE OR REPLACE PROCEDURE registra_monitoraggio (
    p_id_assegnazione        IN NUMBER,
    p_data_monitoraggio      IN DATE,
    p_tipo_monitoraggio      IN VARCHAR2,
    p_esito_monitoraggio     IN VARCHAR2,
    p_note                   IN VARCHAR2 DEFAULT NULL
)
AS
    v_count                NUMBER;
    v_id_monitoraggio      NUMBER;
    v_data_inizio          ASSEGNAZIONE.data_inizio%TYPE;
    v_data_fine_prevista   ASSEGNAZIONE.data_fine_prevista%TYPE;
    v_data_fine_effettiva  ASSEGNAZIONE.data_fine_effettiva%TYPE;
BEGIN
    IF p_id_assegnazione IS NULL
       OR p_data_monitoraggio IS NULL
       OR p_tipo_monitoraggio IS NULL
       OR p_esito_monitoraggio IS NULL THEN
        RAISE_APPLICATION_ERROR(
            -20130,
            'Dati obbligatori mancanti per la registrazione del monitoraggio.'
        );
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM ASSEGNAZIONE
    WHERE id_assegnazione = p_id_assegnazione;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20131,
            'L''assegnazione indicata non esiste.'
        );
    END IF;

    SELECT data_inizio,
           data_fine_prevista,
           data_fine_effettiva
    INTO v_data_inizio,
         v_data_fine_prevista,
         v_data_fine_effettiva
    FROM ASSEGNAZIONE
    WHERE id_assegnazione = p_id_assegnazione;

    IF p_data_monitoraggio < v_data_inizio THEN
        RAISE_APPLICATION_ERROR(
            -20132,
            'La data del monitoraggio non può essere precedente alla data di inizio dell''assegnazione.'
        );
    END IF;

    IF v_data_fine_effettiva IS NOT NULL
       AND p_data_monitoraggio > v_data_fine_effettiva THEN
        RAISE_APPLICATION_ERROR(
            -20133,
            'La data del monitoraggio è successiva alla fine effettiva dell''assegnazione.'
        );
    END IF;

    IF v_data_fine_effettiva IS NULL
       AND v_data_fine_prevista IS NOT NULL
       AND p_data_monitoraggio > v_data_fine_prevista THEN
        RAISE_APPLICATION_ERROR(
            -20134,
            'La data del monitoraggio è successiva alla fine prevista dell''assegnazione.'
        );
    END IF;

    IF UPPER(TRIM(p_tipo_monitoraggio)) NOT IN ('INIZIALE', 'INTERMEDIO', 'FINALE') THEN
        RAISE_APPLICATION_ERROR(
            -20135,
            'Tipologia di monitoraggio non valida.'
        );
    END IF;

    IF UPPER(TRIM(p_esito_monitoraggio)) NOT IN ('POSITIVO', 'NEGATIVO', 'CRITICO') THEN
        RAISE_APPLICATION_ERROR(
            -20136,
            'Esito del monitoraggio non valido.'
        );
    END IF;

    SELECT seq_monitoraggio.NEXTVAL
    INTO v_id_monitoraggio
    FROM DUAL;

    INSERT INTO MONITORAGGIO (
        id_monitoraggio,
        id_assegnazione,
        data_monitoraggio,
        tipo_monitoraggio,
        esito,
        note
    )
    VALUES (
        v_id_monitoraggio,
        p_id_assegnazione,
        p_data_monitoraggio,
        UPPER(TRIM(p_tipo_monitoraggio)),
        UPPER(TRIM(p_esito_monitoraggio)),
        p_note
    );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE(
        'Monitoraggio registrato con successo. ID monitoraggio: ' || v_id_monitoraggio
    );

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

CREATE OR REPLACE VIEW Presenze_Da_Validare AS
SELECT
    rs.id_registro,
    rs.data_servizio,
    rs.tipo_giornata,
    rs.ore_svolte,
    rs.ore_da_recuperare,
    rs.stato_validazione,
    v.id_volontario,
    v.nome,
    v.cognome,
    a.id_assegnazione,
    a.id_progetto,
    a.id_sede
FROM REGISTRO_SERVIZIO rs
JOIN ASSEGNAZIONE a
    ON rs.id_assegnazione = a.id_assegnazione
JOIN VOLONTARIO v
    ON a.id_volontario = v.id_volontario
WHERE rs.stato_validazione = 'DA_VALIDARE'
