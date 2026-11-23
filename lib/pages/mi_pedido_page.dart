import 'package:flutter/material.dart';

import '../services/carrito_service.dart';
import '../services/supabase_service.dart';
import 'login_page.dart';
import 'pago_qr_page.dart';

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

  /// Traduce la excepción a algo que el cliente pueda entender.
  ///
  /// El mensaje técnico sirve para nosotros, no para quien está
  /// pidiendo comida, y además deja a la vista la dirección del
  /// servidor. Se registra en la consola y en pantalla va una frase
  /// clara, con el mismo vocabulario que usa la pantalla del QR.
  String _mensajeDeError(Object e) {
    debugPrint('Error al enviar el pedido: $e');
    final texto = e.toString();
    if (texto.contains('SocketException') ||
        texto.contains('Failed host lookup') ||
        texto.contains('ClientException')) {
      return 'Sin conexión a internet. Revisá tu conexión e intentá de nuevo.';
    }
    if (texto.contains('TimeoutException')) {
      return 'El servidor está tardando en responder. Intentá de nuevo.';
    }
    return 'No se pudo registrar el pedido. Intentá de nuevo en un momento.';
  }

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
      final total = carrito.total;

      // 1. El pedido se registra primero, en estado pendiente. Su número
      //    es el que identifica el cobro, así que no se descarta.
      final pedidoId = await SupabaseService.enviarPedido(
        telefono: telefono,
        detalle: carrito.detalle,
        total: total,
      );
      if (!mounted) return;

      // 2. Pantalla de pago por QR. Devuelve true solo si el banco
      //    confirmó que recibió el dinero.
      final pagado = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PagoQrPage(pedidoId: pedidoId, monto: total),
        ),
      );
      if (!mounted) return;

      // 3. El carrito se vacía únicamente con el pago confirmado. Si el
      //    cliente sale sin pagar, su pedido lo espera tal como estaba.
      if (pagado != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pedido N.º $pedidoId guardado sin pagar. '
                'Podés pagarlo cuando quieras.'),
          ),
        );
        return;
      }

      Carrito.instancia.vaciar();
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded,
              color: Colors.green, size: 48),
          title: const Text('¡Pedido pagado!'),
          content: Text(
            'El negocio recibió tu pedido N.º $pedidoId y el pago. '
            'Te avisará por WhatsApp cuando esté listo.',
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
        SnackBar(
          content: Text(_mensajeDeError(e)),
          action: SnackBarAction(
            label: 'Reintentar',
            onPressed: _enviarPedido,
          ),
        ),
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
                          child: Text('Pagar con QR'),
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
