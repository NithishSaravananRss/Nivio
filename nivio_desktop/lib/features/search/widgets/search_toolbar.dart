import 'package:flutter/material.dart' hide SearchBar, SearchController;

import '../../../shared/theme/index.dart';
import '../controllers/search_controller.dart';

class SearchToolbar extends StatelessWidget {
  const SearchToolbar({
    super.key,
    required this.controller,
    required this.queryController,
    required this.searchFocusNode,
  });

  final SearchController controller;
  final TextEditingController queryController;
  final FocusNode searchFocusNode;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textPrimary, size: 32),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: TextField(
              controller: queryController,
              focusNode: searchFocusNode,
              autofocus: true,
              onChanged: controller.setQuery,
              onSubmitted: (_) => controller.submitQuery(),
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.textPrimary,
              style: AppTypography.title.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Movies, shows and more',
                hintStyle: AppTypography.title.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: queryController,
            builder: (context, _) {
              if (queryController.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  queryController.clear();
                  controller.setQuery('');
                },
                icon: const Icon(Icons.close),
                color: AppColors.textSecondary,
                style: IconButton.styleFrom(
                  fixedSize: const Size.square(40),
                  hoverColor: AppColors.hover,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
