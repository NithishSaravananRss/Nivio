import 'dart:io' show Platform;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nivio_desktop/shared/widgets/layout/media_rail.dart';
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
    expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
  });

  testWidgets('expanded hover card artwork does not open details', (
    tester,
  ) async {
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

    await tester.tapAt(tester.getCenter(find.byType(PosterCard)));
    await tester.pumpAndSettle();

    expect(opened, isFalse);
  });

  testWidgets('linux hover card remains stable while preview resolves', (
    tester,
  ) async {
    if (!Platform.isLinux) return;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 236,
              height: 420,
              child: PosterCard(
                mediaId: 'movie:1',
                title: 'Signal Lost',
                year: '2026',
                rating: '8.4',
                subtitle: 'Movie',
                overview: 'A hidden broadcast network.',
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
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('vertical wheel over media rail scrolls parent page', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                const SizedBox(height: 80),
                MediaRail(
                  itemWidth: 160,
                  height: 220,
                  children: List.generate(
                    8,
                    (index) => PosterCard(title: 'Title $index'),
                  ),
                ),
                const SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      ),
    );

    final railCenter = tester.getCenter(find.byType(MediaRail));
    tester.binding.handlePointerEvent(
      PointerScrollEvent(
        position: railCenter,
        scrollDelta: const Offset(0, 90),
      ),
    );
    await tester.pump();

    expect(controller.offset, greaterThan(0));
  });
}
