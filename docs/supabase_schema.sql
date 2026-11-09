-- =====================================================================
--  ConectaCruz · Base de datos en Supabase
--  Pega TODO este script en:  SQL Editor  →  New query  →  Run
--  (Dashboard de tu proyecto → menú izquierdo → SQL Editor)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1) TABLA: perfiles  (datos del usuario, ligada a auth.users)
-- ---------------------------------------------------------------------
create table if not exists public.perfiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  nombre      text not null default '',
  telefono    text,
  rol         text not null default 'cliente',   -- 'cliente' | 'dueno'
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 2) TABLA: productos  (platos y servicios de la churrasquería)
-- ---------------------------------------------------------------------
create table if not exists public.productos (
  id           uuid primary key default gen_random_uuid(),
  negocio      text not null default 'Churrasquería El Fogón',
  nombre       text not null,
  descripcion  text,
  precio       numeric(10,2) not null check (precio >= 0),
  created_at   timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 3) TABLA: consultas  (botón «Consultar»)
-- ---------------------------------------------------------------------
create table if not exists public.consultas (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  nombre      text not null default '',
  mensaje     text not null,
  estado      text not null default 'pendiente', -- pendiente | respondida
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 4) TABLA: reservas  (botón «Reservar»)
-- ---------------------------------------------------------------------
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

-- =====================================================================
--  SEGURIDAD POR FILA (RLS) — igual que la app del ingeniero
--  Sin esto Supabase NO deja leer ni escribir nada.
-- =====================================================================
alter table public.perfiles enable row level security;
alter table public.productos enable row level security;
alter table public.consultas enable row level security;
alter table public.reservas  enable row level security;

-- perfiles: cada quien ve/edita el suyo; cualquiera logueado puede leer
create policy "perfiles: leer" on public.perfiles
  for select to authenticated using (true);
create policy "perfiles: crear el propio" on public.perfiles
  for insert to authenticated with check (auth.uid() = id);
create policy "perfiles: actualizar el propio" on public.perfiles
  for update to authenticated using (auth.uid() = id);

-- productos: cualquiera puede VER el menú; solo logueados pueden AÑADIR
create policy "productos: leer publico" on public.productos
  for select using (true);
create policy "productos: insertar autenticado" on public.productos
  for insert to authenticated with check (true);

-- consultas: solo el dueño de la consulta la ve/crea
create policy "consultas: leer las propias" on public.consultas
  for select to authenticated using (auth.uid() = user_id);
create policy "consultas: crear la propia" on public.consultas
  for insert to authenticated with check (auth.uid() = user_id);

-- reservas: solo el dueño de la reserva la ve/crea
create policy "reservas: leer las propias" on public.reservas
  for select to authenticated using (auth.uid() = user_id);
create policy "reservas: crear la propia" on public.reservas
  for insert to authenticated with check (auth.uid() = user_id);

-- =====================================================================
--  DATOS INICIALES: menú de la Churrasquería El Fogón
-- =====================================================================
insert into public.productos (nombre, descripcion, precio) values
  ('Parrillada para dos', 'Carne, chorizo, yuca y ensalada', 120.00),
  ('Majadito batido',     'Arroz con charque, huevo y plátano', 35.00),
  ('Pique macho',         'Carne, papas fritas, huevo y llajua', 55.00),
  ('Sonso asado',         'Plátano con queso, mantequilla y dulce de leche', 20.00)
on conflict do nothing;

-- =====================================================================
--  VERIFICACIÓN: debería devolver 4 filas
-- =====================================================================
select nombre, precio from public.productos order by precio desc;
