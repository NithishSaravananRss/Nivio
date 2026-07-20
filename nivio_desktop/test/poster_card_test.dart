import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nivio_desktop/shared/widgets/cards/poster_card.dart';

void main() {
  testWidgets('expanded hover card exposes details action', (tester) async {
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 236,
              height: 420,
              child: PosterCard(
                title: 'Signal Lost',
                year: '2026',
                rating: '8.4',
                subtitle: 'Movie',
                overview: 'A hidden broadcast network.',
                onTap: () => opened = true,
              ),
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(PosterCard)));
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });
}
