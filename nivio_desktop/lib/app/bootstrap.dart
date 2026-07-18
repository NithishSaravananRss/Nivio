import 'package:flutter/widgets.dart';

import '../core/config/app_environment.dart';
import '../features/library/services/library_persistence.dart';
import '../features/history/desktop_watch_history_repository.dart';
import '../features/party/services/watch_party_supabase_config.dart';
import '../features/player/services/playback_runtime_diagnostics.dart';
import 'app.dart';

/// Prepares Flutter desktop services before starting the app.
Future<void> bootstrap() async {
  final startupClock = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();
  PlaybackRuntimeDiagnostics.lifecycleLog(
    'Flutter binding initialized',
    clock: startupClock,
  );
  await AppEnvironment.load();
  PlaybackRuntimeDiagnostics.lifecycleLog(
    'Environment loaded',
    clock: startupClock,
  );
  await WatchPartySupabaseConfig.initializeIfConfigured();
  PlaybackRuntimeDiagnostics.lifecycleLog(
    'Watch party services initialized',
    clock: startupClock,
  );
  await LibraryPersistence.init();
  PlaybackRuntimeDiagnostics.lifecycleLog(
    'Library persistence initialized',
    clock: startupClock,
  );
  await DesktopWatchHistoryRepository.instance.initialize();
  PlaybackRuntimeDiagnostics.lifecycleLog(
    'Watch history initialized',
    clock: startupClock,
  );
  runApp(const NivioDesktopApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PlaybackRuntimeDiagnostics.lifecycleLog(
      'First Flutter frame rendered',
      clock: startupClock,
    );
    PlaybackRuntimeDiagnostics.snapshot(
      'startup complete',
      clock: startupClock,
    );
  });
}
