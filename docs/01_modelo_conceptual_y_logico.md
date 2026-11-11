# Modelo conceptual y lógico — Registro de paros de producción

## 1. Entidades, atributos y reglas de negocio (extraídas del Excel y del P-MTO-22)

| Entidad | Atributos principales | Regla de negocio |
|---|---|---|
| MÁQUINA | nombre (Vinilos_1 a Vinilos_4), factor de producción | Hay 4 líneas de envasado. El factor (1,10 / 1,16 / 1 / 1) corrige la eficiencia. |
| REFERENCIA | nombre, unidades por display, displays por paca | Cada máquina solo produce un subconjunto de referencias (hoja *Tiempos*). |
| TURNO | nombre, hora inicio, hora fin | Turnos vistos: 6am-2pm, 2pm-10pm y 6am-4:30pm. |
| PERSONA | código, nombre, rol (operaria / mantenimiento) | Una operaria diligencia el formato; mantenimiento puede intervenir en un paro. |
| CÓDIGO DE PARO | número (1 a 18), descripción | Catálogo cerrado de causas de paro. |
| SUBCÓDIGO DE PARO | código (p. ej. 5.2), descripción, subcódigo padre | Solo existen para los códigos 1, 3 y 5. Pueden ser jerárquicos (1.2 → 1.2.A). |
| REGISTRO DE PRODUCCIÓN | fecha, pacas producidas, horas trabajadas, meta por hora | Una operaria, en una máquina, turno y referencia, en una fecha. |
| PARO | minutos, observación | Un registro puede tener 0 o más paros; cada paro tiene un código y, a veces, subcódigo y personal involucrado. |

Reglas adicionales:
- Productividad = pacas ÷ (meta por hora × horas trabajadas) × factor de la máquina.
- Un subcódigo solo es válido para su código.
- Un mismo código/subcódigo no se repite dentro de un registro.

## 2. Modelo conceptual (MER, notación pata de gallo)

**Cardinalidades y participación**

| Relación | Cardinalidad | Participación |
|---|---|---|
| MÁQUINA – REGISTRO | 1 : N | Registro **total** (siempre tiene máquina); máquina **parcial** |
| TURNO – REGISTRO | 1 : N | Registro total; turno parcial |
| REFERENCIA – REGISTRO | 1 : N | Registro total; referencia parcial |
| PERSONA (operaria) – REGISTRO | 1 : N | Registro total; persona parcial |
| MÁQUINA – REFERENCIA | N : M ("puede producir") | Ambas parciales |
| REGISTRO – PARO | 1 : N | Paro **total**; registro **parcial** (puede no tener paros) |
| CÓDIGO – PARO | 1 : N | Paro total; código parcial |
| CÓDIGO – SUBCÓDIGO | 1 : N | Subcódigo total |
| SUBCÓDIGO – PARO | 1 : N | Paro **parcial** (subcódigo opcional) |
| SUBCÓDIGO – SUBCÓDIGO | 1 : N (recursiva, "es hijo de") | Ambas parciales |
| PERSONA – PARO | 1 : N ("interviene en") | Paro parcial (personal involucrado opcional) |

```mermaid
erDiagram
  MAQUINA        ||--o{ REGISTRO_PRODUCCION : "se registra en"
  TURNO          ||--o{ REGISTRO_PRODUCCION : "ocurre en"
  REFERENCIA     ||--o{ REGISTRO_PRODUCCION : "se produce en"
  PERSONA        ||--o{ REGISTRO_PRODUCCION : "diligencia (operaria)"
  MAQUINA        }o--o{ REFERENCIA          : "puede producir"
  REGISTRO_PRODUCCION ||--o{ PARO           : "tiene"
  CODIGO_PARO    ||--o{ PARO                : "clasifica"
  CODIGO_PARO    ||--o{ SUBCODIGO_PARO     : "se detalla en"
  SUBCODIGO_PARO |o--o{ PARO               : "precisa"
  SUBCODIGO_PARO |o--o{ SUBCODIGO_PARO     : "es hijo de"
  PERSONA        |o--o{ PARO               : "interviene en"
```

## 3. Modelo relacional (lógico)

```mermaid
erDiagram
  maquina { smallint id_maquina PK
            varchar nombre UK
            decimal factor_produccion }
  referencia { int id_referencia PK
               varchar nombre UK
               smallint unidades_por_display
               smallint displays_por_paca }
  maquina_referencia { smallint id_maquina PK,FK
                       int id_referencia PK,FK
                       decimal unidades_por_minuto }
  turno { smallint id_turno PK
          varchar nombre UK
          time hora_inicio
          time hora_fin }
  persona { int id_persona PK
            varchar codigo UK
            varchar nombre
            varchar rol
            boolean activo }
  codigo_paro { smallint id_codigo_paro PK
                varchar descripcion UK }
  subcodigo_paro { int id_subcodigo PK
                   smallint id_codigo_paro FK
                   varchar codigo UK
                   varchar descripcion
                   int id_subcodigo_padre FK }
  registro_produccion { bigint id_registro PK
                        date fecha
                        smallint id_maquina FK
                        smallint id_turno FK
                        int id_referencia FK
                        int id_operaria FK
                        smallint secuencia
                        int pacas_producidas
                        decimal horas_trabajadas
                        int meta_por_hora
                        text observacion
                        timestamp creado_en }
  paro { bigint id_paro PK
         bigint id_registro FK
         smallint id_codigo_paro FK
         int id_subcodigo FK
         int minutos
         int id_persona FK
         text observacion }
  maquina ||--o{ maquina_referencia : ""
  referencia ||--o{ maquina_referencia : ""
  maquina_referencia ||--o{ registro_produccion : "id_maquina,id_referencia"
  turno ||--o{ registro_produccion : ""
  persona ||--o{ registro_produccion : "id_operaria"
  registro_produccion ||--o{ paro : ""
  codigo_paro ||--o{ paro : ""
  codigo_paro ||--o{ subcodigo_paro : ""
  subcodigo_paro |o--o{ paro : "id_codigo_paro,id_subcodigo"
  subcodigo_paro |o--o{ subcodigo_paro : "padre"
  persona |o--o{ paro : ""
```

Derivación MER → relacional:
- Las relaciones 1:N pasan a clave foránea en el lado N.
- La relación N:M MÁQUINA–REFERENCIA se convierte en la tabla `maquina_referencia`.
- La relación recursiva de SUBCÓDIGO pasa a la columna `id_subcodigo_padre`.
- La especialización de PERSONA (operaria / mantenimiento) se resuelve con la columna `rol`.

> Puede reproducir el diagrama físico desde DBeaver: clic derecho sobre el esquema → *View Diagram*.
