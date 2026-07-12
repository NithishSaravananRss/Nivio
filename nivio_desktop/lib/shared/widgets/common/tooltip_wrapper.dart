import 'package:flutter/material.dart';

class TooltipWrapper extends StatelessWidget {
  const TooltipWrapper({
    super.key,
    required this.child,
    this.message,
    this.excludeFromSemantics = false,
    this.preferBelow,
  });

  final Widget child;
  final String? message;
  final bool excludeFromSemantics;
  final bool? preferBelow;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) {
      return child;
    }

    return Tooltip(
      message: message,
      excludeFromSemantics: excludeFromSemantics,
      preferBelow: preferBelow,
      child: child,
    );
  }
}
