import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../app/theme/theme.dart';
import '../core/format.dart';
import '../l10n/app_localizations.dart';

/// Time-of-day input: typed ("0815", "8:15", "8"), a picker button and
/// ±[stepMinutes] stepper buttons (48 dp each).
///
/// Typed text is committed when the field loses focus or is submitted; the
/// steppers wrap around midnight. Respects the system 12/24-hour setting.
class TimeField extends StatefulWidget {
  /// Creates a time field.
  const TimeField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.stepMinutes = 15,
    this.showStepper = true,
    this.enabled = true,
    this.validator,
    this.focusNode,
  });

  /// Current time, or null if not set yet.
  final ClockTime? value;

  /// Called with every committed time (typed, picked or stepped).
  final ValueChanged<ClockTime> onChanged;

  /// Field label ("Start").
  final String? label;

  /// Minutes per stepper press.
  final int stepMinutes;

  /// Whether to show the − / + buttons.
  final bool showStepper;

  /// Whether the field accepts input.
  final bool enabled;

  /// Extra validation of a readable time.
  final String? Function(ClockTime? time)? validator;

  /// Optional external focus node.
  final FocusNode? focusNode;

  @override
  State<TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<TimeField> {
  final TextEditingController _controller = TextEditingController();
  FocusNode? _ownFocusNode;
  late Fmt _fmt;
  bool _initialized = false;

  /// Text scheduled by [_setText] but not applied yet.
  String? _pendingText;

  /// The text the field shows (or is about to show).
  String get _text => _pendingText ?? _controller.text;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fmt = Fmt.of(context);
    if (!_initialized) {
      _fmt = fmt;
      _initialized = true;
      // Not attached to the field yet: set directly.
      final value = widget.value;
      _controller.text = value == null ? '' : fmt.clockTime(value);
    } else if (!identical(fmt, _fmt)) {
      final current = _fmt.parseTime(_text) ?? widget.value;
      _fmt = fmt;
      _showValue(current);
    }
  }

  @override
  void didUpdateWidget(TimeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_onFocusChanged);
      _focusNode.addListener(_onFocusChanged);
    }
    if (widget.value != oldWidget.value && !_focusNode.hasFocus) {
      _showValue(widget.value);
    }
  }

  void _showValue(ClockTime? time) =>
      _setText(time == null ? '' : _fmt.clockTime(time));

  /// Replaces the text. During a build (locale or parent value changed) the
  /// update is applied at the end of the frame, so an enclosing [Form] is
  /// not marked dirty while it is being built.
  void _setText(String text) {
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      _pendingText = null;
      if (_controller.text != text) _controller.text = text;
      return;
    }
    final alreadyScheduled = _pendingText != null;
    _pendingText = text;
    if (alreadyScheduled) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final pending = _pendingText;
      _pendingText = null;
      if (mounted && pending != null && _controller.text != pending) {
        _controller.text = pending;
      }
    });
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) _commitText();
  }

  void _commitText() {
    final parsed = _fmt.parseTime(_controller.text);
    if (parsed == null) return;
    _showValue(parsed);
    if (parsed != widget.value) widget.onChanged(parsed);
  }

  void _commit(ClockTime time) {
    _showValue(time);
    if (time != widget.value) widget.onChanged(time);
  }

  void _step(int deltaMinutes) {
    final base =
        _fmt.parseTime(_controller.text) ??
        widget.value ??
        (hour: 0, minute: 0);
    final total =
        ((base.hour * 60 + base.minute + deltaMinutes) % 1440 + 1440) % 1440;
    unawaited(HapticFeedback.selectionClick());
    _commit((hour: total ~/ 60, minute: total % 60));
  }

  Future<void> _pick() async {
    final current =
        _fmt.parseTime(_controller.text) ??
        widget.value ??
        (hour: 8, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (!mounted || picked == null) return;
    _commit((hour: picked.hour, minute: picked.minute));
  }

  String? _validate(String? text) {
    final input = text?.trim() ?? '';
    final parsed = input.isEmpty ? null : _fmt.parseTime(input);
    if (input.isNotEmpty && parsed == null) {
      return AppLocalizations.of(context)
          .errorInvalidTime(_fmt.clockTime((hour: 8, minute: 15)));
    }
    return widget.validator?.call(parsed);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _ownFocusNode?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const stepStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size.square(ChronosLayout.minTapTarget),
      ),
    );
    final field = TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      keyboardType: _fmt.use24HourFormat
          ? TextInputType.datetime
          : TextInputType.text,
      inputFormatters: <TextInputFormatter>[
        LengthLimitingTextInputFormatter(12),
      ],
      autovalidateMode: AutovalidateMode.onUnfocus,
      validator: _validate,
      onFieldSubmitted: (_) => _commitText(),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: _fmt.clockTime((hour: 8, minute: 15)),
        suffixIcon: IconButton(
          onPressed: widget.enabled ? _pick : null,
          tooltip: l10n.timeFieldPick,
          icon: const Icon(Icons.schedule),
        ),
      ),
    );
    if (!widget.showStepper) return field;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: field),
        const SizedBox(width: ChronosSpace.s8),
        Padding(
          padding: const EdgeInsets.only(top: ChronosSpace.s4),
          child: IconButton.filledTonal(
            onPressed: widget.enabled ? () => _step(-widget.stepMinutes) : null,
            tooltip: l10n.timeFieldEarlier(widget.stepMinutes),
            style: stepStyle,
            icon: const Icon(Icons.remove),
          ),
        ),
        const SizedBox(width: ChronosSpace.s8),
        Padding(
          padding: const EdgeInsets.only(top: ChronosSpace.s4),
          child: IconButton.filledTonal(
            onPressed: widget.enabled ? () => _step(widget.stepMinutes) : null,
            tooltip: l10n.timeFieldLater(widget.stepMinutes),
            style: stepStyle,
            icon: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
