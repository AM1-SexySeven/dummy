-- =============================================================
-- ConectaCruz · El Fogón · Script 11: fotos en Supabase Storage
--
-- Permite que el dueño del negocio suba la foto de un plato desde la
-- galería o la cámara del teléfono, y que cualquiera pueda verla.
--
-- Qué hace
--   1. Crea el depósito («bucket») público `negocios`.
--   2. Deja subir y reemplazar archivos solo a las cuentas con rol
--      de dueño; leer puede cualquiera.
--   3. Deja que el dueño escriba la columna `imagen_url` del plato.
--
-- Ejecutar en Supabase → SQL Editor, después de TODO_EN_UNO.sql.
-- =============================================================


-- -------------------------------------------------------------
-- 1. El depósito de archivos
-- -------------------------------------------------------------
-- `public = true` significa que cualquiera que conozca la dirección
-- puede ver la foto. Es lo que corresponde para fotos de promoción:
-- no son datos privados, son el escaparate del negocio.

insert into storage.buckets (id, name, public)
values ('negocios', 'negocios', true)
on conflict (id) do nothing;


-- -------------------------------------------------------------
-- 2. Quién es dueño
-- -------------------------------------------------------------
-- Una función corta para no repetir la consulta en cada política.

create or replace function public.es_dueno()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.perfiles
     where id = auth.uid() and rol = 'dueno'
  );
$$;

comment on function public.es_dueno() is
  'true si la sesión actual pertenece a una cuenta con rol de dueño.';

grant execute on function public.es_dueno() to authenticated;


-- -------------------------------------------------------------
-- 3. Políticas del depósito
-- -------------------------------------------------------------
-- Leer: cualquiera, incluso sin sesión. Las fotos del menú tienen que
-- verse antes de iniciar sesión, igual que el catálogo.

drop policy if exists "fotos: lectura publica" on storage.objects;
create policy "fotos: lectura publica"
  on storage.objects for select
  using (bucket_id = 'negocios');

-- Subir: solo el dueño, y solo dentro de la carpeta `platos/`.
-- Dejar la carpeta fija evita que alguien use el depósito del negocio
-- para guardar cualquier otra cosa.

drop policy if exists "fotos: sube el dueno" on storage.objects;
create policy "fotos: sube el dueno"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'negocios'
    and (storage.foldername(name))[1] = 'platos'
    and public.es_dueno()
  );

-- Reemplazar: también solo el dueño. Cada subida usa un nombre nuevo,
-- así que esta política casi no se usa, pero sin ella un reintento
-- sobre el mismo nombre fallaría con un error confuso.

drop policy if exists "fotos: reemplaza el dueno" on storage.objects;
create policy "fotos: reemplaza el dueno"
  on storage.objects for update to authenticated
  using (bucket_id = 'negocios' and public.es_dueno())
  with check (bucket_id = 'negocios' and public.es_dueno());

-- Borrar: nadie. Si una foto deja de usarse, queda huérfana en el
-- depósito, que es preferible a que un error borre la foto de un plato
-- que sí está publicado.


-- -------------------------------------------------------------
-- 4. Guardar la dirección de la foto en el plato
-- -------------------------------------------------------------

alter table public.productos
  add column if not exists imagen_url text not null default '';

drop policy if exists "productos: el dueno actualiza" on public.productos;
create policy "productos: el dueno actualiza"
  on public.productos for update to authenticated
  using (public.es_dueno())
  with check (public.es_dueno());


-- -------------------------------------------------------------
-- 5. Dar de alta al dueño
-- -------------------------------------------------------------
-- Sin una cuenta con rol de dueño el botón de cambiar foto no aparece.
-- Reemplazar el correo por el de la cuenta que va a administrar.
--
--   update public.perfiles set rol = 'dueno'
--    where id = (select id from auth.users where email = 'tucorreo@ejemplo.com');


-- -------------------------------------------------------------
-- 6. Comprobar
-- -------------------------------------------------------------
--   select id, public from storage.buckets where id = 'negocios';
--   select policyname from pg_policies
--    where schemaname = 'storage' and tablename = 'objects';
--   select nombre, imagen_url from public.productos order by nombre;
