import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nivio_desktop/shared/layout/desktop_sidebar.dart';

void main() {
  testWidgets('reveals labels when the icon rail is expanded', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: DesktopSidebar.expandedWidth,
            child: DesktopSidebar(isExpanded: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Live TV'), findsOneWidget);
    expect(find.text('Party'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

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

    expect(find.byKey(const ValueKey('desktop_sidebar_0')), findsOneWidget);
    expect(find.byKey(const ValueKey('desktop_sidebar_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('desktop_sidebar_2')), findsOneWidget);
    expect(find.text('Providers'), findsNothing);
    expect(find.byKey(const ValueKey('desktop_sidebar_3')), findsOneWidget);
    expect(find.byKey(const ValueKey('desktop_sidebar_4')), findsOneWidget);
    expect(find.byKey(const ValueKey('desktop_sidebar_5')), findsOneWidget);
    expect(find.text('Settings'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('desktop_sidebar_5')));
    expect(selectedIndex, 5);
  });

  testWidgets(
    'hovering collapsed icon does not overflow while labels animate',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: DesktopSidebar.preferredWidth,
              child: DesktopSidebar(isExpanded: false),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      await tester.pump();
      await gesture.moveTo(
        tester.getCenter(find.byKey(const ValueKey('desktop_sidebar_0'))),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
