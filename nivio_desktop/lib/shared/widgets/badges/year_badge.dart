import 'package:flutter/material.dart';

import '../../theme/index.dart';
import 'metadata_badge.dart';

class YearBadge extends StatelessWidget {
  const YearBadge({super.key, required this.year});

  final String year;

  @override
  Widget build(BuildContext context) {
    return DesktopBadge(text: year, backgroundColor: AppColors.surfaceVariant, foregroundColor: AppColors.textSecondary);
  }
}
