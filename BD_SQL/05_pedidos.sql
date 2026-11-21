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

comment on table public.pedidos is 'Pedidos enviados desde la app ConectaCruz (Churrasquería El Fogón)';

alter table public.pedidos enable row level security;

-- El cliente crea su propio pedido…
create policy "Cliente crea su pedido"
  on public.pedidos for insert
  with check (auth.uid() = user_id);

-- …y cualquier usuario con sesión puede listarlos (panel del negocio).
create policy "Usuarios autenticados leen pedidos"
  on public.pedidos for select
  using (auth.role() = 'authenticated');

-- El negocio cambia el estado del pedido.
create policy "Usuarios autenticados actualizan pedidos"
  on public.pedidos for update
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');
