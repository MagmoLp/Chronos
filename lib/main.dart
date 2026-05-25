import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'providers/work_entries_provider.dart';
import 'providers/timer_provider.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/work_log_screen.dart';
import 'widgets/custom_bottom_nav.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('Flutter initialized');
    
    final settingsProvider = SettingsProvider();
    await settingsProvider.loadSettings();
    debugPrint('Settings loaded');
    
    final workEntriesProvider = WorkEntriesProvider();
    await workEntriesProvider.loadEntries();
    debugPrint('Entries loaded');
    
    final notificationService = NotificationService();
    await notificationService.init();
    debugPrint('Notification service initialized');
    
    final timerProvider = TimerProvider();
    timerProvider.setHourlyWage(settingsProvider.hourlyWage);
    await timerProvider.loadActiveSession();
    debugPrint('Timer session loaded');
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settingsProvider),
          ChangeNotifierProvider.value(value: workEntriesProvider),
          ChangeNotifierProvider.value(value: timerProvider),
        ],
        child: const ChronosApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('ERROR during startup: $e');
    debugPrint('Stack trace: $stack');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Startup Error: $e'),
          ),
        ),
      ),
    );
  }
}

class ChronosApp extends StatelessWidget {
  const ChronosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Chronos',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('de'),
        Locale('en'),
      ],
      locale: settings.locale,
      theme: AppThemeData.darkTheme,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const WorkLogScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppThemeData.background,
      extendBody: false,
      body: AnimatedSwitcher(
        duration: AppThemeData.animationMedium,
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          NavItem(
            icon: Icons.timer,
            label: l10n?.currentEarnings ?? 'Live',
          ),
          NavItem(
            icon: Icons.format_list_bulleted,
            label: l10n?.workTimeLog ?? 'Log',
          ),
        ],
      ),
    );
  }
}
