# DB Servizio Civile

Database Oracle per la gestione amministrativa del Servizio Civile: enti, sedi, progetti, volontari, assegnazioni, registro di servizio, formazione, monitoraggi e variazioni di percorso. Le regole di business sono applicate direttamente dal database tramite vincoli, trigger e procedure PL/SQL.

![Diagramma ER](docs/diagrammi/diagramma_er.png)

## Funzionalità

- **Anagrafiche**: enti, sedi, operatori (OLP, coordinatori, amministrativi), volontari.
- **Progetti e posti**: progetti collegati alle sedi con posti disponibili.
- **Assegnazioni**: percorso del volontario con storico delle variazioni (sede/progetto) e controllo delle sovrapposizioni.
- **Registro di servizio**: ore svolte, permessi e malattie con limiti configurabili; decadenza automatica al superamento.
- **Formazione e monitoraggio**: eventi formativi, partecipazioni, monitoraggi iniziali/intermedi/finali.
- **Sicurezza**: tre ruoli con privilegi minimi (amministratore, operatore, volontario).

Elenco completo delle regole in [docs/regole_di_business.md](docs/regole_di_business.md).

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

## Test

```bash
sqlplus utente/password@//host:1521/servizio @tests/test_vincoli.sql
```

I test verificano il rifiuto delle operazioni non valide e la decadenza automatica, poi eseguono un `ROLLBACK`.

## Struttura

```text
.
├── install.sql / uninstall.sql
├── sql/
│   ├── 01_schema/        tabelle e indici
│   ├── 02_seed/          dati di esempio (fittizi)
│   ├── 03_procedures/    procedure PL/SQL
│   ├── 04_triggers/      vincoli applicativi
│   ├── 05_views/         viste
│   └── 06_security/      ruoli e privilegi
├── tests/                test dei vincoli
└── docs/                 relazione, diagrammi, regole di business
```

## Documentazione

- [Regole di business](docs/regole_di_business.md)
- [Relazione completa (PDF)](docs/relazione.pdf)
- Diagrammi: [ER](docs/diagrammi/diagramma_er.png) · [relazionale](docs/diagrammi/diagramma_relazionale.png) · [casi d'uso](docs/diagrammi/diagramma_casi_uso.png)

## Dati di esempio

I dati in `sql/02_seed/` sono interamente fittizi (nomi, codici fiscali ed e-mail inventati). Gli ID inferiori a 1000 sono riservati al seed; le sequenze generano da 1000 in poi.

## Licenza

[MIT](LICENSE)
