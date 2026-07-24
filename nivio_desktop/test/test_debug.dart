import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nivio_desktop/app/app.dart';
import 'package:nivio_desktop/features/search/controllers/mock_search_repository.dart';

void main() {
  testWidgets('debug search page', (WidgetTester tester) async {
    await tester.pumpWidget(
      NivioDesktopApp(
        requireAuthentication: false,
        searchRepository: MockSearchRepository(),
      ),
    );

    final searchField = find.byType(TextField).first;
    await tester.enterText(searchField, 'signal');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    debugDumpApp();
  });
}
