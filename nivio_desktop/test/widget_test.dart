import 'package:flutter_test/flutter_test.dart';
import 'package:nivio_desktop/app/app.dart';

void main() {
  testWidgets('shows the desktop home surface', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NivioDesktopApp());

    expect(find.text('Nivio Desktop'), findsOneWidget);
    expect(find.text('Blackout City'), findsWidgets);
    expect(find.text('Continue Watching'), findsOneWidget);
    expect(find.text('Trending Movies'), findsOneWidget);
    expect(find.text('Trending TV'), findsOneWidget);
    expect(find.text('Trending Anime'), findsOneWidget);
    expect(find.text('Popular Providers'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
  });
}
