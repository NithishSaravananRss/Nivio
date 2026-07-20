import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nivio_desktop/app/app.dart';

import 'package:nivio_desktop/core/interfaces/details_repository.dart';
import 'package:nivio_desktop/features/search/controllers/mock_search_repository.dart';
import 'package:nivio_desktop/features/search/models/search_media_item.dart';
import 'package:nivio_desktop/features/details/data/mock_detail_catalog.dart';
import 'package:nivio_desktop/features/details/models/detail_models.dart';
import 'package:nivio_desktop/features/details/models/detail_route_args.dart';
import 'package:nivio_desktop/shared/widgets/cards/media_card.dart';
import 'test_helper.dart';

class _SearchDetailsRepository implements DetailsRepository {
  DetailRouteArgs? lastArgs;

  @override
  Future<DetailMedia> loadCompleteDetail(DetailRouteArgs args) async {
    lastArgs = args;
    return detailForId('signal-lost');
  }

  @override
  Future<List<DetailEpisode>> getSeasonEpisodes({
    required int tvId,
    required int seasonNumber,
  }) async {
    return const [];
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  testWidgets('opens the search page and shows mock results', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      NivioDesktopApp(searchRepository: MockSearchRepository()),
    );

    await tester.tap(find.byKey(const ValueKey('desktop_sidebar_1')));
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField).first;
    await tester.enterText(searchField, 'signal');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Filters'), findsNothing);

    Finder mediaCard(String title) => find.byWidgetPredicate(
      (widget) => widget is MediaCard && widget.title == title,
    );

    expect(mediaCard('Signal Lost'), findsOneWidget);
    await tester.scrollUntilVisible(
      mediaCard('Halo Signal'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    expect(mediaCard('Halo Signal'), findsOneWidget);
    expect(mediaCard('Blackout City'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('search result cards open details with typed media ids', (
    WidgetTester tester,
  ) async {
    final detailsRepository = _SearchDetailsRepository();
    const item = SearchMediaItem(
      id: 'movie:550',
      title: 'Signal Lost',
      year: 2026,
      rating: 8.4,
      language: SearchLanguageFilter.english,
      mediaType: SearchMediaTypeFilter.movie,
      provider: 'Prime Video',
      genres: ['Drama'],
      posterLabel: 'Signal Lost',
      overview: 'An ex-operator uncovers a hidden broadcast network.',
      runtimeLabel: '1h 56m',
    );

    await tester.pumpWidget(
      NivioDesktopApp(
        searchRepository: MockSearchRepository(items: const [item]),
        detailsRepository: detailsRepository,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('desktop_sidebar_1')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'signal');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is MediaCard && widget.title == 'Signal Lost',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      detailsRepository.lastArgs,
      const DetailRouteArgs(mediaType: 'movie', mediaId: 550),
    );
    expect(find.text('Signal Lost'), findsWidgets);
  });
}
