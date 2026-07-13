import 'package:flutter/material.dart';
import '../../theme/index.dart';

class InformationGroup extends StatelessWidget {
  const InformationGroup({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTypography.sectionTitle.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 1.2,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Divider(color: AppColors.borderSubtle, thickness: 1),
        const SizedBox(height: AppSpacing.lg),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ],
    );
  }
}

class InformationRow extends StatelessWidget {
  const InformationRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: AppTypography.body.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: DefaultTextStyle(
                style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                child: value,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
