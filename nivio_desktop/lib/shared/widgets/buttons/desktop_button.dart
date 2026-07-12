import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/index.dart';
import '../common/animated_scale_container.dart';
import '../common/tooltip_wrapper.dart';

enum DesktopButtonVariant { primary, secondary, ghost, icon }

class DesktopButton extends StatefulWidget {
  const DesktopButton({
    super.key,
    required this.variant,
    required this.child,
    this.icon,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    this.isLoading = false,
    this.semanticLabel,
    this.tooltip,
    this.minimumSize,
    this.padding,
  });

  final DesktopButtonVariant variant;
  final Widget child;
  final Widget? icon;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool isLoading;
  final String? semanticLabel;
  final String? tooltip;
  final Size? minimumSize;
  final EdgeInsetsGeometry? padding;

  @override
  State<DesktopButton> createState() => _DesktopButtonState();
}

class _DesktopButtonState extends State<DesktopButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final colors = _resolveColors(widget.variant, enabled);
    final scale = _isPressed ? 0.98 : _isHovered && enabled ? 1.02 : 1.0;

    final button = FocusableActionDetector(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor:
          enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onShowFocusHighlight: (value) => setState(() => _isFocused = value),
      onShowHoverHighlight: (value) => setState(() => _isHovered = value),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (enabled) {
              widget.onPressed?.call();
            }
            return null;
          },
        ),
      },
      child: Semantics(
        button: true,
        enabled: enabled,
        label: widget.semanticLabel,
        child: TooltipWrapper(
          message: widget.tooltip,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? widget.onPressed : null,
            onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
            onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
            onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
            child: AnimatedScaleContainer(
              scale: scale,
              child: AnimatedContainer(
                duration: AppAnimation.hover,
                curve: AppAnimation.standard,
                constraints: BoxConstraints(
                  minWidth: widget.minimumSize?.width ?? 0,
                  minHeight: widget.minimumSize?.height ?? 0,
                ),
                padding: widget.padding ?? _defaultPadding(widget.variant),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(_borderRadius(widget.variant)),
                  border: Border.all(
                    color: _isFocused ? colors.focusBorder : colors.border,
                    width: _isFocused ? 1.5 : 1,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(opacity: widget.isLoading ? 0 : 1, child: _buildChild(colors)),
                    if (widget.isLoading)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(colors.foreground),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return MouseRegion(cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden, child: button);
  }

  Widget _buildChild(_DesktopButtonColors colors) {
    if (widget.variant == DesktopButtonVariant.icon) {
      return Center(
        child: IconTheme.merge(
          data: IconThemeData(color: colors.foreground, size: AppSpacing.xl),
          child: widget.icon ?? widget.child,
        ),
      );
    }

    if (widget.icon == null) {
      return DefaultTextStyle.merge(
        style: AppTypography.title.copyWith(color: colors.foreground),
        child: widget.child,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconTheme.merge(
          data: IconThemeData(color: colors.foreground, size: AppSpacing.xl),
          child: widget.icon!,
        ),
        const SizedBox(width: AppSpacing.sm),
        DefaultTextStyle.merge(
          style: AppTypography.title.copyWith(color: colors.foreground),
          child: widget.child,
        ),
      ],
    );
  }
}

class _DesktopButtonColors {
  const _DesktopButtonColors({
    required this.background,
    required this.foreground,
    required this.border,
    required this.focusBorder,
  });

  final Color background;
  final Color foreground;
  final Color border;
  final Color focusBorder;
}

_DesktopButtonColors _resolveColors(DesktopButtonVariant variant, bool enabled) {
  switch (variant) {
    case DesktopButtonVariant.primary:
      return _DesktopButtonColors(
        background: enabled ? AppColors.primary : AppColors.disabledFill,
        foreground: enabled ? AppColors.textPrimary : AppColors.disabledText,
        border: enabled ? AppColors.primary : AppColors.disabledFill,
        focusBorder: AppColors.textPrimary,
      );
    case DesktopButtonVariant.secondary:
      return _DesktopButtonColors(
        background: enabled ? AppColors.surfaceVariant : AppColors.disabledFill,
        foreground: enabled ? AppColors.textPrimary : AppColors.disabledText,
        border: enabled ? AppColors.borderStrong : AppColors.disabledFill,
        focusBorder: AppColors.primary,
      );
    case DesktopButtonVariant.ghost:
      return _DesktopButtonColors(
        background: Colors.transparent,
        foreground: enabled ? AppColors.textPrimary : AppColors.disabledText,
        border: Colors.transparent,
        focusBorder: AppColors.primary,
      );
    case DesktopButtonVariant.icon:
      return _DesktopButtonColors(
        background: enabled ? AppColors.surfaceVariant : AppColors.disabledFill,
        foreground: enabled ? AppColors.textPrimary : AppColors.disabledText,
        border: enabled ? AppColors.borderSubtle : AppColors.disabledFill,
        focusBorder: AppColors.primary,
      );
  }
}

double _borderRadius(DesktopButtonVariant variant) {
  return variant == DesktopButtonVariant.icon ? AppRadius.pill : AppRadius.medium;
}

EdgeInsetsGeometry _defaultPadding(DesktopButtonVariant variant) {
  if (variant == DesktopButtonVariant.icon) {
    return const EdgeInsets.all(AppSpacing.sm);
  }

  return const EdgeInsets.symmetric(
    horizontal: AppSpacing.xxl,
    vertical: AppSpacing.md,
  );
}
