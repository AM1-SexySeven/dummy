import 'dart:convert';

import 'package:conecta_cruz/services/pasarela_fortaleza.dart';
import 'package:conecta_cruz/services/pasarela_qr.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Respuesta de ejemplo del banco, con los nombres de campo que
/// esperamos encontrar en su documentación.
String _respuestaBanco({
  String estado = 'PENDIENTE',
  String monto = '240.00',
}) =>
    jsonEncode({
      'id': 'c0b1-2233-4455',
      'codigoTransaccion': 'FOR-20261122-000123',
      'importe': monto,
      'estado': estado,
      'qr': '00020101021253030685406240.006304ABCD',
      'fechaVencimiento':
          DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
    });

PasarelaFortaleza _conRespuesta(
  Future<http.Response> Function(http.Request) responder,
) =>
    PasarelaFortaleza(
      urlBase: 'https://banco.ejemplo.test/api',
      usuario: 'usuario_de_prueba',
      clave: 'clave_de_prueba',
      cuenta: '1151026105',
      clienteHttp: MockClient(responder),
    );

void main() {
  group('Modelo del cobro', () {
    test('lee la respuesta del banco', () {
      final cobro = Cobro.fromJson({
        'id': 'abc-123',
        'monto': 240.0,
        'estado': 'pendiente',
        'qr_payload': '0002016304ABCD',
        'id_banco': 'SIM-001',
        'vence_en':
            DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
      });

      expect(cobro.id, 'abc-123');
      expect(cobro.monto, 240.0);
      expect(cobro.estado, EstadoCobro.pendiente);
      expect(cobro.pagado, isFalse);
      expect(cobro.segundosRestantes, greaterThan(500));
    });

    test('acepta el monto como texto, que es como lo manda Postgres', () {
      final cobro = Cobro.fromJson({
        'id': 'abc-123',
        'monto': '18.50',
        'estado': 'pagado',
      });
      expect(cobro.monto, 18.50);
      expect(cobro.pagado, isTrue);
    });

    test('lanza FormatException si falta el identificador', () {
      expect(
        () => Cobro.fromJson({'monto': 10}),
        throwsA(isA<FormatException>()),
      );
    });

    test('lanza FormatException si falta el monto', () {
      expect(
        () => Cobro.fromJson({'id': 'abc'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('un cobro vencido no deja segundos restantes', () {
      final cobro = Cobro.fromJson({
        'id': 'abc',
        'monto': 10,
        'estado': 'vencido',
        'vence_en':
            DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String(),
      });
      expect(cobro.segundosRestantes, 0);
      expect(cobro.estado, EstadoCobro.vencido);
    });

    test('un estado desconocido se trata como pendiente', () {
      expect(EstadoCobro.desdeTexto('cualquier_cosa'), EstadoCobro.pendiente);
      expect(EstadoCobro.desdeTexto(null), EstadoCobro.pendiente);
    });
  });

  group('Banco Fortaleza · petición', () {
    test('pide el QR con POST y manda la referencia del pedido', () async {
      late http.Request recibida;
      final pasarela = _conRespuesta((req) async {
        recibida = req;
        return http.Response(_respuestaBanco(), 200);
      });

      final res = await pasarela.generarQr(pedidoId: 77, monto: 240.0);

      expect(res.hayError, isFalse);
      expect(recibida.method, 'POST');
      expect(recibida.url.path, endsWith('/qr/generar'));

      final cuerpo = jsonDecode(recibida.body) as Map<String, dynamic>;
      // El identificador lo pone la app, no el banco: eso es lo que
      // evita cobrar dos veces el mismo pedido.
      expect(cuerpo['referencia'], 'PED-77');
      expect(cuerpo['monto'], '240.00');
      expect(cuerpo['moneda'], 'BOB');
      expect(cuerpo['cuenta'], '1151026105');
    });

    test('manda la autenticación en la cabecera', () async {
      late http.Request recibida;
      final pasarela = _conRespuesta((req) async {
        recibida = req;
        return http.Response(_respuestaBanco(), 200);
      });

      await pasarela.generarQr(pedidoId: 1, monto: 1.0);

      final esperado =
          'Basic ${base64Encode(utf8.encode('usuario_de_prueba:clave_de_prueba'))}';
      expect(recibida.headers['Authorization'], esperado);
    });

    test('consulta el estado con GET', () async {
      late http.Request recibida;
      final pasarela = _conRespuesta((req) async {
        recibida = req;
        return http.Response(_respuestaBanco(estado: 'PAGADO'), 200);
      });

      final res = await pasarela.consultarEstado('c0b1-2233-4455');

      expect(recibida.method, 'GET');
      expect(recibida.url.path, contains('/qr/estado/c0b1-2233-4455'));
      expect(res.cobro!.pagado, isTrue);
    });
  });

  group('Banco Fortaleza · traducción de la respuesta', () {
    test('entiende los nombres de campo del banco', () async {
      final pasarela =
          _conRespuesta((_) async => http.Response(_respuestaBanco(), 200));

      final cobro = (await pasarela.generarQr(pedidoId: 1, monto: 240.0)).cobro!;

      expect(cobro.id, 'c0b1-2233-4455');
      expect(cobro.idBanco, 'FOR-20261122-000123');
      expect(cobro.monto, 240.00);
      expect(cobro.estado, EstadoCobro.pendiente);
    });

    test('traduce los estados que usa el banco a los nuestros', () async {
      for (final caso in {
        'PAGADO': EstadoCobro.pagado,
        'ACREDITADO': EstadoCobro.pagado,
        'COMPLETADO': EstadoCobro.pagado,
        'ANULADO': EstadoCobro.anulado,
        'CUALQUIERA': EstadoCobro.pendiente,
      }.entries) {
        final pasarela = _conRespuesta(
          (_) async => http.Response(_respuestaBanco(estado: caso.key), 200),
        );
        final res = await pasarela.consultarEstado('x');
        expect(res.cobro!.estado, caso.value, reason: caso.key);
      }
    });

    test('un QR vencido se devuelve como error, no como cobro', () async {
      final pasarela = _conRespuesta(
        (_) async => http.Response(_respuestaBanco(estado: 'VENCIDO'), 200),
      );
      final res = await pasarela.consultarEstado('x');
      expect(res.hayError, isTrue);
      expect(res.error, CobroError.vencido);
    });
  });

  group('Banco Fortaleza · cuando algo falla', () {
    test('credenciales rechazadas: error de servidor con el código', () async {
      final pasarela =
          _conRespuesta((_) async => http.Response('no autorizado', 401));
      final res = await pasarela.generarQr(pedidoId: 1, monto: 1.0);

      expect(res.error, CobroError.servidor);
      expect(res.mensaje, contains('401'));
    });

    test('error 500 del banco: no se rompe, informa', () async {
      final pasarela =
          _conRespuesta((_) async => http.Response('falla interna', 500));
      final res = await pasarela.generarQr(pedidoId: 1, monto: 1.0);

      expect(res.error, CobroError.servidor);
      expect(res.mensaje, contains('500'));
    });

    test('respuesta que no es JSON: error de datos', () async {
      final pasarela =
          _conRespuesta((_) async => http.Response('esto no es json', 200));
      final res = await pasarela.generarQr(pedidoId: 1, monto: 1.0);

      expect(res.error, CobroError.respuestaInvalida);
    });

    test('sin conexión: reintenta y después avisa', () async {
      var llamadas = 0;
      final pasarela = _conRespuesta((_) async {
        llamadas++;
        throw const SocketExceptionFalsa();
      });

      final res = await pasarela.generarQr(pedidoId: 1, monto: 1.0);

      expect(llamadas, 2, reason: 'tiene que reintentar una vez');
      expect(res.error, CobroError.sinConexion);
      expect(res.mensaje, 'Sin conexión a internet.');
    });

    test('falla una vez y a la segunda responde', () async {
      var llamadas = 0;
      final pasarela = _conRespuesta((_) async {
        llamadas++;
        if (llamadas == 1) throw const SocketExceptionFalsa();
        return http.Response(_respuestaBanco(), 200);
      });

      final res = await pasarela.generarQr(pedidoId: 1, monto: 1.0);

      expect(llamadas, 2);
      expect(res.hayError, isFalse);
      expect(res.cobro!.id, 'c0b1-2233-4455');
    });
  });
}

/// Falla de red, para no depender de dart:io en las pruebas.
class SocketExceptionFalsa implements Exception {
  const SocketExceptionFalsa();
}
