import 'package:flutter_test/flutter_test.dart';
import 'package:nivio_desktop/app/app.dart';

void main() {
  testWidgets('shows the desktop application shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NivioDesktopApp());

    expect(find.text('Nivio Desktop'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Watchlist'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Welcome to Nivio Desktop'), findsOneWidget);
    expect(find.text('Desktop Application Shell'), findsOneWidget);
    expect(find.text('Future features will be loaded here.'), findsOneWidget);
  });
}
