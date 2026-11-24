import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/carrito_service.dart';
import '../services/supabase_service.dart';
import '../services/theme_service.dart';

/// Comprobante de la compra, después de que el banco confirma el pago.
///
/// Recibe una copia de los ítems porque el carrito se vacía en cuanto el
/// pago entra: si leyera el carrito, el comprobante saldría en blanco.
///
/// No se llama «factura» a propósito. Una factura en Bolivia la emite el
/// sistema de Impuestos Nacionales con NIT y número de autorización; esto
/// es el comprobante de que el pago se hizo, que es lo que la app puede
/// respaldar de verdad.
class ComprobantePage extends StatefulWidget {
  const ComprobantePage({
    super.key,
    required this.pedidoId,
    required this.items,
    required this.total,
    required this.telefono,
    required this.fecha,
  });

  final int pedidoId;
  final List<ItemCarrito> items;
  final double total;
  final String telefono;
  final DateTime fecha;

  @override
  State<ComprobantePage> createState() => _ComprobantePageState();
}

class _ComprobantePageState extends State<ComprobantePage> {
  /// Envuelve el recuadro del comprobante: es lo que se convierte en
  /// imagen al descargar. Solo eso, sin los botones ni el encabezado.
  final _recuadro = GlobalKey();
  bool _descargando = false;

  int get pedidoId => widget.pedidoId;
  List<ItemCarrito> get items => widget.items;
  double get total => widget.total;
  String get telefono => widget.telefono;
  DateTime get fecha => widget.fecha;

  static String _bs(double v) => 'Bs ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  String get _numero => pedidoId.toString().padLeft(6, '0');

  String get _fechaTexto {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}'
        '  ${dos(fecha.hour)}:${dos(fecha.minute)}';
  }

  /// Versión en texto plano, para mandar por WhatsApp o guardar.
  String _comoTexto(InfoNegocio? negocio) {
    final b = StringBuffer()
      ..writeln('COMPROBANTE DE PAGO N.º $_numero')
      ..writeln(negocio?.nombre ?? 'ConectaCruz')
      ..writeln(_fechaTexto)
      ..writeln('')
      ..writeln('Cliente: ${_nombreCliente()}')
      ..writeln('Teléfono: $telefono')
      ..writeln('');
    for (final i in items) {
      b.writeln('${i.cantidad}x ${i.nombre}  ${_bs(i.subtotal)}');
    }
    b
      ..writeln('')
      ..writeln('TOTAL PAGADO: ${_bs(total)}')
      ..writeln('Pagado con QR interoperable')
      ..writeln('')
      ..writeln('Este comprobante no es una factura fiscal.');
    return b.toString();
  }

  String _nombreCliente() {
    final u = SupabaseService.usuario;
    final n = (u?.userMetadata?['nombre'] as String?)?.trim();
    if (n != null && n.isNotEmpty) return n;
    return u?.email ?? 'Cliente';
  }

  /// Convierte el recuadro del comprobante en PNG, lo guarda en la
  /// carpeta de la app y abre el menú de compartir con el archivo ya
  /// adjunto, para que el cliente lo mande o lo guarde donde quiera.
  Future<void> _descargar() async {
    if (_descargando) return;
    setState(() => _descargando = true);
    try {
      final objeto = _recuadro.currentContext?.findRenderObject();
      if (objeto is! RenderRepaintBoundary) {
        throw StateError('El comprobante todavía no está dibujado');
      }
      // x3 para que el texto se lea bien al ampliarlo o imprimirlo.
      final ui.Image imagen = await objeto.toImage(pixelRatio: 3);
      final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
      imagen.dispose();
      if (datos == null) throw StateError('No se pudo generar la imagen');

      // En Android esta carpeta se ve desde el explorador de archivos;
      // si el sistema no la da, se usa la carpeta interna de la app.
      final carpetaBase =
          await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final carpeta = Directory('${carpetaBase.path}/Comprobantes');
      if (!await carpeta.exists()) await carpeta.create(recursive: true);

      final ruta = '${carpeta.path}/comprobante_$_numero.png';
      await File(ruta).writeAsBytes(datos.buffer.asUint8List(), flush: true);
      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(ruta, mimeType: 'image/png')],
          text: 'Comprobante de pago N.º $_numero',
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Guardado como comprobante_$_numero.png')),
      );
    } catch (e) {
      debugPrint('Error al descargar el comprobante: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar el comprobante. Intentá de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _descargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<InfoNegocio>(
      future: SupabaseService.cargarNegocio(),
      builder: (context, snap) {
        final negocio = snap.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Comprobante'),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              // Confirmación, arriba de todo: es lo que el cliente busca.
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: ThemeService.monte, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Pago confirmado',
                        style: theme.textTheme.headlineMedium),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'El negocio ya recibió tu pedido y el pago. '
                'Te avisará por WhatsApp cuando esté listo.',
                style: TextStyle(color: theme.colorScheme.outline),
              ),

              const SizedBox(height: 26),
              // El comprobante propiamente dicho, enmarcado como un ticket.
              // El RepaintBoundary es lo que se captura al descargar.
              RepaintBoundary(
                key: _recuadro,
                child: Container(
                padding: const EdgeInsets.all(18),
                color: Theme.of(context).scaffoldBackgroundColor,
                foregroundDecoration: BoxDecoration(
                  border: Border.all(color: ThemeService.linea, width: 1.4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('COMPROBANTE N.º $_numero',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(letterSpacing: 0.7)),
                    const SizedBox(height: 2),
                    Text(negocio?.nombre ?? 'ConectaCruz',
                        style: theme.textTheme.titleLarge),
                    if (negocio != null && negocio.direccion.isNotEmpty)
                      Text(negocio.direccion,
                          style: TextStyle(
                              fontSize: 12.5,
                              color: theme.colorScheme.outline)),
                    Text(_fechaTexto,
                        style: TextStyle(
                            fontSize: 12.5, color: theme.colorScheme.outline)),

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: ThemeService.linea),
                    const SizedBox(height: 14),

                    _Dato(etiqueta: 'Cliente', valor: _nombreCliente()),
                    _Dato(etiqueta: 'Teléfono', valor: telefono),
                    _Dato(etiqueta: 'Pedido', valor: 'N.º $pedidoId'),
                    _Dato(etiqueta: 'Forma de pago', valor: 'QR interoperable'),

                    const SizedBox(height: 14),
                    const Divider(height: 1, color: ThemeService.linea),
                    const SizedBox(height: 10),

                    for (final i in items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text(
                                '${i.cantidad}×',
                                style: const TextStyle(
                                  fontFamily: ThemeService.texto,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                            Expanded(child: Text(i.nombre)),
                            const SizedBox(width: 8),
                            Text(
                              _bs(i.subtotal),
                              style: const TextStyle(
                                fontFamily: ThemeService.texto,
                                fontWeight: FontWeight.w600,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: ThemeService.linea),
                    const SizedBox(height: 12),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('TOTAL PAGADO',
                            style: theme.textTheme.labelMedium),
                        const Spacer(),
                        Text(
                          _bs(total),
                          style: const TextStyle(
                            fontFamily: ThemeService.texto,
                            fontWeight: FontWeight.w700,
                            fontSize: 28,
                            height: 1,
                            color: ThemeService.brasa,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ),
              ),

              const SizedBox(height: 12),
              Text(
                'Este comprobante no es una factura fiscal. Si necesitás '
                'factura, pedila en el local al retirar.',
                style:
                    TextStyle(fontSize: 12, color: theme.colorScheme.outline),
              ),

              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: _descargando ? null : _descargar,
                icon: _descargando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('Descargar comprobante'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => SharePlus.instance
                    .share(ShareParams(text: _comoTexto(negocio))),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Enviar como texto'),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('Listo'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Etiqueta y valor en una fila, para la cabecera del comprobante.
class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              child: Text(etiqueta,
                  style: TextStyle(color: Theme.of(context).colorScheme.outline)),
            ),
            Expanded(
              child: Text(valor,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}
