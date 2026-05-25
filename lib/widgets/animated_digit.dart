import 'package:flutter/material.dart';

class AnimatedDigit extends StatelessWidget {
  final String digit;
  final TextStyle? style;

  const AnimatedDigit({
    super.key,
    required this.digit,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final value = animation.value;
            return ClipRect(
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 30),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              ),
            );
          },
          child: child,
        );
      },
      child: Text(
        digit,
        key: ValueKey<String>(digit),
        style: style ?? Theme.of(context).textTheme.headlineLarge,
      ),
    );
  }
}
