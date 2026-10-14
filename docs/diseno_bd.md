# Diseño de base de datos (SQLite, versión 3)

Todo se construye a partir de **personas**: primero se registran los hermanos y
después se usan para formar el equipo, los equipos de catequistas, los
responsables de signos, los grupos y los carismas.

```mermaid
erDiagram
    personas ||--o| personas : "conyugeId"
    personas ||--o| equipo : "tiene cargo"
    personas ||--o{ equipo_catequistas_miembros : "integra"
    equipos_catequistas ||--o{ equipo_catequistas_miembros : "tiene"
    comunidad }o--o| equipos_catequistas : "equipo_catequista_id"
    signos ||--o{ signo_responsables : "tiene"
    personas ||--o{ signo_responsables : "es responsable"
    grupos ||--o{ grupo_miembros : "tiene"
    personas ||--o{ grupo_miembros : "pertenece"
    personas ||--o{ carismas : "tiene"

    personas {
        int id PK
        text nombres
        text apellidos
        text sexo "M | F"
        text fechaNacimiento
        text documento
        text telefono
        text direccion
        text correo
        text estadoCivil
        int conyugeId FK "personas.id, SET NULL"
        text fechaAniversario
        int numeroHijos
    }
    comunidad {
        int id PK
        text numero
        text fechaNacimiento
        text parroquia
        text tipoParroquia "Parroquia | Capilla"
        text pasoActual
        text fechaPaso
        int huboRito
        text catequista
        text catequistaComunidad
        text catequistaParroquia
        int equipo_catequista_id FK
    }
    equipo {
        int id PK
        int persona_id FK "UNIQUE"
        text cargo "Responsable | Viceresponsable | Corresponsable"
    }
    equipos_catequistas {
        int id PK
        text nombre "UNIQUE"
    }
    equipo_catequistas_miembros {
        int id PK
        int equipo_id FK
        int persona_id FK
        text rol "Responsable | Catequista"
    }
    signos {
        int id PK
        text nombre
        int cantidad
        text fechaCompra
        text fechaEntrega
        text observacion
    }
    signo_responsables {
        int id PK
        int signo_id FK
        int persona_id FK
    }
    grupos {
        int id PK
        text tipo "Palabra | Eucaristía | Artículo | Doméstica"
        text nombre
    }
    grupo_miembros {
        int id PK
        int grupo_id FK
        text tipo
        int persona_id FK
    }
    carismas {
        int id PK
        int persona_id FK
        text tipo
    }
```

## Reglas

| Tabla | Restricción | Para qué |
|---|---|---|
| `equipo` | `UNIQUE(persona_id)` | Una persona tiene un solo cargo (la app además garantiza un único Responsable). |
| `equipo_catequistas_miembros` | `UNIQUE(equipo_id, persona_id)` | Sin duplicados en un equipo; una persona puede estar en varios equipos. |
| `signo_responsables` | `UNIQUE(signo_id, persona_id)` | Varios responsables por signo. |
| `grupos` | `UNIQUE(tipo, nombre)` | Grupos numerados por tipo. |
| `grupo_miembros` | `UNIQUE(tipo, persona_id)` | Una persona está en **un** grupo de cada tipo (puede estar en uno de Palabra y otro de Eucaristía). |
| `carismas` | `UNIQUE(persona_id, tipo)` | Varios carismas por persona, sin repetir. |
| `personas.conyugeId` | se mantiene en ambos sentidos | Al casar a A con B, B apunta a A. El reparto de grupos mantiene juntos a los matrimonios. |

Todas las FK hacia `personas` usan `ON DELETE CASCADE`: al eliminar una persona
desaparece de equipos, grupos, signos y carismas.

## Migración desde v1

`DBHelper._migrarV2` conserva los datos existentes:

- `equipo`: se eliminan duplicados (queda el cargo más reciente por persona).
- `grupo_persona` (un único grupo genérico) pasa a `grupos` / `grupo_miembros` como tipo **Palabra**.
- `carismas`: se recrea con cascada y sin duplicados.
- Se añaden `personas.sexo`, `comunidad.equipo_catequista_id` y la tabla `signo_responsables`.
- v3: se añaden `comunidad.catequistaComunidad` y `comunidad.catequistaParroquia`.
