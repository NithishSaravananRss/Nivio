import 'package:flutter/material.dart';

import '../../theme/index.dart';
import '../buttons/icon_action_button.dart';

class SearchBar extends StatefulWidget {
  const SearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.semanticLabel,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final String? semanticLabel;

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late final TextEditingController _controller = widget.controller ?? TextEditingController();
  late final bool _ownsController = widget.controller == null;
  bool _hasFocus = false;

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowFocusHighlight: (value) => setState(() => _hasFocus = value),
      child: AnimatedContainer(
        duration: AppAnimation.hover,
        curve: AppAnimation.standard,
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: _hasFocus ? AppColors.primary : AppColors.borderSubtle),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.textMuted, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: widget.focusNode,
                autofocus: widget.autofocus,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                textInputAction: TextInputAction.search,
                style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_controller.text.isEmpty) {
                  return const SizedBox.shrink();
                }

                return IconActionButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Clear search',
                  semanticLabel: 'Clear search',
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged?.call('');
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
