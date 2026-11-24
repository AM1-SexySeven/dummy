import 'package:supabase_flutter/supabase_flutter.dart';

import 'pasarela_fortaleza.dart';
import 'pasarela_qr.dart';
import 'pasarela_simulada.dart';

export 'pasarela_qr.dart';

/// Punto único donde se elige con qué banco se cobra.
///
/// Toda la aplicación pide el QR por acá. Cambiar de banco es cambiar
/// [usarBancoReal] a true y pasar las credenciales al compilar; ninguna
/// pantalla se entera.
class QrService {
  QrService._();

  /// Interruptor. En false se cobra contra el banco simulado.
  ///
  /// Se puede cambiar sin tocar el código:
  ///   flutter run --dart-define=USAR_BANCO_REAL=true
  static const bool usarBancoReal =
      bool.fromEnvironment('USAR_BANCO_REAL', defaultValue: false);

  /// Credenciales del Banco Fortaleza. Nunca se escriben en el código:
  /// llegan al compilar, igual que las de Supabase.
  ///
  ///   flutter run \
  ///     --dart-define=USAR_BANCO_REAL=true \
  ///     --dart-define=FORTALEZA_URL=https://... \
  ///     --dart-define=FORTALEZA_USUARIO=... \
  ///     --dart-define=FORTALEZA_CLAVE=...
  static const String _urlBase =
      String.fromEnvironment('FORTALEZA_URL', defaultValue: '');
  static const String _usuario =
      String.fromEnvironment('FORTALEZA_USUARIO', defaultValue: '');
  static const String _clave =
      String.fromEnvironment('FORTALEZA_CLAVE', defaultValue: '');

  /// Cuenta del comercio donde cae el dinero.
  static const String cuenta = '1151-026105';

  static PasarelaQr? _pasarela;

  /// La pasarela que está en uso ahora mismo.
  static PasarelaQr get pasarela {
    _pasarela ??= usarBancoReal
        ? PasarelaFortaleza(
            urlBase: _urlBase,
            usuario: _usuario,
            clave: _clave,
            cuenta: cuenta.replaceAll('-', ''),
          )
        : PasarelaSimulada(Supabase.instance.client);
    return _pasarela!;
  }

  /// Permite inyectar una pasarela falsa en las pruebas.
  static set pasarelaDePrueba(PasarelaQr? p) => _pasarela = p;

  static Future<CobroResult> generarQr({
    required int pedidoId,
    required double monto,
  }) =>
      pasarela.generarQr(pedidoId: pedidoId, monto: monto);

  static Future<CobroResult> consultarEstado(String cobroId) =>
      pasarela.consultarEstado(cobroId);
}
