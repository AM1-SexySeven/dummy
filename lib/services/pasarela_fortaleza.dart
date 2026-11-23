import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'pasarela_qr.dart';

/// Pasarela del Banco Fortaleza.
///
/// ESTADO: escrita y lista, sin probar contra el banco.
///
/// El docente nos entregó número de cuenta, usuario y contraseña, pero
/// todavía no la documentación técnica de la API. Lo que falta para que
/// esta clase funcione son tres datos, y nada más:
///
///   1. La dirección base del servicio            → [urlBase]
///   2. Cómo se autentica la petición             → [_cabeceras]
///   3. Cómo se llaman los campos de la respuesta → [_leerRespuesta]
///
/// El resto —el flujo, los reintentos, los tiempos límite, el manejo de
/// errores y toda la pantalla de pago— ya está hecho y probado contra
/// [PasarelaSimulada], que cumple este mismo contrato.
///
/// Para activarla, en `qr_service.dart` cambiar una línea:
///
///   static const bool usarBancoReal = true;
///
/// Los cuatro pasos del consumo de la API son los mismos que usamos con
/// Open-Meteo en `clima_service.dart`: armar la dirección, hacer la
/// petición, verificar el código de estado y convertir el JSON en un
/// objeto de Dart.
class PasarelaFortaleza extends PasarelaQr {
  const PasarelaFortaleza({
    required this.urlBase,
    required this.usuario,
    required this.clave,
    required this.cuenta,
    this.clienteHttp,
  });

  /// Dirección base del servicio. Pendiente de confirmar con el banco.
  final String urlBase;

  /// Usuario y clave que entregó el banco. No se escriben acá: llegan
  /// desde fuera con --dart-define, igual que las de Supabase.
  final String usuario;
  final String clave;

  /// Cuenta donde cae el dinero: 1151-026105.
  final String cuenta;

  /// Cliente HTTP. Se puede inyectar uno falso en las pruebas.
  final http.Client? clienteHttp;

  static const Duration tiempoLimite = Duration(seconds: 8);
  static const int intentos = 2;

  @override
  String get nombre => 'Banco Fortaleza';

  @override
  Future<CobroResult> generarQr({
    required int pedidoId,
    required double monto,
  }) async {
    // Paso 1: armar la dirección y el cuerpo de la petición.
    final url = Uri.parse('$urlBase/qr/generar');
    final cuerpo = jsonEncode({
      // El identificador lo ponemos nosotros, no el banco. Es lo que
      // hace que reintentar no genere dos cobros por la misma compra.
      'referencia': 'PED-$pedidoId',
      'cuenta': cuenta,
      'monto': monto.toStringAsFixed(2),
      'moneda': 'BOB',
      'glosa': 'Pedido $pedidoId - Churrasqueria El Fogon',
      'vigencia_minutos': 10,
    });

    return _enviar(() => _http.post(url, headers: _cabeceras, body: cuerpo));
  }

  @override
  Future<CobroResult> consultarEstado(String cobroId) {
    final url = Uri.parse('$urlBase/qr/estado/$cobroId');
    return _enviar(() => _http.get(url, headers: _cabeceras));
  }

  http.Client get _http => clienteHttp ?? http.Client();

  /// Autenticación. Pendiente de confirmar: el banco puede pedir un
  /// token que se renueva, en lugar de usuario y clave en cada llamada.
  Map<String, String> get _cabeceras => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$usuario:$clave'))}',
      };

  /// Paso 2 y 3: hacer la petición, verificar el código de estado.
  Future<CobroResult> _enviar(Future<http.Response> Function() peticion) async {
    CobroError ultimoError = CobroError.sinConexion;
    String ultimoMensaje = 'Sin conexión a internet.';

    for (var intento = 1; intento <= intentos; intento++) {
      try {
        final resp = await peticion().timeout(tiempoLimite);

        if (resp.statusCode == 401 || resp.statusCode == 403) {
          return CobroResult.error(
            CobroError.servidor,
            'El banco rechazó las credenciales (código ${resp.statusCode}).',
          );
        }
        if (resp.statusCode != 200 && resp.statusCode != 201) {
          return CobroResult.error(
            CobroError.servidor,
            'El banco respondió con el código ${resp.statusCode}.',
          );
        }

        // Paso 4: convertir el JSON en un objeto de Dart.
        final decodificado = jsonDecode(resp.body);
        if (decodificado is! Map<String, dynamic>) {
          return CobroResult.error(
            CobroError.respuestaInvalida,
            'El cuerpo de la respuesta no es un objeto JSON.',
          );
        }
        final cobro = Cobro.fromJson(_leerRespuesta(decodificado));

        // Un código vencido se devuelve como error, igual que hace la
        // pasarela simulada. Las dos tienen que comportarse igual,
        // porque la pantalla de pago decide qué mostrar según esto.
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
      } catch (_) {
        ultimoError = CobroError.sinConexion;
        ultimoMensaje = 'Sin conexión a internet.';
      }
      if (intento < intentos) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
      }
    }
    return CobroResult.error(ultimoError, ultimoMensaje);
  }

  /// Traduce los nombres de campo del banco a los nuestros.
  ///
  /// PENDIENTE: ajustar cuando llegue la documentación. Los nombres de
  /// abajo son los más habituales en las pasarelas bolivianas, pero hay
  /// que confirmarlos. Este método es, literalmente, lo único que
  /// cambia si el banco usa otros nombres.
  Map<String, dynamic> _leerRespuesta(Map<String, dynamic> json) {
    return {
      'id': json['id'] ?? json['idQr'] ?? json['referencia'],
      'id_banco': json['codigoTransaccion'] ?? json['idBanco'],
      'monto': json['monto'] ?? json['importe'],
      'estado': _traducirEstado(json['estado'] as String?),
      'qr_payload': json['qr'] ?? json['imagenQr'] ?? json['payload'],
      'vence_en': json['fechaVencimiento'] ?? json['vence_en'],
      'pagado_en': json['fechaPago'] ?? json['pagado_en'],
    };
  }

  String _traducirEstado(String? estadoBanco) {
    switch (estadoBanco?.toUpperCase()) {
      case 'PAGADO':
      case 'COMPLETADO':
      case 'ACREDITADO':
        return 'pagado';
      case 'VENCIDO':
      case 'EXPIRADO':
        return 'vencido';
      case 'ANULADO':
      case 'CANCELADO':
        return 'anulado';
      default:
        return 'pendiente';
    }
  }
}
