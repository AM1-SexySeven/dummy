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
