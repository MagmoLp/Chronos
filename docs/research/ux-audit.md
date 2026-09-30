# UX / UI / design audit (v1.0.0)

> Raw research output from the Chronos analysis on 2026-09-30 (English). Line numbers refer to commit 9a52779 (v1.0.0). Summary and plan: [../UMBAUPLAN.md](../UMBAUPLAN.md).


## Spec (App Spezifikationen.docx) vs implementation

## "App Spezifikationen.docx": what the spec says (translated and condensed)

**Platform and look:** Flutter, built for Android. Dark mode uses **navy blue + anthracite**. Light mode uses **light blue + white**. Languages are English and German.

**Two overlapping core functions**
1. **RealTimeSalaryCount (page 1):** uses the hourly wage from settings to compute the money earned in the running session, including cents. It also shows the **total earned money over all open (not yet settled) work time**.
2. **Work-time log (page 2):** Start and Stop buttons on page 1 measure active time. After Stop, the time is stored on page 2 as *open (unpaid)*. On the log page you can mark an entry as settled ("Hackerl setzen"), which removes it from the open total on page 1. Entries must be editable: **long-press opens a dropdown menu with Edit / Delete**. There must be a button to create an entry manually.

**Settings:** language and dark/light mode are set with classic switches ("Schieberegler"). There is a field for the hourly wage in euros with 2 decimals. If you type "15", the app should understand that the decimals are zero.

**Page 1 layout:** at the top centre, in well-readable type: **the amount earned today**, updating continuously through a **wheel effect: the next digit slides in from top to bottom** and replaces the old one, timed exactly to the wage. The total open amount sits a little lower in the centre and rises in step. **Below the two sums are Start and Stop, and centred below them a window shows the elapsed time.** Stop must be confirmed ("Are you sure…").

**Global elements:** the settings gear is always top-right. The page switcher is at the bottom, with page 1 on the left and page 2 on the right.

**Page 2 layout:** a list of worked time with correct dates. Each row reads left to right: paid checkbox (tappable), date, time range (e.g. 08:00–14:00), total time (e.g. 8:45h). Top-right, left of the gear, is the "new entry" button. A new entry takes a date and a from–to time. Entries are sorted by date and **the most recent entry is always at the bottom**. There is no limit, and you scroll up to see older, settled entries.

**Overall:** "must look very modern, with high-quality animations, responsive elements and nice transitions."

## Where the implementation deviates

| Spec | Implementation | Evidence |
|---|---|---|
| Dark = navy + anthracite, light = light blue + white | One generic dark theme only: #121212 / #1E1E1E + Tailwind "electric blue" #3B82F6. No light theme at all. README still claims navy / light blue | lib/theme/app_theme.dart:3-20, lib/main.dart:82, README.md "Design" |
| Switches for language and dark/light | Language is two custom tiles. **There is no theme control.** Model, provider and ARB keys exist but nothing uses them | lib/screens/settings_screen.dart:35-40, 56-144; lib/providers/settings_provider.dart:23-30, 53-57; lib/l10n/app_de.arb:15-17 |
| Page 1 shows what was **earned today** | Shows only the **current running session**: 0,00 € when idle, and it resets for a second shift on the same day | lib/screens/home_screen.dart:33, lib/providers/timer_provider.dart:79-83 |
| Timer window centred **below** the buttons | Timer sits **above** the buttons | lib/screens/home_screen.dart:74-77 |
| Wheel: new digit slides **top→bottom** | New digit comes in 30 px **from below**, moving up with a fade. Updates happen in 1-second steps only | lib/widgets/animated_digit.dart:17-34 |
| Stop needs a confirmation | Single AlertDialog (fine), but it gives no information and the rounding happens silently afterwards | lib/screens/home_screen.dart:208-298 |
| Wage with 2 decimals, "15" → 15.00 | The input formatter accepts only "." (German users can't type a comma). The value is saved on every keystroke. "15.00" only appears after reopening. No currency option | lib/screens/settings_screen.dart:379-409 |
| Row: checkbox, date, time, total | Implemented, plus an extra "Verdient: 123.75 €" line, a green "Abgerechnet" badge and a blue highlighted row for paid entries (paid state shown 3 ways) | lib/screens/work_log_screen.dart:148-240 |
| Newest entry at the **bottom**, scroll up for older | Newest **first** (descending) | lib/providers/work_entries_provider.dart:49-51, lib/screens/work_log_screen.dart:95 |
| Long-press → **dropdown** with Edit/Delete | Modal bottom sheet, opened by **tap and** long-press | lib/screens/work_log_screen.dart:156-157, 310-365 |
| Add button top-right, left of the gear | Implemented, as a filled circle | lib/screens/work_log_screen.dart:28-43 |
| New entry: date + from–to | Implemented as a dialog with 3 pickers. If end ≤ start it silently becomes an overnight shift (end == start → a 24 h shift). The `endAfterStart` string exists but is never used | lib/screens/work_log_screen.dart:421-585, 551-553 |
| "Very modern, high-quality animations" | Scale-on-press on every element plus AnimatedContainer everywhere. This reads as rubbery and heavy, not modern. No shared-axis or container transitions, no reduced-motion support | lib/widgets/animated_button.dart, lib/widgets/animated_card.dart, lib/widgets/custom_bottom_nav.dart |

**Not in the spec but added:** quarter-hour rounding of timer sessions with a 7-minute threshold. **Sessions under 15 min are thrown away after the timer has already stopped.** Also added: an ongoing notification with a chronometer, month grouping, a confirmation only when un-marking paid, and a delete-all that requires typing the German word "Löschen".

**Where the known internal-test bugs come from:** "Alles löschen" stays German → settings_screen.dart:182-302 is entirely hard-coded German. Landscape "BOTTOM OVERFLOWED BY 284 PIXELS" → home_screen.dart:54-80 (fixed ~460 dp Column, not scrollable, plus an ~80 dp custom nav bar). Dark/Light display problem → static color constants, see the first UX problem. Tablet untested → there is no adaptive code at all (zero uses of LayoutBuilder or MediaQuery sizes).

**Gaps in the spec itself:** breaks, multiple employers, wage history, tips and surcharges, payouts, export/backup, statistics, forgetting to start or stop the timer, overnight/DST shifts, onboarding, notifications and widgets.

## Current UI

## App shell
- **main.dart:88-133 MainScreen**: a Scaffold with background #121212. Its body is an `AnimatedSwitcher` (300 ms cross-fade) swapping two full screens by key, so the Log screen is destroyed on every tab switch. Each screen has its **own nested Scaffold + AppBar**.
- **CustomBottomNavigation** (custom_bottom_nav.dart): a floating #1E1E1E bar with radius 28 and margins 16/8, about 80 dp tall plus the system inset. It has 2 items. The selected item is a pill (electric blue at 20%) with icon and label; the label grows in via `AnimatedSize` with an `easeOutBack` overshoot. **Unselected items show only an icon.** The labels reuse the long screen titles "Aktueller Verdienst" and "Arbeitszeit-Protokoll" (main.dart:120-129). Each item has its own scale-0.9 press controller.
- **Launch:** main() awaits settings, entries, **the notification init, which shows the Android 13 permission prompt**, and the timer restore, all before `runApp`. The native splash is #121212 in both day and night resources. If startup fails, a raw screen shows `Startup Error: $e`.

## Theme (app_theme.dart), "Reactive Dark Minimalist"
- Colors: background #121212, surface #1E1E1E, surfaceLight #2A2A2A, electricBlue #3B82F6, electricBlueLight #60A5FA, text #FFFFFF / #B3B3B3, success #22C55E, error #EF4444. **Dark only.**
- Radii 12 / 20 / 28 / 50. Durations 150 / 300 / 500 ms. Curves easeInOut / easeOutBack.
- Type: platform Roboto. headlineLarge 56 bold, headlineMedium 40 bold, titleLarge 22, titleMedium 16, bodyLarge 16, bodyMedium 14 grey. The timer uses 52 w300 `fontFamily: 'RobotoMono'`, **which is not bundled** (pubspec has no fonts), so it silently falls back.
- Card, BottomNavigationBar and ElevatedButton themes are defined but mostly unused, because the UI is built from custom containers. Colors are referenced as static constants 140 times.

## Home ("Chronos")
- AppBar: centred title "Chronos" and a 48 dp filled grey circle holding the gear icon.
- Body: a non-scrollable Column with `spaceEvenly` and 20 dp side padding:
  1. **HighlightCard** (radius 28, 1.5 px blue border at 30%, padding 28): the label "Aktueller Verdienst" (18 px grey) and **AnimatedMoneyDisplay 56 px bold**, e.g. "0,00 €".
  2. HighlightCard: "Gesamter offener Betrag" (14 px) and **40 px bold** money.
  3. **Timer pill** "00:00:00" at 52 px, padding 40/20. While running it gets a blue 15% fill and a blue border.
  4. A Row with two pill buttons: **START (green #22C55E, white text)** and **STOPP (red #EF4444)**. The inactive one turns grey (#2A2A2A).
- Stop → AlertDialog "Timer stoppen? / Sind Sie sicher…" with Abbrechen (grey text) and a blue pill "Bestätigen" → times rounded to the quarter hour → a green snackbar "Arbeitszeit gespeichert", or a red snackbar "Zeit zu kurz…" (entry discarded).
- **AnimatedMoneyDisplay:** one AnimatedSwitcher per digit, with a 30 px slide-up plus Opacity fade over 300 ms. The "," separator is hard-coded and € is a suffix at 60% size. The whole Home screen rebuilds every second (`context.watch<TimerProvider>()`, timer_provider.dart:55-64).

## Work log ("Arbeitszeit-Protokoll")
- AppBar actions: two filled circles (+ and gear).
- **Month headers:** uppercase, 12 px, electric blue, letter-spacing 2, with a hairline. No totals.
- **Rows (AnimatedListItem):** radius-20 #1E1E1E cards with 16 dp margin and 16 dp padding.
  - Leading: a **28 px custom checkbox** (green check when paid).
  - Body: date "30.09.2026" (16 w600), "08:00 – 16:15" (14 grey), "Verdient: 123.75 €" (blue w600).
  - Trailing: duration "8:15h" (16 bold) and a green **"Abgerechnet" 10 px badge**.
  - Paid rows are also tinted blue with a blue border (the "isSelected" style).
- **Tap or long-press** → a bottom sheet (background #121212, drag handle) whose two options are themselves cards: "Eintrag bearbeiten" and "Löschen".
- **Add / Edit:** an AlertDialog with three tappable card rows (Datum, Startzeit, Endzeit), each opening a stock date or time picker **forced to `ColorScheme.dark`**. Defaults are 08:00–16:00 and the date range is 2020–2030. The add and edit code is duplicated (about 160 lines each).
- Delete: sheet → non-dismissible dialog → **green** snackbar "Eintrag gelöscht" (no undo). Un-marking paid opens a confirm dialog; marking paid is instant.
- Empty state: a grey circle with the `work_off` icon and "Keine Einträge vorhanden".

## Settings (pushed route)
- A manual back IconButton. ListView with 16 padding and three HighlightCards (another 16 margin and 24 padding):
  1. **Sprache:** two custom selectable tiles, "Deutsch" and "English", with a check icon.
  2. **Stundenlohn (€):** a filled TextField with € prefix icon, "/ h" suffix and the helper "Beispiel: 15 oder 15.50".
  3. **"Datenverwaltung" (hard-coded German):** a nested, red-tinted AnimatedCard "Alle Einträge löschen" → a dialog that makes you type "Löschen".
- Footer: "Chronos v1.0" (hard-coded). No theme switch, no about or privacy link.

## Notifications
- An ongoing, low-importance notification "Arbeite / Verdient: 12.34 €" with a native chronometer. It is re-posted every **15 s** from the Dart timer.
- Channel "Arbeitssession". The small icon is the full-colour launcher mipmap. No actions, no tap handling.

## Motion inventory
- Scale-on-press: buttons 0.95, icon buttons 0.9, cards 0.98, list rows 0.98, nav items 0.9. Each is its own AnimationController, so every list row owns one.
- AnimatedContainer color/border tweens (300 ms) on cards, rows, the timer pill, language tiles and the checkbox.
- AnimatedSize with overshoot in the nav. Full-screen AnimatedSwitcher on tabs. Per-digit slide + Opacity.
- No reduced-motion handling, no haptics.

## Android assets
- The launcher icon is a detailed neon hourglass with a € sign and a bar chart on black (brand read: **navy + electric/cyan blue**). It is a **2048×2048 PNG copied into all five mipmap densities** (~2.2 MB each) plus the adaptive foreground, with a transparent adaptive background and no monochrome layer.
- LaunchTheme/NormalTheme = Theme.Black.

## What's missing entirely
- Grep over lib/ finds **no** Semantics, tooltip, semanticLabel, LayoutBuilder, OrientationBuilder, FittedBox, SingleChildScrollView, disableAnimations, RepaintBoundary, WidgetsBindingObserver, HapticFeedback, Dismissible, FloatingActionButton, NavigationBar or NavigationRail.
- The only MediaQuery use is the bottom inset in custom_bottom_nav.dart:38.

## UX problems

### [high] Global / theme

There is one hard-coded dark theme. Light mode and a theme switch don't exist, and the architecture makes switching impossible: about 140 direct references to static AppThemeData colors (electricBlue 36x, textSecondary 24x, surface 22x, textPrimary 20x, error 13x, success 10x, background 9x, surfaceLight 6x) plus 11 Colors.white/transparent bypass Theme.of(context). This is the most likely root cause of the internal-test note 'Dark/Light Mode Darstellungsproblem beim Umschalten'. Anything the framework draws (dialog defaults, pickers, snackbars, selection handles, progress indicators) follows the theme; every custom widget ignores it. Any theme or system-brightness switch therefore gives a mixed dark/light UI or no change at all.

- **Evidence:** `lib/main.dart:82; lib/providers/settings_provider.dart:23-30 (themeMode never used) and :53-57 (setTheme never called); lib/l10n/app_de.arb:15-17 (theme/darkMode/lightMode keys unused); lib/theme/app_theme.dart:12-20; lib/screens/work_log_screen.dart:457,481,505,656,680,704 (pickers forced to ColorScheme.dark)`
- **Recommendation:** Build light and dark ColorSchemes from the token table and set MaterialApp(theme, darkTheme, themeMode) with 'System' as the default. Replace every static color with colorScheme roles or a ThemeExtension. Delete the picker overrides. Add a CI grep or custom lint that rejects Color(0x..)/AppThemeData colors outside lib/theme.

### [high] Global / brand

The palette is a generic Tailwind-style 'electric blue on #121212'. It isn't the specified navy + anthracite / light blue + white, and it doesn't match the navy/cyan app icon. The app has no recognizable identity, and README.md claims colors that aren't implemented.

- **Evidence:** `lib/theme/app_theme.dart:3-20; README.md Design section; App Spezifikationen.docx 'Design Farben'`
- **Recommendation:** Adopt the refined 'Navy Night / Sky Day' tokens from the design system: navy-tinted dark surfaces (#0B1320…#233142), sky-blue primary in dark (#9CCFF5), navy primary in light (#14548C), and brand sky #87CEEB as the live-state container in light mode.

### [high] Home

Landscape overflow ('BOTTOM OVERFLOWED BY 284 PIXELS'). The body is a non-scrollable Column with spaceEvenly and fixed-size children of about 460 dp (card 1 ≈160, card 2 ≈136, timer pill ≈101, buttons ≈64). In landscape only about 180-250 dp remain after the status bar, the 56 dp AppBar and the ~80 dp floating custom nav bar.

- **Evidence:** `lib/screens/home_screen.dart:54-80, 92, 122, 158, 178; lib/widgets/custom_bottom_nav.dart:39-60`
- **Recommendation:** Use an adaptive layout. When height < 480 dp, put navigation in a NavigationRail and split into two columns (hero left, actions right). Always wrap content in a scroll view as a safety net, drop the fixed paddings, and size the hero with FittedBox.

### [high] Home

No visual hierarchy. Three hero-sized numbers compete: 56 px bold session money, 40 px bold open total and a 52 px timer, each in its own bordered container. The eye has nowhere to land, and the important number changes with state (idle: unpaid balance; running: this shift) but the layout doesn't.

- **Evidence:** `lib/screens/home_screen.dart:61-77, 100, 106-108, 135`
- **Recommendation:** One hero per state. Running: this shift's amount (displayLarge, tabular), with the timer as a titleLarge line under it and the open total as a single secondary line. Idle: the unpaid balance as hero (displaySmall), plus the Start button.

### [medium] Home

The idle state is meaningless. It shows a big '0,00 €', '00:00:00' and a disabled grey STOP button that uses a third of the screen. There's nothing useful when not working: no today, week or last-shift info.

- **Evidence:** `lib/screens/home_screen.dart:33, 75, 172-176`
- **Recommendation:** Idle Today screen: unpaid balance card with a 'Record payout' action, a large 'Start shift' button with an optional job chip and 'Started earlier?', and summaries for this week and the last shift.

### [medium] Home

There are two separate Start and Stop pill buttons with traffic-light colors, and one is always disabled. White text on #22C55E has a contrast of 2.28:1 and on #EF4444 3.76:1, both failing AA. The green/red pair adds visual noise and doesn't scale to Pause.

- **Evidence:** `lib/screens/home_screen.dart:148-192; lib/widgets/animated_button.dart:78-87`
- **Recommendation:** Use a single primary FilledButton ('Start shift' → 'Finish', 56-64 dp, stadium shape that morphs to a rounded square while recording) and a tonal 'Break' button. Use colors from the scheme only; red is reserved for destructive actions.

### [medium] Home

Hard-coded sizes break at large font scale and on narrow phones. The money Row (mainAxisSize.min, 56 px) has no FittedBox. The button Row uses 32 dp horizontal padding per button and needs about 320 dp, exactly the available width on a 360 dp phone. At 130-200% font scale, or with a 4-digit total, you get yellow overflow stripes.

- **Evidence:** `lib/widgets/animated_money_display.dart:25-44; lib/screens/home_screen.dart:92, 158, 166, 178, 186`
- **Recommendation:** Use FittedBox(fit: scaleDown) around the hero amount, Expanded buttons in a Row (or a Column when narrow), and no fixed padding for layout. Test with textScaler 2.0 and at 320 dp width.

### [medium] Global / components

Custom widgets reinvent Material components and lose their behavior. AnimatedButton and AnimatedIconButton are GestureDetectors: no button semantics, no focus or keyboard support, no ripple, no tooltip, and the disabled state isn't announced. CustomBottomNavigation, HighlightCard/AnimatedCard/AnimatedListItem, the custom checkbox and the language tiles all replace NavigationBar, Card, ListTile, Checkbox and SegmentedButton.

- **Evidence:** `lib/widgets/animated_button.dart:89-121, 211-240; lib/widgets/custom_bottom_nav.dart:107-163; lib/widgets/animated_card.dart:9-268; lib/screens/work_log_screen.dart:159-179; lib/screens/settings_screen.dart:96-144`
- **Recommendation:** Delete lib/widgets except a new RollingAmount widget. Use FilledButton/FilledButton.tonal, IconButton(tooltip:), NavigationBar/NavigationRail, Card.filled, ListTile, Checkbox, SegmentedButton and component themes.

### [medium] Global / motion

Every touchable element scales on press (0.95/0.98/0.9) and every container tweens color and border (AnimatedContainer, 300 ms). With the easeOutBack overshoot in the nav, the UI feels rubbery and slow ('klobig'). Every list row owns its own AnimationController, and the whole Home screen rebuilds every second.

- **Evidence:** `lib/widgets/animated_button.dart:43-52, 191-200; lib/widgets/animated_card.dart:43-52, 190-199, 90-96, 218-233; lib/widgets/custom_bottom_nav.dart:91, 122-131, 142; lib/providers/timer_provider.dart:55-64`
- **Recommendation:** Use Material state layers and ripples only for press feedback. Keep 3 purposeful animations (digit roll on cent change, start/stop state change, button shape morph). No per-row controllers.

### [medium] Global / layout

Gutters are inconsistent and margins nest. Home uses 20 dp. Log uses 32 dp (ListView 16 + row margin 16) and content starts at 48 dp. In Settings, text starts at 56 dp (16 + 16 + 24), and the 'Alle Einträge löschen' text starts at about 132 dp (nested AnimatedCard margin 16 + padding 20 + icon 24 + gap 16), leaving a narrow column on a 360 dp phone. Month headers (20 dp) don't align with row cards (32 dp).

- **Evidence:** `lib/screens/home_screen.dart:56; lib/screens/work_log_screen.dart:112, 125; lib/widgets/animated_card.dart:93, 111, 144-145, 221, 247; lib/screens/settings_screen.dart:33, 188-224`
- **Recommendation:** One spacing system: a 16 dp screen margin on compact and 24 dp on medium or wider, and list content aligned to a single keyline (16 dp + 56 dp leading). No margins inside reusable widgets; the parent controls spacing.

### [low] Global / visual language

There are seven different corner radii (2, 4, 8, 12, 20, 28, 50) and ad-hoc font sizes (10, 12, 14, 16, 18, 22, 40, 52, 56) set through copyWith overrides. The textTheme is only partly defined, so bodySmall falls back to defaults.

- **Evidence:** `lib/theme/app_theme.dart:23-26, 93-133; lib/screens/work_log_screen.dart:133, 172, 187, 198, 205, 217; lib/screens/home_screen.dart:100, 135, 166, 186`
- **Recommendation:** Use the M3 shape scale (4/8/12/16/20/28/full) and the M3 type scale with named roles. No fontSize literals in screens.

### [medium] Global / surfaces

Outlines are heavy and boxes sit inside boxes. Every HighlightCard has a 1.5 px blue border. Paid rows get a blue tint plus border, the running timer gets a border, and Settings nests a card inside a card. The result is noisy and dated.

- **Evidence:** `lib/widgets/animated_card.dart:149-152, 223-233; lib/screens/home_screen.dart:128-130; lib/screens/settings_screen.dart:177-228`
- **Recommendation:** Use tonal surfaces (surfaceContainerLow/High) without borders. Outlines are only for inputs and the rare outlined card. Settings becomes a grouped list with 2 dp gaps, not cards containing cards.

### [medium] Navigation

The custom floating bottom bar hides the label of unselected destinations, uses long screen titles as nav labels ('Aktueller Verdienst', 'Arbeitszeit-Protokoll'), has no semantics, and animates width with an overshoot curve. It follows neither M3 NavigationBar (80 dp, always-visible labels, pill indicator) nor adaptive rules.

- **Evidence:** `lib/widgets/custom_bottom_nav.dart:38-60, 122-160; lib/main.dart:120-129`
- **Recommendation:** Use M3 NavigationBar with 3 short labels (Today / Shifts / Insights) on compact width, NavigationRail on medium or compact-height screens, and a rail plus panes on expanded.

### [medium] Navigation

Switching tabs cross-fades two full Scaffolds through AnimatedSwitcher, rebuilding and discarding the other screen. The Log scroll position is lost on every switch, and nested Scaffolds each with an AppBar complicate snackbars and insets.

- **Evidence:** `lib/main.dart:98-116; lib/screens/home_screen.dart:36; lib/screens/work_log_screen.dart:23`
- **Recommendation:** Use one Scaffold with IndexedStack, or go_router StatefulShellRoute.indexedStack, so tab state is preserved. Use a short fade-through on the incoming page or no transition.

### [low] Home / Log app bars

App-bar actions are 48 dp filled grey circles, heavier than M3 icon buttons, with no tooltips. On Home, the most prominent slot shows the brand name 'Chronos' instead of useful context.

- **Evidence:** `lib/screens/home_screen.dart:38-53; lib/screens/work_log_screen.dart:25-46; lib/widgets/animated_button.dart:226-238`
- **Recommendation:** Use standard IconButton with a tooltip. Title the Home screen with context ('Today, Wed 30 Sep'). Move 'Add' to an Extended FAB on Shifts.

### [high] Work log

Rows are tall (~100 dp: 3 text lines plus a badge, 16 padding, 4+4 margin), so only about 6 shifts fit on screen. Paid state is shown three ways (green checkbox, blue 'selected' tint and border, green 'Abgerechnet' badge). Blue normally means 'selected', which confuses. Earnings sit in the secondary position while duration is emphasized.

- **Evidence:** `lib/screens/work_log_screen.dart:155-239; lib/widgets/animated_card.dart:223-233`
- **Recommendation:** Use a dense two-line ListTile (72 dp): a leading date block (day number plus weekday), the title '08:00–16:15 · 8:15 h', the subtitle 'Job · break 30 min', and a trailing tabular amount with a small status icon (check = paid, clock = open). Show paid rows with the success icon and onSurfaceVariant text, and nothing else.

### [medium] Work log

The paid checkbox is a 28×28 dp GestureDetector (below the 48 dp minimum) inside a tappable row. The unpaid border contrast is about 2.0:1, and it has no semantics, so TalkBack can't read or toggle the paid state.

- **Evidence:** `lib/screens/work_log_screen.dart:159-179`
- **Recommendation:** Use a real Checkbox (48 dp target), swipe-to-toggle-paid with Undo, and a CustomSemanticsAction 'Mark as paid'.

### [medium] Work log

Tap and long-press both open the same options sheet, so the 'long-press' spec doesn't add anything. The sheet options are cards inside a sheet. Correcting an end time takes tap row → Edit → dialog → end time → dial picker → OK → Save: 6+ interactions with a dialog stacked on a dialog.

- **Evidence:** `lib/screens/work_log_screen.dart:156-157, 310-365, 621-783`
- **Recommendation:** Tap opens the editor sheet directly. Long-press starts multi-select (Android convention). Put edit/delete/duplicate inside the editor. Time fields accept keyboard input and ±15 min steppers.

### [medium] Work log

Month headers show only the month name, with no hours, earnings or open amount. You can't filter open vs paid or by job, and you can't search or pick a date range. The spec's unlimited history becomes endless scrolling.

- **Evidence:** `lib/screens/work_log_screen.dart:117-146`
- **Recommendation:** Use sticky month headers with the summary '42,5 h · 637,50 € · 318,75 € open', filter chips (All / Open / Paid / Job), and a month jump or date-range picker.

### [medium] Work log

The list is built eagerly with ListView(children:), creating every row widget plus its AnimationController up front. That's fine for 20 entries and janky for the unlimited history the spec requires.

- **Evidence:** `lib/screens/work_log_screen.dart:99-114`
- **Recommendation:** Use CustomScrollView with SliverList.builder per month, sticky headers (PinnedHeaderSliver or SliverPersistentHeader), and no per-row controllers.

### [low] Work log

The empty state is a grey circle with a 'work_off' icon (which reads as 'no work allowed') and 'Keine Einträge vorhanden'. There's no call to action and no explanation.

- **Evidence:** `lib/screens/work_log_screen.dart:55-83`
- **Recommendation:** An empty state with a friendly title ('No shifts yet'), one sentence, and two actions: 'Start timer' (goes to Today) and 'Add past shift'.

### [medium] Work log

Money formatting is inconsistent inside the same German UI. The log shows 'Verdient: 123.75 €' (dot decimal) while Home shows '123,75 €' (hard-coded comma). English users get a comma on Home.

- **Evidence:** `lib/screens/work_log_screen.dart:231; lib/widgets/animated_money_display.dart:20-32`
- **Recommendation:** Use a single Formatters service built on intl NumberFormat.currency(locale, name: currency) everywhere, including the notification and exports.

### [medium] Add / Edit entry

Add and Edit are AlertDialogs with three card-rows that open pickers stacked on top of the dialog. The two are duplicated code (2 × ~160 lines). Defaults are fixed at 08:00–16:00. There's no validation (end == start silently makes a 24 h shift), no overlap check, and no live preview of duration or earnings. Dates are limited to 2020–2030, allowing future dates up to 2030.

- **Evidence:** `lib/screens/work_log_screen.dart:421-585, 621-783, 425-427, 452-454, 551-553, 750-752`
- **Recommendation:** One ShiftEditor bottom sheet (full-screen dialog on compact when the keyboard is open, side sheet on expanded) with inline fields, smart defaults, a live '7:45 h × 15,00 €/h = 116,25 €' preview, and inline validation messages.

### [low] Dialogs

Every dialog restyles its buttons inline (a stadium ElevatedButton in electric blue, a grey TextButton). The confirm button for Stop is blue, the same as neutral confirms. Only one dialog uses barrierDismissible:false. Nothing comes from a dialog theme.

- **Evidence:** `lib/screens/home_screen.dart:213-245; lib/screens/work_log_screen.dart:270-302, 375-407, 432-581; lib/screens/settings_screen.dart:274-337`
- **Recommendation:** Use M3 defaults (TextButtons in dialogs; a destructive action as TextButton with the error color). Styles come from dialogTheme and the button themes, never inline.

### [medium] Feedback

Snackbars are color-coded: green for 'Eintrag gelöscht' and 'Alle Einträge gelöscht' (destructive actions shown as success), red for the informational 'Zeit zu kurz'. None offer Undo. Irreversible actions are guarded by confirmation dialogs instead of being undoable.

- **Evidence:** `lib/screens/work_log_screen.dart:412-417, 571-576; lib/screens/settings_screen.dart:240-245; lib/screens/home_screen.dart:264-271, 290-295`
- **Recommendation:** Use M3 snackbars (inverseSurface, floating) with an 'Undo' action for delete, paid toggle, payout and stop. Keep dialogs only for truly irreversible bulk actions.

### [high] Settings

'Delete all' is entirely hard-coded German (this is the known 'Alles löschen' bug). English users must type the German word 'Löschen'. The copy mixes 'du' and 'Sie' and uses the wrong imperative ('gebe' instead of 'gib'). It's a heavy red card nested in a card, and there's no export-before-delete.

- **Evidence:** `lib/screens/settings_screen.dart:176-229, 231-248, 251-340 (271, 280, 288, 293, 302)`
- **Recommendation:** Settings → Data & backup: Export, Backup/Restore, 'Delete paid shifts before…', and 'Delete all data…'. The last uses a standard localized destructive dialog with counts ('Delete 214 shifts and 2 jobs?'), an automatic backup snapshot and a 10 s Undo.

### [high] Settings

The wage input only accepts '.'. The regex blocks ',', which is the decimal key on German keyboards (e.g. Samsung, Gboard German number pad), so German users may not be able to enter cents at all. The replaceAll(',', '.') is dead code. The value is saved and pushed through the whole app on every keystroke (typing 15,50 briefly persists 1 €/h and retroactively re-prices all history). Empty or 0 input is silently ignored with no error. The field shows '15.00' in German.

- **Evidence:** `lib/screens/settings_screen.dart:343-409 (367, 381, 384, 403-408); lib/providers/settings_provider.dart:59-63; lib/l10n/app_de.arb:39`
- **Recommendation:** Move the rate into the Job editor. Use a locale-aware decimal field (accept both separators and normalize on blur), validate with an inline error, save on Done or blur, and show it formatted ('15,00 €/h'). Ask 'Apply from today / from date…' when it changes.

### [medium] Settings

There's no theme control even though the spec requires one. Language uses custom selectable tiles instead of standard controls, with no 'System default' option. There's no section structure, no about page, no privacy policy link and no licenses page.

- **Evidence:** `lib/screens/settings_screen.dart:35-50, 56-144`
- **Recommendation:** A grouped settings list: General (Language: System/Deutsch/English; Theme: System/Light/Dark as a SegmentedButton; Wallpaper colors switch), Work, Notifications, Data, About.

### [low] Settings

A manual back IconButton duplicates the automatic leading button. The version string 'Chronos v1.0' is hard-coded and doesn't match pubspec 1.0.0+1.

- **Evidence:** `lib/screens/settings_screen.dart:24-27, 42-49; pubspec.yaml:4`
- **Recommendation:** Remove the custom leading. Get the version from package_info_plus in an About section with privacy policy (localized), open-source licenses (showLicensePage) and a feedback mailto.

### [medium] Startup

The notification permission is requested during cold start, before runApp, so the first thing a new user sees is a system permission dialog over a black screen with no context. runApp waits for the answer. If any storage or JSON error occurs, a raw 'Startup Error: <exception>' screen appears in English with no theme and no way to recover.

- **Evidence:** `lib/main.dart:14-58 (27-28, 46-57); lib/services/notification_service.dart:16-29`
- **Recommendation:** Show UI immediately. Ask for the notification permission when the user first taps Start, with a one-line rationale sheet. Replace the error screen with a localized recovery screen ('Export raw data', 'Reset').

### [medium] Notification

The ongoing notification is German-only ('Arbeite', 'Verdient: 12.34 €' with a dot decimal, channel 'Arbeitssession'). The small icon is the full-color adaptive launcher mipmap, which renders as a white blob (and adaptive icons as notification icons are known to crash SystemUI on Android 8.0). There are no actions (Break/Finish) and no tap target. On Android 14+ non-foreground-service ongoing notifications are swipe-dismissible, and the app re-posts it within 15 s, so it keeps coming back.

- **Evidence:** `lib/services/notification_service.dart:12-14, 18, 35-60; lib/providers/timer_provider.dart:66-77`
- **Recommendation:** Localized title 'Recording · <job>', text 'Since 08:02 · 15,00 €/h', native chronometer, actions [Break] [Finish], tap opens Today, a monochrome vector small icon, and no periodic re-posting from Dart.

### [medium] Home / money counter

The rolling digits are positional children without keys. When the amount grows a digit (9,99 → 10,00, 99,99 → 100,00), every digit widget after the change is recreated and jumps instead of rolling. Each digit uses Opacity inside AnimatedBuilder (a saveLayer per frame). The direction is the opposite of the spec (from below). Cents advance in irregular 1 s steps.

- **Evidence:** `lib/widgets/animated_digit.dart:15-40 (24-28, 37); lib/widgets/animated_money_display.dart:25-50`
- **Recommendation:** A RollingAmount widget: characters keyed from the right, ClipRect + SlideTransition (enter from top per spec, 250 ms emphasizedDecelerate), no Opacity, and updates scheduled at the exact moment the next cent is earned, inside a RepaintBoundary.

### [low] Home

The timer uses fontFamily 'RobotoMono', which isn't declared in pubspec, so it silently falls back. Tabular figures aren't set anywhere, so width stability depends on the platform font.

- **Evidence:** `lib/screens/home_screen.dart:134-140; pubspec.yaml:24-26`
- **Recommendation:** Bundle the chosen font. Apply FontFeature.tabularFigures() in the money and time text styles.

### [medium] Home

The live counter shows unrounded time, but the saved entry is rounded to the quarter hour (7-minute threshold). After Stop, 'Gesamter offener Betrag' jumps up or down and the user doesn't know why. Rounding isn't visible or configurable anywhere.

- **Evidence:** `lib/screens/home_screen.dart:195-206, 259-262`
- **Recommendation:** Show the rounding in the Finish sheet ('08:02–16:09 → 08:00–16:15, rule: job 15 min'). Make rounding a per-job setting (default: none). Store raw and billed times.

### [high] Global / adaptive

There are no adaptive layouts at all: zero MediaQuery size, LayoutBuilder or orientation logic, so tablets and foldables get a stretched phone UI. New apps and updates must target API 36 since 31 Aug 2026, and on Android 16 apps targeting API 36 can't lock orientation or resizability on displays with smallest width ≥ 600 dp, so landscape and tablet must work.

- **Evidence:** `grep over lib/: only MediaQuery use is lib/widgets/custom_bottom_nav.dart:38; android/app/build.gradle:65 targetSdkVersion flutter.targetSdkVersion`
- **Recommendation:** Use window-size-class breakpoints (compact <600, medium 600-839, expanded ≥840; compact height <480): NavigationBar → NavigationRail → rail plus list-detail panes. Cap reading width at 840 dp and test on 7" and 10" emulators and foldables.

### [low] Launcher icon

The icon is a highly detailed neon illustration that becomes illegible at 48 dp. The 2048×2048 PNG is copied into all 5 densities (about 11 MB of icons in the source). The adaptive icon has a transparent background (launcher-dependent look) and no monochrome layer for Android 13+ themed icons.

- **Evidence:** `android/app/src/main/res/mipmap-*/ic_launcher.png (2048x2048, 2.2 MB each); android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
- **Recommendation:** A simplified mark (hourglass + € silhouette) on a solid navy #001F3F background layer, a sky foreground, a monochrome layer and a notification silhouette. Generate densities with flutter_launcher_icons.

### [low] Splash / system bars

The splash color #121212 is used for both day and night, and the Android 12+ SplashScreen isn't configured, so light-mode users get a dark flash. System bar icon brightness isn't managed for the future light theme.

- **Evidence:** `android/app/src/main/res/values/colors.xml:3; values/styles.xml and values-night/styles.xml (identical)`
- **Recommendation:** flutter_native_splash with day #F6F9FC / night #0B1320 and the icon. Set SystemUiOverlayStyle through AppBarTheme and an AnnotatedRegion per brightness, with edge-to-edge enabled.

### [medium] Global / feedback

There's no haptic feedback anywhere. Start, stop and marking paid are important physical actions that a worker in a noisy, busy catering setting often does without looking.

- **Evidence:** `grep HapticFeedback over lib/: 0 hits`
- **Recommendation:** HapticFeedback.mediumImpact on start/finish, selectionClick on paid toggle and steppers, heavyImpact on destructive confirmations.

### [low] Work log / formats

The duration '8:45h' reads like a clock time. The list always shows 24 h times, but the add/edit pickers show 12 h 'AM/PM' in English (TimeOfDay.format), so the same data looks different in two places. Overnight rows show a long '22:00 (30.09.) – 02:00 (01.10.)'.

- **Evidence:** `lib/models/work_entry.dart:28-46; lib/screens/work_log_screen.dart:473, 497, 246-255`
- **Recommendation:** Use a duration format like '8 h 45 min' (compact '8:45 h'), times through DateFormat.Hm/jm respecting MediaQuery.alwaysUse24HourFormat, and an overnight marker '+1'.

### [low] Home

Side effect in build: timer.setHourlyWage(...) is only called while Home is built, so a wage change made while another tab is visible isn't picked up by the notification. The isLoading spinners are dead code, because settings load before runApp.

- **Evidence:** `lib/screens/home_screen.dart:24-31; lib/screens/settings_screen.dart:30-31`
- **Recommendation:** Derive the rate from the active job in the timer/session model, not from widget build. Remove the dead loading branches.


## Flow problems

### Start / Stop a shift

**Problem:** Stop shows an 'Are you sure?' dialog with no information. After confirming, times are silently rounded to the quarter hour, and sessions under 15 min are discarded after the timer has already stopped (the data is lost). There are no breaks or pauses. There's no way to backdate a forgotten start or fix a forgotten stop, and nothing reminds you if the timer keeps running (a 50 h entry is possible). You can't choose which job the shift is for. IDs are millisecond strings here but UUIDs elsewhere.

**Evidence:** lib/screens/home_screen.dart:195-298 (256-272 discard); lib/providers/timer_provider.dart:32-51; lib/screens/work_log_screen.dart:562

**Better flow:** Start is one tap with haptic feedback. It uses the default or last job, shown as a chip you can change. Right after Start, an inline chip 'Started earlier? −5 / −15 / Set time' allows backdating. While running, [Break] creates break segments with a live break counter, and optional auto-break rules come from the job (e.g. 30 min after 6 h, 45 min after 9 h). [Finish] opens a Finish-shift sheet: raw vs rounded times, breaks, duration, earnings, optional tip and note, and Save / Keep running / Discard. Dismissing the sheet keeps the timer running, so the sheet itself is the spec's double confirmation, and it carries information. Short sessions are saved with a hint ('Only 9 min, save anyway?'), never silently dropped. Safety nets: a notification after X hours (default 10 h) and at the job's usual end time with [Finish] / [Still working]; above 16 h the Finish sheet asks for the real end time.

### Today's earnings (page 1 hero)

**Problem:** The spec asks for the amount earned today. The implementation shows only the current session: 0,00 € when idle, and it resets for a second shift on the same day. The open total is computed with the current wage for all history.

**Evidence:** lib/screens/home_screen.dart:33-34; lib/providers/timer_provider.dart:79-83; lib/providers/work_entries_provider.dart:14-16

**Better flow:** Running: the hero is this shift, with a line 'Today total 87,40 €' when there was an earlier shift today. Idle: the hero is the unpaid balance, plus 'Today', 'This week' and 'Last shift' summaries. All sums use each entry's stored rate.

### Manual entry (add)

**Problem:** A dialog with 3 pickers stacked on top of it, fixed defaults of 08:00–16:00, and no validation. End ≤ start silently becomes the next day, and end == start becomes a 24 h shift (the endAfterStart string exists but is unused). No overlap or duplicate check, no break, job, tip or note, dates up to 2030, and no preview of what the entry is worth.

**Evidence:** lib/screens/work_log_screen.dart:421-585; lib/l10n/app_de.arb:38

**Better flow:** An Extended FAB 'Add shift' opens the ShiftEditor sheet. It's prefilled from the last shift of the same job and weekday, with the date defaulting to today, or the day after the last entry if today already has a shift. Time fields accept typed input ('0815', '8:15') and have ±15 min steppers. The time picker opens in input mode. A live preview shows 'Mon 30 Sep · 8:15 h − 0:30 break = 7:45 h · 116,25 €'. If end < start, an explicit 'Ends next day' switch turns on and stays visible. Inline errors: end == start, duration > 16 h (warning), overlap with another shift (with a link to it), future date (warning, or a planned-shift feature later). 'Save' plus an overflow item 'Save & add another'.

### Edit entry

**Problem:** Tap → options sheet → Edit → dialog → per-field pickers. You can only edit date and times; job, break, notes and paid state can't be changed in the editor. Tap and long-press do the same thing.

**Evidence:** lib/screens/work_log_screen.dart:156-157, 310-365, 621-783

**Better flow:** Tap a row to open the same ShiftEditor with all fields, including a Paid/Open segmented control. Actions in the editor: Delete (with Undo snackbar) and Duplicate. Long-press enters multi-select mode with a contextual top bar (Mark paid · Export · Delete).

### Delete entry

**Problem:** Three steps (sheet → non-dismissible dialog → green snackbar) with no undo. The destructive result is shown with a success color.

**Evidence:** lib/screens/work_log_screen.dart:348-358, 367-419

**Better flow:** Swipe end-to-start deletes immediately and shows a snackbar 'Shift deleted' with [Undo] (8 s). Deleting from the editor or multi-select works the same way. No confirmation dialogs for single deletes.

### Paid / unpaid

**Problem:** Only a per-entry toggle through a tiny checkbox. Marking paid is instant, but un-marking asks for confirmation (asymmetric). There's no record of when or how much was paid, so after payday the user has to tick maybe 20 rows one by one. Paid entries are included in the same endless list.

**Evidence:** lib/screens/work_log_screen.dart:159-179, 257-308; lib/providers/work_entries_provider.dart:40-47

**Better flow:** Add a Payout concept. From the Today unpaid card or Shifts multi-select, 'Record payout' opens a sheet: period preset 'All open up to [31 Aug]' (or the current selection), a summary '23 shifts · 172,5 h · 2.587,50 €', an optional 'Amount received' field (the difference is shown as deductions or bonus), the payout date and a note. Saving marks every linked shift Paid and shows an Undo snackbar. Rows show a small 'Paid 5 Sep' status. A single swipe start-to-end toggles paid for one row, with Undo. Insights shows the payout history.

### Hourly wage

**Problem:** There's one global wage, and entries don't store their rate. Changing the wage re-prices the entire history, including paid entries (data integrity). The input saves on every keystroke, blocks the comma, and silently ignores 0 or empty. The default of 15 € is arbitrary; the German minimum wage in 2026 is 13,90 €/h.

**Evidence:** lib/models/work_entry.dart:18-21; lib/providers/work_entries_provider.dart:14-16; lib/screens/settings_screen.dart:343-409; lib/models/app_settings.dart:13

**Better flow:** The rate belongs to a Job, with a rate history (effective-from dates). Each entry stores the rate used when it was created. Editing the rate asks 'Apply from: today / date… / also to open shifts'. Input is a locale-aware currency field with validation, saved on Done. Onboarding asks for the rate once, with the minimum wage as a hint and no hidden default.

### Delete all

**Problem:** You must type the German word 'Löschen', even in English. There's no export or backup first and no scope other than 'everything'. The success is shown as a green snackbar. The feature is in Settings but not discoverable next to the data it affects.

**Evidence:** lib/screens/settings_screen.dart:176-340

**Better flow:** Settings → Data & backup. The main actions are 'Export timesheet…' and 'Create backup'. Housekeeping: 'Delete paid shifts before [date]…'. At the bottom: 'Delete all data…', a standard localized destructive dialog with explicit counts. It automatically writes a backup snapshot first and offers Undo for the session.

### Totals and insight

**Problem:** The only aggregate is one 'open total'. There are no hours per week or month, no per-job or per-month sums, no average hourly figure including tips, and no progress toward a Minijob cap. That's why the owner feels the app 'can do too little'.

**Evidence:** lib/providers/work_entries_provider.dart:11-16; lib/screens/work_log_screen.dart:117-146

**Better flow:** An Insights tab: Week / Month / Year segmented control with ‹ period › stepper, stat cards (hours, earned, unpaid, average €/h incl. tips), a bars-per-day/week chart colored by job, a Minijob or monthly-cap progress bar (configurable; 603 €/month in DE for 2026), a by-job breakdown, and payout history. Month summaries also appear in the Shifts sticky headers.

### Rounding and minimum duration

**Problem:** Quarter-hour rounding (7-min threshold) and a 15-min minimum are hard-coded, invisible and applied only to timer sessions, not manual entries. The raw times are lost.

**Evidence:** lib/screens/home_screen.dart:195-206, 256-272

**Better flow:** Per-job setting: Rounding None / 5 / 10 / 15 min; mode Nearest / Up / Down, optionally separate for start and end. Default None. Store raw and billed times, show both in the Finish sheet and the editor, and apply the same rule everywhere.

### Overnight and DST shifts

**Problem:** Grouping uses the start month. The manual 'end ≤ start ⇒ next day' rule is implicit. Display shows dates twice. There's no hint when a night shift crosses a DST change (the EU switch is 25 Oct 2026: 22:00–06:00 is really 9 h).

**Evidence:** lib/screens/work_log_screen.dart:89-94, 246-255, 551-553; lib/models/work_entry.dart:23-37

**Better flow:** An explicit 'Ends next day' switch in the editor and a '+1' badge in rows. The duration preview notes 'includes clock change (+1 h)'. Group by the shift's start date, which should be documented in the UI.

### Language default

**Problem:** The default language is German regardless of the device language, so English-speaking testers first see German. There's no 'System' option.

**Evidence:** lib/models/app_settings.dart:11, 38-41; lib/main.dart:81

**Better flow:** Add an AppLanguage.system default (MaterialApp.locale = null, localeResolutionCallback falls back to en). Settings offers System / Deutsch / English. Formatting uses the full device locale (e.g. de_AT for 'Jänner'), and strings use the language.

### Notifications and permission

**Problem:** The permission is asked at cold start without context, and startup is blocked until it's answered. The notification has no actions, and on Android 14+ it's dismissible and keeps re-appearing. A denied permission is never explained.

**Evidence:** lib/main.dart:27-28; lib/services/notification_service.dart:16-29; lib/providers/timer_provider.dart:66-77

**Better flow:** Ask on the first Start with a rationale bottom sheet ('See your running shift on the lock screen and stop it from there'). If denied, show an inline banner on Today with [Enable] that opens the app notification settings. The notification offers [Break] [Finish] actions; tap opens Today or the Finish sheet.

### Data safety (export, backup, recovery)

**Problem:** All data is a single JSON string in SharedPreferences. There's no export for handing a timesheet to an employer, and no manual backup or restore. If the JSON is corrupted, startup shows a raw error screen and the data can't be reached. android:allowBackup isn't set, so Android Auto Backup may copy the data to the user's Google Drive, which contradicts privacy.html ('verlassen dieses niemals').

**Evidence:** lib/services/storage_service.dart:43-56; lib/main.dart:46-57; android/app/src/main/AndroidManifest.xml:6-9; privacy.html:31

**Better flow:** Export (PDF timesheet per job/month for the employer, CSV for Excel with decimal hours in locale format) through the share sheet. Backup/Restore to a JSON file through the Storage Access Framework. A friendly recovery screen with 'Export raw data' and 'Reset'. Decide on Auto Backup explicitly (data-extraction rules) and update the privacy policy (DE and EN).

### Multiple jobs / employers

**Problem:** Catering workers often work for several agencies or venues with different rates and payout cycles. The app can't tell them apart.

**Evidence:** lib/models/work_entry.dart:1-83 (no job field); lib/models/app_settings.dart:8

**Better flow:** Jobs (name, color, rate history, rounding, break rules, optional surcharges for night/Sunday/holiday in %, monthly cap, payout cycle). If only one job exists, all job UI is hidden.

### Tips, surcharges and notes

**Problem:** No place for Trinkgeld, night or Sunday surcharges, or notes (event name, location), even though these matter most in catering.

**Evidence:** lib/models/work_entry.dart:1-83

**Better flow:** Optional tip field in the Finish sheet and the editor. Surcharge rules on the job are applied automatically and shown as a separate line in the preview. A free-text note shows as a subtitle in the row.

### Quick access outside the app

**Problem:** The timer can only be controlled by opening the app. Workers need to start or stop quickly at shift change.

**Evidence:** lib/services/notification_service.dart (no actions); no widget or tile code

**Better flow:** Notification actions, a Quick Settings tile (Start/Finish), a home-screen widget (2×1 status + button; 4×2 today + unpaid), and launcher shortcuts (long-press icon: 'Start shift', 'Add shift').

### Onboarding

**Problem:** On first launch the app is in German with a 15 € wage the user never set, and a permission dialog appears before any UI.

**Evidence:** lib/models/app_settings.dart:11-13; lib/main.dart:27-28

**Better flow:** Two short steps: Welcome ('Track shifts. See your pay grow live.') → 'Your job': name (optional), hourly rate (required, locale field), currency. Everything else can be changed later. The permission is deferred to the first Start.


## Localization gaps

| Location | Text | Fix |
|---|---|---|
| `lib/screens/settings_screen.dart:182` | 'Datenverwaltung' (section title) | New key dataSection: 'Daten & Sicherung' / 'Data & backup'. |
| `lib/screens/settings_screen.dart:203` | 'Alle Einträge löschen' (the known 'Alles löschen' bug: stays German in English) | Key deleteAllData: 'Alle Daten löschen…' / 'Delete all data…'. |
| `lib/screens/settings_screen.dart:210` | 'Löscht alle Arbeitszeiteinträge unwiderruflich' | Key deleteAllDataSubtitle with an ICU plural count: '{count, plural, =1{1 Schicht} other{{count} Schichten}} werden endgültig gelöscht'. |
| `lib/screens/settings_screen.dart:242` | Snackbar 'Alle Einträge gelöscht' | Key allDataDeleted plus an Undo action (key undo). |
| `lib/screens/settings_screen.dart:280` | Dialog title 'Alle Daten löschen?' | Key deleteAllDialogTitle. |
| `lib/screens/settings_screen.dart:288` | 'Diese Aktion kann nicht rückgängig gemacht werden. Alle Arbeitszeiteinträge werden unwiderruflich gelöscht.' | Key deleteAllDialogBody with {shifts} and {jobs} plural placeholders. |
| `lib/screens/settings_screen.dart:293` | 'Zum Bestätigen gebe das Wort "Löschen" ein:' (wrong imperative 'gebe' → 'gib', and uses 'du' while other strings use 'Sie') | Replace the typed confirmation with a standard destructive dialog. If kept, use key deleteConfirmPrompt with a localized {word}. |
| `lib/screens/settings_screen.dart:271, 302` | Validation input == 'Löschen' \|\| 'Loeschen' and hintText 'Löschen': English users must type a German word | Compare against l10n.deleteConfirmWord ('LÖSCHEN' / 'DELETE') case-insensitively, or drop it. |
| `lib/screens/settings_screen.dart:44` | 'Chronos v1.0' (hard-coded, wrong vs pubspec 1.0.0+1) | package_info_plus + key versionLabel: 'Version {version} ({build})'. |
| `lib/screens/settings_screen.dart:73, 83` | 'Deutsch' / 'English' (endonyms are fine) but no 'System default' option | Keep the endonyms. Add key languageSystem: 'Systemsprache' / 'System default'. |
| `lib/screens/settings_screen.dart:162` | Suffix built by concatenation: '/ ${l10n?.hours ?? 'h'}' | ICU message ratePerHour: '{amount}/Std.' / '{amount}/h' with amount pre-formatted by NumberFormat.currency. |
| `lib/screens/settings_screen.dart:166; lib/l10n/app_de.arb:39` | 'Beispiel: 15 oder 15.50' shows a dot decimal in German | Generate the example with NumberFormat (German '15 oder 15,50'), or drop the helper and validate inline. |
| `lib/screens/settings_screen.dart:367` | Initial wage text uses toStringAsFixed(2), so '15.00' appears in German | NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 2).format(rate). |
| `lib/screens/settings_screen.dart:384` | Input regex allows only '.' as decimal separator (the German comma is blocked) | Accept both ',' and '.', normalize with NumberFormat.decimalPattern(locale).parse on blur, and show a localized error key invalidRate. |
| `lib/screens/settings_screen.dart:387; home_screen.dart:39,63,70,165,185,219,223,230,242,267,292; work_log_screen.dart:26,75,201,231,276,280,287,299,343,355,381,385,392,404,414,438,446,472,496,524,573,579,637,645,671,695,723,771,777; settings_screen.dart:23,62,152,161,166,322,335; main.dart:123,127` | German `?? '…'` fallbacks after every l10n?. lookup (e.g. 'Gehaltszähler', 'Lohn eingeben', 'Live', 'Log') | Set `nullable-getter: false` in l10n.yaml, add a `context.l10n` extension, and delete all fallbacks so a missing key fails at compile time. |
| `lib/l10n/app_de.arb:18; lib/l10n/app_en.arb:61` | 'Stundenlohn (€)' / 'Hourly Wage (€)': currency baked into the translation | 'Stundenlohn' / 'Hourly rate', with the currency symbol taken from the selected currency (NumberFormat.simpleCurrency). |
| `lib/services/notification_service.dart:13-14` | Channel name 'Arbeitssession' and description 'Zeigt die aktive Arbeitssession an' (German for all users) | Pass localized strings into init. Re-create the channel (same id) on locale change so the name in system settings updates. |
| `lib/services/notification_service.dart:57` | Notification title 'Arbeite' | Key notifRecordingTitle: 'Läuft · {job}' / 'Recording · {job}'. |
| `lib/services/notification_service.dart:35, 58` | 'Verdient: $earningsString €' (dot decimal, € suffix hard-coded) | Key notifRecordingBody: 'Seit {start} · {rate}' with DateFormat.Hm/jm and NumberFormat.currency. Add action labels notifActionBreak and notifActionFinish. |
| `lib/main.dart:53` | 'Startup Error: $e' (English, raw exception) | A localized recovery screen using lookupAppLocalizations(PlatformDispatcher.instance.locale): 'Chronos konnte deine Daten nicht laden' plus [Export raw data] [Reset]. |
| `lib/main.dart:69` | title: 'Chronos' | Use onGenerateTitle: (c) => c.l10n.appTitle (the brand name is the same, but this keeps it in one place). |
| `lib/main.dart:123, 127` | Nav labels reuse currentEarnings ('Aktueller Verdienst') and workTimeLog ('Arbeitszeit-Protokoll'), with fallbacks 'Live'/'Log' | Short dedicated keys: navToday 'Heute'/'Today', navShifts 'Schichten'/'Shifts', navInsights 'Übersicht'/'Insights'. |
| `lib/screens/home_screen.dart:116-133` | Timer string built manually as HH:MM:SS; no spoken form | Keep the visual H:MM:SS with tabular digits, and add a semantics label via an ICU plural key durationSpoken: '{h} Stunden {m} Minuten'. |
| `lib/widgets/animated_money_display.dart:14, 20-23, 32, 37-42` | Default currency '€', split on '.', hard-coded ',' decimal separator, € always as a suffix, no grouping (1234,56) | Format with NumberFormat.currency(locale, name: currencyCode) and roll only digit glyphs, keeping separators and the symbol static. English shows '€1,234.56', German '1.234,56 €'. |
| `lib/screens/work_log_screen.dart:231` | '${earned}: ${earnings.toStringAsFixed(2)} €' (dot decimal in German, concatenation) | Show the amount alone in the trailing slot, formatted with NumberFormat.currency. If a label is needed, use ICU 'earnedAmount': 'Verdient: {amount}'. |
| `lib/screens/work_log_screen.dart:242-244` | _formatDate hard-codes 'dd.MM.yyyy' | DateFormat.yMMMEd(locale) in the editor ('Mi., 30. Sept. 2026' / 'Wed, Sep 30, 2026'). |
| `lib/screens/work_log_screen.dart:246-255` | _formatEntryDate hard-codes 'dd.' / 'dd.MM.yyyy', no weekday, overnight as '30. – 01.10.2026' | A leading date block with DateFormat.d and DateFormat.E (weekday). Overnight shown with a '+1' badge. |
| `lib/screens/work_log_screen.dart:122` | Month header built as '$monthName $year' by concatenation | DateFormat.yMMMM(locale) for other years and DateFormat.MMMM for the current year. |
| `lib/screens/work_log_screen.dart:129-134` | Month header forced uppercase with letterSpacing 2 | Sentence case, titleSmall. Uppercasing German nouns is awkward and not M3 style. |
| `lib/screens/work_log_screen.dart:473, 497, 672, 696` | TimeOfDay.format(context) gives 12 h 'AM/PM' in English, while the list always shows 24 h | One time formatter: MediaQuery.alwaysUse24HourFormatOf(context) ? DateFormat.Hm(locale) : DateFormat.jm(locale), used for pickers, rows, notification and export. |
| `lib/models/work_entry.dart:28-37` | formattedTimeRange hard-codes 'HH:mm' and 'dd.MM.' in the model | Remove formatting from the model and put it in a UI-layer Formatters class with DateFormat. Use an en dash with thin spaces. |
| `lib/models/work_entry.dart:39-46` | formattedDuration '8:45h' / '8h' (hard-coded unit, looks like a clock time) | ICU keys durationShort '{h} h {m} min' (DE/EN), compact '8:45 h'. Decimal hours for export use locale decimals ('8,75'). |
| `lib/l10n/app_de.arb:6-7; lib/l10n/app_en.arb:49-50` | 'START' / 'STOPP' / 'STOP' uppercase inside the translations | 'Schicht starten' / 'Start shift', 'Beenden' / 'Finish', 'Pause' / 'Break'. Casing is a style concern, not a string concern. |
| `lib/l10n/app_de.arb:9 vs lib/screens/settings_screen.dart:293 vs privacy.html` | Formality is mixed: 'Sind Sie sicher…' (Sie) vs 'gebe … ein' (du) vs the privacy policy in 'du' | Choose 'du' consistently (usual for hospitality and personal apps in DE/AT) and add a short glossary (Schicht, Pause, Auszahlung, offen, bezahlt). |
| `lib/l10n/app_en.arb:48, 55, 73, 84, 47` | Awkward English: 'Total Open Amount', 'Work Time Log', 'No entries available', 'Remove billing?', 'Current Earnings' | 'Unpaid balance', 'Shifts', 'No shifts yet', 'Mark as unpaid?', 'This shift'. Have a native speaker review. |
| `lib/l10n/app_de.arb:36; lib/l10n/app_en.arb:79` | tooShortEntry hard-codes '15 Min' in the text | Placeholder {minutes} (and the flow changes to 'save anyway?'). |
| `lib/l10n/app_de.arb:15-17, 20, 27, 32, 38` | Unused keys theme, darkMode, lightMode, workEntries, totalTime, minutes, endAfterStart (a sign of missing features: theme toggle, end-time validation) | Use them (theme SegmentedButton, editor validation) or delete them. Add @key descriptions for translators. |
| `lib/l10n/app_de.arb, lib/l10n/app_en.arb (all)` | No @descriptions, no placeholders, no ICU plurals or selects | Add metadata. Plurals for counts ('{count, plural, =1{1 Schicht} other{{count} Schichten}}'), a select for paid/open status, and number/date placeholders with format types. |
| `lib/models/app_settings.dart:11, 40; lib/main.dart:81` | Default language German regardless of device locale | AppLanguage.system as default. MaterialApp.locale = null for system. Keep the full device locale (de_AT, de_CH, en_GB) for intl formatting. |
| `lib/main.dart:77-80` | supportedLocales hard-coded | AppLocalizations.supportedLocales and AppLocalizations.localizationsDelegates (generated). |
| `lib/screens/work_log_screen.dart:118-121` | The only locale-aware formatting in the app (DateFormat('MMMM', locale)): everything else ignores the locale | Centralize in lib/core/formatters.dart (money, rate, time, date, duration, decimal hours) and forbid toStringAsFixed/padLeft date building in UI code. |
| `lib/widgets/*.dart, lib/screens/*.dart (every icon-only control)` | No semantic labels or tooltips anywhere (settings gear, add, paid checkbox, nav items) | Localized tooltips and semantic labels: tooltipSettings, tooltipAddShift, a11yMarkPaid('{date}'), a11yMarkUnpaid, a11yDeleteShift, a11yRunningAmount. |
| `privacy.html:2 (lang=de)` | Privacy policy is German only, while the Play listing and English UI need an English version | Publish privacy-en.html (or a bilingual page), link both from Settings → About by locale, and update it for export/backup and Auto Backup. |
| `lib/screens/work_log_screen.dart:452-454, 651-653` | Date picker bounds DateTime(2020)–DateTime(2030) (not a string, but the UX changes by locale and year) | firstDate 2000 (or the earliest entry), lastDate today (or today + 1 year if planned shifts are added). Use the locale-aware picker in input mode where precision matters. |
| `android/app/src/main (future)` | Launcher shortcuts, Quick Settings tile and widget labels will need Android string resources | Add res/values/strings.xml and res/values-de/strings.xml for native surfaces (shortcut 'Start shift', tile label). |

## Design system

## Chronos Design System v2: "Navy Night / Sky Day"

**Principles**
1. **One hero per screen.** The number that matters in the current state gets the stage, and everything else is supporting text.
2. **Tonal surfaces, not borders.** Hierarchy comes from surfaceContainer levels, not outlines or shadows.
3. **Motion only when something changes meaning** (a cent is earned, a shift starts or ends). Nothing loops and nothing wobbles.
4. **Thumb-first.** Primary actions sit in the lower half, with targets of 48 dp or more.
5. **Calm and trustworthy, like a banking app, with a hint of sky.**

### 1. Color tokens (contrast-checked, WCAG 2.x)
Brand anchors from the spec and icon: **Navy #001F3F** (icon background, splash accents, marketing), **Sky #87CEEB** (light-mode live state), and the icon's signal blue expressed as primary. Neutrals are navy-tinted (hue ≈ 215°), so dark mode reads as the spec's "navy + anthracite" and not pure grey.

| Role | Light ("Sky Day") | Dark ("Navy Night") |
|---|---|---|
| primary / onPrimary | **#14548C** / #FFFFFF (7.85:1) | **#9CCFF5** / #00324F (8.07:1) |
| primaryContainer / on | #CFE8F7 / #002A48 (11.6:1) | #0F3E63 / #CFE8F7 (8.75:1) |
| secondary / onSecondary | #3F6178 / #FFFFFF (6.6:1) | #B5C9DA / #1F3344 (7.6:1) |
| secondaryContainer / on (nav indicator) | #D3E7F4 / #0C2C40 (11.4:1) | #2A3E52 / #D3E7F4 (8.65:1) |
| tertiary = **Open / pending** (amber) / on | #7A4A00 / #FFFFFF (7.5:1) | #F3BD6E / #432C00 (7.7:1) |
| tertiaryContainer / on | #FFDDB0 / #2B1800 (13.2:1) | #5E3F00 / #FFDDB0 (7.4:1) |
| error / onError | #B3261E / #FFFFFF (6.5:1) | #FFB4AB / #690005 (7.7:1) |
| errorContainer / on | #F9DEDC / #410E0B (12.8:1) | #93000A / #FFDAD6 (7.2:1) |
| surface (= background) | #F6F9FC | #0B1320 |
| surfaceDim / surfaceBright | #D3DEE8 / #F6F9FC | #0B1320 / #2B394B |
| surfaceContainerLowest | #FFFFFF | #070C14 |
| surfaceContainerLow (cards, sheets) | #EFF4F9 | #111B2A |
| surfaceContainer (nav bar/rail, menus) | #E9F0F6 | #152131 |
| surfaceContainerHigh (dialogs, selected rows) | #E2EBF3 | #1B2738 |
| surfaceContainerHighest (inputs, chips) | #DBE5EF | #233142 |
| onSurface | #0F1A26 (16.6:1 on surface) | #E3E9F0 (15.2:1) |
| onSurfaceVariant | #43505E (7.8:1) | #B9C6D3 (10.7:1) |
| outline (UI boundaries, ≥3:1) | #6E7B88 (4.1:1) | #8894A1 (6.0:1) |
| outlineVariant (dividers only, decorative) | #C3CFDA | #37475A |
| inverseSurface / onInverse (snackbars) | #25313D / #EAF1F8 (11.6:1) | #E3E9F0 / #1C2733 (12.4:1) |
| inversePrimary (snackbar action) | #9CCFF5 (8.0:1 on inverse) | #14548C (6.4:1) |
| scrim / shadow | #000000 | #000000 |

**ThemeExtension `ChronosColors`** (semantic colors that M3 doesn't have):
| Token | Light | Dark | Use |
|---|---|---|---|
| success / onSuccess | #1B6B3A / #FFFFFF (6.5:1) | #8FD8A5 / #00391C (7.8:1) | **Paid** icon, payout confirmations |
| successContainer / on | #C4EFCF / #002110 | #0E5130 / #C4EFCF | Paid chip |
| liveContainer / onLive | **#87CEEB** / #002A48 (8.5:1) | #0F3E63 / #CFE8F7 | Running-shift hero card |
| liveIndicator | #14548C | #9CCFF5 | Static "recording" dot (no pulsing) |
| jobPalette[6] | #1F6FB2, #00796B, #9A6200, #B03A5B, #6A4FB3, #2E7D32 | #8CC4F2, #6FD6C6, #F3BD6E, #F4A7BC, #C8B6FF, #9ED79A | Job dots, chart series (check ≥3:1 vs surface before shipping) |

Checked contrasts: all text pairs above are ≥ 4.5:1, and outline is ≥ 3:1 against surface in both modes (light outline on surfaceContainerHighest is 3.39:1). For comparison, today's UI has **white on #22C55E at 2.28:1 (START button, "Abgerechnet" badge), white on #3B82F6 at 3.68:1, and the unpaid checkbox border at about 2.0:1**, all failing.

**Implementation:** put explicit `ColorScheme(...)` constants in `lib/theme/color_schemes.dart`. Either generate them once in Material Theme Builder from seed #14548C (variant *fidelity*) and hand-tune the navy surfaces as above, or use `ColorScheme.fromSeed(seedColor: Color(0xFF14548C), dynamicSchemeVariant: DynamicSchemeVariant.fidelity, brightness: b).copyWith(surface…: …)`. Use `Color.withValues(alpha:)`, not the deprecated `withOpacity`.

**Dynamic color (optional):** a Settings switch "Use wallpaper colors" (Android 12+) through the `dynamic_color` package (`DynamicColorBuilder`), **default off** to keep the brand. When on, take primary/secondary/surfaces from the wallpaper scheme, keep the `ChronosColors` semantics and harmonize them to the dynamic primary (`Color.harmonizeWith`). Splash and icon stay brand.

### 2. Typography
- **Font:** **Roboto Flex** (OFL), **bundled as an asset** and subset to Latin. Don't use the `google_fonts` runtime download: privacy.html promises "no internet connection". It's variable (wght/wdth/opsz), matches Android and M3, and has tabular figures. The zero-cost alternative is the system Roboto.
- **All numbers** (money, times, durations, stats) use `fontFeatures: [FontFeature.tabularFigures()]`, so the counter never jitters horizontally.
- Scale (sp; M3 baseline plus 3 app roles):

| Role | Size / line | Weight | Used for |
|---|---|---|---|
| **moneyHero** (custom, from displayLarge) | 57/64 (compact), 72/80 (expanded) | 600, tnum, wdth 95 | Running-shift amount. Cents at 0.6× in onSurfaceVariant. Wrapped in FittedBox(scaleDown) |
| displaySmall | 36/44 | 500 tnum | Idle hero: unpaid balance |
| headlineSmall | 24/32 | 500 | Sheet titles, stat card values |
| **timer** (custom, from titleLarge) | 22/28 | 500 tnum | "3:11:42" |
| titleLarge | 22/28 | 400 | Top app bar |
| titleMedium | 16/24 | 500 (tnum for amounts) | List primary line, trailing amounts |
| titleSmall | 14/20 | 500 | Month and section headers (sentence case) |
| bodyLarge / bodyMedium / bodySmall | 16/24, 14/20, 12/16 | 400 | Body, secondary lines, month summaries |
| labelLarge / labelMedium / labelSmall | 14/20, 12/16, 11/16 | 500 | Buttons / nav labels, chips / badges |

- Rules: no uppercase styling with letter-spacing, and no fontSize literals in screens (roles only). German compounds ("Arbeitszeit-Protokoll") must fit in 2 lines. Nav labels are one short word.

### 3. Shape
| Token | dp | Component |
|---|---|---|
| extraSmall | 4 | Inner corners of grouped list items, badges, snackbar |
| small | 8 | Chips, tooltips, date block in rows |
| medium | 12 | List cards, outlined inputs, menus |
| large | 16 | Stat cards, FAB, the Finish button while recording (shape morph target) |
| largeIncreased | 20 | Outer corners of grouped list sections (Android 16-style settings) |
| extraLarge | 28 | Hero card, dialogs, bottom-sheet top corners |
| full | stadium | Buttons (default), nav indicator, segmented buttons, search |

That's 7 tokens with a clear mapping, replacing today's 7 ad-hoc values.

### 4. Spacing and sizing (4 dp grid)
- Tokens: **4 · 8 · 12 · 16 · 24 · 32 · 48**.
- Screen margin: 16 (compact), 24 (medium and up). Readable content max width 840 dp, panes 360–412 dp for lists.
- Card padding 16 (hero 20–24). Gap between sections 24. Gap between related elements 8.
- List rows: 56 (1-line), **72 (2-line shift row)**, 88 (3-line). Leading keyline 16, text keyline 72.
- Buttons 40 (standard), **56–64 (primary Start/Finish)**. Touch targets ≥ 48×48 with ≥ 8 dp between them.
- NavigationBar 80 dp. NavigationRail 80 dp wide (collapsed) / 220–360 (expanded).

### 5. Elevation
Tonal only. Level 0 surface (screens). Level 1 surfaceContainerLow (cards, sheets). Level 2 surfaceContainer (nav bar/rail, menus). Level 3 surfaceContainerHigh (dialogs). The FAB keeps its M3 shadow; nothing else has a shadow. Outlines are used only on text fields, focus rings and an optional `Card.outlined` for "draft/planned".

### 6. Motion (subtle and cheap)
Tokens use the Flutter names: `Durations.short2` 100 ms (state layers), `short4` 200 ms (checkbox, chip, shape morph), `medium2` 300 ms (hero container change), `medium4` 400 ms (sheets, default), `long2` 500 ms (onboarding). Easing: `Easing.emphasizedDecelerate` (enter), `Easing.emphasizedAccelerate` (exit), `Easing.standard` (in-place).

**The only animations on Today:**
1. **Rolling cents:** a digit animates only when it changes. Each digit slides in **from the top** (per spec) inside a ClipRect with SlideTransition, 250 ms, emphasizedDecelerate. No Opacity; if a fade is needed, use FadeTransition. Characters are keyed from the right. The next update is scheduled at the exact millisecond the next cent is earned (at 15 €/h that's every 2.4 s), not every second. Wrapped in RepaintBoundary.
2. **State change idle ↔ running:** the hero card cross-fades and resizes once (300 ms).
3. **Primary button shape morph:** stadium ▶ "Start" → rounded-16 ■ "Finish" (200 ms). This is the "Expressive" signature moment.

**Rules:**
- No scale-on-press anywhere: use the ripple/InkSparkle state layer.
- No AnimatedContainer on list rows and no per-row AnimationControllers.
- Tabs switch through IndexedStack with a short fade on the incoming page (or none).
- Pages use the platform default transitions plus `PredictiveBackPageTransitionsBuilder` and `android:enableOnBackInvokedCallback="true"`.
- Sheets and dialogs use M3 defaults.
- Haptics accompany the key moments.
- `MediaQuery.disableAnimationsOf(context)` means digits swap instantly and there's no morph.
- **Frame budget:** 0 frames/s while idle. While running in the foreground, ≤ 1 frame per cent plus 1 per second for the timer text only. **0 Dart timers in the background**: the notification uses the native chronometer, and on resume everything recomputes from startTime.
- Verify with `flutter run --profile` and the performance overlay.

**Material 3 Expressive in Flutter (2026):** Flutter's built-in material library does **not** ship M3 Expressive components. The Flutter team isn't implementing them in the framework, and new Material work is moving into decoupled packages (flutter/flutter#168813). So treat Expressive as *style guidance*: an emphasized hero typeface, a larger hero radius (28), one shape-morph moment, connected button groups through `SegmentedButton`, and spring-like `emphasizedDecelerate` curves. Avoid third-party "M3E" packages for now (maintenance risk for a hobby project). Revisit once the official decoupled Material package ships Expressive.

### 7. Component inventory (M3 widget → use → replaces)
| Need | Flutter widget | Replaces |
|---|---|---|
| Top-level nav | `NavigationBar` (compact) / `NavigationRail` (medium, compact-height, expanded) | CustomBottomNavigation |
| Top bars | `AppBar`, `SliverAppBar.medium` (Shifts, Insights), contextual selection bar | AppBar with circle buttons |
| Icon actions | `IconButton` + tooltip, `IconButton.filledTonal` for emphasis | AnimatedIconButton |
| Primary action | `FilledButton.icon` (56–64 dp; Start/Finish), `FilledButton.tonal` (Break) | AnimatedButton START/STOP |
| Add shift | `FloatingActionButton.extended` (collapses to icon on scroll) | "+" circle in app bar |
| Hero and stat cards | `Card.filled` (surfaceContainerLow / liveContainer) | HighlightCard |
| Shift rows | `ListTile` inside `Dismissible` (swipe paid / delete) + leading date block | AnimatedListItem |
| Selection | `Checkbox`, `SegmentedButton` (theme, language, period, paid/open), `FilterChip`, `ChoiceChip`, `InputChip` (job) | custom checkbox, language tiles |
| Inputs | `TextFormField` (filled), locale-aware `MoneyField` and `TimeField` wrappers with validators | _WageInputField |
| Pickers | `showDatePicker`, `showDateRangePicker`, `showTimePicker(initialEntryMode: TimePickerEntryMode.input)`, themed from the scheme | dark-forced pickers |
| Sheets | `showModalBottomSheet(showDragHandle: true, useSafeArea: true, isScrollControlled: true)`. Side sheet (dialog aligned right) on expanded | options sheet, AlertDialog editors |
| Dialogs | `AlertDialog` with M3 defaults (destructive only) | custom-styled dialogs |
| Feedback | `SnackBar(behavior: floating, action: Undo)`, `HapticFeedback` | colored snackbars |
| Progress | `LinearProgressIndicator` (monthly cap), `CircularProgressIndicator` | – |
| Badges | `Badge` on the Shifts destination (optional count of open shifts ≥ 1 month old) | – |
| Menus | `MenuAnchor` / `PopupMenuButton` (overflow) | – |
| Charts | `fl_chart` BarChart, or a small CustomPainter (job colors, labels always visible) | – |
| Sticky headers | `CustomScrollView` + `SliverMainAxisGroup` + `PinnedHeaderSliver` | ListView(children) |
| **Custom (only these)** | `RollingAmount`, `EmptyState`, `DateBlock`, `StatCard` | 5 animated_* widgets |

**Component themes to set once in ThemeData:** navigationBarTheme, navigationRailTheme, cardTheme (CardThemeData elevation 0, radius 16), filledButtonTheme (min height 48; primary variant 56), segmentedButtonTheme, chipTheme, inputDecorationTheme (filled, surfaceContainerHighest), listTileTheme, bottomSheetTheme (showDragHandle, surfaceContainerLow, radius 28), dialogTheme, snackBarTheme (floating), and appBarTheme (systemOverlayStyle per brightness).

### 8. Iconography and brand assets
Material Symbols Rounded, weight 400, fill 0 → 1 on the selected nav destination:
- Today = `schedule` / `timer`
- Shifts = `list_alt` / `calendar_month`
- Insights = `bar_chart`
- Paid = `check_circle`
- Open = `pending`
- Break = `coffee`
- Finish = `stop_circle`

Launcher icon: a simplified hourglass + € mark on a solid **#001F3F** background, sky/cyan foreground, a monochrome layer, and a white notification silhouette. Splash: day #F6F9FC / night #0B1320.

Sources: [Flutter issue #168813: Bring Material 3 Expressive to Flutter](https://github.com/flutter/flutter/issues/168813), [Material Design for Flutter](https://docs.flutter.dev/ui/design/material), [Mindestlohn 2026: 13,90 €](https://www.bundesregierung.de/breg-de/aktuelles/mindestlohn-steigt-2391010), [Minijob limit 2026: 603 €](https://magazin.minijob-zentrale.de/minijob-2026-aenderungen/)

## Screen redesigns

### Today (replaces Home / page 1): idle and running states

*Glanceable live pay while working, and a single obvious action to start or finish a shift. When idle, show what you're owed.*

**Phone portrait**

```
IDLE
+------------------------------------------+
| Today, Wed 30 Sep                    (gear)|
|                                          |
| +--------------------------------------+ |
| | Unpaid balance                       | |  Card.filled, radius 28
| | 1.234,56 EUR                         | |  displaySmall, tnum
| | 82,5 h - 11 shifts since 1 Sep       | |  bodyMedium, onSurfaceVariant
| |                     [Record payout >]| |  TextButton
| +--------------------------------------+ |
|                                          |
|  Job  ( * Catering Mueller   v )         |  InputChip, hidden if 1 job
| +--------------------------------------+ |
| |           >  Start shift             | |  FilledButton 64dp, stadium
| +--------------------------------------+ |
|   Started earlier?  [-15 min] [Set time] |  ActionChips
|                                          |
|  This week          18,5 h    256,75 EUR |  ListTile
|  Last shift  Mon 08:00-16:15    8:15 h > |  ListTile -> editor
+------------------------------------------+
| [*Today]      Shifts        Insights     |  NavigationBar
+------------------------------------------+

RUNNING
+------------------------------------------+
| Today, Wed 30 Sep                    (gear)|
| +--------------------------------------+ |
| | o Recording - Catering Mueller       | |  liveContainer (#87CEEB light)
| |                                      | |
| |              47,83 EUR               | |  moneyHero 57sp tnum, cents 0.6x
| |                                      | |
| |   3:11:42    since 08:02  (edit)     | |  timer 22sp tnum
| |   15,00 EUR/h  -  break 0:30         | |  bodyMedium
| +--------------------------------------+ |
|  Unpaid incl. this shift    1.282,39 EUR |  bodyLarge
|  Today total                   87,40 EUR |  only if earlier shift today
|                                          |
| +-----------------+ +------------------+ |
| |  ||  Break      | |  []  Finish      | |  Tonal + Filled 56dp
| +-----------------+ +------------------+ |  Finish morphs to radius 16
+------------------------------------------+
| [*Today]      Shifts        Insights     |
+------------------------------------------+
```

**Landscape / tablet**

Phone landscape (compact height < 480 dp): NavigationRail on the left and two panes, with no vertical scrolling needed.
```
+------+-----------------------------+-----------------------------+
| (o)  | o Recording - Catering      | Unpaid incl. shift          |
| Today|                             | 1.282,39 EUR                |
|      |        47,83 EUR            | +-------------------------+ |
| ( )  |  3:11:42  since 08:02       | | ||  Break               | |
|Shifts|  15,00 EUR/h                | +-------------------------+ |
| ( )  |                             | | []  Finish shift        | |
|Insig.|                             | +-------------------------+ |
| (gear)|                            |                             |
+------+-----------------------------+-----------------------------+
```
Tablet / expanded (>= 840 dp): the rail shows labels, the Today pane has a max width of 560 dp, and a right pane shows today's shifts, a mini bar chart for this week and the unpaid balance card.
```
+--------+----------------------------------+------------------------------+
| Chronos| Today, Wed 30 Sep                | Today                        |
| (o)Today| [ hero card 47,83 EUR  (72sp) ] | 07:00-11:00 Event Hall 4:00 h|
| ( )Shifts| [ || Break ] [ [] Finish ]    | This week  18,5 h 256,75 EUR |
| ( )Insights| Unpaid 1.282,39 EUR [Payout]| [Mo Tu We Th Fr Sa Su bars]  |
| (gear) |                                  | Last shift  Mon 8:15 h       |
+--------+----------------------------------+------------------------------+
```
Medium (600-839 dp, e.g. foldable inner portrait): rail plus a single centered column, max 560 dp.

**Key changes**

- One hero per state: running shows this shift's amount; idle shows the unpaid balance. The session-only '0,00 €' and '00:00:00' idle clutter is gone.
- A single primary Start/Finish button with a shape morph (the Expressive moment), plus a tonal Break button. The green/red button pair and the disabled button are gone.
- Backdating a forgotten start with 'Started earlier?'.
- A job chip.
- A 'Today total' line (the spec's 'today' meaning).
- The rolling digits change only on cent change, slide from the top per spec, use tabular figures, and are FittedBox-protected. The timer is a supporting line, not a third hero.
- Adaptive layout fixes the 284 px landscape overflow.
- The gear stays top-right per spec. The context title replaces 'Chronos'.

### Finish shift sheet (new; replaces the Stop confirm dialog)

*A confirmation that carries information: review, correct and enrich the shift before saving. This fulfils the spec's double confirmation without an empty 'are you sure?'.*

**Phone portrait**

```
+------------------------------------------+
|                  ----                    |  drag handle
| Finish shift?                            |  headlineSmall
|                                          |
|  Start   08:02  ->  08:00   (rounded)    |  raw -> billed, per job rule
|  End     16:09  ->  16:15                |
|  Break   0:30   [edit]                   |
|  ---------------------------------------  |
|  7:45 h  x 15,00 EUR/h                   |
|  116,25 EUR                              |  headlineMedium tnum
|                                          |
|  Tip   [          EUR ]                  |  optional
|  Note  [ Hochzeit Schloss ...        ]   |  optional
|                                          |
| +--------------------------------------+ |
| |              Save shift              | |  FilledButton
| +--------------------------------------+ |
|    Keep running            Discard...    |  TextButtons; Discard confirms
+------------------------------------------+
```

**Landscape / tablet**

Compact height: the sheet opens full-height with a scroll body; the time rows go side by side ('Start 08:02->08:00 | End 16:09->16:15') and Save sits fixed at the bottom. Expanded: a 560 dp modal dialog centered, or a side sheet anchored right next to the Today pane, so the running hero stays visible.

**Key changes**

- Shows the rounding result explicitly, so the 'Total open jumps after stop' surprise goes away.
- Short sessions are never silently discarded ('Only 9 min, save anyway?').
- Tip and note are captured at the moment the worker remembers them.
- Dismissing the sheet keeps the timer running, which is safe by default.
- The notification's [Finish] action and the Quick Settings tile open this same sheet.

### Shifts (replaces Work log / page 2), including multi-select

*Dense, scannable history with month context, filters and fast bulk actions (paid, export, delete).*

**Phone portrait**

```
+------------------------------------------+
| Shifts                    (search) (:) (gear)|  SliverAppBar.medium
| [All] [Open *] [Paid]      [Job v]       |  FilterChips
|------------------------------------------|
| September 2026                           |  sticky, titleSmall
| 42,5 h - 637,50 EUR - 318,75 EUR open    |  bodySmall
| +----+ 08:00-16:15 - 7:45 h   116,25 EUR |  ListTile 72dp, tnum
| | 30 | Catering Mueller - break 30 min (c)|  (c)=clock icon: open
| | Tu |                                   |
| +----+                                   |
| +----+ 18:00-02:00 +1 - 8:00 h 120,00 EUR|
| | 27 | Event Hall - tip 20 EUR       (v)  |  (v)=check: paid, dimmed
| | Sa |                                   |
| +----+                                   |
| August 2026                              |
| 61 h - 915,00 EUR - paid 5 Sep           |
| ...                                      |
|                        +---------------+ |
|                        | +  Add shift  | |  Extended FAB
|                        +---------------+ |
+------------------------------------------+
|  Today       [*Shifts]      Insights     |
+------------------------------------------+
  swipe right -> toggle paid (Undo)
  swipe left  -> delete (Undo)

MULTI-SELECT (long-press)
+------------------------------------------+
| (x) 3 selected - 24,5 h - 367,50 EUR     |  contextual top bar
|        [Mark paid] [Export] [Delete]     |
```

**Landscape / tablet**

Medium and expanded use a list-detail layout: the list pane is 360-412 dp wide on the left, and the right pane shows the ShiftEditor for the selected row (no modal). The FAB moves to the top of the rail or into the list pane header. Phone landscape uses a single list with the rail, and rows stay 72 dp with a wider trailing column.
```
+------+------------------------------+----------------------------------+
| rail | Shifts   [All][Open][Paid]   | Edit shift          [Delete] [Save]|
|      | Sep 2026  42,5 h 637,50 EUR  | Job   (* Catering Mueller v)     |
|      | > 30 Tu 08:00-16:15 116,25   | Date  Tue, 30 Sep 2026           |
|      |   27 Sa 18:00-02:00 120,00   | Start 08:00 [-][+]  End 16:15    |
|      |   ...                        | Break 0:30   Tip 0,00 EUR        |
|      |                              | 7:45 h x 15,00 = 116,25 EUR      |
+------+------------------------------+----------------------------------+
```

**Key changes**

- 72 dp two-line rows instead of about 100 dp cards: roughly 60% more shifts per screen.
- One paid indicator (icon plus dimming) instead of three.
- Sticky month headers with totals.
- Filters for open, paid and job.
- Swipe actions with Undo instead of sheet → dialog chains.
- Tap edits and long-press multi-selects (Android conventions).
- Bulk 'Mark paid' leads into the Record payout flow.
- Extended FAB instead of an app-bar circle.
- A lazy sliver list keeps scrolling smooth with an unlimited history.
- Order stays newest first. This is a deliberate deviation from the spec's 'newest at bottom', because a timesheet is read from the latest shift; confirm with the owner.

### Shift editor sheet (new; replaces the Add and Edit dialogs)

*Create or correct a shift in seconds with typed input, smart defaults, live pay preview and validation.*

**Phone portrait**

```
+------------------------------------------+
|                  ----                    |
| (x)  New shift                    [Save] |  top row inside sheet
|------------------------------------------|
| Job    ( * Catering Mueller        v )   |  hidden if 1 job
| Date   [ Tue, 30 Sep 2026        (cal) ] |
| Start  [ 08:00 ]   [-15] [+15]           |  typed '0800' ok
| End    [ 16:15 ]   [-15] [+15]           |
|        Ends next day            ( o  )   |  Switch, auto-on if end<start
| Break  [ 0:30 ]   auto: 30 min after 6 h |
| Tip    [ 0,00 EUR ]                      |
| Note   [                              ]  |
| Status [ Open | Paid ]                   |  SegmentedButton
|------------------------------------------|
| 7:45 h x 15,00 EUR/h = 116,25 EUR        |  live preview, titleMedium
| (!) Overlaps Tue 07:00-09:00 [view]      |  inline warning
|------------------------------------------|
| [Delete]                     [Duplicate] |  edit mode only
+------------------------------------------+
```

**Landscape / tablet**

Compact height: a full-screen dialog with a two-column form (Job/Date/Start/End | Break/Tip/Note/Status), the preview pinned at the bottom and Save in the app bar. Expanded: the right pane of the Shifts list-detail, or a 560 dp dialog when opened from Today.

**Key changes**

- One component for add and edit, replacing about 320 duplicated lines.
- Keyboard time entry and steppers instead of dial pickers stacked on a dialog.
- Prefilled from the last similar shift.
- An explicit 'Ends next day' instead of a silent overnight or 24 h shift.
- Validation uses the unused `endAfterStart` key plus overlap and duration warnings.
- Break, tip, note, job and status are editable.
- Earnings preview uses the entry's stored rate.
- Delete (with Undo) and Duplicate live here.

### Record payout sheet (new)

*Settle many open shifts at once when the employer pays, keeping a record of date and amount.*

**Phone portrait**

```
+------------------------------------------+
|                  ----                    |
| Record payout                            |
| Job     ( Catering Mueller v )           |
| Period  [ All open up to 31 Aug  v ]     |  or 'selected shifts (3)'
|------------------------------------------|
| 23 shifts - 172,5 h                      |
| Expected          2.587,50 EUR           |  tnum
| Received  [       2.587,50 EUR ]         |  optional, editable
| Difference            0,00 EUR           |
| Paid on   [ Fri, 5 Sep 2026 ]            |
| Note      [ Lohnabrechnung Aug ]         |
| +--------------------------------------+ |
| |          Mark 23 shifts paid         | |
| +--------------------------------------+ |
+------------------------------------------+
```

**Landscape / tablet**

Expanded: a 560 dp dialog showing the list of included shifts in a scrollable column next to the form. Compact height: a full-screen dialog with the form on the left and the included shifts on the right.

**Key changes**

- Replaces ticking 20+ tiny checkboxes.
- Creates a Payout record (date, expected vs received, note) shown in Insights and on rows as 'Paid 5 Sep'.
- Undo snackbar after saving.
- Reachable from the Today unpaid card, from Shifts multi-select, and from Insights.

### Insights (new tab)

*Answers the 'can do too little' complaint: hours and earnings over time, per job, unpaid versus paid, and monthly cap tracking.*

**Phone portrait**

```
+------------------------------------------+
| Insights                             (gear)|
| [ Week | Month | Year ]   < Sep 2026 >   |  SegmentedButton + stepper
| +------------------+ +-----------------+ |
| | 82,5 h           | | 1.237,50 EUR    | |  StatCards, headlineSmall
| | worked           | | earned          | |
| +------------------+ +-----------------+ |
| +------------------+ +-----------------+ |
| | 15,48 EUR/h      | | 318,75 EUR      | |
| | avg incl. tips   | | unpaid     >    | |  -> Shifts filtered Open
| +------------------+ +-----------------+ |
| Hours per week                           |
|  |  _    _                               |
|  | | |  | |  _                           |  bar chart, job colors,
|  |_|_|__|_|_|_|___                       |  value labels visible
|   W36  W37 W38 W39                       |
| Monthly limit (Minijob)  438 / 603 EUR   |  LinearProgressIndicator
| [=============-------]                   |
| By job                                   |
|  * Catering Mueller    52 h   780,00 EUR |
|  * Event Hall        30,5 h   457,50 EUR |
| Payouts                                  |
|  5 Sep  Catering Mueller   2.587,50 EUR  |
| [ Export this month ]                    |  OutlinedButton
+------------------------------------------+
|  Today        Shifts       [*Insights]   |
+------------------------------------------+
```

**Landscape / tablet**

Medium: a 2×2 stat grid on top and the chart full width below. Expanded: a 12-column grid with 4 stat cards in one row, the chart (8 cols) next to the 'By job' list (4 cols), and payouts plus monthly cap in a second row. Phone landscape: stat cards in one row of 4 and a horizontally scrollable chart.

**Key changes**

- A new destination that gives week, month and year context.
- Uses the job palette with labelled bars, so color is never the only encoding.
- The monthly cap is configurable per job (German Minijob limit 603 €/month in 2026).
- Tapping the unpaid card jumps to filtered Shifts.
- Export entry point.

### Jobs & rates (new, under Settings → Work)

*Support several employers or venues with their own rate history, rounding, break rules and surcharges.*

**Phone portrait**

```
JOBS LIST
+------------------------------------------+
| <  Jobs & rates                          |
|  * Catering Mueller    15,00 EUR/h    >  |
|  * Event Hall          14,20 EUR/h    >  |
|  + Add job                               |
+------------------------------------------+

JOB EDITOR
+------------------------------------------+
| <  Catering Mueller              [Save]  |
| Name     [ Catering Mueller ]            |
| Color    (o)(o)(o)(o)(o)(o)              |  6 job swatches
| Rate     [ 15,00 EUR ] /h                |
|          Rate history  (3 changes)   >   |  effective-from list
| Rounding [ None | 5 | 15 min ]           |  SegmentedButton
|          Mode [ Nearest v ]              |
| Breaks   Auto-deduct            ( o  )   |
|          30 min after 6 h, 45 after 9 h  |  editable defaults
| Surcharges (advanced)               >    |  night/Sun/holiday %
| Monthly limit  [ 603 EUR ]  (optional)   |
| Payout cycle   [ Monthly v ]             |
| [Archive job]                            |
+------------------------------------------+
```

**Landscape / tablet**

Expanded: list-detail, with jobs on the left and the editor on the right. Compact height: the editor form in two columns.

**Key changes**

- The rate moves out of global settings into the job, with effective dates, so changing the rate no longer rewrites history.
- Rounding becomes visible and optional instead of hard-coded.
- Break rules match the German ArbZG defaults (editable).
- Surcharges and the monthly cap cover real catering needs.
- With one job, all job UI is hidden elsewhere.

### Export & backup (new, under Settings → Data, also from Insights and Shifts multi-select)

*Hand a timesheet to the employer and keep data safe, fully offline and user-initiated.*

**Phone portrait**

```
+------------------------------------------+
| <  Export & backup                       |
| EXPORT                                   |
| Range   [ September 2026        v ]      |  or custom date range
| Job     [ All jobs              v ]      |
| Format  [ PDF timesheet | CSV ]          |
| Include [x] breaks [x] earnings [ ] notes|
| Preview: 30.09. 08:00-16:15 7,75 h ...   |
| +--------------------------------------+ |
| |              Share...                | |  share_plus
| +--------------------------------------+ |
| BACKUP                                   |
|  Create backup file                  >   |  SAF save dialog
|  Restore from backup                 >   |  confirm + summary
|  Last backup: 12 Sep 2026                |
| DANGER ZONE                              |
|  Delete paid shifts before...        >   |
|  Delete all data...                      |  error color text
+------------------------------------------+
```

**Landscape / tablet**

Expanded: two columns, with the export form on the left and a live PDF/CSV preview on the right. Compact height: the form scrolls and the Share button stays pinned.

**Key changes**

- New capability: timesheets for employers, with CSV decimal hours in locale format (8,75) and a PDF with signature line.
- Backup and restore.
- Delete-all becomes a localized, standard destructive dialog with counts and an automatic pre-delete backup. This replaces the German-only typed confirmation.
- Privacy text updated.

### Settings

*A calm, grouped list of preferences, with the spec's switches for language and theme, in Android 16-style grouped sections.*

**Phone portrait**

```
+------------------------------------------+
| <  Settings                              |
| General                                  |  titleSmall, primary
| +--------------------------------------+ |  grouped, 2dp gaps,
| | Language   [System|Deutsch|English]  | |  radius 20 outer / 4 inner
| |--------------------------------------| |
| | Theme      [System | Light | Dark ]  | |
| |--------------------------------------| |
| | Wallpaper colors             ( o  )  | |  Android 12+
| +--------------------------------------+ |
| Work                                     |
| | Jobs & rates                     >   | |
| | Currency                  EUR (€) >  | |
| | Reminders    long shift 10 h     >   | |
| Notifications                            |
| | Live notification            ( o  )  | |
| Data                                     |
| | Export & backup                  >   | |
| About                                    |
| | Version 1.1.0 (12)                   | |
| | Privacy policy - Licenses - Feedback | |
+------------------------------------------+
```

**Landscape / tablet**

Medium and expanded: a two-pane settings layout, with categories on the left (General, Work, Notifications, Data, About) and details on the right, max width 840 dp. Phone landscape: a single column with the rail, content max width 600 dp and centered.

**Key changes**

- Adds the missing Theme control (System/Light/Dark).
- Language gets 'System'.
- Every string localized (fixes the 'Alles löschen' bug).
- The wage field moves to Jobs.
- No cards inside cards and no 56-132 dp indents.
- Version from package_info_plus.
- Privacy (DE/EN), licenses and feedback added.

### Onboarding (new, first run only)

*Set language and theme automatically from the system and capture the single required input (the hourly rate) without friction.*

**Phone portrait**

```
STEP 1
+------------------------------------------+
|                                          |
|              [ app mark ]                |
|        Track shifts. Watch your          |  headlineSmall
|           pay grow live.                 |
|   Works offline. Your data stays on      |  bodyMedium
|   your phone.                            |
|                                          |
| +--------------------------------------+ |
| |             Get started              | |
| +--------------------------------------+ |
|                 o  .                     |  page dots
+------------------------------------------+

STEP 2
+------------------------------------------+
| Your job                                 |
| Name (optional) [ e.g. Catering Mueller ]|
| Hourly rate     [ 13,90 ] EUR/h          |  locale field, required
|   Minimum wage in Germany 2026: 13,90 EUR|  helper
| Currency        [ EUR v ]                |
| +--------------------------------------+ |
| |                Done                  | |
| +--------------------------------------+ |
|   You can add more jobs later.           |
+------------------------------------------+
```

**Landscape / tablet**

A centered 480-560 dp card on a surfaceContainerLow background. In compact-height landscape, the illustration or mark is on the left and the text and actions on the right. Shared-axis (horizontal) transition between steps at 300 ms; instant when reduce-motion is on.

**Key changes**

- Replaces the German-by-default first launch with its hidden 15 € rate and an immediate permission prompt.
- The notification permission is requested on the first Start, with a rationale.
- Two steps at most, and step 2 can be completed by keyboard alone.

### System surfaces: ongoing notification, Quick Settings tile, home-screen widget, launcher shortcuts (new)

*Control and see the shift without opening the app, which is where catering workers actually are at shift change.*

**Phone portrait**

```
NOTIFICATION (ongoing, low importance, silent)
+------------------------------------------+
| (mono icon) Chronos - 3:11:42            |  native chronometer
| Recording - Catering Mueller             |
| Since 08:02 - 15,00 EUR/h                |  static text, no re-posting
| [ Break ]                  [ Finish ]    |  actions
+------------------------------------------+

QUICK SETTINGS TILE      WIDGET 2x1          WIDGET 4x2
+-----------------+      +--------------+    +-----------------------+
| (timer) Chronos |      | 3:11 47,83   |    | Today   8:15 h 123,75 |
| Recording 3:11  |      | [ Finish ]   |    | Unpaid  1.282,39 EUR  |
+-----------------+      +--------------+    | [ Start shift ]       |
                                              +-----------------------+
LAUNCHER SHORTCUTS (long-press icon): Start shift - Add shift
```

**Landscape / tablet**

Widgets are resizable (2×1 up to 4×3). On tablets the 4×2 widget adds a 7-day bar strip. The notification's [Finish] action deep-links into the Finish sheet (a side sheet on expanded).

**Key changes**

- Localized notification with actions and a monochrome icon.
- No Dart timer re-posting every 15 s, which removes the zombie notification and much of the background load.
- New entry points: QS tile (native TileService), home_widget, and app shortcuts.


## Navigation & information architecture

## Information architecture

**Top-level destinations (3):**
| Destination | Icon | Question it answers | Contains |
|---|---|---|---|
| **Today** (Heute) | timer / schedule | "What am I earning right now, and what am I owed?" | Start/Break/Finish, live hero, unpaid balance, this week, last shift |
| **Shifts** (Schichten) | list_alt | "What did I work, and what's paid?" | Month-grouped list, filters, swipe paid/delete, multi-select, Add shift FAB |
| **Insights** (Übersicht) | bar_chart | "How am I doing over time?" | Week/Month/Year stats, charts, per-job, monthly cap, payouts, export entry |

**Settings** stays a gear in the top app bar trailing slot on every destination (the spec: "oben rechts immer das Einstellungssymbol"). On expanded layouts it also sits at the bottom of the NavigationRail. It isn't a 4th tab because it's rarely used.

**Why 3 tabs:** M3 recommends a NavigationBar for 3–5 peers. Today and Shifts preserve the spec's "page 1 left, page 2 right" order, and Insights is the new capability.

## Where every feature lives
| Feature | Primary location | Secondary entry points |
|---|---|---|
| Start / Break / Finish | Today | Notification actions, QS tile, widget, launcher shortcut |
| Finish review (rounding, tip, note) | Finish sheet (modal) | Notification [Finish] deep link |
| Add past shift | Shifts → Extended FAB → Editor sheet | Today "Last shift" row, launcher shortcut "Add shift", empty states |
| Edit / delete / duplicate | Tap row → Editor sheet | Swipe (delete), multi-select |
| Mark paid / payouts | Record payout sheet | Today unpaid card, Shifts multi-select, Insights "Unpaid" card, swipe right on a row (single) |
| Jobs, rates, rounding, breaks, surcharges | Settings → Work → Jobs & rates | Job chip on Today ("Manage jobs…"), Editor job field |
| Statistics | Insights | Month headers in Shifts (totals) |
| Export timesheet (PDF/CSV) | Settings → Data → Export & backup | Insights "Export this month", Shifts multi-select "Export", overflow ⋮ on Shifts |
| Backup / restore / delete data | Settings → Data | Recovery screen on startup failure |
| Language / theme / wallpaper colors | Settings → General | Onboarding (auto from system) |
| Reminders (long shift, forgot to stop) | Settings → Work → Reminders | Notification |

## Surfaces and patterns
- **Sheets (modal bottom, drag handle):** Shift editor, Finish shift, Record payout, filter/job picker. On expanded widths, the editor becomes the right pane (list-detail) and the others become 560 dp dialogs or side sheets.
- **FAB:** only on Shifts ("Add shift", extended, collapses on scroll). Today uses an in-content primary button because Start/Finish *is* the content. Insights has no FAB.
- **Dialogs:** only for irreversible bulk actions (delete all, restore backup overwrite) and the permission rationale.
- **Snackbars with Undo:** delete, paid toggle, payout, discard shift.
- **Contextual action bar:** Shifts multi-select (count, hours and sum in the title; Mark paid · Export · Delete).

## Routes (go_router, `StatefulShellRoute.indexedStack` keeps each tab's state and scroll)
`/today` · `/shifts` · `/shifts/:id` (sheet on compact, pane on expanded; deep-linkable) · `/insights` · `/settings` · `/settings/jobs` · `/settings/jobs/:id` · `/settings/data` · `/onboarding` (redirect guard on first run) · `/finish` (sheet, notification deep link).
Back behavior: system back on Shifts or Insights returns to Today, then exits. Enable predictive back (`android:enableOnBackInvokedCallback="true"` plus `PredictiveBackPageTransitionsBuilder`).

## Adaptive navigation (M3 window size classes)
| Window | Condition | Navigation | Content layout |
|---|---|---|---|
| Compact | width < 600 dp | **NavigationBar** (80 dp, labels always shown) | Single pane, 16 dp margins |
| Compact height (phone landscape) | height < 480 dp | **NavigationRail** (no bottom bar, which saves ~80 dp) | Two columns on Today (hero / actions); forms in 2 columns |
| Medium | 600–839 dp | NavigationRail with labels | Single pane max 560–600 dp centered; Shifts can already show list-detail on foldables when the posture is flat |
| Expanded | 840–1199 dp | NavigationRail (labels) with settings at the bottom | **List-detail**: Shifts list 360–412 dp + editor pane; Today + today/week pane; Settings categories + detail |
| Large / XL | ≥ 1200 dp | Expanded rail (or a NavigationDrawer-style rail, 220–360 dp) | Same panes, more whitespace; Insights on a 12-column grid |

Implement with a single `AdaptiveScaffold`-like widget built on `LayoutBuilder` / `MediaQuery.sizeOf`; no extra package is needed. Test on a 360×640 phone (portrait and landscape), a 7" tablet, a 10" tablet, a foldable (inner and outer), and at 200% font scale. This matters for release: new apps and updates must target API 36 since 31 Aug 2026, and Android 16 then ignores orientation and resizability locks on large screens, so there's no "portrait-only" escape hatch on tablets.

## Outside the app
Ongoing notification (Break/Finish), Quick Settings tile, home-screen widget (2×1, 4×2), and launcher shortcuts (Start shift, Add shift). All deep-link into the routes above.

Sources: [Play target API level requirements](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en), [Meet Google Play's target API level requirement](https://developer.android.com/google/play/requirements/target-sdk)

## Accessibility

## Accessibility checklist (Chronos v2)

### Text scaling
- [ ] Supports up to **200%** font scale (Android 14+ nonlinear scaling). No fixed heights on text containers, and every screen scrolls (today home_screen.dart:54-80 overflows even without scaling).
- [ ] The hero amount uses `FittedBox(fit: BoxFit.scaleDown)`. The full value stays available to TalkBack through the semantics label even when visually scaled.
- [ ] Buttons wrap or stack when narrow (no Row of fixed-padding pills, cf. home_screen.dart:148-192).
- [ ] Nav labels are one short word. Long German labels ("Arbeitszeit-Protokoll") get a max of 2 lines and ellipsis is only a last resort.
- [ ] Golden and widget tests run at `textScaler: TextScaler.linear(1.0 / 1.3 / 2.0)` and at 320 dp width.

### Contrast (WCAG 2.x AA)
- [ ] Text ≥ 4.5:1, large text and UI boundaries/icons ≥ 3:1. All proposed token pairs pass (e.g. light primary on surface 7.4:1, dark onSurfaceVariant 10.7:1, light outline 4.1:1).
- [ ] Current failures to eliminate: white on #22C55E **2.28:1** (START, "Abgerechnet" badge at 10 px), white on #3B82F6 **3.68:1** (all primary pills and dialog buttons), white on #EF4444 3.76:1 (STOPP), unpaid checkbox border **≈2.0:1**, delete-all hint text **2.89:1**.
- [ ] Both themes verified, including disabled states and chart series against the surface (≥ 3:1).

### TalkBack semantics
- [ ] Every icon-only control has a localized `tooltip` or semantic label: settings, add shift, filters, close, overflow. Today, **no control has one** (grep: zero Semantics or tooltip).
- [ ] Only real Material controls (`FilledButton`, `IconButton`, `Checkbox`, `NavigationBar`), so role, enabled/disabled and checked state are announced. This removes the GestureDetector buttons (animated_button.dart:89, 211; custom_bottom_nav.dart:107; work_log_screen.dart:159).
- [ ] Shift rows use `MergeSemantics` with a label like "Tuesday 30 September, 8:00 to 16:15, 7 hours 45 minutes, 116 euros 25, open". **Swipe actions are also exposed as `CustomSemanticsAction`s** ("Mark as paid", "Delete", "Edit"), because swipes aren't reachable with TalkBack.
- [ ] Rolling counter: exclude the individual digit widgets (`ExcludeSemantics`) and expose one label ("This shift: 47 euros 83"). **No live region**, since announcing every cent would be unbearable. Announce state changes once with `SemanticsService.announce` ("Shift started at 8:02", "Shift saved, 7 hours 45 minutes").
- [ ] Timer text gets a spoken duration ("3 hours 11 minutes"), not "3 colon 11 colon 42".
- [ ] Month headers and section titles have `Semantics(header: true)`, so users can jump by heading.
- [ ] Dialogs and sheets move focus to their title. Snackbar Undo is reachable, and the duration is extended when accessibility services are on (Flutter does this for SnackBars with actions).
- [ ] Charts provide a text alternative (a data table or per-bar semantics: "Week 38: 18.5 hours").

### Touch targets
- [ ] ≥ 48×48 dp for every interactive element, with ≥ 8 dp between neighbors. The current paid checkbox is **28×28 dp** (work_log_screen.dart:163-164).
- [ ] Primary Start/Finish is 56–64 dp tall and full-width or half-width, reachable with the thumb.
- [ ] Steppers (±15 min) are 48 dp each, not tiny icons.

### Motion and reduced motion
- [ ] Honor `MediaQuery.disableAnimationsOf(context)` (system "Remove animations"): digits swap instantly, no shape morph, no page slide (fade only).
- [ ] No infinite or pulsing animations: the "recording" dot is static and there's no flashing (nothing above 3 flashes/s).
- [ ] No scale-on-press (removes today's rubbery motion, which can also bother vestibular-sensitive users).

### Color independence
- [ ] Paid vs open is conveyed by icon **and** text or semantics (check_circle "Paid" / pending "Open"), not by green or blue alone. Today, paid is partly color-only (blue row tint).
- [ ] Charts use labels and value text, and optionally patterns. Job colors are always paired with the job name.
- [ ] Errors show an icon plus text (inline field errors), not red alone.

### Input
- [ ] Time fields accept typed input and time pickers open in `TimePickerEntryMode.input` where precision matters. Date pickers can switch to input mode.
- [ ] Money fields accept the locale decimal separator (the German comma is blocked today, settings_screen.dart:384), with a correct `keyboardType` and `textInputAction`, and an error message announced.
- [ ] Hardware keyboard and switch access: logical focus order (FocusTraversalGroup per pane), visible focus ring (M3 default), Enter to save in the editor. Optional tablet shortcuts: Ctrl+N (add shift).

### Language and formats
- [ ] Locale-aware numbers, dates and durations everywhere, so TalkBack reads "1.234,56 €" correctly in German and "€1,234.56" in English.
- [ ] App language follows the system by default. Per-app language on Android 13+ can be offered through `android:localeConfig` so it appears in system settings.

### Feedback and haptics
- [ ] `HapticFeedback` on start/finish (mediumImpact), paid toggle and steppers (selectionClick), destructive confirms (heavyImpact). This respects the system haptics setting.
- [ ] Every destructive action is either confirmed (bulk) or undoable (single).

### Verification
- [ ] Automated: `flutter test` with `expect(tester, meetsGuideline(androidTapTargetGuideline))`, `labeledTapTargetGuideline` and `textContrastGuideline` on every screen, in both themes.
- [ ] Manual: an Accessibility Scanner pass, a full TalkBack walkthrough (start → break → finish → edit → mark paid → export), 200% font plus display size "largest", and the landscape and tablet emulators.
