import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'theme/theme.dart';

/// The three top-level destinations, in navigation order.
enum ShellTab {
  /// Live shift, today's pay and unpaid balance.
  today,

  /// Month-grouped list of shifts.
  shifts,

  /// Statistics for week / month / year.
  insights,
}

/// Selected [ShellTab] of an [AdaptiveShell]. Pass one in to switch tabs from
/// outside (e.g. a notification tap), or use [AdaptiveShell.selectTab] from
/// inside a page.
class ShellController extends ValueNotifier<ShellTab> {
  /// Creates a controller that starts on [value] (Today by default).
  ShellController([super.value = ShellTab.today]);

  /// Shows [tab].
  void select(ShellTab tab) => value = tab;
}

/// App scaffold with adaptive top-level navigation.
///
/// * width < 600 dp (and height ≥ 480 dp): [NavigationBar] at the bottom;
/// * width ≥ 600 dp or height < 480 dp (phone landscape): [NavigationRail].
///
/// Pages are built lazily on first visit and then kept alive in an
/// [IndexedStack] (scroll position, form input). Hidden pages run with
/// tickers disabled, so animations and `LiveTicker`s stop. System back on
/// Shifts / Insights returns to Today first ([PopScope], compatible with
/// predictive back). Each page brings its own [Scaffold] and app bar, with
/// [ShellSettingsButton] as its trailing action.
class AdaptiveShell extends StatefulWidget {
  /// Creates the shell.
  const AdaptiveShell({
    super.key,
    required this.todayBuilder,
    required this.shiftsBuilder,
    required this.insightsBuilder,
    this.controller,
    this.onTabChanged,
  });

  /// Builds the Today page.
  final WidgetBuilder todayBuilder;

  /// Builds the Shifts page.
  final WidgetBuilder shiftsBuilder;

  /// Builds the Insights page.
  final WidgetBuilder insightsBuilder;

  /// Optional external tab state.
  final ShellController? controller;

  /// Called after the selected tab changed.
  final ValueChanged<ShellTab>? onTabChanged;

  /// Whether a window of [size] uses the [NavigationRail].
  static bool usesRail(Size size) =>
      size.width >= ChronosLayout.compactWidth ||
      size.height < ChronosLayout.compactHeight;

  /// Switches the enclosing shell to [tab] (no-op outside a shell).
  static void selectTab(BuildContext context, ShellTab tab) =>
      controllerOf(context)?.select(tab);

  /// The controller of the enclosing shell, if any.
  static ShellController? controllerOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_ShellScope>()?.controller;

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  ShellController? _ownController;
  final Set<ShellTab> _visited = <ShellTab>{};

  /// Keeps the pages (and their state) when the layout switches between bar
  /// and rail, e.g. on rotation or when a foldable is opened.
  final GlobalKey _pagesKey = GlobalKey(debugLabel: 'AdaptiveShell pages');

  ShellController get _controller =>
      widget.controller ?? (_ownController ??= ShellController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTabChanged);
    _visited.add(_controller.value);
  }

  @override
  void didUpdateWidget(AdaptiveShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_onTabChanged);
      _controller.addListener(_onTabChanged);
      _visited.add(_controller.value);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTabChanged);
    _ownController?.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() => _visited.add(_controller.value));
    widget.onTabChanged?.call(_controller.value);
  }

  WidgetBuilder _builderFor(ShellTab tab) => switch (tab) {
    ShellTab.today => widget.todayBuilder,
    ShellTab.shifts => widget.shiftsBuilder,
    ShellTab.insights => widget.insightsBuilder,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final tab = _controller.value;
    final destinations = <_Destination>[
      _Destination(Icons.timer_outlined, Icons.timer, l10n.navToday),
      _Destination(Icons.list_alt_outlined, Icons.list_alt, l10n.navShifts),
      _Destination(Icons.bar_chart_outlined, Icons.bar_chart, l10n.navInsights),
    ];

    final pages = IndexedStack(
      key: _pagesKey,
      index: tab.index,
      sizing: StackFit.expand,
      children: <Widget>[
        for (final t in ShellTab.values)
          TickerMode(
            enabled: t == tab,
            child: _visited.contains(t)
                ? KeyedSubtree(
                    key: ValueKey<ShellTab>(t),
                    child: Builder(builder: _builderFor(t)),
                  )
                : const SizedBox.shrink(),
          ),
      ],
    );

    final Widget body;
    if (AdaptiveShell.usesRail(media.size)) {
      final ltr = Directionality.of(context) == TextDirection.ltr;
      body = Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: tab.index,
            onDestinationSelected: (i) =>
                _controller.select(ShellTab.values[i]),
            labelType: NavigationRailLabelType.all,
            scrollable: true,
            destinations: <NavigationRailDestination>[
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label, textAlign: TextAlign.center),
                ),
            ],
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeLeft: ltr,
              removeRight: !ltr,
              child: pages,
            ),
          ),
        ],
      );
    } else {
      // The bar consumes the bottom inset; the pages must not pad for it
      // again, and the keyboard only overlaps them by what exceeds the bar.
      final barExtent =
          (Theme.of(context).navigationBarTheme.height ??
              ChronosLayout.navigationBarHeight) +
          media.padding.bottom;
      final pageMedia = media.copyWith(
        padding: media.padding.copyWith(bottom: 0),
        viewPadding: media.viewPadding.copyWith(bottom: 0),
        viewInsets: media.viewInsets.copyWith(
          bottom: math.max(0, media.viewInsets.bottom - barExtent),
        ),
      );
      body = Column(
        children: <Widget>[
          Expanded(
            child: MediaQuery(data: pageMedia, child: pages),
          ),
          NavigationBar(
            selectedIndex: tab.index,
            onDestinationSelected: (i) =>
                _controller.select(ShellTab.values[i]),
            destinations: <Widget>[
              for (final d in destinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                ),
            ],
          ),
        ],
      );
    }

    return PopScope<Object?>(
      canPop: tab == ShellTab.today,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _controller.select(ShellTab.today);
      },
      child: _ShellScope(
        controller: _controller,
        child: Material(color: scheme.surface, child: body),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _ShellScope extends InheritedWidget {
  const _ShellScope({required this.controller, required super.child});

  final ShellController controller;

  @override
  bool updateShouldNotify(_ShellScope oldWidget) =>
      controller != oldWidget.controller;
}

/// The gear icon for the trailing slot of every page's app bar.
///
/// ```dart
/// AppBar(title: ..., actions: [ShellSettingsButton(onPressed: openSettings)])
/// ```
class ShellSettingsButton extends StatelessWidget {
  /// Creates the settings action.
  const ShellSettingsButton({super.key, required this.onPressed});

  /// Opens the settings screen.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: AppLocalizations.of(context).commonSettings,
      icon: const Icon(Icons.settings_outlined),
    );
  }
}
