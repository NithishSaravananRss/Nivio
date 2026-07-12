import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nivio_desktop/app/app.dart';

void main() {
  testWidgets('opens the search page and filters mock results', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NivioDesktopApp());

    final searchField = find.byType(TextField).first;
    await tester.enterText(searchField, 'signal');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Filters'), findsOneWidget);

    expect(find.text('Signal Lost'), findsOneWidget);
    expect(find.text('Halo Signal'), findsOneWidget);
    expect(find.text('Blackout City'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
  });
}
