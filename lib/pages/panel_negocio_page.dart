import 'package:flutter/material.dart';

import '../services/theme_service.dart';

import '../services/supabase_service.dart';
import '../widgets/foto_plato.dart';
import 'agregar_producto_page.dart';

/// Panel del negocio: Reservas · Pedidos · Consultas · Platos · Negocio.
///
/// Las reservas y consultas son de solo lectura; los pedidos pueden
/// cambiar de estado (pendiente → preparando → entregado / cancelado).
/// En «Platos» el dueño gestiona la carta (añadir, editar precio, eliminar).
/// En «Negocio» el dueño edita la información que el cliente ve y da de
/// alta a otros dueños.
class PanelNegocioPage extends StatefulWidget {
  const PanelNegocioPage({super.key});

  @override
  State<PanelNegocioPage> createState() => _PanelNegocioPageState();
}

class _PanelNegocioPageState extends State<PanelNegocioPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late Future<List<Map<String, dynamic>>> _reservas;
  late Future<List<Map<String, dynamic>>> _pedidos;
  late Future<List<Map<String, dynamic>>> _consultas;
  late Future<CatalogoResult> _productos;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _cargarTodo();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _cargar(
    Future<List<Map<String, dynamic>>> Function() fn,
  ) async {
    try {
      return await fn();
    } catch (_) {
      return const [];
    }
  }

  void _cargarTodo() {
    setState(() {
      _reservas = _cargar(SupabaseService.cargarReservas);
      _pedidos = _cargar(SupabaseService.cargarPedidos);
      _consultas = _cargar(SupabaseService.cargarConsultas);
      _productos = SupabaseService.cargarProductos();
    });
  }

  String _bs(num v) => 'Bs ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _cargarTodo,
            tooltip: 'Actualizar panel',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month_rounded, size: 18), text: 'Reservas'),
            Tab(icon: Icon(Icons.shopping_bag_outlined, size: 18), text: 'Pedidos'),
            Tab(icon: Icon(Icons.chat_bubble_outline_rounded, size: 18), text: 'Consultas'),
            Tab(icon: Icon(Icons.restaurant_menu_rounded, size: 18), text: 'Platos'),
            Tab(icon: Icon(Icons.storefront_rounded, size: 18), text: 'Negocio'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Banner de métricas rápidas arriba del panel
          _resumenMetricasHeader(theme),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _lista(_reservas, _reservaCard),
                _lista(_pedidos, _pedidoCard),
                _lista(_consultas, _consultaCard),
                _PlatosTab(onPlatoModificado: _cargarTodo),
                const _NegocioTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjetas de resumen rápido en la cabecera
  Widget _resumenMetricasHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _metricChip(
              icon: Icons.calendar_month_rounded,
              label: 'Reservas',
              future: _reservas.then((l) => l.length),
              color: Colors.blue.shade700,
            ),
            const SizedBox(width: 8),
            _metricChip(
              icon: Icons.shopping_bag_outlined,
              label: 'Pedidos',
              future: _pedidos.then((l) => l.length),
              color: Colors.orange.shade800,
            ),
            const SizedBox(width: 8),
            _metricChip(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Consultas',
              future: _consultas.then((l) => l.length),
              color: Colors.teal.shade700,
            ),
            const SizedBox(width: 8),
            _metricChip(
              icon: Icons.restaurant_rounded,
              label: 'Platos',
              future: _productos.then((c) => c.productos.length),
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricChip({
    required IconData icon,
    required String label,
    required Future<int> future,
    required Color color,
  }) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snap) {
        final cant = snap.data ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                '$label: ',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Text(
                '$cant',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _lista(
    Future<List<Map<String, dynamic>>> future,
    Widget Function(Map<String, dynamic> fila) card,
  ) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final filas = snap.data ?? const [];
        if (filas.isEmpty) {
          return _vacio(context, 'Sin registros por ahora');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filas.length,
          itemBuilder: (context, i) => card(filas[i]),
        );
      },
    );
  }

  Widget _vacio(BuildContext context, String texto) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(texto),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- reservas
  Widget _reservaCard(Map<String, dynamic> r) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_month_rounded),
        title: Text(
          '${r['nombre'] ?? 'Cliente'} · ${r['personas'] ?? 1} persona(s)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Fecha: ${r['fecha'] ?? '—'}\n${r['detalle'] ?? ''}'),
        isThreeLine: true,
        trailing: Chip(label: Text(_estadoLabel('${r['estado'] ?? 'pendiente'}'))),
      ),
    );
  }

  // ------------------------------------------------------------- consultas
  Widget _consultaCard(Map<String, dynamic> c) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.chat_bubble_outline_rounded),
        title: Text(
          '${c['nombre'] ?? 'Anónimo'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${c['mensaje'] ?? ''}'),
        isThreeLine: false,
      ),
    );
  }

  // -------------------------------------------------------------- pedidos
  static const _estados = ['pendiente', 'preparando', 'entregado', 'cancelado'];

  String _estadoLabel(String e) => switch (e) {
        'pendiente' => 'pendiente',
        'preparando' => 'preparando',
        'entregado' => 'entregado',
        'cancelado' => 'cancelado',
        _ => e,
      };

  Widget _pedidoCard(Map<String, dynamic> p) {
    final id = (p['id'] as num?)?.toInt() ?? 0;
    final estado = '${p['estado'] ?? 'pendiente'}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pedido #$id · ${p['nombre'] ?? 'Cliente'} · ${_bs((p['total'] as num?) ?? 0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('${p['detalle'] ?? ''}'),
            Text(
              'Tel. ${p['telefono'] ?? '—'}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                for (final e in _estados)
                  ChoiceChip(
                    label: Text(_estadoLabel(e)),
                    selected: estado == e,
                    onSelected: (sel) async {
                      if (!sel || estado == e) return;
                      try {
                        await SupabaseService.actualizarEstadoPedido(id, e);
                        if (!mounted) return;
                        _cargarTodo();
                      } catch (err) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('No se pudo actualizar: $err')),
                        );
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab para la gestión completa de platos en el menú.
class _PlatosTab extends StatefulWidget {
  const _PlatosTab({required this.onPlatoModificado});

  final VoidCallback onPlatoModificado;

  @override
  State<_PlatosTab> createState() => _PlatosTabState();
}

class _PlatosTabState extends State<_PlatosTab> {
  late Future<CatalogoResult> _productos;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _productos = SupabaseService.cargarProductos();
    });
  }

  Future<void> _abrirAgregarPlato() async {
    final agregado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AgregarProductoPage()),
    );
    if (agregado == true && mounted) {
      _cargar();
      widget.onPlatoModificado();
    }
  }

  Future<void> _editarPrecio(Producto p) async {
    final ctrl = TextEditingController(text: p.precio.toStringAsFixed(2));
    final nuevoPrecio = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar precio: ${p.nombre}'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Nuevo precio (Bs)',
            prefixIcon: Icon(Icons.attach_money_rounded),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
              if (val != null && val > 0) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (nuevoPrecio == null || !mounted) return;

    try {
      await SupabaseService.actualizarPrecioProducto(p.id, nuevoPrecio);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Precio de «${p.nombre}» actualizado a Bs ${nuevoPrecio.toStringAsFixed(2)}',
          ),
        ),
      );
      _cargar();
      widget.onPlatoModificado();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el precio: $e')),
      );
    }
  }

  Future<void> _eliminarPlato(Producto p) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar plato'),
        content: Text('¿Seguro que deseas eliminar «${p.nombre}» del menú?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await SupabaseService.eliminarProducto(p.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plato «${p.nombre}» eliminado')),
      );
      _cargar();
      widget.onPlatoModificado();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: FutureBuilder<CatalogoResult>(
        future: _productos,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final lista = snap.data?.productos ?? [];
          if (lista.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu_rounded,
                      size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  const Text('No hay platos registrados en el menú'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _abrirAgregarPlato,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Añadir primer plato'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 80),
            itemCount: lista.length,
            itemBuilder: (context, i) {
              final p = lista[i];
              final precio =
                  'Bs ${p.precio.toStringAsFixed(2).replaceAll('.', ',')}';
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: ThemeService.linea)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: FotoPlato(
                        fotoUrl: p.fotoUrl,
                        forma: FotoForma.lleno,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(p.nombre, style: theme.textTheme.titleLarge),
                          const SizedBox(height: 5),
                          Text(
                            precio,
                            style: const TextStyle(
                              fontFamily: ThemeService.texto,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: ThemeService.brasa,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Editar precio',
                      onPressed: () => _editarPrecio(p),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 20, color: theme.colorScheme.error),
                      tooltip: 'Eliminar plato',
                      onPressed: () => _eliminarPlato(p),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirAgregarPlato,
        backgroundColor: ThemeService.tinta,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo plato'),
      ),
    );
  }
}

class _NegocioTab extends StatefulWidget {
  const _NegocioTab();

  @override
  State<_NegocioTab> createState() => _NegocioTabState();
}

class _NegocioTabState extends State<_NegocioTab> {
  final _nombre = TextEditingController();
  final _direccion = TextEditingController();
  final _telefono = TextEditingController();
  final _whatsapp = TextEditingController();
  final _descripcion = TextEditingController();
  final _horario = TextEditingController();
  final _foto = TextEditingController();
  final _correoDueno = TextEditingController();

  InfoNegocio? _cargado;
  String? _error;
  bool _guardando = false;
  bool _agregando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _direccion.dispose();
    _telefono.dispose();
    _whatsapp.dispose();
    _descripcion.dispose();
    _horario.dispose();
    _foto.dispose();
    _correoDueno.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final info = await SupabaseService.cargarNegocio();
    if (!mounted) return;
    setState(() {
      _cargado = info;
      _nombre.text = info.nombre;
      _direccion.text = info.direccion;
      _telefono.text = info.telefono;
      _whatsapp.text = info.whatsapp;
      _descripcion.text = info.descripcion;
      _horario.text = info.horario;
      _foto.text = info.fotoUrl;
    });
  }

  String _mensaje(Object e) {
    final t = e.toString();
    final i = t.indexOf('message:');
    if (i >= 0) {
      final raw = t.substring(i + 8).trim();
      return raw.replaceAll(RegExp(r'[{}"\u0027]'), '').trim();
    }
    return t;
  }

  Future<void> _guardar() async {
    final info = _cargado;
    if (info == null) return;
    if (_nombre.text.trim().isEmpty) {
      setState(() => _error = 'El nombre del negocio no puede estar vacío');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await SupabaseService.actualizarNegocio(info.copyWith(
        nombre: _nombre.text.trim(),
        direccion: _direccion.text.trim(),
        telefono: _telefono.text.trim(),
        whatsapp: _whatsapp.text.trim(),
        descripcion: _descripcion.text.trim(),
        horario: _horario.text.trim(),
        fotoUrl: _foto.text.trim(),
      ));
      if (!mounted) return;
      await _cargar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Información guardada ✓')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _mensaje(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _agregarDueno() async {
    final correo = _correoDueno.text.trim();
    if (!correo.contains('@')) {
      setState(() => _error = 'Ingrese un correo válido');
      return;
    }
    setState(() {
      _agregando = true;
      _error = null;
    });
    try {
      await SupabaseService.agregarDueno(correo);
      if (!mounted) return;
      _correoDueno.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$correo ahora es dueño del negocio ✓')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _mensaje(e));
    } finally {
      if (mounted) setState(() => _agregando = false);
    }
  }

  Widget _campo(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_cargado == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Información que ven los clientes',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Cuando guardes, el teléfono, la dirección y el resto se '
          'actualizan al instante en la app de los clientes.',
          style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 14),

        _campo(_nombre, 'Nombre del negocio', Icons.storefront_rounded),
        _campo(_direccion, 'Dirección', Icons.location_on_outlined),
        _campo(_telefono, 'Teléfono', Icons.phone_outlined,
            keyboardType: TextInputType.phone),
        _campo(_whatsapp, 'WhatsApp', Icons.chat_rounded,
            keyboardType: TextInputType.phone),
        _campo(_descripcion, 'Descripción', Icons.notes_rounded,
            maxLines: 2),
        _campo(_horario, 'Horario de atención', Icons.access_time_rounded),
        _campo(_foto, 'URL de la foto del negocio (opcional)',
            Icons.image_outlined),
        if (_foto.text.isNotEmpty) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _foto.text,
              height: 110,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 4),
        ],
        if (_error != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _guardando ? null : _guardar,
          icon: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Text(_guardando ? 'Guardando…' : 'Guardar cambios'),
          ),
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),
        Text(
          'Agregar dueño',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'La persona debe tener una cuenta en ConectaCruz. '
          'Al guardarla, podrá entrar al Panel del negocio.',
          style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _correoDueno,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo del nuevo dueño',
            prefixIcon: Icon(Icons.person_add_alt_1_rounded),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _agregando ? null : _agregarDueno,
          icon: _agregando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.verified_user_rounded),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(_agregando ? 'Agregando…' : 'Hacer dueño'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
