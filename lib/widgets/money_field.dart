import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../core/format.dart';
import '../l10n/app_localizations.dart';

/// Text field for a euro amount, entered as cents.
///
/// Accepts "," and "." as decimal separator (see [Fmt.parseMoneyToCents]),
/// shows the decimal keyboard, and reformats the value on blur
/// ("15,5" → "15,50"). Validation runs when the field loses focus and on
/// `FormState.validate()`: empty (if [required]), unreadable, zero (unless
/// [allowZero]) and finally the custom [validator].
class MoneyField extends StatefulWidget {
  /// Creates a money field.
  const MoneyField({
    super.key,
    this.value,
    this.onChanged,
    this.validator,
    this.label,
    this.helperText,
    this.required = false,
    this.allowZero = true,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  /// Amount in cents. Changes from the parent replace the text while the
  /// field is not focused (e.g. a prefilled "received" amount).
  final int? value;

  /// Called on every edit with the parsed cents, or `null` if the text is
  /// empty or not a valid amount.
  final ValueChanged<int?>? onChanged;

  /// Extra validation of a readable value (null when the field is empty).
  final String? Function(int? cents)? validator;

  /// Field label ("Stundenlohn").
  final String? label;

  /// Helper text below the field.
  final String? helperText;

  /// Whether an empty field is an error.
  final bool required;

  /// Whether 0 is a valid amount (false for wages).
  final bool allowZero;

  /// Whether the field accepts input.
  final bool enabled;

  /// Whether to focus the field initially.
  final bool autofocus;

  /// Optional external focus node.
  final FocusNode? focusNode;

  /// Keyboard action button.
  final TextInputAction? textInputAction;

  /// Called when the user submits from the keyboard.
  final ValueChanged<int?>? onSubmitted;

  @override
  State<MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<MoneyField> {
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
      // Not attached to the field yet: set directly.
      _controller.text = widget.value == null
          ? ''
          : fmt.moneyInput(widget.value!);
      _initialized = true;
    } else if (!identical(fmt, _fmt)) {
      final cents = _fmt.parseMoneyToCents(_text);
      _fmt = fmt;
      if (cents != null) _setValue(cents);
    }
  }

  @override
  void didUpdateWidget(MoneyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_onFocusChanged);
      _focusNode.addListener(_onFocusChanged);
    }
    if (widget.value != oldWidget.value &&
        !_focusNode.hasFocus &&
        widget.value != _fmt.parseMoneyToCents(_text)) {
      _setValue(widget.value);
    }
  }

  void _setValue(int? cents) =>
      _setText(cents == null ? '' : _fmt.moneyInput(cents));

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
    if (_focusNode.hasFocus) return;
    final cents = _fmt.parseMoneyToCents(_controller.text);
    if (cents != null) _setValue(cents);
  }

  String? _validate(String? text) {
    final l10n = AppLocalizations.of(context);
    final input = text?.trim() ?? '';
    if (input.isEmpty) {
      return widget.required
          ? l10n.errorRequired
          : widget.validator?.call(null);
    }
    final cents = _fmt.parseMoneyToCents(input);
    if (cents == null) return l10n.errorInvalidAmount(_fmt.moneyInput(1550));
    if (!widget.allowZero && cents == 0) return l10n.errorAmountNotPositive;
    return widget.validator?.call(cents);
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
    final symbolFirst = _fmt.currencySymbolFirst;
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: widget.textInputAction,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r"[0-9.,'’ €]")),
        LengthLimitingTextInputFormatter(18),
      ],
      autovalidateMode: AutovalidateMode.onUnfocus,
      validator: _validate,
      onChanged: (text) => widget.onChanged?.call(_fmt.parseMoneyToCents(text)),
      onFieldSubmitted: widget.onSubmitted == null
          ? null
          : (text) => widget.onSubmitted!(_fmt.parseMoneyToCents(text)),
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        prefixText: symbolFirst ? '${_fmt.currencySymbol} ' : null,
        suffixText: symbolFirst ? null : _fmt.currencySymbol,
      ),
    );
  }
}
