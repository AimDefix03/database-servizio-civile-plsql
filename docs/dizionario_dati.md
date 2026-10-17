# Dizionario dei dati

> File generato da `scripts/genera-documentazione.sh` a partire dal catalogo del database.
> Non modificarlo a mano: aggiornare i commenti in `sql/01_schema/03_commenti.sql` e rigenerare.

Tabelle: 14. Diagramma delle relazioni: [diagramma_er.md](diagramma_er.md).

## Indice

- [ASSEGNAZIONE](#assegnazione)
- [ASSEGNAZIONE_FORMAZIONE](#assegnazione-formazione)
- [AUDIT_LOG](#audit-log)
- [ENTE](#ente)
- [FORMAZIONE](#formazione)
- [MONITORAGGIO](#monitoraggio)
- [OPERATORE](#operatore)
- [PROGETTO](#progetto)
- [PROGETTO_SEDE](#progetto-sede)
- [REGISTRO_SERVIZIO](#registro-servizio)
- [RICHIESTA_VARIAZIONE](#richiesta-variazione)
- [SEDE](#sede)
- [UTENTE_APPLICATIVO](#utente-applicativo)
- [VOLONTARIO](#volontario)

## ASSEGNAZIONE

Percorso di un volontario su un progetto e una sede, con i limiti di assenza

| Colonna | Tipo | Null | Chiave | Descrizione |
|---|---|---|---|---|
| `id_assegnazione` | NUMBER(10,0) | no | PK | Identificativo dell'assegnazione |
| `id_volontario` | NUMBER(10,0) | no | FK → VOLONTARIO(id_volontario) | Volontario assegnato |
| `id_progetto` | NUMBER(10,0) | no | FK → PROGETTO(id_progetto) | Progetto |
| `id_sede` | NUMBER(10,0) | no | FK → SEDE(id_sede) | Sede (deve essere collegata al progetto) |
| `id_assegnazione_precedente` | NUMBER(10,0) | sì | FK → ASSEGNAZIONE(id_assegnazione), UK | Assegnazione che questa sostituisce, per lo storico delle variazioni (facoltativa, univoca) |
| `data_inizio` | DATE | no |  | Data di inizio |
| `data_fine_prevista` | DATE | sì |  | Data di fine prevista |
| `data_fine_effettiva` | DATE | sì |  | Data di fine effettiva (obbligatoria se conclusa) |
| `stato_assegnazione` | VARCHAR2(20) | no |  | Stato: ATTIVA, CONCLUSA o DECADUTA |
| `ore_settimanali_previste` | NUMBER(2,0) | no |  | Ore settimanali previste (maggiori di zero) |
| `max_permessi_ordinari` | NUMBER(2,0) | no |  | Massimo di giornate di permesso ordinario (default 15) |
| `max_malattie_retribuite` | NUMBER(2,0) | no |  | Massimo di giornate di malattia retribuita (default 10) |
| `max_malattie_non_retribuite` | NUMBER(2,0) | no |  | Massimo di giornate di malattia non retribuita (default 10) |

Vincoli di controllo:

- `chk_assegnazione_precedente_diversa`: `id_assegnazione_precedente IS NULL OR id_assegnazione_precedente <> id_assegnazione`
- `chk_conclusa_con_data_fine`: `stato_assegnazione <> 'CONCLUSA' OR data_fine_effettiva IS NOT NULL`
- `chk_max_malattie_non_retribuite`: `max_malattie_non_retribuite >= 0`
- `chk_max_malattie_retribuite`: `max_malattie_retribuite >= 0`
- `chk_max_permessi_ordinari`: `max_permessi_ordinari >= 0`
- `chk_ore_settimanali_previste`: `ore_settimanali_previste > 0`
- `chk_periodo_assegnazione_eff`: `data_fine_effettiva IS NULL OR data_inizio <= data_fine_effettiva`
- `chk_periodo_assegnazione_prev`: `data_fine_prevista IS NULL OR data_inizio <= data_fine_prevista`
- `chk_stato_assegnazione`: `stato_assegnazione IN ('ATTIVA', 'CONCLUSA', 'DECADUTA')`

## ASSEGNAZIONE_FORMAZIONE

Partecipazione di un'assegnazione a un evento formativo

| Colonna | Tipo | Null | Chiave | Descrizione |
|---|---|---|---|---|
| `id_assegnazione` | NUMBER(10,0) | no | PK, FK → ASSEGNAZIONE(id_assegnazione) | Assegnazione partecipante |
| `id_formazione` | NUMBER(10,0) | no | PK, FK → FORMAZIONE(id_formazione) | Formazione frequentata |
| `presenza` | VARCHAR2(15) | no |  | Presenza: PRESENTE, ASSENTE o PARZIALE |
| `ore_frequentate` | NUMBER(4,1) | no |  | Ore frequentate (zero se assente, altrimenti maggiori di zero) |
| `note_partecipazione` | VARCHAR2(255) | sì |  | Note (facoltative) |

Chiave primaria composta: `id_assegnazione, id_formazione`.

Vincoli di controllo:

- `chk_coerenza_presenza_ore`: `(presenza = 'ASSENTE' AND ore_frequentate = 0) OR (presenza IN ('PRESENTE', 'PARZIALE') AND ore_frequentate > 0)`
- `chk_ore_frequentate`: `ore_frequentate >= 0`
- `chk_presenza_formazione`: `presenza IN ('PRESENTE', 'ASSENTE', 'PARZIALE')`

## AUDIT_LOG

Registro delle modifiche a assegnazioni, registro di servizio e richieste (sola lettura)

| Colonna | Tipo | Null | Chiave | Descrizione |
|---|---|---|---|---|
| `id_audit` | NUMBER(12,0) | no | PK | Identificativo progressivo |
| `tabella` | VARCHAR2(30) | no |  | Tabella modificata |
| `chiave` | VARCHAR2(100) | no |  | Chiave primaria della riga modificata |
| `operazione` | VARCHAR2(1) | no |  | I inserimento, U modifica, D cancellazione |
| `utente` | VARCHAR2(128) | no |  | Utente di database che ha eseguito loperazione |
| `data_ora` | TIMESTAMP | no |  | Istante dell'operazione |
| `valori_prima` | VARCHAR2(4000) | sì |  | Valori della riga prima (modifica e cancellazione) |
| `valori_dopo` | VARCHAR2(4000) | sì |  | Valori della riga dopo (inserimento e modifica) |

Vincoli di controllo:

- `chk_audit_operazione`: `operazione IN ('I', 'U', 'D')`
- `chk_audit_valori`: `(operazione = 'I' AND valori_prima IS NULL AND valori_dopo IS NOT NULL) OR (operazione = 'U' AND valori_prima IS NOT NULL AND valori_dopo IS NOT NULL) OR (operazione = 'D' AND valori_prima IS NOT NULL AND valori_dopo IS NULL)`

## ENTE

Ente titolare dei progetti di servizio civile

| Colonna | Tipo | Null | Chiave | Descrizione |
|---|---|---|---|---|
| `id_ente` | NUMBER(10,0) | no | PK | Identificativo dell'ente |
| `denominazione` | VARCHAR2(100) | no |  | Denominazione ufficiale |
| `codice_fiscale` | VARCHAR2(16) | no | UK | Codice fiscale dell'ente (univoco) |
| `indirizzo_sede_legale` | VARCHAR2(150) | no |  | Indirizzo della sede legale |
| `email` | VARCHAR2(100) | no |  | Indirizzo e-mail di contatto |

Vincoli di controllo:

- `chk_email_ente`: `REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')`

## FORMAZIONE

Evento formativo tenuto da un operatore

| Colonna | Tipo | Null | Chiave | Descrizione |
|---|---|---|---|---|
| `id_formazione` | NUMBER(10,0) | no | PK | Identificativo della formazione |
| `id_operatore` | NUMBER(10,0) | no | FK → OPERATORE(id_operatore) | Operatore che la tiene |
| `titolo` | VARCHAR2(100) | no |  | Titolo |
| `tipologia` | VARCHAR2(30) | no |  | Tipologia: GENERALE, SPECIFICA o INTEGRATIVA |
| `data_formazione` | DATE | no |  | Data di svolgimento |
| `durata_ore` | NUMBER(4,1) | no |  | Durata in ore (maggiore di zero) |
| `descrizione` | VARCHAR2(255) | no |  | Descrizione |

Vincoli di controllo:

- `chk_durata_ore_formazione`: `durata_ore > 0`
- `chk_tipologia_formazione`: `tipologia IN ('GENERALE', 'SPECIFICA', 'INTEGRATIVA')`

## MONITORAGGIO

Monitoraggio iniziale, intermedio o finale di un'assegnazione

| Colonna | Tipo | Null | Chiave | Descrizione |
|---|---|---|---|---|
| `id_monitoraggio` | NUMBER(10,0) | no | PK | Identificativo del monitoraggio |
| `id_assegnazione` | NUMBER(10,0) | no | FK → ASSEGNAZIONE(id_assegnazione) | Assegnazione monitorata |
| `data_monitoraggio` | DATE | no |  | Data (nel periodo dell'assegnazione) |
| `tipo_monitoraggio` | VARCHAR2(20) | no |  | INIZIALE, INTERMEDIO o FINALE |
| `esito` | VARCHAR2(20) | sì |  | POSITIVO, CRITICO o NEGATIVO (facoltativo) |
| `note` | VARCHAR2(255) | sì |  | Note (facoltative) |

Vincoli di controllo:

- `chk_data_monitoraggio`: `data_monitoraggio IS NOT NULL`
- `chk_esito_monitoraggio`: `esito IS NULL OR esito IN ('POSITIVO', 'CRITICO', 'NEGATIVO')`
- `chk_tipo_monitoraggio`: `tipo_monitoraggio IN ('INIZIALE', 'INTERMEDIO', 'FINALE')`

## OPERATORE

Operatore dell'ente (OLP, coordinatore o amministrativo)

| Colonna | Tipo | Null | Chiave | Descrizione |
|---|---|---|---|---|
| `id_operatore` | NUMBER(10,0) | no | PK | Identificativo dell'operatore |
| `id_ente` | NUMBER(10,0) | no | FK → ENTE(id_ente) | Ente di appartenenza |
| `nome` | VARCHAR2(50) | no |  | Nome |
| `cognome` | VARCHAR2(50) | no |  | Cognome |
| `codice_fiscale` | VARCHAR2(16) | no | UK | Codice fiscale (univoco) |
| `email` | VARCHAR2(100) | no |  | Indirizzo e-mail |
| `telefono` | VARCHAR2(15) | sì |  | Numero di telefono (facoltativo) |
| `ruolo_operatore` | VARCHAR2(30) | no |  | Ruolo: OLP, COORDINATORE o AMMINISTRATIVO |

Vincoli di controllo:

- `chk_email_operatore`: `REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')`
- `chk_ruolo_operatore`: `ruolo_operatore IN ('OLP', 'COORDINATORE', 'AMMINISTRATIVO')`

## PROGETTO

Progetto di servizio civile promosso da un ente

| Colonna | Tipo | Null | Chiave | Descrizione |
|---|---|---|---|---|
| `id_progetto` | NUMBER(10,0) | no | PK | Identificativo del progetto |
| `id_ente` | NUMBER(10,0) | no | FK → ENTE(id_ente) | Ente promotore |
| `titolo` | VARCHAR2(100) | no |  | Titolo del progetto |
| `area_intervento` | VARCHAR2(100) | no |  | Area di intervento |
| `descrizione` | VARCHAR2(255) | no |  | Descrizione del progetto |
| `data_inizio` | DATE | no |  | Data di inizio |
| `data_fine` | DATE | sì |  | Data di fine (facoltativa, non anteriore allinizio) |
| `stato_progetto` | VARCHAR2(20) | no |  | Stato: ATTIVO, CONCLUSO o SOSPESO |

Vincoli di controllo:

- `chk_periodo_progetto`: `data_fine IS NULL OR data_inizio <= data_fine`
- `chk_stato_progetto`: `stato_progetto IN ('ATTIVO', 'CONCLUSO', 'SOSPESO')`

## PROGETTO_SEDE

Sedi in cui si svolge un progetto, con i posti disponibili

| Colonna | Tipo | Null | Chiave | Descrizione |
|---|---|---|---|---|
| `id_progetto` | NUMBER(10,0) | no | PK, FK → PROGETTO(id_progetto) | Progetto |
| `id_sede` | NUMBER(10,0) | no | PK, FK → SEDE(id_sede) | Sede di attuazione del progetto |
| `posti_disponibili` | NUMBER(3,0) | no |  | Numero di posti disponibili per la coppia progetto-sede |

Chiave primaria composta: `id_progetto, id_sede`.

Vincoli di controllo:

- `chk_posti_disponibili`: `posti_disponibili >= 0`

## REGISTRO_SERVIZIO

Giornate di servizio, permesso o malattia di un'assegnazione

| Colonna | Tipo | Null | Chiave | Descrizione |
|---|---|---|---|---|
| `id_registro` | NUMBER(10,0) | no | PK | Identificativo della registrazione |
| `id_assegnazione` | NUMBER(10,0) | no | FK → ASSEGNAZIONE(id_assegnazione) | Assegnazione di riferimento |
| `data_servizio` | DATE | no |  | Data della giornata (una sola per assegnazione) |
| `tipo_giornata` | VARCHAR2(30) | no |  | SERVIZIO, MALATTIA_RETRIBUITA, MALATTIA_NON_RETRIBUITA, PERMESSO_ORDINARIO o PERMESSO_STRAORDINARIO |
| `ore_svolte` | NUMBER(4,1) | no |  | Ore svolte (1-8 se servizio, zero altrimenti) |
| `ore_da_recuperare` | NUMBER(4,1) | no |  | Ore da recuperare |
| `stato_validazione` | VARCHAR2(15) | no |  | DA_VALIDARE, VALIDATA o RIFIUTATA |
| `note` | VARCHAR2(255) | sì |  | Note; obbligatorie per il permesso straordinario |

Unicità composta: `id_assegnazione, data_servizio`.

Vincoli di controllo:

- `chk_coerenza_tipo_giornata_ore`: `(tipo_giornata = 'SERVIZIO' AND ore_svolte > 0) OR (tipo_giornata IN ( 'MALATTIA_RETRIBUITA', 'MALATTIA_NON_RETRIBUITA', 'PERMESSO_ORDINARIO', 'PERMESSO_STRAORDINARIO' ) AND ore_svolte = 0)`
- `chk_data_servizio`: `data_servizio IS NOT NULL`
- `chk_ore_da_recuperare`: `ore_da_recuperare >= 0`
- `chk_ore_massime_giornaliere`: `ore_svolte <= 8`
- `chk_ore_svolte`: `ore_svolte >= 0`
- `chk_stato_validazione`: `stato_validazione IN ('DA_VALIDARE', 'VALIDATA', 'RIFIUTATA')`
- `chk_tipo_giornata`: `tipo_giornata IN ( 'SERVIZIO', 'MALATTIA_RETRIBUITA', 'MALATTIA_NON_RETRIBUITA', 'PERMESSO_ORDINARIO', 'PERMESSO_STRAORDINARIO' )`

## RICHIESTA_VARIAZIONE

Richiesta di cambio di sede o progetto di un volontario

| Colonna | Tipo | Null | Chiave | Descrizione |
|---|---|---|---|---|
| `id_richiesta` | NUMBER(10,0) | no | PK | Identificativo della richiesta |
| `id_assegnazione` | NUMBER(10,0) | no | FK → ASSEGNAZIONE(id_assegnazione) | Assegnazione di cui si chiede la variazione |
| `data_richiesta` | DATE | no |  | Data della richiesta |
| `tipo_variazione` | VARCHAR2(30) | no |  | CAMBIO_SEDE, CAMBIO_PROGETTO o CAMBIO_ENTRAMBI |
| `motivazione` | VARCHAR2(255) | no |  | Motivazione |
| `stato_richiesta` | VARCHAR2(20) | no |  | IN_ATTESA, APPROVATA o RIFIUTATA |
| `data_validazione` | DATE | sì |  | Data della decisione |

Vincoli di controllo:

- `chk_data_richiesta`: `data_richiesta IS NOT NULL`
- `chk_stato_richiesta`: `stato_richiesta IN ('IN_ATTESA', 'APPROVATA', 'RIFIUTATA')`
- `chk_tipo_variazione`: `tipo_variazione IN ('CAMBIO_SEDE', 'CAMBIO_PROGETTO', 'CAMBIO_ENTRAMBI')`

## SEDE

Sede di attuazione appartenente a un ente

| Colonna | Tipo | Null | Chiave | Descrizione |
|---|---|---|---|---|
| `id_sede` | NUMBER(10,0) | no | PK | Identificativo della sede |
| `id_ente` | NUMBER(10,0) | no | FK → ENTE(id_ente) | Ente a cui appartiene la sede |
| `nome_sede` | VARCHAR2(100) | no |  | Nome della sede |
| `indirizzo` | VARCHAR2(150) | no |  | Indirizzo della sede |
| `comune` | VARCHAR2(100) | no |  | Comune della sede |
| `provincia` | VARCHAR2(2) | no |  | Sigla della provincia (2 lettere) |
| `cap_sede` | VARCHAR2(5) | no |  | CAP (5 cifre) |

Vincoli di controllo:

- `chk_cap_sede`: `REGEXP_LIKE(cap_sede, '^[0-9]{5}$')`

## UTENTE_APPLICATIVO

Collega un utente di database alla persona che lo usa (base della sicurezza)

| Colonna | Tipo | Null | Chiave | Descrizione |
|---|---|---|---|---|
| `username` | VARCHAR2(128) | no | PK | Utente di database (SESSION_USER), in maiuscolo |
| `tipo_utente` | VARCHAR2(15) | no |  | AMMINISTRATORE, OPERATORE o VOLONTARIO |
| `id_volontario` | NUMBER(10,0) | sì | FK → VOLONTARIO(id_volontario), UK | Volontario collegato (solo per tipo VOLONTARIO) |
| `id_operatore` | NUMBER(10,0) | sì | FK → OPERATORE(id_operatore), UK | Operatore collegato (solo per tipo OPERATORE) |

Vincoli di controllo:

- `chk_coerenza_tipo_utente`: `(tipo_utente = 'VOLONTARIO' AND id_volontario IS NOT NULL AND id_operatore IS NULL) OR (tipo_utente = 'OPERATORE' AND id_operatore IS NOT NULL AND id_volontario IS NULL) OR (tipo_utente = 'AMMINISTRATORE' AND id_volontario IS NULL AND id_operatore IS NULL)`
- `chk_tipo_utente`: `tipo_utente IN ('AMMINISTRATORE', 'OPERATORE', 'VOLONTARIO')`
- `chk_username_maiuscolo`: `username = UPPER(username)`

## VOLONTARIO

Volontario del servizio civile (dati personali)

| Colonna | Tipo | Null | Chiave | Descrizione |
|---|---|---|---|---|
| `id_volontario` | NUMBER(10,0) | no | PK | Identificativo del volontario |
| `nome` | VARCHAR2(50) | no |  | Nome |
| `cognome` | VARCHAR2(50) | no |  | Cognome |
| `codice_fiscale` | VARCHAR2(16) | no | UK | Codice fiscale (univoco) |
| `data_nascita` | DATE | no |  | Data di nascita |
| `email` | VARCHAR2(100) | no |  | Indirizzo e-mail |
| `telefono` | VARCHAR2(15) | sì |  | Numero di telefono (facoltativo) |
| `comune_residenza` | VARCHAR2(100) | no |  | Comune di residenza |
| `stato_volontario` | VARCHAR2(30) | no |  | Stato del volontario |

Vincoli di controllo:

- `chk_email_volontario`: `REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')`
