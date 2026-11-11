-- 05_restricciones.sql  |  MySQL 8.0  |  Demostración de INSERT / UPDATE / DELETE y de las restricciones.
-- Los casos marcados "DEBE FALLAR" son rechazados por la base de datos. En DBeaver, al ejecutar el script (Alt + X)
-- elija "Ignorar todo" (Skip All) en el diálogo de error, o ejecute cada sentencia sola con Ctrl + Enter.
-- El código de error aparece en el mensaje (p. ej. 3819 = CHECK, 1452 = FK, 1062 = UNIQUE, 1451 = ON DELETE RESTRICT).

-- 1) INSERT válido
INSERT INTO registro_produccion (fecha, id_maquina, id_turno, id_referencia, id_operaria, pacas_producidas, horas_trabajadas, meta_por_hora)
SELECT DATE '2025-03-31', m.id_maquina, t.id_turno, r.id_referencia, p.id_persona, 120, 10.5, 52
FROM maquina m, turno t, referencia r, persona p
WHERE m.nombre='Vinilos_2' AND t.nombre='6am-4:30pm' AND r.nombre='Parchesitos 125 cc' AND p.nombre='Operaria OP-022';

-- 2) UPDATE válido
UPDATE registro_produccion SET pacas_producidas = 125
WHERE fecha = DATE '2025-03-31';

-- 3) Casos que la base de datos debe RECHAZAR

-- DEBE FALLAR (CHECK minutos > 0)
INSERT INTO paro (id_registro, id_codigo_paro, minutos)
SELECT id_registro, 6, -5 FROM registro_produccion WHERE fecha = DATE '2025-03-31';

-- DEBE FALLAR (FK compuesta): el subcódigo 1.2 NO pertenece al código 5
INSERT INTO paro (id_registro, id_codigo_paro, id_subcodigo, minutos)
SELECT r.id_registro, 5, s.id_subcodigo, 10 FROM registro_produccion r, subcodigo_paro s
WHERE r.fecha = DATE '2025-03-31' AND s.codigo = '1.2';

-- DEBE FALLAR (FK compuesta): Vinilos_2 no produce 'Kids 22cc (6 col)'
INSERT INTO registro_produccion (fecha, id_maquina, id_turno, id_referencia, id_operaria, pacas_producidas, horas_trabajadas, meta_por_hora)
SELECT DATE '2025-04-01', m.id_maquina, t.id_turno, r.id_referencia, p.id_persona, 50, 8, 52
FROM maquina m, turno t, referencia r, persona p
WHERE m.nombre='Vinilos_2' AND t.nombre='6am-4:30pm' AND r.nombre='Kids 22cc (6 col)' AND p.nombre='Operaria OP-022';

-- DEBE FALLAR (UNIQUE): registro duplicado
INSERT INTO registro_produccion (fecha, id_maquina, id_turno, id_referencia, id_operaria, pacas_producidas, horas_trabajadas, meta_por_hora)
SELECT DATE '2025-03-31', m.id_maquina, t.id_turno, r.id_referencia, p.id_persona, 10, 8, 52
FROM maquina m, turno t, referencia r, persona p
WHERE m.nombre='Vinilos_2' AND t.nombre='6am-4:30pm' AND r.nombre='Parchesitos 125 cc' AND p.nombre='Operaria OP-022';

-- DEBE FALLAR (CHECK horas_trabajadas <= 24)
UPDATE registro_produccion SET horas_trabajadas = 30 WHERE fecha = DATE '2025-03-31';

-- DEBE FALLAR (ON DELETE RESTRICT): no se puede borrar una máquina con registros
DELETE FROM maquina WHERE nombre = 'Vinilos_2';

-- 4) ON DELETE CASCADE: al borrar un registro se borran sus paros
INSERT INTO paro (id_registro, id_codigo_paro, minutos)
SELECT id_registro, 6, 15 FROM registro_produccion WHERE fecha = DATE '2025-03-31';
SELECT COUNT(*) AS paros_antes FROM paro p JOIN registro_produccion r USING (id_registro) WHERE r.fecha = DATE '2025-03-31';
DELETE FROM registro_produccion WHERE fecha = DATE '2025-03-31';
SELECT COUNT(*) AS paros_despues_del_cascade FROM paro WHERE id_registro NOT IN (SELECT id_registro FROM registro_produccion);  -- 0
