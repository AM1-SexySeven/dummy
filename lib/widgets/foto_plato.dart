import 'package:flutter/material.dart';

/// Forma del marco de la foto.
enum FotoForma { circulo, cuadrado }

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

  /// Nombre de archivo de la URL (".../menu-fotos/parrillada.jpg" -> "parrillada.jpg").
  String get _archivo => Uri.tryParse(fotoUrl)?.pathSegments.lastOrNull ?? '';

  @override
  Widget build(BuildContext context) {
    return _enmarcar(_imagen(context));
  }

  Widget _imagen(BuildContext context) {
    if (fotoUrl.isNotEmpty) {
      return Image.network(
        fotoUrl,
        width: tamano,
        height: tamano,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _respaldoAsset(context),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: tamano,
            height: tamano,
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

  /// Intenta la copia local de la foto; si no existe, el icono de fuego.
  Widget _respaldoAsset(BuildContext context) {
    final archivo = _archivo;
    if (archivo.isEmpty) return _iconoFuego(context);
    return Image.asset(
      'assets/images/platos/$archivo',
      width: tamano,
      height: tamano,
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, stack) => _iconoFuego(context),
    );
  }

  Widget _enmarcar(Widget child) {
    if (forma == FotoForma.cuadrado) {
      return SizedBox(
        width: tamano,
        height: tamano,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(width: tamano, height: tamano, child: child),
        ),
      );
    }
    return ClipOval(child: child);
  }

  Widget _iconoFuego(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: tamano,
      height: tamano,
      decoration: const BoxDecoration(
        color: Color(0xFFF9F2E0),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.local_fire_department_rounded,
        color: theme.colorScheme.primary,
        size: tamano * 0.55,
      ),
    );
  }
}
