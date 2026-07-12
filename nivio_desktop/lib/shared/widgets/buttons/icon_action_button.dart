import 'package:flutter/material.dart';

import '../../theme/index.dart';
import 'desktop_button.dart';

class IconActionButton extends StatelessWidget {
  const IconActionButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    this.isLoading = false,
    this.semanticLabel,
    this.tooltip,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool isLoading;
  final String? semanticLabel;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return DesktopButton(
      variant: DesktopButtonVariant.icon,
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      isLoading: isLoading,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      minimumSize: const Size.square(40),
      padding: const EdgeInsets.all(AppSpacing.sm),
      icon: icon,
      child: const SizedBox.shrink(),
    );
  }
}
