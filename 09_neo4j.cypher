// =====================================================================
// Laboratorio de Bases de Datos · Esquema BOMBERO · Neo4j
// Gestor: Neo4j 5 Community
// Ejecución:  cypher-shell -u neo4j -p lbd-clave-2026 -f 09_neo4j.cypher
//   (con contenedor: docker cp 09_neo4j.cypher neo4j:/tmp/ &&
//    docker exec -it neo4j cypher-shell -u neo4j -p lbd-clave-2026 -f /tmp/09_neo4j.cypher)
// Modelo: nodos Bombero, Accidente (con etiqueta Transito o Incendio) y Vehiculo;
//         relaciones ASISTIO {rol} y INVOLUCRO. Los teléfonos son una propiedad de lista.
// =====================================================================
MATCH (n) DETACH DELETE n;

CREATE CONSTRAINT bombero_nrodoc IF NOT EXISTS FOR (b:Bombero) REQUIRE b.nrodoc IS UNIQUE;
CREATE CONSTRAINT accidente_id IF NOT EXISTS FOR (a:Accidente) REQUIRE a.idaccidente IS UNIQUE;

CREATE
  (ana:Bombero   {tipodoc: 'DNI', nrodoc: '20111222', nombre: 'Ana',   apellido: 'Pérez', anios_servicio: 12, localidad: 'Neuquén',      genero: 'F', telefonos: ['2994421122']}),
  (luis:Bombero  {tipodoc: 'DNI', nrodoc: '22333444', nombre: 'Luis',  apellido: 'Gómez', anios_servicio: 8,  localidad: 'Cipolletti',   genero: 'M', telefonos: ['2994765432']}),
  (marta:Bombero {tipodoc: 'DNI', nrodoc: '25444555', nombre: 'Marta', apellido: 'Sosa',  anios_servicio: 15, localidad: 'General Roca', genero: 'F', telefonos: []}),
  (diego:Bombero {tipodoc: 'DNI', nrodoc: '30555666', nombre: 'Diego', apellido: 'Ruiz',  anios_servicio: 3,  localidad: 'Neuquén',      genero: 'M', telefonos: []}),
  (a1:Accidente:Transito {idaccidente: 1001, tipo_accidente: 'transito', fecha: date('2025-03-14'), localidad: 'Neuquén',      cantidadheridos: 2, motivo: 'Exceso de velocidad'}),
  (a2:Accidente:Transito {idaccidente: 1002, tipo_accidente: 'transito', fecha: date('2025-04-02'), localidad: 'Cipolletti',   cantidadheridos: 0, motivo: 'Frenada brusca'}),
  (a3:Accidente:Incendio {idaccidente: 2001, tipo_accidente: 'incendio', fecha: date('2025-05-20'), localidad: 'Neuquén',      cantidadheridos: 1, tipo: 'Vivienda'}),
  (a4:Accidente:Incendio {idaccidente: 2002, tipo_accidente: 'incendio', fecha: date('2025-06-11'), localidad: 'General Roca', cantidadheridos: 0, tipo: 'Forestal'}),
  (v1:Vehiculo {modelo: 'Corsa', anio: 2012, cantidadPasajeros: 2}),
  (v2:Vehiculo {modelo: 'Hilux', anio: 2019, cantidadPasajeros: 1}),
  (v3:Vehiculo {modelo: 'Gol',   anio: 2015, cantidadPasajeros: 1}),
  (a1)-[:INVOLUCRO]->(v1), (a1)-[:INVOLUCRO]->(v2), (a2)-[:INVOLUCRO]->(v3),
  (ana)-[:ASISTIO   {rol: 'Conductor de autobomba'}]->(a1),
  (luis)-[:ASISTIO  {rol: 'Rescatista'}]->(a1),
  (marta)-[:ASISTIO {rol: 'Rescatista'}]->(a2),
  (ana)-[:ASISTIO   {rol: 'Jefe de dotación'}]->(a2),
  (ana)-[:ASISTIO   {rol: 'Jefe de dotación'}]->(a3),
  (luis)-[:ASISTIO  {rol: 'Rescatista'}]->(a3),
  (diego)-[:ASISTIO {rol: 'Brigadista'}]->(a4);

// ---------------------------------------------------------------- Verificación
// Accidentes asistidos por bombero (esperado: Ana 3, Luis 2, Diego 1, Marta 1)
MATCH (b:Bombero)-[:ASISTIO]->(a:Accidente)
RETURN b.nombre AS bombero, count(a) AS accidentes
ORDER BY accidentes DESC, bombero;

// ¿Con quién trabajó Ana? (esperado: Luis 2, Marta 1)
MATCH (ana:Bombero {nombre: 'Ana'})-[:ASISTIO]->(a:Accidente)<-[:ASISTIO]-(c:Bombero)
RETURN c.nombre AS companiero, count(a) AS accidentes_en_comun
ORDER BY accidentes_en_comun DESC;
