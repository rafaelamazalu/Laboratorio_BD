// =====================================================================
// Laboratorio de Bases de Datos · Esquema BOMBERO · MongoDB (pauta 9)
// Gestor: MongoDB 6 o superior
// Ejecución:  mongosh --file 06_mongodb.js
//   (en el laboratorio con contenedores: docker exec -i mongo1 mongosh < 06_mongodb.js)
// Modelo: 2 colecciones. TELEFONO y VEHICULO se embeben (pautas 1, 3 y 8);
//         ACCIDENTE, TRANSITO e INCENDIO son una sola colección con tipo_accidente (pauta 9);
//         ASISTE es el arreglo "roles", con la referencia al bombero (pauta 6 y 11).
// =====================================================================
const bd = db.getSiblingDB("bombero");
bd.dropDatabase();

// ---------------------------------------------------------------- bombero
bd.createCollection("bombero", {
  validator: { $jsonSchema: {
    bsonType: "object",
    required: ["tipodoc", "nrodoc", "nombre", "apellido"],
    properties: {
      tipodoc: { bsonType: "string", enum: ["DNI", "LE", "LC", "PAS"] },
      nrodoc: { bsonType: "string" },
      nombre: { bsonType: "string" },
      apellido: { bsonType: "string" },
      anios_servicio: { bsonType: "int", minimum: 0, maximum: 60 },
      telefonos: { bsonType: "array", items: {
        bsonType: "object", required: ["codarea", "numero"],
        properties: { codarea: { bsonType: "string" }, numero: { bsonType: "string" } } } }
    } } },
  validationAction: "error"
});
bd.bombero.createIndex({ tipodoc: 1, nrodoc: 1 }, { unique: true });

bd.bombero.insertMany([
  { tipodoc: "DNI", nrodoc: "20111222", nombre: "Ana", apellido: "Pérez",
    anios_servicio: NumberInt(12), localidad: "Neuquén", genero: "F",
    telefonos: [ { codarea: "299", numero: "4421122" } ] },
  { tipodoc: "DNI", nrodoc: "22333444", nombre: "Luis", apellido: "Gómez",
    anios_servicio: NumberInt(8), localidad: "Cipolletti", genero: "M",
    telefonos: [ { codarea: "299", numero: "4765432" } ] },
  { tipodoc: "DNI", nrodoc: "25444555", nombre: "Marta", apellido: "Sosa",
    anios_servicio: NumberInt(15), localidad: "General Roca", genero: "F",
    telefonos: [] },
  { tipodoc: "DNI", nrodoc: "30555666", nombre: "Diego", apellido: "Ruiz",
    anios_servicio: NumberInt(3), localidad: "Neuquén", genero: "M",
    telefonos: [] }
]);

// ---------------------------------------------------------------- accidente (única colección)
bd.accidente.insertMany([
  { _id: 1001, tipo_accidente: "transito", fecha: ISODate("2025-03-14"),
    localidad: "Neuquén", cantidadheridos: 2, motivo: "Exceso de velocidad",
    vehiculos: [ { modelo: "Corsa", anio: 2012, cantidadPasajeros: 2 },
                 { modelo: "Hilux", anio: 2019, cantidadPasajeros: 1 } ],
    roles: [
      { rol: "Conductor de autobomba", bombero: { tipodoc: "DNI", nrodoc: "20111222" } },
      { rol: "Rescatista",             bombero: { tipodoc: "DNI", nrodoc: "22333444" } } ] },
  { _id: 1002, tipo_accidente: "transito", fecha: ISODate("2025-04-02"),
    localidad: "Cipolletti", cantidadheridos: 0, motivo: "Frenada brusca",
    vehiculos: [ { modelo: "Gol", anio: 2015, cantidadPasajeros: 1 } ],
    roles: [
      { rol: "Rescatista",       bombero: { tipodoc: "DNI", nrodoc: "25444555" } },
      { rol: "Jefe de dotación", bombero: { tipodoc: "DNI", nrodoc: "20111222" } } ] },
  { _id: 2001, tipo_accidente: "incendio", fecha: ISODate("2025-05-20"),
    localidad: "Neuquén", cantidadheridos: 1, tipo: "Vivienda",
    roles: [
      { rol: "Jefe de dotación", bombero: { tipodoc: "DNI", nrodoc: "20111222" } },
      { rol: "Rescatista",       bombero: { tipodoc: "DNI", nrodoc: "22333444" } } ] },
  { _id: 2002, tipo_accidente: "incendio", fecha: ISODate("2025-06-11"),
    localidad: "General Roca", cantidadheridos: 0, tipo: "Forestal",
    roles: [
      { rol: "Brigadista", bombero: { tipodoc: "DNI", nrodoc: "30555666" } } ] }
]);

bd.accidente.createIndex({ localidad: 1, fecha: -1 });
bd.accidente.createIndex({ "roles.bombero.nrodoc": 1 });   // multiclave
bd.accidente.createIndex({ tipo_accidente: 1 });

// ---------------------------------------------------------------- verificación
print("Accidentes asistidos por bombero (esperado: Ana 3, Luis 2, Diego 1, Marta 1):");
bd.accidente.aggregate([
  { $unwind: "$roles" },
  { $group: { _id: { tipodoc: "$roles.bombero.tipodoc", nrodoc: "$roles.bombero.nrodoc" },
              cantidad: { $sum: 1 } } },
  { $lookup: {
      from: "bombero",
      let: { t: "$_id.tipodoc", n: "$_id.nrodoc" },
      pipeline: [
        { $match: { $expr: { $and: [
            { $eq: ["$tipodoc", "$$t"] }, { $eq: ["$nrodoc", "$$n"] } ] } } },
        { $project: { _id: 0, nombre: 1, apellido: 1 } }
      ],
      as: "b" } },
  { $unwind: "$b" },
  { $project: { _id: 0, cantidad: 1,
                bombero: { $concat: ["$b.nombre", " ", "$b.apellido"] } } },
  { $sort: { cantidad: -1, bombero: 1 } }
]).forEach(d => printjson(d));
