import 'package:flutter/material.dart';

import '../../theme/index.dart';
import 'metadata_badge.dart';

class RuntimeBadge extends StatelessWidget {
  const RuntimeBadge({super.key, required this.runtime});

  final String runtime;

  @override
  Widget build(BuildContext context) {
    return DesktopBadge(text: runtime, backgroundColor: AppColors.surfaceVariant, foregroundColor: AppColors.textSecondary);
  }
}
