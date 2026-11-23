-- =============================================================
-- Actividad 03 (mejora) · El Fogón · Script 08: información del negocio
-- - Columnas nuevas en `negocios` (teléfono, WhatsApp, descripción,
--   horario, foto) para que el dueño edite lo que el cliente ve.
-- - Política UPDATE: solo dueños (perfiles.rol = 'dueno').
-- - Función `agregar_dueno(p_email)`: un dueño da de alta a otro.
-- Ejecutar en Supabase → SQL Editor.
-- =============================================================

alter table public.negocios
  add column if not exists telefono text not null default '',
  add column if not exists whatsapp text not null default '',
  add column if not exists descripcion text not null default '',
  add column if not exists horario text not null default '',
  add column if not exists foto_url text not null default '',
  add column if not exists actualizado_en timestamptz;

comment on table public.negocios is
  'Negocios de Santa Cruz. La información visible para clientes se puede editar desde el Panel del negocio (solo dueños).';

-- Rellenar El Fogón (id = 1) con los datos actuales de la app
update public.negocios
set telefono = '+591 6775 6448',
    whatsapp = '+591 6775 6448',
    descripcion = 'Parrillas y platos tradicionales cruceños para compartir.',
    horario = 'Mar a Dom · 18:00 – 23:30',
    actualizado_en = now()
where id = 1;

-- Solo dueños pueden actualizar la información del negocio
drop policy if exists "Solo dueños actualizan negocios" on public.negocios;
create policy "Solo dueños actualizan negocios"
  on public.negocios for update
  using (
    exists (
      select 1 from public.perfiles p
      where p.id = auth.uid() and p.rol = 'dueno'
    )
  )
  with check (
    exists (
      select 1 from public.perfiles p
      where p.id = auth.uid() and p.rol = 'dueno'
    )
  );

-- Un dueño puede dar de alta a otro dueño por su correo.
-- Necesita leer auth.users → va con security definer (la crea el owner
-- del proyecto) y solo se expone a cuentas autenticadas.
create or replace function public.agregar_dueno(p_email text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  nuevo_id uuid;
begin
  if not exists (
    select 1 from public.perfiles
    where id = auth.uid() and rol = 'dueno'
  ) then
    raise exception 'Solo un dueño puede agregar otros dueños';
  end if;

  select id into nuevo_id
  from auth.users
  where lower(email) = lower(trim(p_email));

  if nuevo_id is null then
    raise exception 'No existe una cuenta registrada con ese correo';
  end if;

  insert into public.perfiles (id, nombre, rol)
  values (nuevo_id, split_part(trim(p_email), '@', 1), 'dueno')
  on conflict (id) do update set rol = 'dueno';
end;
$$;

revoke execute on function public.agregar_dueno(text) from public, anon;
grant execute on function public.agregar_dueno(text) to authenticated;
