-- =============================================================================
-- Audit: registra chi ha inserito, modificato o cancellato assegnazioni, giornate del
-- registro di servizio e richieste di variazione (valori prima e dopo, utente, istante).
--
-- Si installa DOPO il caricamento dei dati di esempio: il registro parte pulito.
-- Il log fa parte della transazione dell'operazione: se questa viene annullata
-- (ROLLBACK), anche le righe di log vengono annullate.
-- =============================================================================

CREATE OR REPLACE TRIGGER audit_assegnazione
AFTER INSERT OR UPDATE OR DELETE ON ASSEGNAZIONE
FOR EACH ROW
DECLARE
    v_prima AUDIT_LOG.valori_prima%TYPE;
    v_dopo  AUDIT_LOG.valori_dopo%TYPE;
    v_op    AUDIT_LOG.operazione%TYPE;
BEGIN
    IF INSERTING THEN
        v_op := 'I';
    ELSIF UPDATING THEN
        v_op := 'U';
    ELSE
        v_op := 'D';
    END IF;

    IF INSERTING OR UPDATING THEN
        v_dopo := 'id_assegnazione=' || NVL(TO_CHAR(:NEW.id_assegnazione), 'NULL') ||
            '; id_volontario=' || NVL(TO_CHAR(:NEW.id_volontario), 'NULL') ||
            '; id_progetto=' || NVL(TO_CHAR(:NEW.id_progetto), 'NULL') ||
            '; id_sede=' || NVL(TO_CHAR(:NEW.id_sede), 'NULL') ||
            '; id_assegnazione_precedente=' || NVL(TO_CHAR(:NEW.id_assegnazione_precedente), 'NULL') ||
            '; data_inizio=' || NVL(TO_CHAR(:NEW.data_inizio, 'YYYY-MM-DD'), 'NULL') ||
            '; data_fine_prevista=' || NVL(TO_CHAR(:NEW.data_fine_prevista, 'YYYY-MM-DD'), 'NULL') ||
            '; data_fine_effettiva=' || NVL(TO_CHAR(:NEW.data_fine_effettiva, 'YYYY-MM-DD'), 'NULL') ||
            '; stato_assegnazione=' || NVL(TO_CHAR(:NEW.stato_assegnazione), 'NULL') ||
            '; ore_settimanali_previste=' || NVL(TO_CHAR(:NEW.ore_settimanali_previste), 'NULL') ||
            '; max_permessi_ordinari=' || NVL(TO_CHAR(:NEW.max_permessi_ordinari), 'NULL') ||
            '; max_malattie_retribuite=' || NVL(TO_CHAR(:NEW.max_malattie_retribuite), 'NULL') ||
            '; max_malattie_non_retribuite=' || NVL(TO_CHAR(:NEW.max_malattie_non_retribuite), 'NULL');
    END IF;

    IF UPDATING OR DELETING THEN
        v_prima := 'id_assegnazione=' || NVL(TO_CHAR(:OLD.id_assegnazione), 'NULL') ||
            '; id_volontario=' || NVL(TO_CHAR(:OLD.id_volontario), 'NULL') ||
            '; id_progetto=' || NVL(TO_CHAR(:OLD.id_progetto), 'NULL') ||
            '; id_sede=' || NVL(TO_CHAR(:OLD.id_sede), 'NULL') ||
            '; id_assegnazione_precedente=' || NVL(TO_CHAR(:OLD.id_assegnazione_precedente), 'NULL') ||
            '; data_inizio=' || NVL(TO_CHAR(:OLD.data_inizio, 'YYYY-MM-DD'), 'NULL') ||
            '; data_fine_prevista=' || NVL(TO_CHAR(:OLD.data_fine_prevista, 'YYYY-MM-DD'), 'NULL') ||
            '; data_fine_effettiva=' || NVL(TO_CHAR(:OLD.data_fine_effettiva, 'YYYY-MM-DD'), 'NULL') ||
            '; stato_assegnazione=' || NVL(TO_CHAR(:OLD.stato_assegnazione), 'NULL') ||
            '; ore_settimanali_previste=' || NVL(TO_CHAR(:OLD.ore_settimanali_previste), 'NULL') ||
            '; max_permessi_ordinari=' || NVL(TO_CHAR(:OLD.max_permessi_ordinari), 'NULL') ||
            '; max_malattie_retribuite=' || NVL(TO_CHAR(:OLD.max_malattie_retribuite), 'NULL') ||
            '; max_malattie_non_retribuite=' || NVL(TO_CHAR(:OLD.max_malattie_non_retribuite), 'NULL');
    END IF;

    INSERT INTO AUDIT_LOG (id_audit, tabella, chiave, operazione, utente, valori_prima, valori_dopo)
    VALUES (
        seq_audit.NEXTVAL,
        'ASSEGNAZIONE',
        TO_CHAR(NVL(:NEW.id_assegnazione, :OLD.id_assegnazione)),
        v_op,
        SYS_CONTEXT('USERENV', 'SESSION_USER'),
        v_prima,
        v_dopo
    );
END;
/

CREATE OR REPLACE TRIGGER audit_registro_servizio
AFTER INSERT OR UPDATE OR DELETE ON REGISTRO_SERVIZIO
FOR EACH ROW
DECLARE
    v_prima AUDIT_LOG.valori_prima%TYPE;
    v_dopo  AUDIT_LOG.valori_dopo%TYPE;
    v_op    AUDIT_LOG.operazione%TYPE;
BEGIN
    IF INSERTING THEN
        v_op := 'I';
    ELSIF UPDATING THEN
        v_op := 'U';
    ELSE
        v_op := 'D';
    END IF;

    IF INSERTING OR UPDATING THEN
        v_dopo := 'id_registro=' || NVL(TO_CHAR(:NEW.id_registro), 'NULL') ||
            '; id_assegnazione=' || NVL(TO_CHAR(:NEW.id_assegnazione), 'NULL') ||
            '; data_servizio=' || NVL(TO_CHAR(:NEW.data_servizio, 'YYYY-MM-DD'), 'NULL') ||
            '; tipo_giornata=' || NVL(TO_CHAR(:NEW.tipo_giornata), 'NULL') ||
            '; ore_svolte=' || NVL(TO_CHAR(:NEW.ore_svolte, 'TM', 'NLS_NUMERIC_CHARACTERS=''.,'''), 'NULL') ||
            '; ore_da_recuperare=' || NVL(TO_CHAR(:NEW.ore_da_recuperare, 'TM', 'NLS_NUMERIC_CHARACTERS=''.,'''), 'NULL') ||
            '; stato_validazione=' || NVL(TO_CHAR(:NEW.stato_validazione), 'NULL') ||
            '; note=' || NVL(TO_CHAR(:NEW.note), 'NULL');
    END IF;

    IF UPDATING OR DELETING THEN
        v_prima := 'id_registro=' || NVL(TO_CHAR(:OLD.id_registro), 'NULL') ||
            '; id_assegnazione=' || NVL(TO_CHAR(:OLD.id_assegnazione), 'NULL') ||
            '; data_servizio=' || NVL(TO_CHAR(:OLD.data_servizio, 'YYYY-MM-DD'), 'NULL') ||
            '; tipo_giornata=' || NVL(TO_CHAR(:OLD.tipo_giornata), 'NULL') ||
            '; ore_svolte=' || NVL(TO_CHAR(:OLD.ore_svolte, 'TM', 'NLS_NUMERIC_CHARACTERS=''.,'''), 'NULL') ||
            '; ore_da_recuperare=' || NVL(TO_CHAR(:OLD.ore_da_recuperare, 'TM', 'NLS_NUMERIC_CHARACTERS=''.,'''), 'NULL') ||
            '; stato_validazione=' || NVL(TO_CHAR(:OLD.stato_validazione), 'NULL') ||
            '; note=' || NVL(TO_CHAR(:OLD.note), 'NULL');
    END IF;

    INSERT INTO AUDIT_LOG (id_audit, tabella, chiave, operazione, utente, valori_prima, valori_dopo)
    VALUES (
        seq_audit.NEXTVAL,
        'REGISTRO_SERVIZIO',
        TO_CHAR(NVL(:NEW.id_registro, :OLD.id_registro)),
        v_op,
        SYS_CONTEXT('USERENV', 'SESSION_USER'),
        v_prima,
        v_dopo
    );
END;
/

CREATE OR REPLACE TRIGGER audit_richiesta_variazione
AFTER INSERT OR UPDATE OR DELETE ON RICHIESTA_VARIAZIONE
FOR EACH ROW
DECLARE
    v_prima AUDIT_LOG.valori_prima%TYPE;
    v_dopo  AUDIT_LOG.valori_dopo%TYPE;
    v_op    AUDIT_LOG.operazione%TYPE;
BEGIN
    IF INSERTING THEN
        v_op := 'I';
    ELSIF UPDATING THEN
        v_op := 'U';
    ELSE
        v_op := 'D';
    END IF;

    IF INSERTING OR UPDATING THEN
        v_dopo := 'id_richiesta=' || NVL(TO_CHAR(:NEW.id_richiesta), 'NULL') ||
            '; id_assegnazione=' || NVL(TO_CHAR(:NEW.id_assegnazione), 'NULL') ||
            '; data_richiesta=' || NVL(TO_CHAR(:NEW.data_richiesta, 'YYYY-MM-DD'), 'NULL') ||
            '; tipo_variazione=' || NVL(TO_CHAR(:NEW.tipo_variazione), 'NULL') ||
            '; motivazione=' || NVL(TO_CHAR(:NEW.motivazione), 'NULL') ||
            '; stato_richiesta=' || NVL(TO_CHAR(:NEW.stato_richiesta), 'NULL') ||
            '; data_validazione=' || NVL(TO_CHAR(:NEW.data_validazione, 'YYYY-MM-DD'), 'NULL');
    END IF;

    IF UPDATING OR DELETING THEN
        v_prima := 'id_richiesta=' || NVL(TO_CHAR(:OLD.id_richiesta), 'NULL') ||
            '; id_assegnazione=' || NVL(TO_CHAR(:OLD.id_assegnazione), 'NULL') ||
            '; data_richiesta=' || NVL(TO_CHAR(:OLD.data_richiesta, 'YYYY-MM-DD'), 'NULL') ||
            '; tipo_variazione=' || NVL(TO_CHAR(:OLD.tipo_variazione), 'NULL') ||
            '; motivazione=' || NVL(TO_CHAR(:OLD.motivazione), 'NULL') ||
            '; stato_richiesta=' || NVL(TO_CHAR(:OLD.stato_richiesta), 'NULL') ||
            '; data_validazione=' || NVL(TO_CHAR(:OLD.data_validazione, 'YYYY-MM-DD'), 'NULL');
    END IF;

    INSERT INTO AUDIT_LOG (id_audit, tabella, chiave, operazione, utente, valori_prima, valori_dopo)
    VALUES (
        seq_audit.NEXTVAL,
        'RICHIESTA_VARIAZIONE',
        TO_CHAR(NVL(:NEW.id_richiesta, :OLD.id_richiesta)),
        v_op,
        SYS_CONTEXT('USERENV', 'SESSION_USER'),
        v_prima,
        v_dopo
    );
END;
/
