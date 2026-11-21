import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/supabase_service.dart';
import '../widgets/foto_plato.dart';

/// Pantalla de detalle de un plato del catálogo.
///
/// Consultar/Reservar devuelven el resultado (`consultar` / `reservar`)
/// al catálogo, que decide pedir sesión antes de abrir el formulario.
class ProductoDetallePage extends StatefulWidget {
  const ProductoDetallePage({super.key, required this.producto});

  final Producto producto;

  @override
  State<ProductoDetallePage> createState() => _ProductoDetallePageState();
}

class _ProductoDetallePageState extends State<ProductoDetallePage> {
  /// La información vigente del negocio (tel/WhatsApp) la carga Supabase;
  /// si no hay internet, el caché local o el respaldo.
  late final Future<InfoNegocio> _negocio = SupabaseService.cargarNegocio();

  /// Abre una URL externa (teléfono / WhatsApp) sin crashear si falla.
  Future<void> _abrir(BuildContext context, Uri url) async {
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la aplicación')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final producto = widget.producto;
    final theme = Theme.of(context);
    final precio =
        'Bs ${producto.precio.toStringAsFixed(2).replaceAll('.', ',')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del plato'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: FotoPlato(
                  fotoUrl: producto.fotoUrl,
                  tamano: 240,
                  forma: FotoForma.cuadrado,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                producto.nombre,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Center(
                child: Chip(
                  label: const Text('Gastronomía'),
                  avatar: const Icon(Icons.restaurant_rounded, size: 18),
                  backgroundColor: theme.colorScheme.primaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Descripción',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                producto.descripcion.isEmpty
                    ? 'Plato de la casa.'
                    : producto.descripcion,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Precio',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        precio,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Estas consultas devuelven el resultado al catálogo
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, 'consultar'),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Consultar sobre este plato'),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, 'reservar'),
                icon: const Icon(Icons.calendar_month_rounded),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Reservar para comer'),
                ),
              ),
              const SizedBox(height: 10),
              // Contacto directo: usa el número vigente guardado en Supabase
              FutureBuilder<InfoNegocio>(
                future: _negocio,
                builder: (context, snap) {
                  final info = snap.data ?? InfoNegocio.actual;
                  final numero = info.numeroWa;
                  return Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _abrir(
                          context,
                          Uri(scheme: 'tel', path: numero),
                        ),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                        icon: const Icon(Icons.call_rounded, size: 16),
                        label: const Text('Llamar',
                            style: TextStyle(fontSize: 12)),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _abrir(
                          context,
                          Uri.parse(
                            'https://wa.me/$numero?text=${Uri.encodeComponent('Hola 👋, vengo del catálogo de ConectaCruz y quiero hacer un pedido.')}',
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                        icon: const Icon(Icons.chat_rounded, size: 16),
                        label: const Text('WhatsApp',
                            style: TextStyle(fontSize: 12)),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _abrir(
                          context,
                          Uri.parse(
                            'https://www.google.com/maps/dir/?api=1'
                            '&destination=-17.7925,-63.1780',
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                        icon: const Icon(Icons.directions_rounded, size: 16),
                        label: const Text('Cómo llegar',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
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
