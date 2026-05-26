# DB Servizio Civile

Progetto universitario di basi di dati per la gestione amministrativa del Servizio Civile.

## Descrizione

Il progetto modella un sistema informativo per enti, sedi, progetti, volontari, operatori, assegnazioni, formazione, monitoraggio, registro di servizio e richieste di variazione.

Il database è pensato per gestire:

- anagrafica di enti, sedi, operatori e volontari;
- progetti e sedi collegate;
- assegnazioni dei volontari ai progetti;
- registro giornaliero del servizio;
- formazione e partecipazioni;
- monitoraggi;
- richieste di variazione;
- vincoli applicativi tramite trigger;
- procedure PL/SQL per operazioni gestionali;
- viste e permessi utente.

## Tecnologie

- Oracle SQL
- PL/SQL
- Modellazione ER
- Diagramma relazionale
- Diagramma dei casi d'uso

## Struttura del progetto

```text
DB_ServizioCivile/
├── CreateTable/
│   └── CreateTable.sql
├── InsertInto/
│   ├── 1_InsertIntoEnte.sql
│   ├── 2_InsertIntoSede.sql
│   ├── 3_InsertIntoProgetto.sql
│   ├── 4_InsertIntoOperatore.sql
│   ├── 5_InsertIntoVolontario.sql
│   ├── 6_InsertIntoProgettoSede.sql
│   ├── 7_InsertIntoFormazione.sql
│   ├── 8_InsertIntoAssegnazione.sql
│   ├── 9_InsertIntoAssegnazione_Formazione.sql
│   ├── 10_InsertIntoRegistroServizio.sql
│   ├── 11_InsertIntoMonitoraggio.sql
│   └── 12_InsertIntoRichiestaVariazione.sql
├── Procedure/
│   └── Procedure.sql
├── Trigger/
│   └── Trigger.sql
├── Viste/
│   └── Vista_Presenze_Da_Validare.sql
├── Permessi/
│   └── Permessi.sql
├── Diagrammi/
│   ├── DiagrammaER/
│   ├── DiagrammaRelazionale/
│   └── Diagramma_Casi_Uso/
└── Relazione/
    └── RelazioneDB_Servizio_Civile.pdf
```

## Ordine consigliato di esecuzione degli script

1. `CreateTable/CreateTable.sql`
2. Script nella cartella `InsertInto`, seguendo l'ordine numerico dei file
3. `Procedure/Procedure.sql`
4. `Trigger/Trigger.sql`
5. `Viste/Vista_Presenze_Da_Validare.sql`
6. `Permessi/Permessi.sql`

## Contenuto principale

- 12 tabelle principali
- script di popolamento dati
- procedure PL/SQL per operazioni gestionali
- trigger per il controllo dei vincoli applicativi
- vista per le presenze da validare
- script di gestione permessi
- diagrammi progettuali
- relazione finale in PDF

## Nota

Prima dell'esecuzione in ambiente Oracle, verificare la sintassi richiesta dal client utilizzato, in particolare la terminazione delle istruzioni SQL e PL/SQL.
