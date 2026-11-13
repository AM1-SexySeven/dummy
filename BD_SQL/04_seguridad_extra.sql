-- =====================================================================
--  04 · Seguridad adicional (demo de RLS y borrado)
--  Ejecutar DESPUÉS de 03_escritura_publica.sql
--  Supabase → SQL Editor → New query → Run
-- =====================================================================

-- Vista de solo lectura del menú (útil para reportes del negocio).
-- Las vistas respetan RLS y solo exponen columnas públicas.
create or replace view public.menu_del_dia as
select nombre, descripcion, precio
from public.productos;

-- Nadie (ni logueado) puede borrar platos desde la app.
-- Sin esta política, RLS ya niega por omisión el borrado;
-- la dejamos explícita para la demo de seguridad.
create policy "productos: sin borrado" on public.productos
  for delete using (false);
