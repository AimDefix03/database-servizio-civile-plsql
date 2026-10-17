-- =============================================================================
-- Indici sulle chiavi esterne (Oracle non li crea automaticamente)
-- =============================================================================

CREATE INDEX idx_sede_ente ON SEDE (id_ente);
CREATE INDEX idx_operatore_ente ON OPERATORE (id_ente);
CREATE INDEX idx_progetto_ente ON PROGETTO (id_ente);
CREATE INDEX idx_progetto_sede_sede ON PROGETTO_SEDE (id_sede);
CREATE INDEX idx_assegnazione_volontario ON ASSEGNAZIONE (id_volontario);
CREATE INDEX idx_assegnazione_progetto_sede ON ASSEGNAZIONE (id_progetto, id_sede);
CREATE INDEX idx_assegnazione_stato ON ASSEGNAZIONE (stato_assegnazione);
CREATE INDEX idx_formazione_operatore ON FORMAZIONE (id_operatore);
CREATE INDEX idx_assegn_formazione_formazione ON ASSEGNAZIONE_FORMAZIONE (id_formazione);
CREATE INDEX idx_registro_stato ON REGISTRO_SERVIZIO (stato_validazione);
CREATE INDEX idx_monitoraggio_assegnazione ON MONITORAGGIO (id_assegnazione);
CREATE INDEX idx_richiesta_assegnazione ON RICHIESTA_VARIAZIONE (id_assegnazione);
CREATE INDEX idx_audit_tabella_chiave ON AUDIT_LOG (tabella, chiave);
CREATE INDEX idx_audit_data ON AUDIT_LOG (data_ora);
