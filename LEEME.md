# Scripts del esquema BOMBERO por gestor

Laboratorio de Bases de Datos · Unidad IV (Partes 1 y 2) · Dra. Rafaela Mazalu · FaI-UNComa

Todos los scripts cargan **los mismos datos**: cuatro bomberos (Ana, Luis, Marta y Diego), cuatro accidentes
(1001 y 1002 de tránsito; 2001 y 2002 de incendio), tres vehículos y siete asistencias. Por eso el resultado
de la consulta de control es el mismo en todos: **Ana 3, Luis 2, Marta 1, Diego 1**.

| Archivo | Gestor | Modelo | Cómo ejecutarlo | Estado |
|---|---|---|---|---|
| `01_postgresql.sql` | PostgreSQL 14+ | Relacional (7 tablas, con claves foráneas) | `psql -U postgres -f 01_postgresql.sql` | Ejecutado y verificado en PostgreSQL 16 |
| `02_mysql.sql` | MySQL 8.0.17+ | Relacional + columna JSON | `mysql -u root -p --default-character-set=utf8mb4 < 02_mysql.sql` | Sin ejecutar |
| `03_mariadb.sql` | MariaDB 10.6+ | Relacional + columna JSON | `mariadb -u root -p --default-character-set=utf8mb4 < 03_mariadb.sql` | Sin ejecutar |
| `04_yugabytedb.sql` | YugabyteDB (YSQL) | Relacional distribuido (`SPLIT INTO 3 TABLETS`) | `ysqlsh -h localhost -p 5433 -U yugabyte -f 04_yugabytedb.sql` | Sin ejecutar (es el script de PostgreSQL con tablets) |
| `05_postgresql_jsonb.sql` | PostgreSQL 14+ | Híbrido: columna `jsonb` + índice GIN | `psql -U postgres -f 05_postgresql_jsonb.sql` | Ejecutado y verificado en PostgreSQL 16 |
| `06_mongodb.js` | MongoDB 6+ | Documental, 2 colecciones (pauta 9) | `mongosh --file 06_mongodb.js` | Sin ejecutar |
| `07_redis.redis` | Redis 7+ | Clave-valor (hashes, conjuntos, conjunto ordenado) | `redis-cli --raw < 07_redis.redis` | Ejecutado y verificado en Redis |
| `08_cassandra.cql` | Cassandra 4.1+ / 5.0 | Familia de columnas, una tabla por consulta | `cqlsh -f 08_cassandra.cql` | Sin ejecutar |
| `09_neo4j.cypher` | Neo4j 5 Community | Grafo | `cypher-shell -u neo4j -p lbd-clave-2026 -f 09_neo4j.cypher` | Sin ejecutar |

## Con contenedores

Las imágenes y los puertos están en la Tabla 4.12 del apunte de la Parte 2. Para copiar un script dentro de un contenedor:

```
docker cp 08_cassandra.cql cass:/tmp/ && docker exec -it cass cqlsh -f /tmp/08_cassandra.cql
docker exec -i redis redis-cli --raw < 07_redis.redis
docker exec -i mongo1 mongosh < 06_mongodb.js
```

Con Podman, reemplazar `docker` por `podman`.

## Diferencias de diseño que conviene notar

* **MySQL ignora las cláusulas `REFERENCES` escritas en la columna**: por eso las claves foráneas de `02_mysql.sql` y `03_mariadb.sql` están declaradas con `FOREIGN KEY` a nivel de tabla.
* **MariaDB no tiene los operadores `->` y `->>`**: los scripts usan `JSON_UNQUOTE(JSON_EXTRACT(...))`, que funciona en MySQL y en MariaDB.
* **MongoDB** usa una sola colección `accidente` con `tipo_accidente` (pauta 9 de la cátedra); los teléfonos y vehículos van embebidos y los roles referencian al bombero.
* **Cassandra**: la clave de partición es `(localidad, anio)` para evitar particiones sin límite; sin la clave de partición completa, las consultas se rechazan.
* **Redis** no tiene consultas por contenido: el índice por localidad (`localidad:<nombre>`) se mantiene a mano.
* **Neo4j Community** no admite claves de nodo compuestas (solo Enterprise): por eso la restricción de unicidad es sobre `nrodoc`.
* **Neo4j**: el apunte (Ejemplo 4.18) usa la propiedad `tipo` en los accidentes y ahí `tipo` es solo el tipo de accidente; en este script la propiedad se llama `tipo_accidente`, y `tipo` queda para el tipo de incendio.

## Estructura de claves del script de Redis

| Clave | Tipo | Contenido |
|---|---|---|
| `bombero:<nrodoc>` | hash | legajo del bombero |
| `telefonos:<nrodoc>` | conjunto | teléfonos del bombero |
| `localidad:<nombre>` | conjunto | legajos de la localidad (índice mantenido a mano) |
| `accidente:<id>` | hash | datos comunes y propios del accidente |
| `accidente:<id>:roles` | hash | `nrodoc` → rol |
| `accidente:<id>:vehiculos` | hash | `n` → `modelo\|anio\|pasajeros` |
| `bombero:<nrodoc>:accidentes` | conjunto | accidentes asistidos |
| `ranking:asistencias` | conjunto ordenado | puntaje = accidentes asistidos |

Consultas de control incluidas en el script: ranking (`ZRANGE ... REV WITHSCORES`), bomberos de Neuquén (`SMEMBERS`) y accidentes en común de Ana y Luis (`SINTER`, esperado 1001 y 2001).
