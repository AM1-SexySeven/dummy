import 'package:flutter/material.dart';

import '../services/carrito_service.dart';
import '../services/supabase_service.dart';
import '../services/theme_service.dart';
import '../widgets/foto_plato.dart';

/// Último paso antes de pagar: el cliente revisa a nombre de quién va el
/// pedido, qué pidió y cuánto va a pagar.
///
/// Es una pantalla de solo lectura a propósito (salvo el teléfono): quien
/// quiera corregir cantidades vuelve atrás, al carrito. Así el resumen que
/// se confirma es exactamente el que se cobra.
///
/// Devuelve el teléfono de contacto si el cliente confirma, o `null` si
/// se arrepiente.
class ConfirmarPedidoPage extends StatefulWidget {
  const ConfirmarPedidoPage({super.key, this.telefonoInicial = ''});

  final String telefonoInicial;

  @override
  State<ConfirmarPedidoPage> createState() => _ConfirmarPedidoPageState();
}

class _ConfirmarPedidoPageState extends State<ConfirmarPedidoPage> {
  late final TextEditingController _telCtrl =
      TextEditingController(text: widget.telefonoInicial);

  late final Future<InfoNegocio> _negocio = SupabaseService.cargarNegocio();

  @override
  void dispose() {
    _telCtrl.dispose();
    super.dispose();
  }

  String _bs(double v) => 'Bs ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  void _confirmar() {
    final telefono = _telCtrl.text.trim();
    if (telefono.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresá un teléfono para que el negocio te avise'),
        ),
      );
      return;
    }
    Navigator.pop(context, telefono);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usuario = SupabaseService.usuario;
    final nombre = (usuario?.userMetadata?['nombre'] as String?)?.trim();
    final correo = usuario?.email ?? '';
    final items = Carrito.instancia.value;
    final total = Carrito.instancia.total;
    final unidades = Carrito.instancia.cantidadTotal;

    return Scaffold(
      appBar: AppBar(title: const Text('Último paso'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _Rotulo('A nombre de'),
          Text(
            nombre == null || nombre.isEmpty ? correo : nombre,
            style: theme.textTheme.titleLarge,
          ),
          if (nombre != null && nombre.isNotEmpty && correo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(correo,
                  style: TextStyle(color: theme.colorScheme.outline)),
            ),
          const SizedBox(height: 22),
          TextField(
            controller: _telCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Teléfono para avisarte',
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 30),
          _Rotulo('Tu pedido · $unidades ${unidades == 1 ? "ítem" : "ítems"}'),
          const SizedBox(height: 4),
          for (final item in items) _FilaItem(item: item, bs: _bs),

          const SizedBox(height: 26),
          _Rotulo('Resumen'),
          const SizedBox(height: 8),
          _FilaMonto(etiqueta: 'Productos', valor: _bs(total)),
          const _FilaMonto(etiqueta: 'Servicio en el local', valor: 'Sin cargo'),

          const SizedBox(height: 26),
          // Dónde se retira: el pedido se recoge en el local, no hay envío.
          FutureBuilder<InfoNegocio>(
            future: _negocio,
            builder: (context, snap) {
              final n = snap.data;
              if (n == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Rotulo('Retirás en'),
                  const SizedBox(height: 4),
                  Text(n.nombre, style: theme.textTheme.titleLarge),
                  if (n.direccion.isNotEmpty)
                    Text(n.direccion,
                        style: TextStyle(color: theme.colorScheme.outline)),
                  if (n.horario.isNotEmpty)
                    Text(n.horario,
                        style: TextStyle(color: theme.colorScheme.outline)),
                ],
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: ThemeService.linea)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('Total a pagar', style: theme.textTheme.labelMedium),
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
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: items.isEmpty ? null : _confirmar,
                icon: const Icon(Icons.qr_code_2_rounded),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('Pagar con QR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rótulo de sección: chico, espaciado y en mayúsculas.
class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          texto.toUpperCase(),
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(letterSpacing: 0.7),
        ),
      );
}

/// Una línea del pedido: foto, cantidad, nombre, precio unitario y subtotal.
class _FilaItem extends StatelessWidget {
  const _FilaItem({required this.item, required this.bs});
  final ItemCarrito item;
  final String Function(double) bs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ThemeService.linea)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: FotoPlato(fotoUrl: item.fotoUrl, forma: FotoForma.lleno),
          ),
          const SizedBox(width: 12),
          // La cantidad va adelante del nombre, como en una comanda.
          Text(
            '${item.cantidad}×',
            style: const TextStyle(
              fontFamily: ThemeService.texto,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.nombre, style: theme.textTheme.titleLarge),
                Text('${bs(item.precio)} c/u',
                    style: TextStyle(
                        fontSize: 12.5, color: theme.colorScheme.outline)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            bs(item.subtotal),
            style: const TextStyle(
              fontFamily: ThemeService.texto,
              fontWeight: FontWeight.w600,
              fontSize: 15.5,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Una línea del resumen: etiqueta a la izquierda, monto a la derecha.
class _FilaMonto extends StatelessWidget {
  const _FilaMonto({required this.etiqueta, required this.valor});
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Text(etiqueta),
            const Spacer(),
            Text(
              valor,
              style: const TextStyle(
                fontFamily: ThemeService.texto,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
}
