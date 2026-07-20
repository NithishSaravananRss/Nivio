import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/services/desktop_update_service.dart';
import '../shared/layout/desktop_scaffold.dart';
import '../shared/theme/theme.dart';
import '../shared/widgets/dialogs/update_dialog.dart';
import '../core/interfaces/search_repository.dart';
import '../core/interfaces/home_repository.dart';
import '../core/interfaces/details_repository.dart';
import '../features/player/services/stream_resolver.dart';
import '../features/player/playback_engine.dart';
import '../core/interfaces/watch_history_repository.dart';

/// Root widget for the Nivio Linux desktop application.
class NivioDesktopApp extends StatelessWidget {
  final SearchRepository? searchRepository;
  final HomeRepository? homeRepository;
  final DetailsRepository? detailsRepository;
  final StreamResolver? streamResolver;
  final PlaybackEngineFactory? playbackEngineFactory;
  final WatchHistoryRepository? watchHistoryRepository;

  const NivioDesktopApp({
    super.key,
    this.searchRepository,
    this.homeRepository,
    this.detailsRepository,
    this.streamResolver,
    this.playbackEngineFactory,
    this.watchHistoryRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nivio Desktop',
      debugShowCheckedModeBanner: false,
      theme: buildNivioDesktopTheme(),
      home: _StartupUpdateGate(
        child: DesktopScaffold(
          searchRepository: searchRepository,
          homeRepository: homeRepository,
          detailsRepository: detailsRepository,
          streamResolver: streamResolver,
          playbackEngineFactory: playbackEngineFactory,
          watchHistoryRepository: watchHistoryRepository,
        ),
      ),
    );
  }
}

class _StartupUpdateGate extends StatefulWidget {
  const _StartupUpdateGate({required this.child});

  final Widget child;

  @override
  State<_StartupUpdateGate> createState() => _StartupUpdateGateState();
}

class _StartupUpdateGateState extends State<_StartupUpdateGate> {
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    if (kReleaseMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasChecked) {
          _hasChecked = true;
          unawaited(_checkForUpdates());
        }
      });
    }
  }

  Future<void> _checkForUpdates() async {
    final result = await DesktopUpdateService.checkForUpdates(
      includeShorebird: true,
      downloadShorebirdPatch: true,
    );
    if (!mounted) return;

    final fullRelease = result.fullRelease;
    if (fullRelease.hasUpdate) {
      await showDialog<void>(
        context: context,
        builder: (context) => UpdateDialog(
          currentVersion: fullRelease.installedVersion,
          latestVersion: fullRelease.latestVersion,
          releaseNotes: fullRelease.releaseNotes?.trim().isNotEmpty == true
              ? fullRelease.releaseNotes!
              : 'A new Linux desktop release is available.',
          onLater: () => Navigator.of(context).maybePop(),
          onInstall: () {
            Navigator.of(context).maybePop();
            unawaited(DesktopUpdateService.openInstallTarget(fullRelease));
          },
        ),
      );
      return;
    }

    final patch = result.patch;
    if (patch.action == DesktopPatchUpdateAction.downloaded ||
        patch.action == DesktopPatchUpdateAction.restartRequired) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restart Required'),
          content: Text(patch.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Later'),
            ),
          ],
        ),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
