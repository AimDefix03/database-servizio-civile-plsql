-- =============================================================================
-- Sicurezza: ruoli e privilegi (principio del minimo privilegio)
--
-- Lo script crea tre ruoli. Gli utenti NON vengono creati qui, per evitare
-- credenziali nel repository: crearli separatamente e assegnare il ruolo, es.
--
--   CREATE USER mario_rossi IDENTIFIED BY "<password>";
--   GRANT CREATE SESSION TO mario_rossi;
--   GRANT ruolo_amministratore TO mario_rossi;
-- =============================================================================

CREATE ROLE ruolo_amministratore;
CREATE ROLE ruolo_operatore;
CREATE ROLE ruolo_volontario;

-- Amministratore: gestione completa dei dati
GRANT SELECT, INSERT, UPDATE, DELETE ON ENTE TO ruolo_amministratore;
GRANT SELECT, INSERT, UPDATE, DELETE ON SEDE TO ruolo_amministratore;
GRANT SELECT, INSERT, UPDATE, DELETE ON OPERATORE TO ruolo_amministratore;
GRANT SELECT, INSERT, UPDATE, DELETE ON PROGETTO TO ruolo_amministratore;
GRANT SELECT, INSERT, UPDATE, DELETE ON PROGETTO_SEDE TO ruolo_amministratore;
GRANT SELECT, INSERT, UPDATE, DELETE ON VOLONTARIO TO ruolo_amministratore;
GRANT SELECT, INSERT, UPDATE, DELETE ON ASSEGNAZIONE TO ruolo_amministratore;
GRANT SELECT, INSERT, UPDATE, DELETE ON FORMAZIONE TO ruolo_amministratore;
GRANT SELECT, INSERT, UPDATE, DELETE ON ASSEGNAZIONE_FORMAZIONE TO ruolo_amministratore;
GRANT SELECT, INSERT, UPDATE, DELETE ON MONITORAGGIO TO ruolo_amministratore;
GRANT SELECT, INSERT, UPDATE, DELETE ON REGISTRO_SERVIZIO TO ruolo_amministratore;
GRANT SELECT, INSERT, UPDATE, DELETE ON RICHIESTA_VARIAZIONE TO ruolo_amministratore;
GRANT SELECT ON Presenze_Da_Validare TO ruolo_amministratore;
GRANT EXECUTE ON disattiva_progetto TO ruolo_amministratore;
GRANT EXECUTE ON registra_formazione TO ruolo_amministratore;
GRANT EXECUTE ON registra_partecipazione_formazione TO ruolo_amministratore;
GRANT EXECUTE ON registra_monitoraggio TO ruolo_amministratore;
GRANT EXECUTE ON crea_progetto TO ruolo_amministratore;
GRANT EXECUTE ON modifica_progetto TO ruolo_amministratore;
GRANT EXECUTE ON crea_assegnazione TO ruolo_amministratore;
GRANT EXECUTE ON gestisci_richiesta_variazione TO ruolo_amministratore;
GRANT EXECUTE ON valida_presenza TO ruolo_amministratore;
GRANT EXECUTE ON inserisci_presenza TO ruolo_amministratore;

-- Operatore: consulta le anagrafiche, gestisce formazione e monitoraggi
GRANT SELECT ON VOLONTARIO TO ruolo_operatore;
GRANT SELECT ON PROGETTO TO ruolo_operatore;
GRANT SELECT ON SEDE TO ruolo_operatore;
GRANT SELECT ON ASSEGNAZIONE TO ruolo_operatore;
GRANT SELECT, INSERT, UPDATE ON FORMAZIONE TO ruolo_operatore;
GRANT SELECT, INSERT, UPDATE ON ASSEGNAZIONE_FORMAZIONE TO ruolo_operatore;
GRANT SELECT, INSERT, UPDATE ON MONITORAGGIO TO ruolo_operatore;
GRANT SELECT ON REGISTRO_SERVIZIO TO ruolo_operatore;
GRANT SELECT ON RICHIESTA_VARIAZIONE TO ruolo_operatore;
GRANT SELECT ON Presenze_Da_Validare TO ruolo_operatore;
GRANT EXECUTE ON registra_formazione TO ruolo_operatore;
GRANT EXECUTE ON registra_partecipazione_formazione TO ruolo_operatore;
GRANT EXECUTE ON registra_monitoraggio TO ruolo_operatore;

-- Volontario: consulta il proprio percorso e compila il registro di servizio
GRANT SELECT ON ASSEGNAZIONE TO ruolo_volontario;
GRANT SELECT ON FORMAZIONE TO ruolo_volontario;
GRANT SELECT ON ASSEGNAZIONE_FORMAZIONE TO ruolo_volontario;
GRANT SELECT ON MONITORAGGIO TO ruolo_volontario;
GRANT SELECT ON RICHIESTA_VARIAZIONE TO ruolo_volontario;
GRANT SELECT, INSERT, UPDATE ON REGISTRO_SERVIZIO TO ruolo_volontario;
GRANT EXECUTE ON inserisci_presenza TO ruolo_volontario;
