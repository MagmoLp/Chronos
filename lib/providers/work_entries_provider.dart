import 'package:flutter/material.dart';
import '../models/work_entry.dart';
import '../services/storage_service.dart';

class WorkEntriesProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  
  List<WorkEntry> _entries = [];
  List<WorkEntry> get entries => List.unmodifiable(_entries);

  List<WorkEntry> get openEntries => _entries.where((e) => !e.isPaid).toList();
  List<WorkEntry> get paidEntries => _entries.where((e) => e.isPaid).toList();

  double totalOpenEarnings(double hourlyWage) {
    return openEntries.fold(0.0, (sum, entry) => sum + entry.calculateEarnings(hourlyWage));
  }

  Future<void> loadEntries() async {
    _entries = await _storage.getWorkEntries();
    _sortEntries();
    notifyListeners();
  }

  Future<void> saveEntry(WorkEntry entry) async {
    await _storage.saveWorkEntry(entry);
    await loadEntries();
  }

  Future<void> deleteEntry(String id) async {
    await _storage.deleteWorkEntry(id);
    await loadEntries();
  }

  Future<void> deleteAllEntries() async {
    await _storage.deleteAllWorkEntries();
    _entries = [];
    notifyListeners();
  }

  Future<void> togglePaidStatus(String id) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index >= 0) {
      final updated = _entries[index].copyWith(isPaid: !_entries[index].isPaid);
      await _storage.saveWorkEntry(updated);
      await loadEntries();
    }
  }

  void _sortEntries() {
    _entries.sort((a, b) => b.startTime.compareTo(a.startTime));
  }
}
