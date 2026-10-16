import 'package:flutter_test/flutter_test.dart';
import 'package:ganimedes/main.dart';

void main() {
  testWidgets('GanimedesApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GanimedesApp());
    await tester.pump();

    // Verify that GANIMEDES brand text renders on SplashScreen
    expect(find.text('GANIMEDES'), findsOneWidget);
  });
}
