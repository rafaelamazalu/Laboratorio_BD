-- =====================================================================
-- Laboratorio de Bases de Datos · Esquema BOMBERO · Cassandra
-- Gestor: Apache Cassandra 4.1 o superior (probado el diseño para 5.0)
-- Ejecución:  cqlsh -f 08_cassandra.cql
--   (con contenedor: docker cp 08_cassandra.cql cass:/tmp/ && docker exec -it cass cqlsh -f /tmp/08_cassandra.cql)
-- Diseño query-first: una tabla por consulta; los datos se repiten.
-- =====================================================================
DROP KEYSPACE IF EXISTS bombero;
CREATE KEYSPACE bombero WITH replication = { 'class': 'SimpleStrategy', 'replication_factor': 1 };
USE bombero;

-- Consulta 1: accidentes de una localidad en un año, a partir de una fecha.
-- La partición (localidad, anio) evita que una localidad acumule todos los accidentes de la historia.
CREATE TABLE accidente_por_localidad (
  localidad text,
  anio int,
  fecha date,
  idaccidente int,
  tipo_accidente text,
  cantidadheridos int,
  detalle text,
  PRIMARY KEY ((localidad, anio), fecha, idaccidente)
) WITH CLUSTERING ORDER BY (fecha DESC, idaccidente ASC);

-- Consulta 2: accidentes que asistió un bombero, del más reciente al más antiguo.
CREATE TABLE accidente_por_bombero (
  tipodoc text,
  nrodoc text,
  fecha date,
  idaccidente int,
  rol text,
  localidad text,
  tipo_accidente text,
  PRIMARY KEY ((tipodoc, nrodoc), fecha, idaccidente)
) WITH CLUSTERING ORDER BY (fecha DESC, idaccidente ASC);

-- Consulta 3: quiénes asistieron a un accidente y con qué rol.
CREATE TABLE rol_por_accidente (
  idaccidente int,
  tipodoc text,
  nrodoc text,
  rol text,
  PRIMARY KEY ((idaccidente), tipodoc, nrodoc)
);

-- Consulta 4: bomberos de una localidad.
CREATE TABLE bombero_por_localidad (
  localidad text,
  tipodoc text,
  nrodoc text,
  nombre text,
  apellido text,
  anios_servicio int,
  genero text,
  telefonos set<text>,
  PRIMARY KEY ((localidad), tipodoc, nrodoc)
);

-- Consulta 5: contador de asistencias por bombero.
CREATE TABLE asistencias_por_bombero (
  tipodoc text,
  nrodoc text,
  cantidad counter,
  PRIMARY KEY ((tipodoc, nrodoc))
);

-- Alerta que se borra sola (TTL)
CREATE TABLE alerta (id int PRIMARY KEY, mensaje text);

-- ---------------------------------------------------------------- Datos
INSERT INTO bombero_por_localidad (localidad, tipodoc, nrodoc, nombre, apellido, anios_servicio, genero, telefonos)
  VALUES ('Neuquén', 'DNI', '20111222', 'Ana', 'Pérez', 12, 'F', {'2994421122'});
INSERT INTO bombero_por_localidad (localidad, tipodoc, nrodoc, nombre, apellido, anios_servicio, genero, telefonos)
  VALUES ('Cipolletti', 'DNI', '22333444', 'Luis', 'Gómez', 8, 'M', {'2994765432'});
INSERT INTO bombero_por_localidad (localidad, tipodoc, nrodoc, nombre, apellido, anios_servicio, genero)
  VALUES ('General Roca', 'DNI', '25444555', 'Marta', 'Sosa', 15, 'F');
INSERT INTO bombero_por_localidad (localidad, tipodoc, nrodoc, nombre, apellido, anios_servicio, genero)
  VALUES ('Neuquén', 'DNI', '30555666', 'Diego', 'Ruiz', 3, 'M');

INSERT INTO accidente_por_localidad (localidad, anio, fecha, idaccidente, tipo_accidente, cantidadheridos, detalle)
  VALUES ('Neuquén', 2025, '2025-03-14', 1001, 'transito', 2, 'Exceso de velocidad');
INSERT INTO accidente_por_localidad (localidad, anio, fecha, idaccidente, tipo_accidente, cantidadheridos, detalle)
  VALUES ('Cipolletti', 2025, '2025-04-02', 1002, 'transito', 0, 'Frenada brusca');
INSERT INTO accidente_por_localidad (localidad, anio, fecha, idaccidente, tipo_accidente, cantidadheridos, detalle)
  VALUES ('Neuquén', 2025, '2025-05-20', 2001, 'incendio', 1, 'Vivienda');
INSERT INTO accidente_por_localidad (localidad, anio, fecha, idaccidente, tipo_accidente, cantidadheridos, detalle)
  VALUES ('General Roca', 2025, '2025-06-11', 2002, 'incendio', 0, 'Forestal');

-- asistencias: (bombero, accidente, rol)
INSERT INTO accidente_por_bombero (tipodoc, nrodoc, fecha, idaccidente, rol, localidad, tipo_accidente) VALUES ('DNI', '20111222', '2025-03-14', 1001, 'Conductor de autobomba', 'Neuquén', 'transito');
INSERT INTO accidente_por_bombero (tipodoc, nrodoc, fecha, idaccidente, rol, localidad, tipo_accidente) VALUES ('DNI', '22333444', '2025-03-14', 1001, 'Rescatista', 'Neuquén', 'transito');
INSERT INTO accidente_por_bombero (tipodoc, nrodoc, fecha, idaccidente, rol, localidad, tipo_accidente) VALUES ('DNI', '25444555', '2025-04-02', 1002, 'Rescatista', 'Cipolletti', 'transito');
INSERT INTO accidente_por_bombero (tipodoc, nrodoc, fecha, idaccidente, rol, localidad, tipo_accidente) VALUES ('DNI', '20111222', '2025-04-02', 1002, 'Jefe de dotación', 'Cipolletti', 'transito');
INSERT INTO accidente_por_bombero (tipodoc, nrodoc, fecha, idaccidente, rol, localidad, tipo_accidente) VALUES ('DNI', '20111222', '2025-05-20', 2001, 'Jefe de dotación', 'Neuquén', 'incendio');
INSERT INTO accidente_por_bombero (tipodoc, nrodoc, fecha, idaccidente, rol, localidad, tipo_accidente) VALUES ('DNI', '22333444', '2025-05-20', 2001, 'Rescatista', 'Neuquén', 'incendio');
INSERT INTO accidente_por_bombero (tipodoc, nrodoc, fecha, idaccidente, rol, localidad, tipo_accidente) VALUES ('DNI', '30555666', '2025-06-11', 2002, 'Brigadista', 'General Roca', 'incendio');

INSERT INTO rol_por_accidente (idaccidente, tipodoc, nrodoc, rol) VALUES (1001, 'DNI', '20111222', 'Conductor de autobomba');
INSERT INTO rol_por_accidente (idaccidente, tipodoc, nrodoc, rol) VALUES (1001, 'DNI', '22333444', 'Rescatista');
INSERT INTO rol_por_accidente (idaccidente, tipodoc, nrodoc, rol) VALUES (1002, 'DNI', '25444555', 'Rescatista');
INSERT INTO rol_por_accidente (idaccidente, tipodoc, nrodoc, rol) VALUES (1002, 'DNI', '20111222', 'Jefe de dotación');
INSERT INTO rol_por_accidente (idaccidente, tipodoc, nrodoc, rol) VALUES (2001, 'DNI', '20111222', 'Jefe de dotación');
INSERT INTO rol_por_accidente (idaccidente, tipodoc, nrodoc, rol) VALUES (2001, 'DNI', '22333444', 'Rescatista');
INSERT INTO rol_por_accidente (idaccidente, tipodoc, nrodoc, rol) VALUES (2002, 'DNI', '30555666', 'Brigadista');

-- contadores (un UPDATE por cada asistencia)
UPDATE asistencias_por_bombero SET cantidad = cantidad + 1 WHERE tipodoc = 'DNI' AND nrodoc = '20111222';
UPDATE asistencias_por_bombero SET cantidad = cantidad + 1 WHERE tipodoc = 'DNI' AND nrodoc = '20111222';
UPDATE asistencias_por_bombero SET cantidad = cantidad + 1 WHERE tipodoc = 'DNI' AND nrodoc = '20111222';
UPDATE asistencias_por_bombero SET cantidad = cantidad + 1 WHERE tipodoc = 'DNI' AND nrodoc = '22333444';
UPDATE asistencias_por_bombero SET cantidad = cantidad + 1 WHERE tipodoc = 'DNI' AND nrodoc = '22333444';
UPDATE asistencias_por_bombero SET cantidad = cantidad + 1 WHERE tipodoc = 'DNI' AND nrodoc = '25444555';
UPDATE asistencias_por_bombero SET cantidad = cantidad + 1 WHERE tipodoc = 'DNI' AND nrodoc = '30555666';

INSERT INTO alerta (id, mensaje) VALUES (1, 'Riesgo de incendio forestal') USING TTL 86400;

-- ---------------------------------------------------------------- Verificación
-- Accidentes de Neuquén en 2025 desde enero (esperado: 2001 y 1001, en ese orden)
SELECT idaccidente, fecha, tipo_accidente FROM accidente_por_localidad
 WHERE localidad = 'Neuquén' AND anio = 2025 AND fecha >= '2025-01-01';

-- Accidentes que asistió Ana (esperado: 2001, 1002, 1001)
SELECT idaccidente, fecha, rol FROM accidente_por_bombero
 WHERE tipodoc = 'DNI' AND nrodoc = '20111222';

-- Contadores (esperado: Ana 3, Luis 2, Marta 1, Diego 1)
SELECT nrodoc, cantidad FROM asistencias_por_bombero;

-- Esta consulta es rechazada: tipo_accidente no forma parte de la clave
-- SELECT * FROM accidente_por_localidad WHERE tipo_accidente = 'incendio';

-- Nivel de consistencia por operación (cqlsh)
CONSISTENCY QUORUM;
