import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:conecta_cruz/main.dart';

void main() {
  testWidgets('Muestra la pantalla de bienvenida con su botón', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ConectaCruzApp());

    // Título de la app
    expect(find.text('ConectaCruz'), findsWidgets);

    // Nombre del negocio
    expect(find.text('Churrasquería El Fogón'), findsOneWidget);

    // Subtítulo
    expect(
      find.text('Descubre, consulta y reserva en tu negocio de Santa Cruz'),
      findsOneWidget,
    );

    // Botón «Ver negocio»
    expect(find.text('Ver negocio'), findsOneWidget);
  });

  testWidgets('El botón «Ver negocio» navega a la pantalla del negocio', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ConectaCruzApp());

    await tester.tap(find.text('Ver negocio'));
    await tester.pumpAndSettle();

    // Ya dentro de la página del negocio (lo visible sin desplazar)
    expect(
      find.text('Parrillas y platos tradicionales cruceños para compartir.'),
      findsOneWidget,
    );
    expect(find.text('Consultar'), findsOneWidget);
    expect(find.text('Reservar'), findsOneWidget);

    // Los productos aparecen al desplazar la lista
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
}
