-- =============================================================================
-- Schema: tabelle del database Servizio Civile (Oracle)
-- =============================================================================

CREATE TABLE ENTE (
    id_ente NUMBER(10,0) PRIMARY KEY,
    denominazione VARCHAR2(100) NOT NULL,
    codice_fiscale VARCHAR2(16) NOT NULL UNIQUE,
    indirizzo_sede_legale VARCHAR2(150) NOT NULL,
    email VARCHAR2(100) NOT NULL,

    CONSTRAINT chk_email_ente
        CHECK (REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'))
);

CREATE TABLE SEDE (
    id_sede NUMBER(10,0) PRIMARY KEY,
    id_ente NUMBER(10,0) NOT NULL,
    nome_sede VARCHAR2(100) NOT NULL,
    indirizzo VARCHAR2(150) NOT NULL,
    comune VARCHAR2(100) NOT NULL,
    provincia VARCHAR2(2) NOT NULL,
    cap_sede VARCHAR2(5) NOT NULL,

    CONSTRAINT fk_sede_ente
        FOREIGN KEY (id_ente)
        REFERENCES ENTE(id_ente),

    CONSTRAINT chk_cap_sede
        CHECK (REGEXP_LIKE(cap_sede, '^[0-9]{5}$'))
);

CREATE TABLE OPERATORE (
    id_operatore NUMBER(10,0) PRIMARY KEY,
    id_ente NUMBER(10,0) NOT NULL,
    nome VARCHAR2(50) NOT NULL,
    cognome VARCHAR2(50) NOT NULL,
    codice_fiscale VARCHAR2(16) NOT NULL UNIQUE,
    email VARCHAR2(100) NOT NULL,
    telefono VARCHAR2(15),
    ruolo_operatore VARCHAR2(30) NOT NULL,

    CONSTRAINT fk_operatore_ente
        FOREIGN KEY (id_ente)
        REFERENCES ENTE(id_ente),

    CONSTRAINT chk_email_operatore
        CHECK (REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')),

    CONSTRAINT chk_ruolo_operatore
        CHECK (ruolo_operatore IN ('OLP', 'COORDINATORE', 'AMMINISTRATIVO'))
);

CREATE TABLE PROGETTO (
    id_progetto NUMBER(10,0) PRIMARY KEY,
    id_ente NUMBER(10,0) NOT NULL,
    titolo VARCHAR2(100) NOT NULL,
    area_intervento VARCHAR2(100) NOT NULL,
    descrizione VARCHAR2(255) NOT NULL,
    data_inizio DATE NOT NULL,
    data_fine DATE,
    stato_progetto VARCHAR2(20) NOT NULL,

    CONSTRAINT fk_progetto_ente
        FOREIGN KEY (id_ente)
        REFERENCES ENTE(id_ente),

    CONSTRAINT chk_periodo_progetto
        CHECK (data_fine IS NULL OR data_inizio <= data_fine),

    CONSTRAINT chk_stato_progetto
        CHECK (stato_progetto IN ('ATTIVO', 'CONCLUSO', 'SOSPESO'))
);

CREATE TABLE PROGETTO_SEDE (
    id_progetto NUMBER(10,0) NOT NULL,
    id_sede NUMBER(10,0) NOT NULL,
    posti_disponibili NUMBER(3,0) NOT NULL,

    CONSTRAINT pk_progetto_sede
        PRIMARY KEY (id_progetto, id_sede),

    CONSTRAINT fk_progetto_sede_progetto
        FOREIGN KEY (id_progetto)
        REFERENCES PROGETTO(id_progetto),

    CONSTRAINT fk_progetto_sede_sede
        FOREIGN KEY (id_sede)
        REFERENCES SEDE(id_sede),

    CONSTRAINT chk_posti_disponibili
        CHECK (posti_disponibili >= 0)
);

CREATE TABLE VOLONTARIO (
    id_volontario NUMBER(10,0) PRIMARY KEY,
    nome VARCHAR2(50) NOT NULL,
    cognome VARCHAR2(50) NOT NULL,
    codice_fiscale VARCHAR2(16) NOT NULL UNIQUE,
    data_nascita DATE NOT NULL,
    email VARCHAR2(100) NOT NULL,
    telefono VARCHAR2(15),
    comune_residenza VARCHAR2(100) NOT NULL,
    stato_volontario VARCHAR2(30) NOT NULL,

    CONSTRAINT chk_email_volontario
        CHECK (REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'))
);

CREATE TABLE ASSEGNAZIONE (
    id_assegnazione NUMBER(10,0) PRIMARY KEY,
    id_volontario NUMBER(10,0) NOT NULL,
    id_progetto NUMBER(10,0) NOT NULL,
    id_sede NUMBER(10,0) NOT NULL,
    id_assegnazione_precedente NUMBER(10,0),
    data_inizio DATE NOT NULL,
    data_fine_prevista DATE,
    data_fine_effettiva DATE,
    stato_assegnazione VARCHAR2(20) NOT NULL,
    ore_settimanali_previste NUMBER(2,0) NOT NULL,
    max_permessi_ordinari NUMBER(2,0) DEFAULT 15 NOT NULL,
    max_malattie_retribuite NUMBER(2,0) DEFAULT 10 NOT NULL,
    max_malattie_non_retribuite NUMBER(2,0) DEFAULT 10 NOT NULL,

    CONSTRAINT fk_assegnazione_volontario
        FOREIGN KEY (id_volontario)
        REFERENCES VOLONTARIO(id_volontario),

    CONSTRAINT fk_assegnazione_progetto
        FOREIGN KEY (id_progetto)
        REFERENCES PROGETTO(id_progetto),

    CONSTRAINT fk_assegnazione_sede
        FOREIGN KEY (id_sede)
        REFERENCES SEDE(id_sede),

    CONSTRAINT fk_assegnazione_precedente
        FOREIGN KEY (id_assegnazione_precedente)
        REFERENCES ASSEGNAZIONE(id_assegnazione),

    CONSTRAINT uq_assegnazione_precedente
        UNIQUE (id_assegnazione_precedente),

    CONSTRAINT chk_assegnazione_precedente_diversa
        CHECK (
            id_assegnazione_precedente IS NULL
            OR id_assegnazione_precedente <> id_assegnazione
        ),

    CONSTRAINT chk_periodo_assegnazione_prev
        CHECK (data_fine_prevista IS NULL OR data_inizio <= data_fine_prevista),

    CONSTRAINT chk_periodo_assegnazione_eff
        CHECK (data_fine_effettiva IS NULL OR data_inizio <= data_fine_effettiva),

    CONSTRAINT chk_stato_assegnazione
        CHECK (stato_assegnazione IN ('ATTIVA', 'CONCLUSA', 'DECADUTA')),

    CONSTRAINT chk_conclusa_con_data_fine
        CHECK (stato_assegnazione <> 'CONCLUSA' OR data_fine_effettiva IS NOT NULL),

    CONSTRAINT chk_ore_settimanali_previste
        CHECK (ore_settimanali_previste > 0),

    CONSTRAINT chk_max_permessi_ordinari
        CHECK (max_permessi_ordinari >= 0),

    CONSTRAINT chk_max_malattie_retribuite
        CHECK (max_malattie_retribuite >= 0),

    CONSTRAINT chk_max_malattie_non_retribuite
        CHECK (max_malattie_non_retribuite >= 0)
);

CREATE TABLE FORMAZIONE (
    id_formazione NUMBER(10,0) PRIMARY KEY,
    id_operatore NUMBER(10,0) NOT NULL,
    titolo VARCHAR2(100) NOT NULL,
    tipologia VARCHAR2(30) NOT NULL,
    data_formazione DATE NOT NULL,
    durata_ore NUMBER(4,1) NOT NULL,
    descrizione VARCHAR2(255) NOT NULL,

    CONSTRAINT fk_formazione_operatore
        FOREIGN KEY (id_operatore)
        REFERENCES OPERATORE(id_operatore),

    CONSTRAINT chk_durata_ore_formazione
        CHECK (durata_ore > 0),

    CONSTRAINT chk_tipologia_formazione
        CHECK (tipologia IN ('GENERALE', 'SPECIFICA', 'INTEGRATIVA'))
);

CREATE TABLE ASSEGNAZIONE_FORMAZIONE (
    id_assegnazione NUMBER(10,0) NOT NULL,
    id_formazione NUMBER(10,0) NOT NULL,
    presenza VARCHAR2(15) NOT NULL,
    ore_frequentate NUMBER(4,1) DEFAULT 0 NOT NULL,
    note_partecipazione VARCHAR2(255),

    CONSTRAINT pk_assegnazione_formazione
        PRIMARY KEY (id_assegnazione, id_formazione),

    CONSTRAINT fk_assegnazione_formazione_assegnazione
        FOREIGN KEY (id_assegnazione)
        REFERENCES ASSEGNAZIONE(id_assegnazione),

    CONSTRAINT fk_assegnazione_formazione_formazione
        FOREIGN KEY (id_formazione)
        REFERENCES FORMAZIONE(id_formazione),

    CONSTRAINT chk_presenza_formazione
        CHECK (presenza IN ('PRESENTE', 'ASSENTE', 'PARZIALE')),

    CONSTRAINT chk_ore_frequentate
        CHECK (ore_frequentate >= 0),

    CONSTRAINT chk_coerenza_presenza_ore
        CHECK (
            (presenza = 'ASSENTE' AND ore_frequentate = 0)
            OR
            (presenza IN ('PRESENTE', 'PARZIALE') AND ore_frequentate > 0)
        )
);

CREATE TABLE REGISTRO_SERVIZIO (
    id_registro NUMBER(10,0) PRIMARY KEY,
    id_assegnazione NUMBER(10,0) NOT NULL,
    data_servizio DATE NOT NULL,
    tipo_giornata VARCHAR2(30) NOT NULL,
    ore_svolte NUMBER(4,1) DEFAULT 0 NOT NULL,
    ore_da_recuperare NUMBER(4,1) DEFAULT 0 NOT NULL,
    stato_validazione VARCHAR2(15) NOT NULL,
    note VARCHAR2(255),

    CONSTRAINT fk_registro_servizio_assegnazione
        FOREIGN KEY (id_assegnazione)
        REFERENCES ASSEGNAZIONE(id_assegnazione),

    CONSTRAINT unq_registro_servizio
        UNIQUE (id_assegnazione, data_servizio),

    CONSTRAINT chk_data_servizio
        CHECK (data_servizio IS NOT NULL),

    CONSTRAINT chk_tipo_giornata
        CHECK (tipo_giornata IN (
            'SERVIZIO',
            'MALATTIA_RETRIBUITA',
            'MALATTIA_NON_RETRIBUITA',
            'PERMESSO_ORDINARIO',
            'PERMESSO_STRAORDINARIO'
        )),

    CONSTRAINT chk_ore_svolte
        CHECK (ore_svolte >= 0),

    CONSTRAINT chk_ore_da_recuperare
        CHECK (ore_da_recuperare >= 0),

    CONSTRAINT chk_stato_validazione
        CHECK (stato_validazione IN ('DA_VALIDARE', 'VALIDATA', 'RIFIUTATA')),

    CONSTRAINT chk_coerenza_tipo_giornata_ore
        CHECK (
            (tipo_giornata = 'SERVIZIO' AND ore_svolte > 0)
            OR
            (tipo_giornata IN (
                'MALATTIA_RETRIBUITA',
                'MALATTIA_NON_RETRIBUITA',
                'PERMESSO_ORDINARIO',
                'PERMESSO_STRAORDINARIO'
            ) AND ore_svolte = 0)
        ),

    CONSTRAINT chk_ore_massime_giornaliere
        CHECK (ore_svolte <= 8)
);

CREATE TABLE MONITORAGGIO (
    id_monitoraggio NUMBER(10,0) PRIMARY KEY,
    id_assegnazione NUMBER(10,0) NOT NULL,
    data_monitoraggio DATE NOT NULL,
    tipo_monitoraggio VARCHAR2(20) NOT NULL,
    esito VARCHAR2(20),
    note VARCHAR2(255),

    CONSTRAINT fk_monitoraggio_assegnazione
        FOREIGN KEY (id_assegnazione)
        REFERENCES ASSEGNAZIONE(id_assegnazione),

    CONSTRAINT chk_data_monitoraggio
        CHECK (data_monitoraggio IS NOT NULL),

    CONSTRAINT chk_tipo_monitoraggio
        CHECK (tipo_monitoraggio IN ('INIZIALE', 'INTERMEDIO', 'FINALE')),

    CONSTRAINT chk_esito_monitoraggio
        CHECK (esito IS NULL OR esito IN ('POSITIVO', 'CRITICO', 'NEGATIVO'))
);

CREATE TABLE RICHIESTA_VARIAZIONE (
    id_richiesta NUMBER(10,0) PRIMARY KEY,
    id_assegnazione NUMBER(10,0) NOT NULL,
    data_richiesta DATE NOT NULL,
    tipo_variazione VARCHAR2(30) NOT NULL,
    motivazione VARCHAR2(255) NOT NULL,
    stato_richiesta VARCHAR2(20) NOT NULL,
    data_validazione DATE,

    CONSTRAINT fk_richiesta_variazione_assegnazione
        FOREIGN KEY (id_assegnazione)
        REFERENCES ASSEGNAZIONE(id_assegnazione),

    CONSTRAINT chk_data_richiesta
        CHECK (data_richiesta IS NOT NULL),

    CONSTRAINT chk_tipo_variazione
        CHECK (tipo_variazione IN ('CAMBIO_SEDE', 'CAMBIO_PROGETTO', 'CAMBIO_ENTRAMBI')),

    CONSTRAINT chk_stato_richiesta
        CHECK (stato_richiesta IN ('IN_ATTESA', 'APPROVATA', 'RIFIUTATA'))
);

CREATE TABLE UTENTE_APPLICATIVO (
    username VARCHAR2(128) PRIMARY KEY,
    tipo_utente VARCHAR2(15) NOT NULL,
    id_volontario NUMBER(10,0),
    id_operatore NUMBER(10,0),

    CONSTRAINT fk_utente_volontario
        FOREIGN KEY (id_volontario)
        REFERENCES VOLONTARIO(id_volontario),

    CONSTRAINT fk_utente_operatore
        FOREIGN KEY (id_operatore)
        REFERENCES OPERATORE(id_operatore),

    CONSTRAINT uq_utente_volontario
        UNIQUE (id_volontario),

    CONSTRAINT uq_utente_operatore
        UNIQUE (id_operatore),

    CONSTRAINT chk_username_maiuscolo
        CHECK (username = UPPER(username)),

    CONSTRAINT chk_tipo_utente
        CHECK (tipo_utente IN ('AMMINISTRATORE', 'OPERATORE', 'VOLONTARIO')),

    CONSTRAINT chk_coerenza_tipo_utente
        CHECK (
            (tipo_utente = 'VOLONTARIO' AND id_volontario IS NOT NULL AND id_operatore IS NULL)
            OR
            (tipo_utente = 'OPERATORE' AND id_operatore IS NOT NULL AND id_volontario IS NULL)
            OR
            (tipo_utente = 'AMMINISTRATORE' AND id_volontario IS NULL AND id_operatore IS NULL)
        )
);

-- Collega l'utente di database (SESSION_USER, in maiuscolo) alla persona che lo usa:
-- è la base su cui le viste e le procedure limitano l'accesso ai dati altrui.

-- Sequenze per gli identificativi generati dalle procedure.
-- Partono da 1000: gli ID inferiori sono riservati ai dati di esempio (seed).
CREATE SEQUENCE seq_formazione START WITH 1000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_monitoraggio START WITH 1000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_progetto START WITH 1000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_assegnazione START WITH 1000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_registro START WITH 1000 INCREMENT BY 1 NOCACHE;
