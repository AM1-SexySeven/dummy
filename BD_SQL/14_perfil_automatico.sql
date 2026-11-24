-- =====================================================================
-- 14_perfil_automatico.sql
-- ConectaCruz - Churrasqueria El Fogon
--
-- Problema que resuelve:
--   Al registrarse un usuario nuevo se creaba la cuenta en auth.users
--   pero NO su fila en public.perfiles. La app lo trataba como cliente
--   por defecto, pero el usuario no existia en la tabla de roles.
--
-- Este script hace dos cosas:
--   1) Crea el perfil (rol 'cliente') de todas las cuentas que ya existen
--      y no lo tienen.
--   2) Deja un disparador para que cada cuenta nueva nazca como cliente.
--
-- El rol 'dueno' solo se otorga a mano con el script 13.
-- Ejecutar una sola vez en el SQL Editor de Supabase.
-- =====================================================================

-- 1. Perfiles faltantes de las cuentas ya creadas ---------------------
insert into public.perfiles (id, nombre, rol)
select u.id,
       coalesce(nullif(u.raw_user_meta_data ->> 'nombre', ''),
                split_part(u.email, '@', 1)),
       'cliente'
  from auth.users u
  left join public.perfiles p on p.id = u.id
 where p.id is null;

-- 2. Disparador para las cuentas nuevas -------------------------------
create or replace function public.crear_perfil_nuevo()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.perfiles (id, nombre, rol)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'nombre', ''),
             split_part(new.email, '@', 1)),
    'cliente'            -- toda cuenta nueva nace como cliente
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists al_crear_usuario on auth.users;

create trigger al_crear_usuario
  after insert on auth.users
  for each row
  execute function public.crear_perfil_nuevo();

-- 3. Comprobacion ------------------------------------------------------
-- select u.email, coalesce(p.rol, '(sin perfil)') as rol
--   from auth.users u
--   left join public.perfiles p on p.id = u.id
--  order by u.email;
