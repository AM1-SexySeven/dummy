-- #####################################################################
-- ##  00b · Reconciliación de tablas que ya existían
-- #####################################################################
--
-- Si el proyecto de Supabase ya tenía tablas de una práctica anterior,
-- `create table if not exists` las dejó como estaban y puede que les
-- falte alguna columna. Este bloque agrega solo lo que falte; no borra
-- ni pisa ningún dato existente.

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

alter table public.pedidos
  add column if not exists user_id    uuid default auth.uid(),
  add column if not exists nombre     text,
  add column if not exists telefono   text not null default '',
  add column if not exists detalle    text,
  add column if not exists total      numeric(10,2) not null default 0,
  add column if not exists estado     text not null default 'pendiente',
  add column if not exists created_at timestamptz not null default now();

alter table public.negocios
  add column if not exists nombre     text,
  add column if not exists rubro      text not null default '',
  add column if not exists direccion  text not null default '',
  add column if not exists latitud    double precision,
  add column if not exists longitud   double precision,
  add column if not exists created_at timestamptz not null default now();

-- El pedido pasa a 'pagado' cuando el banco confirma el cobro por QR,
-- así que ese estado tiene que estar permitido.
alter table public.pedidos drop constraint if exists pedidos_estado_check;
alter table public.pedidos add constraint pedidos_estado_check
  check (estado in ('pendiente','pagado','preparando','entregado','cancelado'));
