# Regole di business

Le regole sono applicate dal database, non dall'applicazione che lo usa.

| Regola | Meccanismo | Errore |
|---|---|---|
| Un volontario non può avere due assegnazioni attive con periodi sovrapposti | Trigger `check_assegnazione_attiva` | `-20001` |
| Un'assegnazione può riferirsi solo a una sede collegata al progetto | Trigger `check_progetto_sede_assegnazione` | `-20002` |
| Una variazione si approva solo se la vecchia assegnazione è conclusa e ne esiste una nuova collegata | Trigger `check_storico_variazione` | `-20003` |
| Il registro di servizio si compila solo per giornate comprese nel periodo dell'assegnazione (anche se poi conclusa o decaduta) | Trigger `check_presenza_assegnazione_attiva` | `-20004` |
| Il permesso straordinario richiede una motivazione nelle note | Trigger `check_permesso_straordinario_valido` | `-20009` |
| I monitoraggi devono cadere nel periodo dell'assegnazione | Trigger `check_monitoraggio_assegnazione_valida` | `-20016` |
| Giornate di servizio con ore > 0; permessi e malattie con ore = 0 | Trigger `check_coerenza_tipo_giornata_ore` + CHECK | `-20017`, `-20018` |
| Massimo 8 ore giornaliere | CHECK `chk_ore_massime_giornaliere` | `ORA-02290` |
| Superati i limiti di permessi ordinari / malattie retribuite / non retribuite l'assegnazione passa a `DECADUTA` | Trigger `check_limiti_assenze` | — |
| Una `CONCLUSA` deve avere la data di fine effettiva | CHECK `chk_conclusa_con_data_fine` | `ORA-02290` |

I limiti di assenza sono configurabili per assegnazione
(`max_permessi_ordinari` = 15, `max_malattie_retribuite` = 10,
`max_malattie_non_retribuite` = 10 per default).

## Procedure

Le procedure validano gli input e segnalano gli errori con `RAISE_APPLICATION_ERROR`.
Non eseguono `COMMIT` né `ROLLBACK`: la transazione è del chiamante.

| Procedura | Scopo | Errori |
|---|---|---|
| `crea_progetto(...)` | Crea un progetto e lo collega alle sedi indicate (lista `"1,2,3"`) | `-20150`..`-20159` |
| `modifica_progetto(...)` | Aggiorna un progetto e le sue sedi; non rimuove sedi già usate da assegnazioni | `-20020`..`-20025`, `-20150`..`-20154` |
| `disattiva_progetto(id, motivazione)` | Sospende un progetto privo di assegnazioni attive | `-20040`..`-20043` |
| `crea_assegnazione(...)` | Crea un'assegnazione attiva: controlla periodo, coppia progetto-sede, sovrapposizioni, posti disponibili e assegnazione precedente | `-20050`..`-20067` |
| `gestisci_richiesta_variazione(...)` | Approva o rifiuta una richiesta; se approvata chiude l'assegnazione corrente (fine = decorrenza - 1) e ne crea una nuova collegata | `-20070`..`-20079` |
| `inserisci_presenza(...)` | Il volontario registra una giornata (stato iniziale `DA_VALIDARE`) | `-20140`..`-20147` |
| `valida_presenza(...)` | L'amministratore corregge e valida/rifiuta una giornata | `-20090`..`-20098` |
| `registra_formazione(...)` | Registra un evento formativo (ID da `seq_formazione`) | `-20110`..`-20114` |
| `registra_partecipazione_formazione(...)` | Registra la presenza di un'assegnazione a una formazione | `-20120`..`-20127` |
| `registra_monitoraggio(...)` | Registra un monitoraggio (ID da `seq_monitoraggio`) | `-20130`..`-20136` |

`parse_lista_sedi` è una funzione di supporto usata da `crea_progetto` e `modifica_progetto`.

### Note

- Lo stato iniziale di una richiesta di variazione è `IN_ATTESA` (la relazione lo chiama "pendente").
- `crea_assegnazione` verifica anche che i posti disponibili della coppia progetto-sede non siano esauriti dalle assegnazioni attive nello stesso periodo.
- `inserisci_presenza` riceve l'identificativo del volontario come parametro: il collegamento tra utente di database e volontario non è modellato, quindi il controllo che un volontario inserisca solo le proprie presenze spetta all'applicazione.

## Sicurezza

| Regola | Meccanismo | Errore |
|---|---|---|
| Un volontario registra solo le proprie presenze | `inserisci_presenza` confronta l'utente connesso (`UTENTE_APPLICATIVO`) con il volontario indicato | `-20148` |
| Operatori e utenti non registrati non registrano presenze | `inserisci_presenza` (l'operatore non ha neppure `EXECUTE`) | `-20149` |
| Un volontario non legge né scrive dati altrui | Nessun privilegio sulle tabelle; viste `v_mie_*` filtrate sull'utente connesso | `ORA-00942` |
| Gli operatori non vedono dati personali in chiaro | Vista `v_volontari_mascherati` al posto di `VOLONTARIO` | `ORA-00942` |

Lo script `tests/test_sicurezza.sql` verifica queste regole connettendosi come utenti reali.

