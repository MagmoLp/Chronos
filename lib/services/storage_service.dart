import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/work_entry.dart';
import '../models/app_settings.dart';

class StorageService {
  static const String _workEntriesKey = 'work_entries';
  static const String _settingsKey = 'app_settings';
  static const String _activeSessionKey = 'active_session';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveWorkEntry(WorkEntry entry) async {
    final entries = await getWorkEntries();
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      entries[index] = entry;
    } else {
      entries.add(entry);
    }
    await _saveWorkEntries(entries);
  }

  Future<void> deleteWorkEntry(String id) async {
    final entries = await getWorkEntries();
    entries.removeWhere((e) => e.id == id);
    await _saveWorkEntries(entries);
  }

  Future<void> deleteAllWorkEntries() async {
    if (_prefs == null) await init();
    await _prefs!.remove(_workEntriesKey);
  }

  Future<List<WorkEntry>> getWorkEntries() async {
    if (_prefs == null) await init();
    final jsonString = _prefs!.getString(_workEntriesKey);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => WorkEntry.fromJson(json)).toList();
  }

  Future<void> _saveWorkEntries(List<WorkEntry> entries) async {
    if (_prefs == null) await init();
    final jsonList = entries.map((e) => e.toJson()).toList();
    await _prefs!.setString(_workEntriesKey, json.encode(jsonList));
  }

  Future<AppSettings> getSettings() async {
    if (_prefs == null) await init();
    final jsonString = _prefs!.getString(_settingsKey);
    if (jsonString == null) return AppSettings();
    
    return AppSettings.fromJson(json.decode(jsonString));
  }

  Future<void> saveSettings(AppSettings settings) async {
    if (_prefs == null) await init();
    await _prefs!.setString(_settingsKey, json.encode(settings.toJson()));
  }

  Future<void> saveActiveSession(DateTime? startTime) async {
    if (_prefs == null) await init();
    if (startTime == null) {
      await _prefs!.remove(_activeSessionKey);
    } else {
      await _prefs!.setString(_activeSessionKey, startTime.toIso8601String());
    }
  }

  Future<DateTime?> getActiveSession() async {
    if (_prefs == null) await init();
    final jsonString = _prefs!.getString(_activeSessionKey);
    if (jsonString == null) return null;
    return DateTime.parse(jsonString);
  }
}
