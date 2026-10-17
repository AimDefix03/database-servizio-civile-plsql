# Diagramma entità-relazione

> File generato da `scripts/genera-documentazione.sh` a partire dal catalogo del database.
> Non modificarlo a mano. Descrizione di tabelle e colonne in [dizionario_dati.md](dizionario_dati.md).

```mermaid
erDiagram
    ASSEGNAZIONE {
        NUMBER id_assegnazione PK
        NUMBER id_volontario FK
        NUMBER id_progetto FK
        NUMBER id_sede FK
        NUMBER id_assegnazione_precedente FK
        DATE data_inizio
        DATE data_fine_prevista
        DATE data_fine_effettiva
        VARCHAR2 stato_assegnazione
        NUMBER ore_settimanali_previste
        NUMBER max_permessi_ordinari
        NUMBER max_malattie_retribuite
        NUMBER max_malattie_non_retribuite
    }
    ASSEGNAZIONE_FORMAZIONE {
        NUMBER id_assegnazione PK,FK
        NUMBER id_formazione PK,FK
        VARCHAR2 presenza
        NUMBER ore_frequentate
        VARCHAR2 note_partecipazione
    }
    AUDIT_LOG {
        NUMBER id_audit PK
        VARCHAR2 tabella
        VARCHAR2 chiave
        VARCHAR2 operazione
        VARCHAR2 utente
        TIMESTAMP data_ora
        VARCHAR2 valori_prima
        VARCHAR2 valori_dopo
    }
    ENTE {
        NUMBER id_ente PK
        VARCHAR2 denominazione
        VARCHAR2 codice_fiscale
        VARCHAR2 indirizzo_sede_legale
        VARCHAR2 email
    }
    FORMAZIONE {
        NUMBER id_formazione PK
        NUMBER id_operatore FK
        VARCHAR2 titolo
        VARCHAR2 tipologia
        DATE data_formazione
        NUMBER durata_ore
        VARCHAR2 descrizione
    }
    MONITORAGGIO {
        NUMBER id_monitoraggio PK
        NUMBER id_assegnazione FK
        DATE data_monitoraggio
        VARCHAR2 tipo_monitoraggio
        VARCHAR2 esito
        VARCHAR2 note
    }
    OPERATORE {
        NUMBER id_operatore PK
        NUMBER id_ente FK
        VARCHAR2 nome
        VARCHAR2 cognome
        VARCHAR2 codice_fiscale
        VARCHAR2 email
        VARCHAR2 telefono
        VARCHAR2 ruolo_operatore
    }
    PROGETTO {
        NUMBER id_progetto PK
        NUMBER id_ente FK
        VARCHAR2 titolo
        VARCHAR2 area_intervento
        VARCHAR2 descrizione
        DATE data_inizio
        DATE data_fine
        VARCHAR2 stato_progetto
    }
    PROGETTO_SEDE {
        NUMBER id_progetto PK,FK
        NUMBER id_sede PK,FK
        NUMBER posti_disponibili
    }
    REGISTRO_SERVIZIO {
        NUMBER id_registro PK
        NUMBER id_assegnazione FK
        DATE data_servizio
        VARCHAR2 tipo_giornata
        NUMBER ore_svolte
        NUMBER ore_da_recuperare
        VARCHAR2 stato_validazione
        VARCHAR2 note
    }
    RICHIESTA_VARIAZIONE {
        NUMBER id_richiesta PK
        NUMBER id_assegnazione FK
        DATE data_richiesta
        VARCHAR2 tipo_variazione
        VARCHAR2 motivazione
        VARCHAR2 stato_richiesta
        DATE data_validazione
    }
    SEDE {
        NUMBER id_sede PK
        NUMBER id_ente FK
        VARCHAR2 nome_sede
        VARCHAR2 indirizzo
        VARCHAR2 comune
        VARCHAR2 provincia
        VARCHAR2 cap_sede
    }
    UTENTE_APPLICATIVO {
        VARCHAR2 username PK
        VARCHAR2 tipo_utente
        NUMBER id_volontario FK
        NUMBER id_operatore FK
    }
    VOLONTARIO {
        NUMBER id_volontario PK
        VARCHAR2 nome
        VARCHAR2 cognome
        VARCHAR2 codice_fiscale
        DATE data_nascita
        VARCHAR2 email
        VARCHAR2 telefono
        VARCHAR2 comune_residenza
        VARCHAR2 stato_volontario
    }
    ASSEGNAZIONE ||--o| ASSEGNAZIONE : "id_assegnazione_precedente"
    PROGETTO ||--o{ ASSEGNAZIONE : "id_progetto"
    SEDE ||--o{ ASSEGNAZIONE : "id_sede"
    VOLONTARIO ||--o{ ASSEGNAZIONE : "id_volontario"
    ASSEGNAZIONE ||--o{ ASSEGNAZIONE_FORMAZIONE : "id_assegnazione"
    FORMAZIONE ||--o{ ASSEGNAZIONE_FORMAZIONE : "id_formazione"
    OPERATORE ||--o{ FORMAZIONE : "id_operatore"
    ASSEGNAZIONE ||--o{ MONITORAGGIO : "id_assegnazione"
    ENTE ||--o{ OPERATORE : "id_ente"
    ENTE ||--o{ PROGETTO : "id_ente"
    PROGETTO ||--o{ PROGETTO_SEDE : "id_progetto"
    SEDE ||--o{ PROGETTO_SEDE : "id_sede"
    ASSEGNAZIONE ||--o{ REGISTRO_SERVIZIO : "id_assegnazione"
    ASSEGNAZIONE ||--o{ RICHIESTA_VARIAZIONE : "id_assegnazione"
    ENTE ||--o{ SEDE : "id_ente"
    OPERATORE ||--o| UTENTE_APPLICATIVO : "id_operatore"
    VOLONTARIO ||--o| UTENTE_APPLICATIVO : "id_volontario"
```
