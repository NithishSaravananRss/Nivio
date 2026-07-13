import 'package:flutter/material.dart';

import '../theme/index.dart';
import '../../features/home/home_view.dart';
import '../../features/home/controllers/home_controller.dart';

/// Desktop home content area.
class ContentView extends StatelessWidget {
  const ContentView({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: AppColors.background, child: HomeView(controller: controller));
  }
}
