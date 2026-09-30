import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../l10n/app_localizations.dart';

/// Lets a sheet veto being closed by a drag (or the drag handle), which
/// Flutter's modal bottom sheet does with `Navigator.pop` and therefore
/// without asking `PopScope`.
///
/// The sheet content installs its callbacks in `initState`; the route asks
/// [shouldVeto] before it pops.
class SheetPopGuard {
  /// Whether closing must be refused right now (e.g. unsaved changes).
  bool Function() shouldVeto = _never;

  /// Called (after the navigator settled) when a close was refused, e.g. to
  /// ask "Discard changes?".
  VoidCallback onVetoed = _nothing;

  static bool _never() => false;
  static void _nothing() {}
}

/// How the current sheet is presented, for [SheetFrame].
class SheetScope extends InheritedWidget {
  /// Creates the scope.
  const SheetScope({
    super.key,
    required this.isDialog,
    required this.fillHeight,
    required super.child,
  });

  /// Shown as a centred dialog (expanded windows) instead of a bottom sheet.
  final bool isDialog;

  /// Uses the whole available height (compact height, e.g. phone landscape).
  final bool fillHeight;

  /// The nearest scope, if any.
  static SheetScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SheetScope>();

  @override
  bool updateShouldNotify(SheetScope oldWidget) =>
      isDialog != oldWidget.isDialog || fillHeight != oldWidget.fillHeight;
}

/// Whether a window of [size] shows sheets as centred dialogs.
bool sheetUsesDialog(Size size) =>
    size.width >= ChronosLayout.expandedWidth &&
    size.height >= ChronosLayout.compactHeight;

/// Shows [builder] as a modal bottom sheet (scroll-controlled, safe area,
/// drag handle), full height on compact-height windows, or as a centred
/// dialog at most 560 dp wide on expanded windows.
///
/// With a [guard] a drag-to-close can be refused (see [SheetPopGuard]); back
/// and barrier taps go through the content's `PopScope` as usual.
Future<T?> showAdaptiveSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  SheetPopGuard? guard,
}) {
  final size = MediaQuery.sizeOf(context);
  if (sheetUsesDialog(size)) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => SheetScope(
        isDialog: true,
        fillHeight: false,
        child: Dialog(
          insetPadding: const EdgeInsets.all(ChronosSpace.s24),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: ChronosLayout.paneMaxWidth,
            ),
            child: builder(dialogContext),
          ),
        ),
      ),
    );
  }

  final fillHeight = size.height < ChronosLayout.compactHeight;
  final navigator = Navigator.of(context);
  final localizations = MaterialLocalizations.of(context);
  return navigator.push(
    _GuardedSheetRoute<T>(
      guard: guard,
      builder: (sheetContext) => SheetScope(
        isDialog: false,
        fillHeight: fillHeight,
        child: builder(sheetContext),
      ),
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      barrierLabel: localizations.scrimLabel,
      barrierOnTapHint: localizations.scrimOnTapHint(
        localizations.bottomSheetLabel,
      ),
    ),
  );
}

/// A modal bottom sheet route whose drag-to-close can be vetoed.
class _GuardedSheetRoute<T> extends ModalBottomSheetRoute<T> {
  _GuardedSheetRoute({
    required super.builder,
    required super.isScrollControlled,
    super.capturedThemes,
    super.useSafeArea,
    super.showDragHandle,
    super.barrierLabel,
    super.barrierOnTapHint,
    this.guard,
  });

  final SheetPopGuard? guard;

  @override
  bool didPop(T? result) {
    final guard = this.guard;
    if (guard != null && guard.shouldVeto()) {
      // A drag already started the closing animation: spring back, then let
      // the content ask what to do (the navigator is locked right now).
      unawaited(controller?.forward());
      scheduleMicrotask(guard.onVetoed);
      return false;
    }
    return super.didPop(result);
  }
}

/// Layout of a form sheet: a header (close button + title), a scrolling
/// body and an optional pinned [footer] (primary action).
///
/// Adapts to [SheetScope]: fills the height on compact-height windows and
/// keeps clear of the keyboard.
class SheetFrame extends StatelessWidget {
  /// Creates the frame.
  const SheetFrame({
    super.key,
    required this.title,
    required this.children,
    this.footer,
    this.onClose,
    this.bodyKey,
  });

  /// Sheet title (announced as a header).
  final String title;

  /// Body content, laid out in a scrolling column.
  final List<Widget> children;

  /// Pinned bottom area (e.g. preview and save button).
  final Widget? footer;

  /// Close button action; defaults to `Navigator.maybePop`.
  final VoidCallback? onClose;

  /// Key of the body's scroll view (tests).
  final Key? bodyKey;

  @override
  Widget build(BuildContext context) {
    final scope = SheetScope.maybeOf(context);
    final isDialog = scope?.isDialog ?? false;
    final fill = scope?.fillHeight ?? false;
    final keyboard = isDialog ? 0.0 : MediaQuery.viewInsetsOf(context).bottom;
    const horizontal = ChronosSpace.s24;

    final body = SingleChildScrollView(
      key: bodyKey,
      padding: const EdgeInsets.fromLTRB(
        horizontal,
        ChronosSpace.s8,
        horizontal,
        ChronosSpace.s24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final column = Column(
            mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _SheetHeader(
                title: title,
                maxLines: fill ? 1 : 2,
                topPadding: isDialog ? ChronosSpace.s16 : 0,
                onClose: onClose ?? () => Navigator.maybePop(context),
              ),
              if (fill) Expanded(child: body) else Flexible(child: body),
              if (footer != null) ...<Widget>[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    horizontal,
                    ChronosSpace.s12,
                    horizontal,
                    ChronosSpace.s16,
                  ),
                  child: footer,
                ),
              ],
            ],
          );
          if (fill && constraints.hasBoundedHeight) {
            return SizedBox(height: constraints.maxHeight, child: column);
          }
          return column;
        },
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    required this.maxLines,
    required this.topPadding,
    required this.onClose,
  });

  final String title;
  final int maxLines;
  final double topPadding;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        ChronosSpace.s8,
        topPadding,
        ChronosSpace.s24,
        ChronosSpace.s4,
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onClose,
            tooltip: AppLocalizations.of(context).commonClose,
            icon: const Icon(Icons.close),
          ),
          const SizedBox(width: ChronosSpace.s8),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Moves focus out of text fields and waits until their "commit on blur"
/// handlers ran (typed times, amounts), so a save sees the latest input.
Future<void> commitPendingInput() async {
  FocusManager.instance.primaryFocus?.unfocus();
  await Future<void>.microtask(() {});
}
