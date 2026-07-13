import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nivio_desktop/app/app.dart';
import 'package:nivio_desktop/features/search/controllers/mock_search_repository.dart';

void main() {
  testWidgets('debug search', (tester) async {
    final repo = MockSearchRepository();
    await tester.pumpWidget(NivioDesktopApp(searchRepository: repo));
    
    final searchField = find.byType(TextField).first;
    await tester.enterText(searchField, 'signal');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    
    for (int i=0; i<10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    
    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    for (var w in textWidgets) {
      print('Found Text: ${w.data ?? w.textSpan?.toPlainText()}');
    }
  });
}
