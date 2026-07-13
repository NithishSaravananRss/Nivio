import 'package:flutter/material.dart' hide SearchBar, SearchController;

import '../../../shared/theme/index.dart';
import '../../../shared/widgets/widgets.dart';
import '../controllers/search_controller.dart';

class SearchToolbar extends StatelessWidget {
  const SearchToolbar({
    super.key,
    required this.controller,
    required this.queryController,
    required this.searchFocusNode,
    required this.onToggleFilters,
    required this.filtersVisible,
  });

  final SearchController controller;
  final TextEditingController queryController;
  final FocusNode searchFocusNode;
  final VoidCallback onToggleFilters;
  final bool filtersVisible;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SearchBar(
            controller: queryController,
            focusNode: searchFocusNode,
            autofocus: true,
            hintText: 'Search movies, shows, anime',
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
      ],
    );
  }
}
