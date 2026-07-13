import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/config/app_environment.dart';
import '../../shared/models/iptv_channel.dart';
import '../../shared/models/iptv_playlist.dart';
import '../../shared/theme/index.dart';
import '../../shared/widgets/widgets.dart';
import 'services/iptv_service.dart';

class LiveTvView extends StatefulWidget {
  const LiveTvView({super.key});

  @override
  State<LiveTvView> createState() => _LiveTvViewState();
}

class _LiveTvViewState extends State<LiveTvView> {
  static const Duration _loadTimeout = Duration(seconds: 40);

  final DesktopIptvService _service = DesktopIptvService();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _hasLoadError = false;
  String? _error;
  List<IptvChannel> _channels = const [];
  List<IptvChannel> _filteredChannels = const [];
  Map<String, List<IptvChannel>> _groupedChannels = const {};
  String _searchQuery = '';
  String? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _log('env playlistUrl=${AppEnvironment.iptvPlaylistUrl}');
    _loadSavedPlaylist();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading && !_hasLoadError && _channels.isNotEmpty) {
      return _buildLoadedView();
    }

    return DesktopScrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              const SectionHeader(
                title: 'Live TV',
                subtitle: 'Load IPTV playlists and stream live channels',
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (_isLoading)
                const LoadingView(message: 'Loading channels...')
              else if (_hasLoadError)
                _LiveTvErrorState(
                  message: _error ?? 'Live TV failed to load.',
                  onRetry: _loadSavedPlaylist,
                  onAddNew: _showAddPlaylistForm,
                )
              else if (_channels.isEmpty)
                _EmptyPlaylistState(
                  controller: _urlController,
                  error: _error,
                  onLoad: () => _fetchPlaylist(_urlController.text.trim()),
                  onLoadPublic: () {
                    _urlController.text = AppEnvironment.iptvPlaylistUrl;
                    _fetchPlaylist(_urlController.text);
                  },
                ),
              const SizedBox(height: AppSpacing.massive),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedView() {
    final groups = ['All', 'Favorites', ..._groupedChannels.keys];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              const SectionHeader(
                title: 'Live TV',
                subtitle: 'Load IPTV playlists and stream live channels',
              ),
              const SizedBox(height: AppSpacing.xxl),
              _LiveTvToolbar(
                searchController: _searchController,
                selectedGroup: _selectedGroup ?? 'All',
                groups: groups,
                onSearchChanged: (value) {
                  _searchQuery = value;
                  _filterChannels();
                },
                onGroupSelected: (value) {
                  setState(() {
                    _selectedGroup = value;
                    _filteredChannels = _filteredChannelsFor();
                  });
                  _resetListScroll();
                },
                onManagePlaylists: _showPlaylistManager,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
        Expanded(
          child: PageContainer(
            child: _filteredChannels.isEmpty
                ? const Center(
                    child: EmptyState(
                      title: 'No channels found',
                      message: 'Try a different search term or category.',
                    ),
                  )
                : _ChannelList(
                    controller: _scrollController,
                    channels: _filteredChannels,
                    onToggleFavorite: _toggleFavorite,
                    onPlay: _playChannel,
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadSavedPlaylist() async {
    _log('loadSavedPlaylist start');
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
      _error = null;
    });
    try {
      final channels = await _service.loadAllChannels().timeout(_loadTimeout);
      _log('loadSavedPlaylist service complete channels=${channels.length}');
      if (!mounted) return;
      _processChannels(channels);
      _log(
        'loadSavedPlaylist end state=${channels.isEmpty ? 'empty' : 'loaded'}',
      );
    } catch (error, stackTrace) {
      _log(
        'loadSavedPlaylist exception type=${error.runtimeType} error=$error',
      );
      debugPrintStack(stackTrace: stackTrace, label: '[live_tv] load stack');
      if (!mounted) return;
      setState(() {
        _hasLoadError = true;
        _error = 'Failed to load saved playlists: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _log('loadSavedPlaylist finally loading=false');
      }
    }
  }

  Future<void> _fetchPlaylist(
    String url, {
    String name = 'New Playlist',
  }) async {
    if (url.isEmpty) return;
    _log('fetchPlaylist start url=$url');
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
      _error = null;
    });
    try {
      await _service.fetchAndSavePlaylist(url, name).timeout(_loadTimeout);
      _log('fetchPlaylist save complete');
      await _loadSavedPlaylist();
      _log('fetchPlaylist end loaded');
    } catch (error, stackTrace) {
      _log('fetchPlaylist exception type=${error.runtimeType} error=$error');
      debugPrintStack(stackTrace: stackTrace, label: '[live_tv] fetch stack');
      if (!mounted) return;
      setState(() {
        _hasLoadError = true;
        _error = 'Failed to load playlist: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _log('fetchPlaylist finally loading=false');
      }
    }
  }

  void _processChannels(List<IptvChannel> channels) {
    final grouped = <String, List<IptvChannel>>{};
    for (final channel in channels) {
      grouped.putIfAbsent(channel.group, () => []).add(channel);
    }
    final sortedGroups = Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    setState(() {
      _channels = channels;
      _groupedChannels = sortedGroups;
      _filteredChannels = _filteredChannelsFor(channels: channels);
      _hasLoadError = false;
      _error = null;
    });
  }

  void _filterChannels() {
    setState(() => _filteredChannels = _filteredChannelsFor());
    _resetListScroll();
  }

  List<IptvChannel> _filteredChannelsFor({List<IptvChannel>? channels}) {
    var result = channels ?? _channels;
    if (_selectedGroup == 'Favorites') {
      result = result.where((channel) => channel.isFavorite).toList();
    } else if (_selectedGroup != null && _selectedGroup != 'All') {
      result = result
          .where((channel) => channel.group == _selectedGroup)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where((channel) => channel.name.toLowerCase().contains(query))
          .toList();
    }

    return result;
  }

  Future<void> _toggleFavorite(IptvChannel channel) async {
    await _service.toggleFavorite(channel.url);
    await _loadSavedPlaylist();
  }

  void _playChannel(IptvChannel channel) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Player entry is not available on desktop yet: ${channel.name}',
          ),
        ),
      );
  }

  Future<void> _showPlaylistManager() async {
    final playlists = await _service.getPlaylists();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => _PlaylistManagerDialog(
        playlists: playlists,
        onDelete: (playlist) async {
          await _service.deletePlaylist(playlist.id);
          await _loadSavedPlaylist();
        },
        onAddNew: () {
          setState(() {
            _channels = const [];
            _filteredChannels = const [];
            _groupedChannels = const {};
            _selectedGroup = null;
            _searchQuery = '';
            _hasLoadError = false;
            _error = null;
            _searchController.clear();
          });
        },
      ),
    );
  }

  void _showAddPlaylistForm() {
    setState(() {
      _channels = const [];
      _filteredChannels = const [];
      _groupedChannels = const {};
      _selectedGroup = null;
      _searchQuery = '';
      _hasLoadError = false;
      _error = null;
      _isLoading = false;
      _searchController.clear();
    });
  }

  void _log(String message) {
    debugPrint('[live_tv] $message');
  }

  void _resetListScroll() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(0);
  }
}

class _LiveTvErrorState extends StatelessWidget {
  const _LiveTvErrorState({
    required this.message,
    required this.onRetry,
    required this.onAddNew,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EmptyState(title: 'Live TV failed to load', message: message),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: [
            PrimaryButton(label: 'Retry', onPressed: onRetry),
            SecondaryButton(label: 'Add New Playlist', onPressed: onAddNew),
          ],
        ),
      ],
    );
  }
}

class _EmptyPlaylistState extends StatelessWidget {
  const _EmptyPlaylistState({
    required this.controller,
    required this.onLoad,
    required this.onLoadPublic,
    this.error,
  });

  final TextEditingController controller;
  final VoidCallback onLoad;
  final VoidCallback onLoadPublic;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            LucideIcons.tv,
            size: 80,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Add your IPTV Playlist',
            textAlign: TextAlign.center,
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Enter an M3U URL to stream live TV channels directly in the app.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'https://example.com/playlist.m3u',
              prefixIcon: Icon(Icons.link),
            ),
            onSubmitted: (_) => onLoad(),
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: 'Load Playlist', onPressed: onLoad),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.borderSubtle)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text('OR', style: AppTypography.caption),
              ),
              Expanded(child: Divider(color: AppColors.borderSubtle)),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          SecondaryButton(
            label: 'Load Free Public Channels (iptv-org)',
            onPressed: onLoadPublic,
          ),
        ],
      ),
    );
  }
}

class _LiveTvToolbar extends StatelessWidget {
  const _LiveTvToolbar({
    required this.searchController,
    required this.selectedGroup,
    required this.groups,
    required this.onSearchChanged,
    required this.onGroupSelected,
    required this.onManagePlaylists,
  });

  final TextEditingController searchController;
  final String selectedGroup;
  final List<String> groups;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onGroupSelected;
  final VoidCallback onManagePlaylists;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Search channels...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: selectedGroup,
            items: groups
                .map(
                  (group) => DropdownMenuItem(value: group, child: Text(group)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onGroupSelected(value);
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        IconButton(
          tooltip: 'Manage Playlists',
          onPressed: onManagePlaylists,
          icon: const Icon(Icons.list),
        ),
      ],
    );
  }
}

class _ChannelList extends StatelessWidget {
  const _ChannelList({
    required this.controller,
    required this.channels,
    required this.onToggleFavorite,
    required this.onPlay,
  });

  final ScrollController controller;
  final List<IptvChannel> channels;
  final ValueChanged<IptvChannel> onToggleFavorite;
  final ValueChanged<IptvChannel> onPlay;

  @override
  Widget build(BuildContext context) {
    return DesktopScrollbar(
      controller: controller,
      child: ListView.builder(
        controller: controller,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.massive),
        itemCount: channels.length,
        itemBuilder: (context, index) {
          final channel = channels[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.borderSubtle),
                borderRadius: BorderRadius.circular(AppRadius.large),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                leading: _ChannelLogo(channel: channel),
                title: Text(
                  channel.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  channel.group,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    IconButton(
                      tooltip: channel.isFavorite
                          ? 'Remove favorite'
                          : 'Add favorite',
                      onPressed: () => onToggleFavorite(channel),
                      icon: Icon(
                        channel.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: channel.isFavorite
                            ? AppColors.danger
                            : AppColors.textSecondary,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Play channel',
                      onPressed: () => onPlay(channel),
                      icon: const Icon(Icons.play_circle_outline),
                    ),
                  ],
                ),
                onTap: () => onPlay(channel),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChannelLogo extends StatelessWidget {
  const _ChannelLogo({required this.channel});

  final IptvChannel channel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: SizedBox.square(
        dimension: 48,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.surfaceVariant),
          child: channel.logo.isEmpty
              ? const Icon(LucideIcons.tv)
              : CachedNetworkImage(
                  imageUrl: channel.logo,
                  fit: BoxFit.contain,
                  errorWidget: (context, url, error) =>
                      const Icon(LucideIcons.tv),
                ),
        ),
      ),
    );
  }
}

class _PlaylistManagerDialog extends StatefulWidget {
  const _PlaylistManagerDialog({
    required this.playlists,
    required this.onDelete,
    required this.onAddNew,
  });

  final List<IptvPlaylist> playlists;
  final ValueChanged<IptvPlaylist> onDelete;
  final VoidCallback onAddNew;

  @override
  State<_PlaylistManagerDialog> createState() => _PlaylistManagerDialogState();
}

class _PlaylistManagerDialogState extends State<_PlaylistManagerDialog> {
  late final List<IptvPlaylist> _playlists = List.of(widget.playlists);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Playlists'),
      content: SizedBox(
        width: 620,
        child: _playlists.isEmpty
            ? const EmptyState(
                title: 'No playlists loaded.',
                message: 'Add an M3U playlist to load channels.',
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _playlists.length,
                itemBuilder: (context, index) {
                  final playlist = _playlists[index];
                  return ListTile(
                    leading: const Icon(Icons.list),
                    title: Text(playlist.name),
                    subtitle: Text(
                      playlist.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete playlist',
                      onPressed: () {
                        widget.onDelete(playlist);
                        setState(() => _playlists.removeAt(index));
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            widget.onAddNew();
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.add),
          label: const Text('Add New Playlist'),
        ),
      ],
    );
  }
}
