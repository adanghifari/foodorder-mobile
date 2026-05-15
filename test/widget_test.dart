import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/app/app.dart';

void main() {
  testWidgets('app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KedaiKlikApp());

    expect(find.text('Menu Terbaik'), findsOneWidget);
  });
}
