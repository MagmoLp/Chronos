# Chronos

A Flutter application for real-time salary counting and work time tracking.

## Features

- **Real-Time Salary Counter**: Calculates earned money in real-time based on hourly wage
  - Animated rolling number display for current earnings
  - Total open earnings display (all unpaid work entries)
  - Start/Stop timer with confirmation dialog

- **Work Time Log**: Track and manage work sessions
  - List of all work entries with date, time range, and duration
  - Mark entries as paid/unpaid
  - Edit entries via long-press menu
  - Delete entries with confirmation
  - Add manual entries

- **Settings**:
  - Language selection (German/English)
  - Theme selection (Dark/Light mode)
  - Hourly wage configuration

## Design

- **Dark Mode**: Navy Blue (#001F3F) & Anthracite (#2D2D2D)
- **Light Mode**: Light Blue (#87CEEB) & White (#FFFFFF)

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android Studio or VS Code

### Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Generate localization files:
```bash
flutter gen-l10n
```

3. Run the app:
```bash
flutter run
```

### Build for Android

```bash
flutter build apk --release
```

## Project Structure

```
lib/
├── models/
│   ├── app_settings.dart
│   └── work_entry.dart
├── providers/
│   ├── settings_provider.dart
│   ├── timer_provider.dart
│   └── work_entries_provider.dart
├── screens/
│   ├── home_screen.dart
│   ├── settings_screen.dart
│   └── work_log_screen.dart
├── services/
│   └── storage_service.dart
├── theme/
│   └── app_theme.dart
├── widgets/
│   ├── animated_digit.dart
│   └── animated_money_display.dart
├── l10n/
│   ├── app_de.arb
│   └── app_en.arb
└── main.dart
```

## Dependencies

- `provider`: State management
- `shared_preferences`: Local data storage
- `uuid`: Unique ID generation
- `intl`: Internationalization
- `flutter_localizations`: Localization support
