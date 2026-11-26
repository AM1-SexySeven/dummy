-- =============================================================
-- ConectaCruz · Script 12: quitar platos duplicados
--
-- El script 10 volvía a insertar los cuatro platos «por si alguno se
-- había borrado antes», con `on conflict do nothing`. Esa cláusula
-- solo evita el duplicado cuando existe una restricción de unicidad,
-- y la tabla `productos` no la tenía sobre el nombre: el resultado
-- fue una segunda copia de cada plato que ya estaba.
--
-- Este script borra las copias sobrantes y agrega la restricción que
-- faltaba, para que el problema no se pueda repetir.
--
-- Ejecutar en Supabase → SQL Editor.
-- =============================================================


-- 1. Ver el daño
--    select nombre, count(*) from public.productos
--     group by nombre having count(*) > 1;


-- 2. Dejar una sola fila por nombre: la más antigua, que es la que
--    puede tener una foto ya subida.

delete from public.productos p
 where exists (
   select 1 from public.productos q
    where q.nombre = p.nombre
      and (q.created_at, q.id) < (p.created_at, p.id)
 );


-- 3. Que no vuelva a pasar.
--    Con esta restricción, `on conflict do nothing` sí funciona.

create unique index if not exists productos_nombre_unico
  on public.productos (nombre);


-- 4. Comprobar: tienen que quedar cuatro platos, uno de cada uno.
--    select nombre, precio from public.productos order by precio desc;
