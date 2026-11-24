import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import '../services/theme_service.dart';
import 'login_page.dart';
import 'panel_negocio_page.dart';

/// «Mi cuenta»: datos de la sesión y, solo si el rol es «dueno» en
/// `perfiles`, acceso al panel del negocio.
class CuentaPage extends StatefulWidget {
  const CuentaPage({super.key});

  @override
  State<CuentaPage> createState() => _CuentaPageState();
}

class _CuentaPageState extends State<CuentaPage> {
  /// Se carga UNA vez (al abrir la pantalla).
  late final Future<String> _rol = SupabaseService.rolActual();

  Future<void> _abrirPanel(BuildContext context) async {
    final ok = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PanelNegocioPage()),
    );
    if (ok != true || !context.mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usuario = SupabaseService.usuario;
    final correo = usuario?.email;
    final nombre = usuario?.userMetadata?['nombre'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi cuenta'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: theme.colorScheme.primary,
                  child: correo == null
                      ? const Icon(Icons.person_rounded,
                          size: 56, color: Colors.white)
                      : Text(
                          correo.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              if (correo != null) ...[
                Text(
                  nombre == null || nombre.isEmpty
                      ? correo
                      : '$nombre\n$correo',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                FutureBuilder<String>(
                  future: _rol,
                  builder: (context, snap) {
                    final rol = snap.data;
                    final texto = rol == null
                        ? 'Leyendo el rol de la cuenta…'
                        : rol == 'dueno'
                            ? 'Dueño de negocio'
                            : 'Cliente';
                    return Center(
                      child: Text(
                        texto,
                        style: TextStyle(color: theme.colorScheme.outline),
                      ),
                    );
                  },
                ),
              ] else ...[
                const Center(
                  child: Text(
                    'Sin sesión iniciada',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text('Inicia sesión para gestionar tu negocio.'),
                ),
              ],
              const SizedBox(height: 32),
              if (correo != null) ...[
                FutureBuilder<String>(
                  future: _rol,
                  builder: (context, snap) {
                    final rol = snap.data;
                    if (rol == 'dueno') {
                      return FilledButton.icon(
                        onPressed: () => _abrirPanel(context),
                        icon: const Icon(Icons.dashboard_rounded),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.0),
                          child: Text('Panel del negocio'),
                        ),
                      );
                    }
                    return const Center(
                      child: Text(
                        'Tu cuenta es de cliente. Las reservas y pedidos '
                        'que hagas aparecerán en el panel del negocio.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await SupabaseService.cerrarSesion();
                    if (context.mounted) setState(() {});
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    child: Text('Cerrar sesión'),
                  ),
                ),
              ] else
                OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                    if (context.mounted) setState(() {});
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    child: Text('Iniciar sesión'),
                  ),
                ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Apariencia de la aplicación',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeService.modoTema,
                builder: (context, modoActual, _) {
                  return SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        label: Text('Claro'),
                        icon: Icon(Icons.light_mode_rounded),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        label: Text('Oscuro'),
                        icon: Icon(Icons.dark_mode_rounded),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        label: Text('Sistema'),
                        icon: Icon(Icons.brightness_auto_rounded),
                      ),
                    ],
                    selected: {modoActual},
                    onSelectionChanged: (nuevaSeleccion) {
                      if (nuevaSeleccion.isNotEmpty) {
                        ThemeService.cambiarModo(nuevaSeleccion.first);
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
