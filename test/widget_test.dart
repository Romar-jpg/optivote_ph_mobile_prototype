import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Ensure this matches your package name in pubspec.yaml
import 'package:optivote_ph/main.dart';

void main() {
  testWidgets('MainScreen smoke test: verifies AppBar and loading state', (
    WidgetTester tester,
  ) async {
    // 1. Build our app and trigger a frame.
    // We wrap MainScreen in a MaterialApp just like your main() function does.
    await tester.pumpWidget(const MaterialApp(home: MainScreen()));

    // 2. Verify that the AppBar title 'OptiVote PH' is displayed.
    expect(find.text('OptiVote PH'), findsOneWidget);

    // 3. Verify that the CircularProgressIndicator shows up initially
    // while the FutureBuilder is waiting for the CSV data to load.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Note: To test the actual loaded ListView, you would need to mock the
    // rootBundle to provide dummy CSV data during the test, as widget tests
    // do not load real assets by default. For a basic smoke test, checking
    // the UI frame and loading state is a great start!
  });
}
