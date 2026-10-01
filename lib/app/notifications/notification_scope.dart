import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/app_settings.dart';
import '../providers/providers.dart';
import 'app_notifications.dart';

/// Wires notifications into the running app (placed above the navigator):
///
/// * initialises the notification service after the first frame,
/// * renames the channels when the app or device language changes,
/// * after the start sequence, handles the notification that cold-started
///   the app (once), e.g. "Beenden" → finish sheet.
class NotificationScope extends ConsumerStatefulWidget {
  /// Wraps [child].
  const NotificationScope({super.key, required this.child});

  /// The app below.
  final Widget child;

  @override
  ConsumerState<NotificationScope> createState() => _NotificationScopeState();
}

class _NotificationScopeState extends ConsumerState<NotificationScope>
    with WidgetsBindingObserver {
  AppNotifications get _app => ref.read(appNotificationsProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_app.ensureInitialized());
    });
    ref
      ..listenManual(
        settingsProvider.select((s) => s.language),
        (_, _) => unawaited(_app.refreshChannelTexts()),
      )
      ..listenManual(bootstrapProvider, (_, next) {
        if (next.hasValue && !next.isLoading) {
          unawaited(_app.checkLaunchTap());
        }
      }, fireImmediately: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    unawaited(_app.refreshChannelTexts());
    // Re-post the notification in the new device language.
    if (ref.read(settingsProvider).language == AppLanguage.system &&
        ref.read(bootstrapProvider).hasValue) {
      unawaited(ref.read(activeShiftControllerProvider.notifier).reconcile());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
