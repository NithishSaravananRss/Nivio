import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/index.dart';

class HoverCard extends StatefulWidget {
  const HoverCard({
    super.key,
    required this.child,
    this.builder,
    this.onTap,
    this.onSecondaryTap,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.cursor = SystemMouseCursors.click,
    this.borderRadius = AppRadius.large,
    this.hoverScale = 1.02,
    this.padding,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.borderSubtle,
    this.focusBorderColor = AppColors.primary,
    this.shadow = AppShadows.hover,
  });

  final Widget child;
  final Widget Function(BuildContext context, bool isHovered, bool isFocused)? builder;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;
  final MouseCursor cursor;
  final double borderRadius;
  final double hoverScale;
  final EdgeInsetsGeometry? padding;
  final Color backgroundColor;
  final Color borderColor;
  final Color focusBorderColor;
  final List<BoxShadow> shadow;

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final scale = _isHovered ? widget.hoverScale : 1.0;
    final borderColor = _isFocused ? widget.focusBorderColor : widget.borderColor;

    final content = AnimatedContainer(
      duration: AppAnimation.hover,
      curve: AppAnimation.standard,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: borderColor),
        boxShadow: widget.shadow,
      ),
      padding: widget.padding,
      child: widget.builder?.call(context, _isHovered, _isFocused) ?? widget.child,
    );

    final focusable = FocusableActionDetector(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor: widget.cursor,
      onShowFocusHighlight: (value) => setState(() => _isFocused = value),
      onShowHoverHighlight: (value) => setState(() => _isHovered = value),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: Semantics(
        label: widget.semanticLabel,
        button: widget.onTap != null,
        child: GestureDetector(
          onTap: widget.onTap,
          onSecondaryTap: widget.onSecondaryTap,
          child: AnimatedScale(
            scale: scale,
            duration: AppAnimation.hover,
            curve: AppAnimation.standard,
            child: content,
          ),
        ),
      ),
    );

    return MouseRegion(cursor: widget.cursor, child: focusable);
  }
}
