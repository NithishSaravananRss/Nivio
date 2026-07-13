import 'package:flutter_test/flutter_test.dart';
import 'package:nivio_desktop/features/details/controllers/detail_controller.dart';
import 'package:nivio_desktop/features/details/models/detail_models.dart';
import 'package:nivio_desktop/features/details/models/detail_route_args.dart';
import 'package:nivio_desktop/core/interfaces/details_repository.dart';
import 'package:nivio_desktop/features/details/data/mock_detail_catalog.dart';

class MockDetailsRepository implements DetailsRepository {
  final Map<int, List<DetailEpisode>> mockEpisodes = {};
  bool throwError = false;

  @override
  Future<DetailMedia> loadCompleteDetail(DetailRouteArgs args) async {
    if (throwError) {
      throw Exception('Network error');
    }
    final mediaIdString = '${args.mediaType}:${args.mediaId}';
    return detailForId(mediaIdString);
  }

  @override
  Future<List<DetailEpisode>> getSeasonEpisodes({
    required int tvId,
    required int seasonNumber,
  }) async {
    if (throwError) {
      throw Exception('Network error');
    }
    return mockEpisodes[seasonNumber] ?? [];
  }
}

void main() {
  group('DetailController Tests', () {
    late MockDetailsRepository mockRepository;
    late DetailController controller;

    setUp(() {
      mockRepository = MockDetailsRepository();
      controller = DetailController(repository: mockRepository);
    });

    test('initial state defaults', () {
      expect(controller.status, equals(DetailStatus.loading)); // starts as loading initially
      expect(controller.media, isNull);
      expect(controller.episodes, isEmpty);
    });

    test('loadDetail success loads movie details', () async {
      final args = DetailRouteArgs(mediaType: 'movie', mediaId: 550);
      final future = controller.loadDetail(args);

      expect(controller.status, equals(DetailStatus.loading));

      await future;

      expect(controller.status, equals(DetailStatus.loaded));
      expect(controller.media, isNotNull);
    });

    test('loadDetail failure sets error state', () async {
      mockRepository.throwError = true;
      final args = DetailRouteArgs(mediaType: 'movie', mediaId: 550);

      await controller.loadDetail(args);

      expect(controller.status, equals(DetailStatus.error));
      expect(controller.errorMessage, contains('Network error'));
    });

    test('loadSeasonEpisodes success loads episodes', () async {
      final mockEpisodeList = [
        const DetailEpisode(
          number: 1,
          title: 'Test Pilot',
          runtime: '45m',
          overview: 'Overview test',
          progress: 0.0,
          status: 'Unwatched',
        )
      ];
      mockRepository.mockEpisodes[1] = mockEpisodeList;

      final args = DetailRouteArgs(mediaType: 'tv', mediaId: 100);
      await controller.loadDetail(args);

      // Now load season 1 episodes
      final episodeFuture = controller.loadSeasonEpisodes(100, 1);
      expect(controller.isLoadingEpisodes, isTrue);

      await episodeFuture;

      expect(controller.isLoadingEpisodes, isFalse);
      expect(controller.episodes, equals(mockEpisodeList));
    });
  });
}
