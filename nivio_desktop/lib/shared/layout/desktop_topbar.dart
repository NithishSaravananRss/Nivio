import 'package:flutter/material.dart' hide SearchBar;

import '../theme/index.dart';
import '../widgets/buttons/icon_action_button.dart';
import '../widgets/inputs/search_bar.dart';

/// Top application bar for the desktop shell.
class DesktopTopbar extends StatelessWidget {
  const DesktopTopbar({
    super.key,
    this.searchController,
    this.searchFocusNode,
    this.onSearchChanged,
    this.onSearchSubmitted,
  });

  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.topbarBackground,
        border: const Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Row(
          children: [
            Text(
              'Nivio Desktop',
              style: AppTypography.title.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: SearchBar(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    hintText: 'Search movies, series, anime',
                    semanticLabel: 'Global search',
                    onChanged: onSearchChanged,
                    onSubmitted: onSearchSubmitted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                IconActionButton(
                  icon: Icon(Icons.notifications_none_outlined),
                  semanticLabel: 'Notifications',
                  tooltip: 'Notifications',
                ),
                IconActionButton(
                  icon: Icon(Icons.system_update_alt_outlined),
                  semanticLabel: 'Updates',
                  tooltip: 'Updates',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
