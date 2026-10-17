# DB Servizio Civile

[![CI](https://github.com/AimDefix03/database-servizio-civile-plsql/actions/workflows/ci.yml/badge.svg)](https://github.com/AimDefix03/database-servizio-civile-plsql/actions/workflows/ci.yml)
[![Licenza: MIT](https://img.shields.io/badge/licenza-MIT-blue.svg)](LICENSE)
[![Ultima release](https://img.shields.io/github/v/release/AimDefix03/database-servizio-civile-plsql)](https://github.com/AimDefix03/database-servizio-civile-plsql/releases)

Database Oracle per la gestione amministrativa del Servizio Civile: enti, sedi, progetti, volontari, assegnazioni, registro di servizio, formazione, monitoraggi e variazioni di percorso. Le regole di business sono applicate direttamente dal database tramite vincoli, trigger e procedure PL/SQL.

![Diagramma ER](docs/diagrammi/diagramma_er.png)

## Funzionalità

- **Anagrafiche**: enti, sedi, operatori (OLP, coordinatori, amministrativi), volontari.
- **Progetti e posti**: progetti collegati alle sedi con posti disponibili.
- **Assegnazioni**: percorso del volontario con storico delle variazioni (sede/progetto) e controllo delle sovrapposizioni.
- **Registro di servizio**: ore svolte, permessi e malattie con limiti configurabili; decadenza automatica al superamento.
- **Formazione e monitoraggio**: eventi formativi, partecipazioni, monitoraggi iniziali/intermedi/finali.
- **Sicurezza**: tre ruoli con privilegi minimi (amministratore, operatore, volontario).

Esempi di interrogazione (posti liberi, ore svolte, permessi residui...) in [sql/07_queries/esempi.sql](sql/07_queries/esempi.sql). Elenco completo delle regole in [docs/regole_di_business.md](docs/regole_di_business.md).

## Requisiti

- Oracle Database 12c o superiore (es. Oracle XE)
- SQL*Plus o SQLcl
- Un utente/schema con i privilegi `CREATE TABLE`, `SEQUENCE`, `VIEW`, `PROCEDURE`, `TRIGGER`, `ROLE`

## Installazione

Dalla radice del repository:

```bash
sqlplus utente/password@//host:1521/servizio @install.sql
```

Per rimuovere tutto: `@uninstall.sql`.

Se non hai un'istanza Oracle, ne puoi avviare una locale con Docker (`docker compose up -d --wait`, utente `sc`, servizio `FREEPDB1`, porta 1521; credenziali in `docker-compose.yml`, solo per uso locale).

## Esempio d'uso

Dopo `@install.sql`, da SQL*Plus o SQLcl:

```sql
SET SERVEROUTPUT ON

-- Un amministratore crea un progetto collegato alle sedi 1 e 2 (4 posti ciascuna)
EXEC crea_progetto(1, 'Orto sociale', 'AMBIENTE', 'Cura di spazi verdi condivisi', DATE '2026-03-01', NULL, 'ATTIVO', '1,2', 4);
-- Progetto creato con successo. ID progetto: 1000

-- Un volontario registra una giornata di servizio (stato iniziale DA_VALIDARE)
EXEC inserisci_presenza(1, DATE '2025-07-01', 'SERVIZIO', 6, 0);
-- Presenza registrata con successo. ID registro: 1000

-- Registrare di nuovo la stessa giornata viene rifiutato dal database
EXEC inserisci_presenza(1, DATE '2025-07-01', 'SERVIZIO', 6, 0);
-- ORA-20146: Esiste già una presenza per questa assegnazione e questa data.

-- Le giornate in attesa di validazione
SELECT * FROM Presenze_Da_Validare;
```

Le procedure non fanno `COMMIT`: confermare con `COMMIT` oppure annullare con `ROLLBACK`. Altre interrogazioni in [sql/07_queries/esempi.sql](sql/07_queries/esempi.sql).

## Test

```bash
docker compose up -d --wait
scripts/run-tests.sh
```

Lo script installa il database nel container, lancia `tests/test_vincoli.sql`, poi verifica che `uninstall.sql` lasci lo schema vuoto e che la reinstallazione riesca. I test sono 57 casi sui vincoli (ogni trigger e ogni procedura ha almeno un caso di rifiuto e uno di successo) e 38 casi di sicurezza eseguiti con utenti reali (volontario, altro volontario, operatore, utente non registrato), e annullano le modifiche con un `ROLLBACK`. Gli stessi passi girano in CI a ogni push ([workflow](.github/workflows/ci.yml)). Testato su Oracle Database Free 23ai.

## Sicurezza e protezione dei dati

- **Ruoli con privilegio minimo.** `ruolo_amministratore`, `ruolo_operatore` e `ruolo_volontario` non hanno accesso diretto alle tabelle con dati di persone, salvo l'amministratore.
- **Volontari.** Leggono soltanto i propri dati, tramite le viste `v_mie_*`, e registrano le presenze con `inserisci_presenza`, che accetta solo il proprio identificativo.
- **Operatori.** Vedono i volontari tramite `v_volontari_mascherati`: codice fiscale, e-mail e telefono sono parzialmente oculati.
- **Mappatura utenti.** Le viste e `inserisci_presenza` riconoscono la persona dall'utente di database connesso tramite la tabella `UTENTE_APPLICATIVO`. Un utente non registrato non vede dati personali e non può registrare presenze. Esempio:

  ```sql
  INSERT INTO UTENTE_APPLICATIVO (username, tipo_utente, id_volontario)
  VALUES ('MARIO_ROSSI', 'VOLONTARIO', 1);   -- username in maiuscolo
  ```

**Nota sul GDPR.** I dati di esempio sono interamente fittizi. Lo schema contiene dati personali (anagrafiche di volontari e operatori) e questo repository **non è pensato per ospitare dati reali** senza le misure che un trattamento reale richiede: base giuridica, informativa, registro dei trattamenti, conservazione limitata, cifratura a riposo e in transito, gestione degli accessi e degli incidenti. Le misure qui descritte limitano l'esposizione dei dati nel database ma non sostituiscono una valutazione di conformità.

## Struttura

```text
.
├── install.sql / uninstall.sql
├── docker-compose.yml        Oracle Free per sviluppo locale
├── scripts/run-tests.sh      installazione + test in container
├── .github/workflows/ci.yml  CI
├── sql/
│   ├── 01_schema/        tabelle e indici
│   ├── 02_seed/          dati di esempio (fittizi)
│   ├── 03_procedures/    procedure PL/SQL
│   ├── 04_triggers/      vincoli applicativi
│   ├── 05_views/         viste (anche quelle di sicurezza)
│   ├── 06_security/      ruoli e privilegi
│   └── 07_queries/       query di esempio (sola lettura)
├── tests/                test dei vincoli
└── docs/                 relazione, diagrammi, regole di business
```

## Documentazione

- [Regole di business](docs/regole_di_business.md)
- [Roadmap](docs/ROADMAP.md)
- [Relazione completa (PDF)](docs/relazione.pdf): documento di progetto della versione accademica originale (Università Parthenope, corso di Basi di Dati e Laboratorio). Dopo la consegna gli script sono stati rivisti (ruoli al posto degli utenti, trigger unificati, sequenze, indici): per lo stato attuale fanno fede il codice e il [CHANGELOG](CHANGELOG.md). L'ultima pagina del PDF riassume le modifiche successive alla consegna.
- Diagrammi: [ER](docs/diagrammi/diagramma_er.png) · [relazionale](docs/diagrammi/diagramma_relazionale.png) · [casi d'uso](docs/diagrammi/diagramma_casi_uso.png)

## Dati di esempio

I dati in `sql/02_seed/` sono interamente fittizi (nomi, codici fiscali ed e-mail inventati). Il seed viene caricato con i trigger attivi, quindi ogni installazione ne verifica la coerenza. Gli ID inferiori a 1000 sono riservati al seed; le sequenze generano da 1000 in poi.

## Licenza

[MIT](LICENSE)
