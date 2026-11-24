import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'pasarela_qr.dart';

/// Banco simulado.
///
/// Habla por HTTPS contra tres funciones que viven en nuestro propio
/// Supabase (BD_SQL/09_cobros_qr.sql) y que responden igual que
/// respondería la API de un banco: devuelven el QR en formato EMVCo,
/// informan el estado del cobro y avisan cuando entra el pago.
///
/// No es una maqueta dentro de la aplicación: la petición sale del
/// teléfono, viaja por la red hasta São Paulo y vuelve. Lo único
/// fingido es quién paga.
///
/// Se usa mientras el banco real no nos entregue su documentación.
class PasarelaSimulada extends PasarelaQr {
  const PasarelaSimulada(this._db);

  final SupabaseClient _db;

  static const Duration tiempoLimite = Duration(seconds: 8);
  static const int intentos = 2;

  @override
  String get nombre => 'Banco simulado (pruebas)';

  @override
  Future<CobroResult> generarQr({
    required int pedidoId,
    required double monto,
  }) {
    return _llamar(
      () => _db.rpc('banco_generar_qr', params: {
        'p_pedido_id': pedidoId,
        'p_monto': monto,
      }),
      'No se pudo generar el código QR.',
    );
  }

  @override
  Future<CobroResult> consultarEstado(String cobroId) {
    return _llamar(
      () => _db.rpc('banco_consultar_pago', params: {'p_cobro_id': cobroId}),
      'No se pudo consultar el estado del pago.',
    );
  }

  /// Marca el cobro como pagado al instante.
  ///
  /// Solo existe para grabar la demostración sin esperar. Equivale al
  /// momento en que el banco avisa que recibió la transferencia; con el
  /// banco real este método no se usa.
  Future<CobroResult> simularPago(String cobroId) {
    return _llamar(
      () => _db.rpc('banco_simular_pago', params: {'p_cobro_id': cobroId}),
      'No se pudo registrar el pago de prueba.',
    );
  }

  /// Escucha los cambios del cobro en vivo, sin preguntar cada rato.
  ///
  /// Es el equivalente al aviso que manda el banco cuando entra el pago.
  Stream<EstadoCobro> escucharEstado(String cobroId) {
    return _db
        .from('cobros')
        .stream(primaryKey: ['id'])
        .eq('id', cobroId)
        .map((filas) {
          if (filas.isEmpty) return EstadoCobro.pendiente;
          return EstadoCobro.desdeTexto(filas.first['estado'] as String?);
        });
  }

  /// Envuelve la llamada con tiempo límite, reintento y traducción de
  /// errores. Mismo esquema que `ClimaService.obtener`.
  Future<CobroResult> _llamar(
    Future<dynamic> Function() peticion,
    String mensajeGenerico,
  ) async {
    CobroError ultimoError = CobroError.sinConexion;
    String ultimoMensaje = mensajeGenerico;

    for (var intento = 1; intento <= intentos; intento++) {
      try {
        final respuesta = await peticion().timeout(tiempoLimite);
        if (respuesta is! Map) {
          return CobroResult.error(
            CobroError.respuestaInvalida,
            'El banco respondió algo que no entendemos.',
          );
        }
        final cobro = Cobro.fromJson(Map<String, dynamic>.from(respuesta));
        if (cobro.estado == EstadoCobro.vencido) {
          return CobroResult.error(
            CobroError.vencido,
            'El código QR venció. Generá uno nuevo.',
          );
        }
        return CobroResult.ok(cobro);
      } on TimeoutException {
        ultimoError = CobroError.tiempoAgotado;
        ultimoMensaje = 'El banco está tardando en responder.';
      } on FormatException catch (e) {
        return CobroResult.error(
          CobroError.respuestaInvalida,
          'Respuesta del banco incompleta: ${e.message}',
        );
      } on PostgrestException catch (e) {
        // El banco contestó, pero rechazó la operación.
        final texto = e.message;
        if (texto.contains('ya estaba pagado') || texto.contains('pagado')) {
          return CobroResult.error(
            CobroError.yaPagado,
            'Este pedido ya figura como pagado.',
          );
        }
        return CobroResult.error(CobroError.servidor, texto);
      } catch (_) {
        // Sin red, DNS caído o permiso denegado.
        ultimoError = CobroError.sinConexion;
        ultimoMensaje = 'Sin conexión a internet.';
      }
      if (intento < intentos) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
      }
    }
    return CobroResult.error(ultimoError, ultimoMensaje);
  }
}
