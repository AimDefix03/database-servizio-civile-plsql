-- =============================================================================
-- Viste di sicurezza
--  * v_volontari_mascherati: anagrafica senza dati personali in chiaro (per gli operatori)
--  * v_mie_*: i soli dati del volontario collegato all'utente connesso (UTENTE_APPLICATIVO)
-- Le viste girano con i diritti del proprietario: i ruoli non hanno accesso diretto alle tabelle.
-- Le colonne sono elencate esplicitamente: una colonna aggiunta in futuro a una tabella
-- non diventa visibile ai volontari senza una decisione esplicita.
-- =============================================================================

CREATE OR REPLACE VIEW v_volontari_mascherati AS
SELECT
    id_volontario,
    nome,
    cognome,
    SUBSTR(codice_fiscale, 1, 3)
        || RPAD('*', GREATEST(LENGTH(codice_fiscale) - 6, 0), '*')
        || SUBSTR(codice_fiscale, -3) AS codice_fiscale,
    SUBSTR(email, 1, 1) || '***' || SUBSTR(email, INSTR(email, '@')) AS email,
    CASE
        WHEN telefono IS NULL THEN NULL
        ELSE RPAD('*', GREATEST(LENGTH(telefono) - 3, 0), '*') || SUBSTR(telefono, -3)
    END AS telefono,
    comune_residenza,
    stato_volontario
FROM VOLONTARIO;

CREATE OR REPLACE VIEW v_mie_assegnazioni AS
SELECT
    a.id_assegnazione,
    a.id_volontario,
    a.id_progetto,
    a.id_sede,
    a.id_assegnazione_precedente,
    a.data_inizio,
    a.data_fine_prevista,
    a.data_fine_effettiva,
    a.stato_assegnazione,
    a.ore_settimanali_previste,
    a.max_permessi_ordinari,
    a.max_malattie_retribuite,
    a.max_malattie_non_retribuite
FROM ASSEGNAZIONE a
INNER JOIN UTENTE_APPLICATIVO u ON u.id_volontario = a.id_volontario
WHERE u.tipo_utente = 'VOLONTARIO'
  AND u.username = SYS_CONTEXT('USERENV', 'SESSION_USER');

CREATE OR REPLACE VIEW v_mio_registro AS
SELECT
    r.id_registro,
    r.id_assegnazione,
    r.data_servizio,
    r.tipo_giornata,
    r.ore_svolte,
    r.ore_da_recuperare,
    r.stato_validazione,
    r.note
FROM REGISTRO_SERVIZIO r
INNER JOIN v_mie_assegnazioni a ON a.id_assegnazione = r.id_assegnazione;

CREATE OR REPLACE VIEW v_mie_partecipazioni_formazione AS
SELECT
    af.id_assegnazione,
    af.id_formazione,
    af.presenza,
    af.ore_frequentate,
    af.note_partecipazione
FROM ASSEGNAZIONE_FORMAZIONE af
INNER JOIN v_mie_assegnazioni a ON a.id_assegnazione = af.id_assegnazione;

CREATE OR REPLACE VIEW v_miei_monitoraggi AS
SELECT
    m.id_monitoraggio,
    m.id_assegnazione,
    m.data_monitoraggio,
    m.tipo_monitoraggio,
    m.esito,
    m.note
FROM MONITORAGGIO m
INNER JOIN v_mie_assegnazioni a ON a.id_assegnazione = m.id_assegnazione;

CREATE OR REPLACE VIEW v_mie_richieste_variazione AS
SELECT
    rv.id_richiesta,
    rv.id_assegnazione,
    rv.data_richiesta,
    rv.tipo_variazione,
    rv.motivazione,
    rv.stato_richiesta,
    rv.data_validazione
FROM RICHIESTA_VARIAZIONE rv
INNER JOIN v_mie_assegnazioni a ON a.id_assegnazione = rv.id_assegnazione;
