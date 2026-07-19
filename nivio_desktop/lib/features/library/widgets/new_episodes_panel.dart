import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../core/network/image/tmdb_image_builder.dart';
import '../../../shared/theme/index.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/library_models.dart';
import '../services/episode_tracking_service.dart';
import '../services/library_persistence.dart';
import 'library_empty_state.dart';

class NewEpisodesPanel extends StatefulWidget {
  const NewEpisodesPanel({super.key, required this.service, this.onOpenDetail});

  final LibraryEpisodeTrackingService service;
  final ValueChanged<String>? onOpenDetail;

  @override
  State<NewEpisodesPanel> createState() => _NewEpisodesPanelState();
}

class _NewEpisodesPanelState extends State<NewEpisodesPanel> {
  var _isChecking = false;

  @override
  Widget build(BuildContext context) {
    if (!LibraryPersistence.isReady) {
      return const LibraryEmptyState(
        title: 'New episodes unavailable',
        message: 'Library storage is still starting.',
      );
    }

    return ValueListenableBuilder<Box<LibraryNewEpisodeItem>>(
      valueListenable: widget.service.listenable(),
      builder: (context, box, _) {
        final episodes = box.values.toList()
          ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
        final unreadCount = episodes.where((episode) => !episode.isRead).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: 'New Episodes',
              subtitle: unreadCount == 0
                  ? 'Tracked from TV shows in your watchlist'
                  : '$unreadCount unread episode${unreadCount == 1 ? '' : 's'} from your watchlist',
              trailing: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isChecking ? null : _checkNow,
                    icon: _isChecking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.refreshCw),
                    label: const Text('Check now'),
                  ),
                  OutlinedButton.icon(
                    onPressed: unreadCount == 0
                        ? null
                        : widget.service.markAllAsRead,
                    icon: const Icon(LucideIcons.checkCheck),
                    label: const Text('Mark read'),
                  ),
                  OutlinedButton.icon(
                    onPressed: episodes.isEmpty
                        ? null
                        : widget.service.clearAll,
                    icon: const Icon(LucideIcons.trash2),
                    label: const Text('Clear'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (episodes.isEmpty)
              const LibraryEmptyState(
                title: 'No new episodes yet',
                message:
                    'Add TV shows to your watchlist and check for newly aired episodes.',
              )
            else
              Column(
                children: [
                  for (final episode in episodes)
                    _NewEpisodeTile(
                      episode: episode,
                      onTap: () {
                        widget.service.markAsRead(episode.episodeKey);
                        widget.onOpenDetail?.call('tv:${episode.showId}');
                      },
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  Future<void> _checkNow() async {
    setState(() => _isChecking = true);
    final added = await widget.service.checkNow();
    if (!mounted) return;
    setState(() => _isChecking = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added == 0
              ? 'No new episodes found.'
              : 'Found $added new episode${added == 1 ? '' : 's'}.',
        ),
      ),
    );
  }
}

class _NewEpisodeTile extends StatelessWidget {
  const _NewEpisodeTile({required this.episode, required this.onTap});

  final LibraryNewEpisodeItem episode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = episode.posterPath == null || episode.posterPath!.isEmpty
        ? null
        : TmdbImageBuilder.poster(episode.posterPath!);
    final metadata =
        'S${episode.seasonNumber} E${episode.episodeNumber} · ${DateFormat.yMMMd().format(episode.airDate)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: episode.isRead ? AppColors.surface : AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: episode.isRead
                ? AppColors.borderSubtle
                : AppColors.selectionBorder,
          ),
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.large),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  child: SizedBox(
                    width: 70,
                    height: 105,
                    child: imageUrl == null
                        ? const ColoredBox(
                            color: AppColors.sidebarSelected,
                            child: Icon(Icons.live_tv_outlined),
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const ColoredBox(
                                  color: AppColors.sidebarSelected,
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (!episode.isRead) const _UnreadBadge(),
                          Text(metadata, style: AppTypography.metadata),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        episode.showName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        episode.episodeName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Detected ${DateFormat.yMMMd().add_jm().format(episode.detectedAt)}',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.selectionFill,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          'UNREAD',
          style: AppTypography.metadata.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}
