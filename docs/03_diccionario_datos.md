# Diccionario de datos

Motor: MySQL 8.0.19 o superior (las restricciones `CHECK` solo se aplican desde la 8.0.16; antes se aceptaban y se ignoraban).

Convenciones: PK = clave primaria, FK = clave foránea, UQ = única, CK = restricción CHECK, NN = NOT NULL, `—` = sin valor por defecto.

## maquina
Líneas de envasado de vinilos y témperas.
| Columna | Tipo | Nulo | Defecto | Restricciones | Descripción |
|---|---|---|---|---|---|
| id_maquina | SMALLINT AUTO_INCREMENT | NN | auto | PK | Identificador |
| nombre | VARCHAR(20) | NN | — | UQ | Vinilos_1 a Vinilos_4 |
| factor_produccion | DECIMAL(4,2) | NN | 1.00 | CK > 0 | Factor de corrección de la eficiencia (hoja *Tiempos*) |

## referencia
Productos que se envasan.
| Columna | Tipo | Nulo | Defecto | Restricciones | Descripción |
|---|---|---|---|---|---|
| id_referencia | INT AUTO_INCREMENT | NN | auto | PK | Identificador |
| nombre | VARCHAR(60) | NN | — | UQ | Nombre comercial (p. ej. "Parchesitos 22cc (6 col)") |
| unidades_por_display | SMALLINT | NULL | — | CK > 0 | Unidades en cada display |
| displays_por_paca | SMALLINT | NULL | — | CK > 0 | Displays que forman una paca |

## maquina_referencia
Qué referencias puede producir cada máquina (N:M).
| Columna | Tipo | Nulo | Defecto | Restricciones | Descripción |
|---|---|---|---|---|---|
| id_maquina | SMALLINT | NN | — | PK, FK → maquina (CASCADE / CASCADE) | Máquina |
| id_referencia | INT | NN | — | PK, FK → referencia (CASCADE / CASCADE) | Referencia |
| unidades_por_minuto | DECIMAL(6,2) | NULL | — | CK > 0 | Velocidad nominal de esa referencia en esa máquina |

## turno
| Columna | Tipo | Nulo | Defecto | Restricciones | Descripción |
|---|---|---|---|---|---|
| id_turno | SMALLINT AUTO_INCREMENT | NN | auto | PK | Identificador |
| nombre | VARCHAR(30) | NN | — | UQ | Nombre tal como se escribe en el formato (p. ej. "6am-4:30pm") |
| hora_inicio | TIME | NN | — | — | Inicio del turno |
| hora_fin | TIME | NN | — | — | Fin del turno |

## persona
Operarias y personal de mantenimiento (datos personales; ver sección de privacidad).
| Columna | Tipo | Nulo | Defecto | Restricciones | Descripción |
|---|---|---|---|---|---|
| id_persona | INT AUTO_INCREMENT | NN | auto | PK | Identificador |
| codigo | VARCHAR(10) | NN | — | UQ | Seudónimo (OP-001, MT-001) para reportes |
| nombre | VARCHAR(80) | NN | — | — | Nombre (dato personal) |
| rol | VARCHAR(13) | NN | — | CK IN ('OPERARIA','MANTENIMIENTO') | Función; define el "área involucrada" |
| activo | BOOLEAN (TINYINT(1)) | NN | TRUE | — | FALSE si ya no trabaja; se conserva el historial |

## codigo_paro
Catálogo de causas de paro.
| Columna | Tipo | Nulo | Defecto | Restricciones | Descripción |
|---|---|---|---|---|---|
| id_codigo_paro | SMALLINT | NN | — | PK, CK entre 1 y 18 | Número del código (1 a 18) |
| descripcion | VARCHAR(100) | NN | — | UQ | Descripción (p. ej. "Ajuste operativo") |

## subcodigo_paro
Detalle de los códigos 1, 3 y 5.
| Columna | Tipo | Nulo | Defecto | Restricciones | Descripción |
|---|---|---|---|---|---|
| id_subcodigo | INT AUTO_INCREMENT | NN | auto | PK | Identificador |
| id_codigo_paro | SMALLINT | NN | — | FK → codigo_paro (RESTRICT / CASCADE); UQ(id_codigo_paro, id_subcodigo) | Código al que pertenece |
| codigo | VARCHAR(10) | NN | — | UQ | Número (p. ej. 5.2, 1.2.A) |
| descripcion | VARCHAR(100) | NN | — | — | Nombre del subcódigo |
| id_subcodigo_padre | INT | NULL | — | FK → subcodigo_paro (SET NULL / CASCADE) | Subcódigo superior (1.2 es padre de 1.2.A) |

## registro_produccion
Producción de una operaria en una máquina, turno y referencia, en una fecha.
| Columna | Tipo | Nulo | Defecto | Restricciones | Descripción |
|---|---|---|---|---|---|
| id_registro | BIGINT AUTO_INCREMENT | NN | auto | PK | Identificador |
| fecha | DATE | NN | — | UQ compuesta (ver abajo) | Fecha del turno |
| id_maquina | SMALLINT | NN | — | FK → maquina (RESTRICT / CASCADE) | Máquina |
| id_turno | SMALLINT | NN | — | FK → turno (RESTRICT / CASCADE) | Turno |
| id_referencia | INT | NN | — | FK compuesta (id_maquina, id_referencia) → maquina_referencia (RESTRICT / CASCADE) | Referencia producida; debe ser válida para la máquina |
| id_operaria | INT | NN | — | FK → persona (RESTRICT / CASCADE) | Operaria que diligenció el formato (`OP-000` "Sin especificar" antes de oct-2023) |
| secuencia | SMALLINT | NN | 1 | UQ compuesta (ver abajo) | N.º de registro idéntico el mismo día; el Excel antiguo no distingue turno ni operaria |
| pacas_producidas | INT | NN | — | CK ≥ 0 | Producción real |
| horas_trabajadas | DECIMAL(4,2) | NN | — | CK > 0 y ≤ 24 | Horas efectivas (admite 10.5) |
| meta_por_hora | INT | NN | — | CK > 0 | Meta de pacas por hora (valor histórico) |
| observacion | TEXT | NULL | — | — | Comentarios del formato |
| creado_en | TIMESTAMP | NN | CURRENT_TIMESTAMP | — | Auditoría de la carga |

Restricción única: `(fecha, id_maquina, id_turno, id_referencia, id_operaria, secuencia)`: evita registros duplicados.

## paro
Cada paro de un registro, con su causa y duración.
| Columna | Tipo | Nulo | Defecto | Restricciones | Descripción |
|---|---|---|---|---|---|
| id_paro | BIGINT AUTO_INCREMENT | NN | auto | PK | Identificador |
| id_registro | BIGINT | NN | — | FK → registro_produccion (CASCADE / CASCADE) | Registro al que pertenece; si se borra, se borran sus paros |
| id_codigo_paro | SMALLINT | NN | — | FK → codigo_paro (RESTRICT / CASCADE) | Causa del paro |
| id_subcodigo | INT | NULL | — | FK compuesta (id_codigo_paro, id_subcodigo) → subcodigo_paro (RESTRICT / CASCADE) | Detalle opcional; debe pertenecer al código |
| minutos | INT | NN | — | CK > 0 | Duración (la unidad original del formato) |
| id_persona | INT | NULL | — | FK → persona (SET NULL / CASCADE) | Personal involucrado |
| observacion | TEXT | NULL | — | — | Comentario del paro |

Índice único funcional `ux_paro_registro_codigo (id_registro, id_codigo_paro, (COALESCE(id_subcodigo,0)))`: no se repite el mismo código/subcódigo en un registro. Se usa `COALESCE` porque en MySQL un `UNIQUE` admite varios `NULL`.

## Políticas de integridad referencial (resumen)
- **RESTRICT** en los catálogos (máquina, turno, persona, código): no se puede borrar algo que ya tiene producción o paros asociados.
- **CASCADE** en `paro → registro_produccion` y en `maquina_referencia`: los detalles no tienen sentido sin su padre.
- **SET NULL** en datos opcionales (`id_persona`, `id_subcodigo_padre`): se conserva el paro aunque se retire la referencia.
- **ON UPDATE CASCADE** en todas, por si se corrige una clave.

## Índices
| Índice | Consulta que lo justifica |
|---|---|
| ix_registro_fecha | Q1, Q2: filtros por rango de fechas |
| ix_registro_maquina_fecha | Q1: productividad por máquina y mes |
| ix_registro_turno | Q4: comparación entre turnos |
| ix_paro_codigo | Q2, Q6: participación por código |
| ix_paro_subcodigo | Q3: detalle por subcódigo |
