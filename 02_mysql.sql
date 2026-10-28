-- =====================================================================
-- Laboratorio de Bases de Datos · Esquema BOMBERO (estación de bomberos)
-- Gestor: MySQL 8.0.17 o superior (InnoDB)
-- Ejecución:  mysql -u root -p --default-character-set=utf8mb4 < 02_mysql.sql
-- =====================================================================
-- Nota: MySQL ignora las cláusulas REFERENCES escritas en la columna; por eso
-- todas las claves foráneas se declaran como FOREIGN KEY a nivel de tabla.
SET NAMES utf8mb4;
DROP DATABASE IF EXISTS bombero;
CREATE DATABASE bombero CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bombero;

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
  PRIMARY KEY (tipodoc, nrodoc)
) ENGINE=InnoDB;

CREATE TABLE telefono (
  nrotelefono VARCHAR(15) NOT NULL,
  tipodoc     VARCHAR(3)  NOT NULL,
  nrodoc      VARCHAR(8)  NOT NULL,
  PRIMARY KEY (nrotelefono, tipodoc, nrodoc),
  FOREIGN KEY (tipodoc, nrodoc) REFERENCES bombero (tipodoc, nrodoc)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE accidente (
  idaccidente     INT         PRIMARY KEY,
  fecha           DATE        NOT NULL,
  cantidadheridos INT         NOT NULL DEFAULT 0 CHECK (cantidadheridos >= 0),
  localidad       VARCHAR(40) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE transito (
  idaccidente INT PRIMARY KEY,
  motivo      VARCHAR(60) NOT NULL,
  FOREIGN KEY (idaccidente) REFERENCES accidente (idaccidente) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE incendio (
  idaccidente INT PRIMARY KEY,
  tipo        VARCHAR(30) NOT NULL,
  FOREIGN KEY (idaccidente) REFERENCES accidente (idaccidente) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE vehiculo (
  modelo              VARCHAR(40) NOT NULL,
  anio                INT         NOT NULL,
  cantidadpasajeros   INT         NOT NULL DEFAULT 0,
  idaccidentetransito INT         NOT NULL,
  PRIMARY KEY (idaccidentetransito, modelo, anio),
  FOREIGN KEY (idaccidentetransito) REFERENCES transito (idaccidente) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE asiste (
  tipodoc     VARCHAR(3)  NOT NULL,
  nrodoc      VARCHAR(8)  NOT NULL,
  idaccidente INT         NOT NULL,
  rol         VARCHAR(40) NOT NULL,
  PRIMARY KEY (tipodoc, nrodoc, idaccidente),
  FOREIGN KEY (tipodoc, nrodoc) REFERENCES bombero (tipodoc, nrodoc),
  FOREIGN KEY (idaccidente) REFERENCES accidente (idaccidente) ON DELETE CASCADE
) ENGINE=InnoDB;

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

-- ---------------------------------------------------------------- Parte 2: columna JSON (puente relacional-documental)
-- En MariaDB, JSON es un alias de LONGTEXT; no existen los operadores -> y ->>.
-- Por eso se usa JSON_UNQUOTE(JSON_EXTRACT(...)), que funciona en ambos gestores.
CREATE TABLE accidente_doc (
  idaccidente    INT PRIMARY KEY,
  tipo_accidente VARCHAR(10) NOT NULL,
  fecha          DATE NOT NULL,
  localidad      VARCHAR(40),
  detalle        JSON
) ENGINE=InnoDB;

INSERT INTO accidente_doc VALUES
 (1001,'transito','2025-03-14','Neuquén','{"motivo":"Exceso de velocidad",
   "vehiculos":[{"modelo":"Corsa","anio":2012},{"modelo":"Hilux","anio":2019}],
   "roles":[{"rol":"Conductor de autobomba","bombero":{"tipodoc":"DNI","nrodoc":"20111222"}},
            {"rol":"Rescatista","bombero":{"tipodoc":"DNI","nrodoc":"22333444"}}]}'),
 (1002,'transito','2025-04-02','Cipolletti','{"motivo":"Frenada brusca",
   "vehiculos":[{"modelo":"Gol","anio":2015}],
   "roles":[{"rol":"Rescatista","bombero":{"tipodoc":"DNI","nrodoc":"25444555"}},
            {"rol":"Jefe de dotación","bombero":{"tipodoc":"DNI","nrodoc":"20111222"}}]}'),
 (2001,'incendio','2025-05-20','Neuquén','{"tipo":"Vivienda",
   "roles":[{"rol":"Jefe de dotación","bombero":{"tipodoc":"DNI","nrodoc":"20111222"}},
            {"rol":"Rescatista","bombero":{"tipodoc":"DNI","nrodoc":"22333444"}}]}'),
 (2002,'incendio','2025-06-11','General Roca','{"tipo":"Forestal",
   "roles":[{"rol":"Brigadista","bombero":{"tipodoc":"DNI","nrodoc":"30555666"}}]}');

-- Extraer un campo
SELECT idaccidente, JSON_UNQUOTE(JSON_EXTRACT(detalle,'$.motivo')) AS motivo
  FROM accidente_doc WHERE tipo_accidente = 'transito';

-- Accidentes donde participó el bombero 20111222 (esperado: 1001, 1002, 2001)
SELECT idaccidente FROM accidente_doc
 WHERE JSON_SEARCH(detalle,'one','20111222',NULL,'$.roles[*].bombero.nrodoc') IS NOT NULL;

-- Conteo por bombero (esperado: 20111222 -> 3, 22333444 -> 2, 25444555 -> 1, 30555666 -> 1)
SELECT jt.nrodoc, COUNT(*) AS cantidad
  FROM accidente_doc,
       JSON_TABLE(detalle,'$.roles[*]'
         COLUMNS (nrodoc VARCHAR(8) PATH '$.bombero.nrodoc')) AS jt
 GROUP BY jt.nrodoc ORDER BY cantidad DESC, jt.nrodoc;

-- Indexar un campo del documento mediante una columna generada
ALTER TABLE accidente_doc
  ADD COLUMN motivo VARCHAR(40) GENERATED ALWAYS AS
      (JSON_UNQUOTE(JSON_EXTRACT(detalle,'$.motivo'))) VIRTUAL,
  ADD INDEX idx_motivo (motivo);
