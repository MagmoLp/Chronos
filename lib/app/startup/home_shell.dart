import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/insights/insights_page.dart';
import '../../features/review/review_page.dart';
import '../../features/shifts/shifts_page.dart';
import '../../features/today/today_page.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../shell.dart';

/// Whether the one-time "N Einträge aus Chronos 1 übernommen" notice was
/// shown in this app session.
final migrationNoticeProvider =
    NotifierProvider<MigrationNoticeController, bool>(
      MigrationNoticeController.new,
      name: 'migrationNoticeProvider',
    );

/// Remembers that the migration notice was shown.
class MigrationNoticeController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Marks the notice as shown; returns `false` if it already was.
  bool claim() {
    if (state) return false;
    state = true;
    return true;
  }
}

/// The app once it is ready: the three tabs in an [AdaptiveShell].
///
/// Owns the [ShellController] and routes [AppRequest]s from notifications:
/// both "show Today" and "open the finish sheet" bring the Today tab to the
/// front (closing routes above the shell); "show Today" is consumed here,
/// the finish-sheet request is left for the Today page.
class HomeShell extends ConsumerStatefulWidget {
  /// Creates the shell.
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  final ShellController _controller = ShellController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleRequest(ref.read(appRequestProvider));
      _showMigrationNotice();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleRequest(AppRequest? request) {
    if (request == null || !mounted) return;
    Navigator.maybeOf(context)?.popUntil((route) => route.isFirst);
    _controller.select(ShellTab.today);
    if (request.kind == AppRequestKind.showToday) {
      ref.read(appRequestProvider.notifier).consume(request);
    }
  }

  void _showMigrationNotice() {
    final result = ref.read(bootstrapProvider).value;
    if (result == null || !result.migration.migrated) return;
    final count = result.migration.importedCount;
    if (count <= 0 || !ref.read(migrationNoticeProvider.notifier).claim()) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final accessible = MediaQuery.accessibleNavigationOf(context);
    final needsReview = result.reviewCount + result.legacyFailureCount > 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.startupMigratedNotice(count)),
        duration: const Duration(seconds: 8),
        persist: accessible,
        showCloseIcon: accessible,
        action: needsReview
            ? SnackBarAction(
                label: l10n.startupMigratedReview,
                onPressed: () => openReviewPage(context),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appRequestProvider, (_, next) => _handleRequest(next));
    return AdaptiveShell(
      controller: _controller,
      todayBuilder: (_) => const TodayPage(),
      shiftsBuilder: (_) => const ShiftsPage(),
      insightsBuilder: (_) => const InsightsPage(),
    );
  }
}
