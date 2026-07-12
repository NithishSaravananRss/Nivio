import 'package:flutter/widgets.dart';

import 'app.dart';

/// Prepares Flutter desktop services before starting the app.
void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NivioDesktopApp());
}
