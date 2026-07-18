import 'package:flutter/material.dart';

import '../../../core/network/image/tmdb_image_builder.dart';
import '../../../shared/theme/index.dart';
import '../models/library_models.dart';
import '../services/library_data_service.dart';
import '../../player/models/playback_request.dart';
import '../../player/playback_request_factory.dart';
import 'library_empty_state.dart';

class DownloadsGrid extends StatelessWidget {
  const DownloadsGrid({
    super.key,
    required this.downloads,
    required this.service,
    this.onOpenDetail,
    this.onPlay,
  });

  final List<LibraryDownloadItem> downloads;
  final LibraryDownloadsService service;
  final ValueChanged<String>? onOpenDetail;
  final ValueChanged<PlaybackRequest>? onPlay;

  @override
  Widget build(BuildContext context) {
    if (downloads.isEmpty) {
      return const LibraryEmptyState(
        title: 'No downloads yet',
        message: 'Downloaded movies and episodes will appear here.',
      );
    }

    final grouped = <int, List<LibraryDownloadItem>>{};
    for (final item in downloads) {
      grouped.putIfAbsent(item.mediaId, () => []).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in grouped.values)
          group.length == 1
              ? _DownloadTile(
                  item: group.first,
                  service: service,
                  onOpenDetail: onOpenDetail,
                  onPlay: onPlay,
                )
              : _DownloadGroup(
                  items: group,
                  service: service,
                  onOpenDetail: onOpenDetail,
                  onPlay: onPlay,
                ),
      ],
    );
  }
}

class _DownloadGroup extends StatelessWidget {
  const _DownloadGroup({
    required this.items,
    required this.service,
    this.onOpenDetail,
    this.onPlay,
  });

  final List<LibraryDownloadItem> items;
  final LibraryDownloadsService service;
  final ValueChanged<String>? onOpenDetail;
  final ValueChanged<PlaybackRequest>? onPlay;

  @override
  Widget build(BuildContext context) {
    final first = items.first;
    final title = _titleParts(first).first;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            leading: _Poster(path: _posterParts(first).firstOrNull),
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${items.length} Episodes'),
            children: [
              for (final item in items)
                _DownloadTile(
                  item: item,
                  service: service,
                  grouped: true,
                  onOpenDetail: onOpenDetail,
                  onPlay: onPlay,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  const _DownloadTile({
    required this.item,
    required this.service,
    this.grouped = false,
    this.onOpenDetail,
    this.onPlay,
  });

  final LibraryDownloadItem item;
  final LibraryDownloadsService service;
  final bool grouped;
  final ValueChanged<String>? onOpenDetail;
  final ValueChanged<PlaybackRequest>? onPlay;

  @override
  Widget build(BuildContext context) {
    final parts = _titleParts(item);
    final title = grouped && parts.length > 1
        ? parts.last
        : parts.length > 1
        ? '${parts.first} - ${parts.last}'
        : item.title;
    final size = service.fileSizeBytes(item);
    final statusText = _statusText(size);
    final posterParts = _posterParts(item);
    final poster = posterParts.length > 1
        ? posterParts.last
        : posterParts.firstOrNull;

    return Padding(
      padding: EdgeInsets.only(bottom: grouped ? 0 : AppSpacing.sm),
      child: ListTile(
        tileColor: grouped ? Colors.transparent : AppColors.surface,
        shape: grouped
            ? null
            : RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.borderSubtle),
                borderRadius: BorderRadius.circular(AppRadius.large),
              ),
        leading: _Poster(
          path: poster,
          landscape: item.season != null && item.episode != null,
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(statusText, style: AppTypography.caption),
            if (item.status == LibraryDownloadStatus.downloading)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: LinearProgressIndicator(
                  value: item.progress.clamp(0, 1),
                ),
              ),
          ],
        ),
        onTap: () => onOpenDetail?.call('${item.mediaType}:${item.mediaId}'),
        trailing: Wrap(
          spacing: AppSpacing.xs,
          children: [
            if (item.status == LibraryDownloadStatus.completed)
              IconButton(
                tooltip: service.fileExists(item)
                    ? 'Play download'
                    : 'Downloaded file missing',
                onPressed: service.fileExists(item)
                    ? () => onPlay?.call(
                        PlaybackRequestFactory.fromDownload(item),
                      )
                    : null,
                icon: const Icon(Icons.play_circle_fill),
              ),
            if (item.status == LibraryDownloadStatus.downloading ||
                item.status == LibraryDownloadStatus.pending)
              IconButton(
                tooltip: 'Pause',
                onPressed: () => service.pause(item.id),
                icon: const Icon(Icons.pause_circle_outline),
              ),
            if (item.status == LibraryDownloadStatus.paused)
              IconButton(
                tooltip: 'Resume',
                onPressed: () => service.resume(item.id),
                icon: const Icon(Icons.play_circle_outline),
              ),
            if (item.status == LibraryDownloadStatus.failed)
              IconButton(
                tooltip: 'Retry',
                onPressed: () => service.retry(item.id),
                icon: const Icon(Icons.refresh),
              ),
            IconButton(
              tooltip: 'Delete',
              onPressed: () => service.delete(item.id),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  String _statusText(int? size) {
    final parts = <String>[];
    if (item.season != null && item.episode != null) {
      parts.add('Season ${item.season} E${item.episode}');
    }
    parts.add(switch (item.status) {
      LibraryDownloadStatus.pending => 'Pending',
      LibraryDownloadStatus.downloading =>
        'Downloading ${(item.progress * 100).toStringAsFixed(1)}%',
      LibraryDownloadStatus.completed => 'Completed',
      LibraryDownloadStatus.failed => 'Failed',
      LibraryDownloadStatus.paused => 'Paused',
      LibraryDownloadStatus.extracting =>
        item.progress >= 1.0 ? 'Merging files...' : 'Extracting video link...',
    });
    if (size != null && size > 0) {
      parts.add('${(size / (1024 * 1024)).toStringAsFixed(1)} MB');
    }
    return parts.join(' · ');
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.path, this.landscape = false});

  final String? path;
  final bool landscape;

  @override
  Widget build(BuildContext context) {
    final width = landscape ? 80.0 : 50.0;
    final height = landscape ? 45.0 : 75.0;
    final url = path == null || path!.isEmpty
        ? null
        : TmdbImageBuilder.poster(path!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: SizedBox(
        width: width,
        height: height,
        child: url == null
            ? const ColoredBox(
                color: AppColors.surfaceVariant,
                child: Icon(Icons.movie_outlined),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: AppColors.surfaceVariant,
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
      ),
    );
  }
}

List<String> _titleParts(LibraryDownloadItem item) => item.title.split('|||');

List<String> _posterParts(LibraryDownloadItem item) =>
    item.posterPath?.split('|||') ?? const [];
