import 'package:flutter_test/flutter_test.dart';

import 'package:conecta_cruz/services/supabase_service.dart';

void main() {
  test('InfoNegocio.fromMap lee la fila de negocios (con los nuevos campos)',
      () {
    final info = InfoNegocio.fromMap({
      'id': 1,
      'nombre': 'Churrasquería El Fogón',
      'rubro': 'Gastronomía',
      'direccion': 'Av. Busch 1234',
      'telefono': '+591 7000 1111',
      'whatsapp': '+591 7000 2222',
      'descripcion': 'Parrillas cruceñas',
      'horario': 'Lun a Sab · 18:00',
      'foto_url': 'https://ejemplo.com/foto.jpg',
    });

    expect(info.id, 1);
    expect(info.nombre, 'Churrasquería El Fogón');
    expect(info.direccion, 'Av. Busch 1234');
    expect(info.telefono, '+591 7000 1111');
    expect(info.whatsapp, '+591 7000 2222');
    expect(info.numeroWa, '59170002222');
    expect(info.descripcion, 'Parrillas cruceñas');
    expect(info.horario, 'Lun a Sab · 18:00');
    expect(info.fotoUrl, 'https://ejemplo.com/foto.jpg');
  });

  test('InfoNegocio.fromMap tolera filas incompletas', () {
    final info = InfoNegocio.fromMap({'id': 1});

    expect(info.nombre, '');
    expect(info.telefono, '');
    expect(info.numeroWa, '');
    expect(info.fotoUrl, '');
  });

  test('InfoNegocio.numeroWa usa el teléfono si no hay WhatsApp', () {
    const info = InfoNegocio(
      id: 1,
      nombre: 'Test',
      rubro: 'Gastronomía',
      direccion: '',
      telefono: '+591 6775 6448',
      whatsapp: '',
      descripcion: '',
      horario: '',
      fotoUrl: '',
    );

    expect(info.numeroWa, '59167756448');
  });

  test('InfoNegocio.copyWith cambia solo lo pedido', () {
    const base = InfoNegocio.actual;
    final copia = base.copyWith(telefono: '+591 0000 0000');

    expect(copia.telefono, '+591 0000 0000');
    expect(copia.nombre, base.nombre);
    expect(copia.whatsapp, base.whatsapp);
    expect(copia.id, base.id);
  });

  test('InfoNegocio.actual (respaldo) trae los datos reales del negocio', () {
    expect(InfoNegocio.actual.nombre, 'Churrasquería El Fogón');
    expect(InfoNegocio.actual.whatsapp, '+591 6775 6448');
    expect(InfoNegocio.actual.numeroWa, '59167756448');
  });
}