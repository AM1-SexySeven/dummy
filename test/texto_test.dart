import 'package:conecta_cruz/utils/texto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Normalización', () {
    test('pasa a minúsculas', () {
      expect(Texto.normalizar('PARRILLADA'), 'parrillada');
    });

    test('quita las tildes', () {
      expect(Texto.normalizar('Artesanía'), 'artesania');
      expect(Texto.normalizar('Cuñapé'), 'cunape');
      expect(Texto.normalizar('Achachairú'), 'achachairu');
    });

    test('quita los espacios de los extremos', () {
      expect(Texto.normalizar('  pique macho  '), 'pique macho');
    });
  });

  group('Búsqueda sin tildes', () {
    test('encuentra con tilde lo escrito sin tilde', () {
      expect(Texto.contiene('Cerámica del Oriente', 'ceramica'), isTrue);
    });

    test('encuentra sin tilde lo escrito con tilde', () {
      expect(Texto.contiene('Ceramica del Oriente', 'cerámica'), isTrue);
    });

    test('no distingue mayúsculas', () {
      expect(Texto.contiene('Pique macho', 'PIQUE'), isTrue);
    });

    test('una búsqueda vacía encuentra todo', () {
      expect(Texto.contiene('lo que sea', ''), isTrue);
      expect(Texto.contiene('lo que sea', '   '), isTrue);
    });

    test('no encuentra lo que no está', () {
      expect(Texto.contiene('Parrillada para dos', 'sushi'), isFalse);
    });
  });

  group('Búsqueda por nombre o rubro', () {
    // El caso de prueba que pidió el docente: decir «artesanía» tiene
    // que traer los negocios de ese rubro, aunque no se llamen así.
    const negocios = [
      ['Churrasquería El Fogón', 'Gastronomía'],
      ['Cerámica del Oriente', 'Artesanía'],
      ['Telares Chiquitanos', 'Artesanía'],
      ['Ruta Misionera', 'Turismo'],
    ];

    List<String> buscar(String termino) => negocios
        .where((n) => Texto.contieneEnAlguno(n, termino))
        .map((n) => n[0])
        .toList();

    test('«artesania» trae los dos negocios de ese rubro', () {
      expect(buscar('artesania'), ['Cerámica del Oriente', 'Telares Chiquitanos']);
    });

    test('«artesanía» con tilde trae lo mismo', () {
      expect(buscar('artesanía'), ['Cerámica del Oriente', 'Telares Chiquitanos']);
    });

    test('«ceramica» trae solo ese negocio, por su nombre', () {
      expect(buscar('ceramica'), ['Cerámica del Oriente']);
    });

    test('«turismo» trae el de ese rubro', () {
      expect(buscar('turismo'), ['Ruta Misionera']);
    });

    test('una palabra que no está no trae nada', () {
      expect(buscar('ferreteria'), isEmpty);
    });
  });
}
