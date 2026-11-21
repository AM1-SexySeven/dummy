import 'package:flutter/material.dart';

import '../services/carrito_service.dart';
import '../services/supabase_service.dart';
import 'login_page.dart';

/// Carrito «Mi pedido»: platos elegidos y envío del pedido al negocio.
class MiPedidoPage extends StatefulWidget {
  const MiPedidoPage({super.key});

  @override
  State<MiPedidoPage> createState() => _MiPedidoPageState();
}

class _MiPedidoPageState extends State<MiPedidoPage> {
  final _telCtrl = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _telCtrl.dispose();
    super.dispose();
  }

  String _bs(double v) => 'Bs ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  Future<void> _enviarPedido() async {
    // Sin sesión no se puede registrar el pedido.
    if (!SupabaseService.haySesion) {
      final ok = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      if (ok != true || !mounted) return;
    }
    final telefono = _telCtrl.text.trim();
    if (telefono.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu teléfono para avisarte')),
      );
      return;
    }
    setState(() => _enviando = true);
    try {
      final carrito = Carrito.instancia;
      await SupabaseService.enviarPedido(
        telefono: telefono,
        detalle: carrito.detalle,
        total: carrito.total,
      );
      Carrito.instancia.vaciar();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded,
              color: Colors.green, size: 48),
          title: const Text('¡Pedido enviado!'),
          content: const Text(
            'El negocio recibió tu pedido y lo confirmará por WhatsApp '
            'o por teléfono.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo enviar el pedido: $e')),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi pedido'),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<List<ItemCarrito>>(
        valueListenable: Carrito.instancia,
        builder: (context, items, _) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 84, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  const Text(
                    'Su carrito está vacío.',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text('Agregue productos desde el negocio.'),
                ],
              ),
            );
          }
          final total = Carrito.instancia.total;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return Card(
                      child: ListTile(
                        title: Text(
                          item.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(_bs(item.precio)),
                        leading: IconButton(
                          onPressed: () => Carrito.instancia
                              .cambiarCantidad(item.nombre, -1),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${item.cantidad}',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              onPressed: () => Carrito.instancia
                                  .cambiarCantidad(item.nombre, 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Total + teléfono + envío
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Text('Total'),
                          const Spacer(),
                          Text(
                            _bs(total),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _telCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono para avisarte',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _enviando ? null : _enviarPedido,
                        icon: _enviando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text('Enviar pedido'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
