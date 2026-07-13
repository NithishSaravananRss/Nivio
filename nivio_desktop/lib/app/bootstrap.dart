import 'package:flutter/widgets.dart';

import '../core/config/app_environment.dart';
import '../features/library/services/library_persistence.dart';
import '../features/party/services/watch_party_supabase_config.dart';
import 'app.dart';

/// Prepares Flutter desktop services before starting the app.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppEnvironment.load();
  await WatchPartySupabaseConfig.initializeIfConfigured();
  await LibraryPersistence.init();
  runApp(const NivioDesktopApp());
}
