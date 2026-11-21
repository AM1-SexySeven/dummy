import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Clima en tiempo real de Santa Cruz de la Sierra.
/// Fuente: Open-Meteo (gratis, sin API key) — petición GET en JSON.
/// Documentación: https://open-meteo.com/en/docs
class Clima {
  const Clima({
    required this.temperatura,
    required this.viento,
    required this.codigo,
  });

  /// Lee el JSON de Open-Meteo (objeto `current`). Lanza [FormatException]
  /// si falta algún campo obligatorio o el cuerpo no tiene la forma esperada.
  factory Clima.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    if (current is! Map) {
      throw const FormatException('Falta el objeto "current" en la respuesta');
    }
    final temperatura = current['temperature_2m'];
    final viento = current['wind_speed_10m'];
    final codigo = current['weather_code'];
    if (temperatura is! num || viento is! num || codigo is! num) {
      throw const FormatException(
        'Faltan temperature_2m / wind_speed_10m / weather_code en "current"',
      );
    }
    return Clima(
      temperatura: temperatura.toDouble(),
      viento: viento.toDouble(),
      codigo: codigo.toInt(),
    );
  }

  /// Temperatura en °C (entero, redondeada).
  final double temperatura;

  /// Viento en km/h.
  final double viento;

  /// Código WMO del estado del cielo.
  final int codigo;

  String get descripcion {
    switch (codigo) {
      case 0:
        return 'Despejado';
      case 1:
      case 2:
        return 'Parcialmente nublado';
      case 3:
        return 'Nublado';
      case 45:
      case 48:
        return 'Niebla';
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return 'Llovizna';
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return 'Lluvia';
      case 95:
      case 96:
      case 99:
        return 'Tormenta eléctrica';
      default:
        return 'Clima variable';
    }
  }
}

/// Tipo de error al pedir el clima (la app decide qué mostrar).
enum ClimaError {
  /// No hay red (wifi/datos apagados, host inalcanzable).
  sinConexion,

  /// La petición superó el tiempo límite (8 s).
  tiempoAgotado,

  /// Open-Meteo respondió con un código distinto de 200.
  servidor,

  /// La respuesta no era un JSON válido / le faltaban campos.
  datos,
}

/// Resultado de la petición: o hay clima, o hay un error con mensaje claro.
class ClimaResult {
  const ClimaResult.ok(this.clima)
      : error = null,
        mensaje = null;

  const ClimaResult.error(this.error, this.mensaje) : clima = null;

  final Clima? clima;
  final ClimaError? error;
  final String? mensaje;

  bool get esError => clima == null;
}

class ClimaService {
  ClimaService._();

  /// Centro de Santa Cruz de la Sierra. URL pública, sin API key.
  static const url =
      'https://api.open-meteo.com/v1/forecast?latitude=-17.7833&longitude=-63.1821'
      '&current=temperature_2m,weather_code,wind_speed_10m';

  /// Tiempo límite por intento (la app no se queda colgada esperando).
  static const tiempoLimite = Duration(seconds: 8);

  /// Espera entre reintentos.
  static const esperaReintento = Duration(milliseconds: 800);

  /// Lee el clima actual con reintento automático (hasta [intentos] intentos).
  /// Nunca lanza: devuelve [ClimaResult.ok] o [ClimaResult.error] con un
  /// mensaje claro para mostrar al usuario.
  static Future<ClimaResult> obtener({
    http.Client? client,
    int intentos = 2,
  }) async {
    final propio = client == null;
    final c = client ?? http.Client();
    try {
      ClimaError? ultimoError;
      for (var intento = 1; intento <= intentos; intento++) {
        try {
          final resp = await c.get(Uri.parse(url)).timeout(tiempoLimite);
          if (resp.statusCode != 200) {
            return ClimaResult.error(
              ClimaError.servidor,
              'El servicio del clima respondió (código ${resp.statusCode}). '
              'Inténtalo de nuevo.',
            );
          }
          final decodificado = jsonDecode(resp.body);
          if (decodificado is! Map<String, dynamic>) {
            throw const FormatException('El cuerpo no es un objeto JSON');
          }
          return ClimaResult.ok(Clima.fromJson(decodificado));
        } on TimeoutException {
          ultimoError = ClimaError.tiempoAgotado;
        } on FormatException {
          // El JSON viene roto: reintentar no ayuda, se avisa de inmediato.
          return const ClimaResult.error(
            ClimaError.datos,
            'No se pudo leer la respuesta del clima (JSON inesperado).',
          );
        } catch (_) {
          // SocketException / ClientException / HandshakeException...
          ultimoError = ClimaError.sinConexion;
        }
        if (intento < intentos) {
          await Future<void>.delayed(esperaReintento);
        }
      }
      switch (ultimoError) {
        case ClimaError.tiempoAgotado:
          return const ClimaResult.error(
            ClimaError.tiempoAgotado,
            'El servicio del clima tardó demasiado (8 s). '
            'Revisa la conexión e inténtalo de nuevo.',
          );
        default:
          return const ClimaResult.error(
            ClimaError.sinConexion,
            'Sin conexión a internet. Activa los datos o el wifi '
            'e inténtalo de nuevo.',
          );
      }
    } finally {
      if (propio) c.close();
    }
  }
}
