import 'package:flutter/material.dart';

import 'content_view.dart';
import 'desktop_sidebar.dart';
import 'desktop_topbar.dart';

/// Permanent desktop shell used by future feature screens.
class DesktopScaffold extends StatelessWidget {
  const DesktopScaffold({super.key});

  static const double _sidebarWidth = 220;
  static const double _topbarHeight = 64;
  static const double _compactBreakpoint = 720;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: _topbarHeight, child: DesktopTopbar()),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < _compactBreakpoint;

                  if (isCompact) {
                    return const Column(
                      children: [
                        DesktopSidebar(isCompact: true),
                        Expanded(child: ContentView()),
                      ],
                    );
                  }

                  return const Row(
                    children: [
                      SizedBox(width: _sidebarWidth, child: DesktopSidebar()),
                      Expanded(child: ContentView()),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
