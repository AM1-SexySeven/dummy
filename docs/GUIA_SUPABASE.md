# Guía: crear el proyecto de Supabase de ConectaCruz

Son **4 pasos** y tardas como **10 minutos**. Es gratis.

---

## Paso 1 — Crear la cuenta (si no tienes)

1. Entra a <https://supabase.com>
2. Haz clic en **Start your project** → **Sign up**
3. Puedes registrarte con **GitHub** (más rápido) o con correo
4. Confirma tu correo si te lo pide

## Paso 2 — Crear el proyecto

1. Haz clic en **New project**
2. Completa:
   | Campo | Valor |
   |---|---|
   | **Organization** | crea una (Botón *Create organization*, nombre cualquiera) |
   | **Name** | `conecta-cruz` |
   | **Database Password** | genera uno y **guárdalo** (no lo necesitas para la app, pero anótalo) |
   | **Region** | **South America (São Paulo)** o **East US (N. Virginia)** |
3. Espera **1–2 minutos** a que diga `All migrations complete`

## Paso 3 — Copiar las credenciales

1. Menú izquierdo → **Project Settings** (⚙) → **API**
2. Copia:
   - **Project URL** → algo como `https://abcdefgh.supabase.co`
   - **anon public** (Project API keys) → clave larga que empieza con `eyJ...`
3. **Pégalas aquí:**
   - `conecta_cruz/lib/config.dart` → en `url = '...'` y `anonKey = '...'`

> La clave `anon` **no es secreta**: está pensada para ir dentro de la app.
> Nunca pegues la clave `service_role` (esa sí es secreta).

## Paso 4 — Permitir el registro sin verificar correo (para la demo)

1. Menú izquierdo → **Authentication** → **Sign In / Providers**
2. Haz clic en **Email**
3. Apaga el interruptor **Confirm email** → **Save**
   - Así puedes crear la cuenta y entrar **al instante** en la demo
   - (La app del ingeniero sí pide confirmar correo; puedes volver a
     encenderlo después de la entrega)

## Paso 5 — Crear las tablas

1. Menú izquierdo → **SQL Editor**
2. Haz clic en **New query**
3. Pega **todo** el contenido de `docs/supabase_schema.sql`
4. Presiona **Run** (▶)
5. Abajo debería aparecer la tabla con 4 platos

---

## Checklist final

- [ ] Cuenta creada en supabase.com
- [ ] Proyecto `conecta-cruz` creado (región São Paulo o US East)
- [ ] URL + anon key pegadas en `lib/config.dart`
- [ ] *Confirm email* apagado en Authentication
- [ ] Script SQL ejecutado (4 platos visibles)
- [ ] `flutter run` en el emulador → la pantalla de bienvenida ya
      muestra el botón **Iniciar sesión** y ya **no** dice "Modo demo"

## Cómo verificar que todo funciona

1. **Iniciar sesión** → **Crear cuenta** → nombre, correo y clave → `Registrarme`
2. Te loguea solo → la bienvenida muestra tu correo
3. **Ver negocio** → el menú trae los 4 platos **desde la nube**
4. **Consultar** → escribes y `Enviar consulta`
5. **Reservar** → eliges fecha/hora/personas → `Confirmar reserva`
6. **Añadir plato** → nombre + precio → aparece en el menú
7. En el dashboard de Supabase → **Table Editor** → ves las filas aparecer
