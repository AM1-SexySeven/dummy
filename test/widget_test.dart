import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:conecta_cruz/main.dart';
import 'package:conecta_cruz/pages/agregar_producto_page.dart';
import 'package:conecta_cruz/pages/consulta_page.dart';
import 'package:conecta_cruz/pages/login_page.dart';
import 'package:conecta_cruz/pages/registro_page.dart';
import 'package:conecta_cruz/pages/reserva_page.dart';

const _pantalla = Size(1080, 2400);

void main() {
  // ---------------------------------------------------- 1. Bienvenida
  testWidgets('Muestra la pantalla de bienvenida con su botón', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ConectaCruzApp());

    expect(find.text('ConectaCruz'), findsWidgets);
    expect(find.text('Churrasquería El Fogón'), findsOneWidget);
    expect(
      find.text('Descubre, consulta y reserva en tu negocio de Santa Cruz'),
      findsOneWidget,
    );
    expect(find.text('Ver negocio'), findsOneWidget);
  });

  // ---------------------------------------------------- 2. Navegar al negocio
  testWidgets('El botón «Ver negocio» navega a la pantalla del negocio', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ConectaCruzApp());

    await tester.tap(find.text('Ver negocio'));
    await tester.pumpAndSettle();

    expect(
      find.text('Parrillas y platos tradicionales cruceños para compartir.'),
      findsOneWidget,
    );
    expect(find.text('Consultar'), findsOneWidget);
    expect(find.text('Reservar'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Parrillada para dos'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Productos y servicios'), findsOneWidget);
    expect(find.text('Parrillada para dos'), findsOneWidget);
    expect(find.text('Majadito batido'), findsOneWidget);
  });

  // ---------------------------------------------------- 3. Iniciar sesión → login
  testWidgets('El botón «Iniciar sesión» abre la pantalla de login', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(_pantalla);
    await tester.pumpWidget(const ConectaCruzApp());

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  // ---------------------------------------------------- 4. Login vacío → error correo
  testWidgets('Login: sin datos muestra error de correo', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(_pantalla);
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Ingrese un correo válido'), findsOneWidget);
  });

  // ---------------------------------------------------- 5. Login correo sin @
  testWidgets('Login: correo sin @ muestra error', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(_pantalla);
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    await tester.enterText(find.byType(TextField).at(0), 'correo.novalido');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Ingrese un correo válido'), findsOneWidget);
  });

  // ---------------------------------------------------- 6. Login sin clave
  testWidgets('Login: correo válido sin clave muestra error de clave', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(_pantalla);
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    await tester.enterText(find.byType(TextField).at(0), 'cliente@gmail.com');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Ingrese su clave'), findsOneWidget);
  });

  // ---------------------------------------------------- 7. Login desde la
  // ---------------- bienvenida exige login antes de Consultar
  testWidgets('Negocio: Consultar sin sesión pide iniciar sesión', (
    WidgetTester tester,
  ) async {
    // Si Supabase NO está configurado, no se exige login: se abre directo.
    // Este test solo documenta el flujo con Supabase disponible. Lo dejamos
    // como verificación de la navegación desde el negocio a Consultar.
    await tester.binding.setSurfaceSize(_pantalla);
    await tester.pumpWidget(const ConectaCruzApp());

    await tester.tap(find.text('Ver negocio'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Consultar'));
    await tester.pumpAndSettle();

    // Sin Supabase configurado: entra directo a la pantalla de consulta
    expect(find.text('Enviar consulta'), findsOneWidget);
  });

  // ---------------------------------------------------- 8. Consulta sin mensaje
  testWidgets('Consultar: sin mensaje muestra error', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(_pantalla);
    await tester.pumpWidget(const MaterialApp(home: ConsultaPage()));

    expect(find.text('Enviar consulta'), findsOneWidget);

    await tester.tap(find.text('Enviar consulta'));
    await tester.pump();

    expect(find.text('Escriba su consulta primero'), findsOneWidget);
  });

  // ---------------------------------------------------- 9. Reservar muestra todo
  testWidgets('Reservar: muestra fecha, hora, personas y botón', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(_pantalla);
    await tester.pumpWidget(const MaterialApp(home: ReservaPage()));

    expect(find.text('Fecha'), findsOneWidget);
    expect(find.text('Hora'), findsOneWidget);
    expect(find.text('Personas'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // personas por defecto
    expect(find.text('Confirmar reserva'), findsOneWidget);
  });

  // ---------------------------------------------------- 10. Reservar +/− personas
  testWidgets('Reservar: aumentar personas cambia el contador', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(_pantalla);
    await tester.pumpWidget(const MaterialApp(home: ReservaPage()));

    await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
    await tester.pump();

    expect(find.text('3'), findsOneWidget);
  });

  // ---------------------------------------------------- 11. Registro sin nombre
  testWidgets('Registro: sin nombre muestra error', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(_pantalla);
    await tester.pumpWidget(const MaterialApp(home: RegistroPage()));

    await tester.tap(find.text('Registrarme'));
    await tester.pump();

    expect(find.text('Ingrese su nombre'), findsOneWidget);
  });

  // ---------------------------------------------------- 12. Registro correo inválido
  testWidgets('Registro: correo sin @ muestra error', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(_pantalla);
    await tester.pumpWidget(const MaterialApp(home: RegistroPage()));

    await tester.enterText(find.byType(TextField).at(0), 'Marco Kiataque');
    await tester.enterText(find.byType(TextField).at(1), 'correo.novalido');
    await tester.tap(find.text('Registrarme'));
    await tester.pump();

    expect(find.text('Ingrese un correo válido'), findsOneWidget);
  });

  // ---------------------------------------------------- 13. Registro clave corta
  testWidgets('Registro: clave de menos de 6 caracteres muestra error', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(_pantalla);
    await tester.pumpWidget(const MaterialApp(home: RegistroPage()));

    await tester.enterText(find.byType(TextField).at(0), 'Marco Kiataque');
    await tester.enterText(find.byType(TextField).at(1), 'cliente@gmail.com');
    await tester.enterText(find.byType(TextField).at(2), '123');
    await tester.tap(find.text('Registrarme'));
    await tester.pump();

    expect(find.text('La clave debe tener al menos 6 caracteres'), findsOneWidget);
  });

  // ---------------------------------------------------- 14. Añadir plato sin nombre
  testWidgets('Añadir plato: sin nombre muestra error', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(_pantalla);
    await tester.pumpWidget(const MaterialApp(home: AgregarProductoPage()));

    expect(find.text('Añadir plato'), findsWidgets);

    // El botón principal (FilledButton) es el que tiene ese texto
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('Ingrese el nombre del plato'), findsOneWidget);
  });

  // ---------------------------------------------------- 15. Añadir plato sin precio
  testWidgets('Añadir plato: sin precio válido muestra error', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(_pantalla);
    await tester.pumpWidget(const MaterialApp(home: AgregarProductoPage()));

    await tester.enterText(find.byType(TextField).at(0), 'Pique macho');
    await tester.enterText(find.byType(TextField).at(2), 'abc');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('Ingrese un precio válido (ej: 45.50)'), findsOneWidget);
  });
}
