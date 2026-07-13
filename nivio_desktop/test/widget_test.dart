import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nivio_desktop/app/app.dart';

import 'package:nivio_desktop/features/search/models/search_media_item.dart';
import 'package:nivio_desktop/core/interfaces/home_repository.dart';
import 'package:nivio_desktop/features/search/controllers/mock_search_repository.dart';
import 'test_helper.dart';

class MockHomeRepository implements HomeRepository {
  @override
  Future<List<SearchMediaItem>> getTrendingMovies() async => [];

  @override
  Future<List<SearchMediaItem>> getTrendingTv() async => [];

  @override
  Future<List<SearchMediaItem>> getTrendingAnime() async => [];

  @override
  Future<List<SearchMediaItem>> getFeaturedContent() async => [];
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  testWidgets('shows the desktop home surface', (WidgetTester tester) async {
    await tester.pumpWidget(
      NivioDesktopApp(
        searchRepository: MockSearchRepository(),
        homeRepository: MockHomeRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nivio Desktop'), findsOneWidget);
    expect(find.text('Continue Watching'), findsNothing);
    expect(find.text('Trending Movies'), findsOneWidget);
    expect(find.text('Trending TV'), findsOneWidget);
    expect(find.text('Trending Anime'), findsNothing);
    expect(find.text('Studios'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
  });
}
