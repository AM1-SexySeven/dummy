-- =============================================================
-- ConectaCruz · El Fogón · Script 09: cobros por QR
--
-- Qué hace este script
--   1. Crea la tabla `cobros`, que guarda un cobro por pedido.
--   2. Activa seguridad por fila: cada quien ve solo sus cobros.
--   3. Crea un "banco simulado" con tres funciones, que responden
--      igual que respondería la API del banco real.
--   4. Habilita Realtime para que la app se entere del pago sola.
--
-- Por qué un banco simulado
--   El banco real todavía no nos entregó la documentación de su API.
--   Estas funciones cumplen el mismo contrato, así que toda la
--   integración queda escrita y probada. Cuando lleguen las
--   credenciales reales, solo se cambia la clase PasarelaSimulada
--   por PasarelaFortaleza en la aplicación: nada más se toca.
--
-- Ejecutar en Supabase → SQL Editor, DESPUÉS de 07_crear_pedido.sql
-- =============================================================


-- -------------------------------------------------------------
-- 1. Utilidades para armar el código QR
-- -------------------------------------------------------------

-- El QR interoperable boliviano sigue el formato EMVCo: una cadena de
-- campos "identificador + largo + valor", cerrada con una suma de
-- verificación CRC-16. Si un solo carácter cambia, el CRC no coincide
-- y la aplicación del banco rechaza el código.

create or replace function public.emv_campo(p_id text, p_valor text)
returns text
language sql
immutable
as $$
  select p_id || lpad(length(p_valor)::text, 2, '0') || p_valor;
$$;

comment on function public.emv_campo(text, text) is
  'Arma un campo EMVCo: identificador + largo en dos dígitos + valor.';


create or replace function public.crc16_ccitt(p_texto text)
returns text
language plpgsql
immutable
as $$
declare
  crc int := 65535;   -- valor inicial 0xFFFF
  byte int;
  i int;
  j int;
begin
  for i in 1 .. length(p_texto) loop
    byte := ascii(substr(p_texto, i, 1));
    crc := (crc # (byte << 8)) & 65535;
    for j in 1 .. 8 loop
      if (crc & 32768) <> 0 then
        crc := ((crc << 1) # 4129) & 65535;   -- polinomio 0x1021
      else
        crc := (crc << 1) & 65535;
      end if;
    end loop;
  end loop;
  return upper(lpad(to_hex(crc), 4, '0'));
end;
$$;

comment on function public.crc16_ccitt(text) is
  'Suma de verificación CRC-16/CCITT-FALSE, la que exige el estándar EMVCo.';


-- -------------------------------------------------------------
-- 2. La tabla de cobros
-- -------------------------------------------------------------

create table if not exists public.cobros (
  id            uuid primary key default gen_random_uuid(),
  pedido_id     bigint not null references public.pedidos(id) on delete cascade,
  user_id       uuid   not null default auth.uid(),
  monto         numeric(10,2) not null check (monto > 0),
  estado        text   not null default 'pendiente'
                 check (estado in ('pendiente','pagado','vencido','anulado')),
  qr_payload    text,
  id_banco      text,
  vence_en      timestamptz not null default now() + interval '10 minutes',
  pagado_en     timestamptz,
  creado_en     timestamptz not null default now()
);

comment on table public.cobros is
  'Un cobro por QR por cada pedido. El estado lo mueve el banco, nunca la app.';

-- Un solo cobro pendiente por pedido: si se reintenta, se reusa el mismo.
create unique index if not exists cobros_pedido_pendiente_idx
  on public.cobros (pedido_id)
  where estado = 'pendiente';

create index if not exists cobros_user_idx on public.cobros (user_id);


-- -------------------------------------------------------------
-- 3. Seguridad por fila
-- -------------------------------------------------------------

alter table public.cobros enable row level security;

drop policy if exists "cobros: ver los propios" on public.cobros;
create policy "cobros: ver los propios"
  on public.cobros for select
  to authenticated
  using (auth.uid() = user_id);

-- Nadie escribe directo en la tabla: ni crear, ni modificar, ni borrar.
-- Los cobros solo nacen y cambian de estado a través de las funciones
-- de abajo, que son las que representan al banco.
drop policy if exists "cobros: nadie inserta a mano" on public.cobros;
drop policy if exists "cobros: nadie modifica a mano" on public.cobros;
drop policy if exists "cobros: nadie borra a mano" on public.cobros;

revoke insert, update, delete on public.cobros from authenticated, anon;


-- -------------------------------------------------------------
-- 4. El banco simulado
-- -------------------------------------------------------------

-- 4.1 Generar el QR de un pedido.
--
-- Es idempotente: si el pedido ya tiene un cobro pendiente sin vencer,
-- devuelve ese mismo en lugar de crear otro. Así, si el usuario vuelve
-- atrás y entra de nuevo, no se generan dos cobros por la misma compra.

create or replace function public.banco_generar_qr(
  p_pedido_id bigint,
  p_monto numeric
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cobro   public.cobros;
  v_sin_crc text;
  v_payload text;
  v_dueno   uuid;
begin
  if p_monto is null or p_monto <= 0 then
    raise exception 'El monto del cobro debe ser mayor a cero';
  end if;

  -- El pedido tiene que existir y ser de quien pide el QR.
  select user_id into v_dueno from public.pedidos where id = p_pedido_id;
  if v_dueno is null then
    raise exception 'El pedido % no existe', p_pedido_id;
  end if;
  if v_dueno <> auth.uid() then
    raise exception 'El pedido % no es de este usuario', p_pedido_id;
  end if;

  -- Marcar como vencidos los cobros a los que se les pasó la hora.
  update public.cobros
     set estado = 'vencido'
   where pedido_id = p_pedido_id
     and estado = 'pendiente'
     and vence_en < now();

  -- ¿Ya hay uno pendiente? Se devuelve el mismo.
  select * into v_cobro
    from public.cobros
   where pedido_id = p_pedido_id and estado = 'pendiente'
   limit 1;

  if found then
    return json_build_object(
      'id',          v_cobro.id,
      'id_banco',    v_cobro.id_banco,
      'estado',      v_cobro.estado,
      'monto',       v_cobro.monto,
      'qr_payload',  v_cobro.qr_payload,
      'vence_en',    v_cobro.vence_en,
      'reutilizado', true
    );
  end if;

  insert into public.cobros (pedido_id, user_id, monto)
  values (p_pedido_id, auth.uid(), round(p_monto, 2))
  returning * into v_cobro;

  -- Armado del QR según EMVCo, igual que lo haría el banco.
  v_sin_crc :=
      public.emv_campo('00', '01')                               -- versión del formato
   || public.emv_campo('01', '12')                               -- QR dinámico (un solo pago)
   || public.emv_campo('26',
        public.emv_campo('00', 'bo.gob.bcb.qr')                  -- identificador del esquema
     || public.emv_campo('01', '1151026105'))                    -- cuenta del comercio
   || public.emv_campo('52', '5812')                             -- rubro: restaurante
   || public.emv_campo('53', '068')                              -- moneda: boliviano
   || public.emv_campo('54', to_char(v_cobro.monto, 'FM999999990.00'))
   || public.emv_campo('58', 'BO')
   || public.emv_campo('59', 'CHURRASQUERIA EL FOGON')
   || public.emv_campo('60', 'SANTA CRUZ')
   || public.emv_campo('62', public.emv_campo('05', replace(v_cobro.id::text, '-', '')))
   || '6304';                                                    -- encabezado del CRC

  v_payload := v_sin_crc || public.crc16_ccitt(v_sin_crc);

  update public.cobros
     set qr_payload = v_payload,
         id_banco   = 'SIM-' || to_char(now(), 'YYYYMMDD') || '-'
                      || lpad((random() * 999999)::int::text, 6, '0')
   where id = v_cobro.id
   returning * into v_cobro;

  return json_build_object(
    'id',          v_cobro.id,
    'id_banco',    v_cobro.id_banco,
    'estado',      v_cobro.estado,
    'monto',       v_cobro.monto,
    'qr_payload',  v_cobro.qr_payload,
    'vence_en',    v_cobro.vence_en,
    'reutilizado', false
  );
end;
$$;

revoke execute on function public.banco_generar_qr(bigint, numeric) from anon;
grant  execute on function public.banco_generar_qr(bigint, numeric) to authenticated;


-- 4.2 Consultar el estado de un cobro.
--
-- Esta es la consulta de respaldo: la app la usa si el aviso en vivo
-- no llega. Además hace de reloj: vence los cobros pasados de hora y,
-- para que la demostración se pueda grabar sin pagar de verdad,
-- da por pagado el cobro a los 90 segundos de creado.
--
-- Esa simulación del pago está aislada en ESTA función. Con el banco
-- real desaparece, porque el aviso lo manda el banco.

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


-- 4.3 Forzar el pago al instante.
--
-- Solo para grabar la demostración sin esperar los 20 segundos.
-- Equivale al momento en que el banco avisa que recibió el pago.

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
  if v_cobro.estado = 'pagado' then
    -- Pago duplicado: no se cobra dos veces, se devuelve el mismo resultado.
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


-- -------------------------------------------------------------
-- 5. Aviso en vivo
-- -------------------------------------------------------------
-- Con esto la app recibe el cambio de estado apenas ocurre, en lugar
-- de preguntar cada dos segundos.

alter table public.cobros replica identity full;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime' and tablename = 'cobros'
  ) then
    alter publication supabase_realtime add table public.cobros;
  end if;
end;
$$;


-- -------------------------------------------------------------
-- 6. Verificación
-- -------------------------------------------------------------
-- Pegar estas consultas en el editor SQL para comprobar que quedó bien.
--
--   select tablename, rowsecurity from pg_tables
--    where schemaname = 'public' order by tablename;
--
--   select public.crc16_ccitt('123456789');   -- debe devolver 29B1
--
--   select id, pedido_id, monto, estado, vence_en
--     from public.cobros order by creado_en desc limit 10;
