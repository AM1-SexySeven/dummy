-- =====================================================================
--  03 · Políticas de escritura (insertar solamente)
--  Las consultas y reservas las crean clientes logueados;
--  nadie puede leer las de otro (eso lo garantiza 02_rls_lectura.sql).
--  Ejecutar DESPUÉS de 02b_datos_semilla.sql
-- =====================================================================

-- perfiles: un usuario crea el suyo (la app lo hace en el registro)
create policy "perfiles: crear el propio" on public.perfiles
  for insert to authenticated with check (auth.uid() = id);
create policy "perfiles: actualizar el propio" on public.perfiles
  for update to authenticated using (auth.uid() = id);

-- productos: el dueño logueado puede añadir platos (el cliente NO)
create policy "productos: insertar autenticado" on public.productos
  for insert to authenticated with check (true);

-- consultas: un usuario logueado crea su propia consulta
create policy "consultas: crear la propia" on public.consultas
  for insert to authenticated with check (auth.uid() = user_id);

-- reservas: un usuario logueado crea su propia reserva
create policy "reservas: crear la propia" on public.reservas
  for insert to authenticated with check (auth.uid() = user_id);
