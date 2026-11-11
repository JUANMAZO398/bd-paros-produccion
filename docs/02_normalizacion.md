# Normalización: de la hoja "Base de Datos" a 3FN

## 0. Estructura original (0FN)
Una sola tabla con 58 columnas:

`Fecha, Mes, Año, Máquina, Operario, Referencia, Unidades/min, Unidad por display, Display por paca, Pacas producidas, Horas trabajadas, Turno, Horas no trabajadas, Tipo de paro, Observaciones de paro, Código de paro 1…18, Subcódigo 1/3/5, Código N en horas (×18), Área involucrada, Personal involucrado, Tiempo de Paro, Observaciones`

**Anomalías detectadas**
- *Inserción:* para registrar un subcódigo hay que tener un registro de producción completo.
- *Actualización:* si cambia la descripción de un subcódigo o el nombre de una operaria, hay que corregirlo en cada fila donde aparece. Hoy basta con una errata ("Vinilos_4" en el bloque de Vinilos_3) para dejar el catálogo inconsistente.
- *Borrado:* borrar la última fila de una máquina o de un subcódigo borra también el único lugar donde aparece.
- Muchas columnas de código quedan vacías en cada fila (en la muestra, la mayoría de las 36 columnas de códigos y horas).

**Dependencias funcionales identificadas**
- `(fecha, máquina, turno, referencia, operaria)` → pacas, horas trabajadas, meta
- `máquina` → factor de producción
- `código` → descripción del código
- `subcódigo` → descripción, código al que pertenece
- `persona` → rol (área involucrada)
- `turno` → hora de inicio y fin
- `(registro, código, subcódigo)` → minutos
- `fecha` → mes, año (derivado)
- `minutos` → horas (derivado)

## 1. Primera forma normal (1FN)
| Problema | Solución |
|---|---|
| **Grupo repetitivo:** 18 columnas "Código N" y 18 "Código N en horas". El número de código está codificado en el nombre de la columna. | Se crea la tabla `paro` (una fila por código con minutos > 0). `id_codigo_paro` pasa a ser un dato, no un nombre de columna. |
| **Valores no atómicos:** el formato mezcla número y texto ("40 mnt", "11 hrs", "25 pacas"). | Cada columna guarda solo el número, con tipo y unidad fija (`minutos INT`, `horas DECIMAL`). |
| **Subcódigo como texto compuesto** ("5.8 Banda de sujeción…"). | Se separa en `codigo` y `descripcion` dentro de `subcodigo_paro`. |
| **Datos derivados guardados:** Mes, Año, "Código N en horas", "Tiempo de Paro", "Horas no trabajadas". | Se eliminan. Mes y año salen de `fecha`; las horas, de `minutos / 60`; el total de paro, de `SUM(minutos)`. |

**Anomalía eliminada:** ya no hay un máximo de 18 paros por fila, ni columnas vacías, ni se puede sumar texto con unidades.

## 2. Segunda forma normal (2FN)
Las claves compuestas son:
- `registro`: `(fecha, máquina, turno, referencia, operaria)`
- `paro`: `(registro, código, subcódigo)`

| Dependencia parcial | Tabla nueva |
|---|---|
| `máquina → factor_produccion` (depende solo de una parte de la clave del registro) | `maquina` |
| `referencia → unidades_por_display, displays_por_paca` | `referencia` |
| `código → descripcion` (depende solo de una parte de la clave de `paro`) | `codigo_paro` |
| `subcódigo → descripcion` | `subcodigo_paro` |
| `turno → hora_inicio, hora_fin` | `turno` |
| `(máquina, referencia) → unidades_por_minuto`, y qué referencias produce cada máquina | `maquina_referencia` |

Se usan claves sustitutas (`id_…`) en las tablas de entrada de datos para que las claves foráneas sean simples.

**Anomalía eliminada:** la descripción de un código o el factor de una máquina se guardan una sola vez; ya no se repiten en cada fila ni se contradicen.

## 3. Tercera forma normal (3FN)
Se eliminan las dependencias transitivas:

| Dependencia transitiva | Solución |
|---|---|
| `subcódigo → código → descripción del código` (el código del subcódigo se repetía en la fila del paro) | `subcodigo_paro.id_codigo_paro` y una **FK compuesta** `(id_codigo_paro, id_subcodigo)` en `paro` garantiza la coherencia. |
| `personal involucrado → área involucrada` (el área es el rol de la persona) | Se elimina la columna "Área" y se usa `persona.rol`. El área se obtiene con un JOIN. |
| `operario` (texto libre) → datos de la persona | Se crea `persona` con código y nombre; el registro guarda solo `id_operaria`. |
| `tipo de paro` ("[19] No aplica") se deduce de si hay paros | Se elimina; se obtiene con `LEFT JOIN paro … IS NULL`. |
| `observaciones de paro = 'No aplica'` (valor de relleno) | Se migra como `NULL`. |

**Resultado:** 9 tablas, todas en 3FN. Cada atributo no clave depende de la clave, de toda la clave y solo de la clave.

## 4. Desnormalizaciones deliberadas
| Decisión | Justificación |
|---|---|
| `registro_produccion.meta_por_hora` se guarda en el registro y no se calcula desde `maquina` o `referencia`. | La meta puede cambiar con el tiempo y el formato físico la registra en cada hoja; guardarla conserva el valor histórico con el que se midió ese día. |
| `persona.codigo` junto a `nombre`. | No es redundancia de datos: permite anonimizar la información en las vistas. |

Todo lo demás (productividad, horas, totales, mes, año) **no se almacena**: se calcula en la vista `vw_productividad` o en las consultas.

## 5. Protección de datos personales
- Los nombres solo existen en `persona`. El resto de las tablas guarda `id_persona`.
- La vista `vw_persona_anonima` expone `codigo` y `rol`, sin nombre, para reportes e indicadores.
- En producción: el acceso a `persona.nombre` se limita por rol (`GRANT SELECT` solo a RR. HH. o mantenimiento), y las personas retiradas se marcan con `activo = FALSE` en lugar de borrarlas, para conservar el historial.
- Los indicadores de gerencia usan el código (OP-001, MT-001), no el nombre.
