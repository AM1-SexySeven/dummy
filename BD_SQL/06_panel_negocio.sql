-- =============================================================
-- Actividad 02 · El Fogón · Script 06: panel del negocio
-- Lectura para el negocio (usuario autenticado) de todas las
-- reservas y consultas — igual que el panel del dueño en la app
-- ConectaCruz de referencia.
-- Ejecutar en Supabase → SQL Editor.
-- =============================================================

create policy "Negocio ve todas las reservas" on public.reservas
  for select to authenticated using (true);

create policy "Negocio ve todas las consultas" on public.consultas
  for select to authenticated using (true);
