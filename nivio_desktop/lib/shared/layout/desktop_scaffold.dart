import 'package:flutter/material.dart';

import '../theme/index.dart';
import 'content_view.dart';
import 'desktop_sidebar.dart';
import 'desktop_topbar.dart';

/// Permanent desktop shell used by future feature screens.
class DesktopScaffold extends StatelessWidget {
  const DesktopScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(
              height: AppBreakpoints.topbarHeight,
              child: DesktopTopbar(),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact =
                      constraints.maxWidth < AppBreakpoints.compactShell;

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
                      SizedBox(
                        width: AppBreakpoints.sidebarExpandedWidth,
                        child: DesktopSidebar(),
                      ),
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
