import 'package:flutter/material.dart';

import 'desktop_button.dart';

class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.focusNode,
    this.autofocus = false,
    this.isLoading = false,
    this.semanticLabel,
    this.tooltip,
    this.minimumSize,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool isLoading;
  final String? semanticLabel;
  final String? tooltip;
  final Size? minimumSize;

  @override
  Widget build(BuildContext context) {
    return DesktopButton(
      variant: DesktopButtonVariant.ghost,
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      isLoading: isLoading,
      semanticLabel: semanticLabel ?? label,
      tooltip: tooltip,
      minimumSize: minimumSize,
      icon: icon,
      child: Text(label),
    );
  }
}
