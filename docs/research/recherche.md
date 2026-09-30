# Market & technology research

> Raw research output from the Chronos analysis on 2026-09-30 (English). Line numbers refer to commit 9a52779 (v1.0.0). Summary and plan: [../UMBAUPLAN.md](../UMBAUPLAN.md).


## Competitors

### Time Recording – Timesheet App (DynamicG, CH)

- **Rating / installs:** about 4.5–4.56 stars from about 25k ratings, 1M+ installs (about 3M lifetime per AppGrooves); Pro edition 4.87 stars from about 6.2k ratings; on Play since May 2010; v7.92 updated May 2026. These are aggregator numbers from search snippets, because play.google.com and appbrain.com are blocked by the egress proxy here.
- **Strengths:** Very deep feature set built up over 15 years. Highly configurable (week start, bi-weekly reporting, hourly rates, paid overtime, daily/weekly/monthly target times). Actively maintained. Strong offline and backup story.
- **Common complaints:** Reviews call the UI and navigation confusing, e.g. 'UI and usability is horrible', 'navigation … extremely confusing and not intuitive'. Setup is hard. It shows ads unless you buy Pro. The smallest unit is 1 minute and there is no parallel tracking.
- **Notable features:** Check-in/out, tasks, daily notes, day/week/month overviews. Excel/PDF/HTML reports. Backup to Google Drive, Dropbox and ownCloud. One-way Google Calendar sync. Home-screen widget with punch action, status-bar notification while checked in. Tasker plugin, NFC tags, Wear OS app and tile, multi-device sync, target time and overtime balance.

### Timesheet – Work Time Tracker (rauscha / timesheet.io, AT)

- **Rating / installs:** about 3.7 stars from about 13k ratings (AppBrain snippet), 1M+ installs, on Play since 2011
- **Strengths:** The free tier has no account and no time limit and includes projects, breaks, expenses, statistics, exports and automations. Available on phone, tablet, Wear OS and web. Trustpilot shows 5 stars from about 789 reviews, with praise for fast support.
- **Common complaints:** The middling Play rating (3.7) points to friction. I could not read Play reviews directly. From the public tier model: cloud sync, automatic backup and PDF invoices sit behind Plus/Pro subscriptions, and the product has shifted toward freelancers/teams (projects, invoices, HR tiers), which is heavy for a simple hourly job.
- **Notable features:** Timer turns into billable hours. Breaks and expenses. Excel export. Automations. Plus tier: sync, multi-device, auto-backup. Pro tier: web app, PDF invoices, API, AI assistant. Business tier: absences and overtime balances.

### Hours Tracker: Time Tracking (Cribasoft, US)

- **Rating / installs:** about 3.6 stars from about 6.4k reviews, 1M+ installs (search snippets); vendor claims 120k+ active users
- **Strengths:** Made for hourly workers: tracks time and pay per job, with multiple jobs, tax-percentage estimates and rounding.
- **Common complaints:** Full-screen ads with tiny skip buttons next to 'download' buttons. Paying just to track more than one job ($6 for 5 jobs, $10 unlimited). The 21-day trial is only revealed after users have entered data. Tax-percentage calculation reported as wrong and not fixed. Reports of punches and days going missing (data loss).
- **Notable features:** Clock in/out, multiple jobs with rates, overtime, pay periods, tax estimate, reports, cloud backup (paid).

### WorkingHours Time Tracker (Timo Partl, AT)

- **Rating / installs:** about 4.79 stars from about 3.4k ratings, 100K+ installs (about 400k lifetime downloads per aggregator)
- **Strengths:** Modern UI and high rating. Tracks earnings per hour and activity. One-time purchase is offered as an alternative to a subscription, which users like. Cross-platform (Android, iOS, Windows, Mac).
- **Common complaints:** Many of the useful features are Pro-only (7-day trial): widget and notification timer controls, Excel/CSV export, cloud sync, geofencing, unlimited tasks. So the free version is weak for exactly the use case Chronos targets. It is aimed at freelancers and projects.
- **Notable features:** Widget and notification start/pause/stop. Tags and tasks. Graphs of time and earnings. Excel/CSV export. Geofencing and NFC auto-tracking. Calendar integration that turns appointments into tracked time. Pomodoro/focus sessions. Cloud sync.

### Timesheet: Work Hours Tracker (Bakua / Timechief)

- **Rating / installs:** 1M+ installs (Similarweb/search snippet); rating not verifiable here
- **Strengths:** Clearly aimed at hourly workers: automatic pay calculator, overtime detection, an overtime/deficit running balance, unpaid breaks, multiple pay rates and tax estimates. Clean calendar view of the work log.
- **Common complaints:** Not verifiable directly. It is subscription/freemium like most of the category. Tax estimates are US-centric and do not fit DE/AT payroll.
- **Notable features:** Clock in/out plus manual entry for past days. Calendar log. Overtime and deficit tracker. Leave management. Multiple rates. Unpaid breaks. Tax estimate.

### Clockify – Time Tracker (CAKE.com)

- **Rating / installs:** About 1.2M Android downloads. Ratings are inconsistent across sources (3.1 / 3.6 / 4.5 stars).
- **Strengths:** Free for unlimited users, strong web/desktop suite, team features, customizable, easy to learn.
- **Common complaints:** Mobile app: login errors, lost time entries, entries recorded on the wrong dates, sync problems (one user refreshes every 10 s so the running timer doesn't lose the date). Needs an account. Too team/project-oriented for a single hourly worker.
- **Notable features:** Timer and manual entries, projects, tags, billable rates, reports, web sync, kiosk and GPS on paid tiers.

### Toggl Track

- **Rating / installs:** about 4.6 stars from about 25k ratings, about 2.1M downloads (AppBrain via search); last update Mar 2026
- **Strengths:** Polished UX, cross-device sync, many integrations, strong brand.
- **Common complaints:** Sync is inconsistent: timers started on mobile don't stop on desktop, and signing out loses unsynced data. Users find the new mobile UI less intuitive (tracked time missing on the home page). Widgets and tiles are limited to paid plans. Price and a no-refund policy. Account required.
- **Notable features:** Timer, calendar view, projects and clients, Pomodoro, reports, home-screen widgets on paid plans, integrations.

### Supershift – Dienstplan / Shift Work Calendar (Supershift GmbH, DE)

- **Rating / installs:** about 4.67 stars from about 29k ratings, 2M+ installs
- **Strengths:** Best-in-class personal shift planner, popular with German shift workers. Colored shift templates with icons, fast to fill a month. Notes and breaks per shift. Statistics for earnings, shift allowances (Zulagen), hours per shift type, overtime and shift counts. Clean, aesthetic design.
- **Common complaints:** Pro (about €7.99) seen as pricey. Calendar export, PDF, cloud sync and external-calendar integration are Pro-only. It is a planner, not a live time clock, and doesn't replace real clock-in data. Consumer-only.
- **Notable features:** Shift templates, rotating patterns, month calendar, earnings and allowance statistics, overtime, calendar export/PDF (Pro), sync (Pro).

### Simple Time Tracker (Razeeman, open source)

- **Rating / installs:** about 1.2k GitHub stars; on Google Play and F-Droid; install and rating figures not retrieved
- **Strengths:** Free and open source, no ads, no account, offline, privacy-friendly. Minimal UI. Actively developed (Kotlin, Compose, MVVM, multi-module) and a good reference implementation.
- **Common complaints:** It tracks activities, not wages: no pay rates, surcharges or payouts. Setup can feel abstract for work-hour use.
- **Notable features:** Home-screen widgets, notifications, backup/restore, CSV export, statistics, goals, reminders, Wear OS app and complications, automation via intents, Pomodoro.

### Tip trackers for servers (Tipbook, Server44, Waiter Pal, TipSee, Track My Tips)

- **Rating / installs:** Several small apps; ratings not verified here (Play blocked)
- **Strengths:** Built for hospitality staff. Cash vs card tips, tip-out, 'true hourly rate' (wage + tips), per-shift take-home, weekly/monthly totals, calendar view, logging a shift in under 30 s.
- **Common complaints:** US-centric (tipped minimum wage, US taxes). Weak or no live clock-in. Little or no DE/AT law awareness (breaks, Minijob limit, §3b surcharges).
- **Notable features:** Tip logging, tip-out calculation, effective hourly rate, multiple jobs, goals, earnings dashboard.


## Feature ideas

| Priority | Effort | Feature |
|---|---|---|
| must | M | Crash-safe shift engine: start / pause / resume / stop and retroactive edits |
| must | M | Multiple jobs / employers |
| must | S | Wage history and per-shift wage snapshot |
| must | M | Breaks: manual pause plus automatic legal minimum |
| must | M | Payout periods and payslip reconciliation |
| must | M | Statistics dashboard |
| must | M | Timesheet export (PDF and CSV) |
| must | S | Backup and restore (local file) plus Android Auto Backup |
| must | S | Onboarding and first-run setup |
| must | S | Ongoing notification with native chronometer and actions |
| must | M | Adaptive, modern UI (Material 3, system theme, tablets and landscape) |
| must | S | Better work log: grouping, filters, swipe actions, undo |
| should | S | Tips tracking |
| should | L | Surcharge rules (night / Sunday / holiday) with DE and AT presets |
| should | S | Minijob / Geringfügigkeit limit monitor |
| should | S | Reminders: forgot to clock out, shift start, weekly summary |
| should | L | Shift planning and calendar |
| should | S | Shift templates and quick add |
| should | S | Notes and tags per shift |
| should | M | Home-screen widget |
| could | S | Monthly goals |
| could | S | Rounding rules |
| could | M | Overtime / target hours balance |
| could | S | Gross-to-net estimate |
| could | M | Quick Settings tile |
| could | S | Calendar export (ICS / add to calendar) |
| could | S | NFC tag start/stop |
| could | M | Absences (vacation / sick days) |
| could | S | Android 16 Live Update (status-bar chip) |
| could | S | App lock |
| could | L | Google Drive backup |
| could | L | Geofencing auto start/stop (evaluated, not recommended now) |
| could | S | In-app review prompt and feedback link |

### Crash-safe shift engine: start / pause / resume / stop and retroactive edits (must, M)

Replace the 1 s ticking provider with a persisted state model: one running shift row with startUtc, pausedAt and pausedTotal. Everything shown is computed from those timestamps. Add 'I started 20 min ago' and 'stop at 23:15' adjustments, plus undo for stop and delete.

- **User value:** Catering staff often forget to clock in or out, or get interrupted. Correct time and wage even after an app kill, a reboot or a forgotten tap is the core promise of the app.
- **Tech notes:** The current code has no pause and holds session state in a ChangeNotifier driven by Timer.periodic(1s) (lib/providers/timer_provider.dart:55-64). Store UTC epoch ms plus the local offset in drift; use package:clock for testability; enforce a single running shift (partial unique index or a check in the repository). Recompute on resume; never trust in-memory counters.

### Multiple jobs / employers (must, M)

Jobs with name, employer, color, icon, hourly wage, employment type (DE Minijob / Midijob / regular / Werkstudent; AT geringfügig / Teilzeit), break rule, surcharge profile and rounding rule. Every shift belongs to a job. Filters and totals per job.

- **User value:** Students and catering workers often combine two or three jobs (restaurant, events, bar). Competitors charge for more than one job (Hours Tracker), so offering it free is a differentiator.
- **Tech notes:** drift tables jobs + wage_rates. On migration, all legacy entries go into a default job. The color drives chips, calendar dots and the widget. Archive rather than delete jobs that have shifts.

### Wage history and per-shift wage snapshot (must, S)

Wage rates with a valid-from date (e.g. minimum wage €13.90 from 1 Jan 2026, €14.60 from 1 Jan 2027). Each shift stores the rate it was earned at.

- **User value:** Today, changing the hourly wage in settings silently rewrites the earnings of every past entry, because WorkEntry has no wage (lib/models/work_entry.dart:18-21 uses one global wage). History makes past totals and payouts stable.
- **Tech notes:** Money as int cents. Earnings = rateCents * workedMs / 3,600,000, rounded half-up to cents once when the shift is closed. Offer 'apply new rate to unpaid shifts since …?' when the wage changes.

### Breaks: manual pause plus automatic legal minimum (must, M)

Pause/resume during a shift and manual break minutes in the editor. Per-job rule: automatically deduct the statutory minimum when recorded breaks are shorter (DE §4 ArbZG: more than 6 h → 30 min, more than 9 h → 45 min; AT §11 AZG: more than 6 h → 30 min). Paid vs unpaid breaks. Warn when 6 h are worked without a break.

- **User value:** Payslips in gastronomy deduct breaks. Without break handling, the expected pay in the app never matches the payslip, which is exactly what users want to check.
- **Tech notes:** breaks table (shiftId, start, end). Pure-Dart BreakPolicy that can be unit-tested at edge cases (exactly 6:00 h → no break, 6:01 h → 30 min). Youth rules (JArbSchG/KJBG) as an optional preset. The notification switches between chronometer and 'Pause seit …'.

### Payout periods and payslip reconciliation (must, M)

Replace the per-entry paid toggle with Abrechnungen: pick a period (calendar month, 2 weeks, custom) per job. The app shows expected gross (base + surcharges) next to the amount actually received, highlights the difference, and marks all shifts in that period as paid in one step. The open amount is shown per job and in total.

- **User value:** 'Did my boss pay me correctly?' is the main question hourly workers have. Answering it replaces the clunky long-press toggles.
- **Tech notes:** payouts table (jobId, periodStart, periodEnd, expectedCents, receivedCents, paidOn, note) with shifts.payoutId. Payout reminders on a chosen day of the month (inexact scheduled notification). Keep the legacy isPaid boolean during migration.

### Statistics dashboard (must, M)

Week, month and year views: hours, gross earnings, tips, effective hourly rate (wage + tips), number of shifts, averages, and comparison with the previous period. Bar chart per day or week, stacked by job. Totals per job. The home screen shows today, this month and the open amount.

- **User value:** The app does little beyond a counter today. Statistics give it long-term value and motivation.
- **Tech notes:** fl_chart 1.2.0. Aggregate in SQL (drift customSelect with GROUP BY on local-date buckets; compute buckets in Dart when crossing DST). Riverpod family providers per period.

### Timesheet export (PDF and CSV) (must, M)

Monthly Stundenzettel per job as a PDF (date, start, end, break, net hours, rate, amount, totals, signature line) and CSV. Share it or save it via the system file picker.

- **User value:** Many Minijob and gastronomy employers ask staff to hand in hours. The §17 MiLoG record (start, end, duration) is exactly this table. Also useful for disputes.
- **Tech notes:** pdf 3.13.1 + printing 5.15.1 (share/print). csv 8.0.0 with ';' delimiter, decimal comma and a UTF-8 BOM so German Excel opens it correctly. share_plus 13.3.0; file_picker 13.1.0 saveFile (Storage Access Framework, no storage permission). Real .xlsx only if needed: syncfusion_flutter_xlsio (community license terms apply) or the stale excel 4.0.6.

### Backup and restore (local file) plus Android Auto Backup (must, S)

Export and import the whole database as versioned JSON (or a SQLite copy) through the file picker or share sheet. Enable Android Auto Backup with explicit dataExtractionRules so data comes back on a new phone. Suggest a backup when many unexported shifts have piled up.

- **User value:** Data loss is the top complaint across competitors (Hours Tracker, Clockify, Toggl). Earnings history is valuable.
- **Tech notes:** Auto Backup: 25 MB quota, runs about once a day when idle and on Wi-Fi, end-to-end encrypted on Android 9+ with a screen lock. The manifest currently has no backup rules. Add android:dataExtractionRules plus fullBackupContent including the database and sharedpref domains. Import must validate the schema version and ask whether to merge or replace.

### Onboarding and first-run setup (must, S)

Three short steps: country (DE/AT) and, for DE, the Bundesland (holidays); first job (name, wage, employment type such as Minijob); explain the live counter. Ask for notification permission only when the user first taps Start.

- **User value:** The right defaults (break law, Minijob limit, holidays) without a settings maze, and no permission prompt on first launch.
- **Tech notes:** The current code requests POST_NOTIFICATIONS in NotificationService.init before runApp (lib/services/notification_service.dart:24-28, lib/main.dart:27-29). Use areNotificationsEnabled() and requestNotificationsPermission() in context; openAppNotificationSettings() (f_l_n ≥22.3) after a denial.

### Ongoing notification with native chronometer and actions (must, S)

Post once per state change: title 'Arbeitest bei <Job>', body 'seit 17:02 · 15,00 €/h'. SystemUI renders the running clock. Actions: Pause/Resume (runs in the background) and Stop (opens an end-of-shift sheet for tips, break and confirmation).

- **User value:** See and control the shift from the lock screen and shade without opening the app, at zero battery cost.
- **Tech notes:** flutter_local_notifications 22.3.1: usesChronometer, when = now - worked, onlyAlertOnce, silent, Importance.low, category stopwatch, AndroidNotificationAction with an onDidReceiveBackgroundNotificationResponse entry point. No periodic reposting (today it reposts every 15 s: timer_provider.dart:66-77). Localize the channel name and texts (they are hardcoded German at notification_service.dart:14-16,58-60).

### Adaptive, modern UI (Material 3, system theme, tablets and landscape) (must, M)

Rebuild the UI on Material 3 with a seed-based ColorScheme from brand navy #001F3F in light and dark, ThemeMode system/light/dark, and optional dynamic color. NavigationBar on phones, NavigationRail and two-pane layout at 600 dp and above. Everything scrollable, no fixed heights. Tabular figures for counters.

- **User value:** Fixes the 'klobig' feel, the landscape overflow and the broken theme switch (MaterialApp hardcodes theme: AppThemeData.darkTheme at lib/main.dart:82, and the colors are static consts in lib/theme/app_theme.dart:12-20). Android 16 forces resizable layouts on tablets anyway.
- **Tech notes:** LayoutBuilder or MediaQuery.sizeOf breakpoints 600/840. Golden tests for phone portrait, phone landscape, 10-inch tablet, both themes, DE/EN and font scale 2.0. Bundle the font as an asset (no runtime google_fonts fetch; GDPR). Replace the per-digit AnimatedSwitcher+Opacity+ClipRect (lib/widgets/animated_digit.dart:70-95) with a cheaper animation.

### Better work log: grouping, filters, swipe actions, undo (must, S)

Sticky month and week headers with totals. Filter by job, paid/open and period. Swipe to delete (with undo snackbar) or duplicate. Tap to edit instead of long-press. Visible edit button. Search by note.

- **User value:** The log is where users spend time after the shift; long-press editing isn't discoverable.
- **Tech notes:** flutter_slidable 4.0.3 or Dismissible. drift watch queries with LIMIT/OFFSET or keyset paging. Handle overnight shifts and DST correctly (display in local time, store UTC).

### Tips tracking (should, S)

Per shift: cash tips, card tips and tip-out/Tronc. Shown separately from wage. Effective hourly rate including tips. Monthly tip totals. Tips are excluded from Minijob-limit calculations.

- **User value:** In catering, tips can be 20-50% of income. Dedicated tip trackers exist for exactly this reason (Tipbook, Server44).
- **Tech notes:** Integer-cent columns on shifts. Entered in the end-of-shift sheet opened from the Stop action. In DE, tips from customers are tax- and SV-free (§3 Nr. 51 EStG); in AT they are tax-free but subject to SV via the Trinkgeldpauschale. The UI should only label them, not compute tax.

### Surcharge rules (night / Sunday / holiday) with DE and AT presets (should, L)

Per-job surcharge profile: percentage per time window (e.g. night 20–6 at 25%, 0–4 at 40% if started before midnight, Sunday 50%, holiday 125%, Dec 24/25/26 and May 1 at 150%), or custom rules from the contract or Tarifvertrag. Holidays computed offline per Bundesland (DE) or nationally (AT). Earnings are split into base and surcharges.

- **User value:** Night, Sunday and holiday premiums are common in gastronomy and are the most frequent reason a payslip differs from the naive hours × wage.
- **Tech notes:** Pure-Dart engine that slices a shift into minute intervals against the rule windows. Holiday calculator (Gauss/Anonymous Gregorian Easter algorithm plus fixed dates, a Bundesland table). Presets are only suggestions: statutory tax-free limits (§3b EStG) are not an entitlement, and the actual premium comes from the contract. Extensive unit tests across midnight, DST and New Year.

### Minijob / Geringfügigkeit limit monitor (should, S)

For jobs flagged as Minijob (DE, €603/month in 2026, €7,236/year) or geringfügig (AT, €551.10/month in 2026): a progress bar of this month's gross, a forecast from planned shifts, and warnings at 80/100%. Shows the DE exception for occasional overruns (at most 2 months within 12, up to €1,206).

- **User value:** Going over the limit has real consequences (full social insurance; in AT since 2026 also for people on unemployment benefit). Nobody else in the category offers this for DE/AT.
- **Tech notes:** Store limits in a versioned constants table keyed by year and country; add 2027 values (€633) when confirmed. Sum across all Minijob jobs (DE: multiple Minijobs are added together). Exclude tax-free tips and tax-free SFN surcharges only with a clear 'estimate' disclaimer.

### Reminders: forgot to clock out, shift start, weekly summary (should, S)

If a shift runs longer than X h, or longer than the planned end plus 30 min, notify 'Still working?' with Stop/Continue. Remind 10 min before a planned shift ('Start timer?'). Optional Sunday-evening summary.

- **User value:** Prevents 14-hour shifts that were really forgotten stops, which is the most common data-quality problem.
- **Tech notes:** zonedSchedule with AndroidScheduleMode.inexactAllowWhileIdle (no SCHEDULE_EXACT_ALARM/USE_EXACT_ALARM needed; Play restricts USE_EXACT_ALARM to alarm/calendar apps). Needs the ScheduledNotificationReceiver and BootReceiver in the manifest plus RECEIVE_BOOT_COMPLETED; timezone + flutter_timezone. Cancel or reschedule on stop or edit.

### Shift planning and calendar (should, L)

Enter upcoming shifts (planned start/end, job) in a month calendar. See expected earnings for the month. Turn a planned shift into an actual one with one tap (or it auto-suggests when the timer starts near the planned time). Show planned-vs-actual deviation.

- **User value:** Catering staff get weekly Dienstpläne; the planner-plus-tracker combination is what Supershift users ask for (Supershift has no real time clock).
- **Tech notes:** table_calendar 3.2.1 (or a custom grid). shifts.status = planned/running/done, or a separate planned_shifts table. Planned shifts feed the Minijob forecast and reminders.

### Shift templates and quick add (should, S)

Templates such as 'Spätdienst 17–23 (30 min Pause)' or 'Event 10–18' per job, with a color. Quick-add past shifts and fill the plan quickly (multi-select days).

- **User value:** Entering many similar shifts takes seconds instead of minutes (Supershift's most praised feature).
- **Tech notes:** templates table (jobId, startMinuteOfDay, durationMin, breakMin, color). Handle templates that cross midnight.

### Notes and tags per shift (should, S)

Free-text note (e.g. 'Hochzeit Müller, Location X') and optional tags (event, Service, Bar, Küche). Searchable and included in exports.

- **User value:** Useful for event catering, where every shift is a different location or client, and for disputes.
- **Tech notes:** Columns on shifts plus a tags table (many-to-many), or a simple comma-separated field for v2.0. FTS5 search is possible later via drift.

### Home-screen widget (should, M)

2x2 or 4x2 widget: job color, running clock (native Chronometer), rate, today's and this month's earnings, one start/stop button. A 'pin widget' button in settings.

- **User value:** One-tap clock-in without opening the app. Competitors lock this behind Pro (WorkingHours, Toggl).
- **Tech notes:** home_widget 0.10.0 with a native Kotlin HomeWidgetProvider and XML RemoteViews containing <Chronometer> via RemoteViews.setChronometer(base = elapsedRealtime - workedMs). Set updatePeriodMillis to 0 and update only on state changes. registerInteractivityCallback for the toggle (runs via WorkManager since 0.8.1). requestPinWidget(). Avoid scheduleWidgetUpdates (alarm-based).

### Monthly goals (could, S)

Earnings or hours target per month (e.g. save €400), with a progress ring on the home screen and a forecast from planned shifts.

- **User value:** Motivation and planning for students saving up.
- **Tech notes:** A settings row plus a derived provider. Pairs with the Minijob monitor (a goal must not exceed the limit).

### Rounding rules (could, S)

Per job: round start and end to 1/5/10/15 minutes (nearest, up or down), matching employer policy.

- **User value:** Makes expected pay match employers that round.
- **Tech notes:** Apply rounding only in the pay engine and keep the raw timestamps. Show 'gerundet' in the log.

### Overtime / target hours balance (could, M)

For part-timers with contracted hours (e.g. 20 h/week): running plus/minus balance, AT Mehrarbeit and Überstunden hints.

- **User value:** Part-time catering staff want to know whether they worked more than contracted.
- **Tech notes:** Contract hours per job with a valid-from date. Weekly and monthly balance computed in the domain layer. Don't claim legal entitlements; the AT 25% (Mehrarbeit) and 50% (Überstunden) surcharges are only informational presets.

### Gross-to-net estimate (could, S)

Simple and honest: DE Minijob gross minus 3.6% pension contribution unless exempt; AT geringfügig about equal to gross. For other jobs, a user-defined deduction percentage. Clearly labeled as an estimate.

- **User value:** Users want to know what actually lands in their account.
- **Tech notes:** Don't implement the BMF Lohnsteuer program (PAP) or Midijob formulas in v2. Link to the official calculators (BMF, bmf.gv.at Brutto-Netto-Rechner). Keep the constants per year.

### Quick Settings tile (could, M)

Tile in the notification shade showing state (active or inactive) and toggling start/stop.

- **User value:** Fastest possible clock-in/out, especially with gloves or wet hands in a kitchen.
- **Tech notes:** There is no maintained Flutter plugin (quick_settings 1.0.1 is from 2023), so it needs a native Kotlin TileService (about 80 lines) that reads state from the widget SharedPreferences. onClick either sends a HomeWidgetBackgroundIntent or calls startActivityAndCollapse(PendingIntent) with a deep link. StatusBarManager.requestAddTileService on Android 13+.

### Calendar export (ICS / add to calendar) (could, S)

Export planned shifts as an .ics file or add a single shift to the system calendar.

- **User value:** Shifts show up next to private appointments.
- **Tech notes:** add_2_calendar 3.1.1 (intent-based, no permission) or generate an ICS string and share it. Full two-way sync (device_calendar_plus 0.9.0, still pre-1.0; device_calendar 4.3.3 unmaintained since 2024) needs READ/WRITE_CALENDAR, so it's not worth it.

### NFC tag start/stop (could, S)

Stick a cheap NFC tag at the staff entrance; tapping the phone toggles the shift.

- **User value:** A reliable 'auto' clock-in without location permissions. Time Recording and WorkingHours offer it.
- **Tech notes:** No plugin needed: an intent-filter for NDEF_DISCOVERED with a chronos://toggle URI opens the app, and go_router or app_links handles it. Writing the tag can be done in any NFC app, or with nfc_manager 4.2.1 later.

### Absences (vacation / sick days) (could, M)

Record paid vacation or sick days per job with the expected pay (e.g. average of recent earnings).

- **User value:** Minijobbers are also entitled to paid leave and sick pay, and many don't know it. Makes payouts reconcile.
- **Tech notes:** absences table. Pay estimate uses the average over the previous 13 weeks (DE §11 BUrlG reference period) and is labeled an estimate.

### Android 16 Live Update (status-bar chip) (could, S)

Promote the ongoing shift notification to a Live Update so a chip with the running time appears in the status bar and lock screen.

- **User value:** Glanceable shift status on Android 16+ devices.
- **Tech notes:** Needs POST_PROMOTED_NOTIFICATIONS (normal permission) and setRequestPromotedOngoing(true), with no custom views and no colorized style. flutter_local_notifications doesn't support it yet: PR #2810 was still open on 29 Sep 2026 and needs androidx.core 1.19, compileSdk 37 and AGP 9.1. Until then it needs a small MethodChannel. The use case (user-initiated ongoing activity) matches the policy, but OEMs may apply extra rules.

### App lock (could, S)

Optional biometric or PIN lock for the app.

- **User value:** Privacy of income data on shared devices.
- **Tech notes:** local_auth 3.0.2. Lock on resume after N minutes.

### Google Drive backup (could, L)

Optional automatic backup to the user's own Drive (appDataFolder).

- **User value:** Cross-device safety beyond Android Auto Backup.
- **Tech notes:** google_sign_in 7.2.0 + googleapis 17.0.0 (Drive v3, drive.appdata scope). Needs an OAuth consent-screen setup, a privacy policy update and a Data safety review. Android Auto Backup plus manual export covers most needs first.

### Geofencing auto start/stop (evaluated, not recommended now) (could, L)

Automatically suggest or start a shift when arriving at the workplace.

- **User value:** Convenient in theory, but most catering staff have irregular locations (events), so a reminder is better than auto-start.
- **Tech notes:** Needs ACCESS_FINE and ACCESS_BACKGROUND_LOCATION. Google Play requires a location-permissions declaration with a video and rejects non-core use. Location must be declared in Data safety. geofence_service is discontinued; native_geofence 1.3.1 uses the OS geofencing APIs (no foreground service). Prefer NFC or a planned-shift reminder.

### In-app review prompt and feedback link (could, S)

After about 10 completed shifts and no recent crash, ask for a Play review. Settings has feedback by email.

- **User value:** Ratings for a hobby app launch; direct bug reports.
- **Tech notes:** in_app_review 2.0.12 (the Play In-App Review API has quota limits, so it may not show). package_info_plus 10.2.1 for the version in feedback mails.

## Battery-friendly background tracking

## TL;DR: minimal, battery-neutral design (recommended)

- **The app runs no code in the background:** no foreground service, no WorkManager, no background isolate, no Dart `Timer` while the app is not visible.
- **Source of truth is persisted timestamps** (start, pause start, total paused) in the database. Elapsed time and live wage are pure functions of `(timestamps, now, rate)`, so killing, rebooting or freezing the app never loses time.
- **The UI ticks once per second, only while the app is visible**, and only the small widget that shows the counter rebuilds.
- **The ongoing notification is posted once per state change** (start, pause, resume, edit). Android's SystemUI renders the running clock natively (`usesChronometer` + `when`).
- **Reminders use inexact scheduled notifications** (no exact-alarm permission).
- **The home-screen widget uses a native `<Chronometer>`** in RemoteViews and is updated only on state changes.

## 1. What's wrong today (evidence)

- `lib/providers/timer_provider.dart:55-64`: `Timer.periodic(1s)` calls `notifyListeners()` every second for as long as the process lives, including in the background. There is no lifecycle handling anywhere in `lib/` (no `WidgetsBindingObserver` or `AppLifecycleListener`).
- `lib/providers/timer_provider.dart:66-77`: re-posts the notification every 15 s through a platform channel (the comment says 30 s), in the background too. Each post makes SystemUI re-inflate the notification and wakes the CPU. The chronometer already ticks natively, so only the "Verdient: x €" text changes.
- `lib/screens/home_screen.dart:20`: `context.watch<TimerProvider>()` sits at the top of `HomeScreen`, so the whole screen rebuilds every second: two HighlightCards, AnimatedMoneyDisplay, AnimatedContainer and the buttons. `timer.setHourlyWage(...)` is even called inside `build()` (line 31).
- `lib/widgets/animated_digit.dart:70-95`: every digit has its own `AnimatedSwitcher` with `ClipRect` + `Opacity` (an `Opacity` animation means `saveLayer`) inside a baseline `Row`, so there is a 300 ms animation every second on several digits.
- On Android 14+ devices with the cached-apps freezer (mostly Pixel), the process is frozen about 10 s after it becomes cached, which hides the problem. On OEM builds without the freezer, the Dart timer keeps running indefinitely, which explains the reported lag and drain.
- `lib/services/notification_service.dart:24-28` + `lib/main.dart:27-29`: the permission prompt and all loading are awaited before `runApp`, which slows startup.

## 2. Crash-safe session model

```text
running shift row: id, jobId, startUtcMs, rateCentsPerHour (snapshot), pausedAtUtcMs?, pausedTotalMs
worked(now) = (now - start) - pausedTotal - (pausedAt != null ? now - pausedAt : 0)
earnedCents(now) = rateCentsPerHour * worked.inMilliseconds / 3_600_000   // double for display
on stop: round half-up to int cents once and store it on the shift
```

- Use `package:clock` (`clock.now()`) everywhere so tests can freeze and advance time.
- Store UTC epoch values, and render in local time. Overnight and DST shifts then compute correctly, because durations come from UTC differences.
- Retroactive edits ("started 20 min ago", "stopped at 23:15") are just timestamp updates.

## 3. Ticking the UI only while visible

```dart
/// Rebuilds its child once per wall-clock second while the app is visible.
class LiveTicker extends StatefulWidget {
  const LiveTicker({super.key, required this.builder});
  final Widget Function(BuildContext, DateTime now) builder;
  @override
  State<LiveTicker> createState() => _LiveTickerState();
}

class _LiveTickerState extends State<LiveTicker> {
  Timer? _timer;
  late final AppLifecycleListener _lifecycle;
  DateTime _now = clock.now();

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onShow: _start, onHide: _stop);
    _start();
  }

  void _start() { _stop(); _tick(); }
  void _stop() { _timer?.cancel(); _timer = null; }

  void _tick() {
    if (!mounted) return;
    setState(() => _now = clock.now());
    // align to the next full second so the display doesn't drift
    _timer = Timer(Duration(milliseconds: 1000 - _now.millisecond), _tick);
  }

  @override
  void dispose() { _stop(); _lifecycle.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) =>
      RepaintBoundary(child: widget.builder(context, _now));
}
```

Rules:
- Only the counter leaf lives inside `LiveTicker`. The rest of the screen listens to session state, which changes only on start/pause/stop. With Riverpod use `ref.watch(activeShiftProvider.select(...))`.
- With Riverpod 3 you can also make a `secondTickProvider` (StreamProvider.autoDispose) that uses the same timer/lifecycle logic. Riverpod 3 pauses providers whose listeners sit in invisible widgets (TickerMode), which covers offstage tabs automatically.
- Prefer a 1 Hz `Timer` over a vsync `Ticker`. A Ticker fires at display refresh rate (60–120 Hz), keeps the frame pipeline busy and stops LTPO panels from dropping to low refresh rates.
- Optionally schedule the money display by its own cadence: the next cent arrives after `3_600_000 / rateCents` ms (2.4 s at €15/h).
- Use `TextStyle(fontFeatures: [FontFeature.tabularFigures()])` so digits don't jitter.
- Animate at most the changed digits with `FadeTransition`/`SlideTransition` (no `Opacity` widget, no per-digit `ClipRect`). Respect `MediaQuery.disableAnimationsOf(context)`.
- Format money with `NumberFormat.currency(locale: ..., symbol: '€')`. `lib/widgets/animated_money_display.dart:31-41` hardcodes ',' and '€'.

## 4. Ongoing notification: post once, let SystemUI tick

```dart
// flutter_local_notifications 22.x (named parameters since v20)
Future<void> showRunning(Shift s, Duration workedSoFar, AppLocalizations l10n) =>
  plugin.show(
    id: 1,
    title: l10n.notifWorkingAt(s.jobName),
    body: l10n.notifRateSince(s.rateFormatted, s.startLocalHHmm), // static text, never refreshed per second
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        'active_shift', l10n.channelActiveShift,          // localized; today hardcoded German
        channelDescription: l10n.channelActiveShiftDesc,
        importance: Importance.low, priority: Priority.low,
        ongoing: true, autoCancel: false, onlyAlertOnce: true, silent: true,
        category: AndroidNotificationCategory.stopwatch,
        showWhen: true, usesChronometer: true,
        when: clock.now().millisecondsSinceEpoch - workedSoFar.inMilliseconds, // excludes pauses
        actions: [
          AndroidNotificationAction('pause', l10n.pause),                             // background
          AndroidNotificationAction('stop', l10n.stop, showsUserInterface: true), // opens end-of-shift sheet
        ],
      ),
    ),
    payload: 'shift:${s.id}',
  );
```

- **While paused:** re-post with `usesChronometer: false, showWhen: false`, body "Pause seit 14:32" and a Resume action.
- **No periodic updates.** If you want money in the notification, write a snapshot line ("≈ 23,40 € · Stand 18:34") once in `AppLifecycleListener.onHide`. Never on a timer.
- **Android 14+ makes ongoing, non-FGS notifications swipeable** (except on the lock screen). Accept that. Re-post on the next app resume. Optionally set `dismissIsolate: NotificationDismissedIsolate.main` (f_l_n ≥22.2) to know about it, and don't nag.
- **Changing importance later requires a new channel ID**, because channel settings are immutable once created.
- **Android 16 Live Update (optional, later):** add `POST_PROMOTED_NOTIFICATIONS` and `setRequestPromotedOngoing(true)`. The system then shows a status-bar chip with the chronometer. f_l_n doesn't support it yet (PR #2810 open as of 29 Sep 2026; needs androidx.core 1.19 / compileSdk 37 / AGP 9.1). Until then it would need your own MethodChannel with `NotificationCompat`. A user-started shift timer fits the "ongoing, user-initiated, time-sensitive" criteria, but OEMs may add rules.

## 5. Foreground service: not needed, don't add one

- An FGS only exists to keep a process alive so it can run code. Chronos needs no code running: SystemUI draws the clock, and the database holds the timestamps.
- **Since Android 14 a type is mandatory, and none fits:**
  - `shortService` stops after about 3 min (`onTimeout`).
  - `dataSync` means transfers, and on Android 15 it's capped at 6 h per 24 h.
  - `specialUse` needs `FOREGROUND_SERVICE_SPECIAL_USE`, a `PROPERTY_SPECIAL_USE_FGS_SUBTYPE` property and a Play Console declaration with justification or video. Rejections are common.
  - `systemExempted` isn't eligible.
- **Other costs:** most types can't start from `BOOT_COMPLETED` (Android 15+), and an FGS keeps the process unfrozen, which is exactly the drain users complain about.
- `flutter_foreground_task` (11.0.3) is built around a repeating callback (its README example runs every 5 s). Avoid it.
- Check the merged manifest (`build/app/intermediates/merged_manifest/...`) for any stray `FOREGROUND_SERVICE*` permission. Play rejects apps that declare FGS permissions without a declaration.

## 6. Reminders ("still working?", shift start, payout day)

```dart
await plugin.zonedSchedule(
  id: 100,
  scheduledDate: tz.TZDateTime.from(plannedEnd.add(const Duration(minutes: 30)), tz.local),
  notificationDetails: reminderDetails,
  androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // no exact-alarm permission
  title: l10n.stillWorkingTitle, body: l10n.stillWorkingBody,
);
```

- **Setup:** initialize `timezone` + `flutter_timezone`. Add `ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver` and `RECEIVE_BOOT_COMPLETED` to the manifest (per the f_l_n README).
- **No exact-alarm permissions.** Don't declare `USE_EXACT_ALARM`: Play restricts it to alarm/calendar apps. Don't declare `SCHEDULE_EXACT_ALARM` either: it's denied by default on 14+ and would need a settings detour.
- **Doze may delay an inexact alarm by a few minutes**, which is fine for these reminders.
- Cancel or reschedule on stop, edit or delete. Use a deterministic ID per shift (e.g. `shiftId * 10 + kind`).

## 7. Notification actions in the background

```dart
@pragma('vm:entry-point')
Future<void> onNotificationActionBackground(NotificationResponse r) async {
  DartPluginRegistrant.ensureInitialized(); // needed when other plugins are used in this isolate
  final db = AppDatabase(driftDatabase(
    name: 'chronos',
    native: const DriftNativeOptions(shareAcrossIsolates: true), // reuse the main isolate's DB server if alive
  ));
  try {
    final repo = ShiftRepository(db);
    if (r.actionId == 'pause') await repo.pauseActive(clock.now());
    if (r.actionId == 'resume') await repo.resumeActive(clock.now());
    await NotificationService.instance.syncFromDb(repo);   // re-post once
    await WidgetService.refresh(repo);                     // HomeWidget.saveWidgetData + updateWidget
  } finally {
    await db.close();
  }
}
```

- Register it with `initialize(settings: ..., onDidReceiveBackgroundNotificationResponse: onNotificationActionBackground)`.
- Keep the handler tiny. The "Stop" action uses `showsUserInterface: true`, so it opens the app (deep link) to a sheet for tips, break and confirmation, instead of stopping blind.

## 8. Home-screen widget

- `home_widget` 0.10.0 with a native Kotlin `HomeWidgetProvider` and an XML layout containing `<Chronometer android:id="@+id/clock"/>`.
- In `onUpdate`, compute `base = SystemClock.elapsedRealtime() - workedMs` from the saved epoch values, then call `views.setChronometer(R.id.clock, base, null, isRunning)`. Recompute on every update, because `elapsedRealtime` restarts after a reboot, and `onUpdate` runs after boot.
- Set `updatePeriodMillis="0"`. Call `HomeWidget.saveWidgetData(...)` + `HomeWidget.updateWidget(...)` only on start/pause/resume/stop/edit.
- The toggle button uses `HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("chronos://toggle"))` plus `HomeWidget.registerInteractivityCallback(...)` (runs via WorkManager since 0.8.1). The alternative is to open the app with a deep link.
- Don't use `HomeWidget.scheduleWidgetUpdates` (alarm-based). Offer `HomeWidget.requestPinWidget()` in settings.

## 9. Lifecycle and reconciliation

- **App root:** one `AppLifecycleListener`.
  - `onResume` → reconcile. If the database has a running shift and `getActiveNotifications()` doesn't contain ID 1, re-post it and refresh the widget. Recompute derived state.
  - `onHide` → tickers stop themselves; optionally write the notification money snapshot.
- **Startup:** call `runApp` immediately (open the DB lazily and show a skeleton for a few ms). Never await permission prompts before the first frame.
- **Reboot, force-stop or app update remove shown notifications.** Re-post on next launch. Optionally add a small native `BOOT_COMPLETED` receiver that re-posts the plain chronometer notification from SharedPreferences. A plain notification is allowed; only FGS starts from boot are restricted.
- **Doze and App Standby:** nothing runs, so nothing to fix. Don't ask for battery-optimization exemptions (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` is policy-restricted and unnecessary).

## 10. How to verify

- Battery: `adb shell dumpsys batterystats --reset`, run a 1 h shift with the screen off, then `adb shell dumpsys batterystats com.paulhuebner.chronos`. Expect near-zero CPU and wakeups.
- `adb shell dumpsys notification --noredact`: shows one post per state change.
- `adb shell dumpsys alarm | grep chronos`: only reminder alarms.
- Freezer: enable Developer options → "Suspend execution for cached apps". Doze: `adb shell dumpsys deviceidle force-idle`.
- Flutter DevTools with Performance overlay and "Track widget rebuilds": only the `LiveTicker` subtree rebuilds each second.
- Unit tests with `withClock(Clock.fixed(...))` and `fakeAsync` for worked-time, pause and DST cases (DE/AT DST switches on the last Sunday of March and October).

## Architecture recommendation

## 0. Toolchain baseline (as of 30 Sep 2026)

- **Flutter 3.47.5 stable** (18 Sep 2026, Dart 3.13.4). Flutter 3.50 is expected in November 2026.
- **Flutter Gradle defaults** (`FlutterExtension.kt` on stable): compileSdk 36, targetSdk 36, minSdk 24, NDK 28.2.13676358.

`android/app/build.gradle` fixes:
- Java 17 instead of 1.8 (lines 40-45: `JavaVersion.VERSION_1_8`, `jvmTarget '1.8'`). flutter_local_notifications 22 requires Java 17 plus desugar_jdk_libs 2.1.4, which is already present (line 85).
- Delete the hardcoded `ndkVersion "27.0.12077973"` (line 36) or use `flutter.ndkVersion`. NDK r28 aligns native libraries to 16 KB by default, and drift's sqlite3 build hook compiles C code with it.
- AGP: `settings.gradle` pins AGP 8.7.0, but flutter_local_notifications 21+ needs ≥8.11.1. Kotlin plugin must be ≥2.0 (Flutter 3.44 minimum); 2.1.0 is already fine.
  - AGP 9 is supported from Flutter 3.44 with `android.builtInKotlin=false`. Built-in Kotlin needs Flutter 3.47 and every plugin migrated, so check the plugins first (home_widget ≥0.9.2 supports AGP 9).
  - Optionally convert to Kotlin DSL (`build.gradle.kts`).
- Drop `multiDexEnabled` (pointless at minSdk 24) and `flutter.experimental.impeller=true` (Impeller is the default on Android).

`pubspec.yaml` fixes:
- `intl: ^0.19.0` conflicts with the intl version pinned by `flutter_localizations` on current SDKs. Use `intl: any`, or match the SDK pin (0.20.x).
- `flutter_local_notifications ^18` → 22.3.1: the API moved to named parameters in v20.
- SDK constraint `^3.13.0`.

## 1. State management: Riverpod 3 (flutter_riverpod 3.4.3)

Why Riverpod over Provider or Bloc for a hobby developer:
- **Same author and mental model as Provider**, but it's the actively developed successor. provider 6.1.5+1 was last published Aug 2025 and is only maintained.
- **No `BuildContext` needed.** Notification action handlers, the widget callback and startup code can read and write state through a `ProviderContainer`. Chronos has three entry points besides the UI (notification, home widget, tile), so this matters.
- **Pairs naturally with drift streams:** `StreamProvider` over `watch()` queries gives automatic UI updates for the log and statistics without manual `notifyListeners`.
- **Riverpod 3 specifics:**
  - Providers pause when their listeners sit in invisible widgets (TickerMode), which suits the live counter.
  - Automatic retry and `Ref.mounted`.
  - All providers use `==` to filter updates.
  - Legacy `StateNotifierProvider`/`StateProvider` moved to `legacy.dart`, so don't use them.
- **Testing:** `ProviderContainer(overrides: [clockProvider.overrideWithValue(...), databaseProvider.overrideWithValue(inMemoryDb)])`.
- **Bloc** (flutter_bloc 9.1.1) works but has more boilerplate for a 5-screen solo app.
- **Codegen:** start with hand-written `Notifier`/`AsyncNotifier`/`StreamProvider`. Since build_runner is needed for drift anyway, you can adopt `riverpod_generator` 4.0.9 later. Add `riverpod_lint` 3.1.9.
- **DI:** Riverpod is the DI container, so no get_it is needed.

Core providers:
- `clockProvider` → `Clock`
- `databaseProvider` → `AppDatabase` (keepAlive)
- `shiftRepositoryProvider`, `jobRepositoryProvider`, `payoutRepositoryProvider`
- `activeShiftProvider` → `StreamProvider<Shift?>` over a drift `watchSingleOrNull()`
- `ActiveShiftController extends Notifier`: `start`/`pause`/`resume`/`stop`/`adjustStart`. It writes to the DB, then syncs the notification, widget and reminders.
- `shiftsInRangeProvider` (family on a `DateTimeRange`), `statsProvider(period)`, `minijobStatusProvider(month)`
- `settingsProvider` → `Notifier` over `SharedPreferencesWithCache` (locale, themeMode, country/Bundesland, onboarding done)

## 2. Persistence: drift (2.35.0, 9 Sep 2026) on SQLite

- **Relational data:** job → wage_rates, shifts → breaks, payouts, templates, surcharge rules. Statistics are SQL aggregates.
- **Reactive `watch()` streams, typed queries, lints** for SQL errors, and built-in isolate support (`DriftNativeOptions(shareAcrossIsolates: true)`).
- **First-class schema migrations:** `schemaVersion` plus `dart run drift_dev make-migrations`, which generates step-by-step migrations and migration tests.
- **Setup is now simpler:** `drift_flutter` 0.3.1 `driftDatabase(name: 'chronos')`. sqlite3 3.x bundles SQLite through Dart build hooks, and `sqlite3_flutter_libs` is EOL (0.6.0+eol), so don't add it.

Status of the alternatives (pub.dev, Sep 2026):
- **isar 3.1.0+1:** last release Apr 2023, abandoned by its author (issue isar/isar#1689). The `isar_community` fork (3.3.2, Mar 2026) has a small maintainer base.
- **hive 2.2.3:** 2022, abandoned. `hive_ce` 2.20.1 is active, but it's a key-value store with no relational queries or aggregates.
- **sqflite 2.4.4:** fine, but raw SQL, no codegen and no streams.
- **ObjectBox 5.3.2:** sync-oriented and binary.
- **Verdict:** drift. Treat Isar and Hive as legacy.

Settings stay in `SharedPreferencesWithCache` (allowList), which gives synchronous reads of theme and locale at startup. The legacy `SharedPreferences` API is announced for future deprecation. Note that the `SharedPreferencesAsync` API defaults to DataStore on Android, a different store from the legacy XML, which matters for the migration below.

Proposed schema, v1 of the new database:

```text
jobs(id, name, employer, colorArgb, icon, kind[de_minijob|de_midijob|de_regular|at_geringfuegig|at_regular|other],
     breakRule[none|de_arbzg|at_azg|custom], roundingRule, surchargeProfileId?, archived, sort)
wage_rates(id, jobId, validFrom(date), centsPerHour)
shifts(id, uuid, jobId, status[planned|running|done], startUtc, endUtc?, tzOffsetMin,
       rateCentsPerHour(snapshot), manualBreakMin, pausedAtUtc?, pausedTotalMs,
       tipsCashCents, tipsCardCents, tipOutCents, note, payoutId?, legacyId?, source[timer|manual|template|import|legacy],
       createdAt, updatedAt)
breaks(id, shiftId, startUtc, endUtc?)
payouts(id, jobId, periodStart, periodEnd, expectedCents, receivedCents?, paidOn?, note)
templates(id, jobId, name, startMinuteOfDay, durationMin, breakMin, colorArgb?)
surcharge_rules(id, profileId, kind[night|sunday|holiday|custom], percent, fromMinute, toMinute, weekdayMask, holidaySet?)
meta(key PRIMARY KEY, value)
```

Rules:
- Money is `int` cents and never `double` in storage.
- Time is UTC epoch. drift's default DateTime storage is a unix timestamp; enable `store_date_time_values_as_text: false`, the default.
- Exactly one running shift, enforced in the repository or with a partial unique index `WHERE status='running'`.
- Earnings are computed by the domain layer and cached on the shift when it's closed.

## 3. Routing: go_router 18.0.2

- `StatefulShellRoute.indexedStack` for the tabs (Heute, Verlauf, Statistik, Planung), which preserves tab state. Other routes: `/settings`, `/shift/:id`, `/export`, `/onboarding`.
- Deep links (`chronos://toggle`, `chronos://shift/123`) from notifications, the widget, the tile and NFC.
- go_router is officially feature-complete and in maintenance mode (bug fixes only). That's fine for an app this size.
- 18.x requires Flutter ≥3.44 and already uses `material_ui`.

## 4. UI layer and design system

- **Material 3.** `ColorScheme.fromSeed(seedColor: Color(0xFF001F3F), brightness: ...)` for both themes, plus `ThemeMode` from settings (system/light/dark). Optionally Material You via `dynamic_color` 2.1.0.
- **Decoupled Material package.** Since Flutter 3.47 the Material library also ships as `material_ui` (1.5.0) and `cupertino_ui` (1.1.1) on pub.dev. The migration is `dart fix --apply --code=migrate_design_widgets`, and the imports become `package:material_ui/material_ui.dart`. Press coverage says the bundled imports will be deprecated in the Nov 2026 stable release and removed in 2027; I couldn't confirm the exact timeline because docs.flutter.dev and flutter.dev are blocked here. For the rewrite, use whichever import your main UI packages (fl_chart, table_calendar) support. go_router 18 has already moved.
- **Adaptive layout:** breakpoints at 600 and 840 dp; `NavigationBar` for compact, `NavigationRail` plus list/detail for medium and expanded. No fixed pixel heights; scrollable bodies; test at textScaler 2.0.
- **Typography:** bundle one font (e.g. Inter or Manrope TTF) as an asset instead of fetching it at runtime. Use tabular figures for timers and money.
- **Motion:** fewer, calmer animations (`animations` 3.0.0 for container transforms). Respect reduced motion.

## 5. Project structure (feature-first)

```text
lib/
  main.dart                      // runApp(ProviderScope(child: ChronosApp()))
  app/ (router.dart, theme.dart, app.dart, lifecycle_reconciler.dart)
  core/ (clock.dart, money.dart (Cents type + formatting), time.dart, result.dart)
  data/ db/ (database.dart, tables/*.dart, daos/*.dart, legacy_migration.dart)
        repositories/*.dart
  domain/ (pay_engine.dart, break_policy.dart, surcharge_engine.dart, holidays_de_at.dart,
           minijob_rules.dart, rounding.dart)          // pure Dart, no Flutter imports
  platform/ (notification_service.dart, widget_service.dart, reminders.dart)
  features/ today/ log/ stats/ planning/ payouts/ export/ settings/ onboarding/
            each with widgets/ + controllers (Notifiers)
  l10n/ (app_de.arb, app_en.arb, optional app_de_AT.arb for 'Jänner')
```

## 6. Domain layer, 100% unit-tested

- `PayEngine.compute(shift, breaks, rules, holidays) -> PayBreakdown{workedMs, breakMs, baseCents, surchargeCents by kind, tipsCents, totalCents}`.
- `BreakPolicy`: DE §4 ArbZG, AT §11 AZG, youth presets.
- `SurchargeEngine`: splits intervals across midnight, Sunday and holidays.
- `Holidays`: computed Easter, DE per Bundesland, AT national.
- `MinijobRules`: yearly constants table for DE and AT.
- Test edge cases: exactly 6:00 h vs 6:01 h, shifts over midnight, DST (29 Mar 2026 and 25 Oct 2026; 28 Mar and 31 Oct 2027), 24 Dec from 14:00, New Year.

## 7. Testing

- **Unit:** domain and repositories. For drift use `NativeDatabase.memory()`. Generate migration tests with `drift_dev` `SchemaVerifier`.
- **Legacy migration tests:** JSON fixtures in the exact legacy format (`lib/models/work_entry.dart:48-66`, `lib/models/app_settings.dart:28-47`), including corrupt entries, an empty list and an active session.
- **Widget tests** with `ProviderScope` overrides and a fixed clock.
- **Golden tests** for Today, Log and Stats across light/dark, DE/EN, 360x800, 800x360 (landscape) and 1280x800 (tablet). This catches the landscape overflow regression.
- **Integration tests:** `patrol` 4.10.0 for the notification-permission dialog and notification-tap flows on an emulator.
- **CI (GitHub Actions):** `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test`, `flutter build appbundle`.

## 8. Lints

- Either `very_good_analysis` 11.0.0 (strict and opinionated, good for learning) or `flutter_lints` 6.0.0 plus a curated set of extras: `unawaited_futures`, `discarded_futures`, `avoid_dynamic_calls`, `prefer_const_constructors`, `always_use_package_imports`, `require_trailing_commas`, `use_build_context_synchronously`.
- For a hobby dev I'd pick `flutter_lints` + extras, plus `riverpod_lint`.
- Treat warnings as errors in CI.

## 9. Migrating from Provider + shared_preferences without losing testers' data

Legacy storage facts:
- The data is stored through the legacy `SharedPreferences` API, i.e. the Android file `FlutterSharedPreferences.xml` with a `flutter.` key prefix.
- Keys (`lib/services/storage_service.dart:7-9`):
  - `work_entries`: JSON list of `{id, date, startTime, endTime, isPaid}`, ISO strings without an offset, meaning local time.
  - `app_settings`: `{language: german|english, theme: light|dark, hourlyWage: double}`.
  - `active_session`: ISO local string.
- Read them with the legacy API, or with `SharedPreferencesAsync` configured for the SharedPreferences backend. The plain `SharedPreferencesAsync` defaults to DataStore and would see nothing.

Steps, run once at startup before the UI reads data:
1. If `meta['legacy_prefs_migrated'] == '1'`, return (the migration is idempotent).
2. Read the three legacy keys. Write a verbatim safety copy to `getApplicationDocumentsDirectory()/legacy_backup_v1.json`.
3. In one drift transaction:
   - Create the default job, named "Mein Job" / localized, with a `wage_rates` row `validFrom=2000-01-01` and `cents = round(hourlyWage*100)`, falling back to 1500.
   - For each entry, inside its own try/catch:
     - `start = DateTime.parse(e['startTime'])` (local) → `startUtc = start.toUtc()`, `tzOffsetMin = start.timeZoneOffset.inMinutes`; same for end.
     - `rateCentsPerHour` = the default wage (legacy entries never stored a wage).
     - `status=done`, `legacyId=e['id']`, `source=legacy`, `isPaid → payoutId=null` plus a boolean `legacyPaid` column, or one synthetic 'Altbestand bezahlt' payout.
     - Collect skipped entries so they can be reported.
   - If `active_session` exists, insert a `running` shift with that start.
   - Settings: `language` german→'de' / english→'en'; `theme` → `ThemeMode` (keep dark as the default if the key is missing). Write them to `SharedPreferencesWithCache`.
   - Set `meta['legacy_prefs_migrated']='1'` and `meta['legacy_count']=n`.
4. Keep the legacy keys untouched for at least 2 releases so v2.0 can be re-migrated if something goes wrong. Remove them in v2.2 or later.
5. Show a one-time card: "N Einträge übernommen (Stundenlohn X €/h angenommen – bei Bedarf anpassen)". Offer "apply a different historical rate to all migrated entries".
6. Release hygiene:
   - Keep `applicationId com.paulhuebner.chronos` and the upload key (`key.properties`). Bump `versionCode`.
   - Add Android Auto Backup `dataExtractionRules` (database + sharedpref domains) so the new data survives a phone switch.
   - Test by installing v1.0.0 from the internal track, creating data, then upgrading to the v2 build (`adb install -r`).

## 10. Suggested phasing

- **Phase 0 (hotfix v1.0.x):** toolchain (Java 17, AGP, Flutter 3.47, targetSdk 36), lifecycle-aware ticker, notification posted once, fix the l10n/landscape/theme bugs.
- **Phase 1 (v2.0):** drift + Riverpod + legacy migration, multiple jobs, wage history, breaks, payouts, new adaptive UI, export and backup.
- **Phase 2:** statistics, tips, Minijob monitor, reminders, planning and templates, home widget.
- **Phase 3:** surcharge engine, tile, NFC, Live Updates, goals.

## Recommended packages

| Package | Version | Purpose | Notes |
|---|---|---|---|
| flutter_riverpod | 3.4.3 (2026-09-03) | State management and dependency injection | Riverpod 3: pausing of invisible listeners (TickerMode), auto-retry, Ref.mounted; StateNotifier/StateProvider moved to legacy.dart. Optional: riverpod_generator 4.0.9 + riverpod_annotation 4.0.7; riverpod_lint 3.1.9. |
| drift | 2.35.0 (2026-09-09) | Typed, reactive SQLite database | Dev dependencies drift_dev 2.35.0 + build_runner 2.16.1. Use make-migrations for step-by-step migrations and tests. Depends on sqlite3 ^3.4 (currently 3.6.0), which bundles SQLite via Dart build hooks. |
| drift_flutter | 0.3.1 (2026-07-11) | One-line Flutter setup for drift: driftDatabase(name:) | DriftNativeOptions(shareAcrossIsolates: true) for notification/widget background isolates. Do NOT add sqlite3_flutter_libs (0.6.0+eol, 'not used anymore'). |
| shared_preferences | 2.5.5 (2026-03-25) | Small settings (locale, theme, onboarding flags) plus reading legacy v1 data | Use SharedPreferencesWithCache (allowList) for sync reads. SharedPreferencesAsync defaults to DataStore on Android, not the legacy XML, so read v1 data via the legacy API or the SharedPreferences backend option. The legacy API is slated for deprecation. |
| go_router | 18.0.2 (2026-09-28) | Routing, tab shell, deep links | Requires Flutter ≥3.44 and has migrated to material_ui. Maintenance mode (feature-complete). StatefulShellRoute.indexedStack for the bottom tabs. |
| flutter_local_notifications | 22.3.1 (2026-09-13) | Ongoing chronometer notification, actions, inexact reminders | Requires Flutter ≥3.38.1, Android minSdk 24, compileSdk 36, AGP ≥8.11.1, Java 17 + desugar_jdk_libs 2.1.4. Named parameters since v20. openAppNotificationSettings (22.3), dismissal callbacks (22.2). Live Updates not yet supported (PR #2810 open). Needs timezone 0.11.1 + flutter_timezone 5.1.0 for zonedSchedule. |
| home_widget | 0.10.0 (2026-09-17) | Android home-screen widget with a start/stop toggle | Requires Flutter ≥3.38.1. The widget is written natively (Kotlin + XML RemoteViews, <Chronometer>). registerInteractivityCallback runs via WorkManager. requestPinWidget. Avoid scheduleWidgetUpdates (alarms). 0.10.0 has breaking changes (custom fonts, previews). |
| fl_chart | 1.2.0 (2026-03-13) | Bar and line charts for statistics | Pure Dart, themeable. Check whether it has migrated to material_ui before switching imports. |
| table_calendar | 3.2.1 (2026-08-09) | Month calendar for planned and actual shifts | Uses intl locales (de, de_AT). A custom grid is an option if styling gets too limited. |
| intl | 0.20.3 (2026-06-25) | Number, currency and date formatting; gen-l10n | Must match the version pinned by flutter_localizations in your SDK, so declare 'intl: any'. The current ^0.19.0 will fail to resolve on new SDKs. |
| share_plus | 13.3.0 (2026-07-23) | Share PDF, CSV and backup files | User-initiated sharing covers the Data safety exemption for data sent via the share sheet. |
| file_picker | 13.1.0 (2026-09-15) | Save and open export and backup files via the Storage Access Framework | No storage permission needed. saveFile for exports, pickFiles for restore. |
| pdf | 3.13.1 (2026-09-19) | Generate a monthly Stundenzettel PDF | Embed the bundled TTF for umlauts and €. |
| printing | 5.15.1 (2026-09-19) | Preview, print and share the PDF | PdfPreview widget for a nice export screen. |
| csv | 8.0.0 (2026-03-19) | CSV export | Use ';' delimiter, decimal comma and a UTF-8 BOM for German Excel. The 8.0 major may have API changes from 6.x examples. |
| dynamic_color | 2.1.0 (2026-08-20) | Optional Material You colors | Keep the brand seed (#001F3F) as the default. Offer dynamic color as a toggle. |
| google_fonts | 9.0.0 (2026-09-28) | Typography (optional) | Prefer bundling the TTF as an asset, or set GoogleFonts.config.allowRuntimeFetching = false. Runtime fetching contacts Google servers (a GDPR and privacy-policy issue) and fails offline. |
| package_info_plus | 10.2.1 (2026-07-15) | Version in About screen, backups and feedback mails | — |
| clock | 1.1.3 (2026-08-28) | Injectable time source | clock.now() everywhere; withClock and fake_async 1.3.3 in tests. |
| uuid | 4.6.0 (2026-07-15) | Stable IDs for export/import merge | Already used. Keep a uuid column next to drift integer primary keys. |
| animations | 3.0.0 (2026-08-19) | Official Material motion (container transform, shared axis) | Replaces the hand-rolled animated_card/animated_button widgets. |
| flutter_slidable | 4.0.3 (2025-09-27) | Swipe actions in the work log | Or the built-in Dismissible plus an undo SnackBar. |
| add_2_calendar | 3.1.1 (2026-06-15) | Add a planned shift to the system calendar | Intent-based, no calendar permission. device_calendar 4.3.3 is stale (2024); device_calendar_plus 0.9.0 only if full sync is ever needed. |
| in_app_review | 2.0.12 (2026-05-15) | Ask for a Play rating at a good moment | Quota-limited by Play; don't tie it to a button. |
| local_auth | 3.0.2 (2026-07-09) | Optional app lock | could-have |
| material_ui | 1.5.0 (2026-09-28) | Decoupled Material library (Flutter ≥3.47) | Migrate with 'dart fix --apply --code=migrate_design_widgets' once your main UI packages support it; MaterialUiCompatibilityBridge exists for mixed trees. |
| flutter_lints / very_good_analysis | 6.0.0 (2025-05-27) / 11.0.0 (2026-09-03) | Static analysis | Project is on flutter_lints ^4.0.0. Upgrade to 6 plus extra rules, or adopt very_good_analysis for stricter rules. |
| patrol | 4.10.0 (2026-09-15) | Integration tests including native dialogs and notifications | Optional; mocktail 1.0.5 for unit-test fakes. |
| flutter_launcher_icons / flutter_native_splash | 0.14.4 / 2.4.8 | Adaptive and themed (monochrome) icon, Android 12+ splash | Add a monochrome layer for Android 13+ themed icons. |
| workmanager (NOT recommended) | 0.10.10 (2026-09-07) | Deferred background work | Not needed: no periodic background work in this design. Reminders use inexact notifications, and backup uses Android Auto Backup plus manual export. |
| flutter_foreground_task (NOT recommended) | 11.0.3 (2026-09-07) | Foreground service | Would add FGS type, permission and Play declaration overhead and keep the process alive, the opposite of the battery goal. |
| isar / hive (do NOT use) | isar 3.1.0+1 (2023-04-25); hive 2.2.3 (2022-06-30) | — | Abandoned upstream. Community forks isar_community 3.3.2 (2026-03) and hive_ce 2.20.1 (2026-09) exist but add no benefit over drift for relational data. |
| permission_handler (only if needed) | 13.0.2 (2026-09-04) | Runtime permissions | Not needed for notifications: flutter_local_notifications has requestNotificationsPermission and areNotificationsEnabled. Only add it for calendar or location features. |
| native_geofence (only if geofencing is ever built) | 1.3.1 (2026-06-10) | OS geofencing without a foreground service | geofence_service is discontinued. Needs background location, which is heavy on Play policy. Not recommended now. |

## Google Play requirements

## 1. Target API level
- Since **31 Aug 2026**, new apps and app updates must target **Android 16 (API 36)**. Extensions to **1 Nov 2026** can be requested in Play Console.
- Existing apps must target ≥ API 35 to stay available to new users on newer Android versions.
- API 37 is expected to be required from August 2027.
- Chronos uses `targetSdkVersion flutter.targetSdkVersion` (`android/app/build.gradle:65`). Flutter 3.47 stable defaults to target and compile SDK 36 and min SDK 24, so upgrading Flutter meets the requirement. That also turns on the Android 16 behaviors below.

## 2. Closed testing for new personal developer accounts
- Personal accounts created after **13 Nov 2023** must run a **closed test with ≥12 testers opted in continuously for the preceding 14 days** before applying for production access. The limit was 20 testers until Dec 2024.
- Organization accounts and older personal accounts are exempt.
- **Internal testing (the 26 May 2026 track) does not count.** Start a closed track as early as possible with the v2 beta. Testers must stay opted in (people who leave reset the count). Afterwards you answer the production-access questionnaire (how testing went, what you changed).

## 3. Android developer verification
- Play apps were registered automatically (March 2026).
- From **30 Sep 2026**, apps installed on certified devices in BR, ID, SG and TH must come from verified developers, with global rollout in 2027. This only matters if you share APKs outside Play.
- A free "limited distribution" account (up to 20 devices) exists for hobbyists.

## 4. Data safety, privacy policy and App content declarations
- **Data safety:** every app, including testing tracks, must complete the form even if it collects nothing.
  - Chronos stores data locally only, so it can declare "no data collected/shared".
  - Exports through the system share sheet are user-initiated.
  - Adding crash reporting (Crashlytics, Sentry), Google Drive backup or analytics changes the answers.
  - July 2026 policy update: more guidance on location disclosures, and User Data rules apply to third-party AI integrations.
- **Privacy policy:** mandatory. Host the existing `privacy.html` at a stable public URL (e.g. GitHub Pages), link it in the store listing and in app settings, and update it when features change. Provide German and English.
- **Other declarations:**
  - Content rating: complete the IARC questionnaire (unrated apps are not allowed, clarified in July 2026).
  - Target audience: not children.
  - Ads: none.
  - Answer the remaining App content forms (e.g. financial features, health) truthfully, i.e. "no". I couldn't verify the exact set of mandatory forms here.

## 5. Notification permission (Android 13+)
- `POST_NOTIFICATIONS` is a runtime permission. Request it **in context** (first Start tap, or at the onboarding step explaining the live notification), not at launch. Today it's requested in `NotificationService.init` before `runApp` (`lib/services/notification_service.dart:24-28`).
- Handle denial: the app still works; show an in-app hint and `openAppNotificationSettings()`.
- On Android 14+, users can swipe away ongoing non-FGS notifications.

## 6. Foreground services
- Apps targeting 34+ must declare a service type and the matching `FOREGROUND_SERVICE_<TYPE>` permission.
- **Play Console also requires an FGS declaration** (description, user impact, video). `specialUse` additionally needs a `PROPERTY_SPECIAL_USE_FGS_SUBTYPE` property and is reviewed; `shortService` is limited to about 3 minutes; `dataSync` is capped at 6 h per 24 h on Android 15.
- Play rejects updates that declare FGS permissions without a matching use.
- **Recommendation: no foreground service.** The chronometer notification plus timestamps need none. Check the merged manifest to make sure no plugin adds `FOREGROUND_SERVICE*`.

## 7. Exact alarms
- `USE_EXACT_ALARM` is a Play-restricted permission for alarm-clock and calendar apps.
- `SCHEDULE_EXACT_ALARM` is denied by default for new installs on Android 14+.
- Use `AndroidScheduleMode.inexactAllowWhileIdle` for reminders and declare neither permission.
- The same applies to `USE_FULL_SCREEN_INTENT` (only calling and alarm apps get it by default).

## 8. 16 KB memory page size
- Mandatory since **1 Nov 2025** for new apps and updates targeting Android 15+. The optional extension ended **31 May 2026**.
- Flutter ≥3.35 with NDK r28 produces 16 KB-aligned binaries. Remove the hardcoded `ndkVersion "27.0.12077973"` (`android/app/build.gradle:36`) so plugins that build native code (drift's sqlite3 hook) use the Flutter default NDK 28.2.
- Verify in Play Console → App bundle explorer (shows 16 KB compatibility), or with `zipalign -c -P 16 -v 4 app.apk`, and test on an Android 15/16 16 KB emulator image.

## 9. Edge-to-edge (Android 15+ / 16)
- Targeting 35 enforces edge-to-edge on Android 15. Targeting 36 removes the `windowOptOutEdgeToEdgeEnforcement` opt-out.
- Flutter draws edge-to-edge by default since 3.27. Use `SafeArea`/`MediaQuery.paddingOf`, let `NavigationBar` handle bottom insets, and use transparent system bars with correct icon brightness per theme. This matters for the dark/light switching bug.
- Play Console may still warn "Edge-to-edge may not display for all users" or flag deprecated status/navigation-bar color APIs coming from the Flutter engine (flutter/flutter#192921, open, P2). That's a warning only, not a blocker.

## 10. Predictive back (Android 16)
- When targeting 36, predictive back animations are on by default, `onBackPressed` isn't called and `KEYCODE_BACK` isn't dispatched.
- In Flutter:
  - Add `android:enableOnBackInvokedCallback="true"` to `<application>`. The current manifest lacks it.
  - Use `PopScope` (not the deprecated `WillPopScope`) for "discard changes?" on edit screens, and decide in advance whether a pop is allowed.
  - The default Android page transition is now `PredictiveBackPageTransitionsBuilder`.

## 11. Large screens, tablets and orientation
- On displays with smallest width ≥600 dp, Android 16 **ignores** `screenOrientation`, `resizableActivity=false` and min/max aspect ratio for apps targeting 36. There's a temporary per-activity opt-out, `android.window.PROPERTY_COMPAT_ALLOW_RESTRICTED_RESIZABILITY`, which stops working when targeting API 37 (required Aug 2027).
- So locking portrait is **not** a fix for the landscape "BOTTOM OVERFLOWED BY 284 PIXELS" bug: the layout has to adapt.
- Follow the Adaptive app quality guidelines:
  - **Tier 3 "Adaptive ready":** full screen with no letterboxing, critical flows usable, basic keyboard and mouse.
  - **Tier 2 "Adaptive optimized":** layouts for all sizes.
- Test on a foldable (841x701 dp), 8-inch and 10.5-inch tablets, phone landscape, split-screen and font scale 200%.
- Upload 7-inch and 10-inch tablet screenshots; large-screen quality influences visibility.

## 12. Other release hygiene
- Keep `applicationId com.paulhuebner.chronos` and the upload key. Use Play App Signing, publish an AAB and increment `versionCode`.
- R8 is enabled (`minifyEnabled true`, `shrinkResources true`), so test the release build: notification actions, drift and the widget receivers must survive shrinking.
- Store listing in German and English.
- Themed (monochrome) launcher icon for Android 13+.
- Include `dataExtractionRules` for Auto Backup.
- Toolchain: Flutter 3.44+ supports AGP 9 (with `android.builtInKotlin=false`); built-in Kotlin needs 3.47 and migrated plugins.

## Domain notes (DE/AT)

These notes are for a personal tracker. They are not legal or tax advice, and Chronos must say so (e.g. "Schätzung – maßgeblich ist deine Lohnabrechnung / dein Vertrag / KV"). Figures are for 2026 unless noted. Each item names its source; "(verify)" marks points I couldn't confirm from a primary source during this research.

## Germany (DE)

| Topic | Rule (2026) | Source |
|---|---|---|
| Statutory minimum wage | **€13.90/h** from 1 Jan 2026; **€14.60/h** from 1 Jan 2027. Tips don't count toward the minimum wage. Exceptions include under-18s without completed vocational training (§22 MiLoG). | Bundesregierung; MiLoG |
| Minijob limit | **€603/month** (dynamic: min. wage × 130 / 3, rounded up); annual **€7,236**. Occasional, unforeseeable overruns allowed in max **2 calendar months within 12**, up to double the limit (**€1,206**). 2027: **€633**. | Minijob-Zentrale; Haufe; TK |
| Midijob (Übergangsbereich) | €603.01 – €2,000/month, with reduced employee social-insurance contributions (formula-based). | TK; Lexware |
| Minijob pension contribution | Commercial Minijobs are subject to pension insurance by default. The employee pays **3.6%** (18.6% total rate minus the employer's 15% flat rate) unless exempted on request. Since **1 Jul 2026**, a previous exemption can be revoked once. Status applies uniformly to all parallel Minijobs. | Minijob-Zentrale; DRV |
| Multiple jobs | Several Minijobs are **added together** against the €603 limit. Alongside a main job, only the first Minijob stays separate; further ones are added to the main job (§8 SGB IV). A regular second job is taxed in class VI. | Minijob-Zentrale (verify details) |
| Breaks (§4 ArbZG) | More than 6 h up to 9 h → **30 min**; more than 9 h → **45 min**, in blocks of at least 15 min; no more than 6 h without a break. Youths (JArbSchG §11): more than 4.5 h → 30 min, more than 6 h → 60 min. | gesetze-im-internet.de |
| Daily rest (§5 ArbZG) | 11 h. In gastronomy and hotels it can be shortened by up to 1 h (to 10 h) if compensated within a month or 4 weeks by a rest of at least 12 h. | gesetze-im-internet.de |
| Working time | 8 h/day, extendable to 10 h if averaged to 8 h over 6 months (§3). Legal night = 23:00–06:00 (§2); night workers are entitled to paid days off or an appropriate surcharge (§6(5)). Gastronomy may work Sundays and holidays (§10), with at least 15 free Sundays per year (§11). | ArbZG |
| Reform in progress | The BMAS draft (mid-2026) would move to a weekly maximum (average 48 h), mainly via collective agreements, and **mandatory electronic same-day time recording** by employers. **Not passed** as of Sep 2026. | kliemt.blog, Sage, clockin (2026) |
| Record-keeping (§17 MiLoG) | For Minijobbers and in sectors under §2a SchwarzArbG (incl. Gaststätten/Beherbergung), start, end and duration must be recorded **within 7 days** and kept **2 years**. This is the employer's duty; Chronos's PDF export matches these fields. | MiLoG §17; Grunderküche/Minijob-Zentrale |
| Tax-free surcharges (§3b EStG) | Night **20:00–06:00: 25%**; **00:00–04:00: 40%** if work started before midnight; Sunday **50%**; public holidays and **31 Dec from 14:00: 125%**; **24 Dec from 14:00, 25/26 Dec, 1 May: 150%**. Base wage capped at **€50/h** for tax. Social-security-free only up to **€25/h** base wage (verify: DRV lexicon). Surcharges can combine (e.g. night + Sunday). These are tax **limits**, not entitlements: the actual premium comes from the contract or Tarifvertrag. Tax-free SFN surcharges within the SV limit are generally not counted as wages for the Minijob limit (verify). | EStG §3b; LStH 2026; DRV |
| Tips | Voluntary customer tips are **tax- and social-security-free without a cap** (§3 Nr. 51 EStG) and **don't count toward the Minijob limit**. Tips pooled by customers into a common box stay tax-free per federal government statements. Employer-distributed or contractually owed tips may not be tax-free (sources differ: verify). | Haufe; Minijob-Zentrale magazine; NWB |
| On-call work (§12 TzBfG) | If the daily duration isn't agreed, the employer must use the employee for at least **3 consecutive hours** per call; if weekly hours aren't agreed, **20 h** apply. A candidate "short shift" hint in the app. | TzBfG |
| Public holidays | 9 nationwide (Neujahr, Karfreitag, Ostermontag, 1 May, Christi Himmelfahrt, Pfingstmontag, 3 Oct, 25 and 26 Dec) plus **state-specific** ones (e.g. Heilige Drei Könige, Fronleichnam, Reformationstag, Allerheiligen, Buß- und Bettag SN, Frauentag BE/MV, Weltkindertag TH, Mariä Himmelfahrt SL/parts of BY). The app needs a **Bundesland** setting. | general |
| Gross vs net | Minijob: net ≈ gross − 3.6% (if subject to pension insurance); the employer pays the flat-rate taxes. Midijob and regular jobs: proper net needs the BMF wage-tax program plus health-insurance extra contributions and church tax. **Don't implement**; use an estimate percentage or link to official calculators. | — |

## Austria (AT)

| Topic | Rule (2026) | Source |
|---|---|---|
| Minimum wage | **No statutory minimum wage.** Minimums come from collective agreements (KV). KV Hotel- und Gastgewerbe: new agreement effective **1 Oct 2026**, **+3% on average** (+3.44% apprentices, +3.48% wage group 5) plus a one-off bonus of **up to €275**. Rates differ **by federal state** (Vienna also by business type), so let the user enter the wage. | OTS 18 Aug 2026; WKO |
| Geringfügigkeitsgrenze | **€551.10/month**, **frozen** at the 2025 value by the Budgetbegleitgesetz 2025 (no daily limit since 2017). Several marginal jobs, or a marginal job plus a main job, that together exceed it → full health and pension insurance, billed after year end. | PwC AT; oesterreich.gv.at; iKontista |
| Unemployment + marginal job | Since **1 Jan 2026**, a marginal job alongside unemployment benefit or emergency assistance is generally **no longer allowed**, with exceptions (e.g. held for at least 26 weeks alongside the previous full job; long-term unemployed after 365 days for up to 26 weeks; 50+/disabled; training cases). Transition ended 31 Jan 2026. | Arbeiterkammer; AMS |
| Breaks (§11 AZG) | Daily working time over **6 h → at least 30 min**. Can be split into 2 × 15 or 3 × 10 min if in the employees' interest or operationally required; one part must be at least 10 min (at least 15 in other splits). Youths (KJBG): over 4.5 h → 30 min. | JUSLINE §11 AZG; usp.gv.at |
| Working time | Normal 8 h/day and 40 h/week; max **12 h/day, 60 h/week** (average 48 h over 17 weeks); daily rest 11 h (§12 AZG; sector exceptions exist, verify for Gastgewerbe). | AZG |
| Overtime / Mehrarbeit | Overtime (beyond 40 h or 8 h) → **50%** surcharge or time off at 1:1.5 (§10 AZG). Part-time **Mehrarbeit → 25%** surcharge unless compensated within the period (§19d AZG). | AZG |
| Tax-free surcharges (§68 EStG) | 2026: surcharges for the **first 15 overtime hours per month tax-free up to €170**. The 2024/25 increase (18 h / €200) expired; without the 2026 change it would have been 10 h / €120. **SEG allowances plus Sunday, holiday and night surcharges (and related overtime surcharges and Feiertagsarbeitsentgelt): €400/month** from 2026, previously €360 (per WKO brochure March 2026 and search results; verify). Night work for §68 = at least 3 consecutive hours between 19:00 and 07:00 (verify). | WKO; Parlament Budgetdienst; WKO brochure |
| Holiday work | 13 national public holidays (1 Jan, 6 Jan, Easter Monday, 1 May, Ascension, Whit Monday, Corpus Christi, 15 Aug, 26 Oct, 1 Nov, 8 Dec, 25 and 26 Dec). Anyone who works on a holiday gets the regular holiday pay **plus** pay for the work (Feiertagsarbeitsentgelt, ARG §9), effectively about double. | ARG |
| Tips | Customary, voluntary tips from third parties are **income-tax-free** (§3 (1) Z 16a EStG) but **subject to social insurance** via a flat amount. Since **1 Jan 2026** there is a nationwide uniform **Trinkgeldpauschale**: **€65/month** for staff who collect payments (Inkasso), **€45** without Inkasso (e.g. cooks), **€20** apprentices. Rises to **€85 (2027)** and **€100 (2028)**, then indexed. | WKO; gastrodok; FreeFinance |
| Special payments | Many KVs (incl. Gastgewerbe) include 13th and 14th salaries, pro rata for part-time and marginal jobs, so expected-vs-payslip reconciliation should allow extra payouts. | KV (verify per KV) |
| Locale detail | Austrian German uses "Jänner" (intl `de_AT`). Add an `app_de_AT.arb` override or date formatting with the `de_AT` locale. | — |

## Modeling implications for Chronos
- Store a **country** (DE/AT) and, for DE, a **Bundesland** per user, with overrides per job.
- **Job kind** drives defaults: break rule, limit monitor (€603 DE / €551.10 AT), and net estimate (Minijob 3.6%).
- **Constants table by year** (`minWage`, `minijobLimit`, `midijobUpper`, `atGeringfuegig`, `§3b` rates, `AT §68` caps, `Trinkgeldpauschale`), shipped with the app and easy to update each January. Show the year next to every number in the UI.
- **Surcharge presets are editable suggestions**, never presented as entitlements.
- **Tips are stored separately.** They're excluded from Minijob limit sums (DE) and shown separately from wage (AT: only the flat amount matters for social insurance, which is the employer's business).
- **Always show breaks and night/Sunday/holiday minutes in exports**, because they're what payroll checks.
- **Disclaimers:** "Chronos ersetzt keine Arbeitszeiterfassung des Arbeitgebers" and "Beträge sind Schätzungen".
- **Uncertainty flags to re-check before release:** DE SV-free SFN limit of €25/h and its effect on the Minijob limit; how pooled tips are treated; the German ArbZG reform timeline; AT §68 €400 cap and night-work definition; KV Gastgewerbe tables per state; AT daily rest exceptions in Gastgewerbe.

## Sources

- https://developer.android.com/google/play/requirements/target-sdk
- https://support.google.com/googleplay/android-developer/answer/14151465
- https://www.testerscommunity.com/blog/google-play-12-testers-policy
- https://primetestlab.com/blog/google-play-changed-20-to-12-testers
- https://android-developers.googleblog.com/2025/05/prepare-play-apps-for-devices-with-16kb-page-size.html
- https://support.google.com/googleplay/android-developer/thread/369751886/clarification-on-16-kb-page-size-extension-and-monitoring-for-issues-before-may-31-2026?hl=en
- https://developer.android.com/about/versions/16/behavior-changes-16
- https://developer.android.com/about/versions/14/behavior-changes-all
- https://developer.android.com/about/versions/14/changes/schedule-exact-alarms
- https://developer.android.com/develop/background-work/services/alarms
- https://developer.android.com/develop/background-work/services/fgs/service-types
- https://support.google.com/googleplay/android-developer/answer/13392821
- https://developer.android.com/develop/ui/views/notifications/live-update
- https://developer.android.com/develop/ui/views/notifications/notification-permission
- https://developer.android.com/identity/data/autobackup
- https://developer.android.com/develop/ui/views/quicksettings-tiles
- https://source.android.com/docs/core/perf/cached-apps-freezer
- https://developer.android.com/docs/quality-guidelines/adaptive-app-quality
- https://android-developers.googleblog.com/2025/01/orientation-and-resizability-changes-in-android-16.html
- https://developer.android.com/about/versions/17/changes/ff-restrictions-ignored
- https://android-developers.googleblog.com/2026/02/prepare-your-app-for-resizability-and.html
- https://android-developers.googleblog.com/2026/03/android-developer-verification-rolling-out-to-all-developers.html
- https://support.google.com/googleplay/android-developer/answer/10787469
- https://support.google.com/googleplay/android-developer/answer/17134731
- https://github.com/flutter/flutter/issues/192921
- https://docs.flutter.dev/release/breaking-changes/default-systemuimode-edge-to-edge
- https://docs.flutter.dev/platform-integration/android/predictive-back
- https://docs.flutter.dev/release/breaking-changes/default-android-page-transition
- https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin
- https://somniosoftware.com/blog/flutter-3-44-migration-guide-agp-9-swift-package-manager-and-breaking-changes
- https://raw.githubusercontent.com/flutter/flutter/stable/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt
- https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json
- https://www.freecodecamp.org/news/how-to-work-with-material-and-cupertino-decoupling-in-flutter-full-handbook/
- https://pub.dev/packages/material_ui
- https://pub.dev/packages/flutter_local_notifications
- https://pub.dev/packages/flutter_local_notifications/changelog
- https://github.com/MaikuB/flutter_local_notifications/pull/2810
- https://github.com/MaikuB/flutter_local_notifications/issues/2773
- https://pub.dev/packages/flutter_riverpod/changelog
- https://pub.dev/packages/drift
- https://pub.dev/documentation/drift_flutter/latest/drift_flutter/DriftNativeOptions-class.html
- https://pub.dev/packages/sqlite3
- https://pub.dev/packages/sqlite3_flutter_libs
- https://github.com/isar/isar/issues/1689
- https://luci-studio.com/blog/the-flutter-local-database-landscape-in-2026-a-maintenance-first-guide-fe6d267c/
- https://docs.hive.isar.community/
- https://pub.dev/packages/shared_preferences
- https://pub.dev/packages/home_widget
- https://github.com/ABausG/home_widget
- https://pub.dev/packages/go_router/changelog
- https://8thlight.com/insights/flutter-navigation-is-gorouter-still-the-best-choice
- https://pub.dev/packages/flutter_foreground_task
- https://pub.dev/api/packages/<name> (pub.dev API queried 2026-09-30 for all listed package versions)
- https://play.google.com/store/apps/details?id=com.dynamicg.timerecording
- https://dynamicg.ch/timerecording/home/en.html
- https://appgrooves.com/android/com.dynamicg.timerecording
- https://play.google.com/store/apps/details?id=com.rauscha.apps.timesheet
- https://www.appbrain.com/app/timesheet-time-tracker/com.rauscha.apps.timesheet
- https://www.trustpilot.com/review/timesheet.io
- https://play.google.com/store/apps/details?id=com.cribasoft.HoursTrackerFree.Android
- https://appgrooves.com/app/hourstracker-time-tracking-for-hourly-work-by-cribasoft-llc/negative
- https://play.google.com/store/apps/details?id=partl.workinghours
- https://workinghoursapp.com/en
- https://www.appbrain.com/app/workinghours-time-tracking/partl.workinghours
- https://play.google.com/store/apps/details?id=com.bakua.worktimemanager
- https://www.similarweb.com/app/google/com.bakua.worktimemanager/
- https://play.google.com/store/apps/details?id=me.clockify.android
- https://www.jibble.io/reviews/clockify
- https://www.appbrain.com/app/toggl-track-time-tracking/com.toggl.giskard
- https://www.timely.com/blog/toggl-track-reviews/
- https://play.google.com/store/apps/details?id=app.supershift
- https://www.appbrain.com/app/supershift-shift-work-calendar/app.supershift
- https://www.ordio.com/insights/ratgeber/dienstplan-app-vergleich
- https://github.com/Razeeman/Android-SimpleTimeTracker
- https://f-droid.org/packages/com.razeeman.util.simpletimetracker/
- https://play.google.com/store/apps/details?id=app.gntl.tipbook
- https://server44.app/
- https://play.google.com/store/apps/details?id=com.magonapps.waiterpal
- https://www.bundesregierung.de/breg-de/aktuelles/mindestlohn-steigt-2391010
- https://magazin.minijob-zentrale.de/neue-verdienstgrenze-2026/
- https://www.haufe.de/personal/entgelt/minijob-grenze_78_479516.html
- https://www.tk.de/firmenkunden/fachthemen/versicherung-fachthema/mindestlohn-2026-minijobs-und-uebergangsbereich-2203074
- https://www.minijob-zentrale.de/DE/die-minijobs/rentenversicherungspflicht
- https://magazin.minijob-zentrale.de/minijob-rentenversicherung-befreiung-aufheben/
- https://magazin.minijob-zentrale.de/minijobs-gastronomie/
- https://www.gesetze-im-internet.de/arbzg/__4.html
- https://www.gesetze-im-internet.de/arbzg/__5.html
- https://www.gesetze-im-internet.de/estg/__3b.html
- https://esth.bundesfinanzministerium.de/lsth/2026/A-Einkommensteuergesetz/II-Einkommen-2-24b/2-Steuerfreie-Einnahmen-3-3c/Paragraf-3b/inhalt.html
- https://www.deutsche-rentenversicherung.de/DRV/DE/Experten/Arbeitgeber-und-Steuerberater/summa-summarum/Lexikon/S/steuerfreie_sfn_zuschlaege.html
- https://www.haufe.de/finance/buchfuehrung-kontierung/trinkgelder-an-arbeitnehmer-und-unternehmer/trinkgeld-versteuern_186_421634.html
- https://kliemt.blog/2026/05/13/gesetzesentwurf-zur-arbeitszeit-2026-was-jetzt-zu-erwarten-ist/
- https://www.gruenderkueche.de/fachartikel/organisation/die-besten-zeiterfassung-apps/
- https://www.pwc.at/de/insights/workforce-aktuell/2025/keine-erhoehung-der-geringfuegigkeitsgrenze-2026-was-das-festhalten-im-aktuellen-wert-aus-sozialversicherungsrechtlciher-sicht-bedeutet.html
- https://www.oesterreich.gv.at/de/lexicon/G/Seite.990119
- https://www.arbeiterkammer.at/beratung/arbeitundrecht/Arbeitslosigkeit/Ab-2026-Geringfuegiger-Zuverdienst-zum-Arbeitslosengeld-e.html
- https://www.ams.at/arbeitsuchende/arbeitslos-was-tun/arbeitslos-geringfuegig-beschaeftigt
- https://www.jusline.at/gesetz/azg/paragraf/11
- https://www.usp.gv.at/mitarbeiter/arbeitszeit/ruhepausen.html
- https://www.wko.at/steuern/steuerfreiheit-ueberstundenzuschlaege
- https://www.parlament.gv.at/fachinfos/budgetdienst/Steuerliche-Beguenstigung-Ueberstundenzuschlaege-und-Beleglotterie
- https://www.wko.at/oe/lohnverrechnung/versteuerung-zulagen-zuschlaege-broschuere.pdf
- https://www.wko.at/tourismus-freizeitwirtschaft/serviceplattform-gastronomie-hotellerie/trinkgeldpauschale
- https://gastrodok.de/trinkgeldpauschale-oesterreich-2026
- https://www.ots.at/presseaussendung/OTS_20260818_OTS0076/kv-abschluss-fuer-gastronomie-und-hotellerie-fairer-abschluss-in-wirtschaftlich-fordernden-zeiten
- NOTE: play.google.com, appbrain.com, apkpure.com, support.google.com, docs.flutter.dev, flutter.dev, riverpod.dev, drift.simonbinder.eu, dynamicg.ch, workinghoursapp.com and wko.at were blocked by the session egress proxy. Figures from those pages come from search-result snippets and should be spot-checked in a browser.
