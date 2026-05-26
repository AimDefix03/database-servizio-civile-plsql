CREATE OR REPLACE TRIGGER check_assegnazione_attiva
FOR INSERT OR UPDATE ON ASSEGNAZIONE
COMPOUND TRIGGER

    TYPE t_assegnazione IS RECORD (
        id_assegnazione ASSEGNAZIONE.id_assegnazione%TYPE,
        id_volontario ASSEGNAZIONE.id_volontario%TYPE,
        data_inizio ASSEGNAZIONE.data_inizio%TYPE,
        data_fine_prevista ASSEGNAZIONE.data_fine_prevista%TYPE,
        data_fine_effettiva ASSEGNAZIONE.data_fine_effettiva%TYPE,
        stato_assegnazione ASSEGNAZIONE.stato_assegnazione%TYPE
    );

    TYPE t_lista_assegnazioni IS TABLE OF t_assegnazione INDEX BY PLS_INTEGER;

    v_assegnazioni t_lista_assegnazioni;
    v_indice PLS_INTEGER := 0;

AFTER EACH ROW IS
BEGIN
    v_indice := v_indice + 1;

    v_assegnazioni(v_indice).id_assegnazione := :NEW.id_assegnazione;
    v_assegnazioni(v_indice).id_volontario := :NEW.id_volontario;
    v_assegnazioni(v_indice).data_inizio := :NEW.data_inizio;
    v_assegnazioni(v_indice).data_fine_prevista := :NEW.data_fine_prevista;
    v_assegnazioni(v_indice).data_fine_effettiva := :NEW.data_fine_effettiva;
    v_assegnazioni(v_indice).stato_assegnazione := :NEW.stato_assegnazione;
END AFTER EACH ROW;

AFTER STATEMENT IS
    v_conteggio NUMBER;
BEGIN
    FOR i IN 1 .. v_indice LOOP

        IF v_assegnazioni(i).stato_assegnazione = 'ATTIVA' THEN

            SELECT COUNT(*)
            INTO v_conteggio
            FROM ASSEGNAZIONE a
            WHERE a.id_volontario = v_assegnazioni(i).id_volontario
              AND a.id_assegnazione <> v_assegnazioni(i).id_assegnazione
              AND a.stato_assegnazione = 'ATTIVA'
              AND v_assegnazioni(i).data_inizio <= NVL(a.data_fine_effettiva, NVL(a.data_fine_prevista, DATE '9999-12-31'))
              AND NVL(v_assegnazioni(i).data_fine_effettiva, NVL(v_assegnazioni(i).data_fine_prevista, DATE '9999-12-31')) >= a.data_inizio;

            IF v_conteggio > 0 THEN
                RAISE_APPLICATION_ERROR(
                    -20001,
                    'Il volontario ha gia una assegnazione attiva nello stesso intervallo temporale.'
                );
            END IF;

        END IF;

    END LOOP;
END AFTER STATEMENT;

END;

CREATE OR REPLACE TRIGGER check_progetto_sede_assegnazione
BEFORE INSERT OR UPDATE OF id_progetto, id_sede
ON ASSEGNAZIONE
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM PROGETTO_SEDE
    WHERE id_progetto = :NEW.id_progetto
      AND id_sede = :NEW.id_sede;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'La sede indicata non e associata al progetto scelto.'
        );
    END IF;
END;

CREATE OR REPLACE TRIGGER check_storico_variazione
BEFORE UPDATE OF stato_richiesta
ON RICHIESTA_VARIAZIONE
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    IF :NEW.stato_richiesta = 'APPROVATA'
       AND :OLD.stato_richiesta <> 'APPROVATA' THEN

        SELECT COUNT(*)
        INTO v_count
        FROM ASSEGNAZIONE precedente
        JOIN ASSEGNAZIONE successiva
          ON successiva.id_assegnazione_precedente = precedente.id_assegnazione
        WHERE precedente.id_assegnazione = :NEW.id_assegnazione
          AND precedente.stato_assegnazione = 'CONCLUSA'
          AND precedente.data_fine_effettiva IS NOT NULL
          AND successiva.id_volontario = precedente.id_volontario
          AND successiva.data_inizio > precedente.data_fine_effettiva;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20003,
                'La richiesta non puo essere approvata: la vecchia assegnazione deve essere conclusa e deve esistere una nuova assegnazione collegata correttamente.'
            );
        END IF;

    END IF;
END;

CREATE OR REPLACE TRIGGER check_presenza_assegnazione_attiva
BEFORE INSERT OR UPDATE OF id_assegnazione, data_servizio
ON REGISTRO_SERVIZIO
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM ASSEGNAZIONE
    WHERE id_assegnazione = :NEW.id_assegnazione
      AND stato_assegnazione = 'ATTIVA'
      AND :NEW.data_servizio >= data_inizio
      AND :NEW.data_servizio <= NVL(data_fine_effettiva, NVL(data_fine_prevista, DATE '9999-12-31'));

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20004,
            'La presenza puo essere registrata solo per una assegnazione attiva e valida nella data indicata.'
        );
    END IF;
END;

CREATE OR REPLACE TRIGGER check_permesso_straordinario_valido
BEFORE INSERT OR UPDATE OF tipo_giornata, note
ON REGISTRO_SERVIZIO
FOR EACH ROW
BEGIN
    IF :NEW.tipo_giornata = 'PERMESSO_STRAORDINARIO'
       AND (:NEW.note IS NULL OR TRIM(:NEW.note) IS NULL) THEN

        RAISE_APPLICATION_ERROR(
            -20009,
            'Il permesso straordinario richiede una motivazione valida nelle note.'
        );

    END IF;
END;

CREATE OR REPLACE TRIGGER check_limite_malattia_non_retribuita
FOR INSERT OR UPDATE ON REGISTRO_SERVIZIO
COMPOUND TRIGGER

    TYPE t_id_assegnazione IS TABLE OF REGISTRO_SERVIZIO.id_assegnazione%TYPE INDEX BY PLS_INTEGER;

    v_ids_assegnazione t_id_assegnazione;
    v_indice PLS_INTEGER := 0;

AFTER EACH ROW IS
BEGIN
    v_indice := v_indice + 1;
    v_ids_assegnazione(v_indice) := :NEW.id_assegnazione;
END AFTER EACH ROW;

AFTER STATEMENT IS
    v_totale_malattie NUMBER;
    v_max_malattie NUMBER;
BEGIN
    FOR i IN 1 .. v_indice LOOP

        SELECT COUNT(*)
        INTO v_totale_malattie
        FROM REGISTRO_SERVIZIO
        WHERE id_assegnazione = v_ids_assegnazione(i)
          AND tipo_giornata = 'MALATTIA_NON_RETRIBUITA';

        SELECT max_malattie_non_retribuite
        INTO v_max_malattie
        FROM ASSEGNAZIONE
        WHERE id_assegnazione = v_ids_assegnazione(i);

        IF v_totale_malattie > v_max_malattie THEN

            UPDATE ASSEGNAZIONE
            SET stato_assegnazione = 'DECADUTA',
                data_fine_effettiva = NVL(data_fine_effettiva, SYSDATE)
            WHERE id_assegnazione = v_ids_assegnazione(i)
              AND stato_assegnazione <> 'DECADUTA';

        END IF;

    END LOOP;
END AFTER STATEMENT;

END;

CREATE OR REPLACE TRIGGER check_limite_malattia_retribuita
FOR INSERT OR UPDATE ON REGISTRO_SERVIZIO
COMPOUND TRIGGER

    TYPE t_id_assegnazione IS TABLE OF REGISTRO_SERVIZIO.id_assegnazione%TYPE INDEX BY PLS_INTEGER;

    v_ids_assegnazione t_id_assegnazione;
    v_indice PLS_INTEGER := 0;

AFTER EACH ROW IS
BEGIN
    v_indice := v_indice + 1;
    v_ids_assegnazione(v_indice) := :NEW.id_assegnazione;
END AFTER EACH ROW;

AFTER STATEMENT IS
    v_totale_malattie NUMBER;
    v_max_malattie NUMBER;
BEGIN
    FOR i IN 1 .. v_indice LOOP

        SELECT COUNT(*)
        INTO v_totale_malattie
        FROM REGISTRO_SERVIZIO
        WHERE id_assegnazione = v_ids_assegnazione(i)
          AND tipo_giornata = 'MALATTIA_RETRIBUITA';

        SELECT max_malattie_retribuite
        INTO v_max_malattie
        FROM ASSEGNAZIONE
        WHERE id_assegnazione = v_ids_assegnazione(i);

        IF v_totale_malattie > v_max_malattie THEN

            UPDATE ASSEGNAZIONE
            SET stato_assegnazione = 'DECADUTA',
                data_fine_effettiva = NVL(data_fine_effettiva, SYSDATE)
            WHERE id_assegnazione = v_ids_assegnazione(i)
              AND stato_assegnazione <> 'DECADUTA';

        END IF;

    END LOOP;
END AFTER STATEMENT;

END;

CREATE OR REPLACE TRIGGER check_limite_permessi_ordinari
FOR INSERT OR UPDATE ON REGISTRO_SERVIZIO
COMPOUND TRIGGER

    TYPE t_id_assegnazione IS TABLE OF REGISTRO_SERVIZIO.id_assegnazione%TYPE INDEX BY PLS_INTEGER;

    v_ids_assegnazione t_id_assegnazione;
    v_indice PLS_INTEGER := 0;

AFTER EACH ROW IS
BEGIN
    v_indice := v_indice + 1;
    v_ids_assegnazione(v_indice) := :NEW.id_assegnazione;
END AFTER EACH ROW;

AFTER STATEMENT IS
    v_totale_permessi NUMBER;
    v_max_permessi NUMBER;
BEGIN
    FOR i IN 1 .. v_indice LOOP

        SELECT COUNT(*)
        INTO v_totale_permessi
        FROM REGISTRO_SERVIZIO
        WHERE id_assegnazione = v_ids_assegnazione(i)
          AND tipo_giornata = 'PERMESSO_ORDINARIO';

        SELECT max_permessi_ordinari
        INTO v_max_permessi
        FROM ASSEGNAZIONE
        WHERE id_assegnazione = v_ids_assegnazione(i);

        IF v_totale_permessi > v_max_permessi THEN

            UPDATE ASSEGNAZIONE
            SET stato_assegnazione = 'DECADUTA',
                data_fine_effettiva = NVL(data_fine_effettiva, SYSDATE)
            WHERE id_assegnazione = v_ids_assegnazione(i)
              AND stato_assegnazione <> 'DECADUTA';

        END IF;

    END LOOP;
END AFTER STATEMENT;

END;

CREATE OR REPLACE TRIGGER check_limite_ore_giornaliere
BEFORE INSERT OR UPDATE OF ore_svolte
ON REGISTRO_SERVIZIO
FOR EACH ROW
BEGIN
    IF :NEW.ore_svolte > 8 THEN
        :NEW.ore_svolte := 8;
    END IF;
END;

CREATE OR REPLACE TRIGGER check_monitoraggio_assegnazione_valida
BEFORE INSERT OR UPDATE OF id_assegnazione, data_monitoraggio
ON MONITORAGGIO
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM ASSEGNAZIONE
    WHERE id_assegnazione = :NEW.id_assegnazione
      AND :NEW.data_monitoraggio >= data_inizio
      AND :NEW.data_monitoraggio <= NVL(data_fine_effettiva, NVL(data_fine_prevista, DATE '9999-12-31'));

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20016,
            'Il monitoraggio deve riferirsi a una assegnazione esistente e coerente con il periodo del percorso.'
        );
    END IF;
END;

CREATE OR REPLACE TRIGGER check_coerenza_tipo_giornata_ore
BEFORE INSERT OR UPDATE OF tipo_giornata, ore_svolte
ON REGISTRO_SERVIZIO
FOR EACH ROW
BEGIN
    IF :NEW.tipo_giornata = 'SERVIZIO' AND :NEW.ore_svolte <= 0 THEN
        RAISE_APPLICATION_ERROR(
            -20017,
            'Una giornata di servizio deve avere un numero di ore maggiore di zero.'
        );

    ELSIF :NEW.tipo_giornata IN (
        'PERMESSO_ORDINARIO',
        'MALATTIA_RETRIBUITA',
        'MALATTIA_NON_RETRIBUITA',
        'PERMESSO_STRAORDINARIO'
    ) AND :NEW.ore_svolte <> 0 THEN
        RAISE_APPLICATION_ERROR(
            -20018,
            'Permessi e malattie devono avere ore_svolte pari a zero.'
        );
    END IF;
END;