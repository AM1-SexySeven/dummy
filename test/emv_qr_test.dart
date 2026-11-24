import 'package:conecta_cruz/utils/emv_qr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CRC-16/CCITT-FALSE', () {
    test('el caso de prueba del estándar da 29B1', () {
      // '123456789' es la cadena de control que usa la especificación
      // para comprobar que una implementación de CRC-16 es correcta.
      expect(EmvQr.crc16('123456789'), '29B1');
    });

    test('cambiar un solo carácter cambia la suma', () {
      final a = EmvQr.crc16('000201');
      final b = EmvQr.crc16('000202');
      expect(a, isNot(b));
    });
  });

  group('Validación del QR', () {
    // QR armado igual que lo arma la función banco_generar_qr.
    String armar(String cuerpoSinCrc) =>
        cuerpoSinCrc + EmvQr.crc16(cuerpoSinCrc);

    // Los largos tienen que coincidir con el contenido, como los arma
    // emv_campo() en la base: identificador + largo + valor.
    const cuerpo = '000201'
        '010212'
        '2631' '0013bo.gob.bcb.qr' '01101151026105'
        '52045812'
        '5303068'
        '5406240.00'
        '5802BO'
        '5922CHURRASQUERIA EL FOGON'
        '6010SANTA CRUZ'
        '6236' '0532abc123def4567890abc123def456'
        '6304';

    test('acepta un QR bien formado', () {
      expect(EmvQr.esValido(armar(cuerpo)), isTrue);
    });

    test('rechaza un QR al que le cambiaron el monto', () {
      final bueno = armar(cuerpo);
      final adulterado = bueno.replaceFirst('5406240.00', '5406020.00');
      expect(EmvQr.esValido(adulterado), isFalse);
    });

    test('rechaza texto vacío o demasiado corto', () {
      expect(EmvQr.esValido(null), isFalse);
      expect(EmvQr.esValido(''), isFalse);
      expect(EmvQr.esValido('6304AB'), isFalse);
    });
  });

  group('Lectura de campos', () {
    const payload = '000201'
        '010212'
        '5303068'
        '5406240.00'
        '5802BO'
        '5922CHURRASQUERIA EL FOGON';

    test('lee el monto', () {
      expect(EmvQr.monto(payload), 240.00);
    });

    test('lee el nombre del comercio', () {
      expect(EmvQr.comercio(payload), 'CHURRASQUERIA EL FOGON');
    });

    test('devuelve null para un campo que no está', () {
      expect(EmvQr.campo(payload, '99'), isNull);
    });
  });
}
