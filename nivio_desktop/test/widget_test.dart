import 'package:flutter_test/flutter_test.dart';
import 'package:nivio_desktop/app/app.dart';

void main() {
  testWidgets('shows the desktop loading shell', (WidgetTester tester) async {
    await tester.pumpWidget(const NivioDesktopApp());

    expect(find.text('NIVIO'), findsOneWidget);
    expect(find.text('Desktop Edition'), findsOneWidget);
    expect(find.text('Loading...'), findsOneWidget);
  });
}
