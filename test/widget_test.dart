// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_estudio/main.dart';

void main() {
  testWidgets('Shows empty state and opens add dialog', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Horario de Estudio'), findsOneWidget);
    expect(find.text('No hay horarios aun.\nAgrega uno con el boton +'),
        findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo horario'), findsOneWidget);
    expect(find.text('Materia'), findsOneWidget);
    expect(find.text('Dia'), findsOneWidget);
  });
}
