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
