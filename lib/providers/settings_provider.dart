import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  
  AppSettings _settings = AppSettings();
  AppSettings get settings => _settings;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Locale get locale {
    switch (_settings.language) {
      case AppLanguage.german:
        return const Locale('de');
      case AppLanguage.english:
        return const Locale('en');
    }
  }

  ThemeMode get themeMode {
    switch (_settings.theme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
    }
  }

  double get hourlyWage => _settings.hourlyWage;
  AppLanguage get language => _settings.language;
  AppTheme get theme => _settings.theme;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    
    await _storage.init();
    _settings = await _storage.getSettings();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    _settings = _settings.copyWith(language: language);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    _settings = _settings.copyWith(theme: theme);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setHourlyWage(double wage) async {
    _settings = _settings.copyWith(hourlyWage: wage);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }
}
