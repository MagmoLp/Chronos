import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/providers.dart';
import '../../core/format.dart';
import '../../domain/app_settings.dart';
import '../../domain/job.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/app_info.dart';
import '../export/export_sheet.dart';
import 'about.dart';
import 'data_actions.dart';
import 'goal_dialog.dart';
import 'jobs_page.dart';
import 'widgets/choice_segments.dart';
import 'widgets/settings_group.dart';

/// Opens the settings screen.
Future<void> openSettings(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));

/// Settings: general (language, theme), work (jobs, monthly goal, reminder),
/// notifications, data (export, backup, restore, delete) and about.
class SettingsPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final AppLifecycleListener _lifecycle;
  bool? _notificationsEnabled;
  AppInfo? _appInfo;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _checkNotifications);
    unawaited(_checkNotifications());
    unawaited(_loadAppInfo());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _checkNotifications() async {
    final enabled = await ref
        .read(notificationServiceProvider)
        .areNotificationsEnabled();
    if (mounted) setState(() => _notificationsEnabled = enabled);
  }

  Future<void> _loadAppInfo() async {
    try {
      final info = await ref.read(appInfoServiceProvider).load();
      if (mounted) setState(() => _appInfo = info);
    } on Object catch (e, st) {
      await ref.read(errorLogProvider).record(e, st, context: 'appInfo');
    }
  }

  Future<void> _openNotificationSettings() async {
    await ref.read(notificationServiceProvider).openNotificationSettings();
    await _checkNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final settingsCtl = ref.read(settingsProvider.notifier);
    final busy = ref.watch(dataControllerProvider);
    final active = ref.watch(activeJobsProvider).value ?? const <Job>[];
    final info = _appInfo;

    final goalCents = settings.monthlyGoalCents;
    final goalText = goalCents == null
        ? l10n.settingsGoalOff
        : settings.monthlyGoalType == MonthlyGoalType.limit
        ? l10n.settingsGoalLimitValue(fmt.money(goalCents))
        : l10n.settingsGoalGoalValue(fmt.money(goalCents));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.commonSettings),
        bottom: busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: SettingsListView(
        children: [
          SettingsGroup(
            title: l10n.settingsSectionGeneral,
            children: [
              SettingsControlTile(
                icon: Icons.language,
                title: l10n.settingsLanguage,
                child: ChoiceSegments<AppLanguage>(
                  segments: [
                    ChoiceSegment(
                      value: AppLanguage.system,
                      label: l10n.settingsLanguageSystem,
                    ),
                    ChoiceSegment(
                      value: AppLanguage.de,
                      label: l10n.settingsLanguageGerman,
                    ),
                    ChoiceSegment(
                      value: AppLanguage.en,
                      label: l10n.settingsLanguageEnglish,
                    ),
                  ],
                  selected: settings.language,
                  onChanged: (v) => unawaited(settingsCtl.setLanguage(v)),
                ),
              ),
              SettingsControlTile(
                icon: Icons.brightness_6_outlined,
                title: l10n.settingsTheme,
                child: ChoiceSegments<AppThemeMode>(
                  segments: [
                    ChoiceSegment(
                      value: AppThemeMode.system,
                      label: l10n.settingsThemeSystem,
                    ),
                    ChoiceSegment(
                      value: AppThemeMode.light,
                      label: l10n.settingsThemeLight,
                    ),
                    ChoiceSegment(
                      value: AppThemeMode.dark,
                      label: l10n.settingsThemeDark,
                    ),
                  ],
                  selected: settings.themeMode,
                  onChanged: (v) => unawaited(settingsCtl.setThemeMode(v)),
                ),
              ),
            ],
          ),
          SettingsGroup(
            title: l10n.settingsSectionWork,
            children: [
              ListTile(
                leading: const Icon(Icons.work_outline),
                title: Text(l10n.settingsJobs),
                subtitle: _JobsSummary(active: active),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const JobsPage()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(l10n.settingsGoal),
                subtitle: Text(goalText),
                onTap: () => showMonthlyGoalDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.alarm),
                title: Text(l10n.settingsReminder),
                subtitle: Text(
                  settings.reminderEnabled
                      ? l10n.settingsReminderHours(settings.reminderHours)
                      : l10n.settingsReminderOff,
                ),
                onTap: () => showReminderDialog(context),
              ),
            ],
          ),
          SettingsGroup(
            title: l10n.settingsSectionNotifications,
            children: [
              Semantics(
                onTapHint: l10n.settingsNotificationsOpen,
                child: ListTile(
                  leading: Icon(
                    _notificationsEnabled == false
                        ? Icons.notifications_off_outlined
                        : Icons.notifications_outlined,
                    color: _notificationsEnabled == false
                        ? scheme.error
                        : null,
                  ),
                  title: Text(switch (_notificationsEnabled) {
                    null => l10n.commonLoading,
                    true => l10n.settingsNotificationsOn,
                    false => l10n.settingsNotificationsOffTitle,
                  }),
                  subtitle: _notificationsEnabled == null
                      ? null
                      : Text(
                          _notificationsEnabled!
                              ? l10n.settingsNotificationsOnHint
                              : l10n.settingsNotificationsOff,
                        ),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: _openNotificationSettings,
                ),
              ),
            ],
          ),
          SettingsGroup(
            title: l10n.settingsSectionData,
            children: [
              ListTile(
                enabled: !busy,
                leading: const Icon(Icons.ios_share),
                title: Text(l10n.dataExport),
                subtitle: Text(l10n.dataExportSubtitle),
                onTap: () => showExportSheet(context),
              ),
              ListTile(
                enabled: !busy,
                leading: const Icon(Icons.backup_outlined),
                title: Text(l10n.dataBackupCreate),
                subtitle: Text(l10n.dataBackupCreateSubtitle),
                onTap: () => createBackup(context, ref),
              ),
              ListTile(
                enabled: !busy,
                leading: const Icon(Icons.settings_backup_restore),
                title: Text(l10n.dataBackupRestore),
                subtitle: Text(l10n.dataBackupRestoreSubtitle),
                onTap: () => restoreBackup(context, ref),
              ),
              ListTile(
                enabled: !busy,
                iconColor: scheme.error,
                textColor: scheme.error,
                leading: const Icon(Icons.delete_forever_outlined),
                title: Text(l10n.dataDeleteAll),
                subtitle: Text(
                  l10n.dataDeleteAllSubtitle,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                onTap: () => deleteAllData(context, ref),
              ),
            ],
          ),
          SettingsGroup(
            title: l10n.settingsSectionAbout,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.aboutVersion),
                subtitle: Text(
                  info == null
                      ? l10n.commonLoading
                      : l10n.aboutVersionValue(info.version, info.buildNumber),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(l10n.aboutPrivacy),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PrivacyPage()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(l10n.aboutLicenses),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openLicenses(context, version: info?.fullVersion),
              ),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: Text(l10n.aboutErrorReport),
                subtitle: Text(l10n.aboutErrorReportSubtitle),
                onTap: () => shareErrorReport(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Catering · 15,00 €/h" (one job) or "2 Jobs".
class _JobsSummary extends ConsumerWidget {
  const _JobsSummary({required this.active});

  final List<Job> active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (active.length != 1) return Text(l10n.settingsJobsCount(active.length));
    final job = active.single;
    final rates = ref.watch(jobRatesProvider(job.id)).value;
    final rate = rates == null
        ? null
        : currentRate(rates, ref.watch(currentDateProvider));
    if (rate == null) return Text(job.name);
    return Text(
      l10n.settingsJobsOne(job.name, Fmt.of(context).rate(rate.centsPerHour)),
    );
  }
}
