# BD_SQL — Scripts de la base de datos (Supabase)

Proyecto Supabase del grupo: **ConectaCruz — Churrasquería El Fogón**
(organización MarcoKiataque-org · región São Paulo).

## ¿Qué hace cada archivo y en qué orden se ejecuta?

Ejecutar en **Supabase → SQL Editor** en este orden:

| # | Archivo | Qué hace |
|---|---------|----------|
| 00 | `00_esquema_inicial.sql` | Esquema original completo (perfiles, productos, consultas, reservas + RLS + datos). Fue la primera versión cargada a la base. |
| 01 | `01_tablas.sql` | Crea las tablas `perfiles`, `productos`, `consultas` y `reservas` |
| 02 | `02_rls_lectura.sql` | Activa RLS en las 4 tablas. Lectura pública solo del menú; el usuario solo ve sus consultas/reservas |
| 02b | `02b_datos_semilla.sql` | Inserta los 4 platos de la churrasquería |
| 03 | `03_escritura_publica.sql` | Políticas de inserción (clientes logueados crean sus consultas/reservas; el dueño añade platos) |
| 04 | `04_seguridad_extra.sql` | Vista `menu_del_dia` (solo lectura) y política explícita de **sin borrado** de platos |

> `00` es el esquema original de referencia; `01……04` son los scripts
> desglosados y comentados. Basta con ejecutar **01 → 02 → 02b → 03 → 04**
> para reconstruir la base desde cero.

## Cambios futuros (`actualizar_N.sql`)

Cada vez que haya que modificar la base de datos (nueva tabla, nuevo
producto, nueva política), se crea un archivo numerado nuevo — **sin editar
los anteriores** — para tener historial que mostrar:

```sql
-- actualizar_1.sql
-- Fecha: xx/11/2026 · Autor: Marco / Luis / Anderson
-- Qué hace: agrega la columna 'categoria' a la tabla productos
alter table public.productos add column categoria text default 'plato';
```

**Ejemplo incluido:** `actualizar_1.sql` (plantilla comentada).

> **Seguridad:** nunca uses la clave `service_role` ni subas contraseñas de la
> base de datos al repositorio. La clave pública (`anon`/`publishable`) de
> `lib/config.dart` es segura por diseño.
