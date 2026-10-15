-- R1
INSERT INTO RICHIESTA_VARIAZIONE (
    id_richiesta, id_assegnazione, data_richiesta,
    tipo_variazione, motivazione, stato_richiesta, data_validazione
)
VALUES (
    1, 3, DATE '2025-04-28',
    'CAMBIO_ENTRAMBI',
    'Richiesta di variazione per migliore compatibilita tra sede operativa e attivita progettuali.',
    'APPROVATA', DATE '2025-05-02'
);

-- R2
INSERT INTO RICHIESTA_VARIAZIONE (
    id_richiesta, id_assegnazione, data_richiesta,
    tipo_variazione, motivazione, stato_richiesta, data_validazione
)
VALUES (
    2, 12, DATE '2025-02-27',
    'CAMBIO_ENTRAMBI',
    'Richiesta di riassegnazione a seguito di esigenze organizzative e disponibilita su altro progetto.',
    'APPROVATA', DATE '2025-03-05'
);

-- R3
INSERT INTO RICHIESTA_VARIAZIONE (
    id_richiesta, id_assegnazione, data_richiesta,
    tipo_variazione, motivazione, stato_richiesta, data_validazione
)
VALUES (
    3, 14, DATE '2025-02-16',
    'CAMBIO_ENTRAMBI',
    'Richiesta di riallocazione del volontario su nuova sede e nuovo progetto per continuita del percorso.',
    'APPROVATA', DATE '2025-02-25'
);

-- R4
INSERT INTO RICHIESTA_VARIAZIONE (
    id_richiesta, id_assegnazione, data_richiesta,
    tipo_variazione, motivazione, stato_richiesta, data_validazione
)
VALUES (
    4, 1, DATE '2025-06-25',
    'CAMBIO_SEDE',
    'Richiesta di trasferimento per maggiore vicinanza territoriale alla residenza.',
    'RIFIUTATA', DATE '2025-06-30'
);

-- R5
INSERT INTO RICHIESTA_VARIAZIONE (
    id_richiesta, id_assegnazione, data_richiesta,
    tipo_variazione, motivazione, stato_richiesta, data_validazione
)
VALUES (
    5, 2, DATE '2025-07-05',
    'CAMBIO_PROGETTO',
    'Richiesta di spostamento verso attivita maggiormente coerenti con il profilo formativo del volontario.',
    'IN_ATTESA', NULL
);

-- R6
INSERT INTO RICHIESTA_VARIAZIONE (
    id_richiesta, id_assegnazione, data_richiesta,
    tipo_variazione, motivazione, stato_richiesta, data_validazione
)
VALUES (
    6, 5, DATE '2025-05-12',
    'CAMBIO_SEDE',
    'Richiesta presentata per difficolta logistiche negli spostamenti verso la sede assegnata.',
    'RIFIUTATA', DATE '2025-05-18'
);