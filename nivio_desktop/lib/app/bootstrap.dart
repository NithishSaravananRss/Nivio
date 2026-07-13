import 'package:flutter/widgets.dart';

import '../features/library/services/library_persistence.dart';
import 'app.dart';

/// Prepares Flutter desktop services before starting the app.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LibraryPersistence.init();
  runApp(const NivioDesktopApp());
}
