import 'package:flutter/foundation.dart';

/// Contrato de una pasarela de cobro por QR.
///
/// La aplicación habla siempre con esta interfaz y nunca con un banco
/// concreto. Hoy detrás está [PasarelaSimulada]; el día que lleguen las
/// credenciales de Banco Fortaleza se pone [PasarelaFortaleza] en su
/// lugar y no hay que tocar ni la pantalla ni el carrito.
///
/// Las dos operaciones son las mismas que expone cualquier pasarela QR:
///   · pedir un QR para un monto
///   · preguntar si ese QR ya fue pagado
abstract class PasarelaQr {
  const PasarelaQr();

  /// Nombre que se muestra al pie de la pantalla de pago.
  String get nombre;

  /// Pide al banco un QR para [pedidoId] por [monto] bolivianos.
  ///
  /// Debe ser idempotente: llamarla dos veces con el mismo [pedidoId]
  /// tiene que devolver el mismo cobro, nunca cobrar dos veces.
  Future<CobroResult> generarQr({
    required int pedidoId,
    required double monto,
  });

  /// Pregunta al banco en qué estado está el cobro.
  Future<CobroResult> consultarEstado(String cobroId);
}

/// Estado de un cobro, tal como lo informa el banco.
enum EstadoCobro {
  pendiente,
  pagado,
  vencido,
  anulado;

  static EstadoCobro desdeTexto(String? valor) {
    switch (valor) {
      case 'pagado':
        return EstadoCobro.pagado;
      case 'vencido':
        return EstadoCobro.vencido;
      case 'anulado':
        return EstadoCobro.anulado;
      default:
        return EstadoCobro.pendiente;
    }
  }

  String get texto {
    switch (this) {
      case EstadoCobro.pendiente:
        return 'Esperando el pago';
      case EstadoCobro.pagado:
        return 'Pago recibido';
      case EstadoCobro.vencido:
        return 'El código venció';
      case EstadoCobro.anulado:
        return 'Cobro anulado';
    }
  }
}

/// Un cobro por QR.
@immutable
class Cobro {
  const Cobro({
    required this.id,
    required this.monto,
    required this.estado,
    this.qrPayload,
    this.idBanco,
    this.venceEn,
    this.pagadoEn,
    this.reutilizado = false,
  });

  /// Lee la respuesta del banco.
  ///
  /// Lanza [FormatException] si falta algo obligatorio, igual que hace
  /// [Clima.fromJson] con la respuesta del servicio de clima.
  factory Cobro.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Falta el identificador del cobro');
    }
    final monto = json['monto'];
    if (monto is! num && monto is! String) {
      throw const FormatException('Falta el monto del cobro');
    }
    return Cobro(
      id: id,
      monto: monto is num
          ? monto.toDouble()
          : double.parse(monto as String),
      estado: EstadoCobro.desdeTexto(json['estado'] as String?),
      qrPayload: json['qr_payload'] as String?,
      idBanco: json['id_banco'] as String?,
      venceEn: _fecha(json['vence_en']),
      pagadoEn: _fecha(json['pagado_en']),
      reutilizado: json['reutilizado'] == true,
    );
  }

  static DateTime? _fecha(Object? valor) {
    if (valor is! String || valor.isEmpty) return null;
    return DateTime.tryParse(valor)?.toLocal();
  }

  /// Identificador del cobro en nuestro sistema.
  final String id;

  /// Monto en bolivianos.
  final double monto;

  final EstadoCobro estado;

  /// Texto que se dibuja como código QR. Formato EMVCo.
  final String? qrPayload;

  /// Identificador que asignó el banco.
  final String? idBanco;

  final DateTime? venceEn;
  final DateTime? pagadoEn;

  /// true cuando el banco devolvió un cobro que ya existía, en lugar de
  /// crear uno nuevo. Es la señal de que la idempotencia funcionó.
  final bool reutilizado;

  bool get pagado => estado == EstadoCobro.pagado;

  /// Segundos que faltan para que el QR deje de servir.
  int get segundosRestantes {
    final v = venceEn;
    if (v == null) return 0;
    final faltan = v.difference(DateTime.now()).inSeconds;
    return faltan < 0 ? 0 : faltan;
  }
}

/// Qué puede salir mal al hablar con el banco.
enum CobroError {
  /// No hay internet, o el teléfono no deja salir.
  sinConexion,

  /// El banco tardó más de lo aceptable en contestar.
  tiempoAgotado,

  /// El banco contestó, pero con un error suyo.
  servidor,

  /// El QR ya venció y hay que pedir uno nuevo.
  vencido,

  /// El cobro ya estaba pagado.
  yaPagado,

  /// La respuesta llegó, pero no tiene la forma esperada.
  respuestaInvalida,
}

/// Resultado de una operación contra el banco: o salió bien y trae el
/// cobro, o salió mal y trae el motivo y un mensaje para la pantalla.
@immutable
class CobroResult {
  const CobroResult._({this.cobro, this.error, this.mensaje});

  factory CobroResult.ok(Cobro cobro) => CobroResult._(cobro: cobro);

  factory CobroResult.error(CobroError error, String mensaje) =>
      CobroResult._(error: error, mensaje: mensaje);

  final Cobro? cobro;
  final CobroError? error;
  final String? mensaje;

  bool get hayError => error != null;
}
