# Changelog

Formato basato su [Keep a Changelog](https://keepachangelog.com/it/1.1.0/).

## [Non rilasciato]

### Sicurezza (Fase 2)
- Tabella `UTENTE_APPLICATIVO`: collega l'utente di database alla persona (volontario, operatore o amministratore).
- Viste `v_mie_*` per i volontari (solo i propri dati) e `v_volontari_mascherati` per gli operatori (codice fiscale, e-mail e telefono parzialmente oculati).
- `inserisci_presenza` accetta solo il volontario collegato all'utente connesso (`-20148`) e rifiuta operatori e utenti non registrati (`-20149`).
- Test di sicurezza eseguiti con utenti reali (`tests/test_sicurezza.sql`, 38 casi) e nota sul GDPR nel README.

### Modifiche che rompono la compatibilità
- `ruolo_volontario` non ha più accesso diretto alle tabelle `ASSEGNAZIONE`, `ASSEGNAZIONE_FORMAZIONE`, `MONITORAGGIO`, `RICHIESTA_VARIAZIONE` e `REGISTRO_SERVIZIO` (prima poteva leggere quelle di tutti e scrivere sul registro): usa le viste `v_mie_*`.
- `ruolo_operatore` non legge più `VOLONTARIO` in chiaro: usa `v_volontari_mascherati`.
- Gli utenti con ruolo di operatore o volontario vanno registrati in `UTENTE_APPLICATIVO`.

## [1.2.0] - 2026-10-17

### Aggiunto
- Lint SQL in CI con SQLFluff (`.sqlfluff`, `.sqlfluffignore`).
- Test di ogni trigger (successo e rifiuto) e delle regole sulle malattie retribuite e non retribuite: da 48 a 57 casi.
- Verifica automatica che `uninstall.sql` lasci lo schema e i ruoli vuoti e che la reinstallazione riesca (`tests/verifica_schema_vuoto.sql`).
- Badge e sezione "Esempio d'uso" nel README; roadmap in `docs/ROADMAP.md`.

### Modificato
- JOIN esplicite (`INNER JOIN`) nella vista e nelle query di esempio; newline finale in tutti i file SQL.

## [1.1.0] - 2026-10-16

### Aggiunto
- Le sei procedure descritte nella relazione ma assenti dal repository: `crea_progetto`, `modifica_progetto`, `crea_assegnazione`, `gestisci_richiesta_variazione`, `valida_presenza`, `inserisci_presenza`, più la funzione di supporto `parse_lista_sedi`. Riscritte nello stile delle altre (errori con `RAISE_APPLICATION_ERROR`, nessun `COMMIT`, ID da sequenze `seq_progetto`, `seq_assegnazione`, `seq_registro`).
- `crea_assegnazione` controlla anche i posti disponibili della coppia progetto-sede.
- Test: da 19 a 48 casi.

## [1.0.0] - 2026-10-16

### Aggiunto
- `install.sql` e `uninstall.sql` per installare/rimuovere l'intero database.
- Indici sulle chiavi esterne (`sql/01_schema/02_indexes.sql`).
- Sequenze `seq_formazione` e `seq_monitoraggio`.
- Vincolo `chk_conclusa_con_data_fine` su `ASSEGNAZIONE`.
- Ruoli `ruolo_amministratore`, `ruolo_operatore`, `ruolo_volontario`; `GRANT` su vista e procedure.
- Test dei vincoli e delle procedure in `tests/test_vincoli.sql` (19 casi).
- Query di esempio in `sql/07_queries/esempi.sql`.
- `docker-compose.yml`, `scripts/run-tests.sh` e workflow CI su Oracle Database Free.
- Documentazione delle regole di business, LICENSE (MIT), CHANGELOG.

### Modificato
- Le procedure non fanno più `COMMIT`/`ROLLBACK`: la transazione è del chiamante.
- `install.sql` carica il seed dopo i trigger.
- Struttura del repository riorganizzata in `sql/`, `docs/`, `tests/`.
- Aggiunti i terminatori `;` e `/` mancanti negli script.
- Gli ID di formazioni e monitoraggi usano sequenze invece di `MAX(id)+1` (race condition).
- I tre trigger sui limiti di assenza sono unificati in `check_limiti_assenze`.
- `data_fine_effettiva` in caso di decadenza usa `TRUNC(SYSDATE)`.

### Corretto
- Il trigger `check_presenza_assegnazione_attiva` rifiutava le giornate di assegnazioni concluse o decadute (6 righe del seed): ora controlla solo il periodo.
- Rimossa dalle procedure una copia della vista priva di terminatore, che rompeva l'esecuzione dei trigger successivi.
- Rimossa una riga di testo estraneo alla fine del seed delle assegnazioni.
- `install.sql` abilita `SQLBLANKLINES` (le righe vuote nelle istruzioni interrompevano SQL*Plus).

### Rimosso
- Definizione duplicata di `disattiva_progetto` (la seconda sovrascriveva la prima).
- Trigger `check_limite_ore_giornaliere`, che troncava silenziosamente le ore invece di rifiutarle (il CHECK della tabella resta).
- Utenti con password in chiaro in `Permessi.sql`.
