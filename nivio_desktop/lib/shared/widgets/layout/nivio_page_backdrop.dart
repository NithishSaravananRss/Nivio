import 'package:flutter/material.dart';

import '../../theme/index.dart';

class NivioPageBackdrop extends StatelessWidget {
  const NivioPageBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF151922), AppColors.background],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: Center(
              child: Opacity(
                opacity: 0.05,
                child: FractionallySizedBox(
                  widthFactor: 0.58,
                  child: Image.asset(
                    'assets/images/nivio-dark.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
