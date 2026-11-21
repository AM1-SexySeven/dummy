import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/agregar_producto_page.dart';
import 'pages/consulta_page.dart';
import 'pages/cuenta_page.dart';
import 'pages/login_page.dart';
import 'pages/mapa_page.dart';
import 'pages/mi_pedido_page.dart';
import 'pages/producto_detalle_page.dart';
import 'pages/reserva_page.dart';
import 'services/carrito_service.dart';
import 'services/clima_service.dart';
import 'services/supabase_service.dart';
import 'widgets/foto_plato.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // La bienvenida sale de inmediato; Supabase se inicializa en segundo plano.
  runApp(const ConectaCruzApp());
  unawaited(SupabaseService.init());
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
/// Título + logo del negocio + botón «Ver negocio» + sesión de usuario.
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

    // Se redibuja sola cuando Supabase termina de inicializarse.
    return ValueListenableBuilder<bool>(
      valueListenable: SupabaseService.listo,
      builder: (context, listo, _) {
        final client = SupabaseService.client;

        // Con Supabase: se redibuja al cambiar la sesión (entrar/salir).
        // Sin Supabase (modo demo): se dibuja una sola vez.
        if (client == null) {
          // `sinConfigurar` solo cuando ya sabemos que no hay Supabase,
          // no mientras todavía está inicializando.
          return _pagina(context, theme, usuario: null, sinConfigurar: listo);
        }

        return StreamBuilder<AuthState>(
          stream: client.auth.onAuthStateChange,
          builder: (context, snap) {
            final sesion = snap.data?.session ?? client.auth.currentSession;
            return _pagina(context, theme,
                usuario: sesion?.user, sinConfigurar: false);
          },
        );
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
                      'Ver negocio',
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
  // El Future se crea UNA sola vez aquí (no en build):
  // así no se repite la consulta a la base de datos.
  late Future<CatalogoResult> _futuro;
  final _buscarCtrl = TextEditingController();
  String _filtro = '';

  // Clima de Santa Cruz (open-meteo) y dictado por voz del buscador
  final _voz = SpeechToText();
  late Future<ClimaResult> _clima;
  late Future<InfoNegocio> _negocio;
  bool _escuchando = false;

  @override
  void initState() {
    super.initState();
    _futuro = _crearFuturo();
    _clima = ClimaService.obtener();
    _negocio = SupabaseService.cargarNegocio();
  }

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  /// Inicia el dictado por voz: lo que se diga se escribe en el buscador.
  Future<void> _escuchar() async {
    final disponible = await _voz.initialize(
      onStatus: (estado) {
        if (estado == 'notListening' && mounted) {
          setState(() => _escuchando = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _escuchando = false);
      },
    );
    if (!mounted) return;
    if (!disponible) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Micrófono no disponible o sin permiso'),
        ),
      );
      return;
    }
    setState(() => _escuchando = true);
    await _voz.listen(
      onResult: (resultado) {
        setState(() {
          _buscarCtrl.text = resultado.recognizedWords;
          _filtro = resultado.recognizedWords.trim().toLowerCase();
        });
      },
      listenOptions: SpeechListenOptions(localeId: 'es_ES'),
    );
  }

  /// Agrega un plato al carrito y avisa.
  void _agregarAlCarrito(Producto p) {
    Carrito.instancia.agregar(nombre: p.nombre, precio: p.precio);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('«${p.nombre}» agregado a tu pedido')),
    );
  }

  Future<CatalogoResult> _crearFuturo() => SupabaseService.cargarProductos();

  /// Vuelve a consultar (botón «Reintentar» o tras añadir un plato).
  void _reintentar() {
    final nuevo = _crearFuturo();
    setState(() {
      _futuro = nuevo;
    });
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
    if (res == true) _reintentar(); // se añadió un plato: refrescamos la lista
  }

  /// Comparte la app por WhatsApp, correo o lo que el usuario elija.
  Future<void> _compartirApp() async {
    await SharePlus.instance.share(
      ShareParams(
        text: 'ConectaCruz — Churrasquería El Fogón 🍖🥩\n'
            'Nuestra carta con precios actualizados, consultas y reservas '
            'desde tu celular.\n'
            'Descárgala en: https://github.com/AM1-SexySeven/dummy',
      ),
    );
  }

  /// Abre el detalle del plato; desde ahí puede ir a Consultar o Reservar.
  Future<void> _abrirDetalle(Producto p) async {
    final accion = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => ProductoDetallePage(producto: p)),
    );
    if (!mounted || accion == null) return;
    if (accion == 'consultar') await _abrir(const ConsultaPage());
    if (accion == 'reservar') await _abrir(const ReservaPage());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('El Fogón'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MapaPage())),
            tooltip: 'Mapa de negocios',
            icon: const Icon(Icons.map_rounded),
          ),
          ValueListenableBuilder<List<ItemCarrito>>(
            valueListenable: Carrito.instancia,
            builder: (context, items, _) {
              final cantidad = Carrito.instancia.cantidadTotal;
              return Badge(
                label: Text('$cantidad'),
                isLabelVisible: cantidad > 0,
                child: IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MiPedidoPage()),
                  ),
                  tooltip: 'Mi pedido',
                  icon: const Icon(Icons.shopping_cart_rounded),
                ),
              );
            },
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CuentaPage()),
            ),
            tooltip: 'Mi cuenta',
            icon: const Icon(Icons.person_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: 'Más opciones',
            onSelected: (valor) {
              if (valor == 'compartir') _compartirApp();
              if (valor == 'actualizar') _reintentar();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'compartir',
                child: ListTile(
                  leading: Icon(Icons.share_rounded),
                  title: Text('Compartir la app'),
                ),
              ),
              PopupMenuItem(
                value: 'actualizar',
                child: ListTile(
                  leading: Icon(Icons.refresh_rounded),
                  title: Text('Actualizar menú'),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Clima en vivo de Santa Cruz (open-meteo). Si falla, avisa y
          // ofrece reintentar; la aplicación nunca se cierra.
          FutureBuilder<ClimaResult>(
            future: _clima,
            builder: (context, snap) {
              final tema = Theme.of(context);
              final resultado = snap.data;

              Widget contenido;
              Color? colorTarjeta;
              if (resultado == null) {
                contenido = const Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Consultando el clima de Santa Cruz…'),
                    ),
                  ],
                );
              } else if (resultado.esError) {
                colorTarjeta = tema.colorScheme.errorContainer;
                contenido = Row(
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      color: tema.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        resultado.mensaje ??
                            'No se pudo obtener el clima.',
                        style: TextStyle(
                          color: tema.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _clima = ClimaService.obtener();
                      }),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reintentar'),
                    ),
                  ],
                );
              } else {
                final clima = resultado.clima!;
                contenido = Row(
                  children: [
                    Icon(
                      Icons.wb_sunny_rounded,
                      color: tema.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Santa Cruz ahora: ${clima.temperatura.round()} °C'
                        ' · viento ${clima.viento.round()} km/h'
                        ' · ${clima.descripcion}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  Card(
                    color: colorTarjeta ?? tema.colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: contenido,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
          FutureBuilder<InfoNegocio>(
            future: _negocio,
            builder: (context, snap) {
              final info = snap.data ?? InfoNegocio.actual;
              final foto = info.fotoUrl.trim();
              final asset = Image.asset(
                'assets/images/logo_fogon.png',
                width: 280,
                height: 180,
                fit: BoxFit.cover,
              );
              return Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: foto.isEmpty
                      ? asset
                      : Image.network(
                          foto,
                          width: 280,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => asset,
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          FutureBuilder<InfoNegocio>(
            future: _negocio,
            builder: (context, snap) {
              final info = snap.data ?? InfoNegocio.actual;
              return Column(
                children: [
                  Text(
                    info.nombre,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Chip(
                      label: Text(info.rubro),
                      avatar:
                          const Icon(Icons.restaurant_rounded, size: 18),
                      backgroundColor: theme.colorScheme.primaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    info.descripcion,
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
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

          // Buscador de platos por nombre
          TextField(
            controller: _buscarCtrl,
            onChanged: (v) =>
                setState(() => _filtro = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Buscar plato...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                tooltip: _escuchando ? 'Escuchando…' : 'Buscar por voz',
                onPressed: _escuchando ? null : _escuchar,
                icon: Icon(
                  _escuchando ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: _escuchando
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),

          FutureBuilder<CatalogoResult>(
            future: _futuro,
            builder: (context, snap) {
              // Estado "cargando"
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              // Estado "error" (y no hay nada guardado en el dispositivo)
              if (!snap.hasData) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_off_rounded,
                          size: 48, color: theme.colorScheme.outline),
                      const SizedBox(height: 12),
                      const Text(
                        'No se pudo cargar el menú',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Revise su conexión a Internet e intente de nuevo.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _reintentar,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }
              final catalogo = snap.data!;
              // Estado "vacío"
              if (catalogo.productos.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Aún no hay platos en el menú')),
                );
              }
              // Filtro de búsqueda por nombre
              final visibles = catalogo.productos
                  .where((p) => p.nombre.toLowerCase().contains(_filtro))
                  .toList();
              if (visibles.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('Ningún plato coincide con tu búsqueda'),
                  ),
                );
              }
              // Estado "con datos" (en línea o desde el caché offline)
              final actualizado = catalogo.actualizado;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (actualizado != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Actualizado: ${actualizado.day}/${actualizado.month} '
                        '${actualizado.hour}:${actualizado.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  if (catalogo.desdeCache) ...[
                    _CacheNotice(onRetry: _reintentar),
                    const SizedBox(height: 8),
                  ],
                  for (final p in visibles)
                    _ProductoTile(
                      producto: p,
                      onTap: () => _abrirDetalle(p),
                      onAdd: () => _agregarAlCarrito(p),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Datos de contacto (los guarda Supabase; el dueño los edita
          // desde el Panel del negocio y el cliente ve siempre el último)
          FutureBuilder<InfoNegocio>(
            future: _negocio,
            builder: (context, snap) {
              final info = snap.data ?? InfoNegocio.actual;
              return Card(
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
                      _DatoRow(
                        icon: Icons.location_on_outlined,
                        texto: info.direccion,
                      ),
                      const SizedBox(height: 6),
                      _DatoRow(
                        icon: Icons.phone_outlined,
                        texto: 'Cel: ${info.telefono}',
                      ),
                      const SizedBox(height: 6),
                      _DatoRow(
                        icon: Icons.access_time_rounded,
                        texto: info.horario,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CacheNotice extends StatelessWidget {
  const _CacheNotice({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Sin conexión — mostrando los últimos platos guardados',
                style: TextStyle(fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
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
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _ProductoTile({
    required this.producto,
    required this.onTap,
    required this.onAdd,
  });

  /// Color del precio según el rango (Luis).
  static Color _colorPrecio(double precio) {
    if (precio <= 50) return Colors.green.shade700;
    if (precio <= 100) return Colors.orange.shade800;
    return Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final precio =
        'Bs ${producto.precio.toStringAsFixed(2).replaceAll('.', ',')}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: FotoPlato(fotoUrl: producto.fotoUrl),
        title: Text(
          producto.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(producto.descripcion),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              precio,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _colorPrecio(producto.precio),
              ),
            ),
            const SizedBox(width: 2),
            IconButton(
              tooltip: 'Agregar a tu pedido',
              icon: const Icon(Icons.add_shopping_cart_rounded),
              iconSize: 22,
              color: theme.colorScheme.primary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: onAdd,
            ),
            Icon(Icons.chevron_right_rounded,
                color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}

