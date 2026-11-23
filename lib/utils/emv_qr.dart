/// Lectura y verificación del código QR que devuelve el banco.
///
/// El QR interoperable boliviano sigue el formato EMVCo: una cadena de
/// campos «identificador + largo + valor», cerrada con una suma de
/// verificación CRC-16. La aplicación comprueba esa suma antes de
/// dibujar el código, para no mostrarle al cliente un QR corrupto que
/// su banca móvil va a rechazar.
class EmvQr {
  const EmvQr._();

  /// Calcula el CRC-16/CCITT-FALSE de [texto].
  ///
  /// Valor inicial 0xFFFF, polinomio 0x1021. Es el mismo algoritmo que
  /// usa la función `crc16_ccitt` del script 09 en la base de datos.
  static String crc16(String texto) {
    var crc = 0xFFFF;
    for (final byte in texto.codeUnits) {
      crc ^= (byte << 8) & 0xFFFF;
      for (var i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  /// true si el QR está completo y su suma de verificación coincide.
  ///
  /// El CRC ocupa siempre los últimos cuatro caracteres, precedidos por
  /// el encabezado «6304».
  static bool esValido(String? payload) {
    if (payload == null || payload.length < 8) return false;
    final corte = payload.length - 4;
    if (payload.substring(corte - 4, corte) != '6304') return false;
    final cuerpo = payload.substring(0, corte);
    final suma = payload.substring(corte).toUpperCase();
    return crc16(cuerpo) == suma;
  }

  /// Saca el valor de un campo del QR, por ejemplo el monto ('54').
  /// Devuelve null si ese campo no está.
  static String? campo(String payload, String id) {
    var i = 0;
    while (i + 4 <= payload.length) {
      final idActual = payload.substring(i, i + 2);
      final largo = int.tryParse(payload.substring(i + 2, i + 4));
      if (largo == null || i + 4 + largo > payload.length) return null;
      final valor = payload.substring(i + 4, i + 4 + largo);
      if (idActual == id) return valor;
      i += 4 + largo;
    }
    return null;
  }

  /// Monto que lleva escrito el QR, en bolivianos.
  static double? monto(String payload) {
    final valor = campo(payload, '54');
    return valor == null ? null : double.tryParse(valor);
  }

  /// Nombre del comercio que lleva escrito el QR.
  static String? comercio(String payload) => campo(payload, '59');
}
