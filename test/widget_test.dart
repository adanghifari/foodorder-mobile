import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('material app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('KedaiKlik'),
        ),
      ),
    );

    expect(find.text('KedaiKlik'), findsOneWidget);
  });
}
