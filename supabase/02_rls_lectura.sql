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
create policy "perfiles: leer" on public.perfiles
  for select to authenticated using (true);

-- productos (el menú): cualquiera puede LEERLO, incluso sin sesión
create policy "productos: leer publico" on public.productos
  for select using (true);

-- consultas: solo el dueño lee las suyas
create policy "consultas: leer las propias" on public.consultas
  for select to authenticated using (auth.uid() = user_id);

-- reservas: solo el dueño lee las suyas
create policy "reservas: leer las propias" on public.reservas
  for select to authenticated using (auth.uid() = user_id);
