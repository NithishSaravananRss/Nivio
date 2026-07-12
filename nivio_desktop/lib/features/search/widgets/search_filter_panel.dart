import 'package:flutter/material.dart' hide SearchController;

import '../../../shared/theme/index.dart';
import '../../../shared/widgets/widgets.dart';
import '../controllers/search_controller.dart';
import '../models/search_media_item.dart';

class SearchFilterPanel extends StatelessWidget {
  const SearchFilterPanel({super.key, required this.controller});

  final SearchController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Filters',
                  style: AppTypography.title,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GhostButton(
                    label: 'Reset',
                    onPressed: controller.hasActiveFilters
                        ? controller.clearFilters
                        : null,
                    minimumSize: const Size(0, 34),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _FilterSection(
            title: 'Language',
            children: [
              _FilterChip(
                label: 'All',
                selected: controller.language == SearchLanguageFilter.all,
                onTap: () => controller.setLanguage(SearchLanguageFilter.all),
              ),
              _FilterChip(
                label: 'English',
                selected: controller.language == SearchLanguageFilter.english,
                onTap: () =>
                    controller.setLanguage(SearchLanguageFilter.english),
              ),
              _FilterChip(
                label: 'Tamil',
                selected: controller.language == SearchLanguageFilter.tamil,
                onTap: () => controller.setLanguage(SearchLanguageFilter.tamil),
              ),
              _FilterChip(
                label: 'Hindi',
                selected: controller.language == SearchLanguageFilter.hindi,
                onTap: () => controller.setLanguage(SearchLanguageFilter.hindi),
              ),
              _FilterChip(
                label: 'Japanese',
                selected: controller.language == SearchLanguageFilter.japanese,
                onTap: () =>
                    controller.setLanguage(SearchLanguageFilter.japanese),
              ),
              _FilterChip(
                label: 'Korean',
                selected: controller.language == SearchLanguageFilter.korean,
                onTap: () =>
                    controller.setLanguage(SearchLanguageFilter.korean),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _FilterSection(
            title: 'Media Type',
            children: [
              _FilterChip(
                label: 'All',
                selected: controller.mediaType == SearchMediaTypeFilter.all,
                onTap: () => controller.setMediaType(SearchMediaTypeFilter.all),
              ),
              _FilterChip(
                label: 'Movie',
                selected: controller.mediaType == SearchMediaTypeFilter.movie,
                onTap: () =>
                    controller.setMediaType(SearchMediaTypeFilter.movie),
              ),
              _FilterChip(
                label: 'TV',
                selected: controller.mediaType == SearchMediaTypeFilter.tv,
                onTap: () => controller.setMediaType(SearchMediaTypeFilter.tv),
              ),
              _FilterChip(
                label: 'Anime',
                selected: controller.mediaType == SearchMediaTypeFilter.anime,
                onTap: () =>
                    controller.setMediaType(SearchMediaTypeFilter.anime),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _FilterSection(
            title: 'Sort',
            children: [
              _FilterChip(
                label: 'Default',
                selected: controller.sort == SearchSortOption.defaultOrder,
                onTap: () => controller.setSort(SearchSortOption.defaultOrder),
              ),
              _FilterChip(
                label: 'Title',
                selected: controller.sort == SearchSortOption.title,
                onTap: () => controller.setSort(SearchSortOption.title),
              ),
              _FilterChip(
                label: 'Year',
                selected: controller.sort == SearchSortOption.year,
                onTap: () => controller.setSort(SearchSortOption.year),
              ),
              _FilterChip(
                label: 'Rating',
                selected: controller.sort == SearchSortOption.rating,
                onTap: () => controller.setSort(SearchSortOption.rating),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: children,
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GenreChip(label: label, selected: selected, onPressed: onTap);
  }
}
