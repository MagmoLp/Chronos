# Bug reproduction with Flutter tests

> Raw research output from the Chronos analysis on 2026-09-30 (English). Line numbers refer to commit 9a52779 (v1.0.0). Summary and plan: [../UMBAUPLAN.md](../UMBAUPLAN.md).


## Setup

- **Toolchain:** Flutter 3.47.5 stable, Dart 3.13.4, from the SDK already in the scratchpad (not reinstalled). Working copy is `repro`, made with tar because rsync is missing; `.git`, `build` and `.dart_tool` were excluded.
- **Original repo is untouched:** `git -C /home/user/Chronos status` is clean. An md5 comparison of `lib/` shows only `app_theme.dart` differs, and only in the copy.
- **Changes needed in the copy:**
  1. `lib/theme/app_theme.dart:61`: `cardTheme: CardTheme(` became `cardTheme: CardThemeData(`. This fixes the only compile error.
  2. `pubspec.yaml`: `intl: ^0.19.0` became `intl: ^0.20.2`. Without it `pub get` fails: "flutter_localizations from sdk depends on intl ^0.20.3".
  3. `pub get` rewrote `pubspec.lock` (17 dependencies changed) and added an `analyzer: exclude: [build/**, android/**]` block to `analysis_options.yaml`. The tool did this itself; no manual edit.
- **Nothing was patched for instrumentation.** No build counters were added to `lib/`. Build counts come from `debugProfileBuildsEnabled` + `FlutterTimeline.debugCollect()` and `debugOnRebuildDirtyWidget`.
- **Original target version:** the `pubspec.lock` says `sdks: dart >=3.5.0, flutter >=3.24.0`. Its pinned SDK-transitive packages (collection 1.18.0, meta 1.15.0, vm_service 14.2.5, material_color_utilities 0.11.1, intl 0.19.0) match **Flutter 3.24.x / Dart 3.5** (Aug–Oct 2024).
- **Analyzer after the fixes:** 0 errors and 24 infos:
  - 22× `deprecated_member_use` (`withOpacity`)
  - `unnecessary_brace_in_string_interps` at `work_entry.dart:45`
  - `use_build_context_synchronously` at `home_screen.dart:290`
  - `flutter analyze test` reports no issues.
- **Fonts, for realistic pixel counts:**
  - Roboto and MaterialIcons are loaded from `flutter/bin/cache/artifacts/material_fonts` through `FontLoader`.
  - Roboto is also registered as `RobotoMono`. The app asks for `RobotoMono` (`home_screen.dart:137`) but never bundles it, so a device falls back to Roboto.
  - `AnimatedButton` (`animated_button.dart:109-115`) replaces `DefaultTextStyle` with a style that has no `fontFamily`. Under `flutter test` the START/STOP labels therefore use the square test font. The layout test reports a Roboto-corrected width for that Row.
- **Notification stub:** `AndroidFlutterLocalNotificationsPlugin.registerWith()` plus a mock handler on `dexterous.com/flutter/local_notifications` that records every `MethodCall`.
- **Final run:** `TZ=Europe/Berlin flutter test` on all files except `perf_live` gives 72 tests, all passing (`scratchpad/full_suite.log`). `perf_live_test` passes separately in about 80 s.
- **Log files** (in the scratchpad): `layout_roboto_de.log`, `layout_roboto_en.log`, `l10n.log`, `theme.log`, `logic.log`, `perf_live.log`, `verbose_tab13.log`.

## Reproductions

### 1a Landscape phone: HomeScreen vertical overflow + START/STOP unreachable — **yes**

*Test:* `test/layout_overflow_test.dart`

**Observed**

- **Overflow messages** (all from `RenderFlex` at `lib/screens/home_screen.dart:57:18`, the body Column):
  - 915x412 @1.0: "A RenderFlex overflowed by 222 pixels on the bottom."
  - 915x412 @1.3: 297 px; @2.0: 490 px
  - 800x360 @1.0: 274 px; @1.3: 349 px; @2.0: 542 px
- **Where the buttons end up:** at 915x412 @1.0 the body spans y 56..332, but the START button sits at y 490..554, below the bottom-nav top (332). A real tester.tap on START and on STOP misses in every landscape configuration. The user cannot start or stop the timer in landscape.
- **Tablet landscape 1280x800:** OK at 1.0 and 1.3. At @2.0 it overflows by 102 px and the buttons end up outside the body (734..806 vs 704).

**Root cause**

- `lib/screens/home_screen.dart:54-80`: a fixed, non-scrollable `Column(mainAxisAlignment: spaceEvenly)` holds 4 tall children:
  - 2 HighlightCards with 28 px padding and 56/40 px money text
  - the 52 px timer pill
  - the button Row
- There is no scroll view, `LayoutBuilder` or orientation-specific layout.
- `AndroidManifest.xml` declares no `screenOrientation`, so landscape is allowed.

### 1b Landscape dialogs/sheets (add/edit entry, entry-options sheet, delete-all, keyboard) — **yes**

*Test:* `test/layout_overflow_test.dart`

**Observed**

- **Add / edit dialog** (Column at `work_log_screen.dart:441:20` / `640:20`):
  - 915x412: 50 px @1.0, 90 px @1.3, 194 px @2.0
  - 800x360: 102 px @1.0, 142 px @1.3, 246 px @2.0
  - Hit tests (`isHittable`): the end-time tile cannot be hit in every phone landscape size, even at 1.0. The start-time tile also cannot be hit at 800x360 @1.3/2.0 and 915x412 @2.0, so the time picker cannot be opened.
- **Entry-options bottom sheet** (Column at `work_log_screen.dart:324:18`): 5.5 px (800x360 @1.0), 9.5 px (@1.3), 38 px (@2.0), 8.3 px (915x412 @2.0).
- **Delete-all dialog** (Column at `settings_screen.dart:283:16`): 4 px (800x360 @1.0), 33 px (@1.3), 60 px (915x412 @2.0).
- **Delete-all dialog with keyboard open** (viewInsets = 45% of height):
  - 117 px at 915x412 @1.0, 167 px @1.3
  - 120 px at 360x640 @1.0 (72 px in English)
  - 16 px at 412x915 @1.3, 289 px at 412x915 @2.0
  - 32 px at 1280x800 @2.0

**Root cause**

- `AlertDialog` content in `work_log_screen.dart:441-518`, `640-717` and `settings_screen.dart:283-316` is a plain `Column`. It has no `scrollable: true` and no `SingleChildScrollView`.
- The bottom sheet at `work_log_screen.dart:313-364` has no `isScrollControlled` and uses a non-scrollable Column.
- `AnimatedListItem` tiles are 16 px padded Rows at a fixed height.

### 1c Small phone 360x640 and text scale 1.3 / 2.0 on all screens — **yes**

*Test:* `test/layout_overflow_test.dart`

**Observed**

All numbers are German unless noted; English values are in brackets.
- **Home body Column (`home_screen.dart:57`), no system bars:**
  - 360x640: 1.0 fits with 1 px to spare; 166 px @1.3; 507 px @2.0 [EN 465].
  - 412x915: OK @1.0 and @1.3; 232 px @2.0 [EN 136].
  - Wherever it overflows, the buttons are completely outside the body and cannot be tapped.
- **Home with realistic system bars** (status 24 dp + 3-button nav 48 dp):
  - 360x640: 66 px @1.0, 103 px @1.15, 238 px @1.3, START/STOP untappable.
  - 360x740 with gesture bar: OK @1.0/1.15, 114 px @1.3.
  - 412x915: OK up to 1.3.
- **Control Row (`home_screen.dart:148`), Roboto-corrected:**
  - Fits at 1.0 on every size; the measured 13/65 px at 1.0 is a test-font artifact.
  - Overflows by 31.9 px @360 1.3x [EN 16.3], 59.1 px @412 2.0x [EN 35.4], 111.1 px @360 2.0x [EN 87.4].
- **Bottom nav Row (`custom_bottom_nav.dart:49:16`):** 19 px @412 2.0x (German only); 71 px [EN 40] @360 2.0x. At 360 @2.0 the Log tab icon sits at x=362.6..386.6 on a 360-wide screen [EN 331.5..355.5, outside the Row's bounds], and tapping it misses: **the work log cannot be reached**.
- **Settings language option Row (`settings_screen.dart:120:16`):** 6.8 px already at 360 @1.0 [EN 1.4], 22 px @1.3, 58 px / 16 px @2.0, 32 px @412 2.0x.
- **Money display (`animated_money_display.dart:25:12`):** 3.2 px and 20 px only at 360 @2.0. A total of 12,345.67 € fits at 1.0 on both 360 and 412.
- **Date picker** (framework `DatePickerDialog`, reported at `work_log_screen.dart:455:50`): 116 px @1.3 on every portrait size, including the 800x1280 tablet; 108 px @2.0 on phones.
- **Tablet portrait 800x1280:** no app overflow at any scale apart from the date picker.

**Root cause**

- Fixed-size layouts with no `Flexible`/`Expanded`/`FittedBox` and no text-scale clamping:
  - Control Row: `home_screen.dart:148-192`
  - `_NavItemWidget` label Row: `custom_bottom_nav.dart:129-160`, inside a spaceEvenly Row at `:49`
  - Language option: `settings_screen.dart:103-143` (horizontal padding 20 + icon + bold label inside a half-width `Expanded`)
  - Money Row: `animated_money_display.dart:25`, `mainAxisSize.min` with no FittedBox
- The date-picker overflow is caused by the app theme, confirmed separately in `date_picker_theme_leak_test.dart`: `app_theme.dart:94-95` sets `headlineLarge` to fontSize 56, which the M3 date picker uses for its header. "Mi., 30. Sept." renders at 56 px instead of 32 px. With `ThemeData.dark()` the picker has no overflow at 1.3.

### 2a Localization: German leftovers in English UI — **yes**

*Test:* `test/localization_leftovers_test.dart`

**Observed**

With the app set to English:
- **Settings:** "Datenverwaltung", "Alle Einträge löschen", "Löscht alle Arbeitszeiteinträge unwiderruflich".
- **Delete-all dialog:** "Alle Daten löschen?", "Diese Aktion kann nicht rückgängig gemacht werden. Alle Arbeitszeiteinträge werden unwiderruflich gelöscht.", "Zum Bestätigen gebe das Wort \"Löschen\" ein:" and the hint "Löschen".
- **Confirmation word:** typing "Delete" leaves the confirm button disabled (`onPressed == null`). Only the German word "Löschen" is accepted.
- **Snackbar:** "Alle Einträge gelöscht".
- **Notification sent to the plugin in English mode:** title="Arbeite", body="Verdient: 0.00 €", channelName="Arbeitssession", channelDescription="Zeigt die aktive Arbeitssession an".
- **German formats:**
  - Work-log dates "30.09.2026", "27. – 28.09.2026", "22:00 (27.09.) – 06:00 (28.09.)".
  - The home money display renders "502,50€" with a decimal comma.
- **Inconsistency:** the add/edit dialogs show "8:00 AM"/"4:00 PM" while the list shows 24-hour "08:00 – 16:00".

**Root cause**

- Hard-coded strings in `lib/screens/settings_screen.dart`: 182, 203, 210, 242, 280, 288, 293, 302; the German-only check at 271.
- `lib/services/notification_service.dart`: 13-14 (channel name/description), 57-58 (title/body; the body also uses `toStringAsFixed`).
- Hard-coded `','` separator: `lib/widgets/animated_money_display.dart:32`.
- Manual dd.MM.yyyy formatting: `lib/screens/work_log_screen.dart:242-255` and `lib/models/work_entry.dart:29-37`.
- Unused ARB keys: `endAfterStart`, `theme`, `darkMode`, `lightMode`.

### 2b Localization: English leftovers in German UI — **partially**

*Test:* `test/localization_leftovers_test.dart`

**Observed**

- **No English words appear in the German UI.** The only hit, "Timer stoppen?", was a false positive from the word list and was removed.
- **English number format in German:**
  - Work log: "Verdient: 120.00 €" … "138.75 €" use a decimal point.
  - The notification body uses "0.00 €".
  - The wage hint says "Beispiel: 15 oder 15.50".
- The German home money display correctly shows "502,50€", which makes it inconsistent with the work log.

**Root cause**

- `work_log_screen.dart:231` uses `earnings.toStringAsFixed(2)` instead of a locale `NumberFormat`.
- `notification_service.dart:22` has the same problem.
- The `wageExample` string in `app_de.arb` uses "15.50". The input formatter also rejects commas (see the wage-input item).

### 3 Dark/Light theme switch — **yes**

*Test:* `test/theme_switch_test.dart`

**Observed**

- **Switching does nothing.** After `SettingsProvider.setTheme(AppTheme.light)` the painted-colour snapshot is identical to dark: Theme brightness dark, scaffold 0xFF121212, AppBar 0xFF121212, text colours {white: 29, 0xFFB3B3B3: 7, blue: 3}, bottom nav 0xFF121212.
- **MaterialApp configuration:** `theme.brightness=dark`, `darkTheme=null`, `themeMode=system`. `SettingsProvider.themeMode` returns `ThemeMode.light`, but nothing reads it.
- Setting the platform brightness to light changes nothing either.
- A persisted `"theme":"light"` is loaded after restart (`settings.theme=light`), yet the app still renders dark.
- **Settings has no theme selector.** None of the texts Erscheinungsbild / Hellmodus / Dunkelmodus appear.
- **Hard-coded dark colours:** with a light ThemeData forced around each screen, these are still painted:
  - Home: surface boxes ×6, white text ×5, grey text ×6, Scaffold background #121212
  - Work log: white text ×36, grey ×14, surface ×6
  - Settings: white ×8, grey ×10, surface ×3, surfaceLight ×3
  - Bottom nav: surface ×1, grey ×1
  - 88 hard-coded palette references across `lib/`.
- **SystemUiOverlayStyle:** `SystemChrome.latestStyle` comes only from AppBar (statusBarIconBrightness=light, statusBarColor transparent); `systemNavigationBarColor` is null. No file in `lib/` uses SystemChrome.
- **Answer to "what renders wrong":** nothing flips, so no stale colours appear mid-switch; the feature simply does not exist.

**Root cause**

- `lib/main.dart:81-82` sets only `theme: AppThemeData.darkTheme`; there is no `darkTheme`/`themeMode`, and no light ThemeData exists in `app_theme.dart`.
- `settings_provider.dart:23-30` defines a `themeMode` that is never used; `settings_screen.dart` has no theme section.
- Every widget uses `const AppThemeData.*` colours instead of `Theme.of(context)`. Examples: `home_screen.dart:37,49,99,125,138`; `custom_bottom_nav.dart:26,32`; `animated_card.dart:78,145`; `animated_button.dart:77-85`.
- The date and time pickers force `ColorScheme.dark` (`work_log_screen.dart:455-461` and others).
- The system navigation bar colour relies on `android/app/src/main/res/values*/styles.xml`, which uses `Theme.Black.NoTitleBar`, so it would stay black if a light theme were added.

### 4 Background / CPU: rebuilds, notifyListeners, timers after pause, notification rate — **yes**

*Test:* `test/perf_live_test.dart (+ perf_fake_time_test.dart)`

**Observed**

The full numbers are in `perf_measurements`. In short:
- **Foreground:** 1 `notifyListeners`/s, and HomeScreen rebuilds its whole subtree about 270 widget builds per tick. That is about 418 widget builds/s and about 7.6 fps at 15 €/h, and about 814 builds/s and 17 fps at 150 €/h.
- **Covered or hidden:** HomeScreen keeps rebuilding while Settings covers it. On the Log tab there are still 1 dirty InheritedProvider and 1 frame per second.
- **After `paused`** (`hidden`/`paused` set `framesEnabled=false`):
  - `Timer.periodic` keeps running: 60 `notifyListeners` in 60 s.
  - No frames and no builds, but up to 12 frozen transient callbacks.
  - Notifications continue every 15 s (4/min) with German text.

**Root cause**

- `timer_provider.dart:57-63`: an unconditional 1 Hz `Timer.periodic` calls `notifyListeners`.
- No `WidgetsBindingObserver` / `AppLifecycleListener` exists anywhere in `lib/`.
- `home_screen.dart:20` watches the whole `TimerProvider` at the root of the screen (no `Selector`/`Consumer` around the timer text).
- `animated_money_display.dart` creates 1 `AnimatedSwitcher` per digit.
- `timer_provider.dart:66-77`: the notification is re-posted every 15 s (the comment says 30) and is not awaited.

### 5a Wage precision 12.82 €/h × 7h13m — **no**

*Test:* `test/logic_probes_test.dart`

**Observed**

12.82 € × 7h13m = 92.51766… and displays as "92.52", which is correct. This specific case is refuted, but related precision bugs were found (next two items).

**Root cause**

`work_entry.dart:18-20` computes `inMinutes/60*wage` in double arithmetic; for this input the result is correct.

### 5b Float rounding: displayed cents vs commercial rounding — **yes**

*Test:* `test/logic_probes_test.dart`

**Observed**

- **Exhaustive check** of every wage 0.01–60.00 € against every quarter-hour duration up to 12 h: 32,994 of 288,000 combinations (11.5%) display a different cent than half-up rounding.
- **Examples:**
  - 10.10 €/h × 15 min shows 2.52 (correct 2.53)
  - 10.10 € × 45 min shows 7.57 (correct 7.58)
  - 10.10 € × 315 min shows 53.02 (correct 53.03)
- **Totals do not add up:** 3 entries of 7h13m at 12.82 € each show 92.52 (sum 277.56), but Home "Gesamter offener Betrag" shows 277.55.

**Root cause**

- `work_entry.dart:18-20` works in doubles.
- `toStringAsFixed(2)` is applied to a binary double; used at `work_log_screen.dart:231` and `animated_money_display.dart:20`.
- `work_entries_provider.dart:12-14` sums unrounded values.
- Earnings should be computed in integer cents with an explicit rounding rule.

### 5c Entry spanning midnight — **no**

*Test:* `test/logic_probes_test.dart`

**Observed**

- 22:00→06:00 gives duration 8h, isOvernightShift=true, "22:00 (01.09.) – 06:00 (02.09.)", "8h", 120.0 € at 15 €/h.
- The stop-flow rounding 23:53 → next day 00:00 is also correct.
- Refuted outside DST days; on DST days the handling is wrong (see `additional_bugs_found`).

**Root cause**

`work_entry.dart:16-37` is correct for normal days.

### 5d End < start (and end == start) in edit dialog — **yes**

*Test:* `test/logic_probes_test.dart`

**Observed**

Driven through the real UI:
- Editing 08:00–16:00 by setting the end to 07:00 with the Material time picker (input mode, 24 h) saves 2026-09-01 08:00 → 2026-09-02 07:00. The list shows "23h" and "Verdient: 345.00 €", and there is no warning.
- Setting start == end saves a 24h entry.
- The ARB key `endAfterStart` ("Endzeit muss nach Startzeit liegen") is never used.

**Root cause**

`lib/screens/work_log_screen.dart:551-553` (add) and `750-752` (edit): `if (!endDateTime.isAfter(startDateTime)) endDateTime = endDateTime.add(Duration(days: 1))`. It silently treats the entry as overnight with no validation or confirmation.

### 5e Hourly wage change after entries exist (do old entries change?) — **yes**

*Test:* `test/logic_probes_test.dart`

**Observed**

A **paid** 8h entry shows "Verdient: 120.00 €". After changing the wage from 15 to 20 it shows "Verdient: 160.00 €". Every past entry, paid or open, is recomputed with the current wage.

**Root cause**

`WorkEntry` stores no wage or earnings (`work_entry.dart:1-15`, `toJson` 45-53). `calculateEarnings(hourlyWage)` is always called with the current `settings.hourlyWage` (`work_log_screen.dart:50,106`; `work_entries_provider.dart:12-14`).

### 5f Hourly wage change while timer runs — **yes**

*Test:* `test/logic_probes_test.dart`

**Observed**

Setup: a session restored at now−2h, then switch to the Log tab (HomeScreen unmounted), set the wage from 15 to 30, and wait 16 s of real time.
- The next notification body is "Verdient: 30.07 €", computed at 15 €/h; 30 €/h would give about 60.
- When HomeScreen stays mounted (the first, buggy run) the body is "Verdient: 60.13 €", i.e. it syncs.
- On Home, the running amount is recomputed for the whole session at the new wage; there is no split at the time of the change.

**Root cause**

`timer_provider.dart:21-23`: `_hourlyWage` is only updated by `HomeScreen.build` (`home_screen.dart:31`). `main.dart:32` sets it once at startup, and the settings change never reaches TimerProvider.

### 5g App restart while timer runs — **partially**

*Test:* `test/logic_probes_test.dart`

**Observed**

- **Restore works:** the persisted start time is restored exactly (isRunning=true), and the notification is re-posted on the first tick.
- **Glitch on first frame:** the first frame shows "00:00:00" and earnings 0.0. After 1 s it jumps to "03:05:00".
- **DST bug (TZ=Europe/Berlin):** a start at 2026-10-25 01:30Z (02:30 CET, second pass) is stored as "2026-10-25T02:30:00.000" and restored 1 hour off (`restored.difference(real) = -1:00:00`).

**Root cause**

- `timer_provider.dart:25-30`: `loadActiveSession` does not compute `_elapsed` before the first tick.
- `storage_service.dart:76,84`: `toIso8601String()` of a local DateTime has no UTC offset, and `DateTime.parse` resolves ambiguous local times to the first occurrence.

### 5h Malformed JSON / wrong types in prefs — **yes**

*Test:* `test/logic_probes_test.dart`

**Observed**

**Every case throws:**
- `work_entries="not json"` → FormatException
- `"{}"` → `_TypeError` ('_Map' is not a subtype of 'List')
- An entry without `id` → `_TypeError` (Null is not a subtype of String)
- A bad date → FormatException
- `app_settings="{bad"` → FormatException
- `hourlyWage` as a string → `_TypeError` (String is not a subtype of num?)
- `active_session="garbage"` → FormatException

**Effect on startup:** running the real `main()` with a corrupt `work_entries` leaves only "Startup Error: FormatException: Unexpected character (at character 1)" on screen. The screen has no recovery or reset action, so the app is bricked until its data is cleared.

**Root cause**

- No try/catch or validation in `storage_service.dart:48,63,84`, `work_entry.dart:58-65` or `app_settings.dart:36-48`.
- `main.dart:46-57` catches everything and replaces the app with a static error screen.

### 5i Delete-all — **no**

*Test:* `test/logic_probes_test.dart`

**Observed**

- The provider works: entries become 0, a reload gives 0, the prefs key is removed, and `active_session` is correctly kept.
- The UI flow works in German. In English it requires the German word "Löschen" (see item 2a).

**Root cause**

`work_entries_provider.dart:30-34`, `storage_service.dart:37-40`: correct.

### 5j Paid/unpaid totals — **no**

*Test:* `test/logic_probes_test.dart`

**Observed**

Open total is 180 initially, 120 after paying u2, and 270 after un-paying p1, all as expected. Only the rounding mismatch of item 5b remains.

**Root cause**

`work_entries_provider.dart:9-14`: correct.

### 5k Decimal comma wage input "12,50" — **yes**

*Test:* `test/logic_probes_test.dart`

**Observed**

- **Typed key by key, "12,50" becomes field "1250" and wage 1250.0 €/h**, which is persisted.
- **Other inputs:**
  - "12.50" → 12.5 (correct).
  - "0" → field shows "0" but the wage stays 12.5, silently.
  - "12.505" → "12.50".
  - "1e3" → "13".
  - Pasting "12,50" gives "12" (wage 12.0).
- Every keystroke is persisted, including intermediate values such as 1 €/h.

**Root cause**

`settings_screen.dart:384`: `FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))` drops the comma. The `replaceAll(',', '.')` at line 404 is therefore dead code, and `onChanged` (403-407) saves on every keystroke. German Android keyboards often offer only ','.

### 5l Sorting of entries — **no**

*Test:* `test/logic_probes_test.dart`

**Observed**

Order is "cba" newest-first after inserts and "acb" after moving entry a to 30.09. The month grouping in the work log is also consistent.

**Root cause**

`work_entries_provider.dart:45-47` sorts by `startTime` descending: correct.

### 5m Quarter-hour rounding in the stop flow — **yes**

*Test:* `test/logic_probes_test.dart`

**Observed**

- **Rounding goes the wrong way at 7 minutes:** 08:07 rounds up to 08:15 although 08:00 is nearer, despite the "nearest" doc comment.
- **Near-identical sessions get different results:**
  - 08:07–08:21 (14 real min) and 08:22–08:36 become 0 min and are discarded.
  - 08:06–08:22 (16 real min) becomes 30 min.
- **A discarded session is lost for good.** In the real widget flow, a session started 2 min earlier and then stopped shows the "Zeit zu kurz" snackbar, saves 0 entries, and has already cleared `active_session`. There is no undo.

**Root cause**

- `home_screen.dart:198-206`: a threshold of 7 instead of 7.5 or 8.
- `home_screen.dart:250-273`: `timer.stop()` clears persistence before the minimum-duration check discards the session.


## Performance measurements

**How it was measured**
- `perf_live_test.dart` keeps the fake clock in step with the real clock (the app reads `DateTime.now()` directly). Every ~16 ms of real time it advances fake time by the same amount and renders a frame only if the framework asked for one (`hasScheduledFrame`), which mimics vsync. The harness loop runs at about 56 iterations/s.
- Screen size 800x1280, wage 15 €/h. Widget-build counts come from `debugProfileBuildsEnabled` + `FlutterTimeline`.

**Real-time results**

| Window | Frame requested in | ≈ fps on a 60 Hz device | notifyListeners/s | Widget builds/s | Notification posts |
|---|---|---|---|---|---|
| Idle, timer stopped (5 s) | 0.0% of vsync slots | 0 | 0 | 0 | 0 |
| Foreground, 15 €/h (32 s) | 12.7% | ~7.6 | 1.00 | 417 (HomeScreen 1.0/s, AnimatedDigit 6.0/s, AnimatedSwitcher 6.9/s, Text 16/s) | 3 (every 15 s → 4/min steady state) |
| Foreground, 150 €/h (8 s) | 28.8% | ~17.3 | 1.00 | 814 | 0 in window |
| Paused / background (32 s) | 0.1% (one transition frame) | ~0 | 1.00 (timer keeps firing) | 13 (almost all from the transition frame) | 2 → 4/min |
| Resumed (3 s) | 21% | ~12.7 | 1 | 692 (catch-up) | 0 |

- **Details:**
  - Foreground 15 €/h: max 8 transient callbacks.
  - Paused: `framesEnabled=false` and `timer.isRunning=true`. Up to 12 transient callbacks from frozen AnimatedDigit switchers stay registered.
- **Notification bodies posted, in order:** \"Verdient: 0.00 €\", \"0.07 €\", \"0.13 €\", \"0.19 €\", \"0.25 €\", i.e. every 15 s of elapsed time in both foreground and background. The code comment says 30 s.

**Deterministic per-tick counts (`perf_fake_time_test.dart`, 10 fake seconds)**
- **Home visible:** 10 `notifyListeners`, 10 frames, 2,704 widget builds (about 270 per tick). Per tick: RichText 20, Text 19, AnimatedDigit 9, AnimatedSwitcher 9, HomeScreen 1, AppBar 1, both HighlightCards and both AnimatedButtons. The dirty root each tick is `_InheritedProviderScope<TimerProvider>` → HomeScreen; the whole screen rebuilds every second.
- **Settings pushed over Home:** still 10 HomeScreen rebuilds and 2,620 builds in 10 s, all for a screen nobody can see.
- **Log tab (HomeScreen unmounted):** still 10 `notifyListeners` and 10 frames. 110 builds, only the InheritedProvider plus layout/semantics.
- **Paused, 60 fake s:** `framesEnabled=false`, 60 `notifyListeners`, 0 frames, 0 builds, `hasScheduledFrame` false in 60/60 samples. The first frame after resume does 262 builds.

**Measurement pitfalls**
- **Fake time and notifications:** under fake time, a freshly started timer posts a notification on every tick (10 in 10 s). Elapsed stays at 0 s, so the `_lastNotificationUpdate == 0` branch always fires. A restored session posts once and then never. Notification counts from a fake-time test, such as the other agent's `proj/test/perf_test.dart`, are therefore meaningless.
- **LiveTestWidgetsFlutterBinding:** it reports about 60 fps even when idle or paused, because its `handleDrawFrame` re-schedules a frame after every frame. It cannot be used for frame counts.

## Additional bugs found

- **Bottom nav can lose the Log tab** (`lib/widgets/custom_bottom_nav.dart:49` Row, `:129-160` item): at 360 dp width and text scale 2.0 the \"Log\" item lies outside the Row, so the work-log screen cannot be reached.
- **Add-entry dialog in landscape** (`lib/screens/work_log_screen.dart:441`, same for edit at `:640`): the end-time tile cannot be hit in every phone landscape size, even at 1.0. The start-time tile also cannot be hit at 800x360 @1.3.
- **Theme leaks into the date picker** (`lib/theme/app_theme.dart:94-95`): `headlineLarge` fontSize 56 is picked up by the Material DatePickerDialog header, so the picker overflows by 116 px at text scale 1.3 on every portrait device.
- **DST, quarter rounding** (`lib/screens/home_screen.dart:204-205`): `DateTime(y,m,d).add(Duration(minutes: …))` shifts rounded times on DST days. Under TZ=Europe/Berlin, 29.03. 08:00 becomes 09:00 and 25.10. 08:00 becomes 07:00.
- **DST, overnight entries** (`lib/screens/work_log_screen.dart:552` and `:751`): `endDateTime.add(Duration(days: 1))` on the DST night. A 24.10. 22:00–06:00 entry is stored with end 05:00 and 8 h, although the real span 22:00 CEST → 06:00 CET is 9 h.
- **DST, restored start time** (`lib/services/storage_service.dart:76/84`): `active_session` is stored as local ISO time without an offset, so it restores 1 h off during the repeated 02:xx hour.
- **Stale wage in the notification** (`lib/providers/timer_provider.dart:21-23` + `lib/screens/home_screen.dart:31`): the notification keeps the old wage when the wage changes while HomeScreen is not mounted.
- **Wage-input edge cases** (`lib/screens/settings_screen.dart:403-407`): every keystroke is persisted, including intermediate values. Typing \"0\" silently keeps the old wage while the field shows 0.
- **Timer shows 0 right after restart** (`lib/providers/timer_provider.dart:25-30`): for up to 1 s after a restart the screen shows 00:00:00 and 0,00 €.
- **Short sessions are lost** (`lib/screens/home_screen.dart:251-273`): `stop()` clears the persisted session before the minimum-duration check, so a session that rounds to under 15 min is gone for good.
- **Rounding threshold** (`lib/screens/home_screen.dart:201`): the threshold is 7, not 7.5, so :07 rounds up, contradicting the \"nearest quarter\" doc.
- **Wasted rebuilds while running** (`lib/screens/home_screen.dart:20`): HomeScreen watches the whole TimerProvider, so about 270 widget builds happen per second, even while Settings covers Home. On the Log tab one useless frame is still drawn every second.
- **No lifecycle handling anywhere in `lib/`** (`lib/providers/timer_provider.dart:57-63`): the 1 Hz timer and the 15 s notification re-posts keep running in the background.
- **Notification cadence comment is wrong** (`lib/providers/timer_provider.dart:68-69`): the comment says 30 s, the code uses 15 s.
- **Monospace font never bundled** (`lib/screens/home_screen.dart:137`): `fontFamily 'RobotoMono'` is not declared in `pubspec.yaml`, so it falls back to the system font.
- **Button labels lose the theme font** (`lib/widgets/animated_button.dart:109-115`): the `DefaultTextStyle` replacement drops the theme's fontFamily and text theme.
- **German confirmation word in English** (`lib/screens/settings_screen.dart:271`): delete-all can only be confirmed by typing the German word \"Löschen\", also in English.
- **Framework quirk, not an app bug:** with a German locale and the device set to 12-hour time, typing \"07\" in the time picker's input mode while the initial time is PM gives 19:00. The framework's `_parseHour` checks only `MediaQuery.alwaysUse24HourFormat`. It does not happen when the device uses 24-hour time, the German Android default. It was seen because tests default to `alwaysUse24HourFormat=false`.
- **Not reproduced:** using the bottom-sheet context after `Navigator.pop` (`lib/screens/work_log_screen.dart:338-339, 350-351`) did not crash; the edit and delete flows work.

## Reusable tests

All files are in `docs/research/repro-tests/`:
- **`helpers.dart`** — the shared harness:
  - `bootApp()` wires the providers exactly like `main.dart`.
  - `installNotificationStub()` records every plugin method call.
  - `loadRealFonts()` loads Roboto, the RobotoMono fallback and MaterialIcons.
  - `captureErrors()` stringifies FlutterErrors eagerly.
  - Also `setScreen`/`resetScreen` and `visibleTexts()`.
  - Worth adopting as `test/support/`.
- **`logic_probes_test.dart`** (23 tests):
  - Wage precision, including the exhaustive cent-rounding check, and the total-vs-rows mismatch.
  - Quarter rounding, overnight entries, end<start via the real time-picker UI.
  - Every malformed-prefs case, and real `main()` showing the Startup Error screen.
  - Restart restore, the DST cases (run with `TZ=Europe/Berlin`), the retroactive wage change, the stale-wage notification (takes 16 s real time), and the decimal-comma input.
  - Sorting, paid/unpaid totals, delete-all, and the discarded short session.
  - Tests named \"BUG…\" assert the current buggy behaviour; flip those expectations when fixing.
- **`layout_overflow_test.dart`** (33 tests):
  - A matrix of 6 sizes × 3 text scales visiting every screen, dialog and sheet, plus keyboard insets, realistic system bars and large money amounts.
  - Checks hit-testability of START/STOP, the Log tab and dialog tiles, and reports Roboto-corrected control-row widths.
  - Environment variables: `CHRONOS_LANG=english`, `CHRONOS_TEST_FONT=1`, `CHRONOS_VERBOSE=1`.
  - It records rather than fails today. Turn its results into `expect(errors, isEmpty)` once the layout is fixed.
- **`localization_leftovers_test.dart`** — walks all UI in EN and DE and flags strings in the other language, date and number formats, and notification texts. Good regression guard for l10n.
- **`theme_switch_test.dart`** — covers the setTheme no-op, persisted light theme, and hard-coded palette colours under a light ThemeData. Use it as the acceptance test when light mode is implemented.
- **`date_picker_theme_leak_test.dart`** — shows the `headlineLarge` override breaking DatePickerDialog at 1.3x.
- **`perf_fake_time_test.dart`** — deterministic builds per tick, the paused-lifecycle behaviour, and an idle no-work check. It could become a budget test, e.g. HomeScreen must not rebuild on ticks, and no ticks while paused.
- **`perf_live_test.dart`** — the real-time frames, builds, notification cadence and pause test (about 80 s; run on its own).
