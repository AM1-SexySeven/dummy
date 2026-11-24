import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/storage_service.dart';
import '../services/theme_service.dart';
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
      // Sin barra superior: la foto empieza arriba de todo y la flecha
      // de volver va encima de ella.
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 380,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_subiendo)
                    const ColoredBox(
                      color: Color(0xFFEFE9E1),
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
                  else
                    FotoPlato(fotoUrl: _fotoUrl, forma: FotoForma.lleno),
                  // Un velo corto arriba, sólo para que la flecha se vea
                  // sobre fotos claras.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.32],
                        colors: [Color(0x800A0706), Color(0x000A0706)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 16,
                    child: Material(
                      color: const Color(0xEBFFFFFF),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(Icons.arrow_back_rounded,
                              size: 21, color: ThemeService.tinta),
                        ),
                      ),
                    ),
                  ),
                  // Cambiar la foto solo lo puede hacer el dueño. Mientras
                  // se resuelve el rol no se dibuja nada, para que el botón
                  // no aparezca y desaparezca.
                  ValueListenableBuilder<String>(
                    valueListenable: SupabaseService.rol,
                    builder: (context, rol, _) {
                      if (rol != 'dueno') return const SizedBox.shrink();
                      return Positioned(
                        left: 16,
                        bottom: 14,
                        child: Material(
                          color: const Color(0xEBFFFFFF),
                          child: InkWell(
                            onTap: _subiendo ? null : _cambiarFoto,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.photo_camera_outlined,
                                      size: 16, color: ThemeService.tinta),
                                  SizedBox(width: 7),
                                  Text('Cambiar foto',
                                      style: TextStyle(
                                        fontFamily: ThemeService.texto,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5,
                                        color: ThemeService.tinta,
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(producto.nombre, style: theme.textTheme.displayLarge),
                  const SizedBox(height: 12),
                  Text(
                    producto.descripcion.isEmpty
                        ? 'Plato de la casa.'
                        : producto.descripcion,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: ThemeService.humo),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        precio,
                        style: const TextStyle(
                          fontFamily: ThemeService.texto,
                          fontWeight: FontWeight.w700,
                          fontSize: 38,
                          height: 1,
                          color: ThemeService.brasa,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('por plato', style: theme.textTheme.labelMedium),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Estas consultas devuelven el resultado al catálogo
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pop(context, 'consultar'),
                          child: const Text('Consultar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, 'reservar'),
                          child: const Text('Reservar mesa'),
                        ),
                      ),
                    ],
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
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
