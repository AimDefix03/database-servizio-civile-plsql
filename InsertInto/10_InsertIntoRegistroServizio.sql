-- A1
INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (1, 1, DATE '2025-01-21', 'SERVIZIO', 7.0, 0, 'VALIDATA', 'Prima giornata operativa regolarmente svolta.');

INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (2, 1, DATE '2025-01-22', 'SERVIZIO', 5.0, 2.0, 'VALIDATA', 'Uscita anticipata con recupero previsto.');

INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (3, 1, DATE '2025-01-23', 'PERMESSO_ORDINARIO', 0, 0, 'VALIDATA', 'Permesso ordinario autorizzato.');

-- A2
INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (4, 2, DATE '2025-02-06', 'SERVIZIO', 8.0, 0, 'VALIDATA', 'Giornata piena di servizio.');

INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (5, 2, DATE '2025-02-07', 'MALATTIA_RETRIBUITA', 0, 0, 'VALIDATA', 'Assenza per malattia con certificazione.');

INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (6, 2, DATE '2025-02-10', 'SERVIZIO', 6.0, 1.0, 'DA_VALIDARE', 'Servizio svolto con recupero residuo.');

-- A3
INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (7, 3, DATE '2025-03-05', 'SERVIZIO', 7.0, 0, 'VALIDATA', 'Attivita ordinaria svolta regolarmente.');

INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (8, 3, DATE '2025-03-06', 'PERMESSO_STRAORDINARIO', 0, 0, 'VALIDATA', 'Permesso straordinario con motivazione approvata.');

-- A4
INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (9, 4, DATE '2025-05-06', 'SERVIZIO', 8.0, 0, 'VALIDATA', 'Avvio regolare della nuova assegnazione.');

INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (10, 4, DATE '2025-05-07', 'SERVIZIO', 4.0, 3.0, 'DA_VALIDARE', 'Presenza ridotta con ore da recuperare.');

-- A5
INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (11, 5, DATE '2025-02-26', 'SERVIZIO', 8.0, 0, 'VALIDATA', 'Servizio completato regolarmente.');

INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (12, 5, DATE '2025-03-03', 'MALATTIA_NON_RETRIBUITA', 0, 0, 'VALIDATA', 'Giornata di malattia non retribuita.');

INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (13, 5, DATE '2025-03-04', 'SERVIZIO', 6.0, 0, 'RIFIUTATA', 'Registrazione respinta per errore nella descrizione.');

-- A6
INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (14, 6, DATE '2025-04-11', 'SERVIZIO', 7.0, 0, 'VALIDATA', 'Giornata svolta correttamente.');

INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (15, 6, DATE '2025-04-12', 'PERMESSO_ORDINARIO', 0, 0, 'VALIDATA', 'Permesso ordinario richiesto e concesso.');

-- A7
INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (16, 7, DATE '2025-03-18', 'SERVIZIO', 8.0, 0, 'VALIDATA', 'Giornata piena.');

INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (17, 7, DATE '2025-03-19', 'SERVIZIO', 5.0, 2.0, 'DA_VALIDARE', 'Riduzione oraria con recupero previsto.');

-- A8
INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (18, 8, DATE '2025-03-21', 'SERVIZIO', 7.5, 0, 'VALIDATA', 'Servizio ordinario.');

INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (19, 8, DATE '2025-03-22', 'PERMESSO_STRAORDINARIO', 0, 0, 'VALIDATA', 'Permesso straordinario autorizzato.');

-- A9
INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (20, 9, DATE '2025-03-13', 'SERVIZIO', 8.0, 0, 'VALIDATA', 'Presenza completa.');

INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (21, 9, DATE '2025-03-14', 'MALATTIA_RETRIBUITA', 0, 0, 'VALIDATA', 'Malattia retribuita registrata.');

-- A10
INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (22, 10, DATE '2025-03-11', 'SERVIZIO', 6.0, 1.0, 'VALIDATA', 'Servizio svolto con lieve recupero residuo.');

INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (23, 10, DATE '2025-03-12', 'PERMESSO_ORDINARIO', 0, 0, 'VALIDATA', 'Permesso ordinario.');

-- A11
INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (24, 11, DATE '2025-04-09', 'SERVIZIO', 8.0, 0, 'VALIDATA', 'Servizio regolare.');

-- A12
INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (25, 12, DATE '2025-02-20', 'SERVIZIO', 7.0, 0, 'VALIDATA', 'Ultime giornate del progetto concluse regolarmente.');

-- A14
INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (26, 14, DATE '2025-02-10', 'SERVIZIO', 6.0, 0, 'VALIDATA', 'Servizio svolto prima della conclusione.');

-- A15
INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (27, 15, DATE '2025-05-05', 'SERVIZIO', 4.0, 3.0, 'VALIDATA', 'Riduzione oraria nel periodo finale.');

-- A16
INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (28, 16, DATE '2025-03-25', 'MALATTIA_NON_RETRIBUITA', 0, 0, 'VALIDATA', 'Giornata di malattia non retribuita.');

-- A17
INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (29, 17, DATE '2025-05-07', 'SERVIZIO', 8.0, 0, 'VALIDATA', 'Giornata ordinaria.');

INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (30, 17, DATE '2025-05-08', 'SERVIZIO', 5.0, 2.0, 'DA_VALIDARE', 'Recupero da pianificare entro la settimana.');

-- A18
INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (31, 18, DATE '2025-04-15', 'SERVIZIO', 7.0, 0, 'VALIDATA', 'Giornata regolare di servizio.');

INSERT INTO REGISTRO_SERVIZIO (id_registro, id_assegnazione, data_servizio, tipo_giornata, ore_svolte, ore_da_recuperare, stato_validazione, note)
VALUES (32, 18, DATE '2025-04-16', 'PERMESSO_STRAORDINARIO', 0, 0, 'VALIDATA', 'Permesso straordinario con motivazione documentata.');