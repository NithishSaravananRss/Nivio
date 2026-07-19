import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nivio_desktop/shared/layout/desktop_sidebar.dart';

void main() {
  testWidgets('keeps Profile as the only bottom account destination', (
    tester,
  ) async {
    int? selectedIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            child: DesktopSidebar(
              onDestinationSelected: (index) => selectedIndex = index,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Providers'), findsNothing);
    expect(find.text('Live TV'), findsOneWidget);
    expect(find.text('Party'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);

    await tester.tap(find.text('Profile'));
    expect(selectedIndex, 5);
  });
}
