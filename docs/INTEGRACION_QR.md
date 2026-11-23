# Integración de cobros por QR

ConectaCruz · Churrasquería El Fogón · Aplicaciones Móviles I (SIS-0180)

---

## 1. Qué resuelve

Hasta ahora el cliente armaba su pedido y el negocio lo cobraba aparte, por
fuera de la aplicación. Esta integración cierra el ciclo: el pedido se
registra, la aplicación le pide un código QR al banco, el cliente lo escanea
con su banca móvil y el pedido queda pagado sin que nadie anote nada a mano.

El dinero cae en la cuenta **1151-026105** de la Churrasquería El Fogón.

## 2. Estado actual

| Pieza | Estado |
|---|---|
| Contrato de la pasarela | Hecho |
| Banco simulado | Hecho y funcionando |
| Banco Fortaleza | Escrito, sin probar — falta la documentación del banco |
| Pantalla de pago | Hecha, con sus cinco estados |
| Tabla de cobros y seguridad | Hecha |
| Aviso del pago en vivo | Hecho |
| Pruebas automáticas | Hechas |

El banco nos entregó número de cuenta, usuario y contraseña, pero todavía no
la documentación técnica de su API. Por eso la integración está construida
contra un banco simulado que cumple exactamente el mismo contrato. Conectar
el banco real no requiere rehacer nada: se explica en la sección 8.

## 3. El flujo completo

```
   Cliente                 ConectaCruz              Banco            Base de datos
      │                         │                     │                    │
      │  «Pagar con QR»         │                     │                    │
      ├────────────────────────►│                     │                    │
      │                         │  crear_pedido       │                    │
      │                         ├─────────────────────┼───────────────────►│
      │                         │◄────── N.º de pedido ───────────────────┤
      │                         │                     │                    │
      │                         │  generarQr(N.º, monto)                   │
      │                         ├────────────────────►│                    │
      │                         │                     ├── crea el cobro ──►│
      │                         │◄─── QR + vencimiento ┤                    │
      │                         │                     │                    │
      │◄── QR en pantalla ──────┤                     │                    │
      │                         │                     │                    │
      │  escanea y paga         │                     │                    │
      ├─────────────────────────┼────────────────────►│                    │
      │                         │                     ├── estado=pagado ──►│
      │                         │◄═══ aviso en vivo ══╪════════════════════┤
      │                         │                     │                    │
      │◄── «¡Pago recibido!» ───┤                     │                    │
      │                         │  vacía el carrito   │                    │
```

Lo importante del dibujo: **el carrito se vacía al final, no al principio**.
Si el cliente cierra la aplicación sin pagar, su pedido queda guardado y
puede pagarlo después.

## 4. El contrato

Toda la aplicación habla con una sola interfaz, `PasarelaQr`, que tiene dos
operaciones. Son las mismas que expone cualquier pasarela de QR.

### `generarQr(pedidoId, monto)`

Le pide al banco un código para cobrar.

**Se le manda**

| Campo | Tipo | Qué es |
|---|---|---|
| `pedidoId` | entero | El número que devolvió `crear_pedido` |
| `monto` | decimal | Bolivianos, con dos decimales |

**Devuelve**

| Campo | Qué es |
|---|---|
| `id` | Identificador del cobro |
| `id_banco` | Identificador que asignó el banco |
| `monto` | El monto confirmado |
| `estado` | `pendiente`, `pagado`, `vencido` o `anulado` |
| `qr_payload` | El texto que se dibuja como código QR |
| `vence_en` | Hasta cuándo sirve el código |
| `reutilizado` | `true` si devolvió un cobro que ya existía |

**Es idempotente.** Llamarla dos veces con el mismo `pedidoId` devuelve el
mismo cobro, nunca crea uno nuevo. Esto es lo que impide que un cliente que
vuelve atrás y entra de nuevo termine pagando dos veces. En la base está
garantizado con un índice único sobre `pedido_id` donde el estado es
`pendiente`.

### `consultarEstado(cobroId)`

Pregunta en qué estado está el cobro. Es la consulta de respaldo: la
aplicación la usa cada cinco segundos por si el aviso en vivo no llega.
Nunca hay que depender de un solo canal para saber si cobramos.

## 5. El código QR

El código sigue el formato **EMVCo**, que es el que usa el QR interoperable
boliviano: una cadena de campos «identificador + largo + valor», cerrada con
una suma de verificación CRC-16.

```
000201 010212 2625 0014bo.gob.bcb.qr 01101151026105
52045812 5303068 5406240.00 5802BO
5925CHURRASQUERIA EL FOGON 6011SANTA CRUZ
6236 0532<identificador del cobro>
6304<CRC>
```

| Campo | Contenido |
|---|---|
| 00 | Versión del formato |
| 01 | `12` = código dinámico, para un solo pago |
| 26 | Esquema y número de cuenta del comercio |
| 52 | Rubro del comercio: 5812, restaurante |
| 53 | Moneda: 068, boliviano |
| 54 | Monto |
| 58 | País: BO |
| 59 | Nombre del comercio |
| 60 | Ciudad |
| 62 | Referencia: el identificador del cobro |
| 63 | Suma de verificación |

El CRC se calcula en dos lugares a propósito: el banco lo escribe
(`crc16_ccitt` en el script 09) y la aplicación lo comprueba antes de
dibujar el código (`EmvQr.esValido`). Si un solo carácter cambiara en el
camino, la aplicación lo detecta y no le muestra al cliente un código que
su banca móvil iba a rechazar.

## 6. La base de datos

**`BD_SQL/09_cobros_qr.sql`**, que se ejecuta después del script 07.

Tabla `cobros`: `id`, `pedido_id`, `user_id`, `monto`, `estado`,
`qr_payload`, `id_banco`, `vence_en`, `pagado_en`, `creado_en`.

Seguridad por fila, igual que en las otras seis tablas:

- Cada usuario **ve** solamente sus propios cobros.
- Nadie **escribe** directo en la tabla. Ni insertar, ni modificar, ni
  borrar. Los cobros nacen y cambian de estado únicamente a través de las
  funciones del banco.

Esa segunda regla es la que importa. Si la aplicación pudiera escribir el
estado, cualquiera con la clave pública podría marcarse un pedido como
pagado sin pagar. Al dejar esa escritura del lado del servidor, la regla no
se puede saltear desde el teléfono.

## 7. Qué pasa cuando algo falla

| Situación | Qué hace la aplicación |
|---|---|
| Sin internet | «Sin conexión a internet» con botón Reintentar |
| El banco tarda | Reintenta una vez a los 800 ms; después avisa |
| El banco responde con error | Muestra el código de error que devolvió |
| El QR venció | «El código QR venció» y ofrece generar otro. El pedido queda guardado |
| Pago duplicado | El banco devuelve el mismo cobro ya pagado; no se cobra dos veces |
| El QR llegó dañado | Se detecta por el CRC y no se muestra |
| El aviso no llega | La consulta de respaldo cada cinco segundos lo detecta igual |

Hay una decisión de fondo acá. La aplicación podría guardar el último estado
conocido y mostrarlo siempre, para que nunca se vea un error. Se eligió lo
contrario: avisar con claridad cuando no se puede confirmar el pago. Un
«pagado» mostrado sin certeza es peor que una pantalla honesta que dice que
no se pudo verificar.

## 8. Cómo se conecta el Banco Fortaleza

Esta es la parte que justifica toda la arquitectura. Cuando llegue la
documentación del banco, el cambio es este y nada más:

**Paso 1.** En `lib/services/pasarela_fortaleza.dart`, ajustar tres cosas
según el manual:

- `urlBase` — la dirección del servicio
- `_cabeceras` — cómo se autentica la petición
- `_leerRespuesta` — los nombres de los campos que devuelve el banco

**Paso 2.** Compilar con el interruptor en verdadero:

```
flutter run ^
  --dart-define=USAR_BANCO_REAL=true ^
  --dart-define=FORTALEZA_URL=https://... ^
  --dart-define=FORTALEZA_USUARIO=... ^
  --dart-define=FORTALEZA_CLAVE=...
```

**Paso 3.** En el script 09, borrar el bloque marcado
`<< simulación del pago >>` dentro de `banco_consultar_pago`, porque con el
banco real el aviso lo manda el banco.

No hay que tocar la pantalla de pago, ni el carrito, ni la tabla de cobros,
ni el manejo de errores. Esa es la ventaja de haber escrito el contrato
primero y los bancos después.

Las credenciales nunca van dentro del código ni al repositorio. Viajan por
`--dart-define`, igual que las de Supabase.

## 9. Cómo probarlo

1. Ejecutar `BD_SQL/09_cobros_qr.sql` en el editor SQL de Supabase.
2. Comprobar que el CRC funciona: `select public.crc16_ccitt('123456789');`
   tiene que devolver `29B1`. Es el caso de control del estándar.
3. `flutter test` — las pruebas de `test/emv_qr_test.dart` verifican el CRC
   y que un QR adulterado se rechace.
4. En la aplicación: iniciar sesión, agregar platos al carrito, «Pagar con
   QR». Aparece el código con su cuenta regresiva.
5. El pago se confirma solo a los veinte segundos, o al instante con el
   botón «Simular que el banco confirma el pago».
6. Comprobar en Supabase: `select * from public.cobros order by creado_en desc;`

Para ver los casos de error: apagar la red del emulador antes de pedir el
QR, o esperar diez minutos sin pagar para que el código venza.

## 10. Lo que falta

- La documentación de la API del Banco Fortaleza. Es lo único que bloquea el
  cobro real.
- Probar contra el banco con montos de uno o dos centavos.
- Confirmar si el banco avisa el pago llamando a una dirección nuestra o si
  hay que consultarlo. La aplicación ya soporta las dos formas.
