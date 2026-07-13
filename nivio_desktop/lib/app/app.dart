import 'package:flutter/material.dart';

import '../shared/layout/desktop_scaffold.dart';
import '../shared/theme/theme.dart';
import '../core/interfaces/search_repository.dart';

/// Root widget for the Nivio Linux desktop application.
class NivioDesktopApp extends StatelessWidget {
  final SearchRepository? searchRepository;

  const NivioDesktopApp({super.key, this.searchRepository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nivio Desktop',
      debugShowCheckedModeBanner: false,
      theme: buildNivioDesktopTheme(),
      home: DesktopScaffold(searchRepository: searchRepository),
    );
  }
}
