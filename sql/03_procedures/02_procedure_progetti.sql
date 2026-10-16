-- =============================================================================
-- Procedure sui progetti: crea_progetto, modifica_progetto
-- Codici d'errore: -20150..-20159 (crea e funzione di supporto), -20020..-20025 (modifica)
-- =============================================================================

-- Funzione di supporto: converte una lista "1,2,3" di ID sede in una collezione,
-- verificando che ogni sede sia numerica, esista, appartenga all'ente e non sia duplicata.
CREATE OR REPLACE FUNCTION parse_lista_sedi (
    p_sedi_list IN VARCHAR2,
    p_id_ente   IN NUMBER
) RETURN SYS.ODCINUMBERLIST
AS
    v_sedi   SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST();
    v_token  VARCHAR2(100);
    v_pos    PLS_INTEGER := 1;
    v_id     NUMBER;
    v_count  NUMBER;
BEGIN
    LOOP
        v_token := TRIM(REGEXP_SUBSTR(p_sedi_list, '[^,]+', 1, v_pos));
        EXIT WHEN v_token IS NULL;

        IF NOT REGEXP_LIKE(v_token, '^[0-9]+$') THEN
            RAISE_APPLICATION_ERROR(-20150, 'La lista delle sedi contiene un valore non valido: ' || v_token);
        END IF;

        v_id := TO_NUMBER(v_token);

        FOR i IN 1 .. v_sedi.COUNT LOOP
            IF v_sedi(i) = v_id THEN
                RAISE_APPLICATION_ERROR(-20151, 'La sede ' || v_id || ' è presente più di una volta nella lista.');
            END IF;
        END LOOP;

        SELECT COUNT(*) INTO v_count FROM SEDE WHERE id_sede = v_id;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20152, 'La sede ' || v_id || ' non esiste.');
        END IF;

        SELECT COUNT(*) INTO v_count FROM SEDE WHERE id_sede = v_id AND id_ente = p_id_ente;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20153, 'La sede ' || v_id || ' non appartiene all''ente indicato.');
        END IF;

        v_sedi.EXTEND;
        v_sedi(v_sedi.COUNT) := v_id;
        v_pos := v_pos + 1;
    END LOOP;

    IF v_sedi.COUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20154, 'La lista delle sedi è vuota o malformata.');
    END IF;

    RETURN v_sedi;
END;
/

CREATE OR REPLACE PROCEDURE crea_progetto (
    p_id_ente               IN NUMBER,
    p_titolo_progetto       IN VARCHAR2,
    p_area_intervento       IN VARCHAR2,
    p_descrizione_progetto  IN VARCHAR2,
    p_data_inizio           IN DATE,
    p_data_fine             IN DATE,
    p_stato_progetto        IN VARCHAR2,
    p_sedi_list             IN VARCHAR2,
    p_posti_disponibili     IN NUMBER
)
AS
    v_count        NUMBER;
    v_id_progetto  NUMBER;
    v_sedi         SYS.ODCINUMBERLIST;
BEGIN
    IF p_id_ente IS NULL
       OR p_titolo_progetto IS NULL
       OR p_area_intervento IS NULL
       OR p_descrizione_progetto IS NULL
       OR p_data_inizio IS NULL
       OR p_stato_progetto IS NULL
       OR p_sedi_list IS NULL
       OR p_posti_disponibili IS NULL THEN
        RAISE_APPLICATION_ERROR(-20155, 'Dati obbligatori mancanti per la creazione del progetto.');
    END IF;

    IF p_data_fine IS NOT NULL AND p_data_inizio > p_data_fine THEN
        RAISE_APPLICATION_ERROR(-20156, 'La data di inizio non può essere successiva alla data di fine.');
    END IF;

    IF p_posti_disponibili < 0 THEN
        RAISE_APPLICATION_ERROR(-20157, 'Il numero di posti disponibili non è valido.');
    END IF;

    IF UPPER(TRIM(p_stato_progetto)) NOT IN ('ATTIVO', 'CONCLUSO', 'SOSPESO') THEN
        RAISE_APPLICATION_ERROR(-20158, 'Stato del progetto non valido.');
    END IF;

    SELECT COUNT(*) INTO v_count FROM ENTE WHERE id_ente = p_id_ente;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20159, 'L''ente indicato non esiste.');
    END IF;

    v_sedi := parse_lista_sedi(p_sedi_list, p_id_ente);

    SELECT seq_progetto.NEXTVAL INTO v_id_progetto FROM DUAL;

    INSERT INTO PROGETTO (
        id_progetto, id_ente, titolo, area_intervento, descrizione,
        data_inizio, data_fine, stato_progetto
    )
    VALUES (
        v_id_progetto, p_id_ente, p_titolo_progetto, p_area_intervento, p_descrizione_progetto,
        p_data_inizio, p_data_fine, UPPER(TRIM(p_stato_progetto))
    );

    FOR i IN 1 .. v_sedi.COUNT LOOP
        INSERT INTO PROGETTO_SEDE (id_progetto, id_sede, posti_disponibili)
        VALUES (v_id_progetto, v_sedi(i), p_posti_disponibili);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Progetto creato con successo. ID progetto: ' || v_id_progetto);
END;
/

CREATE OR REPLACE PROCEDURE modifica_progetto (
    p_id_progetto           IN NUMBER,
    p_titolo_progetto       IN VARCHAR2,
    p_area_intervento       IN VARCHAR2,
    p_descrizione_progetto  IN VARCHAR2,
    p_data_inizio           IN DATE,
    p_data_fine             IN DATE,
    p_stato_progetto        IN VARCHAR2,
    p_sedi_list             IN VARCHAR2,
    p_posti_disponibili     IN NUMBER
)
AS
    v_count   NUMBER;
    v_id_ente PROGETTO.id_ente%TYPE;
    v_sedi    SYS.ODCINUMBERLIST;
BEGIN
    IF p_id_progetto IS NULL
       OR p_titolo_progetto IS NULL
       OR p_area_intervento IS NULL
       OR p_descrizione_progetto IS NULL
       OR p_data_inizio IS NULL
       OR p_stato_progetto IS NULL
       OR p_sedi_list IS NULL
       OR p_posti_disponibili IS NULL THEN
        RAISE_APPLICATION_ERROR(-20020, 'Dati obbligatori mancanti per la modifica del progetto.');
    END IF;

    IF p_data_fine IS NOT NULL AND p_data_inizio > p_data_fine THEN
        RAISE_APPLICATION_ERROR(-20021, 'La data di inizio non può essere successiva alla data di fine.');
    END IF;

    IF p_posti_disponibili < 0 THEN
        RAISE_APPLICATION_ERROR(-20022, 'Il numero di posti disponibili non è valido.');
    END IF;

    IF UPPER(TRIM(p_stato_progetto)) NOT IN ('ATTIVO', 'CONCLUSO', 'SOSPESO') THEN
        RAISE_APPLICATION_ERROR(-20023, 'Stato del progetto non valido.');
    END IF;

    SELECT COUNT(*) INTO v_count FROM PROGETTO WHERE id_progetto = p_id_progetto;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20024, 'Il progetto indicato non esiste.');
    END IF;

    SELECT id_ente INTO v_id_ente FROM PROGETTO WHERE id_progetto = p_id_progetto;

    v_sedi := parse_lista_sedi(p_sedi_list, v_id_ente);

    -- Una sede già usata da assegnazioni del progetto non può essere rimossa
    SELECT COUNT(*)
    INTO v_count
    FROM ASSEGNAZIONE a
    WHERE a.id_progetto = p_id_progetto
      AND a.id_sede NOT IN (SELECT COLUMN_VALUE FROM TABLE(v_sedi));

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20025,
            'Non è possibile rimuovere una sede già usata da assegnazioni del progetto.');
    END IF;

    UPDATE PROGETTO
    SET titolo = p_titolo_progetto,
        area_intervento = p_area_intervento,
        descrizione = p_descrizione_progetto,
        data_inizio = p_data_inizio,
        data_fine = p_data_fine,
        stato_progetto = UPPER(TRIM(p_stato_progetto))
    WHERE id_progetto = p_id_progetto;

    DELETE FROM PROGETTO_SEDE WHERE id_progetto = p_id_progetto;

    FOR i IN 1 .. v_sedi.COUNT LOOP
        INSERT INTO PROGETTO_SEDE (id_progetto, id_sede, posti_disponibili)
        VALUES (p_id_progetto, v_sedi(i), p_posti_disponibili);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Progetto modificato con successo. ID progetto: ' || p_id_progetto);
END;
/
