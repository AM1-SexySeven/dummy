import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

/// Panel del negocio: Reservas · Pedidos · Consultas · Negocio.
///
/// Las reservas y consultas son de solo lectura; los pedidos pueden
/// cambiar de estado (pendiente → preparando → entregado / cancelado).
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

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _reservas = _cargar(SupabaseService.cargarReservas);
    _pedidos = _cargar(SupabaseService.cargarPedidos);
    _consultas = _cargar(SupabaseService.cargarConsultas);
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

  void _recargar() {
    setState(() {
      _reservas = _cargar(SupabaseService.cargarReservas);
      _pedidos = _cargar(SupabaseService.cargarPedidos);
      _consultas = _cargar(SupabaseService.cargarConsultas);
    });
  }

  String _bs(num v) => 'Bs ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del negocio'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _recargar,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Reservas'),
            Tab(text: 'Pedidos'),
            Tab(text: 'Consultas'),
            Tab(text: 'Negocio'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _lista(_reservas, _reservaCard),
          _lista(_pedidos, _pedidoCard),
          _lista(_consultas, _consultaCard),
          const _NegocioTab(),
        ],
      ),
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
                        _recargar();
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

