import 'package:flutter_test/flutter_test.dart';
import 'package:digital_library/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that we are at least rendering the login screen or loading
    expect(find.byType(MyApp), findsOneWidget);
  });
}
