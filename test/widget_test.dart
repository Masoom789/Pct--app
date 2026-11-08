// Smoke test: without a Firebase config the app must open the
// Firebase setup screen instead of crashing.
import 'package:flutter_test/flutter_test.dart';
import 'package:pct_app/main.dart';

void main() {
  testWidgets('App opens the Firebase setup screen without config',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PctApp(firebaseReady: false));
    expect(find.text('Firebase is not connected yet'), findsOneWidget);
  });
}
