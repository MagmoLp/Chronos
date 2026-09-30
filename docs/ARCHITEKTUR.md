# Chronos 2.0 – Architektur

Kurzüberblick für alle, die an Chronos arbeiten. Regeln: `CLAUDE.md`, Funktionsumfang: `docs/SPEC_2_0.md`.

## Schichten

```
features/  widgets/        UI: zeigt Zustand, ruft Controller-Methoden auf. Keine Rechnungen.
   │
app/providers/             Riverpod 3 (handgeschrieben): Provider = Lesen, Controller = Handeln.
   │
data/                      drift-Datenbank, Repositories, v1-Migration, Backup, Löschen.
   │
domain/                    Reines Dart: Modelle + Logik (Lohn, Rundung, Prüfung, Statistik …).
core/                      LocalDate, Zeit-Helfer, Cent-Rechnung, Uhr (clockProvider).
```

Abhängigkeiten zeigen nur nach unten. `domain/` kennt weder Flutter noch drift und ist vollständig
unit-getestet (auch unter `TZ=Europe/Berlin`).

## Datenmodell (drift, Schema 1)

| Tabelle | Inhalt |
|---|---|
| `jobs` | id, uuid, name, colorArgb, rounding (`none`/`nearest5`/`nearest15`), archived, sortOrder |
| `wage_rates` | jobId, validFrom (`yyyymmdd`), centsPerHour – eindeutig je Job und Datum |
| `shifts` | status `running`/`done`; `startUtc`/`endUtc` = abgerechnete Zeiten (gerundet), `rawStartUtc`/`rawEndUtc` = erfasste Zeiten; Offsets in Minuten für Start und Ende; `rateCentsPerHour` (Lohn-Schnappschuss); `breakMs`, `pausedAtUtc`; `tipsCents`; `note`; `paidAtUtc`, `payoutId`; `amountCents` (beim Abschluss berechnet); `legacyId`; `source`; `createdAt`/`updatedAt`/`deletedAt` |
| `payouts` | uuid, jobId (`null` = alle Jobs), untilDate, paidOn, expectedCents, receivedCents, note |
| `review_items` | shiftId → Gründe (Prüfliste nach der Übernahme) |
| `legacy_errors` | nicht übernehmbare v1-Einträge (roh + Code) |
| `meta` | interne Schlüssel, z. B. `legacy_v1.migrated_at` |

Zeiten sind UTC-Millisekunden, Geld `int` Cent. Höchstens eine laufende Schicht: geprüft im Repository **und**
per Teil-Index `shifts_one_running … WHERE status = 'running' AND deleted_at IS NULL`.
Datenbank: `driftDatabase(name: 'chronos', native: DriftNativeOptions(shareAcrossIsolates: true))`,
damit Benachrichtigungs-Aktionen im Hintergrund-Isolat dieselben Daten sehen. Einstellungen liegen in
`SharedPreferencesWithCache` (Allow-List), nicht in der Datenbank.

## Rechenregeln (domain)

- Verdienst: `earningsCents(workedMs, centsPerHour)` = `(ms × Cent/h + 1 800 000) ~/ 3 600 000` (half-up, überlaufsicher).
- Gearbeitet = Ende − Start − Pause, nie negativ. Laufende Schicht: `liveValues(shift, now)`; nichts wird hochgezählt.
- Rundung (`roundToRule`): nächster 5/15-Minuten-Wert der lokalen Uhr, genau die Hälfte rundet auf; nur beim
  Beenden einer Timer-Schicht, manuelle Schichten nie. Sicher an Umstellungstagen (nie mehr als ½ Schritt Abstand).
- Eine Schicht gehört zum lokalen Tag ihres Starts. Wochen beginnen Montag. Datumsrechnung nur über `LocalDate`.
- Lohnänderung gilt ab Datum; alte Schichten behalten ihren Schnappschuss, außer `addRate(recalcOpenFromDate: true)`.
- Prüfung (`validateShift`): Fehler = Ende ≤ Start, Pause ≥ Dauer, negative Werte; Warnungen = > 16 h,
  Überschneidung (mit Angabe der Schicht), Start in der Zukunft.

## v1-Übernahme (`data/legacy`)

Beim Start (idempotent über `meta`): alte Schlüssel über die **alte** `SharedPreferences`-API lesen →
Rohdaten als `legacy_backup_v1.json` sichern → in **einer** Transaktion Job „Mein Job“ (15-min-Rundung,
alter Lohn ab dem ältesten Eintrag), jede Zeile einzeln umwandeln (lokale Zeit → UTC + Offsets), bezahlt
übernehmen, laufende Sitzung als laufende Schicht → Prüfliste (≥ 16 h, genau 23/24 h, gleiche Zeiten,
doppelte IDs, Überschneidungen, Umstellungstage) und Fehlerliste speichern. Lohn außerhalb 5–100 €/h →
`pendingWageCheck` (Vorschlag z. B. 12,50 € statt 1250 €), Korrektur mit `ReviewController.fixWage`.
Alte Schlüssel werden nie gelöscht; „Alle Daten löschen“ behält `meta`, damit nichts erneut importiert wird.

## Provider und Controller (`app/providers/providers.dart`)

**Lesen** – reaktiv aus drift-Streams, nichts tickt:

| Provider | Typ | Inhalt |
|---|---|---|
| `bootstrapProvider` | `FutureProvider<BootstrapResult>` | Einstellungen, v1-Migration, Aufräumen, Abgleich |
| `settingsProvider` | `AppSettings` | Sprache, Design, Ziel, Erinnerung, Flags |
| `jobsProvider`, `activeJobsProvider`, `defaultJobProvider`, `jobRatesProvider(id)` | Streams / `AsyncValue` | Jobs und Lohnhistorie |
| `runningShiftProvider`, `runningShiftWithJobProvider` | Stream / `AsyncValue` | laufende Schicht |
| `shiftListProvider(filter)`, `shiftMonthGroupsProvider(filter)` | Stream / `AsyncValue` | Liste Alle/Offen/Bezahlt, nach Monaten |
| `todaySummaryProvider`, `weekSummaryProvider`, `openSummaryProvider` | `AsyncValue` | Heute / Woche / Offen |
| `statsProvider(StatsPeriod)`, `monthlyGoalProvider` | `AsyncValue` | Übersicht, Monatsziel |
| `payoutsProvider`, `payoutPreviewProvider((until:, jobId:))` | Stream | Auszahlungen |
| `reviewItemsProvider`, `legacyFailuresProvider`, `pendingWageCheckProvider` | Stream / Future | Prüfliste |

**Handeln** – Controller (`Notifier<bool>`, `true` = Aktion läuft; eine zweite Aktion währenddessen wirft
`ChronosException(busy)` → kein Doppel-Speichern):
`activeShiftControllerProvider`, `shiftsControllerProvider`, `payoutControllerProvider`,
`jobsControllerProvider`, `dataControllerProvider`, `reviewControllerProvider`, `settingsProvider.notifier`.
Abgelehnte Aktionen werfen `ChronosException` mit `ChronosErrorCode`; die UI übersetzt den Code.

**Live-Werte**: Die Summaries enthalten die laufende Schicht; das sichtbare Ticker-Widget rechnet
`summary.earnedCentsAt(clock.now())`. `msUntilNextCent` sagt, wann der nächste Cent fällig ist.
`currentDateProvider.notifier.refresh()` beim Fortsetzen der App aufrufen (Tageswechsel).

**Nebenwirkungen**: Nach jeder Änderung der laufenden Schicht rufen die Controller einmal
`ShiftSideEffects.shiftChanged(running, job)` auf (`shiftSideEffectsProvider`, Standard: tut nichts).
Die App überschreibt ihn mit der Benachrichtigungs-/Erinnerungs-Implementierung. `reconcile()` gleicht
beim Start und Fortsetzen ab. Fehler dort landen im Fehlerprotokoll (`errorLogProvider`), nie in der UI.

### Beispiele

```dart
// Heute-Karte: Daten lesen, live rechnen (nur solange sichtbar).
final today = ref.watch(todaySummaryProvider).value;
final cents = today?.earnedCentsAt(ref.read(clockProvider).now()) ?? 0;

// Schicht starten / beenden mit Rückgängig.
final active = ref.read(activeShiftControllerProvider.notifier);
await active.start(jobId);
final preview = await active.previewFinish();          // Werte fürs Beenden-Blatt
final result = await active.finish(breakMs: preview!.breakMs, tipsCents: 500);
// Snackbar: result.after.workedMs, result.after.amountCents → Rückgängig:
await active.undoFinish(result);

// Editor speichern.
final outcome = await ref.read(shiftsControllerProvider.notifier).save(draft, shiftId: id);
switch (outcome) {
  case ShiftSaved(:final shift): /* schließen */
  case ShiftSaveNeedsConfirmation(:final validation): /* Warnungen zeigen, dann save(..., confirmed: true) */
  case ShiftSaveInvalid(:final validation): /* Fehler an den Feldern */
}

// Wischen: bezahlt umschalten bzw. löschen, jeweils mit Rückgängig.
final paid = await shifts.togglePaid(id);   await shifts.undoPaid(paid);
final gone = await shifts.delete([id]);     await shifts.undoDelete(gone);
```

## Tests

`test/` spiegelt `lib/`. Datenbank-Tests laufen mit `NativeDatabase.memory()`, Zeit über `TestClock`
(`test/fixtures`). Zeitzonen-abhängige Fälle sind mit `skipUnlessBerlin` markiert und laufen mit
`TZ=Europe/Berlin flutter test`. v1-Testdaten: `test/fixtures/legacy_v1.dart`.
Generierter drift-Code (`lib/data/database.g.dart`) wird eingecheckt: `dart run build_runner build -d`.
