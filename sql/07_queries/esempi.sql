-- =============================================================================
-- Query di esempio (sola lettura). Non fanno parte di install.sql.
-- =============================================================================

-- 1) Volontari attivi per progetto e sede
SELECT p.titolo AS progetto, s.nome_sede AS sede, v.cognome, v.nome, a.data_inizio
FROM ASSEGNAZIONE a
INNER JOIN VOLONTARIO v ON v.id_volontario = a.id_volontario
INNER JOIN PROGETTO p   ON p.id_progetto   = a.id_progetto
INNER JOIN SEDE s       ON s.id_sede       = a.id_sede
WHERE a.stato_assegnazione = 'ATTIVA'
ORDER BY p.titolo, s.nome_sede, v.cognome;

-- 2) Posti liberi per progetto e sede (posti disponibili - assegnazioni attive)
SELECT p.titolo AS progetto, s.nome_sede AS sede, ps.posti_disponibili,
       COUNT(a.id_assegnazione) AS occupati,
       ps.posti_disponibili - COUNT(a.id_assegnazione) AS liberi
FROM PROGETTO_SEDE ps
INNER JOIN PROGETTO p ON p.id_progetto = ps.id_progetto
INNER JOIN SEDE s     ON s.id_sede     = ps.id_sede
LEFT JOIN ASSEGNAZIONE a
       ON a.id_progetto = ps.id_progetto AND a.id_sede = ps.id_sede
      AND a.stato_assegnazione = 'ATTIVA'
GROUP BY p.titolo, s.nome_sede, ps.posti_disponibili
ORDER BY liberi;

-- 3) Ore di servizio svolte per assegnazione (solo giornate validate)
SELECT a.id_assegnazione, v.cognome, v.nome,
       SUM(r.ore_svolte) AS ore_validate,
       SUM(r.ore_da_recuperare) AS ore_da_recuperare
FROM REGISTRO_SERVIZIO r
INNER JOIN ASSEGNAZIONE a ON a.id_assegnazione = r.id_assegnazione
INNER JOIN VOLONTARIO v   ON v.id_volontario   = a.id_volontario
WHERE r.stato_validazione = 'VALIDATA'
GROUP BY a.id_assegnazione, v.cognome, v.nome
ORDER BY ore_validate DESC;

-- 4) Permessi e malattie residui per assegnazione attiva
SELECT a.id_assegnazione, v.cognome, v.nome,
       a.max_permessi_ordinari - COUNT(CASE WHEN r.tipo_giornata = 'PERMESSO_ORDINARIO' THEN 1 END) AS permessi_residui,
       a.max_malattie_retribuite - COUNT(CASE WHEN r.tipo_giornata = 'MALATTIA_RETRIBUITA' THEN 1 END) AS malattie_retr_residue,
       a.max_malattie_non_retribuite - COUNT(CASE WHEN r.tipo_giornata = 'MALATTIA_NON_RETRIBUITA' THEN 1 END) AS malattie_non_retr_residue
FROM ASSEGNAZIONE a
INNER JOIN VOLONTARIO v ON v.id_volontario = a.id_volontario
LEFT JOIN REGISTRO_SERVIZIO r ON r.id_assegnazione = a.id_assegnazione
WHERE a.stato_assegnazione = 'ATTIVA'
GROUP BY a.id_assegnazione, v.cognome, v.nome,
         a.max_permessi_ordinari, a.max_malattie_retribuite, a.max_malattie_non_retribuite;

-- 5) Ore di formazione frequentate per volontario
SELECT v.cognome, v.nome, SUM(af.ore_frequentate) AS ore_formazione
FROM ASSEGNAZIONE_FORMAZIONE af
INNER JOIN ASSEGNAZIONE a ON a.id_assegnazione = af.id_assegnazione
INNER JOIN VOLONTARIO v   ON v.id_volontario   = a.id_volontario
GROUP BY v.cognome, v.nome
ORDER BY ore_formazione DESC;

-- 6) Monitoraggi con esito critico o negativo
SELECT m.data_monitoraggio, m.tipo_monitoraggio, m.esito, v.cognome, v.nome, m.note
FROM MONITORAGGIO m
INNER JOIN ASSEGNAZIONE a ON a.id_assegnazione = m.id_assegnazione
INNER JOIN VOLONTARIO v   ON v.id_volontario   = a.id_volontario
WHERE m.esito IN ('CRITICO', 'NEGATIVO')
ORDER BY m.data_monitoraggio;

-- 7) Giornate da validare (vista)
SELECT * FROM Presenze_Da_Validare ORDER BY data_servizio; -- noqa: AM04
