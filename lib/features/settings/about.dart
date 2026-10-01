import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/providers.dart';
import '../../app/theme/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/share_service.dart';
import 'widgets/settings_group.dart';

bool _fontLicenseRegistered = false;

/// Registers the license of the Roboto font embedded in PDF timesheets
/// (bundled as an asset, so Flutter does not list it on its own).
void registerBundledFontLicense() {
  if (_fontLicenseRegistered) return;
  _fontLicenseRegistered = true;
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const ['Roboto'],
      await rootBundle.loadString('assets/fonts/Roboto_LICENSE.txt'),
    );
  });
}

/// Opens Flutter's license page with the app name and [version].
void openLicenses(BuildContext context, {String? version}) {
  registerBundledFontLicense();
  showLicensePage(
    context: context,
    applicationName: AppLocalizations.of(context).appTitle,
    applicationVersion: version,
  );
}

/// "Fehlerbericht teilen": shares the local error log as a text file, or
/// says that nothing was logged.
Future<void> shareErrorReport(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final log = ref.read(errorLogProvider);
  try {
    final content = await log.read();
    if (content.trim().isEmpty) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.aboutErrorReportEmpty)));
      return;
    }
    final info = await ref.read(appInfoServiceProvider).load();
    final share = ref.read(shareServiceProvider);
    final stamp = ref.read(clockProvider).today().toIso8601String();
    final file = await share.saveTextToTemp(
      'chronos_${l10n.aboutFileBase}_$stamp.txt',
      'Chronos ${info.fullVersion}\n\n$content',
    );
    await share.shareFile(
      file.path,
      mimeType: ShareMimeTypes.text,
      subject: l10n.aboutErrorReportSubject,
    );
  } on Object catch (e, st) {
    await log.record(e, st, context: 'errorReport');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
  }
}

/// The privacy policy in the app language (same content as privacy.html).
class PrivacyPage extends StatelessWidget {
  /// Creates the page.
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget heading(String value) => Padding(
      padding: const EdgeInsets.only(
        top: ChronosSpace.s24,
        bottom: ChronosSpace.s8,
      ),
      child: Semantics(
        header: true,
        child: Text(value, style: text.titleMedium),
      ),
    );
    Widget subheading(String value) => Padding(
      padding: const EdgeInsets.only(
        top: ChronosSpace.s12,
        bottom: ChronosSpace.s4,
      ),
      child: Text(value, style: text.titleSmall),
    );
    Widget body(String value) => Padding(
      padding: const EdgeInsets.only(bottom: ChronosSpace.s8),
      child: Text(
        value,
        style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
    Widget bullet(String value) => Padding(
      padding: const EdgeInsetsDirectional.only(
        start: ChronosSpace.s8,
        bottom: ChronosSpace.s4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: ChronosSpace.s8),
            child: Icon(Icons.circle, size: 6, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: ChronosSpace.s8),
          Expanded(
            child: Text(
              value,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutPrivacy)),
      body: SelectionArea(
        child: SettingsListView(
          children: [
            const SizedBox(height: ChronosSpace.s8),
            Text(
              l10n.privacyUpdated,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: ChronosSpace.s12),
            body(l10n.privacyIntro),
            heading(l10n.privacyShortTitle),
            body(l10n.privacyShortBody),
            heading(l10n.privacyStoredTitle),
            body(l10n.privacyStoredIntro),
            bullet(l10n.privacyStoredShifts),
            bullet(l10n.privacyStoredJobs),
            bullet(l10n.privacyStoredPayouts),
            bullet(l10n.privacyStoredSettings),
            bullet(l10n.privacyStoredErrorLog),
            const SizedBox(height: ChronosSpace.s4),
            body(l10n.privacyStoredNoAccess),
            heading(l10n.privacyExceptionsTitle),
            subheading(l10n.privacyAutoBackupTitle),
            body(l10n.privacyAutoBackupBody),
            subheading(l10n.privacyExportTitle),
            body(l10n.privacyExportBody),
            subheading(l10n.privacyRestoreTitle),
            body(l10n.privacyRestoreBody),
            heading(l10n.privacyPermissionsTitle),
            bullet(l10n.privacyPermissionNotifications),
            bullet(l10n.privacyPermissionBoot),
            const SizedBox(height: ChronosSpace.s4),
            body(l10n.privacyPermissionsNone),
            heading(l10n.privacyNoSharingTitle),
            body(l10n.privacyNoSharingBody),
            heading(l10n.privacyDeleteTitle),
            body(l10n.privacyDeleteBody),
            heading(l10n.privacyChangesTitle),
            body(l10n.privacyChangesBody),
            heading(l10n.privacyContactTitle),
            body(l10n.privacyContactBody),
          ],
        ),
      ),
    );
  }
}
