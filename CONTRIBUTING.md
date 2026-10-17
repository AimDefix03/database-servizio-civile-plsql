# Contribuire

Grazie per l'interesse. Il progetto è un database Oracle (schema, PL/SQL, test) e si lavora con poche regole.

## Prerequisiti

- Docker (per l'Oracle Database Free usato dai test)
- Python 3 (per il linter e per il generatore della documentazione)
- `pip install sqlfluff==4.4.0`

## Flusso di lavoro

1. Crea un branch dal ramo `main` (`feat/...`, `fix/...`, `docs/...`).
2. Fai le modifiche. Ogni cambiamento di comportamento va accompagnato da un test.
3. Verifica in locale:

   ```bash
   docker compose up -d --wait
   scripts/run-tests.sh            # installazione, test, sicurezza, disinstallazione
   scripts/genera-documentazione.sh
   sqlfluff lint .
   ```

4. Apri una pull request. La CI esegue gli stessi controlli: lint, test su Oracle e verifica che la documentazione sia allineata.

## Regole del progetto

- **Struttura degli script.** Schema in `sql/01_schema`, seed in `sql/02_seed`, procedure in `sql/03_procedures`, trigger in `sql/04_triggers`, viste in `sql/05_views`, sicurezza in `sql/06_security`. Gli script si eseguono tramite `install.sql`: aggiungi i nuovi file lì, nell'ordine corretto, e in `uninstall.sql` gli oggetti nuovi.
- **Errori.** Le procedure segnalano gli errori con `RAISE_APPLICATION_ERROR` in una fascia di codici propria (vedi [docs/regole_di_business.md](docs/regole_di_business.md)); non devono usare i codici di un'altra procedura o di un trigger.
- **Transazioni.** Nessun `COMMIT` né `ROLLBACK` dentro le procedure: la transazione è del chiamante.
- **Sicurezza.** Un nuovo oggetto non è accessibile a nessun ruolo finché non lo concedi esplicitamente in `sql/06_security/01_security.sql`. Non dare ai volontari l'accesso diretto a tabelle con dati di persone: usa viste filtrate.
- **Documentazione.** Ogni nuova tabella o colonna ha un commento in `sql/01_schema/03_commenti.sql`. Il dizionario dei dati e il diagramma ER in `docs/` sono generati: non modificarli a mano, rigenerali.
- **Dati di esempio.** Solo dati fittizi. Non aggiungere mai dati reali di persone.
- **Test.** Vincoli e procedure in `tests/test_vincoli.sql`; regole di accesso in `tests/test_sicurezza.sql`. Ogni regola nuova ha almeno un caso di rifiuto e uno di successo.
- **CHANGELOG.** Aggiungi le modifiche sotto "Non rilasciato", segnalando in evidenza quelle che rompono la compatibilità.

## Messaggi di commit

Una riga di sintesi all'imperativo (`Aggiunge...`, `Corregge...`), poi, se serve, un elenco dei motivi.

## Segnalare un problema

Usa i modelli di issue. Per una vulnerabilità o un dato personale esposto non aprire una issue pubblica: contatta direttamente il maintainer del repository.
