import 'package:flutter/material.dart';

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
      home: const _NivioLoadingScreen(),
    );
  }
}

class _NivioLoadingScreen extends StatelessWidget {
  const _NivioLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NIVIO',
              style: textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 12),
            Text('Desktop Edition', style: textTheme.titleLarge),
            const SizedBox(height: 28),
            Text('Loading...', style: textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
