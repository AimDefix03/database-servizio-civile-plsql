# Regole di business

Le regole sono applicate dal database, non dall'applicazione che lo usa.

| Regola | Meccanismo | Errore |
|---|---|---|
| Un volontario non può avere due assegnazioni attive con periodi sovrapposti | Trigger `check_assegnazione_attiva` | `-20001` |
| Un'assegnazione può riferirsi solo a una sede collegata al progetto | Trigger `check_progetto_sede_assegnazione` | `-20002` |
| Una variazione si approva solo se la vecchia assegnazione è conclusa e ne esiste una nuova collegata | Trigger `check_storico_variazione` | `-20003` |
| Il registro di servizio si compila solo per assegnazioni attive e nel loro periodo | Trigger `check_presenza_assegnazione_attiva` | `-20004` |
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

| Procedura | Scopo |
|---|---|
| `disattiva_progetto(id, motivazione)` | Sospende un progetto privo di assegnazioni attive |
| `registra_formazione(...)` | Registra un evento formativo (ID da `seq_formazione`) |
| `registra_partecipazione_formazione(...)` | Registra la presenza di un'assegnazione a una formazione |
| `registra_monitoraggio(...)` | Registra un monitoraggio (ID da `seq_monitoraggio`) |
