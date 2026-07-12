import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/index.dart';

class GenreChip extends StatefulWidget {
  const GenreChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;

  @override
  State<GenreChip> createState() => _GenreChipState();
}

class _GenreChipState extends State<GenreChip> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final backgroundColor = widget.selected ? AppColors.selectionFill : (_isHovered && enabled ? AppColors.hover : AppColors.surfaceVariant);
    final borderColor = widget.selected ? AppColors.selectionBorder : (_isFocused ? AppColors.primary : AppColors.borderSubtle);

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onShowFocusHighlight: (value) => setState(() => _isFocused = value),
        onShowHoverHighlight: (value) => setState(() => _isHovered = value),
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            if (enabled) {
              widget.onPressed?.call();
            }
            return null;
          }),
        },
        child: Semantics(
          button: true,
          selected: widget.selected,
          label: widget.semanticLabel ?? widget.label,
          child: GestureDetector(
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: AppAnimation.hover,
              curve: AppAnimation.standard,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: borderColor),
              ),
              child: Text(widget.label, style: AppTypography.metadata.copyWith(color: AppColors.textPrimary)),
            ),
          ),
        ),
      ),
    );
  }
}
