# Verification: delete bug hunt & audit claims

> Raw verification output from the Chronos analysis on 2026-09-30 (English). Line numbers refer to commit 9a52779 (v1.0.0). Summary and plan: [../UMBAUPLAN.md](../UMBAUPLAN.md). Tests: [repro-tests/](repro-tests/) (`verify_*`).


## Delete needs restart — verdict: **not_reproduced**

### Scenarios tested

All actions were driven through the real UI: tapping and long-pressing rows, the sheet's 'Löschen' option, the confirm button, the nav bar, the settings icon, the back arrow and system back. After every step the test checked what is on screen: the row time ranges, month headers, empty state, Home's two money amounts and the painted digits. It also checked the provider list and the persisted prefs (the store as a restart would load it).

Everything below ran on Flutter 3.47.5 (repro/). I also downloaded Flutter 3.24.5, which is the SDK the owner's build used. The evidence is the repo's pubspec.lock (leak_tracker 10.0.5, test_api 0.7.2, vm_service 14.2.5, meta 1.15.0) and the `CardTheme` usage. I ran verify_delete_single/all/flows/slowstore against the UNMODIFIED repo code and lock in scratchpad/repro324. The results were identical to 3.47.5.

**A.1 Single delete (verify_delete_single_test.dart): all pass**
- Tap path and long-press path; first row (A, open), middle row (B, paid), last row (E, paid, the only July entry), and a row alone in August (D).
  - The row is gone on the first `pump()` after the confirm tap. It stays gone after pumpAndSettle, Home and back, and in storage.
  - The August/July header disappears in the same frame.
- Only row deleted: the empty state 'Keine Einträge vorhanden' appears, and Home shows 0,00€.
- All 5 rows deleted one after another: empty state shown, store `[]`.
- Home open total (A–E sample, 370,00€ before):
  - deleting paid B leaves 370,00€ (correct);
  - deleting open A gives 248,75€, painted '248,75€'.
- English UI works the same way.

**A.2 Animations and fast taps: all pass**
- `disableAnimations=true`, `timeDilation=5`, and `timeDilation=0.05`.
- Fast mode: the sheet option is tapped as soon as it is on screen (112 ms; 16 ms with disableAnimations), and confirm is tapped after 1 frame.
- The 'zero frames' case: at t=0 the sheet option is at y=1744 on a 1600-high screen, so no finger can hit it. After 120 ms the same path works.

**A.3 Delete-all (verify_delete_all_test.dart): all pass**
- Covered: DE and EN, Settings opened from Home and from Log, then back arrow or system back, with a Home to Log cross-fade within 50 ms.
- Result every time: the list is empty immediately after the pop, Home shows 0,00€, the key is removed from prefs, and adding a new entry afterwards works.
- Confirm button state by input:
  - disabled: 'Delete', 'delete', 'DELETE', 'löschen', 'LÖSCHEN', 'loeschen', 'Löschen.'
  - enabled: 'Löschen', 'Löschen ', ' Löschen', 'Loeschen'
- In EN, only the button labels 'Delete'/'Cancel' are English. The section, dialog title, instructions, hint and snackbar ('Alle Einträge gelöscht') are German. An English user who types 'Delete' gets a permanently disabled button and no hint why.
- 360x740 with a 300 dp keyboard (verify_deleteall_keyboard_test.dart): the TextField is clipped and not hittable (32 px content overflow at settings_screen.dart:283). The confirm button is still reachable and the delete works.
- Delete-all while the timer runs, from Home: afterwards open total = current earnings.

**A.4 Combinations (verify_delete_flows_test.dart): all pass**
- Delete while the timer runs (started with START): the row is gone on the first frame, and Home's open total minus current earnings = 246.25.
- Delete right after Add (uuid id), right after Edit, right after toggling paid (the delete follows the toggle 1 frame later, while the highlight animates), and after un-paying via its confirm dialog.
- Delete of a timer-created entry (id '1790740542577', millis).
- 'Restart' check: the persisted ids always equal the visible rows.

**A.5 Duplicates**
- Two rows with the SAME id: deleting one removes both (`removeWhere`), and this is consistent after restart.
- Two identical-looking rows with different ids: deleting one leaves an identical row. The store keeps Q, so it looks like 'delete did nothing', before and after restart.
- Same-id pair plus a paid toggle: the store ends up with two copies of the 16:35 entry and the 16:30 entry is lost.
- Double-tap Save in Add, same frame or 16 ms apart, 0 latency: only 1 entry. The Navigator absorbs the second pointer, then the popping route ignores pointers.
- Double-tap on the delete confirm or on the sheet 'Löschen': handled, 1 dialog, 1 delete.

**A.6 / A.7 with a store that emulates the Android plugin's round-trip latency (SlowStore, verify_delete_slowstore_test.dart)**
- 250 ms latency: the deleted row stays visible for about 250 ms (until the write returns), then disappears.
- Tapping the paid box of that zombie row inside the window RESURRECTS it: provider `[A(paid),…]`, disk `[B,C,D,E,A]`.
- Re-opening the zombie row's sheet and deleting again is harmless.
- Delete, then Home, then Log mid cross-fade with 300 ms latency: correct once the write finishes.
- Add dialog, Save double-tapped 90 ms apart:
  - 50 ms latency: fine;
  - 120, 200 and 400 ms latency: 2 entries saved AND MainScreen popped (blank screen, `visibleTexts=[]`).
- Error injection on the delete write:
  - reply lost after the disk write: no snackbar and the row stays on screen, but the prefs cache and disk no longer have B. The next unrelated reload (a paid toggle), or a restart, shows it gone. This is exactly the reported symptom.
  - commit failed, or hang: the row stays, the prefs cache has it deleted, the disk still has it.
- Double-tap on a row: the sheet opens and is immediately dismissed by its own barrier. Sheets open afterwards: 0.

### Root cause / hypotheses

The straightforward delete works. None of ~50 UI scenarios left the list or Home total stale, on the owner's Flutter 3.24.5 or on 3.47.5.

The delete path is written defensively:
- work_log_screen.dart:367-419 captures `context.read<WorkEntriesProvider>()` and `ScaffoldMessenger` before the await, and pops with `dialogContext`.
- work_entries_provider.dart:29-32 and :35-39 always end in `notifyListeners()`.
- WorkLogScreen and HomeScreen `watch` the one provider instance.
- The outgoing AnimatedSwitcher child also rebuilds, and switching tabs rebuilds WorkLogScreen from scratch.

So a stale list that survives a tab switch would need the provider's `_entries` itself to be stale. In this code that only happens if the prefs write throws or never returns.

Hypotheses, most plausible first.

**1. The 'restart' came from a blank screen caused by Save, not by Löschen.**
- Where: the Add dialog (work_log_screen.dart:535-577; `await saveEntry` :568, then `Navigator.pop(context)` :570) and the Edit dialog (:734-776; await :766, pop :768).
- Mechanism: Save does `await saveEntry` and then `Navigator.pop(context)`. If Save is hit twice within the prefs write latency, both handlers pop. The dialog context is still `mounted` during its exit transition, so the guard does not stop the second pop. The second pop removes MainScreen, the screen goes blank, and only killing the app helps.
- Reproduced with ≥120 ms write latency and taps 90 ms apart.
- The Add variant also leaves two identical rows. Deleting one of them leaves an identical twin, so 'delete didn't work', and that survives restart.
- Minimal fix: make Save re-entrancy-safe (a `saving` flag in the StatefulBuilder, `onPressed: saving ? null : ...`), and pop only if `ModalRoute.of(context)?.isCurrent == true`.

**2. Zombie-row window.**
- Where: work_entries_provider.dart:29-32 updates memory only after the platform write (Android: `commit()` on a background task queue, shared_preferences_android LegacySharedPreferencesPlugin.java:87/103). Meanwhile the row stays interactive.
- Mechanism: togglePaidStatus (:39-47, from stale `_entries`) or an Edit save goes through the upsert in storage_service.dart:21-30 and re-inserts the deleted entry.
- Reproduced at 250 ms latency.
- Minimal fix: remove the entry optimistically, then persist:
  ```dart
  _entries.removeWhere((e) => e.id == id);
  notifyListeners();
  try {
    await _storage.deleteWorkEntry(id);
  } finally {
    await loadEntries();
  }
  ```
  And make toggle and edit update-only: skip when the id is absent in storage.

**3. A storage exception or lost reply.**
- Where: `_showDeleteConfirmation` is fire-and-forget (work_log_screen.dart:351), and there is no try/catch in deleteEntry or storage.
- Mechanism: the error is swallowed, there is no snackbar, and the row stays while prefs already has it removed. A restart or the next unrelated reload shows the deletion. This matches the symptom exactly, but I know of no real Android trigger for it.
- Fix: the same as 2, plus catch the error and show a SnackBar.

**4. The UX flakes, which explain 'Löschen ging nicht gescheit' but not the restart.**
- The delete-all check at settings_screen.dart:270-271 is case-sensitive and German-only: 'löschen' or 'Delete' leaves the button disabled. The field uses the default `TextCapitalization.none`, so keyboards are unlikely to auto-capitalize (plausible, untested).
- A double-tap on a row opens the sheet and instantly dismisses it.

**5. Device-only effects I cannot test.**
- Impeller/GPU repaint glitches.
- A second activity/engine instance. Unlikely: the app has one `singleTop` activity.

**Release, R8 and SDK differences do not matter here.**
- No delete step relies on an assert.
- R8 keeps the Pigeon prefs classes. The notifications plugin's Gson path (loadScheduledNotifications) only runs if scheduled notifications exist, which this app never creates.
- Flutter 3.24.5 behaves identically to 3.47.5.

## Audit claims

### B04 — **partially**

*Claim:* TimerProvider.stop() clears the persisted active session before the entry is saved in HomeScreen; saving depends on context.mounted (home_screen.dart:250-296) -> data-loss path.

The code order is as claimed: `saveActiveSession(null)` at timer_provider.dart:44 runs before `entries.saveEntry` at home_screen.dart:281, and the save is gated by `context.mounted` at :255.

SlowStore test (verify_claims_test.dart): confirm the stop, then tap the Log tab 48 ms later (the dialog barrier ignores pointers while it reverses).
- write latency 100, 250 or 350 ms: entry saved (6 entries);
- write latency 400 ms: entries stay 5, active_session removed from disk. The session is lost.
- no tab switch, even at 400 ms: saved.

So the data loss is real, but it needs slow I/O plus a quick tab switch, or process death between the two writes. It does not happen under normal conditions.

Side effect at 250–350 ms: the unguarded `ScaffoldMessenger.of(context)` at home_screen.dart:290 throws 'Looking up a deactivated widget's ancestor is unsafe'.

### B13 — **confirmed**

*Claim:* Double-tapping 'Save' in the Add dialog creates duplicate entries and may pop the main route (work_log_screen.dart:535-577).

It only happens when the prefs write latency is longer than the tap interval.

With 0 latency: a same-frame double tap and a tap 16 ms later both give 6 entries and MainScreen stays mounted. The Navigator absorbs pointers until the next frame, and after that the popping dialog is IgnorePointer'd.

SlowStore, taps 90 ms apart:
- 50 ms latency: 6 entries, OK;
- 120, 200 and 400 ms latency: 7 entries (two identical 08:00–16:00 rows, different uuids) and MainScreen mounted=0, a blank screen (the second `Navigator.pop(context)` at :570 pops the root route).

The Edit dialog (:766-768) has the same double pop at 200 ms latency (MainScreen mounted=0). It creates no duplicate because the id is upserted. Identical on Flutter 3.24.5.

### B12 — **confirmed**

*Claim:* No overlap/duplicate detection between entries.

Adding the default 08:00–16:00 twice through the UI gives `rows=[08:00 – 16:00, 08:00 – 16:00, ...]` with no warning. saveEntry and saveWorkEntry (work_entries_provider.dart:24-27, storage_service.dart:21-30) do no overlap check at all.

### B10 — **confirmed**

*Claim:* First launch forces German regardless of device locale (app_settings.dart:11).

With `platformDispatcher.locales=[en_US]` and empty prefs, `settings.language=AppLanguage.german` and the UI shows 'Aktueller Verdienst', 'Gesamter offener Betrag'. `AppSettings({this.language = AppLanguage.german ...})` is at app_settings.dart:10-11, and SettingsProvider.locale feeds `MaterialApp.locale`, so the device locale is never consulted.

### B16 — **confirmed**

*Claim:* Notification permission requested before runApp, blocking the first frame (main.dart:27, notification_service.dart:24-28).

The real `app.main()` ran with `requestNotificationsPermission` left pending. After 5 s, ChronosApp was not mounted (0). Channel calls were `[initialize, requestNotificationsPermission]`. After completing the request, ChronosApp was mounted (1).

Small correction: the await is at main.dart:28 (:27 creates the service); the request is at notification_service.dart:24-28. Only Android 13+ shows a dialog, so only there does the #121212 launch background stay until the user answers.

### B30 — **confirmed**

*Claim:* Unkeyed list rows: after delete/insert, state/animations (paid highlight AnimatedContainer, scale controller) shift to neighbouring rows.

Before the delete, row C (unpaid) had border=false and color #1E1E1E; row B (paid) had border=true and blue alpha 0.149.

After deleting B through the UI, row C inherits B's element:
- +0 ms: border=true, alpha 0.149 (blue);
- 50–250 ms: fading;
- 300 ms: border=false, #1E1E1E.

So the deleted row's paid highlight is shown on its neighbour for about 300 ms. I did not observe a visible scale-controller shift, because the controller is at rest after the sheet closes. AnimatedListItem at work_log_screen.dart:155 has no key.

### B35 — **confirmed**

*Claim:* Android back on the Log tab exits the app instead of returning to Home; tab switch loses Log scroll position.

On the Log tab, `handlePopRoute()` returned false and invoked `SystemNavigator.pop` (captured on SystemChannels.platform); the tab stays on Log.

Scroll: after scrolling to 1500 px, going Home and back gives 0.0. The Log screen is rebuilt, because AnimatedSwitcher drops the old child and there is no PageStorageKey or IndexedStack.

### B27 — **confirmed**

*Claim:* Date pickers limited to 2020–2030 (showDatePicker assert risk after 2030; future dates allowed).

The add picker has `firstDate=2020-01-01` and `lastDate=2030-01-01 00:00`, with `initial=2026-09-30`. Future dates up to 2029-12-31 are selectable.

Editing an entry dated 2031-03-01 fails the assertion 'initialDate ... must be on or before lastDate 2030-01-01' (date_picker.dart:239). One dated 2019 fails 'must be on or after firstDate' (:235). No picker opens.

Correction: the Add dialog uses `initialDate: now`, so it will assert from 1 Jan 2030, not only after 2030. In release the assert is stripped, so the behaviour there is untested.

### B28 — **confirmed**

*Claim:* Editing a >24h entry silently shortens it.

A 30 h entry (08:00 20.09. – 14:00 21.09.) was opened in Edit and saved unchanged. It became 2026-09-20 08:00 – 2026-09-20 14:00 = 6:00:00. The end date is rebuilt from `selectedDate` plus the end time-of-day, plus one day only if end <= start (work_log_screen.dart:743-752).

### B39 — **confirmed**

*Claim:* Home 'current earnings' is per-session, not 'today' as the spec wants.

The spec (App Spezifikationen.docx) says: 'Mittig Oben ... der Betrag der aktuell verdienten Summe dieses Tages'.

Test: a 2 h session was running (current earnings 30.00), then stopped. Today then has one 2 h entry, but Home shows current/open=[0.0, 30.0]. `getCurrentEarnings` only uses the running session's `_elapsed` (timer_provider.dart:78-82).

### UX-contrast — **confirmed**

*Claim:* White text on #22C55E ≈2.28:1, on #3B82F6 ≈3.68:1, on #EF4444 ≈3.76:1.

WCAG 2.x relative-luminance computation: white on #22C55E = 2.279:1, on #3B82F6 = 3.678:1, on #EF4444 = 3.763:1. These are AppThemeData.success, electricBlue and error (app_theme.dart:15,19,20).

All fail 4.5:1 for normal text. #22C55E also fails 3:1. It is used for the 10 px bold white 'Abgerechnet' badge (work_log_screen.dart:193-206) and the START button text.

### ICONS — **confirmed**

*Claim:* Launcher PNGs are 2048x2048 (~2.2 MB) copied into all mipmap densities; adaptive icon has transparent background and no monochrome layer.

Each of mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png and drawable/ic_launcher_foreground.png is 2048x2048, 8-bit RGBA and 2,201,994 bytes. All six have the same md5 prefix, c12117ec.

mipmap-anydpi-v26/ic_launcher.xml and ic_launcher_round.xml contain `<background android:drawable="@android:color/transparent"/>` and a foreground (a 17% inset of the same PNG). There is no `<monochrome>` element.

### BACKUP — **confirmed**

*Claim:* AndroidManifest has no allowBackup/dataExtractionRules -> Auto Backup implicitly on; privacy.html claims data never leaves the device.

The app manifest's `<application>` has only label, name and icon. The plugin manifests (flutter_local_notifications 18.0.1, shared_preferences_android 2.4.7) set no backup attributes either. So allowBackup defaults to true, and Auto Backup copies shared_prefs (all entries and the wage) to Google Drive and to device transfers.

privacy.html:31 says: "Alle Informationen die du in der App eingibst – Arbeitsstunden, Stundenlohn, Einträge – werden ausschließlich lokal auf deinem Gerät gespeichert und verlassen dieses niemals."

### GRADLE — **confirmed**

*Claim:* Gradle 8.9 / AGP 8.7.0 / Kotlin 2.1.0 are below the current Flutter 3.47.5 hard minimums.

flutter_tools/gradle/src/main/kotlin/DependencyVersionChecker.kt:94-109 sets:
- errorGradleVersion 8.14.0 (warn 9.1.0);
- errorAGPVersion 8.11.1 (warn 9.0.1);
- errorKGPVersion 2.2.20 (warn 2.3.20).
It throws DependencyValidationException below the error levels; the bypass is `--android-skip-build-dependency-validation`.

The project uses gradle-wrapper 8.9, and settings.gradle declares AGP 8.7.0 and Kotlin 2.1.0. All three are below the error minimums. They were fine for the owner's Flutter 3.24.5.


## New findings

1. **Unguarded ScaffoldMessenger after save (home_screen.dart:290).** `ScaffoldMessenger.of(context)` runs after `await entries.saveEntry(...)` with no second `mounted` check. If Home is left during the save, it throws 'Looking up a deactivated widget's ancestor is unsafe' (release: a null-check error). The entry is saved, but there is no snackbar and the error is uncaught. Reproduced at 250–350 ms write latency with a tab switch. In verify_claims_test these are the two red B04 cases.

2. **Edit dialog Save is not re-entrant (work_log_screen.dart:734-776).** A double tap during the write pops MainScreen and leaves a blank screen (200 ms latency).

3. **A deleted entry can come back (storage_service.dart:21-30).** Save is an upsert. `togglePaidStatus` (work_entries_provider.dart:39-47) builds from `_entries`, which is still stale during the delete write. So toggling or editing a row whose delete is still in flight re-inserts the deleted entry. Reproduced: A came back as paid.

4. **Duplicate ids corrupt data on toggle.** `togglePaidStatus` finds the entry by index in the sorted `_entries`, but storage replaces the first stored entry with that id. The other entry is overwritten by a copy. Reproduced: the 16:30 entry was lost and 16:35 was stored twice. Delete of a duplicated id removes all copies.

5. **Delete errors are silently swallowed (work_log_screen.dart:351).** `_showDeleteConfirmation` is fire-and-forget, and nothing in `deleteEntry` or storage catches errors. Any storage exception is lost: no snackbar, and the UI stays stale while the prefs cache is already changed.

6. **Double-tapping a list row does nothing visible.** The modal sheet opens and its barrier accepts the second tap during the entrance animation, so the sheet closes at once (0 sheets open afterwards).

7. **Delete-all field unreachable on small phones (settings_screen.dart:283).** At 360x740 with a 300 dp keyboard, the confirm TextField is clipped and not hittable (32 px overflow); the button is still reachable. The confirm word also rejects 'löschen' and 'LÖSCHEN' (case-sensitive), and every text except the two button labels stays German in English mode.

8. **B27 is worse than stated.** `lastDate: DateTime(2030)` is 2030-01-01 00:00, so the Add dialog will assert for the whole of 2030, and the last selectable day is 2029-12-31.

9. **Home button row overflows at typical width (home_screen.dart:148).** The START/STOP Row overflows by 14 px at 411 dp width with real Roboto metrics, and by 65 px at 360 dp.

10. **Citation fix.** The B16 await is at main.dart:28, not :27.

11. **Environment note.** The owner's build used Flutter 3.24.x: the repo lock pins leak_tracker 10.0.5, test_api 0.7.2 and vm_service 14.2.5, and the code uses `CardTheme`. I installed a separate Flutter 3.24.5 SDK at scratchpad/f324/flutter. I ran the delete suites on the unmodified repo code in scratchpad/repro324, with identical results to 3.47.5. The 3.47.5 SDK was not touched.
