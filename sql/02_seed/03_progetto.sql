-- P1
INSERT INTO PROGETTO (id_progetto, id_ente, titolo, area_intervento, descrizione, data_inizio, data_fine, stato_progetto)
VALUES (1, 1, 'Giovani e Inclusione Sociale', 'ASSISTENZA',
        'Progetto dedicato al supporto di giovani in condizioni di fragilita sociale.',
        DATE '2025-01-10', NULL, 'ATTIVO');

-- P2
INSERT INTO PROGETTO (id_progetto, id_ente, titolo, area_intervento, descrizione, data_inizio, data_fine, stato_progetto)
VALUES (2, 1, 'Educazione Digitale per Tutti', 'EDUCAZIONE',
        'Percorso di alfabetizzazione digitale rivolto a minori, anziani e cittadini vulnerabili.',
        DATE '2024-03-01', DATE '2025-02-28', 'CONCLUSO');

-- P3
INSERT INTO PROGETTO (id_progetto, id_ente, titolo, area_intervento, descrizione, data_inizio, data_fine, stato_progetto)
VALUES (3, 1, 'Territorio e Partecipazione', 'CITTADINANZA_ATTIVA',
        'Progetto orientato alla promozione della partecipazione civica e del volontariato locale.',
        DATE '2025-04-01', NULL, 'ATTIVO');

-- P4
INSERT INTO PROGETTO (id_progetto, id_ente, titolo, area_intervento, descrizione, data_inizio, data_fine, stato_progetto)
VALUES (4, 2, 'Supporto alle Fragilita Urbane', 'ASSISTENZA',
        'Interventi di supporto sociale per persone e famiglie in contesti urbani complessi.',
        DATE '2025-02-15', NULL, 'ATTIVO');

-- P5
INSERT INTO PROGETTO (id_progetto, id_ente, titolo, area_intervento, descrizione, data_inizio, data_fine, stato_progetto)
VALUES (5, 2, 'Memoria e Comunita', 'PATRIMONIO_CULTURALE',
        'Attivita di valorizzazione della memoria storica locale e del patrimonio culturale cittadino.',
        DATE '2024-01-20', DATE '2024-12-20', 'CONCLUSO');

-- P6
INSERT INTO PROGETTO (id_progetto, id_ente, titolo, area_intervento, descrizione, data_inizio, data_fine, stato_progetto)
VALUES (6, 2, 'Scuola Aperta e Innovazione', 'EDUCAZIONE',
        'Azioni di supporto educativo extrascolastico e innovazione nei contesti formativi.',
        DATE '2025-03-10', NULL, 'ATTIVO');

-- P7
INSERT INTO PROGETTO (id_progetto, id_ente, titolo, area_intervento, descrizione, data_inizio, data_fine, stato_progetto)
VALUES (7, 3, 'Reti di Solidarieta Territoriale', 'ASSISTENZA',
        'Costruzione di reti territoriali di sostegno tra enti, cittadini e volontari.',
        DATE '2025-01-05', NULL, 'ATTIVO');

-- P8
INSERT INTO PROGETTO (id_progetto, id_ente, titolo, area_intervento, descrizione, data_inizio, data_fine, stato_progetto)
VALUES (8, 3, 'Laboratori per la Cittadinanza', 'CITTADINANZA_ATTIVA',
        'Laboratori territoriali per la promozione della cittadinanza consapevole e partecipata.',
        DATE '2025-02-01', NULL, 'SOSPESO');