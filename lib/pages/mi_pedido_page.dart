import 'package:flutter/material.dart';

import '../services/theme_service.dart';

import '../services/carrito_service.dart';
import '../services/supabase_service.dart';
import '../widgets/foto_plato.dart';
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
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: ThemeService.linea),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 62,
                            height: 62,
                            child: FotoPlato(
                              fotoUrl: item.fotoUrl,
                              forma: FotoForma.lleno,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(item.nombre,
                                    style: theme.textTheme.titleLarge),
                                const SizedBox(height: 7),
                                // El menos y el más, juntos y del mismo lado:
                                // así se ajusta la cantidad sin cruzar la fila.
                                Row(
                                  children: [
                                    _PasoCantidad(
                                      icono: item.cantidad == 1
                                          ? Icons.delete_outline_rounded
                                          : Icons.remove_rounded,
                                      onTap: () => Carrito.instancia
                                          .cambiarCantidad(item.nombre, -1),
                                    ),
                                    SizedBox(
                                      width: 30,
                                      child: Text(
                                        '${item.cantidad}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontFamily: ThemeService.texto,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14.5,
                                          fontFeatures: [
                                            FontFeature.tabularFigures()
                                          ],
                                        ),
                                      ),
                                    ),
                                    _PasoCantidad(
                                      icono: Icons.add_rounded,
                                      onTap: () => Carrito.instancia
                                          .cambiarCantidad(item.nombre, 1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _bs(item.precio * item.cantidad),
                            style: const TextStyle(
                              fontFamily: ThemeService.texto,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Total + teléfono + envío
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: ThemeService.linea),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('Total', style: theme.textTheme.labelMedium),
                          const Spacer(),
                          Text(
                            _bs(total),
                            style: const TextStyle(
                              fontFamily: ThemeService.texto,
                              fontWeight: FontWeight.w700,
                              fontSize: 30,
                              height: 1,
                              fontFeatures: [FontFeature.tabularFigures()],
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

/// Un paso de cantidad: cuadrado, borde fino, sin relleno.
class _PasoCantidad extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;
  const _PasoCantidad({required this.icono, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: ThemeService.linea, width: 1.4),
        ),
        child: Icon(icono, size: 15, color: ThemeService.humo),
      ),
    );
  }
}
