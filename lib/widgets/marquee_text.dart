import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class MarqueeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double blankSpace;
  final double velocity;
  final Duration pauseAfterRound;
  final CrossAxisAlignment crossAxisAlignment;

  const MarqueeText({
    super.key,
    required this.text,
    this.style,
    this.blankSpace = 30.0,
    this.velocity = 30.0,
    this.pauseAfterRound = const Duration(seconds: 2),
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textStyle = style ?? DefaultTextStyle.of(context).style;
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: textStyle),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);

        if (textPainter.size.width > constraints.maxWidth) {
          return SizedBox(
            height: textPainter.size.height,
            child: Marquee(
              text: text,
              style: textStyle,
              blankSpace: blankSpace,
              velocity: velocity,
              pauseAfterRound: pauseAfterRound,
              crossAxisAlignment: crossAxisAlignment,
            ),
          );
        } else {
          return Text(
            text,
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }
      },
    );
  }
}
