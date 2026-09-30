# Code audit (v1.0.0)

> Raw research output from the Chronos analysis on 2026-09-30 (English). Line numbers refer to commit 9a52779 (v1.0.0). Summary and plan: [../UMBAUPLAN.md](../UMBAUPLAN.md).


## Summary

**Overall health:** the app has about 2,300 lines of hand-written Dart (plus generated l10n) using Provider + shared_preferences. The code is readable. Every AnimationController and TextEditingController is disposed correctly and there are no stream or listener leaks. Structurally it is still a prototype:
- business logic (rounding, minimum duration, overnight handling, entry creation) lives inside widgets
- no domain or data layer, no dependency injection (hidden `StorageService()` / `NotificationService()` singletons), zero tests
- money is `double`; timestamps are local ISO strings with no offset; the whole log is one JSON string in shared_preferences.

**It does not build on current Flutter stable (3.47.5), verified.** `pub get` fails because of `intl ^0.19.0`, and after relaxing that there is a `CardTheme` compile error. Gradle 8.9 / AGP 8.7.0 / Kotlin 2.1.0 are below Flutter's hard minimums (8.14 / 8.11.1 / 2.2.20). Commit 3dba3ea downgraded intl and `CardThemeData` on purpose to fit an older local SDK.

**Most severe correctness bugs:**
1. The wage field strips the German decimal comma: typing "12,50" stores 1250 €/h (verified).
2. The wage is not stored per entry, so changing it silently re-prices all historic, paid entries and the running session.
3. One malformed JSON value locks the app at startup on a raw "Startup Error" screen (verified).
4. Stop clears the persisted session before the entry is saved, so there are paths that lose data.
5. Quarter-hour rounding is off by ±1 h on DST days (verified with TZ=Europe/Berlin). The next switch is 25 Oct 2026.

**The three known bugs are root-caused:**
- Delete-all: hard-coded German literals in settings_screen.dart.
- Landscape: the Home screen is a non-scrollable column of about 500 dp of fixed-height content. It overflows by 246–318 dp in landscape, which matches the reported 284.
- Dark/light: light mode was never implemented. MaterialApp only gets a dark theme, there is no toggle, and 140 colour constants are hard-coded.

**Performance:** TimerProvider fires `notifyListeners()` once per second for the whole session, including when the app is paused (measured). The entire HomeScreen rebuilds every second (61 builds/min) with Opacity/ClipRect digit transitions. The ongoing notification is re-posted every 15 s (240/h), each costing several IPC calls plus a SystemUI re-render. The work log is a non-lazy list with one AnimationController per entry. There are no wakelocks or foreground services.

**UX/design:** buttons, nav items and the paid checkbox are custom GestureDetector widgets instead of Material components, so they have no semantics and some touch targets are 28 dp. There is no responsive layout code at all. The language is forced to German on first start, and number and date formats are inconsistent. These explain much of the "klobig" feel.

## Tooling notes

Flutter SDK installed into the scratchpad (git clone --depth 1 -b stable -> Flutter 3.47.5, Dart 3.13.4, framework rev 6a19cca564, 2026-09-17); bootstrap + artifact download took ~2 min, no network problems (only google-analytics telemetry was blocked by the proxy; analytics then disabled). The repo was never modified: the project was exported with `git archive HEAD` into scratchpad/proj and all work happened there (repo `git status` clean at the end).

1) `flutter pub get` on the unmodified pubspec FAILS on current stable: "Because chronos depends on flutter_localizations from sdk which depends on intl ^0.20.3, intl ^0.20.3 is required. So, because chronos depends on intl ^0.19.0, version solving failed." (The lock file shows the owner builds with a Flutter ~3.24–3.27-era SDK: collection 1.18.0, leak_tracker 10.0.5, intl 0.19.0, `sdks: flutter >=3.24.0`.) In the scratch copy only, intl was relaxed to `any` (resolved 0.20.3).

2) `flutter analyze` (repo analysis_options): 25 issues = 1 ERROR `argument_type_not_assignable` lib/theme/app_theme.dart:61 (CardTheme -> must be CardThemeData), 22x deprecated `withOpacity` (home_screen 2, settings_screen 5, work_log_screen 3, app_theme 2, animated_button 1, animated_card 8, custom_bottom_nav 1), 1x use_build_context_synchronously home_screen.dart:290, 1x unnecessary_brace_in_string_interps work_entry.dart:45. With a stricter lint set (scratch only): +3 discarded_futures (timer_provider.dart:72, work_log_screen.dart:339, :351), +2 unawaited_futures (work_log_screen.dart:263, :306), +16 prefer_const_constructors (disabled in repo analysis_options.yaml), +1 avoid_catches_without_on_clauses (main.dart:46).

3) The repo has no test/ directory. I wrote throw-away tests in the scratch copy (after patching CardTheme->CardThemeData there):
 - Layout (widget tests, dpr 2.625, 24dp status bar): bottom overflow 246 dp at 915x412 landscape, 298 dp at 800x360, 318 dp at 780x360 with a 16dp gesture inset (the reported 284 falls in this range); ~140 dp bottom overflow at 360x640 portrait; 249 dp at 360x740 with textScale 1.3; no overflow at 1280x800 tablet. Caveat: the Flutter test font has square glyphs that are wider than Roboto, so the horizontal overflows it also reported (13–174 px) and part of the portrait numbers are inflated by extra text wrapping. The landscape numbers are reliable because no wrapping happens there.
 - DST (TZ=Europe/Berlin): the rounding function copied from home_screen.dart gives 2026-10-25 10:05 -> 09:00 and 2026-03-29 17:04 -> 18:00 (normal day 10:05 -> 10:00).
 - Wage formatter: typing 1,2,',',5,0 yields field "1250", parsed 1250.0.
 - Corrupted prefs: work_entries='{"oops":1}' -> loadEntries throws _TypeError, and main() would show the Startup Error screen. active_session='not-a-date' did not throw in the test because mock SharedPreferences.getString returned null for that key setup, but DateTime.parse at storage_service.dart:84 has no guard.
 - Theme: with platformBrightness=light the app theme is Brightness.dark; MaterialApp.darkTheme=null, themeMode=system.
 - Localization: with locale en, the settings screen still renders 'Datenverwaltung', 'Alle Einträge löschen' and the dialog title 'Alle Daten löschen?'.
 - Delete-all dialog with a 320 dp keyboard at 360x740: 216 px bottom overflow (the magnitude is inflated by the test font).
 - Performance (counters injected into the scratch copy; timer running, 60 s of pumped frames): 60 notifyListeners, 61 HomeScreen.build, 366 AnimatedDigit.build (amounts were 0,00; more digits in real use). After lifecycle=paused: framesEnabled=false, 60 notifyListeners/min, 0 builds. The notification `show` count in the test (60/min) is an ARTIFACT: flutter_test does not fake DateTime.now(), so elapsed.inSeconds stayed 0 and the `_lastNotificationUpdate == 0` branch fired every tick. With the real clock the code posts every 15 s (timer_provider.dart:69).
 
4) Also inspected: the flutter_local_notifications 18.0.1 Android sources in the pub cache (each show() -> getNotificationChannel + PendingIntent + notify), current Flutter Gradle plugin minimums (DependencyVersionChecker.kt: error below Gradle 8.14, AGP 8.11.1, KGP 2.2.20; FlutterExtension.kt: compile/target 36, minSdk 24, NDK 28.2.13676358), and the shared_preferences_android 2.4.7 async API default backend (DataStore). No device or emulator was available, so nothing was profiled on real hardware.

## Known bugs – root causes

### Localization: delete-all section and dialog stay German when the language is English

**Root cause:** The whole data-management section and the delete-all dialog use hard-coded German string literals; the ARB files have no keys for them. Only the Cancel and Delete buttons are localized, so the dialog is mixed-language in English. The confirmation also only accepts the German word 'Löschen' or 'Loeschen', so English users must type a German word with an umlaut. Verified in a widget test with locale en.

**Locations:** lib/screens/settings_screen.dart:182 ('Datenverwaltung'), :203 ('Alle Einträge löschen'), :210 (subtitle), :242 (SnackBar 'Alle Einträge gelöscht'), :271 (isValid only 'Löschen'/'Loeschen'), :280 (title), :288 (warning), :293 (instruction), :302 (hintText); localized only at :322 and :335; missing keys in lib/l10n/app_de.arb and app_en.arb. Same class of bug elsewhere: lib/services/notification_service.dart:13-14 (channel name/description), :57-58 ('Arbeite', 'Verdient: ... €'), settings_screen.dart:44 ('Chronos v1.0').

**Fix:** Add ARB keys (dataManagement, deleteAllEntries, deleteAllEntriesSubtitle, deleteAllDialogTitle, deleteAllDialogWarning, deleteAllTypeToConfirm with a {word} placeholder, deleteAllConfirmWord = 'LÖSCHEN'/'DELETE', allEntriesDeleted). Compare case-insensitively against the localized word, or better, replace type-to-confirm with a normal confirmation plus 'export first' and an undo snackbar. Localize the notification texts (pass strings from the UI layer or store the locale) and read the version via package_info_plus. Set `nullable-getter: false` in l10n.yaml and remove the ~60 `l10n?.x ?? 'German fallback'` literals so missing keys fail at compile time. Add a widget test that pumps every screen in `en` and asserts no German text appears.

### Landscape: Home screen shows 'BOTTOM OVERFLOWED BY 284 PIXELS'

**Root cause:** HomeScreen's body is a non-scrollable `Column(mainAxisAlignment: spaceEvenly)` with four fixed-height children totalling about 500 dp:
- large earnings card ≈172 dp: padding 28 all round, 18sp label, 16 dp gap, 56sp headlineLarge digits
- total card ≈148 dp: 40sp digits
- timer pill ≈118 dp: 52sp text plus 20 dp vertical padding
- start/stop row ≈64 dp
In landscape the available height is about 200–250 dp: screen height (360–412) minus status bar (24), AppBar (56) and the custom bottom nav, which is always 80 dp (8+8 margin, 8+8 padding, 48 dp item). spaceEvenly cannot shrink anything, so the column overflows. Measured: 246 dp at 915x412, 298 dp at 800x360, 318 dp at 780x360 with a gesture inset. Nothing in lib/ adapts: grep finds no LayoutBuilder, OrientationBuilder, FittedBox, SingleChildScrollView or MediaQuery-based sizing, despite the note 'App ist zwar responsiv gebaut'. The same layout has no slack in portrait either: tests also overflow at 360x640 and at textScale 1.3. The money Rows have no FittedBox, so large totals or big font scales can also overflow horizontally.

**Locations:** lib/screens/home_screen.dart:54-80 (SafeArea > Padding > Column spaceEvenly), :90-112 (HighlightCard padding 28, font sizes), :115-143 (timer pill, fontSize 52), :145-192 (button row); lib/widgets/custom_bottom_nav.dart:38-58 (fixed 80 dp bar); lib/widgets/animated_money_display.dart:25-44 (unconstrained Row).

**Fix:** Build Home as a responsive layout:
- Use LayoutBuilder/window size class. In compact-height or landscape, use a two-pane Row: counters on the left, timer and buttons on the right.
- Wrap each pane in a scroll view with ConstrainedBox(minHeight) as a safety net.
- Wrap the money displays in `FittedBox(fit: BoxFit.scaleDown)`.
- Derive font sizes and paddings from the available size instead of constants.
- Replace the custom 80 dp bottom bar with Material 3 NavigationBar in portrait and NavigationRail in landscape/tablets.
- Constrain content width (about 560–640 dp) on large screens.
- Add widget/golden tests for 360x640, 412x915, 800x360, 915x412, 1280x800 and textScale 1.0/1.3/2.0 that fail on any RenderFlex overflow.

### Dark/Light mode: display problem when switching (tester note truncated)

**Root cause:** Theme switching was never implemented, so no switch can work.
(a) MaterialApp only gets `theme: AppThemeData.darkTheme`. There is no `darkTheme:` and no `themeMode:`, so the app is always dark regardless of the setting or the system (verified: platform light still gives Brightness.dark).
(b) Settings has no theme control, although the l10n keys theme/darkMode/lightMode exist unused and SettingsProvider.themeMode/setTheme are dead code. `AppSettings.theme` is persisted but never read.
(c) There is no light palette at all. AppThemeData only defines dark constants (#121212 / #1E1E1E / #3B82F6), not even the spec's Navy #001F3F / Anthracite #2D2D2D.
(d) Colours bypass the theme in 140 places across 10 files, plus 7 `Colors.white`: every Scaffold, card, dialog and text sets `AppThemeData.*` directly, and the date/time pickers force `ColorScheme.dark`. Even if a light ThemeData were passed in, the UI would come out mixed dark/light: dark surfaces with light-theme default text, snackbars and ink.
(e) android res values/styles.xml and values-night/styles.xml are identical Theme.Black with a #121212 splash, and no system-bar icon brightness is set for a light variant.
Whatever the tester toggled (the system dark mode, or looking for the promised in-app switch), nothing consistent happens. The exact symptom from the truncated note should still be confirmed on a device.

**Locations:** lib/main.dart:81-82; lib/providers/settings_provider.dart:23-30, 53-57 (unused); lib/models/app_settings.dart:3, 12; lib/screens/settings_screen.dart:34-50 (no theme section); lib/theme/app_theme.dart:10-167 (dark-only constants and getter); hard-coded colours e.g. home_screen.dart:37, 205-245, work_log_screen.dart:24, 457-460, 481-484, 505-508, 656-659, 680-683, 704-707; android/app/src/main/res/values/styles.xml and values-night/styles.xml (identical).

**Fix:** Introduce a real design system:
- Define two ColorSchemes: dark from Navy/Anthracite, light from Light Blue/White (hand-tuned or ColorScheme.fromSeed plus overrides).
- Add a ThemeExtension for semantic tokens (success, danger, money accent, card border).
- Replace every static `AppThemeData.<color>` with `Theme.of(context).colorScheme` or the extension.
- Remove the forced ColorScheme.dark in the pickers.
- Wire `MaterialApp(theme: light, darkTheme: dark, themeMode: settings.themeMode)` with a 3-way setting (system/light/dark, default system), and add a SegmentedButton or switch in Settings.
- Set status/nav-bar overlay styles per brightness (AppBarTheme.systemOverlayStyle or AnnotatedRegion).
- Give values-night a different splash colour.
- Add golden tests for both themes.

### Tablet compatibility untested

**Root cause:** There is no adaptive layout code. At 1280x800 a widget test shows no overflow, but:
- The HighlightCards shrink-wrap their content (Column's default crossAxisAlignment is center and the containers have no width), so the two counters sit as small islands in a large empty dark screen, and their width changes whenever the digit count changes.
- The work log's AnimatedListItem rows and the bottom-nav pill stretch edge to edge (1280 dp lines).
- There is no NavigationRail, no two-pane layout (live counter plus log side by side) and no max content width.
- Dialogs have fixed content and are fine.
- In landscape tablets the fixed 80 dp bottom bar also wastes vertical space.

**Locations:** lib/screens/home_screen.dart:54-80; lib/widgets/animated_card.dart:141-156 (HighlightCard with no width); lib/screens/work_log_screen.dart:111-114; lib/widgets/custom_bottom_nav.dart:38-58; lib/main.dart:107-131.

**Fix:** Use window size classes: compact gets bottom NavigationBar; medium/expanded gets NavigationRail plus a two-pane layout (Home counters | Log) and max-width constrained lists. Test on 7" and 10" emulators in both orientations and with a foldable profile, then produce the Play tablet screenshots. Add golden tests at 800x1280 and 1280x800.


## Bug catalogue

### B01 · critical · l10n — Decimal comma in wage input is silently dropped: '12,50' becomes 1250 €/h

- **Location:** `lib/screens/settings_screen.dart:384`
- **Evidence:** `FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))` only admits '.', so the comma is filtered out before onChanged. The `value.replaceAll(',', '.')` at :404 is therefore dead code. Verified: typing 1,2,',',5,0 produces field '1250' and parsed 1250.0. onChanged saves every keystroke immediately (:403-408, settings_provider.dart:59-63). The hint text at app_de.arb:39 even tells German users to use '15.50'.
- **Impact:** A German or Austrian user typing 12,50 (the natural input; many German keypads only offer ',') gets 1250 €/h. Combined with B02, every past entry, the open total and the live counter become wildly wrong without any warning.
- **Fix:** Parse with `NumberFormat.decimalPattern(locale)` or accept both separators. Use a formatter like `^\d{0,4}([.,]\d{0,2})?$`, validate a plausible range (e.g. 1–500), and commit on 'Save'/blur rather than per keystroke. Show the value formatted for the locale (12,50 in de) and add unit tests for '12,50', '12.50', '15', ',5', ''.

### B02 · high · money-math — Hourly wage not stored per entry: changing the wage retroactively re-prices all entries and the running session

- **Location:** `lib/models/work_entry.dart:18-21`
- **Evidence:** WorkEntry has no wage field. `calculateEarnings(double hourlyWage)` is always called with the *current* settings wage: work_entries_provider.dart:14-15 (open total), work_log_screen.dart:106 (every row, paid ones included), home_screen.dart:33-34 (live counter for the whole elapsed session).
- **Impact:** After a raise from 12 to 13 €/h, last year's paid entries show amounts that were never paid, the open total changes, and a session running during the change is fully re-priced. Worse with B01. Users cannot track multiple jobs or rates.
- **Fix:** Snapshot `wageCents` on every entry and on the active session at start. Keep a wage history (validFrom) and, optionally, jobs with their own rates. Editing an entry may offer to update its wage. Migration: snapshot the current wage and flag the entries as migrated (see data_model_notes).

### B03 · high · persistence — Any malformed persisted value locks the app at startup permanently

- **Location:** `lib/services/storage_service.dart:48-49`
- **Evidence:** `final List<dynamic> jsonList = json.decode(jsonString); return jsonList.map((json) => WorkEntry.fromJson(json)).toList();` has no try/catch. fromJson uses unchecked casts and DateTime.parse (work_entry.dart:60-63). Settings (:63) and active session (:84, DateTime.parse) are the same. main.dart:46-57 catches everything and shows `Text('Startup Error: $e')` with no recovery. Verified: work_entries='{"oops":1}' makes loadEntries throw _TypeError.
- **Impact:** A single bad element (a partial write, a future schema change, restoring an old backup, manual tampering) makes the app unusable. The only way out is Android 'clear storage', which destroys all work records. The user sees a raw English exception text.
- **Fix:** Parse per element with try/catch. Keep valid entries, quarantine invalid raw JSON (backup key or file) and surface it with an export/repair option. Validate fields (end > start, non-null id). Add a schema_version. Replace the startup error screen with a localized recovery screen (export raw data / reset). Add unit tests with corrupted fixtures.

### B04 · high · persistence — Stop clears the session before the entry is saved; saving depends on the widget still being mounted

- **Location:** `lib/screens/home_screen.dart:250-296`
- **Evidence:** `final endTime = await timer.stop();` (:251) removes 'active_session' and cancels the notification (timer_provider.dart:44-48). Only afterwards, and only `if (... && context.mounted)` (:255), is the entry built and saved (:281). If saveEntry throws (e.g. B03-style corrupted list: getWorkEntries is re-read inside saveWorkEntry, storage_service.dart:21-29), the exception escapes after the session is gone. The SnackBar at :290 uses context after an await without a mounted check (analyzer: use_build_context_synchronously).
- **Impact:** Paths that permanently lose a worked shift: a save exception, the process being killed in the gap, or HomeScreen being unmounted before :255. Rounding, the minimum-duration rule and entry creation live in a StatelessWidget, so they cannot be unit-tested.
- **Fix:** Move to a `SessionService.stopAndSave()` in the domain/data layer. Compute the entry, persist it (ideally in the same DB transaction that clears the active session), then clear the session and notification. The UI only awaits the result and shows feedback if still mounted. Never make persistence conditional on `context.mounted`.

### B05 · high · time/date — Quarter-hour rounding is off by ±1 h on DST switch days (next: 25 Oct 2026)

- **Location:** `lib/screens/home_screen.dart:198-206`
- **Evidence:** `final base = DateTime(time.year, time.month, time.day); return base.add(Duration(minutes: rounded));` adds *absolute* minutes to local midnight. Verified with TZ=Europe/Berlin: 2026-10-25 10:05 rounds to 09:00; 2026-03-29 17:04 rounds to 18:00.
- **Impact:** On switch days, stopped sessions get wrong start/end times. For shifts that span the switch (typical catering night shifts, e.g. 22:00–06:00 or 01:00–09:00), the saved duration and pay are off by one hour. The next switch is in 25 days.
- **Fix:** `DateTime(t.year, t.month, t.day, 0, rounded)` (the constructor normalises minute overflow in local time), or do all rounding on UTC epoch minutes and convert for display. Add unit tests run under TZ=Europe/Berlin and Europe/Vienna for both switch dates.

### B06 · high · ui-layout — Home overflows in landscape, on small phones and with larger system font (known bug)

- **Location:** `lib/screens/home_screen.dart:54-80`
- **Evidence:** About 500 dp of fixed-height children sit in a non-scrollable spaceEvenly Column. Test: 246–318 dp bottom overflow in landscape, and overflow at 360x640 and at textScale 1.3 (see known_bug_root_causes).
- **Impact:** Content is clipped behind yellow/black stripes in landscape. Users with small phones or accessibility font sizes, which is common, cannot see the Start/Stop buttons.
- **Fix:** Responsive two-pane / scrollable layout with FittedBox counters (see known_bug_root_causes).

### B07 · high · ui-layout — Dark/Light mode does not exist although README, spec and store notes promise it (known bug)

- **Location:** `lib/main.dart:82`
- **Evidence:** Only `theme: AppThemeData.darkTheme`; no darkTheme/themeMode; no toggle in Settings; 140 hard-coded colour constants; setTheme/themeMode are dead code (settings_provider.dart:23-30, 53-57).
- **Impact:** The advertised feature is missing, and any partial fix would produce a mixed dark/light UI.
- **Fix:** Rebuild theming with light and dark ColorSchemes plus a ThemeExtension, and wire up themeMode (see known_bug_root_causes).

### B08 · medium · l10n — Hard-coded German strings: delete-all section/dialog (known bug), notification, version label

- **Location:** `lib/screens/settings_screen.dart:182-302`
- **Evidence:** 'Datenverwaltung', 'Alle Einträge löschen', 'Alle Daten löschen?', 'Zum Bestätigen gebe das Wort "Löschen" ein:', and a confirm word check that only accepts 'Löschen'/'Loeschen' (:271). notification_service.dart:13-14, 57-58: channel 'Arbeitssession', title 'Arbeite', body 'Verdient: 12.50 €'. settings_screen.dart:44 'Chronos v1.0' (pubspec says 1.0.0+1).
- **Impact:** English UI is mixed with German. English users must type a German word with an umlaut to delete data. The notification is always German, with an English decimal point.
- **Fix:** ARB keys for everything, a localized confirm word, localized notification strings, and package_info_plus for the version (see known_bug_root_causes).

### B09 · medium · l10n — Money/number/date formatting inconsistent and not locale-aware

- **Location:** `lib/widgets/animated_money_display.dart:20-35`
- **Evidence:** The live counter always renders ',' as the decimal separator (`Text(',')` at :31-34) and a suffix '€', even in English. The log uses `earnings.toStringAsFixed(2)` giving '12.50 €' (work_log_screen.dart:231), and the notification also uses '.' (notification_service.dart:35). Nothing has thousands separators. Dates are hand-built 'dd.MM.yyyy' (work_entry.dart:28-36, work_log_screen.dart:242-255) while the time pickers use `TimeOfDay.format(context)` (12 h in en).
- **Impact:** German users see '12,50 €' on Home and '12.50 €' in the log. English users see German-style money on Home. The app looks unpolished.
- **Fix:** Centralize formatting: `NumberFormat.currency(locale:, symbol: '€')`, `DateFormat.yMd(locale)`, `DateFormat.Hm/jm`. Build the rolling-digit widget on top of the formatted string (treating non-digit characters as static glyphs).

### B10 · medium · l10n — UI language forced to German on first launch regardless of device language

- **Location:** `lib/models/app_settings.dart:11`
- **Evidence:** `this.language = AppLanguage.german` default; main.dart:81 `locale: settings.locale` is always non-null, so Flutter's device-locale resolution is bypassed.
- **Impact:** English-speaking (and all non-German) Play users get a German app on first start.
- **Fix:** Store language as nullable/'system'. Pass `locale: null` for system and use supportedLocales with an 'en' fallback. Optionally add Android 13 per-app language support (localeConfig).

### B11 · medium · logic — Manual add/edit: end ≤ start silently becomes an overnight shift; no validation

- **Location:** `lib/screens/work_log_screen.dart:551-553`
- **Evidence:** `if (!endDateTime.isAfter(startDateTime)) { endDateTime = endDateTime.add(const Duration(days: 1)); }` (same at :750-752). start == end becomes 24 h. The ARB key `endAfterStart` exists but is unused. No maximum duration, future dates allowed.
- **Impact:** A typo (end 08:00 instead of 18:00 with start 16:00) creates a 16 h shift and inflates the open total, with no warning.
- **Fix:** Explicit overnight toggle or 'ends next day' hint, confirmation when duration > 12 h or ≤ 0, and inline validation errors. Shared form widget and logic for add/edit (the two dialogs are ~160 duplicated lines).

### B12 · medium · logic — No overlap or duplicate detection between entries (manual vs timer, or manual vs manual)

- **Location:** `lib/providers/work_entries_provider.dart:24-27`
- **Evidence:** `saveEntry` persists anything. No check against existing intervals or the running session.
- **Impact:** The same hours can be logged twice (e.g. a forgotten stop, then a manual correction) and counted twice in the open total and the payout.
- **Fix:** Detect overlapping intervals in the repository and warn/offer merge. Block manual entries overlapping the active session.

### B13 · medium · state — Double-tapping Save in the Add dialog creates duplicate entries and can pop the main route

- **Location:** `lib/screens/work_log_screen.dart:535-577`
- **Evidence:** The Save button stays enabled during `await context.read<WorkEntriesProvider>().saveEntry(entry)` (:568). Each tap builds a new `Uuid().v4()` (:562), so both taps save. Afterwards both call `Navigator.pop(context)` (:570). The second pop runs after the dialog route is already popping, so it targets the next present route (MainScreen), which can leave a blank screen. The Edit dialog has the same pop issue (:766-768).
- **Impact:** Duplicate shifts (double pay in totals) and, occasionally, a black screen, both more likely on a laggy device.
- **Fix:** Disable the button and show progress while saving (a local `_saving` flag), pop exactly once via the result pattern (`Navigator.pop(context, entry)` and let the caller save), and make the repository idempotent per id.

### B14 · medium · logic — Silent, non-configurable quarter-hour rounding and discarding of short sessions

- **Location:** `lib/screens/home_screen.dart:195-206`
- **Evidence:** Remainder < 7 rounds down, otherwise up. 7 min past rounds UP although it is closer to :00, and seconds are ignored. Sessions whose rounded duration is < 15 min are discarded (:256-273): e.g. 08:08–08:21 becomes 08:15–08:15 and is lost, while 08:06–08:14 (8 min) is saved as 15 min. The live counter shows unrounded money, so the total jumps after Stop.
- **Impact:** Users lose or gain up to about 15 min per shift without seeing why. Money 'disappears' from the counter at Stop. Employers' rules differ (exact minutes, 5-min, 15-min).
- **Fix:** Make the rounding policy a setting (none/5/10/15 min; nearest/up/down; minimum duration). Apply it in a tested domain function, show the rounded times in the stop confirmation, and keep the raw times on the entry.

### B15 · medium · logic — No protection against forgotten sessions (days-long timers)

- **Location:** `lib/providers/timer_provider.dart:32-37`
- **Evidence:** A session runs until Stop is pressed. There is no reminder, maximum or auto-stop. The timer shows `elapsed.inHours` unbounded (home_screen.dart:116), and Stop saves e.g. a 72 h entry without warning.
- **Impact:** Forgetting to press Stop after a shift is the most common real-world error. It produces absurd entries and a wrong open total.
- **Fix:** Reminder notification after N hours (configurable, e.g. 10 h), a warning in the stop dialog for > 12 h with editable end time, and an optional 'end of shift' time set at start.

### B16 · medium · notifications — Notification permission requested before runApp blocks first frame; denial not handled

- **Location:** `lib/services/notification_service.dart:24-28`
- **Evidence:** main.dart:27-29 `await notificationService.init()` runs before runApp. init() awaits `requestNotificationsPermission()`, which completes only when the user answers the system dialog. Any PlatformException there goes to the 'Startup Error' screen (main.dart:46-57). There is no rationale, no state for a denied permission, and no settings shortcut.
- **Impact:** On first launch (Android 13+), the permission dialog appears over the blank #121212 splash and the app UI is not shown until the user answers. Denied users silently lose the ongoing notification.
- **Fix:** runApp immediately. Ask for permission contextually on the first Start with a short rationale, remember the denial, and show an unobtrusive hint with a button to the system settings. Wrap plugin calls in try/catch.

### B17 · medium · notifications — Ongoing notification repeatedly re-posted; stale earnings; returns after user dismissal

- **Location:** `lib/providers/timer_provider.dart:66-77`
- **Evidence:** `if (currentSecond - _lastNotificationUpdate >= 15 || _lastNotificationUpdate == 0)` calls show() with fresh details every 15 s (the comment says 30 s). The future is discarded (:72). No foreground service, so once Android freezes or kills the process the 'Verdient' text goes stale while the native chronometer keeps counting. Android 14+ lets users swipe away non-FGS ongoing notifications, and this code re-posts within 15 s.
- **Impact:** The notification shows a wrong amount after the app is frozen. Users cannot get rid of it except by stopping. SystemUI work every 15 s (see performance).
- **Fix:** Post once on start (and on wage change) with static content, e.g. '15,00 €/h · seit 08:15', plus the chronometer and a 'Stop' action. Do not re-post periodically. If live earnings in the notification are a must, compute them natively or use a foreground service with the matching Play declaration (heavier).

### B18 · medium · notifications — Notification small icon uses the full-colour adaptive launcher icon

- **Location:** `lib/services/notification_service.dart:18`
- **Evidence:** `AndroidInitializationSettings('@mipmap/ic_launcher')`. On API 26+ this resolves to the adaptive icon XML (mipmap-anydpi-v26/ic_launcher.xml, transparent background).
- **Impact:** The status bar shows a white blob or square instead of a recognizable glyph (Android masks small icons to alpha). Adaptive icons as small icons are also a known cause of a SystemUI crash loop on Android 8.0.
- **Fix:** Add a monochrome white-on-transparent `ic_stat_chronos` vector drawable, reference it, and add `res/raw/keep.xml` (tools:keep) because resource shrinking cannot see names referenced from Dart.

### B19 · medium · security — Accessibility: custom controls have no semantics; paid checkbox is a 28 dp touch target

- **Location:** `lib/screens/work_log_screen.dart:159-179`
- **Evidence:** Paid 'checkbox' is a GestureDetector plus AnimatedContainer (width/height 28, :163-164), with no checked-state semantics. AnimatedButton (animated_button.dart:89-120), AnimatedIconButton (animated_button.dart:211-240, no tooltip/label for Settings and Add), nav items (custom_bottom_nav.dart:107-165) and language tiles (settings_screen.dart:103-143) are raw GestureDetectors: no button role, no focus, no keyboard support. There are no Semantics widgets anywhere (grep).
- **Impact:** TalkBack users cannot use the app. The Play pre-launch report will flag missing labels and small touch targets. Mis-taps on the small checkbox open the options sheet instead.
- **Fix:** Use Material components (FilledButton, IconButton with tooltip, Checkbox/InkWell with a 48 dp target, NavigationBar, SegmentedButton/Switch), or wrap custom widgets in Semantics with labels and states.

### B20 · medium · logic — Wage saved on every keystroke; intermediate values applied; empty or 0 silently ignored

- **Location:** `lib/screens/settings_screen.dart:403-408`
- **Evidence:** `onChanged: (value) { final parsed = double.tryParse(...); if (parsed != null && parsed > 0) widget.onWageChanged(parsed); }`. Typing '13.50' after select-all writes 1, 13, 13.5, 13.50 to prefs and re-renders everything each time. Clearing the field keeps the old wage while showing an empty field. There is no upper bound. The field never re-syncs if the provider value changes (initState only, :363-369).
- **Impact:** The running session and all totals flicker through wrong values while typing, and the persisted value can be an unintended intermediate if the user leaves mid-edit.
- **Fix:** Explicit save/confirm with validation messages, a debounce if live preview is wanted, and range limits.

### B21 · low · notifications — Notification wage only synced from HomeScreen.build: wage changed from the Log tab is ignored

- **Location:** `lib/screens/home_screen.dart:31`
- **Evidence:** `timer.setHourlyWage(settings.hourlyWage);` is a side effect inside build. When the user opens Settings from the Work Log tab, HomeScreen is not mounted (AnimatedSwitcher shows only one tab), so TimerProvider keeps the old wage.
- **Impact:** The notification keeps showing earnings at the old wage until the user returns to Home. Side effects in build are also an anti-pattern.
- **Fix:** TimerProvider/SessionService should depend on the settings repository (ProxyProvider or stream), not be fed from a build method.

### B22 · low · state — Restored or resumed session shows 00:00:00 and 0,00 € for up to 1 s, then all digits roll

- **Location:** `lib/providers/timer_provider.dart:25-30`
- **Evidence:** loadActiveSession sets _startTime and starts the timer, but `_elapsed` is only computed in the tick callback (:59). After resume from a frozen process it is stale until the next tick.
- **Impact:** A visible glitch on every cold start or resume during a shift: a zero flash, then a cascade of digit animations. It contributes to the clunky feel.
- **Fix:** Do not store elapsed. Compute `now - startTime` at build time (e.g. from a clock in the UI ticker).

### B23 · low · time/date — Session and entry timestamps stored as local wall-clock strings without offset

- **Location:** `lib/services/storage_service.dart:76`
- **Evidence:** `startTime.toIso8601String()` for a local DateTime has no 'Z' and no offset (also work_entry.dart:51-53). `DateTime.parse` at :84 reinterprets it in the *current* zone.
- **Impact:** A time-zone change (travel) or the ambiguous repeated DST hour plus an app restart while a session runs shifts the session start by the offset difference, so elapsed time and pay are wrong by up to hours. Entries silently change meaning after moving time zones.
- **Fix:** Persist UTC epoch milliseconds plus the tz offset at creation. Convert to local only for display.

### B24 · low · time/date — Device clock set backwards produces negative timer/earnings rendering

- **Location:** `lib/screens/home_screen.dart:115-119`
- **Evidence:** `_elapsed = DateTime.now().difference(_startTime!)` can go negative. The timer shows strings like '00:-1:-5' because padLeft is applied to negatives. AnimatedMoneyDisplay splits '-0.42' and renders '-' as an animated 'digit' (animated_money_display.dart:20-23). Stop then produces end < start and discards the session as 'too short'.
- **Impact:** Rare, but it produces confusing UI and a lost session.
- **Fix:** Clamp to zero, detect the clock jump and ask the user to correct the times, and store the monotonic start where possible.

### B25 · low · ui-layout — Rolling-digit display: digits unkeyed, wrong roll direction, fixed offset, no scaling

- **Location:** `lib/widgets/animated_money_display.dart:25-54`
- **Evidence:** Digits are built by index without keys, so when the digit count changes (9,99 to 10,00) the widgets are re-matched by position. The incoming digit slides up from +30 px (animated_digit.dart:24) while the outgoing one slides down; the spec asks for 'von oben nach unten'. The 30 px offset is the same for 56 sp and 40 sp. The Row is unconstrained, so large totals overflow horizontally.
- **Impact:** Janky, 'klobig' animation and possible overflow for large open totals or larger fonts.
- **Fix:** A dedicated RollingNumber widget: keys per decimal place from the right, SlideTransition/FadeTransition inside ClipRect, offset relative to line height, tabular figures, wrapped in FittedBox.

### B26 · low · ui-layout — Timer uses fontFamily 'RobotoMono', which is not bundled

- **Location:** `lib/screens/home_screen.dart:137`
- **Evidence:** `fontFamily: 'RobotoMono'` but pubspec.yaml:25-27 declares no fonts, so Flutter silently falls back to the default font.
- **Impact:** The intended monospace look is absent. Width may jitter with non-tabular fonts.
- **Fix:** Use `fontFeatures: [FontFeature.tabularFigures()]`, or bundle the font or use google_fonts with the assets bundled offline.

### B27 · low · logic — Date pickers hard-limited to 2020–2030

- **Location:** `lib/screens/work_log_screen.dart:453-454`
- **Evidence:** `firstDate: DateTime(2020), lastDate: DateTime(2030)` in Add (:453-454) and Edit (:652-653). initialDate is `now` or `entry.date`.
- **Impact:** From 2031 showDatePicker asserts (initialDate after lastDate), breaking Add Entry. Entries before 2020 cannot be edited. Future dates are allowed.
- **Fix:** Use a firstDate of about 10 years back and lastDate = today (+1 day for overnight), and clamp initialDate.

### B28 · low · logic — Edit dialog cannot represent entries longer than 24 h and re-derives overnight logic

- **Location:** `lib/screens/work_log_screen.dart:624-626`
- **Evidence:** Edit keeps only `TimeOfDay`s and `entry.date`, then recomputes end on the same day (+1 day if not after start).
- **Impact:** Editing any field of a >24 h (forgotten-timer) entry silently shortens it. Paid entries can be edited without any warning.
- **Fix:** Edit full start and end DateTimes with explicit end date. Warn when editing paid entries.

### B29 · low · state — Bottom-sheet context of a popped route reused to open follow-up dialogs

- **Location:** `lib/screens/work_log_screen.dart:321`
- **Evidence:** `builder: (context) => SafeArea(...)` shadows the screen context. At :338-339 and :350-351 it calls `Navigator.pop(context); _showEditEntryDialog(context, entry);`, i.e. uses the context of the route being removed (analyzer: discarded_futures at :339, :351).
- **Impact:** It only works because the exit animation keeps the element alive briefly. It is fragile and can throw 'deactivated widget's ancestor' under timing changes (e.g. disabled animations).
- **Fix:** Return an action from the sheet (`Navigator.pop(context, EntryAction.edit)`) and open the dialog from the screen context after `await showModalBottomSheet`.

### B30 · low · ui-layout — Log list items have no keys

- **Location:** `lib/screens/work_log_screen.dart:104-107`
- **Evidence:** `items.add(_buildEntryItem(...))` builds an AnimatedListItem (StatefulWidget with AnimationController and AnimatedContainer) without `key: ValueKey(entry.id)` (:155). Month headers are interleaved in the same list.
- **Impact:** After a delete or insert, state and colour animations shift to the neighbouring row (paid-highlight flashes on the wrong entry).
- **Fix:** Key rows by entry id and headers by month. Use ListView.builder/SliverList (see performance).

### B31 · low · logic — Sort order contradicts the spec; ties unstable

- **Location:** `lib/providers/work_entries_provider.dart:49-50`
- **Evidence:** `_entries.sort((a, b) => b.startTime.compareTo(a.startTime))` is newest first. The spec: 'der aktuellste Eintrag ist immer ganz unten' (newest at the bottom, scroll up for older). Dart's sort is not stable, so equal start times can swap on reload.
- **Impact:** Deviates from the owner's own spec, and rows may jump.
- **Fix:** Decide deliberately (a reverse ListView anchored at the bottom if following the spec). Add a secondary sort key (id).

### B32 · low · state — start() not guarded; double tap restarts the session

- **Location:** `lib/providers/timer_provider.dart:32-37`
- **Evidence:** No `if (isRunning) return;`. The UI disables the button only after `await _storage.saveActiveSession` and notifyListeners (:34-36), so a second tap in that window overwrites _startTime and recreates the Timer.
- **Impact:** Minor loss of a few ms to seconds and duplicated side effects. It is a symptom of missing domain guards.
- **Fix:** Guard in the service, set state synchronously before awaiting, and debounce the buttons.

### B33 · low · state — Unawaited futures swallow errors; no global error handling

- **Location:** `lib/screens/work_log_screen.dart:263`
- **Evidence:** `entries.togglePaidStatus(entry.id);` (:263, :306) and `_notificationService.showWorkSessionNotification(...)` (timer_provider.dart:72) are not awaited. No FlutterError.onError / PlatformDispatcher.onError is set anywhere.
- **Impact:** Storage or plugin failures are invisible (no feedback, no log), and a failed toggle looks like it succeeded until reload.
- **Fix:** Await and handle errors with user feedback. Install global error handlers that log locally (optionally with opt-in crash reporting). Enable the unawaited_futures and discarded_futures lints.

### B34 · low · ui-layout — Delete-all dialog content not scrollable; overflows with keyboard open

- **Location:** `lib/screens/settings_screen.dart:274-339`
- **Evidence:** AlertDialog content is a Column(min) with two paragraphs and a TextField, without `scrollable: true`. Widget test at 360x740 with a 320 dp keyboard: 216 px bottom overflow (inflated by the test font, but there is no scroll fallback).
- **Impact:** On small phones or landscape the input or buttons can be hidden behind the keyboard.
- **Fix:** `AlertDialog(scrollable: true)` or a SingleChildScrollView. A simpler confirm flow also removes the text field.

### B35 · low · ui-layout — Tab switching destroys screen state; Android back on the Log tab exits the app

- **Location:** `lib/main.dart:98-116`
- **Evidence:** AnimatedSwitcher with KeyedSubtree(ValueKey(_currentIndex)) disposes the previous tab after the fade. No PopScope/back handling to return to tab 0.
- **Impact:** The log scroll position is lost on every switch. Back exits unexpectedly from tab 2.
- **Fix:** NavigationBar with IndexedStack or go_router StatefulShellRoute; back returns to Home first.

### B36 · low · ui-layout — SnackBars have near-black text on red/green

- **Location:** `lib/screens/home_screen.dart:264-295`
- **Evidence:** SnackBar text defaults to colorScheme.onInverseSurface, which for `ColorScheme.dark` falls back to `surface` (#1E1E1E) (verified in the Flutter SDK color_scheme.dart:1326, snack_bar.dart:974-976). The app sets backgrounds AppThemeData.error #EF4444 and success #22C55E: about 4.4:1 contrast on red.
- **Impact:** The error snackbar ('Zeit zu kurz...') is hard to read, and the look is inconsistent.
- **Fix:** Set SnackBarThemeData (behavior floating, contentTextStyle, colours) in the theme, and use semantic colours from the ThemeExtension.

### B37 · low · ui-layout — Custom bottom nav ignores left/right insets and has long labels

- **Location:** `lib/widgets/custom_bottom_nav.dart:38-45`
- **Evidence:** Only `MediaQuery.of(context).padding.bottom` is applied. Tab labels reuse 'Aktueller Verdienst' and 'Arbeitszeit-Protokoll' (main.dart:123, 127), which are long for a pill label at large font scales.
- **Impact:** In landscape with side navigation or a cutout, the bar sits under system UI. It can overflow horizontally at big font scales.
- **Fix:** Use Material NavigationBar/NavigationRail with short dedicated labels ('Live', 'Protokoll').

### B38 · low · security — Implicit Android Auto Backup contradicts the privacy policy

- **Location:** `android/app/src/main/AndroidManifest.xml:6-9`
- **Evidence:** No android:allowBackup / dataExtractionRules, so the default is enabled: FlutterSharedPreferences.xml (all entries and wage) may be backed up to the user's Google Drive. privacy.html states that the data 'werden ausschließlich lokal auf deinem Gerät gespeichert und verlassen dieses niemals'.
- **Impact:** The privacy statement and Play Data-safety answers may be inaccurate. On the positive side, backups are the only thing protecting testers from data loss today.
- **Fix:** Decide explicitly: keep backup (recommended, with fullBackupContent/dataExtractionRules including the new DB) and adjust the privacy text, or disable it and offer export/import.

### B39 · low · logic — 'Aktueller Verdienst' is per-session, but the spec asks for today's total; timer placement differs from spec

- **Location:** `lib/screens/home_screen.dart:33`
- **Evidence:** `currentEarnings = timer.getCurrentEarnings(...)` is 0 when no session runs. The spec says 'Betrag der aktuell verdienten Summe dieses Tages' and puts the elapsed-time window centred *below* the start/stop buttons (the code puts it above, :75-77). The spec also asks for switches for language and dark mode in Settings.
- **Impact:** With two shifts on the same day (common in catering, split shifts) the counter resets. It deviates from the owner's own spec.
- **Fix:** Show 'Heute' (today's saved entries plus the running session) and optionally 'Diese Schicht'. Revisit the layout in the redesign.

### B40 · low · logic — Notification throttle comment and sentinel wrong

- **Location:** `lib/providers/timer_provider.dart:68-69`
- **Evidence:** The comment says 'every 30 seconds' but the code uses 15. `_lastNotificationUpdate == 0` is used as the 'never posted' sentinel, but it is also assigned `currentSecond`, which can be 0 or ≤ 0 (e.g. after a clock change), causing a re-post every tick or no updates at all.
- **Impact:** Minor, but it shows fragile logic (and was the reason the test harness observed a post every tick).
- **Fix:** Use a nullable DateTime `_lastPostedAt` (or remove periodic posting entirely, see B17).

### B41 · low · build — Dead code and unused resources

- **Location:** `lib/widgets/animated_button.dart:126`
- **Evidence:** The PrimaryActionButton class is unused. `_buildLanguageOption(value:)` is unused (settings_screen.dart:99). `isLoading` branches are unreachable because providers are loaded before runApp (home_screen.dart:24-28, settings_screen.dart:30-31). ARB keys theme, darkMode, lightMode, workEntries, totalTime, minutes, endAfterStart are unused. `WorkEntry.date` is redundant with startTime (work_entry.dart:3). The README lists theme selection that does not exist.
- **Impact:** Confusing maintenance and hidden unfinished features.
- **Fix:** Remove or implement during the rewrite. Keep the README in sync.


## Performance & background

### 1 Hz Dart timer + notifyListeners for the whole session, including when backgrounded

- **Location:** `lib/providers/timer_provider.dart:55-63`
- **Evidence:** `Timer.periodic(const Duration(seconds: 1), ...)` sets `_elapsed`, calls `_maybeUpdateNotification()`, then `notifyListeners()`. There is no WidgetsBindingObserver or AppLifecycle handling anywhere in lib/ (grep). Measured in a widget test: 60 notifyListeners/min in foreground and 60/min after lifecycle=paused. Frames are suppressed while paused (framesEnabled=false, 0 HomeScreen builds), but the Dart isolate still wakes every second until Android freezes or kills the process. That is 86,400 wakeups per 24 h of session.
- **Impact:** Constant CPU wakeups in the background on devices or versions without an aggressive app freezer. It also drives the notification re-posting below. Not individually heavy, but completely unnecessary: the model only needs startTime.
- **Fix:** Remove ticking from the model: store only startTime (UTC) and compute elapsed on demand. Put the 1 Hz tick in a small UI widget (StatefulWidget with a Timer or Ticker) that stops on AppLifecycleState.paused/hidden and when TickerMode is off, and rebuilds only the text widgets. Align ticks to whole seconds of the start time.

### Entire HomeScreen rebuilds every second

- **Location:** `lib/screens/home_screen.dart:19-34`
- **Evidence:** `context.watch` of SettingsProvider, TimerProvider and WorkEntriesProvider at the top of HomeScreen.build means every tick rebuilds the Scaffold, AppBar, 2 HighlightCards (AnimatedContainer), the timer pill, 2 AnimatedButtons and ~6–14 AnimatedDigit widgets. Measured: 61 HomeScreen builds and 366 AnimatedDigit builds per minute (with 0,00 amounts). Each build also runs `entries.totalOpenEarnings()`, which allocates a new filtered list and folds over all entries (work_entries_provider.dart:11-15), so O(n) allocations per second, plus `List.unmodifiable` copies on every `entries` access (:9). It also rebuilds while hidden under the Settings route, because routes below stay mounted.
- **Impact:** Steady per-second layout, paint and GC work while the app is visible. On low-end devices this shows up as frame drops in the scroll and animation of the other widgets.
- **Fix:** Split into small widgets and use `context.select`/Selector so only the elapsed and earnings texts listen to the ticker. Cache the open total in the repository (recompute on entry changes only). Add RepaintBoundary around the live counters. Use const constructors (re-enable the const lints).

### Rolling-digit transitions use Opacity + ClipRect + Transform per digit

- **Location:** `lib/widgets/animated_digit.dart:15-40`
- **Evidence:** Each changed digit runs a 300 ms AnimatedSwitcher. The outgoing and incoming children each get AnimatedBuilder > ClipRect > Transform.translate > Opacity. A fractional Opacity forces an offscreen layer (saveLayer) per animating child. At 15 €/h the cent digits of both counters change about every 2.4 s, simultaneously, and higher digits cascade. Each transition renders 18 frames at 60 Hz or 36 at 120 Hz.
- **Impact:** Several layer-heavy animations per second on the main screen. This is the most visible rendering cost while the app is open with a running timer, and battery-relevant on 120 Hz screens.
- **Fix:** Implement one RollingNumber widget with SlideTransition/FadeTransition (FadeTransition uses an OpacityLayer without rebuilds) inside a single ClipRect per number, or a CustomPainter. Animate only digits that changed and only while the route is visible (TickerMode). Consider disabling it when MediaQuery.disableAnimations is set.

### Ongoing notification re-posted every 15 s (240/h) with full rebuild of the notification

- **Location:** `lib/providers/timer_provider.dart:66-77`
- **Evidence:** show() runs every 15 s (the comment claims 30 s) for as long as the process is alive, foreground or background: 5,760 posts per 24 h of session. Each post (flutter_local_notifications 18.0.1, FlutterLocalNotificationsPlugin.createNotification/setupNotificationChannel) does a platform-channel call, a getNotificationChannel binder IPC, PendingIntent creation and NotificationManager.notify, and SystemUI then re-inflates the notification (shade, lock screen, AOD, OEM 'live' surfaces). The chronometer already runs natively (`usesChronometer: true`), so the only reason to re-post is the earnings text.
- **Impact:** There is no wakelock, no foreground service and no exact alarm in the app, so this periodic SystemUI churn plus the 1 Hz wakeups is the most plausible source of the reported system-wide lag on some OEM skins. Verify with `adb shell dumpsys notification --noredact`, Perfetto (system_server and SystemUI CPU) and `dumpsys batterystats`.
- **Fix:** Post once on start and on wage change with static text plus chronometer and a Stop action. Never re-post on a timer.

### Blocking startup sequence and permission dialog before the first frame

- **Location:** `lib/main.dart:14-45`
- **Evidence:** main() awaits sequentially: SharedPreferences init, settings load, full entries JSON decode, notification plugin initialize, `requestNotificationsPermission()` (which waits for the user's answer on first launch), and active-session load, all before runApp.
- **Impact:** Longer splash on every cold start (scales with log size). On first launch the UI is invisible until the permission dialog is answered.
- **Fix:** runApp immediately with a lightweight loading state. Load data in parallel (Future.wait) inside a bootstrap provider. Request the permission on first Start.

### O(n) read-modify-write of the whole log on every tap

- **Location:** `lib/services/storage_service.dart:21-36`
- **Evidence:** saveWorkEntry and deleteWorkEntry do: getWorkEntries (json.decode of the full list), modify, `_saveWorkEntries` (json.encode of the full list), SharedPreferences.setString (Android rewrites the entire FlutterSharedPreferences.xml). Then WorkEntriesProvider calls loadEntries(), which decodes the whole list again (work_entries_provider.dart:24-46). So each paid toggle costs 2 full decodes, 1 full encode and a full XML file rewrite.
- **Impact:** Fine for 50 entries. It grows linearly with an 'unlimited' log (the spec): years of daily entries means hundreds of KB parsed per tap, causing noticeable latency on low-end phones.
- **Fix:** SQLite (drift or sqflite) with row-level updates and indices, exposing reactive queries (streams) to the UI. At minimum, keep the in-memory list as the source of truth and persist asynchronously.

### Work log is a non-lazy ListView with one AnimationController per row, rebuilt on every tab switch, toggle and wage keystroke

- **Location:** `lib/screens/work_log_screen.dart:85-114`
- **Evidence:** `ListView(children: items)` builds all rows up front. Each AnimatedListItem (animated_card.dart:182-266) creates an AnimationController, AnimatedContainer, ClipRRect, Material and InkWell. The whole list is recreated when switching tabs (main.dart:110-116 disposes and recreates screens), on every paid toggle, and on every wage keystroke (WorkLogScreen watches SettingsProvider, :20). The month grouping map is rebuilt each time (:90-109).
- **Impact:** With N entries that is about 25N widgets and N tickers per build. Tab switches and toggles get progressively janky as the history grows.
- **Fix:** ListView.builder or CustomScrollView with SliverList and sticky month headers, keyed rows, stateless rows using plain InkWell (no per-row AnimationController), precomputed groups in the repository, and IndexedStack or keep-alive for tabs.

### Whole MaterialApp rebuilds on any settings change, including each wage keystroke

- **Location:** `lib/main.dart:66`
- **Evidence:** ChronosApp does `context.watch<SettingsProvider>()`. setHourlyWage notifies on every keystroke (settings_screen.dart:403-408), so MaterialApp, Localizations and all routes rebuild. `AppThemeData.darkTheme` is a getter that constructs a new ThemeData on every call (app_theme.dart:35), which AnimatedTheme then deep-compares.
- **Impact:** Typing in the wage field rebuilds the entire app on each character. This is wasted work but not severe.
- **Fix:** `context.select((SettingsProvider s) => (s.locale, s.themeMode))`, static final ThemeData instances, and commit the wage on save or debounce.

### Tab switch cross-fade renders two full screens with opacity for 300 ms

- **Location:** `lib/main.dart:110-116`
- **Evidence:** AnimatedSwitcher with the default FadeTransition keeps the outgoing screen and builds the incoming one, both composited with opacity layers. Combined with the non-lazy log build, the first frame of the switch is expensive.
- **Impact:** A visible hitch on tab changes with a large log.
- **Fix:** NavigationBar with IndexedStack (no rebuild) and a cheap fade-through, or no animation for tab changes.

### Per-item clipping and custom ink in cards

- **Location:** `lib/widgets/animated_card.dart:98-116`
- **Evidence:** Every AnimatedCard and AnimatedListItem wraps content in ClipRRect > Material(transparent) > InkWell (also at :234-263). HighlightCard is an AnimatedContainer that is recreated every second on Home.
- **Impact:** Extra clip layers per row. Minor on its own, but it adds up in long lists.
- **Fix:** Use Card/Material with shape and clipBehavior, Ink decorations, and a plain Container where nothing animates.

### No lifecycle-aware behaviour at all

- **Location:** `lib/main.dart:1-133`
- **Evidence:** grep finds no WidgetsBindingObserver, AppLifecycleListener or didChangeAppLifecycleState in lib/.
- **Impact:** The app cannot pause work in the background, refresh on resume (it shows stale elapsed values until the next tick), or flush state before being killed.
- **Fix:** Add an AppLifecycleListener in the session layer: on resume, recompute from startTime and refresh the notification once; on pause, stop the UI tickers.


## Architecture

### Business logic lives in widgets

**Problem:** Quarter-hour rounding, the minimum-duration rule and entry creation live in HomeScreen (home_screen.dart:195-296). Overnight handling and entry construction are duplicated in the Add and Edit dialogs (work_log_screen.dart:421-585 vs 621-783, about 160 near-identical lines). Earnings math is spread over WorkEntry, TimerProvider and screens. Date formatting is implemented three times (work_entry.dart:26-45, work_log_screen.dart:242-255).

**Recommendation:** Introduce a domain layer of pure, unit-tested Dart: SessionService (start/stop/stopAndSave), RoundingPolicy, EarningsCalculator (int cents), EntryValidator (overlap, >24 h, end<start), Formatters. Screens only render state and dispatch intents.

### Hidden singletons and self-constructed dependencies block testing

**Problem:** StorageService and NotificationService are factory singletons (storage_service.dart:11-13, notification_service.dart:4-6). Every provider news them up internally (`final StorageService _storage = StorageService();`). Time comes from `DateTime.now()` everywhere. Nothing can be faked in tests.

**Recommendation:** Constructor injection behind interfaces (EntryRepository, SettingsRepository, SessionRepository, NotificationGateway, Clock via package:clock). Wire them with Provider/ProxyProvider or Riverpod. Tests then use an in-memory DB and a fake clock.

### State design: derived state stored, side effects in build, god-watch at the top

**Problem:** TimerProvider stores `_elapsed` (derived) and mutates it 1x/s. The wage is pushed into TimerProvider from HomeScreen.build (home_screen.dart:31). HomeScreen and WorkLogScreen watch whole providers. Stop is orchestrated by a widget across two providers.

**Recommendation:** Immutable state objects (e.g. SessionState {startUtc, wageCents, jobId}) exposed via ChangeNotifier/StateNotifier or streams. Derived values are computed with select. Cross-provider dependencies are expressed explicitly (ProxyProvider or Riverpod ref.watch). Keep a small UI-level ticker for live text only.

### Persistence: one JSON blob in shared_preferences

**Problem:** The entire log is a single string (storage_service.dart:4, 43-56). There is no schema version, validation, transaction, index or query capability. Every mutation is O(n) and double-decoded. One bad element bricks startup. The legacy SharedPreferences API is slated for replacement by SharedPreferencesAsync/WithCache.

**Recommendation:** Move to SQLite via drift (typed schema, migrations with tests, reactive queries, in-memory DB for tests), or sqflite if a lighter dependency is preferred. Avoid unmaintained stores (Hive v2, Isar). Keep settings in SharedPreferencesWithCache (legacy backend) or a settings table. Add JSON/CSV export and import.

### Money as double, time as local strings

**Problem:** Earnings are computed as `inMinutes/60.0 * wage` in double and rounded per row with toStringAsFixed. Row sums can differ from the displayed total by cents, and binary rounding (e.g. 1.005 prints 1.00) applies. Timestamps are local ISO strings without offset (B23), and DST handling is buggy (B05).

**Recommendation:** Store int cents and int seconds or minutes. Use one documented rounding rule (e.g. round half-up per entry, then sum). Store UTC epoch ms plus the tz offset at creation. Put all conversions in one tested module and run the tests under several TZ values in CI.

### Design system is a set of static dark constants and hand-rolled widgets

**Problem:** There are 140 references to static AppThemeData colours. The custom AnimatedButton, AnimatedIconButton, AnimatedCard, AnimatedListItem and CustomBottomNavigation are GestureDetector re-implementations without semantics, focus, proper ripple or state layers, and with a 28 dp touch target. This is the main source of the 'klobig' feel and of the accessibility gaps. The palette does not match the owner's spec (Navy/Anthracite, Light Blue/White).

**Recommendation:** Material 3 with light and dark ColorSchemes built from the spec colours, plus a ThemeExtension for semantic tokens and a small component set built on Material widgets (FilledButton, IconButton, Card, NavigationBar/Rail, SegmentedButton, Switch, Checkbox, DatePicker/TimePicker themed centrally). Motion via standard transitions (fade-through, shared axis) instead of custom scale-on-press everywhere.

### No responsive/adaptive layout infrastructure

**Problem:** There is zero LayoutBuilder, MediaQuery sizing, FittedBox or scroll fallback on Home (grep). Fixed 56/52/40 sp font sizes and 28 dp paddings. The note 'App ist zwar responsiv gebaut' is not backed by the code.

**Recommendation:** Window size classes (compact/medium/expanded), an adaptive scaffold (NavigationBar vs NavigationRail), two-pane layouts on wide screens, max content widths, and text-scale-aware sizing. Golden tests per size class.

### Localization setup

**Problem:** `nullable-getter` defaults to true, so every lookup is `l10n?.x ?? 'German literal'` (about 60 fallbacks). Hard-coded German strings exist in settings and notifications. Locale and supportedLocales are duplicated in main.dart instead of using AppLocalizations.localizationsDelegates/supportedLocales. The default language is not the device language.

**Recommendation:** l10n.yaml: `nullable-getter: false` (and `untranslated-messages-file`). No string literals in widgets (add a custom lint or a CI grep for umlauts in lib/screens). Use ARB placeholders and plurals for durations, intl formatting everywhere, system locale by default, and optionally Android 13 per-app language.

### Background/notification architecture

**Problem:** A Dart Timer drives both UI and notification updates. There is no foreground service, so behaviour depends on OEM process freezing. The notification is German-only, has no actions, and its text goes stale. The permission is requested at startup.

**Recommendation:** Treat the session as a persisted fact (startUtc), not a running process. Notification: a single post with native chronometer plus a static rate/start text and a 'Stop' action (flutter_local_notifications action handled on the next app open or via a background callback that writes the stop request). Only consider a foreground service (Android 14 requires a foregroundServiceType and Play declaration) if the owner insists on live money in the notification. Optionally add a reminder after N hours and a home-screen widget or Quick Settings tile later.

### No tests, no CI

**Problem:** There is no test/ directory. flutter_test is declared but unused. The build is broken on current Flutter without anyone noticing. The DST and comma bugs would have been caught by trivial unit tests.

**Recommendation:** Unit tests for rounding (multi-TZ), earnings (cents), validation, JSON migration (v1 fixtures incl. corrupted). Widget/golden tests for all screens at 4 sizes, 2 themes, 2 locales and textScale 1.0/2.0. An integration_test for start, kill, relaunch, stop. GitHub Actions running flutter analyze (stricter lints), flutter test with TZ matrix, and flutter build appbundle.

### Error handling and observability

**Problem:** A single catch-all in main shows a raw exception. Unawaited futures elsewhere swallow errors. There is no logging.

**Recommendation:** Result-type or exception handling at repository boundaries with user-facing localized errors. FlutterError.onError / PlatformDispatcher.onError that log to a local ring buffer the user can export (keeps the 'no data leaves the device' promise), or opt-in crash reporting disclosed in the privacy policy.

### Lint configuration hides problems

**Problem:** analysis_options.yaml disables prefer_const_constructors and prefer_const_literals_to_create_immutables. flutter_lints 4.0.0 (6.0.0 available) is used. 22 deprecated withOpacity calls.

**Recommendation:** Upgrade flutter_lints, and enable unawaited_futures, discarded_futures, use_build_context_synchronously (default), prefer_const_*, avoid_dynamic_calls, always_declare_return_types. Migrate withOpacity to withValues(alpha:).

### Navigation structure

**Problem:** Tabs are swapped by an AnimatedSwitcher that destroys state. Settings is pushed from two places. There is no back handling.

**Recommendation:** go_router with StatefulShellRoute (or NavigationBar plus IndexedStack) and Settings as a route. Predictive-back compatible (PopScope).

### Feature model too narrow for the target users (catering)

**Problem:** The data model cannot express breaks, multiple jobs or employers with different rates, surcharges (night/Sunday/holiday), tips, notes, pay periods or payouts. 'Paid' is a per-entry boolean toggled one by one. Totals are only 'open', with no per-week or per-month stats, no export for the employer, and no backup.

**Recommendation:** Design the new schema now so these can be added without another migration: jobs, wage_rates (validFrom), entries (breakMinutes, wageCentsSnapshot, surchargeRuleIds, tipsCents, note, source), payouts (period, paidAt, entry links). Bulk 'mark period as paid'. Month and week summaries. CSV/PDF export.

### README/spec drift

**Problem:** The README advertises theme selection and a feature set that the code does not have, and its project tree omits files. The spec (App Spezifikationen.docx) asks for today's earnings, newest-at-bottom ordering, the timer below the buttons, and switches in settings, all of which differ from the implementation.

**Recommendation:** Write a short v2 product spec with the owner (what 'current earnings' means, ordering, rounding policy) and keep the README generated from it and accurate.


## Android build & config

### Project does not resolve/compile on current Flutter stable

- **Location:** `pubspec.yaml:14; lib/theme/app_theme.dart:61`
- **Problem:** Verified with Flutter 3.47.5. `intl: ^0.19.0` conflicts with flutter_localizations, which requires intl ^0.20.3, so `flutter pub get` fails. After relaxing that, `cardTheme: CardTheme(` is a compile error (CardThemeData? expected). Commit 3dba3ea deliberately downgraded both (intl ^0.20.2 to ^0.19.0, CardThemeData to CardTheme) to fit an older local SDK (lock: flutter >=3.24.0).
- **Fix:** Upgrade the local Flutter to current stable. Set `intl: any` (let flutter_localizations pin it) and use CardThemeData. Migrate the 22 withOpacity calls to withValues(alpha:). Commit a `.fvmrc` or document the Flutter version (or use FVM) so builds are reproducible.

### Gradle/AGP/Kotlin below current Flutter hard minimums

- **Location:** `android/gradle/wrapper/gradle-wrapper.properties:5; android/settings.gradle:21-22; android/build.gradle (ext.kotlin_version)`
- **Problem:** Gradle 8.9, AGP 8.7.0 and Kotlin 2.1.0 are used. Current Flutter's Gradle plugin throws DependencyValidationException below Gradle 8.14, AGP 8.11.1 and KGP 2.2.20 (flutter_tools/gradle DependencyVersionChecker.kt:96-109), with warnings below 9.1 / 9.0.1 / 2.3.20. It also requires JDK 17.
- **Fix:** Bump the Gradle wrapper to ≥8.14 (ideally 9.x), AGP ≥8.11.1, Kotlin ≥2.2.20. Consider migrating to the current `flutter create` template (settings.gradle.kts / build.gradle.kts, `layout.buildDirectory` instead of the deprecated `buildDir` in android/build.gradle).

### SDK levels, NDK and Play target-API requirement

- **Location:** `android/app/build.gradle:35-36, 63-65`
- **Problem:** compileSdk, minSdk and targetSdk are inherited from whichever (old) Flutter SDK builds the app. ndkVersion is pinned to 27.0.12077973, while current Flutter defaults to compile/target 36, minSdk 24 and NDK 28.2.13676358 (FlutterExtension.kt:23-42). Google Play raises the required targetSdk every year (API 35 for new apps and updates since 31 Aug 2025; check the Play Console for the 2026 deadline). An AAB built with a ~3.24-era SDK may target too low an API for production.
- **Fix:** Build with current Flutter and remove the hard-coded ndkVersion (or align it with flutter.ndkVersion). Check the built AAB with `bundletool dump manifest` before requesting production access. Note that minSdk 24 drops Android 5–6 testers (they keep v1).

### Java/Kotlin bytecode target 1.8

- **Location:** `android/app/build.gradle:38-46`
- **Problem:** `sourceCompatibility/targetCompatibility JavaVersion.VERSION_1_8` and `jvmTarget = '1.8'` produce 'obsolete source/target' warnings with modern JDKs and AGP. Desugaring is correctly enabled (required by flutter_local_notifications).
- **Fix:** Use JavaVersion.VERSION_17 and jvmTarget '17' (or 11 as in the Flutter template). Keep coreLibraryDesugaring and update desugar_jdk_libs.

### proguard-rules.pro referenced but missing; resource shrinking vs. dynamically referenced icons

- **Location:** `android/app/build.gradle:70-76`
- **Problem:** `minifyEnabled true`, `shrinkResources true`, `proguardFiles ..., 'proguard-rules.pro'`, but no android/app/proguard-rules.pro is tracked in git, so a clean clone relies on AGP tolerating the missing file. flutter_local_notifications resolves icons by name at runtime (getIdentifier), which the resource shrinker cannot see. That is harmless today (ic_launcher is referenced from the manifest) but will strip a dedicated notification icon.
- **Fix:** Commit a proguard-rules.pro (even if empty, plus the plugin's recommended keep rules if scheduled notifications are used later). Add res/raw/keep.xml with tools:keep for notification drawables.

### Release signing is unconditional

- **Location:** `android/app/build.gradle:52-59, 72`
- **Problem:** Release always uses signingConfigs.release built from key.properties. Without that file (CI, a fresh clone, another machine), release builds fail with missing signing properties.
- **Fix:** Use release signing only if key.properties exists (otherwise debug-sign or fail with a clear message). Document the upload-key location and backup (already done by the owner) in the README.

### Template debug/profile manifests absent

- **Location:** `android/app/src/ (no debug/ or profile/ folder tracked)`
- **Problem:** The standard Flutter template adds src/debug/AndroidManifest.xml and src/profile/AndroidManifest.xml with the INTERNET permission, which the Flutter tool needs to talk to the running app (hot reload, DevTools). They are not in the repository. (The release manifest correctly lacks INTERNET.)
- **Fix:** Re-add them from `flutter create` so a clean clone can be debugged and profiled (needed to profile the performance issues).

### Manifest and theme resources

- **Location:** `android/app/src/main/AndroidManifest.xml:1-31; res/values*/styles.xml`
- **Problem:** - The deprecated `package=` attribute is still present although `namespace` is set.
- No explicit allowBackup/dataExtractionRules/fullBackupContent (see B38).
- No android:localeConfig (Android 13 per-app language).
- LaunchTheme and NormalTheme use the legacy `@android:style/Theme.Black.NoTitleBar` and are identical in values and values-night (no light splash).
- `windowLayoutInDisplayCutoutMode` sits in base values although it requires API 27 (lint).
- The adaptive icon has a transparent background layer and no <monochrome> layer (Android 13 themed icons).
- There is no dedicated notification small icon (B18).
- **Fix:** Remove `package=`, add backup rules and localeConfig, and base styles on Theme.Material/NoActionBar or the core-splashscreen API with light and night variants. Move API-27 attributes to values-v27. Give the adaptive icon a solid background plus a monochrome layer, and add ic_stat_* notification icons.

### gradle.properties contains no-op/obsolete flags

- **Location:** `android/gradle.properties:1-4`
- **Problem:** `flutter.experimental.impeller=true` is not a switch the Flutter Gradle plugin reads (Impeller is controlled via the manifest meta-data io.flutter.embedding.android.EnableImpeller and is the default on Android anyway). `android.enableJetifier=true` is unnecessary with AndroidX-only dependencies and slows builds.
- **Fix:** Remove both. If Impeller-specific rendering problems appear on old GPUs, test with the EnableImpeller meta-data set to false.

### Generated and legacy build artefacts in the repo; versioning

- **Location:** `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java; android/app/build.gradle:23-31, 64; pubspec.yaml:4`
- **Problem:** GeneratedPluginRegistrant.java is a generated file committed to git. multiDexEnabled is unnecessary at minSdk ≥21. versionCode/versionName come from local.properties (old template) and the app is at 1.0.0+1: every Play upload needs a higher build number, and the next release must be ≥ +2.
- **Fix:** Add GeneratedPluginRegistrant to .gitignore, drop multiDexEnabled, use `flutter.versionCode`/`flutter.versionName` as in the current template, and bump the pubspec version for each upload (e.g. 2.0.0+2).

### Outdated dependencies with breaking upgrades ahead

- **Location:** `pubspec.yaml:14-23; pubspec.lock`
- **Problem:** flutter_local_notifications 18.0.1 (22.3.1 available; major versions change Android setup and APIs), flutter_lints 4.0.0 (6.0.0), shared_preferences 2.5.3 with the legacy API (its async successor uses DataStore by default on Android, a different file, so there is a migration trap), intl 0.19.0. The lock file was produced by a ~3.24 SDK (collection 1.18.0, leak_tracker 10.0.5).
- **Fix:** Upgrade in one controlled step together with the Flutter upgrade, re-verify notification behaviour on Android 13–16, and follow the storage migration notes to avoid 'empty data' after switching the prefs API.


## Data model & migration

### How data is stored today (v1.0.0+1)
- **Backend:** `shared_preferences` 2.5.3, legacy `SharedPreferences` API. On Android this is `/data/data/com.paulhuebner.chronos/shared_prefs/FlutterSharedPreferences.xml`, and every key carries the `flutter.` prefix. The whole map is loaded into memory, and every write rewrites the whole XML file.
- **`flutter.work_entries`:** one JSON string containing the entire log (storage_service.dart:4, 43-56), e.g. `[{"id":"1716712345678" | "<uuid v4>","date":"2026-05-26T00:00:00.000","startTime":"2026-05-26T08:00:00.000","endTime":"2026-05-26T16:15:00.000","isPaid":false}]`.
  - Timestamps are **local wall-clock ISO-8601 without offset**.
  - Timer-created entries are already quarter-rounded.
  - `date` duplicates `startTime`'s day.
  - `id` is a ms-timestamp string for timer entries (home_screen.dart:283) and a UUID v4 for manual entries (work_log_screen.dart:562).
  - There is no wage, break, note, job or schema version.
- **`flutter.app_settings`:** `{"language":"german"|"english","theme":"dark"|"light","hourlyWage":15.0}`. The wage is a double. `theme` is persisted but unused.
- **`flutter.active_session`:** a local ISO string of the running session start, or absent. Earnings are never stored; they are always recomputed with the *current* wage.
- **Backup:** Android Auto Backup is implicitly enabled, so this XML may already be in testers' Google Drive backups and can be restored into a fresh install of any later version.

### Problems to fix in the new model
- Money is a double and there is no wage snapshot (retroactive re-pricing).
- Local timestamps are ambiguous across DST and time zones.
- Parsing is all-or-nothing (one bad element bricks startup).
- Every mutation is an O(n) read-modify-write.
- There is no versioning.

### Suggested target model (drift/SQLite)
- `meta(schema_version)`
- `jobs(id, name, default_wage_cents, currency, color)`
- `wage_rates(job_id, valid_from_utc, wage_cents)`
- `entries(id TEXT PK, job_id, start_utc_ms, end_utc_ms, tz_offset_min, break_minutes, wage_cents_snapshot, is_paid, paid_at_utc_ms, payout_id, note, source ['timer'|'manual'|'migrated_v1'], created_at, updated_at)`
- `active_session(id=1, start_utc_ms, job_id, wage_cents_snapshot, planned_end_utc_ms?)`
- `payouts(id, period_start, period_end, paid_at, amount_cents)`
- settings in a key/value table or SharedPreferencesWithCache: language `system|de|en`, themeMode `system|light|dark`, rounding policy, reminders.
- Earnings = `round(duration_seconds * wage_cents / 3600)` with one documented rounding rule. Raw and rounded times are both kept for timer entries.

### Migration so existing testers lose nothing
1. **Same app identity.** Keep `applicationId com.paulhuebner.chronos` and the same upload key (Play App Signing), and ship a higher versionCode (e.g. 2.0.0+2). Otherwise v2 installs as a different app, or the update is rejected and the data is stranded.
2. **Read legacy data safely.** Keep the `shared_preferences` dependency and read the legacy keys with the **legacy API**. Do not switch blindly to `SharedPreferencesAsync`/`WithCache`: on Android their default backend is **DataStore** (verified in shared_preferences_android 2.4.7: `backend = SharedPreferencesAndroidBackendLibrary.DataStore`), a different file, so legacy data would appear empty. If moving settings to the async API, use `migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary` (package:shared_preferences/util/legacy_to_async_migration_util.dart), or `SharedPreferencesAsyncAndroidOptions` with the SharedPreferences backend and fileName 'FlutterSharedPreferences'. Verify against the exact package version.
3. **Idempotent startup migration** (before any UI reads data), guarded by `schema_version` stored *in the new DB*:
   - (a) Copy the raw strings to a backup file in the app documents dir (`legacy_v1_backup.json`), and keep the prefs keys untouched.
   - (b) Parse **each element individually** with try/catch. Convert `DateTime.parse(localIso)` to UTC ms plus the offset valid at that instant.
   - (c) Snapshot `wage_cents = round(hourlyWage*100)` with `source='migrated_v1'`. There is no wage history, so this is the only available value. Show a one-time notice with an option to adjust rates per month in bulk.
   - (d) Keep the ids as TEXT and preserve `isPaid`.
   - (e) Convert `active_session` to UTC and keep it running, so the notification and chronometer continue.
   - (f) Write everything in **one transaction**, then set schema_version=2.
   - (g) Store unparseable elements in a `migration_errors` table or file and offer an export. Never drop them silently.
4. **Do not delete the legacy keys in the same release.** Remove them in a later version (or after the user confirms). Run the "legacy keys present and not yet imported" check on **every** start, because an Auto Backup restore can bring v1 prefs back into a v2 install.
5. **Ship export/import** (CSV and JSON) in v2 so testers can back up before and after, and add migration tests with realistic v1 fixtures: overnight entries, entries created on 29 Mar / 25 Oct, mixed id formats, missing `isPaid`, a corrupted element, and an active session.
6. **Fix the DST rounding bug (B05) before 25 Oct 2026** if possible. Timer entries saved on switch days are already shifted by 1 h and cannot be auto-corrected. Optionally flag v1 entries on switch days for user review during migration.
