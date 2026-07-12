import 'package:flutter/material.dart';

import '../shared/layout/desktop_scaffold.dart';
import 'theme.dart';

/// Root widget for the Nivio Linux desktop application.
class NivioDesktopApp extends StatelessWidget {
  const NivioDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nivio Desktop',
      debugShowCheckedModeBanner: false,
      theme: buildNivioDarkTheme(),
      home: const DesktopScaffold(),
    );
  }
}
