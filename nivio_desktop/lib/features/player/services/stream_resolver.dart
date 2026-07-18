import '../../../shared/models/stream_result.dart';
import '../models/playback_request.dart';

typedef StreamResolutionStatus = void Function(String status);

class PlaybackSourceOption {
  const PlaybackSourceOption({
    required this.index,
    required this.provider,
    required this.server,
    this.group,
    this.providerId,
    this.directMedia = true,
    this.iframeOnly = false,
  });

  final int index;
  final String provider;
  final String server;
  final String? group;
  final String? providerId;
  final bool directMedia;
  final bool iframeOnly;

  String get label =>
      server.isEmpty || server == provider ? provider : '$provider · $server';
}

abstract interface class StreamResolver {
  Future<List<PlaybackSourceOption>> availableSources(PlaybackRequest request);

  Future<StreamResult> resolve(
    PlaybackRequest request, {
    StreamResolutionStatus? onStatus,
  });
}

class StreamResolutionException implements Exception {
  const StreamResolutionException(this.message, {this.canRetry = true});

  final String message;
  final bool canRetry;

  @override
  String toString() => message;
}
