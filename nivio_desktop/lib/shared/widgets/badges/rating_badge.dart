import 'package:flutter/material.dart';

import '../../theme/index.dart';
import 'metadata_badge.dart';

class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating});

  final String rating;

  @override
  Widget build(BuildContext context) {
    return DesktopBadge(text: rating, backgroundColor: AppColors.selectionFill, foregroundColor: AppColors.textPrimary);
  }
}
