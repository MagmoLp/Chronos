import 'package:flutter/material.dart';

/// Opens the settings screen.
Future<void> openSettings(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));

/// Settings. Placeholder until the Settings feature lands.
class SettingsPage extends StatelessWidget {
  /// Creates the page.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.shrink());
}
