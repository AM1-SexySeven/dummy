-- =============================================================
-- ConectaCruz · El Fogón · Script 09b: ajustes del banco simulado
--
-- Dos correcciones sobre 09_cobros_qr.sql:
--
--  1. La espera del pago automático sube de 20 a 90 segundos, para
--     que el código QR quede en pantalla el tiempo suficiente como
--     para mirarlo y sacarle captura.
--
--  2. La respuesta de un pago duplicado ahora incluye el monto. Sin
--     él, la aplicación no podía leer la respuesta y mostraba un
--     mensaje confuso en lugar de «Este pedido ya estaba pagado».
--
-- Ejecutar en Supabase → SQL Editor, después de 09_cobros_qr.sql.
-- =============================================================


-- 1. Consulta del estado del cobro ------------------------------

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


-- 2. Pago inmediato, para la demostración -----------------------

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

  -- Pago duplicado: no se cobra dos veces. Se devuelve el cobro tal
  -- como está, con todos sus campos, para que la aplicación pueda
  -- leerlo y avisar que ya estaba pagado.
  if v_cobro.estado = 'pagado' then
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
