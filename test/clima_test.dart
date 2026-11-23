import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:conecta_cruz/services/clima_service.dart';

/// Respuesta real de Open-Meteo (recortada) para Santa Cruz.
const _respuestaOk = '''
{
  "latitude": -17.8,
  "longitude": -63.2,
  "current": {
    "temperature_2m": 29.4,
    "weather_code": 1,
    "wind_speed_10m": 12.3
  }
}
''';

void main() {
  test('Clima.fromJson lee el objeto current de Open-Meteo', () {
    final clima = Clima.fromJson({
      'latitude': -17.8,
      'longitude': -63.2,
      'current': {
        'temperature_2m': 29.4,
        'weather_code': 1,
        'wind_speed_10m': 12.3,
      },
    });

    expect(clima.temperatura, 29.4);
    expect(clima.viento, 12.3);
    expect(clima.codigo, 1);
    expect(clima.descripcion, 'Parcialmente nublado');
  });

  test('Clima.fromJson lanza FormatException si falta current', () {
    expect(
      () => Clima.fromJson({'latitude': -17.8}),
      throwsA(isA<FormatException>()),
    );
  });

  test('Clima.fromJson lanza FormatException si falta temperature_2m', () {
    expect(
      () => Clima.fromJson({
        'current': {'weather_code': 1, 'wind_speed_10m': 12.0},
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('obtener devuelve el clima cuando la API responde 200', () async {
    final mock = MockClient((request) async => http.Response(_respuestaOk, 200));
    final resultado = await ClimaService.obtener(client: mock);

    expect(resultado.esError, isFalse);
    expect(resultado.clima?.temperatura, 29.4);
    expect(resultado.clima?.viento, 12.3);
  });

  test('obtener reintenta: falla una vez y la segunda responde', () async {
    var llamadas = 0;
    final mock = MockClient((request) async {
      llamadas++;
      if (llamadas == 1) {
        throw const SocketException('Sin red intermitente');
      }
      return http.Response(_respuestaOk, 200);
    });

    final resultado = await ClimaService.obtener(client: mock, intentos: 2);

    expect(llamadas, 2);
    expect(resultado.esError, isFalse);
    expect(resultado.clima?.temperatura, 29.4);
  });

  test('obtener sin conexión devuelve error con mensaje (no se cierra)',
      () async {
    final mock = MockClient((request) async {
      throw const SocketException('Sin red');
    });

    final resultado = await ClimaService.obtener(client: mock, intentos: 2);

    expect(resultado.esError, isTrue);
    expect(resultado.error, ClimaError.sinConexion);
    expect(resultado.mensaje, isNotEmpty);
  });

  test('obtener con HTTP 500 devuelve error de servidor', () async {
    final mock = MockClient((request) async => http.Response('oops', 500));
    final resultado = await ClimaService.obtener(client: mock);

    expect(resultado.esError, isTrue);
    expect(resultado.error, ClimaError.servidor);
  });

  test('obtener con JSON inválido devuelve error de datos', () async {
    final mock =
        MockClient((request) async => http.Response('esto no es json', 200));
    final resultado = await ClimaService.obtener(client: mock);

    expect(resultado.esError, isTrue);
    expect(resultado.error, ClimaError.datos);
  });
}
