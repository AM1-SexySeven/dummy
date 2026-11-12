# Actividad 02 — Reparto de trabajo por integrantes

**Grupo:** Luis Gerardo Portillo Gonzales · Marco Antonio Kiataque Uchima · Anderson Carvajal Romero
**Proyecto:** ConectaCruz — "Churrasquería El Fogón" (Aplicaciones Móviles I, SIS-0180, UPDS Santa Cruz)
**Repositorio:** https://github.com/AM1-SexySeven/dummy.git
**Fecha límite Actividad 02:** sábado 14/11/2026 07:01

---

## 1. Lo que la app ya tiene hecho (antes de este reparto)

### Arquitectura y pantallas
- **Flutter** con plataformas **Android e iOS** (`--platforms android,ios`).
- Nombre de launcher: **"El Fogón"** (Android `AndroidManifest.xml` + iOS `Info.plist`), con ícono de la parrilla sobre fondo crema.
- Splash de **Android 12+ sin ícono** (destello blanco → directo a la bienvenida).
- Flujo completo: **Bienvenida → Registro/Login → Catálogo (Negocio) → Consulta / Reserva / Añadir plato**.

### Conexión con Supabase (base de datos en línea)
- Proyecto en **Supabase** (organización MarcoKiataque-org, región São Paulo). URL y clave pública van por `--dart-define`.
- Tablas: `perfiles`, `productos`, `consultas`, `reservas` con **RLS** activado:
  - El menú (`productos`) se **lee** sin sesión (público).
  - `consultas`/`reservas` solo las **ve su dueño** (`auth.uid() = user_id`).
  - Nadie puede modificar/borrar registros ajenos.
- Scripts listos para recrear la base desde cero en `supabase/` (`01_tablas`, `02_rls_lectura`, `02b_datos_semilla`, `03_escritura_publica`) + README con el orden de ejecución.

### Qué se hizo en el commit de Marco (Paso 1)
> **Commit de Marco Antonio Kiataque Uchima** — `feat(actividad02): catalogo con datos reales, offline, detalle de plato y dart-define`

| # | Mejora | Archivo | Qué hace |
|---|--------|---------|----------|
| 1 | **Catálogo con `FutureBuilder`** | `lib/main.dart` | El `Future` se crea **una sola vez** en `initState` (no en `build`): no se repite la consulta a la BD en cada redibujado. |
| 2 | **4 estados en pantalla** | `lib/main.dart` | `cargando` (spinner) · `con datos` (lista) · `error` (ícono nube + mensaje + botón **Reintentar**) · `vacío` ("Aún no hay platos en el menú"). |
| 3 | **Modo offline con caché** | `lib/services/supabase_service.dart` | Al cargar el menú bien, guarda los platos en `SharedPreferences`. Si la BD no responde, los muestra igual con el aviso **"Sin conexión — mostrando los últimos platos guardados"**. Si es la primera vez sin red → pantalla de error + Reintentar. **Supera el nivel máximo de la rúbrica (4 pts) en "documenta el comportamiento sin conexión".** |
| 4 | **Pantalla de detalle del plato** | `lib/pages/producto_detalle_page.dart` | Al tocar un plato del catálogo se abre su detalle (nombre, descripción, precio, botones). Desde ahí puede ir a **Consultar** o **Reservar**. Navegación catálogo → detalle (Criterio 3). |
| 5 | **Reservas con fecha/hora validadas** | `lib/pages/reserva_page.dart` | Rechaza **fecha u hora que ya pasaron** (`ReservaPage.fechaHoraValida`, pública y testeable) y bloquea el botón de envío mientras se envía. |
| 6 | **Credenciales por `--dart-define`** | `lib/config.dart` | `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY` se pueden sobreescribir al compilar (`--dart-define=SUPABASE_URL=...`). Los valores actuales son el respaldo para que la app funcione tal cual. |
| 7 | **Permiso INTERNET en Android** | `android/app/src/main/AndroidManifest.xml` | Exigido por el taller (slide 18) para conectarse a Supabase. |
| 8 | **SQL adaptado al esquema propio** | `supabase/01..03*.sql` + `README.md` | Scripts para crear tablas, RLS, datos semilla (4 platos) y políticas de escritura, distintos a los del taller. |
| 9 | **Tests** | `test/widget_test.dart` | **18/18 tests pasan** (`flutter test`), `flutter analyze` limpio, APK debug compilado. |

**En resumen, tu commit cubre:** Criterio 1 (conexión + RLS + `--dart-define`), Criterio 2 (validación fecha/hora + botón bloqueado) y Criterio 3 (FutureBuilder con 4 estados, Future único, navegación catálogo→detalle, comportamiento offline documentado/implementado).

---

## 2. Lo que le toca a Luis — Paso 2 (catálogo / experiencia de usuario)

> **3 commits, uno por mejora.** Antes de cada uno: `Git → Pull` (o `git pull --rebase`). Agrega **solo** tu archivo.

### Luis 1 — Botón "Actualizar" en el catálogo
- **Archivo:** `lib/main.dart`
- **Qué hacer:** en la cabecera de `NegocioPage` (arriba del `FutureBuilder`), agrega un `IconButton` con `Icons.refresh_rounded`. En su `onPressed` llama a `_reintentar()`. Mientras el `Future` está en `waiting`, muestra un `CircularProgressIndicator` pequeño en lugar del ícono (opcional: solo recarga sin bloquear).
- **Resultado:** el usuario puede refrescar el menú sin salir de la pantalla.
- **Guarda y prueba:** `flutter run` → entrar a "Ver negocio" → botón actualiza la lista.
- **Mensaje de commit:** `feat(catalogo): boton actualizar recarga el menu`

### Luis 2 — Búsqueda de platos por nombre
- **Archivo:** `lib/main.dart`
- **Qué hacer:** en `_NegocioPageState` agrega `final _buscar = TextEditingController();` y un `String _filtro = '';`. Pon un `TextField` (ícono `Icons.search`, hint "Buscar plato...") **antes** del `FutureBuilder`. En `onChanged` haz `setState(() => _filtro = valor.trim().toLowerCase())`. En el estado "con datos", filtra: `catalogo.productos.where((p) => p.nombre.toLowerCase().contains(_filtro))`. Si con el filtro no queda nada, muestra "Ningún plato coincide con tu búsqueda". No olvides `_buscar.dispose()` en el `dispose()` (agrégalo si no existe).
- **Resultado:** el menú se filtra en vivo mientras el usuario escribe.
- **Mensaje de commit:** `feat(catalogo): busqueda de platos por nombre`

### Luis 3 — Tarjetas con estilo según precio
- **Archivo:** `lib/main.dart` (widget `_ProductoTile`)
- **Qué hacer:** dale color al precio según rango: **hasta Bs 50** → verde (`Colors.green.shade700`), **Bs 51–100** → naranja, **más de Bs 100** → rojo (`Colors.red.shade700`). Además, cambia el ícono principal por `Icons.local_fire_department_rounded` (fogón) y agrégale un `CircleAvatar` con fondo crema (`Color(0xFFF9F2E0)`).
- **Resultado:** menú más legible y vivo para la churrasquería.
- **Mensaje de commit:** `feat(catalogo): estilos de tarjeta segun precio`

---

## 3. Lo que le toca a Anderson — Paso 3 (conexión / datos / docs)

> **3 commits, uno por mejora.** Antes de cada uno: `Git → Pull` (o `git pull --rebase`). Agrega **solo** tus archivos.

### Anderson 1 — Mostrar "Última actualización" del menú
- **Archivos:** `lib/services/supabase_service.dart` y `lib/main.dart`
- **Qué hacer:**
  1. En `_guardarCache`, guarda además la fecha: `prefs.setString('cache_productos_fecha', DateTime.now().toIso8601String());`
  2. En `CatalogoResult` agrega `final DateTime? actualizado;` (constructor + campo) y pásala al devolver resultados (del servidor o del caché, según corresponda).
  3. En `_NegocioPageState`/`main.dart`, bajo el `FutureBuilder` y encima de la lista, muestra un `Text` pequeño gris: `'Actualizado: ${hora}'` con `actualizado.hour}:$minute` (o "sin dato" si es null).
- **Resultado:** el usuario sabe cuán fresco es el menú — detalle que valora la rúbrica de "consultas reales".
- **Mensaje de commit:** `feat(catalogo): muestra ultima actualizacion del menu`

### Anderson 2 — Script SQL `supabase/04_seguridad_extra.sql`
- **Archivo (nuevo):** `supabase/04_seguridad_extra.sql`
- **Qué hacer:** agrega una política de **borrado prohibido para clientes** y una vista de solo lectura. Ejemplo:
  ```sql
  -- 04 · Seguridad adicional (ejecutar después de 03)
  -- Vista de solo lectura del menú para reportes
  create or replace view public.menu_del_dia as
  select nombre, descripcion, precio from public.productos;

  -- Nadie (ni logueado) puede borrar platos desde la app
  create policy "productos: sin borrado" on public.productos
    for delete using (false);
  ```
  Actualiza también `supabase/README.md` añadiendo la fila del archivo 04 en la tabla. **Sin contraseñas ni claves `service_role`** (nunca van al repo).
- **Resultado:** base de datos más robusta para la demo del RLS (evidencia de rúbrica, Criterio 1).
- **Mensaje de commit:** `feat(supabase): script 04 politica de borrado y vista menu_del_dia`

### Anderson 3 — Sección "Comportamiento sin conexión" en el README
- **Archivo:** `README.md` (raíz del repo)
- **Qué hacer:** agrega al final una sección **"Comportamiento sin conexión (offline)"** explicando en 3 viñetas:
  1. Con internet, la app lee el menú desde Supabase y guarda una copia en el teléfono (`SharedPreferences`).
  2. Sin internet, muestra la última copia con el aviso **"Sin conexión — mostrando los últimos platos guardados"**.
  3. Si nunca se cargó con internet, muestra pantalla de error con botón **Reintentar**.
  Y menciona cómo probarlo: activar **modo avión** → abrir "Ver negocio" → verificar el aviso.
- **Resultado:** documenta exactamente lo que la rúbrica del taller pide como nivel máximo (**4 pts**, Criterio 3).
- **Mensaje de commit:** `docs: comportamiento sin conexion`

---

## 4. Reglas para los 3 (importante para no pisarse)

1. **Orden de trabajo:** Marco (Paso 1, ya hecho y subido) → Luis (Paso 2) → Anderson (Paso 3). Siempre tomar `git pull` **antes** de empezar.
2. Cada quien agrega **solo sus archivos** (`git add lib/main.dart`, etc.), nunca `git add .` si hay cambios ajenos.
3. Después de cada cambio: `flutter analyze` (sin errores) y `flutter test` (18/18). Si algo falla, **no subir**.
4. Al terminar los 3 (Paso 4): los 3 hacen juntos el **informe PDF + presentación + video** (5–8 min, con rostros de los 3) — eso va aparte y lo coordinan después.

## 5. Cómo verificar antes de entregar
```powershell
cd conecta_cruz
flutter analyze
flutter test
flutter build apk --debug
```
Los 3 deben pasar limpio. Las capturas de pantalla de la app (bienvenida, catálogo real, detalle, modo avión, reserva) van a `docs/` y se referencian en el informe.
