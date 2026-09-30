import 'package:flutter/material.dart';

import '../app/theme/theme.dart';
import '../core/format.dart';

/// Animated amount text in which only the characters that changed roll.
///
/// Each changed digit slides in **from the top** inside a [ClipRect] with a
/// [SlideTransition] (no opacity), while the old digit leaves downwards.
/// Characters are keyed from the right, so "9,99 → 10,00" keeps the cents
/// slots stable. Uses tabular figures, scales down to fit ([FittedBox]),
/// exposes one semantics label with the full value and isolates repaints in
/// a [RepaintBoundary]. With `MediaQuery.disableAnimations` the new value
/// appears instantly.
///
/// ```dart
/// RollingAmount.cents(4783, style: context.chronosText.moneyHero, fractionScale: 0.6)
/// ```
class RollingAmount extends StatelessWidget {
  /// Rolls an arbitrary pre-formatted [text].
  ///
  /// Characters after the last [fractionSeparator] (e.g. the cents and a
  /// trailing "€") are drawn at [fractionScale] × the font size in
  /// [fractionColor].
  const RollingAmount({
    super.key,
    required String this.text,
    this.style,
    this.fractionSeparator,
    this.fractionScale = 1.0,
    this.fractionColor,
    this.semanticsLabel,
    this.alignment = Alignment.center,
    this.duration = ChronosMotion.digitRoll,
    this.curve = ChronosMotion.enter,
  }) : cents = null;

  /// Rolls a money amount formatted with [Fmt.money] for the ambient locale.
  const RollingAmount.cents(
    int this.cents, {
    super.key,
    this.style,
    this.fractionScale = 1.0,
    this.fractionColor,
    this.semanticsLabel,
    this.alignment = Alignment.center,
    this.duration = ChronosMotion.digitRoll,
    this.curve = ChronosMotion.enter,
  }) : text = null,
       fractionSeparator = null;

  /// Pre-formatted text (when created with the default constructor).
  final String? text;

  /// Amount in cents (when created with [RollingAmount.cents]).
  final int? cents;

  /// Base text style, merged over the ambient [DefaultTextStyle].
  final TextStyle? style;

  /// Separator after which the "minor" part starts (null: no minor part).
  final String? fractionSeparator;

  /// Font size factor for the minor part (cents), e.g. 0.6.
  final double fractionScale;

  /// Colour of the minor part; defaults to the base colour.
  final Color? fractionColor;

  /// Spoken label; defaults to the full text.
  final String? semanticsLabel;

  /// Alignment inside the available width when scaled down.
  final AlignmentGeometry alignment;

  /// Duration of one digit roll.
  final Duration duration;

  /// Curve of one digit roll.
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final String value;
    final String? separator;
    if (cents != null) {
      final fmt = Fmt.of(context);
      value = fmt.money(cents!);
      separator = fmt.decimalSeparator;
    } else {
      value = text!;
      separator = fractionSeparator;
    }

    final base = DefaultTextStyle.of(context).style
        .merge(style)
        .copyWith(fontFeatures: tabularFigures);
    final minor = fractionScale == 1.0 && fractionColor == null
        ? base
        : ChronosTextStyles.scaled(
            base,
            fractionScale,
          ).copyWith(color: fractionColor ?? base.color);
    final animate = !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

    final chars = value.characters.toList();
    final minorFrom = separator == null ? -1 : chars.lastIndexOf(separator);
    final slots = <Widget>[
      for (var i = 0; i < chars.length; i++)
        _RollingChar(
          key: ValueKey<int>(chars.length - i),
          char: chars[i],
          style: minorFrom >= 0 && i >= minorFrom ? minor : base,
          animate: animate,
          duration: duration,
          curve: curve,
        ),
    ];

    return RepaintBoundary(
      child: Semantics(
        container: true,
        label: semanticsLabel ?? value,
        child: ExcludeSemantics(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignment,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.ltr,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: slots,
            ),
          ),
        ),
      ),
    );
  }
}

class _RollingChar extends StatefulWidget {
  const _RollingChar({
    super.key,
    required this.char,
    required this.style,
    required this.animate,
    required this.duration,
    required this.curve,
  });

  final String char;
  final TextStyle style;
  final bool animate;
  final Duration duration;
  final Curve curve;

  @override
  State<_RollingChar> createState() => _RollingCharState();
}

class _RollingCharState extends State<_RollingChar>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  CurvedAnimation? _curved;
  Animation<Offset>? _incoming;
  Animation<Offset>? _outgoing;
  String? _previous;

  static bool _isDigit(String c) {
    if (c.length != 1) return false;
    final unit = c.codeUnitAt(0);
    return unit >= 0x30 && unit <= 0x39;
  }

  @override
  void didUpdateWidget(_RollingChar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.curve != widget.curve && _curved != null) {
      _curved!.curve = widget.curve;
    }
    if (oldWidget.char == widget.char) return;
    if (widget.animate && _isDigit(widget.char)) {
      _previous = oldWidget.char;
      final controller = _controller ??= _createController();
      controller
        ..duration = widget.duration
        ..forward(from: 0);
    } else {
      _controller?.stop();
      _previous = null;
    }
  }

  AnimationController _createController() {
    final controller =
        AnimationController(vsync: this, duration: widget.duration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              setState(() => _previous = null);
            }
          });
    final curved = _curved = CurvedAnimation(
      parent: controller,
      curve: widget.curve,
    );
    _incoming = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(curved);
    _outgoing = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1),
    ).animate(curved);
    return controller;
  }

  @override
  void dispose() {
    _curved?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = Text(
      widget.char,
      style: widget.style,
      maxLines: 1,
      softWrap: false,
    );
    final previous = _previous;
    if (previous == null) return current;
    return ClipRect(
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SlideTransition(
            position: _outgoing!,
            child: Text(
              previous,
              style: widget.style,
              maxLines: 1,
              softWrap: false,
            ),
          ),
          SlideTransition(position: _incoming!, child: current),
        ],
      ),
    );
  }
}
