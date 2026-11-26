import 'package:flutter/material.dart';

/// Forma del marco de la foto.
///
/// `lleno` ocupa todo el espacio que le dé el padre, sin recorte ni medida
/// fija: es lo que usa el catálogo, donde la foto es la fila entera.
enum FotoForma { circulo, cuadrado, lleno }

/// Foto del plato, leída desde Supabase Storage (URL pública).
///
/// Respaldo: si la URL falla o no carga, muestra la misma foto
/// empaquetada como asset local (assets/images/platos/), y en último
/// caso, el icono de fuego de siempre. Así la app nunca queda sin fotos.
class FotoPlato extends StatelessWidget {
  const FotoPlato({
    super.key,
    required this.fotoUrl,
    this.tamano = 56,
    this.forma = FotoForma.circulo,
  });

  final String fotoUrl;
  final double tamano;
  final FotoForma forma;

  bool get _lleno => forma == FotoForma.lleno;
  double? get _medida => _lleno ? null : tamano;

  /// Nombre de archivo de la URL (".../menu-fotos/parrillada.jpg" -> "parrillada.jpg").
  String get _archivo => Uri.tryParse(fotoUrl)?.pathSegments.lastOrNull ?? '';

  @override
  Widget build(BuildContext context) {
    return _enmarcar(_imagen(context));
  }

  Widget _imagen(BuildContext context) {
    if (fotoUrl.startsWith('assets/')) {
      return Image.asset(
        fotoUrl,
        width: _medida,
        height: _medida,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _respaldoAsset(context),
      );
    }

    if (fotoUrl.startsWith('http://') || fotoUrl.startsWith('https://')) {
      return Image.network(
        fotoUrl,
        width: _medida,
        height: _medida,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _respaldoAsset(context),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: _medida,
            height: _medida,
            child: Center(
              child: SizedBox(
                width: tamano * 0.4,
                height: tamano * 0.4,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }
    return _respaldoAsset(context);
  }

  /// Intenta la copia local de la foto; si no existe o falla, usa parrillada.jpg o el icono de fuego.
  Widget _respaldoAsset(BuildContext context) {
    final archivo = _archivo;
    final ruta = archivo.isNotEmpty
        ? 'assets/images/platos/$archivo'
        : 'assets/images/platos/parrillada.jpg';

    return Image.asset(
      ruta,
      width: _medida,
      height: _medida,
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, stack) {
        if (ruta != 'assets/images/platos/parrillada.jpg') {
          return Image.asset(
            'assets/images/platos/parrillada.jpg',
            width: _medida,
            height: _medida,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => _iconoFuego(context),
          );
        }
        return _iconoFuego(context);
      },
    );
  }

  Widget _enmarcar(Widget child) {
    if (_lleno) return child;
    if (forma == FotoForma.cuadrado) {
      return SizedBox(
        width: _medida,
        height: _medida,
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
          child: SizedBox(width: tamano, height: tamano, child: child),
        ),
      );
    }
    return ClipOval(child: child);
  }

  Widget _iconoFuego(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: _medida,
      height: _medida,
      decoration: BoxDecoration(
        color: const Color(0xFFEFE9E1),
        shape: _lleno || forma == FotoForma.cuadrado
            ? BoxShape.rectangle
            : BoxShape.circle,
      ),
      child: Icon(
        Icons.local_fire_department_rounded,
        color: theme.colorScheme.primary,
        size: _lleno ? 48 : tamano * 0.55,
      ),
    );
  }
}
