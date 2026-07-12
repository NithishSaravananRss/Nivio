import 'package:flutter/material.dart';

import '../theme/index.dart';
import '../../features/home/home_view.dart';

/// Desktop home content area.
class ContentView extends StatelessWidget {
  const ContentView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: AppColors.background, child: HomeView());
  }
}
