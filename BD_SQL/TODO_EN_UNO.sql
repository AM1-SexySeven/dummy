-- =====================================================================
--  ConectaCruz · Churrasquería El Fogón
--  BASE DE DATOS COMPLETA — un solo archivo, todo en orden
--
--  Este archivo deja la base lista para correr la aplicación tal como
--  está hoy, incluido el cobro por QR. Reemplaza a ejecutar los once
--  scripts numerados uno por uno.
--
--  Cómo usarlo
--    1. Supabase → tu proyecto → SQL Editor → New query
--    2. Pegar TODO este archivo
--    3. Run
--    4. Comprobar:  select public.crc16_ccitt('123456789');  → 29B1
--
--  Se puede volver a ejecutar sin romper nada: las tablas se crean solo
--  si faltan, a las que ya existían se les agregan las columnas que les
--  falten, las políticas y funciones se reemplazan, y los datos de
--  ejemplo no se duplican.
--
--  Contenido, en orden
--    01   tablas base: perfiles, productos, consultas, reservas
--    00b  columnas que falten en esas cuatro
--    02   seguridad por fila y lectura pública del menú
--    02b  los platos de la carta
--    03   políticas de escritura
--    04   vista menu_del_dia y prohibición de borrado
--    05   tabla pedidos (+ sus columnas y el estado 'pagado')
--    06   negocios con coordenadas (+ sus columnas)
--    06b  panel del negocio
--    07   función crear_pedido
--    08   información del negocio y dueños
--    09   cobros por QR: tabla, seguridad, banco simulado y aviso en vivo
--
--  Lo del QR en detalle está explicado en docs/INTEGRACION_QR.md
-- =====================================================================


-- #####################################################################
-- ##  01_tablas.sql
-- #####################################################################

-- =====================================================================
--  01 · Tablas de ConectaCruz (Churrasquería El Fogón)
--  Ejecutar en: Supabase → SQL Editor → New query → Run
-- =====================================================================

create table if not exists public.perfiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  nombre      text not null default '',
  telefono    text,
  rol         text not null default 'cliente',   -- 'cliente' | 'dueno'
  created_at  timestamptz not null default now()
);

create table if not exists public.productos (
  id           uuid primary key default gen_random_uuid(),
  negocio      text not null default 'Churrasquería El Fogón',
  nombre       text not null,
  descripcion  text,
  precio       numeric(10,2) not null check (precio >= 0),
  created_at   timestamptz not null default now()
);

create table if not exists public.consultas (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  nombre      text not null default '',
  mensaje     text not null,
  estado      text not null default 'pendiente', -- pendiente | respondida
  created_at  timestamptz not null default now()
);

create table if not exists public.reservas (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  nombre      text not null default '',
  fecha       date not null,
  personas    int not null default 1 check (personas > 0),
  detalle     text,
  estado      text not null default 'pendiente', -- pendiente | confirmada
  created_at  timestamptz not null default now()
);


-- #####################################################################
-- ##  00b · Columnas que falten en las tablas base
-- #####################################################################

-- Si el proyecto ya tenía tablas de una práctica anterior, puede que
-- les falte alguna columna. Esto agrega solo lo que falte; no borra ni
-- pisa ningún dato existente.

alter table public.perfiles
  add column if not exists nombre     text not null default '',
  add column if not exists telefono   text,
  add column if not exists rol        text not null default 'cliente',
  add column if not exists created_at timestamptz not null default now();

alter table public.productos
  add column if not exists negocio     text not null default 'Churrasquería El Fogón',
  add column if not exists nombre      text,
  add column if not exists descripcion text,
  add column if not exists precio      numeric(10,2),
  add column if not exists created_at  timestamptz not null default now();

alter table public.consultas
  add column if not exists user_id    uuid,
  add column if not exists nombre     text not null default '',
  add column if not exists mensaje    text,
  add column if not exists estado     text not null default 'pendiente',
  add column if not exists created_at timestamptz not null default now();

alter table public.reservas
  add column if not exists user_id    uuid,
  add column if not exists nombre     text not null default '',
  add column if not exists fecha      date,
  add column if not exists personas   int not null default 1,
  add column if not exists detalle    text,
  add column if not exists estado     text not null default 'pendiente',
  add column if not exists created_at timestamptz not null default now();


-- #####################################################################
-- ##  02_rls_lectura.sql
-- #####################################################################

-- =====================================================================
--  02 · Seguridad por fila (RLS) — lectura pública del menú
--  «Negar por omisión»: sin política = NADIE puede leer la tabla.
--  Ejecutar DESPUÉS de 01_tablas.sql
-- =====================================================================

alter table public.perfiles enable row level security;
alter table public.productos enable row level security;
alter table public.consultas enable row level security;
alter table public.reservas  enable row level security;

-- perfiles: cada quien ve el suyo; cualquiera logueado puede leer
drop policy if exists "perfiles: leer" on public.perfiles;
create policy "perfiles: leer" on public.perfiles
  for select to authenticated using (true);

-- productos (el menú): cualquiera puede LEERLO, incluso sin sesión
drop policy if exists "productos: leer publico" on public.productos;
create policy "productos: leer publico" on public.productos
  for select using (true);

-- consultas: solo el dueño lee las suyas
drop policy if exists "consultas: leer las propias" on public.consultas;
create policy "consultas: leer las propias" on public.consultas
  for select to authenticated using (auth.uid() = user_id);

-- reservas: solo el dueño lee las suyas
drop policy if exists "reservas: leer las propias" on public.reservas;
create policy "reservas: leer las propias" on public.reservas
  for select to authenticated using (auth.uid() = user_id);


-- #####################################################################
-- ##  02b_datos_semilla.sql
-- #####################################################################

-- =====================================================================
--  02b · Datos de ejemplo (menú real de la Churrasquería)
--  Ejecutar DESPUÉS de 02_rls_lectura.sql
-- =====================================================================

insert into public.productos (nombre, descripcion, precio) values
  ('Parrillada para dos', 'Carne, chorizo, yuca y ensalada', 120.00),
  ('Majadito batido',     'Arroz con charque, huevo y plátano', 35.00),
  ('Pique macho',         'Carne, papas fritas, huevo y llajua', 55.00),
  ('Sonso asado',         'Plátano con queso, mantequilla y dulce de leche', 20.00)
on conflict do nothing;


-- #####################################################################
-- ##  03_escritura_publica.sql
-- #####################################################################

-- =====================================================================
--  03 · Políticas de escritura (insertar solamente)
--  Las consultas y reservas las crean clientes logueados;
--  nadie puede leer las de otro (eso lo garantiza 02_rls_lectura.sql).
--  Ejecutar DESPUÉS de 02b_datos_semilla.sql
-- =====================================================================

-- perfiles: un usuario crea el suyo (la app lo hace en el registro)
drop policy if exists "perfiles: crear el propio" on public.perfiles;
create policy "perfiles: crear el propio" on public.perfiles
  for insert to authenticated with check (auth.uid() = id);
drop policy if exists "perfiles: actualizar el propio" on public.perfiles;
create policy "perfiles: actualizar el propio" on public.perfiles
  for update to authenticated using (auth.uid() = id);

-- productos: el dueño logueado puede añadir platos (el cliente NO)
drop policy if exists "productos: insertar autenticado" on public.productos;
create policy "productos: insertar autenticado" on public.productos
  for insert to authenticated with check (true);

-- consultas: un usuario logueado crea su propia consulta
drop policy if exists "consultas: crear la propia" on public.consultas;
create policy "consultas: crear la propia" on public.consultas
  for insert to authenticated with check (auth.uid() = user_id);

-- reservas: un usuario logueado crea su propia reserva
drop policy if exists "reservas: crear la propia" on public.reservas;
create policy "reservas: crear la propia" on public.reservas
  for insert to authenticated with check (auth.uid() = user_id);


-- #####################################################################
-- ##  04_seguridad_extra.sql
-- #####################################################################

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
drop policy if exists "productos: sin borrado" on public.productos;
create policy "productos: sin borrado" on public.productos
  for delete using (false);


-- #####################################################################
-- ##  05_pedidos.sql
-- #####################################################################

-- =============================================================
-- Actividad 02 · El Fogón · Script 05: tabla `pedidos` (Mi pedido)
-- Ejecutar en Supabase → SQL Editor ANTES de probar la app nueva.
-- =============================================================

create table if not exists public.pedidos (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) default auth.uid(),
  nombre text not null,
  telefono text not null default '',
  detalle text not null,           -- ej.: «2x Parrillada para dos, 1x Sonso»
  total numeric(10, 2) not null default 0,
  estado text not null default 'pendiente'
    check (estado in ('pendiente', 'preparando', 'entregado', 'cancelado')),
  created_at timestamptz not null default now()
);

-- Columnas que puedan faltar si la tabla ya existía de antes.
alter table public.pedidos
  add column if not exists user_id    uuid default auth.uid(),
  add column if not exists nombre     text,
  add column if not exists telefono   text not null default '',
  add column if not exists detalle    text,
  add column if not exists total      numeric(10,2) not null default 0,
  add column if not exists estado     text not null default 'pendiente',
  add column if not exists created_at timestamptz not null default now();

-- El pedido pasa a 'pagado' cuando el banco confirma el cobro por QR.
alter table public.pedidos drop constraint if exists pedidos_estado_check;
alter table public.pedidos add constraint pedidos_estado_check
  check (estado in ('pendiente','pagado','preparando','entregado','cancelado'));

comment on table public.pedidos is 'Pedidos enviados desde la app ConectaCruz (Churrasquería El Fogón)';

alter table public.pedidos enable row level security;

-- El cliente crea su propio pedido…
drop policy if exists "Cliente crea su pedido" on public.pedidos;
create policy "Cliente crea su pedido"
  on public.pedidos for insert
  with check (auth.uid() = user_id);

-- …y cualquier usuario con sesión puede listarlos (panel del negocio).
drop policy if exists "Usuarios autenticados leen pedidos" on public.pedidos;
create policy "Usuarios autenticados leen pedidos"
  on public.pedidos for select
  using (auth.role() = 'authenticated');

-- El negocio cambia el estado del pedido.
drop policy if exists "Usuarios autenticados actualizan pedidos" on public.pedidos;
create policy "Usuarios autenticados actualizan pedidos"
  on public.pedidos for update
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');


-- #####################################################################
-- ##  06_ubicacion.sql
-- #####################################################################

-- =============================================================
-- Actividad 03 · El Fogón · Script 06: ubicación de negocios
-- Columnas latitud/longitud de la tabla de negocios (06_ubicacion.sql)
-- Ejecutar en Supabase → SQL Editor ANTES de las pruebas del mapa.
-- =============================================================

create table if not exists public.negocios (
  id bigint generated always as identity primary key,
  nombre text not null,
  rubro text not null default '',
  direccion text not null default '',
  latitud double precision not null,
  longitud double precision not null,
  created_at timestamptz not null default now()
);

-- Columnas que puedan faltar si la tabla ya existía de antes.
alter table public.negocios
  add column if not exists nombre     text,
  add column if not exists rubro      text not null default '',
  add column if not exists direccion  text not null default '',
  add column if not exists latitud    double precision,
  add column if not exists longitud   double precision,
  add column if not exists created_at timestamptz not null default now();

comment on table public.negocios is
  'Negocios de Santa Cruz de la Sierra mostrados en el mapa ConectaCruz';
comment on column public.negocios.latitud is 'Latitud WGS84 (sur, negativa)';
comment on column public.negocios.longitud is 'Longitud WGS84 (oeste, negativa)';

alter table public.negocios enable row level security;

-- Cualquier visitante puede leer los puntos del mapa…
drop policy if exists "Lectura pública de negocios" on public.negocios;
create policy "Lectura pública de negocios"
  on public.negocios for select
  using (true);

-- …y solo cuentas autenticadas pueden administrarlos.
drop policy if exists "Solo autenticados escriben negocios" on public.negocios;
create policy "Solo autenticados escriben negocios"
  on public.negocios for insert
  with check (auth.role() = 'authenticated');

-- Datos de prueba (Santa Cruz de la Sierra). Coordenadas WGS84.
insert into public.negocios (nombre, rubro, direccion, latitud, longitud) values
  ('Churrasquería El Fogón', 'Gastronomía', 'Av. Busch 1234', -17.7925, -63.1780),
  ('Café Plaza 24 de Septiembre', 'Gastronomía', 'Plaza 24 de Septiembre s/n', -17.7839, -63.1822),
  ('Salteñería Doña Rosa', 'Gastronomía', 'Calle La Paz 55', -17.7755, -63.1910),
  ('Cerámica del Oriente', 'Artesanía', 'Av. Circunvalación 2100', -17.7702, -63.1720),
  ('Telares Chiquitanos', 'Artesanía', 'Mercado Artesanal, Av. Santos Dumont', -17.7990, -63.1950),
  ('Ruta Misionera', 'Turismo', 'Agencias del centro', -17.7610, -63.2050),
  ('Amboró Aventura Tours', 'Turismo', 'Av. España 1450', -17.8050, -63.1650)
on conflict do nothing;


-- #####################################################################
-- ##  06_panel_negocio.sql
-- #####################################################################

-- =============================================================
-- Actividad 02 · El Fogón · Script 06: panel del negocio
-- Lectura para el negocio (usuario autenticado) de todas las
-- reservas y consultas — igual que el panel del dueño en la app
-- ConectaCruz de referencia.
-- Ejecutar en Supabase → SQL Editor.
-- =============================================================

drop policy if exists "Negocio ve todas las reservas" on public.reservas;
create policy "Negocio ve todas las reservas" on public.reservas
  for select to authenticated using (true);

drop policy if exists "Negocio ve todas las consultas" on public.consultas;
create policy "Negocio ve todas las consultas" on public.consultas
  for select to authenticated using (true);


-- #####################################################################
-- ##  07_crear_pedido.sql
-- #####################################################################

-- =============================================================
-- Actividad 03 · El Fogón · Script 07: función `crear_pedido`
-- (Evidencia del Laboratorio 10 · pedido creado por RPC)
-- Ejecutar en Supabase → SQL Editor DESPUÉS de 05_pedidos.sql.
-- =============================================================

create or replace function public.crear_pedido(
  p_nombre text,
  p_telefono text,
  p_detalle text,
  p_total numeric
)
returns bigint
language plpgsql
security invoker
set search_path = public
as $$
declare
  nuevo_id bigint;
begin
  -- Validaciones del lado del servidor (nunca confiar solo en la app)
  if coalesce(trim(p_nombre), '') = '' then
    raise exception 'El nombre no puede estar vacío';
  end if;
  if coalesce(trim(p_detalle), '') = '' then
    raise exception 'El detalle del pedido no puede estar vacío';
  end if;

  insert into public.pedidos (user_id, nombre, telefono, detalle, total, estado)
  values (
    auth.uid(),
    trim(p_nombre),
    coalesce(p_telefono, ''),
    trim(p_detalle),
    greatest(coalesce(p_total, 0), 0),
    'pendiente'
  )
  returning id into nuevo_id;

  return nuevo_id;
end;
$$;

-- El cliente invitado (anon) no puede crear pedidos; solo usuarios con cuenta.
revoke execute on function public.crear_pedido(text, text, text, numeric) from anon;
grant execute on function public.crear_pedido(text, text, text, numeric) to authenticated;


-- #####################################################################
-- ##  08_negocio_info.sql
-- #####################################################################

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


-- #####################################################################
-- ##  09_cobros_qr.sql
-- #####################################################################

-- =============================================================
-- ConectaCruz · El Fogón · Script 09: cobros por QR
--
-- Qué hace este script
--   1. Crea la tabla `cobros`, que guarda un cobro por pedido.
--   2. Activa seguridad por fila: cada quien ve solo sus cobros.
--   3. Crea un "banco simulado" con tres funciones, que responden
--      igual que respondería la API del banco real.
--   4. Habilita Realtime para que la app se entere del pago sola.
--
-- Por qué un banco simulado
--   El banco real todavía no nos entregó la documentación de su API.
--   Estas funciones cumplen el mismo contrato, así que toda la
--   integración queda escrita y probada. Cuando lleguen las
--   credenciales reales, solo se cambia la clase PasarelaSimulada
--   por PasarelaFortaleza en la aplicación: nada más se toca.
--
-- Ejecutar en Supabase → SQL Editor, DESPUÉS de 07_crear_pedido.sql
-- =============================================================


-- -------------------------------------------------------------
-- 1. Utilidades para armar el código QR
-- -------------------------------------------------------------

-- El QR interoperable boliviano sigue el formato EMVCo: una cadena de
-- campos "identificador + largo + valor", cerrada con una suma de
-- verificación CRC-16. Si un solo carácter cambia, el CRC no coincide
-- y la aplicación del banco rechaza el código.

create or replace function public.emv_campo(p_id text, p_valor text)
returns text
language sql
immutable
as $$
  select p_id || lpad(length(p_valor)::text, 2, '0') || p_valor;
$$;

comment on function public.emv_campo(text, text) is
  'Arma un campo EMVCo: identificador + largo en dos dígitos + valor.';


create or replace function public.crc16_ccitt(p_texto text)
returns text
language plpgsql
immutable
as $$
declare
  crc int := 65535;   -- valor inicial 0xFFFF
  byte int;
  i int;
  j int;
begin
  for i in 1 .. length(p_texto) loop
    byte := ascii(substr(p_texto, i, 1));
    crc := (crc # (byte << 8)) & 65535;
    for j in 1 .. 8 loop
      if (crc & 32768) <> 0 then
        crc := ((crc << 1) # 4129) & 65535;   -- polinomio 0x1021
      else
        crc := (crc << 1) & 65535;
      end if;
    end loop;
  end loop;
  return upper(lpad(to_hex(crc), 4, '0'));
end;
$$;

comment on function public.crc16_ccitt(text) is
  'Suma de verificación CRC-16/CCITT-FALSE, la que exige el estándar EMVCo.';


-- -------------------------------------------------------------
-- 2. La tabla de cobros
-- -------------------------------------------------------------

create table if not exists public.cobros (
  id            uuid primary key default gen_random_uuid(),
  pedido_id     bigint not null references public.pedidos(id) on delete cascade,
  user_id       uuid   not null default auth.uid(),
  monto         numeric(10,2) not null check (monto > 0),
  estado        text   not null default 'pendiente'
                 check (estado in ('pendiente','pagado','vencido','anulado')),
  qr_payload    text,
  id_banco      text,
  vence_en      timestamptz not null default now() + interval '10 minutes',
  pagado_en     timestamptz,
  creado_en     timestamptz not null default now()
);

comment on table public.cobros is
  'Un cobro por QR por cada pedido. El estado lo mueve el banco, nunca la app.';

-- Un solo cobro pendiente por pedido: si se reintenta, se reusa el mismo.
create unique index if not exists cobros_pedido_pendiente_idx
  on public.cobros (pedido_id)
  where estado = 'pendiente';

create index if not exists cobros_user_idx on public.cobros (user_id);


-- -------------------------------------------------------------
-- 3. Seguridad por fila
-- -------------------------------------------------------------

alter table public.cobros enable row level security;

drop policy if exists "cobros: ver los propios" on public.cobros;
create policy "cobros: ver los propios"
  on public.cobros for select
  to authenticated
  using (auth.uid() = user_id);

-- Nadie escribe directo en la tabla: ni crear, ni modificar, ni borrar.
-- Los cobros solo nacen y cambian de estado a través de las funciones
-- de abajo, que son las que representan al banco.
drop policy if exists "cobros: nadie inserta a mano" on public.cobros;
drop policy if exists "cobros: nadie modifica a mano" on public.cobros;
drop policy if exists "cobros: nadie borra a mano" on public.cobros;

revoke insert, update, delete on public.cobros from authenticated, anon;


-- -------------------------------------------------------------
-- 4. El banco simulado
-- -------------------------------------------------------------

-- 4.1 Generar el QR de un pedido.
--
-- Es idempotente: si el pedido ya tiene un cobro pendiente sin vencer,
-- devuelve ese mismo en lugar de crear otro. Así, si el usuario vuelve
-- atrás y entra de nuevo, no se generan dos cobros por la misma compra.

create or replace function public.banco_generar_qr(
  p_pedido_id bigint,
  p_monto numeric
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cobro   public.cobros;
  v_sin_crc text;
  v_payload text;
  v_dueno   uuid;
begin
  if p_monto is null or p_monto <= 0 then
    raise exception 'El monto del cobro debe ser mayor a cero';
  end if;

  -- El pedido tiene que existir y ser de quien pide el QR.
  select user_id into v_dueno from public.pedidos where id = p_pedido_id;
  if v_dueno is null then
    raise exception 'El pedido % no existe', p_pedido_id;
  end if;
  if v_dueno <> auth.uid() then
    raise exception 'El pedido % no es de este usuario', p_pedido_id;
  end if;

  -- Marcar como vencidos los cobros a los que se les pasó la hora.
  update public.cobros
     set estado = 'vencido'
   where pedido_id = p_pedido_id
     and estado = 'pendiente'
     and vence_en < now();

  -- ¿Ya hay uno pendiente? Se devuelve el mismo.
  select * into v_cobro
    from public.cobros
   where pedido_id = p_pedido_id and estado = 'pendiente'
   limit 1;

  if found then
    return json_build_object(
      'id',          v_cobro.id,
      'id_banco',    v_cobro.id_banco,
      'estado',      v_cobro.estado,
      'monto',       v_cobro.monto,
      'qr_payload',  v_cobro.qr_payload,
      'vence_en',    v_cobro.vence_en,
      'reutilizado', true
    );
  end if;

  insert into public.cobros (pedido_id, user_id, monto)
  values (p_pedido_id, auth.uid(), round(p_monto, 2))
  returning * into v_cobro;

  -- Armado del QR según EMVCo, igual que lo haría el banco.
  v_sin_crc :=
      public.emv_campo('00', '01')                               -- versión del formato
   || public.emv_campo('01', '12')                               -- QR dinámico (un solo pago)
   || public.emv_campo('26',
        public.emv_campo('00', 'bo.gob.bcb.qr')                  -- identificador del esquema
     || public.emv_campo('01', '1151026105'))                    -- cuenta del comercio
   || public.emv_campo('52', '5812')                             -- rubro: restaurante
   || public.emv_campo('53', '068')                              -- moneda: boliviano
   || public.emv_campo('54', to_char(v_cobro.monto, 'FM999999990.00'))
   || public.emv_campo('58', 'BO')
   || public.emv_campo('59', 'CHURRASQUERIA EL FOGON')
   || public.emv_campo('60', 'SANTA CRUZ')
   || public.emv_campo('62', public.emv_campo('05', replace(v_cobro.id::text, '-', '')))
   || '6304';                                                    -- encabezado del CRC

  v_payload := v_sin_crc || public.crc16_ccitt(v_sin_crc);

  update public.cobros
     set qr_payload = v_payload,
         id_banco   = 'SIM-' || to_char(now(), 'YYYYMMDD') || '-'
                      || lpad((random() * 999999)::int::text, 6, '0')
   where id = v_cobro.id
   returning * into v_cobro;

  return json_build_object(
    'id',          v_cobro.id,
    'id_banco',    v_cobro.id_banco,
    'estado',      v_cobro.estado,
    'monto',       v_cobro.monto,
    'qr_payload',  v_cobro.qr_payload,
    'vence_en',    v_cobro.vence_en,
    'reutilizado', false
  );
end;
$$;

revoke execute on function public.banco_generar_qr(bigint, numeric) from anon;
grant  execute on function public.banco_generar_qr(bigint, numeric) to authenticated;


-- 4.2 Consultar el estado de un cobro.
--
-- Esta es la consulta de respaldo: la app la usa si el aviso en vivo
-- no llega. Además hace de reloj: vence los cobros pasados de hora y,
-- para que la demostración se pueda grabar sin pagar de verdad,
-- da por pagado el cobro a los 90 segundos de creado.
--
-- Esa simulación del pago está aislada en ESTA función. Con el banco
-- real desaparece, porque el aviso lo manda el banco.

create or replace function public.banco_consultar_pago(p_cobro_id uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cobro public.cobros;
begin
  select * into v_cobro from public.cobros where id = p_cobro_id;
  if not found then
    raise exception 'El cobro % no existe', p_cobro_id;
  end if;
  if v_cobro.user_id <> auth.uid() then
    raise exception 'El cobro % no es de este usuario', p_cobro_id;
  end if;

  if v_cobro.estado = 'pendiente' then
    if v_cobro.vence_en < now() then
      update public.cobros set estado = 'vencido'
       where id = p_cobro_id returning * into v_cobro;
    elsif v_cobro.creado_en < now() - interval '90 seconds' then
      -- << simulación del pago; se borra al conectar el banco real >>
      update public.cobros
         set estado = 'pagado', pagado_en = now()
       where id = p_cobro_id returning * into v_cobro;

      update public.pedidos set estado = 'pagado' where id = v_cobro.pedido_id;
    end if;
  end if;

  return json_build_object(
    'id',        v_cobro.id,
    'estado',    v_cobro.estado,
    'monto',     v_cobro.monto,
    'pagado_en', v_cobro.pagado_en,
    'vence_en',  v_cobro.vence_en
  );
end;
$$;

revoke execute on function public.banco_consultar_pago(uuid) from anon;
grant  execute on function public.banco_consultar_pago(uuid) to authenticated;


-- 4.3 Forzar el pago al instante.
--
-- Solo para grabar la demostración sin esperar los 20 segundos.
-- Equivale al momento en que el banco avisa que recibió el pago.

create or replace function public.banco_simular_pago(p_cobro_id uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cobro public.cobros;
begin
  select * into v_cobro from public.cobros where id = p_cobro_id;
  if not found then
    raise exception 'El cobro % no existe', p_cobro_id;
  end if;
  if v_cobro.user_id <> auth.uid() then
    raise exception 'El cobro % no es de este usuario', p_cobro_id;
  end if;
  if v_cobro.estado = 'pagado' then
    -- Pago duplicado: no se cobra dos veces, se devuelve el mismo resultado.
    return json_build_object(
      'id',        v_cobro.id,
      'estado',    'pagado',
      'monto',     v_cobro.monto,
      'pagado_en', v_cobro.pagado_en,
      'vence_en',  v_cobro.vence_en,
      'duplicado', true
    );
  end if;
  if v_cobro.estado <> 'pendiente' then
    raise exception 'El cobro está en estado %, no se puede pagar', v_cobro.estado;
  end if;

  update public.cobros
     set estado = 'pagado', pagado_en = now()
   where id = p_cobro_id returning * into v_cobro;

  update public.pedidos set estado = 'pagado' where id = v_cobro.pedido_id;

  return json_build_object(
    'id',        v_cobro.id,
    'estado',    'pagado',
    'monto',     v_cobro.monto,
    'pagado_en', v_cobro.pagado_en,
    'vence_en',  v_cobro.vence_en,
    'duplicado', false
  );
end;
$$;

revoke execute on function public.banco_simular_pago(uuid) from anon;
grant  execute on function public.banco_simular_pago(uuid) to authenticated;


-- -------------------------------------------------------------
-- 5. Aviso en vivo
-- -------------------------------------------------------------
-- Con esto la app recibe el cambio de estado apenas ocurre, en lugar
-- de preguntar cada dos segundos.

alter table public.cobros replica identity full;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime' and tablename = 'cobros'
  ) then
    alter publication supabase_realtime add table public.cobros;
  end if;
end;
$$;


-- -------------------------------------------------------------
-- 6. Verificación
-- -------------------------------------------------------------
-- Pegar estas consultas en el editor SQL para comprobar que quedó bien.
--
--   select tablename, rowsecurity from pg_tables
--    where schemaname = 'public' order by tablename;
--
--   select public.crc16_ccitt('123456789');   -- debe devolver 29B1
--
--   select id, pedido_id, monto, estado, vence_en
--     from public.cobros order by creado_en desc limit 10;
