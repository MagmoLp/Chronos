import 'package:flutter/material.dart';
import 'animated_digit.dart';

class AnimatedMoneyDisplay extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final String currency;
  final int decimalPlaces;

  const AnimatedMoneyDisplay({
    super.key,
    required this.amount,
    this.style,
    this.currency = '€',
    this.decimalPlaces = 2,
  });

  @override
  Widget build(BuildContext context) {
    final formattedAmount = amount.toStringAsFixed(decimalPlaces);
    final parts = formattedAmount.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '00';

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        ..._buildDigits(integerPart),
        Text(
          ',',
          style: style ?? Theme.of(context).textTheme.headlineLarge,
        ),
        ..._buildDigits(decimalPart),
        SizedBox(width: 8),
        Text(
          currency,
          style: (style ?? Theme.of(context).textTheme.headlineLarge)?.copyWith(
            fontSize: (style?.fontSize ?? 48) * 0.6,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDigits(String digits) {
    return digits.split('').map((digit) {
      return AnimatedDigit(
        digit: digit,
        style: style,
      );
    }).toList();
  }
}
