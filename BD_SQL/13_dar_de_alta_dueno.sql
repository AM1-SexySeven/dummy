-- =============================================================
-- ConectaCruz · Script 13: dar de alta al dueño del negocio
--
-- El botón «Cambiar foto» solo lo ve una cuenta con rol de dueño.
-- La aplicación lee ese rol de la tabla `perfiles`, y una cuenta
-- creada desde el panel de Supabase no siempre tiene su fila ahí.
--
-- Este script la crea si falta y le pone el rol, en una sola
-- operación. Cambiar el correo por el de la cuenta que corresponda.
--
-- Ejecutar en Supabase → SQL Editor.
-- =============================================================

insert into public.perfiles (id, nombre, rol)
select u.id,
       coalesce(u.raw_user_meta_data->>'nombre', split_part(u.email, '@', 1)),
       'dueno'
  from auth.users u
 where u.email = 'prueba.qr@example.com'
on conflict (id) do update set rol = 'dueno';


-- Comprobar: la cuenta tiene que figurar con rol `dueno`.

select u.email,
       coalesce(p.rol, '(sin perfil)') as rol
  from auth.users u
  left join public.perfiles p on p.id = u.id
 order by u.email;
