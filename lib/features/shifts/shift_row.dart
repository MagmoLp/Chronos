import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../app/theme/theme.dart';
import '../../domain/shift.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/date_block.dart';
import 'shift_texts.dart';

enum _RowAction { edit, duplicate, togglePaid, delete }

/// One finished shift in the Shifts list (≈ 72 dp): date block, time range
/// and worked time, details, amount and paid/open status.
///
/// Tap edits, long-press opens a menu, swiping right toggles paid and
/// swiping left deletes; every action is also a screen-reader action.
class ShiftRow extends StatefulWidget {
  /// Creates the row; its key is the shift id.
  ShiftRow({
    required this.shift,
    required this.onEdit,
    required this.onDuplicate,
    required this.onTogglePaid,
    required this.onDelete,
    this.jobName,
    this.isToday = false,
  }) : super(key: ValueKey<int>(shift.id));

  /// The shift.
  final Shift shift;

  /// Job name, shown only when there is more than one job.
  final String? jobName;

  /// Highlights the date block.
  final bool isToday;

  /// Opens the editor.
  final VoidCallback onEdit;

  /// Duplicates the shift.
  final VoidCallback onDuplicate;

  /// Marks the shift paid / open (with undo).
  final VoidCallback onTogglePaid;

  /// Deletes the shift (with undo); resolves to whether it was deleted.
  final Future<bool> Function() onDelete;

  @override
  State<ShiftRow> createState() => _ShiftRowState();
}

class _ShiftRowState extends State<ShiftRow> {
  Offset? _pressPosition;

  Shift get _shift => widget.shift;

  void _run(_RowAction action) {
    switch (action) {
      case _RowAction.edit:
        widget.onEdit();
      case _RowAction.duplicate:
        widget.onDuplicate();
      case _RowAction.togglePaid:
        widget.onTogglePaid();
      case _RowAction.delete:
        unawaited(widget.onDelete());
    }
  }

  Future<void> _showMenu() async {
    final l10n = AppLocalizations.of(context);
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final box = context.findRenderObject()! as RenderBox;
    final anchor =
        _pressPosition ?? box.localToGlobal(box.size.center(Offset.zero));
    final origin = overlay.globalToLocal(anchor);
    final paid = _shift.isPaid;
    final selected = await showMenu<_RowAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(origin, origin),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<_RowAction>>[
        _menuItem(_RowAction.edit, Icons.edit_outlined, l10n.commonEdit),
        _menuItem(
          _RowAction.duplicate,
          Icons.content_copy_outlined,
          l10n.commonDuplicate,
        ),
        _menuItem(
          _RowAction.togglePaid,
          paid ? Icons.schedule : Icons.check_circle_outline,
          paid ? l10n.shiftsMarkOpen : l10n.shiftsMarkPaid,
        ),
        _menuItem(_RowAction.delete, Icons.delete_outline, l10n.commonDelete),
      ],
    );
    if (selected == null || !mounted) return;
    _run(selected);
  }

  PopupMenuItem<_RowAction> _menuItem(
    _RowAction value,
    IconData icon,
    String label,
  ) => PopupMenuItem<_RowAction>(
    value: value,
    child: Row(
      children: <Widget>[
        Icon(icon),
        const SizedBox(width: ChronosSpace.s12),
        Flexible(child: Text(label)),
      ],
    ),
  );

  Future<bool> _confirmDismiss(DismissDirection direction) async {
    if (direction == DismissDirection.startToEnd) {
      widget.onTogglePaid();
      return false;
    }
    return widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texts = ShiftTexts.of(context);
    final scheme = Theme.of(context).colorScheme;
    final colors = ChronosColors.of(context);
    final paid = _shift.isPaid;

    final content = InkWell(
      onTap: widget.onEdit,
      onTapDown: (details) => _pressPosition = details.globalPosition,
      onLongPress: () => unawaited(_showMenu()),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: ChronosLayout.listRow2),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            ChronosSpace.s16,
            ChronosSpace.s12,
            ChronosSpace.s16,
            ChronosSpace.s12,
          ),
          child: Row(
            children: <Widget>[
              DateBlock(
                date: _shift.startUtc.toLocal(),
                highlighted: widget.isToday,
              ),
              const SizedBox(width: ChronosSpace.s16),
              Expanded(
                child: _RowBody(
                  shift: _shift,
                  texts: texts,
                  jobName: widget.jobName,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Dismissible(
      key: ValueKey<String>('dismiss-${_shift.id}'),
      confirmDismiss: _confirmDismiss,
      background: _SwipeBackground(
        alignment: AlignmentDirectional.centerStart,
        color: paid ? colors.openContainer : colors.successContainer,
        foreground: paid ? colors.onOpenContainer : colors.onSuccessContainer,
        icon: paid ? Icons.schedule : Icons.check_circle_outline,
        label: paid ? l10n.shiftsMarkOpen : l10n.shiftsMarkPaid,
      ),
      secondaryBackground: _SwipeBackground(
        alignment: AlignmentDirectional.centerEnd,
        color: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
        icon: Icons.delete_outline,
        label: l10n.commonDelete,
      ),
      child: Semantics(
        container: true,
        button: true,
        label: texts.rowLabel(_shift, jobName: widget.jobName),
        excludeSemantics: true,
        onTap: widget.onEdit,
        onLongPress: () => unawaited(_showMenu()),
        customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
          CustomSemanticsAction(label: l10n.commonEdit): widget.onEdit,
          CustomSemanticsAction(label: l10n.commonDuplicate):
              widget.onDuplicate,
          CustomSemanticsAction(
            label: paid ? l10n.shiftsMarkOpen : l10n.shiftsMarkPaid,
          ): widget.onTogglePaid,
          CustomSemanticsAction(label: l10n.commonDelete): () =>
              unawaited(widget.onDelete()),
        },
        child: content,
      ),
    );
  }
}

/// Title, details and amount/status. Puts amount and status under the text
/// when the row is too narrow for both side by side (large text).
class _RowBody extends StatelessWidget {
  const _RowBody({required this.shift, required this.texts, this.jobName});

  final Shift shift;
  final ShiftTexts texts;
  final String? jobName;

  static double _width(BuildContext context, String text, TextStyle? style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = ChronosColors.of(context);
    final l10n = texts.l10n;
    final fmt = texts.fmt;
    final paid = shift.isPaid;
    final titleStyle = theme.textTheme.bodyLarge?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w500,
    );
    final detailStyle = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final amountStyle = ChronosTextStyles.of(context).amount
        .copyWith(color: paid ? scheme.onSurfaceVariant : scheme.onSurface);
    final amountText = fmt.money(shift.earnedCents);
    final details = texts.details(shift, jobName: jobName);

    final status = Icon(
      paid ? Icons.check_circle : Icons.schedule,
      size: 20,
      color: paid ? colors.success : colors.open,
      semanticLabel: paid ? l10n.statusPaid : l10n.statusOpen,
    );
    final amount = Text(amountText, style: amountStyle, maxLines: 1);

    Widget textColumn({Widget? below}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(texts.title(shift), style: titleStyle),
        if (details.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              details.join(ShiftTexts.separator),
              style: detailStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ?below,
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final amountWidth = _width(context, amountText, amountStyle);
        final titleWidth = _width(context, texts.timeRange(shift), titleStyle);
        final sideBySide =
            constraints.maxWidth - ChronosSpace.s12 - amountWidth >= titleWidth;
        if (!sideBySide) {
          return textColumn(
            below: Padding(
              padding: const EdgeInsets.only(top: ChronosSpace.s4),
              child: Row(
                children: <Widget>[
                  Flexible(child: amount),
                  const SizedBox(width: ChronosSpace.s8),
                  status,
                ],
              ),
            ),
          );
        }
        return Row(
          children: <Widget>[
            Expanded(child: textColumn()),
            const SizedBox(width: ChronosSpace.s12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                amount,
                const SizedBox(height: ChronosSpace.s4),
                status,
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.foreground,
    required this.icon,
    required this.label,
  });

  final AlignmentDirectional alignment;
  final Color color;
  final Color foreground;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge
        ?.copyWith(color: foreground);
    return ExcludeSemantics(
      child: ColoredBox(
        color: color,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ChronosSpace.s24),
          child: Align(
            alignment: alignment,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, color: foreground),
                const SizedBox(width: ChronosSpace.s8),
                Flexible(
                  child: Text(
                    label,
                    style: style,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
