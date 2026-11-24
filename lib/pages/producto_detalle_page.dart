import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/storage_service.dart';
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

  /// Rol de la sesión: el botón de cambiar la foto solo lo ve el dueño.
  late final Future<String> _rol = SupabaseService.rolActual();

  /// Foto que se está mostrando. Arranca con la que traía el plato y
  /// cambia en el acto cuando el dueño sube una nueva, sin esperar a
  /// que se recargue el catálogo.
  late String _fotoUrl = widget.producto.fotoUrl;

  bool _subiendo = false;

  /// Pregunta de dónde sacar la foto y la sube.
  Future<void> _cambiarFoto() async {
    final origen = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Foto del plato',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar una foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (origen == null || !mounted) return;

    setState(() => _subiendo = true);
    final subida = await StorageService.subirFotoPlato(
      productoId: widget.producto.id,
      origen: origen,
    );
    if (!mounted) return;

    // Cancelar no es un error: no se avisa nada.
    if (subida.cancelada) {
      setState(() => _subiendo = false);
      return;
    }

    if (!subida.ok) {
      setState(() => _subiendo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(subida.mensaje ?? 'No se pudo subir la foto.')),
      );
      return;
    }

    // La foto ya está en el depósito; falta dejar su dirección en el plato.
    try {
      await SupabaseService.actualizarFotoProducto(
        productoId: widget.producto.id,
        url: subida.url!,
      );
      if (!mounted) return;
      setState(() {
        _fotoUrl = subida.url!;
        _subiendo = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto actualizada')),
      );
    } on StateError catch (e) {
      // El plato ya no está en el catálogo.
      if (!mounted) return;
      setState(() => _subiendo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _subiendo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La foto se subió, pero no se pudo guardar en el '
              'plato. Revisá que la cuenta sea de dueño.'),
        ),
      );
    }
  }

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
                child: _subiendo
                    ? const SizedBox(
                        width: 240,
                        height: 240,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text('Subiendo la foto…'),
                            ],
                          ),
                        ),
                      )
                    : FotoPlato(
                        fotoUrl: _fotoUrl,
                        tamano: 240,
                        forma: FotoForma.cuadrado,
                      ),
              ),
              // Cambiar la foto solo lo puede hacer el dueño del negocio.
              // Mientras se resuelve el rol no se dibuja nada, para que
              // el botón no aparezca y desaparezca.
              FutureBuilder<String>(
                future: _rol,
                builder: (context, snap) {
                  if (snap.data != 'dueno') return const SizedBox(height: 16);
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Center(
                      child: OutlinedButton.icon(
                        onPressed: _subiendo ? null : _cambiarFoto,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Cambiar foto'),
                      ),
                    ),
                  );
                },
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
