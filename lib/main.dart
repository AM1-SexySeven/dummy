import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/agregar_producto_page.dart';
import 'pages/consulta_page.dart';
import 'pages/login_page.dart';
import 'pages/reserva_page.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  runApp(const ConectaCruzApp());
}

class ConectaCruzApp extends StatelessWidget {
  const ConectaCruzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConectaCruz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB33A1A), // brasas / rojo parrilla
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const BienvenidaPage(),
    );
  }
}

/// Pantalla de bienvenida de ConectaCruz.
/// Título + logo del negocio + botón «Ver negocios» + sesión de usuario.
class BienvenidaPage extends StatelessWidget {
  const BienvenidaPage({super.key});

  Future<void> _irALogin(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = SupabaseService.client;

    // Con Supabase: se redibuja al cambiar la sesión (entrar/salir).
    // Sin Supabase (modo demo): se dibuja una sola vez.
    if (client == null) {
      return _pagina(context, theme, usuario: null, sinConfigurar: true);
    }

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snap) {
        final sesion = snap.data?.session ?? client.auth.currentSession;
        return _pagina(context, theme,
            usuario: sesion?.user, sinConfigurar: false);
      },
    );
  }

  Widget _pagina(
    BuildContext context,
    ThemeData theme, {
    User? usuario,
    required bool sinConfigurar,
  }) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ConectaCruz'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(
                0.0,
                MediaQuery.of(context).size.height -
                    kToolbarHeight -
                    MediaQuery.of(context).padding.vertical,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Logo del negocio
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/logo_fogon.png',
                      width: 260,
                      height: 170,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'ConectaCruz',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Churrasquería El Fogón',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFB33A1A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Descubre, consulta y reserva en tu negocio de Santa Cruz',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 40),

                // Botón principal
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NegocioPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    child: Text(
                      'Ver negocios',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sesión de usuario
                if (usuario != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_circle_rounded,
                            size: 20,
                            color: theme.colorScheme.onSecondaryContainer),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${usuario.email}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => SupabaseService.cerrarSesion(),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Cerrar sesión'),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: () => _irALogin(context),
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'Iniciar sesión',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  if (sinConfigurar) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Modo demo: configure Supabase en lib/config.dart',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pantalla del negocio (Churrasquería El Fogón).
class NegocioPage extends StatefulWidget {
  const NegocioPage({super.key});

  @override
  State<NegocioPage> createState() => _NegocioPageState();
}

class _NegocioPageState extends State<NegocioPage> {
  List<Producto> _productos = Producto.ejemplos;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final lista = await SupabaseService.cargarProductos();
      if (!mounted) return;
      setState(() {
        _productos = lista;
        _cargando = false;
      });
    } catch (_) {
      // Sin conexión o tabla inexistente: mostramos los de ejemplo.
      if (!mounted) return;
      setState(() {
        _productos = Producto.ejemplos;
        _cargando = false;
      });
    }
  }

  /// Abre una pantalla; si hay Supabase pero no hay sesión, pide login antes.
  Future<void> _abrir(Widget pagina) async {
    if (SupabaseService.disponible && !SupabaseService.haySesion) {
      final ok = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      if (ok != true || !mounted) return;
    }
    if (!mounted) return;
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => pagina),
    );
    if (res == true) _cargar(); // se añadió un plato: refrescamos la lista
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Churrasquería El Fogón'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/logo_fogon.png',
                width: 280,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Churrasquería El Fogón',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Chip(
              label: const Text('Gastronomía'),
              avatar: const Icon(Icons.restaurant_rounded, size: 18),
              backgroundColor: theme.colorScheme.primaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Parrillas y platos tradicionales cruceños para compartir.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Acciones
          FilledButton.icon(
            onPressed: () => _abrir(const ConsultaPage()),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text('Consultar'),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _abrir(const ReservaPage()),
            icon: const Icon(Icons.calendar_month_rounded),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text('Reservar'),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _abrir(const AgregarProductoPage()),
            icon: const Icon(Icons.add_rounded),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text('Añadir plato'),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Productos y servicios',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          if (_cargando)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_productos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Aún no hay platos en el menú')),
            )
          else
            for (final p in _productos) _ProductoTile(producto: p),

          const SizedBox(height: 24),

          // Datos de contacto (como en la app del ingeniero)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información del negocio',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const _DatoRow(
                    icon: Icons.location_on_outlined,
                    texto: 'Av. Busch 1234, Santa Cruz de la Sierra',
                  ),
                  const SizedBox(height: 6),
                  const _DatoRow(
                    icon: Icons.phone_outlined,
                    texto: 'Cel: 591 700 0000',
                  ),
                  const SizedBox(height: 6),
                  const _DatoRow(
                    icon: Icons.access_time_rounded,
                    texto: 'Mar a Dom · 18:00 – 23:30',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DatoRow extends StatelessWidget {
  final IconData icon;
  final String texto;

  const _DatoRow({required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(texto)),
      ],
    );
  }
}

class _ProductoTile extends StatelessWidget {
  final Producto producto;

  const _ProductoTile({required this.producto});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final precio =
        'Bs ${producto.precio.toStringAsFixed(2).replaceAll('.', ',')}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.restaurant_menu_rounded),
        title: Text(
          producto.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(producto.descripcion),
        trailing: Text(
          precio,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}