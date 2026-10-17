-- =============================================================================
-- Commenti sulle tabelle e sulle colonne.
-- Sono la fonte del dizionario dei dati (docs/dizionario_dati.md), generato da
-- scripts/genera-documentazione.sh: aggiornare qui, poi rigenerare.
-- =============================================================================

COMMENT ON TABLE ENTE IS 'Ente titolare dei progetti di servizio civile';
COMMENT ON COLUMN ENTE.id_ente IS 'Identificativo dell''ente';
COMMENT ON COLUMN ENTE.denominazione IS 'Denominazione ufficiale';
COMMENT ON COLUMN ENTE.codice_fiscale IS 'Codice fiscale dell''ente (univoco)';
COMMENT ON COLUMN ENTE.indirizzo_sede_legale IS 'Indirizzo della sede legale';
COMMENT ON COLUMN ENTE.email IS 'Indirizzo e-mail di contatto';

COMMENT ON TABLE SEDE IS 'Sede di attuazione appartenente a un ente';
COMMENT ON COLUMN SEDE.id_sede IS 'Identificativo della sede';
COMMENT ON COLUMN SEDE.id_ente IS 'Ente a cui appartiene la sede';
COMMENT ON COLUMN SEDE.nome_sede IS 'Nome della sede';
COMMENT ON COLUMN SEDE.indirizzo IS 'Indirizzo della sede';
COMMENT ON COLUMN SEDE.comune IS 'Comune della sede';
COMMENT ON COLUMN SEDE.provincia IS 'Sigla della provincia (2 lettere)';
COMMENT ON COLUMN SEDE.cap_sede IS 'CAP (5 cifre)';

COMMENT ON TABLE OPERATORE IS 'Operatore dell''ente (OLP, coordinatore o amministrativo)';
COMMENT ON COLUMN OPERATORE.id_operatore IS 'Identificativo dell''operatore';
COMMENT ON COLUMN OPERATORE.id_ente IS 'Ente di appartenenza';
COMMENT ON COLUMN OPERATORE.nome IS 'Nome';
COMMENT ON COLUMN OPERATORE.cognome IS 'Cognome';
COMMENT ON COLUMN OPERATORE.codice_fiscale IS 'Codice fiscale (univoco)';
COMMENT ON COLUMN OPERATORE.email IS 'Indirizzo e-mail';
COMMENT ON COLUMN OPERATORE.telefono IS 'Numero di telefono (facoltativo)';
COMMENT ON COLUMN OPERATORE.ruolo_operatore IS 'Ruolo: OLP, COORDINATORE o AMMINISTRATIVO';

COMMENT ON TABLE PROGETTO IS 'Progetto di servizio civile promosso da un ente';
COMMENT ON COLUMN PROGETTO.id_progetto IS 'Identificativo del progetto';
COMMENT ON COLUMN PROGETTO.id_ente IS 'Ente promotore';
COMMENT ON COLUMN PROGETTO.titolo IS 'Titolo del progetto';
COMMENT ON COLUMN PROGETTO.area_intervento IS 'Area di intervento';
COMMENT ON COLUMN PROGETTO.descrizione IS 'Descrizione del progetto';
COMMENT ON COLUMN PROGETTO.data_inizio IS 'Data di inizio';
COMMENT ON COLUMN PROGETTO.data_fine IS 'Data di fine (facoltativa, non anteriore allinizio)';
COMMENT ON COLUMN PROGETTO.stato_progetto IS 'Stato: ATTIVO, CONCLUSO o SOSPESO';

COMMENT ON TABLE PROGETTO_SEDE IS 'Sedi in cui si svolge un progetto, con i posti disponibili';
COMMENT ON COLUMN PROGETTO_SEDE.id_progetto IS 'Progetto';
COMMENT ON COLUMN PROGETTO_SEDE.id_sede IS 'Sede di attuazione del progetto';
COMMENT ON COLUMN PROGETTO_SEDE.posti_disponibili IS 'Numero di posti disponibili per la coppia progetto-sede';

COMMENT ON TABLE VOLONTARIO IS 'Volontario del servizio civile (dati personali)';
COMMENT ON COLUMN VOLONTARIO.id_volontario IS 'Identificativo del volontario';
COMMENT ON COLUMN VOLONTARIO.nome IS 'Nome';
COMMENT ON COLUMN VOLONTARIO.cognome IS 'Cognome';
COMMENT ON COLUMN VOLONTARIO.codice_fiscale IS 'Codice fiscale (univoco)';
COMMENT ON COLUMN VOLONTARIO.data_nascita IS 'Data di nascita';
COMMENT ON COLUMN VOLONTARIO.email IS 'Indirizzo e-mail';
COMMENT ON COLUMN VOLONTARIO.telefono IS 'Numero di telefono (facoltativo)';
COMMENT ON COLUMN VOLONTARIO.comune_residenza IS 'Comune di residenza';
COMMENT ON COLUMN VOLONTARIO.stato_volontario IS 'Stato del volontario';

COMMENT ON TABLE ASSEGNAZIONE IS 'Percorso di un volontario su un progetto e una sede, con i limiti di assenza';
COMMENT ON COLUMN ASSEGNAZIONE.id_assegnazione IS 'Identificativo dell''assegnazione';
COMMENT ON COLUMN ASSEGNAZIONE.id_volontario IS 'Volontario assegnato';
COMMENT ON COLUMN ASSEGNAZIONE.id_progetto IS 'Progetto';
COMMENT ON COLUMN ASSEGNAZIONE.id_sede IS 'Sede (deve essere collegata al progetto)';
COMMENT ON COLUMN ASSEGNAZIONE.id_assegnazione_precedente IS 'Assegnazione che questa sostituisce, per lo storico delle variazioni (facoltativa, univoca)';
COMMENT ON COLUMN ASSEGNAZIONE.data_inizio IS 'Data di inizio';
COMMENT ON COLUMN ASSEGNAZIONE.data_fine_prevista IS 'Data di fine prevista';
COMMENT ON COLUMN ASSEGNAZIONE.data_fine_effettiva IS 'Data di fine effettiva (obbligatoria se conclusa)';
COMMENT ON COLUMN ASSEGNAZIONE.stato_assegnazione IS 'Stato: ATTIVA, CONCLUSA o DECADUTA';
COMMENT ON COLUMN ASSEGNAZIONE.ore_settimanali_previste IS 'Ore settimanali previste (maggiori di zero)';
COMMENT ON COLUMN ASSEGNAZIONE.max_permessi_ordinari IS 'Massimo di giornate di permesso ordinario (default 15)';
COMMENT ON COLUMN ASSEGNAZIONE.max_malattie_retribuite IS 'Massimo di giornate di malattia retribuita (default 10)';
COMMENT ON COLUMN ASSEGNAZIONE.max_malattie_non_retribuite IS 'Massimo di giornate di malattia non retribuita (default 10)';

COMMENT ON TABLE FORMAZIONE IS 'Evento formativo tenuto da un operatore';
COMMENT ON COLUMN FORMAZIONE.id_formazione IS 'Identificativo della formazione';
COMMENT ON COLUMN FORMAZIONE.id_operatore IS 'Operatore che la tiene';
COMMENT ON COLUMN FORMAZIONE.titolo IS 'Titolo';
COMMENT ON COLUMN FORMAZIONE.tipologia IS 'Tipologia: GENERALE, SPECIFICA o INTEGRATIVA';
COMMENT ON COLUMN FORMAZIONE.data_formazione IS 'Data di svolgimento';
COMMENT ON COLUMN FORMAZIONE.durata_ore IS 'Durata in ore (maggiore di zero)';
COMMENT ON COLUMN FORMAZIONE.descrizione IS 'Descrizione';

COMMENT ON TABLE ASSEGNAZIONE_FORMAZIONE IS 'Partecipazione di un''assegnazione a un evento formativo';
COMMENT ON COLUMN ASSEGNAZIONE_FORMAZIONE.id_assegnazione IS 'Assegnazione partecipante';
COMMENT ON COLUMN ASSEGNAZIONE_FORMAZIONE.id_formazione IS 'Formazione frequentata';
COMMENT ON COLUMN ASSEGNAZIONE_FORMAZIONE.presenza IS 'Presenza: PRESENTE, ASSENTE o PARZIALE';
COMMENT ON COLUMN ASSEGNAZIONE_FORMAZIONE.ore_frequentate IS 'Ore frequentate (zero se assente, altrimenti maggiori di zero)';
COMMENT ON COLUMN ASSEGNAZIONE_FORMAZIONE.note_partecipazione IS 'Note (facoltative)';

COMMENT ON TABLE REGISTRO_SERVIZIO IS 'Giornate di servizio, permesso o malattia di un''assegnazione';
COMMENT ON COLUMN REGISTRO_SERVIZIO.id_registro IS 'Identificativo della registrazione';
COMMENT ON COLUMN REGISTRO_SERVIZIO.id_assegnazione IS 'Assegnazione di riferimento';
COMMENT ON COLUMN REGISTRO_SERVIZIO.data_servizio IS 'Data della giornata (una sola per assegnazione)';
COMMENT ON COLUMN REGISTRO_SERVIZIO.tipo_giornata IS 'SERVIZIO, MALATTIA_RETRIBUITA, MALATTIA_NON_RETRIBUITA, PERMESSO_ORDINARIO o PERMESSO_STRAORDINARIO';
COMMENT ON COLUMN REGISTRO_SERVIZIO.ore_svolte IS 'Ore svolte (1-8 se servizio, zero altrimenti)';
COMMENT ON COLUMN REGISTRO_SERVIZIO.ore_da_recuperare IS 'Ore da recuperare';
COMMENT ON COLUMN REGISTRO_SERVIZIO.stato_validazione IS 'DA_VALIDARE, VALIDATA o RIFIUTATA';
COMMENT ON COLUMN REGISTRO_SERVIZIO.note IS 'Note; obbligatorie per il permesso straordinario';

COMMENT ON TABLE MONITORAGGIO IS 'Monitoraggio iniziale, intermedio o finale di un''assegnazione';
COMMENT ON COLUMN MONITORAGGIO.id_monitoraggio IS 'Identificativo del monitoraggio';
COMMENT ON COLUMN MONITORAGGIO.id_assegnazione IS 'Assegnazione monitorata';
COMMENT ON COLUMN MONITORAGGIO.data_monitoraggio IS 'Data (nel periodo dell''assegnazione)';
COMMENT ON COLUMN MONITORAGGIO.tipo_monitoraggio IS 'INIZIALE, INTERMEDIO o FINALE';
COMMENT ON COLUMN MONITORAGGIO.esito IS 'POSITIVO, CRITICO o NEGATIVO (facoltativo)';
COMMENT ON COLUMN MONITORAGGIO.note IS 'Note (facoltative)';

COMMENT ON TABLE RICHIESTA_VARIAZIONE IS 'Richiesta di cambio di sede o progetto di un volontario';
COMMENT ON COLUMN RICHIESTA_VARIAZIONE.id_richiesta IS 'Identificativo della richiesta';
COMMENT ON COLUMN RICHIESTA_VARIAZIONE.id_assegnazione IS 'Assegnazione di cui si chiede la variazione';
COMMENT ON COLUMN RICHIESTA_VARIAZIONE.data_richiesta IS 'Data della richiesta';
COMMENT ON COLUMN RICHIESTA_VARIAZIONE.tipo_variazione IS 'CAMBIO_SEDE, CAMBIO_PROGETTO o CAMBIO_ENTRAMBI';
COMMENT ON COLUMN RICHIESTA_VARIAZIONE.motivazione IS 'Motivazione';
COMMENT ON COLUMN RICHIESTA_VARIAZIONE.stato_richiesta IS 'IN_ATTESA, APPROVATA o RIFIUTATA';
COMMENT ON COLUMN RICHIESTA_VARIAZIONE.data_validazione IS 'Data della decisione';

COMMENT ON TABLE UTENTE_APPLICATIVO IS 'Collega un utente di database alla persona che lo usa (base della sicurezza)';
COMMENT ON COLUMN UTENTE_APPLICATIVO.username IS 'Utente di database (SESSION_USER), in maiuscolo';
COMMENT ON COLUMN UTENTE_APPLICATIVO.tipo_utente IS 'AMMINISTRATORE, OPERATORE o VOLONTARIO';
COMMENT ON COLUMN UTENTE_APPLICATIVO.id_volontario IS 'Volontario collegato (solo per tipo VOLONTARIO)';
COMMENT ON COLUMN UTENTE_APPLICATIVO.id_operatore IS 'Operatore collegato (solo per tipo OPERATORE)';

COMMENT ON TABLE AUDIT_LOG IS 'Registro delle modifiche a assegnazioni, registro di servizio e richieste (sola lettura)';
COMMENT ON COLUMN AUDIT_LOG.id_audit IS 'Identificativo progressivo';
COMMENT ON COLUMN AUDIT_LOG.tabella IS 'Tabella modificata';
COMMENT ON COLUMN AUDIT_LOG.chiave IS 'Chiave primaria della riga modificata';
COMMENT ON COLUMN AUDIT_LOG.operazione IS 'I inserimento, U modifica, D cancellazione';
COMMENT ON COLUMN AUDIT_LOG.utente IS 'Utente di database che ha eseguito loperazione';
COMMENT ON COLUMN AUDIT_LOG.data_ora IS 'Istante dell''operazione';
COMMENT ON COLUMN AUDIT_LOG.valori_prima IS 'Valori della riga prima (modifica e cancellazione)';
COMMENT ON COLUMN AUDIT_LOG.valori_dopo IS 'Valori della riga dopo (inserimento e modifica)';
