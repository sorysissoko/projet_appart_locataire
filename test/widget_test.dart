import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';

void main() {
  testWidgets('MyApp se construit correctement', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.pumpAndSettle();

    expect(find.byType(MyApp), findsOneWidget);

  });
}