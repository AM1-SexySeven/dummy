# Scripts SQL — ConectaCruz (Churrasquería El Fogón)

Ejecutar en **Supabase → SQL Editor** en este orden:

| # | Archivo | Qué hace |
|---|---------|----------|
| 01 | `01_tablas.sql` | Crea las tablas `perfiles`, `productos`, `consultas` y `reservas` |
| 02 | `02_rls_lectura.sql` | Activa RLS en las 4 tablas y la lectura pública solo para el menú |
| 02b | `02b_datos_semilla.sql` | Inserta los 4 platos de la churrasquería |
| 03 | `03_escritura_publica.sql` | Políticas de inserción (clientes logueados crean sus consultas/reservas) |

> **Seguridad:** nunca uses la clave `service_role`. La clave pública
> (`anon`/`publishable`) va en la app y es segura por diseño.
> El modelo completo también está documentado en `docs/supabase_schema.sql`.
