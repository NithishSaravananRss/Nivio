import 'package:flutter/material.dart' hide SearchBar, SearchController;

import '../../../shared/theme/index.dart';
import '../../../shared/widgets/widgets.dart';
import '../controllers/search_controller.dart';
import '../models/search_media_item.dart';

class SearchToolbar extends StatelessWidget {
  const SearchToolbar({
    super.key,
    required this.controller,
    required this.queryController,
    required this.searchFocusNode,
    required this.onToggleFilters,
    required this.filtersVisible,
    required this.onSortSelected,
    required this.onToggleViewMode,
  });

  final SearchController controller;
  final TextEditingController queryController;
  final FocusNode searchFocusNode;
  final VoidCallback onToggleFilters;
  final bool filtersVisible;
  final ValueChanged<SearchSortOption> onSortSelected;
  final VoidCallback onToggleViewMode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SearchBar(
            controller: queryController,
            focusNode: searchFocusNode,
            autofocus: true,
            hintText: 'Search titles',
            semanticLabel: 'Search titles',
            onChanged: controller.setQuery,
            onSubmitted: (_) => controller.submitQuery(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconActionButton(
          icon: const Icon(Icons.tune_outlined),
          tooltip: filtersVisible ? 'Hide filters' : 'Show filters',
          semanticLabel: filtersVisible ? 'Hide filters' : 'Show filters',
          onPressed: onToggleFilters,
        ),
        const SizedBox(width: AppSpacing.sm),
        PopupMenuButton<SearchSortOption>(
          tooltip: 'Sort',
          onSelected: onSortSelected,
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: SearchSortOption.defaultOrder,
              child: Text('Default'),
            ),
            PopupMenuItem(value: SearchSortOption.title, child: Text('Title')),
            PopupMenuItem(value: SearchSortOption.year, child: Text('Year')),
            PopupMenuItem(
              value: SearchSortOption.rating,
              child: Text('Rating'),
            ),
          ],
          icon: const Icon(Icons.sort_outlined),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconActionButton(
          icon: Icon(
            controller.viewMode == SearchViewMode.grid
                ? Icons.view_list_outlined
                : Icons.grid_view_outlined,
          ),
          tooltip: controller.viewMode == SearchViewMode.grid
              ? 'Switch to list view'
              : 'Switch to grid view',
          semanticLabel: controller.viewMode == SearchViewMode.grid
              ? 'Switch to list view'
              : 'Switch to grid view',
          onPressed: onToggleViewMode,
        ),
      ],
    );
  }
}
