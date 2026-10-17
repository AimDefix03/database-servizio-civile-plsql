# Roadmap

Stato di partenza: **v1.1.0**. Schema, 10 procedure, trigger, ruoli, 48 test e CI su Oracle Database Free.

Ogni fase si chiude con una release, il CHANGELOG aggiornato e la CI verde.
Alla fine di ogni fase si decide se proseguire: la roadmap è un impegno a procedere per passi, non a completare tutto.

## Fase 1 · Qualità e visibilità (v1.2.0)

Obiettivo: rendere verificabile e leggibile ciò che già c'è.

- [ ] **Lint SQL in CI** con SQLFluff (dialetto Oracle), con regole limitate se i falsi positivi sono troppi
- [ ] **Test completi sui trigger**: un caso dedicato per ciascun trigger, incluse malattie retribuite e non retribuite e `check_progetto_sede_assegnazione` in aggiornamento
- [ ] **Test di `uninstall.sql`**: dopo la disinstallazione lo schema è vuoto e `install.sql` si può rieseguire
- [ ] **Badge nel README** (CI, licenza, ultima release)
- [ ] **Esempio d'uso** nel README: sessione completa dall'installazione a un caso reale

Completata quando: CI con lint e test verdi, ogni trigger ha almeno un caso di rifiuto e uno di successo, README con badge ed esempio.

## Fase 2 · Sicurezza e dati personali (v1.3.0)

Obiettivo: chiudere il difetto di sicurezza più concreto e trattare con cautela i dati personali.

- [ ] **Collegamento utente di database ↔ persona**: tabella di mappatura e vista/contesto basato su `SYS_CONTEXT('USERENV','SESSION_USER')`
- [ ] **`inserisci_presenza` vincolata all'utente connesso**: un volontario può registrare solo le proprie presenze
- [ ] **Viste con dati mascherati** (codice fiscale, email, telefono) per i ruoli diversi dall'amministratore
- [ ] **Nota sulla protezione dei dati (GDPR)** nel README: i dati di esempio sono fittizi e lo schema non è pensato per dati reali senza queste misure
- [ ] **Test di sicurezza**: un volontario non può leggere né scrivere dati di altri

Completata quando: i test dimostrano il rifiuto dell'accesso a dati altrui e `ruolo_operatore` e `ruolo_volontario` non leggono dati personali in chiaro dove non necessario.

Rischio: richiede di modificare lo schema (nuova tabella di mappatura). Va documentato nel CHANGELOG e gestito senza rompere i dati di esempio.

## Fase 3 · Tracciabilità e documentazione (v1.4.0)

Obiettivo: rendere il sistema ricostruibile e il progetto presentabile.

- [ ] **Audit**: tabella di log alimentata da trigger per assegnazioni, validazioni delle presenze e richieste di variazione (chi, quando, valore prima e dopo)
- [ ] **Diagramma ER aggiornato** (Mermaid in `docs/`, versionabile) e **dizionario dei dati** (tabelle, colonne, vincoli)
- [ ] **`CONTRIBUTING.md`** e modelli di issue e pull request
- [ ] **Test dell'audit**: ogni modifica rilevante lascia una riga di log coerente

Completata quando: l'audit è coperto dai test, la documentazione dello schema corrisponde al codice e il repository ha le pagine di contorno.

## Punto di verifica finale

A fine Fase 3 si valuta con calma se proseguire con le voci rimaste fuori:

| Voce | Perché è rimasta fuori |
|---|---|
| Tabelle di decodifica per stati e tipi | Cambia lo schema consegnato: costo alto rispetto al beneficio |
| Migrazioni versionate (Liquibase/Flyway) | Eccessive per le dimensioni attuali del progetto |
| Completare la relazione PDF | Le pagine con il codice sono immagini; va rigenerata dal documento sorgente |

Criterio: proseguire solo se una voce risolve un problema reale emerso durante le fasi, non per completezza.

## Fuori ambito

Interfaccia applicativa, API e integrazione con sistemi esterni: il progetto resta un database con la sua logica.
