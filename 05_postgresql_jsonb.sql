-- =====================================================================
-- Laboratorio de Bases de Datos · Esquema BOMBERO · Parte 2: jsonb
-- Gestor: PostgreSQL 14 o superior
-- Ejecución:  psql -U postgres -f 05_postgresql_jsonb.sql
-- =====================================================================
DROP DATABASE IF EXISTS bombero_doc;
CREATE DATABASE bombero_doc ENCODING 'UTF8';
\connect bombero_doc

CREATE TABLE accidente (
  idaccidente    int PRIMARY KEY,
  tipo_accidente text NOT NULL
                   CHECK (tipo_accidente IN ('transito', 'incendio')),
  fecha          date NOT NULL,
  localidad      text,
  detalle        jsonb
);

INSERT INTO accidente VALUES
 (1001,'transito','2025-03-14','Neuquén',
  '{"motivo":"Exceso de velocidad",
    "vehiculos":[{"modelo":"Corsa","anio":2012},{"modelo":"Hilux","anio":2019}],
    "roles":[{"rol":"Conductor de autobomba","bombero":{"tipodoc":"DNI","nrodoc":"20111222"}},
             {"rol":"Rescatista","bombero":{"tipodoc":"DNI","nrodoc":"22333444"}}]}'),
 (1002,'transito','2025-04-02','Cipolletti',
  '{"motivo":"Frenada brusca",
    "vehiculos":[{"modelo":"Gol","anio":2015}],
    "roles":[{"rol":"Rescatista","bombero":{"tipodoc":"DNI","nrodoc":"25444555"}},
             {"rol":"Jefe de dotación","bombero":{"tipodoc":"DNI","nrodoc":"20111222"}}]}'),
 (2001,'incendio','2025-05-20','Neuquén',
  '{"tipo":"Vivienda",
    "roles":[{"rol":"Jefe de dotación","bombero":{"tipodoc":"DNI","nrodoc":"20111222"}},
             {"rol":"Rescatista","bombero":{"tipodoc":"DNI","nrodoc":"22333444"}}]}'),
 (2002,'incendio','2025-06-11','General Roca',
  '{"tipo":"Forestal",
    "roles":[{"rol":"Brigadista","bombero":{"tipodoc":"DNI","nrodoc":"30555666"}}]}');

CREATE INDEX accidente_detalle_gin ON accidente USING gin (detalle jsonb_path_ops);

-- 1) Extraer un campo (esperado: 1001 Exceso de velocidad, 1002 Frenada brusca)
SELECT idaccidente, detalle->>'motivo' AS motivo
  FROM accidente WHERE tipo_accidente = 'transito' ORDER BY 1;

-- 2) Participó el bombero 20111222 (esperado: 1001, 1002, 2001)
SELECT idaccidente FROM accidente
 WHERE detalle @> '{"roles":[{"bombero":{"nrodoc":"20111222"}}]}' ORDER BY 1;

-- 3) Conteo por bombero (esperado: 20111222 -> 3, 22333444 -> 2, 25444555 -> 1, 30555666 -> 1)
SELECT r->'bombero'->>'nrodoc' AS nrodoc, count(*)
  FROM accidente, jsonb_array_elements(detalle->'roles') AS r
 GROUP BY 1 ORDER BY 2 DESC, 1;

-- 4) Vehículos posteriores a 2014 (esperado: 1001, 1002)
SELECT idaccidente FROM accidente
 WHERE jsonb_path_exists(detalle, '$.vehiculos[*] ? (@.anio > 2014)') ORDER BY 1;
