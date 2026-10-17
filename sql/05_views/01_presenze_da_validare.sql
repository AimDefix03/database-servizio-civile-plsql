-- =============================================================================
-- Vista: registrazioni di servizio ancora da validare, con dati del volontario
-- =============================================================================

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
INNER JOIN ASSEGNAZIONE a
    ON rs.id_assegnazione = a.id_assegnazione
INNER JOIN VOLONTARIO v
    ON a.id_volontario = v.id_volontario
WHERE rs.stato_validazione = 'DA_VALIDARE';
