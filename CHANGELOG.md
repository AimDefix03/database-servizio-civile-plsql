# Changelog

Formato basato su [Keep a Changelog](https://keepachangelog.com/it/1.1.0/).

## [Non rilasciato]

### Aggiunto
- `install.sql` e `uninstall.sql` per installare/rimuovere l'intero database.
- Indici sulle chiavi esterne (`sql/01_schema/02_indexes.sql`).
- Sequenze `seq_formazione` e `seq_monitoraggio`.
- Vincolo `chk_conclusa_con_data_fine` su `ASSEGNAZIONE`.
- Ruoli `ruolo_amministratore`, `ruolo_operatore`, `ruolo_volontario`; `GRANT` su vista e procedure.
- Test dei vincoli in `tests/test_vincoli.sql`.
- `docker-compose.yml`, `scripts/run-tests.sh` e workflow CI su Oracle Database Free.
- Documentazione delle regole di business, LICENSE (MIT), CHANGELOG.

### Modificato
- Struttura del repository riorganizzata in `sql/`, `docs/`, `tests/`.
- Aggiunti i terminatori `;` e `/` mancanti negli script.
- Gli ID di formazioni e monitoraggi usano sequenze invece di `MAX(id)+1` (race condition).
- I tre trigger sui limiti di assenza sono unificati in `check_limiti_assenze`.
- `data_fine_effettiva` in caso di decadenza usa `TRUNC(SYSDATE)`.

### Corretto
- Rimossa dalle procedure una copia della vista priva di terminatore, che rompeva l'esecuzione dei trigger successivi.
- Rimossa una riga di testo estraneo alla fine del seed delle assegnazioni.
- `install.sql` abilita `SQLBLANKLINES` (le righe vuote nelle istruzioni interrompevano SQL*Plus).

### Rimosso
- Definizione duplicata di `disattiva_progetto` (la seconda sovrascriveva la prima).
- Trigger `check_limite_ore_giornaliere`, che troncava silenziosamente le ore invece di rifiutarle (il CHECK della tabella resta).
- Utenti con password in chiaro in `Permessi.sql`.
