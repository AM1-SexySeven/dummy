-- =============================================================
-- ConectaCruz · Script 10: limpieza de datos de otra práctica
--
-- El proyecto de Supabase ya se había usado para un ejercicio
-- anterior, con una cafetería, una ferretería y una tienda de
-- tecnología. Al cargar los scripts de ConectaCruz esos registros
-- quedaron mezclados: la aplicación abría en «Cafetería El Cambita»
-- y el catálogo de la churrasquería mostraba martillos y café.
--
-- Este script deja solo los datos de ConectaCruz. No toca pedidos,
-- cobros, consultas ni reservas.
--
-- El orden importa: primero los productos y después los negocios,
-- porque el esquema anterior dejó una clave foránea de productos
-- hacia negocios y la base no deja borrar un negocio que todavía
-- tenga productos colgando.
--
-- Ejecutar en Supabase → SQL Editor, después de TODO_EN_UNO.sql.
-- =============================================================


-- -------------------------------------------------------------
-- 1. Antes: ver qué hay
-- -------------------------------------------------------------
-- select id, nombre, rubro from public.negocios order by id;
-- select nombre, precio from public.productos order by nombre;


-- -------------------------------------------------------------
-- 2. Productos que no son de la churrasquería  (va PRIMERO)
-- -------------------------------------------------------------
-- La carta de El Fogón son cuatro platos. Todo lo demás venía del
-- ejercicio anterior: café, pan, salteñas, herramientas y
-- accesorios de computadora.

delete from public.productos
 where nombre not in (
   'Parrillada para dos',
   'Majadito batido',
   'Pique macho',
   'Sonso asado'
 );


-- -------------------------------------------------------------
-- 3. Negocios que no son de ConectaCruz
-- -------------------------------------------------------------
-- Los de ConectaCruz tienen rubro cargado (Gastronomía, Artesanía,
-- Turismo). Los de la práctica anterior lo tienen vacío.

delete from public.negocios
 where coalesce(trim(rubro), '') = '';


-- -------------------------------------------------------------
-- 4. Que la carta quede completa
-- -------------------------------------------------------------
-- Por si alguno de los cuatro se había borrado antes.

insert into public.productos (nombre, descripcion, precio, negocio) values
  ('Parrillada para dos', 'Carne, chorizo, yuca y ensalada',                120.00, 'Churrasquería El Fogón'),
  ('Majadito batido',     'Arroz con charque, huevo y plátano',              35.00, 'Churrasquería El Fogón'),
  ('Pique macho',         'Carne, papas fritas, huevo y llajua',             55.00, 'Churrasquería El Fogón'),
  ('Sonso asado',         'Plátano con queso, mantequilla y dulce de leche', 20.00, 'Churrasquería El Fogón')
on conflict do nothing;


-- -------------------------------------------------------------
-- 5. Después: comprobar
-- -------------------------------------------------------------
-- Tienen que quedar siete negocios, el primero la churrasquería,
-- y cuatro platos.
--
--   select id, nombre, rubro from public.negocios order by id;
--   select nombre, precio from public.productos order by precio desc;
--
-- Los siete negocios son los que necesita la búsqueda por voz de la
-- Actividad 4: hay Gastronomía, Artesanía y Turismo, así que decir
-- «artesanía» tiene contra qué filtrar.
