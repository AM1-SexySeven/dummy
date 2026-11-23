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
