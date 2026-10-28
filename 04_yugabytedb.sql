-- =====================================================================
-- Laboratorio de Bases de Datos · Esquema BOMBERO (estación de bomberos)
-- Gestor: YugabyteDB 2.x o superior (YSQL, compatible con PostgreSQL)
-- Ejecución:  ysqlsh -h localhost -p 5433 -U yugabyte -f 04_yugabytedb.sql
--             (o psql -h localhost -p 5433 -U yugabyte -f 04_yugabytedb.sql)
-- =====================================================================
DROP DATABASE IF EXISTS bombero;
CREATE DATABASE bombero;
\connect bombero

-- ---------------------------------------------------------------- DDL
CREATE TABLE bombero (
  tipodoc        VARCHAR(3)  NOT NULL CHECK (tipodoc IN ('DNI','LE','LC','PAS')),
  nrodoc         VARCHAR(8)  NOT NULL,
  nombre         VARCHAR(50) NOT NULL,
  apellido       VARCHAR(50) NOT NULL,
  anios_servicio INT         NOT NULL DEFAULT 0 CHECK (anios_servicio BETWEEN 0 AND 60),
  localidad      VARCHAR(40) NOT NULL,
  genero         CHAR(1)     CHECK (genero IN ('F','M','X')),
  cantidadaccidentesasistidos INT NOT NULL DEFAULT 0,
  PRIMARY KEY ((tipodoc, nrodoc) HASH)
) SPLIT INTO 3 TABLETS;

CREATE TABLE telefono (
  nrotelefono VARCHAR(15) NOT NULL,
  tipodoc     VARCHAR(3)  NOT NULL,
  nrodoc      VARCHAR(8)  NOT NULL,
  PRIMARY KEY (nrotelefono, tipodoc, nrodoc),
  FOREIGN KEY (tipodoc, nrodoc) REFERENCES bombero (tipodoc, nrodoc)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE accidente (
  idaccidente     INT         PRIMARY KEY,
  fecha           DATE        NOT NULL,
  cantidadheridos INT         NOT NULL DEFAULT 0 CHECK (cantidadheridos >= 0),
  localidad       VARCHAR(40) NOT NULL
) SPLIT INTO 3 TABLETS;

CREATE TABLE transito (
  idaccidente INT PRIMARY KEY REFERENCES accidente (idaccidente) ON DELETE CASCADE,
  motivo      VARCHAR(60) NOT NULL
);

CREATE TABLE incendio (
  idaccidente INT PRIMARY KEY REFERENCES accidente (idaccidente) ON DELETE CASCADE,
  tipo        VARCHAR(30) NOT NULL
);

CREATE TABLE vehiculo (
  modelo              VARCHAR(40) NOT NULL,
  anio                INT         NOT NULL,
  cantidadpasajeros   INT         NOT NULL DEFAULT 0,
  idaccidentetransito INT         NOT NULL REFERENCES transito (idaccidente) ON DELETE CASCADE,
  PRIMARY KEY (idaccidentetransito, modelo, anio)
);

CREATE TABLE asiste (
  tipodoc     VARCHAR(3)  NOT NULL,
  nrodoc      VARCHAR(8)  NOT NULL,
  idaccidente INT         NOT NULL REFERENCES accidente (idaccidente) ON DELETE CASCADE,
  rol         VARCHAR(40) NOT NULL,
  PRIMARY KEY (tipodoc, nrodoc, idaccidente),
  FOREIGN KEY (tipodoc, nrodoc) REFERENCES bombero (tipodoc, nrodoc)
);

-- ---------------------------------------------------------------- Datos
INSERT INTO bombero (tipodoc, nrodoc, nombre, apellido, anios_servicio, localidad, genero) VALUES
 ('DNI','20111222','Ana',  'Pérez', 12,'Neuquén',     'F'),
 ('DNI','22333444','Luis', 'Gómez',  8,'Cipolletti',  'M'),
 ('DNI','25444555','Marta','Sosa',  15,'General Roca','F'),
 ('DNI','30555666','Diego','Ruiz',   3,'Neuquén',     'M');

INSERT INTO telefono VALUES
 ('2994421122','DNI','20111222'),
 ('2994765432','DNI','22333444');

INSERT INTO accidente VALUES
 (1001,'2025-03-14',2,'Neuquén'),
 (1002,'2025-04-02',0,'Cipolletti'),
 (2001,'2025-05-20',1,'Neuquén'),
 (2002,'2025-06-11',0,'General Roca');

INSERT INTO transito VALUES (1001,'Exceso de velocidad'), (1002,'Frenada brusca');
INSERT INTO incendio VALUES (2001,'Vivienda'), (2002,'Forestal');

INSERT INTO vehiculo VALUES
 ('Corsa',2012,2,1001),
 ('Hilux',2019,1,1001),
 ('Gol',  2015,1,1002);

INSERT INTO asiste VALUES
 ('DNI','20111222',1001,'Conductor de autobomba'),
 ('DNI','22333444',1001,'Rescatista'),
 ('DNI','25444555',1002,'Rescatista'),
 ('DNI','20111222',1002,'Jefe de dotación'),
 ('DNI','20111222',2001,'Jefe de dotación'),
 ('DNI','22333444',2001,'Rescatista'),
 ('DNI','30555666',2002,'Brigadista');

-- atributo derivado almacenado (Unidad 3: triggers)
UPDATE bombero b SET cantidadaccidentesasistidos =
  (SELECT COUNT(*) FROM asiste a WHERE a.tipodoc = b.tipodoc AND a.nrodoc = b.nrodoc);

-- ---------------------------------------------------------------- Verificación
-- Resultado esperado: Ana 3, Luis 2, Marta 1, Diego 1
SELECT b.nombre, b.apellido, COUNT(a.idaccidente) AS accidentes
  FROM bombero b LEFT JOIN asiste a USING (tipodoc, nrodoc)
 GROUP BY b.tipodoc, b.nrodoc, b.nombre, b.apellido
 ORDER BY accidentes DESC, b.apellido;

-- Bomberos sin teléfono: Marta y Diego
SELECT nombre, apellido FROM bombero
 WHERE (tipodoc, nrodoc) NOT IN (SELECT tipodoc, nrodoc FROM telefono);

-- Transacción distribuida: sus filas pueden vivir en tablets con líderes en nodos distintos
BEGIN;
  INSERT INTO accidente VALUES (3001, CURRENT_DATE, 1, 'Neuquén');
  UPDATE bombero SET localidad = 'Neuquén' WHERE tipodoc = 'DNI' AND nrodoc = '22333444';
COMMIT;
-- Interfaz web de administración: http://localhost:7000 (tablets y nodos de cada tabla)
