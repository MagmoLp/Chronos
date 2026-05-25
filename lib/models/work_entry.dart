class WorkEntry {
  final String id;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final bool isPaid;

  WorkEntry({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.isPaid = false,
  });

  Duration get duration => endTime.difference(startTime);

  double calculateEarnings(double hourlyWage) {
    final hours = duration.inMinutes / 60.0;
    return hours * hourlyWage;
  }

  bool get isOvernightShift =>
      startTime.day != endTime.day ||
      startTime.month != endTime.month ||
      startTime.year != endTime.year;

  String get formattedTimeRange {
    final startHHmm = "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}";
    final endHHmm = "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";
    if (isOvernightShift) {
      final startDay = "${startTime.day.toString().padLeft(2, '0')}.${startTime.month.toString().padLeft(2, '0')}.";
      final endDay = "${endTime.day.toString().padLeft(2, '0')}.${endTime.month.toString().padLeft(2, '0')}.";
      return "$startHHmm ($startDay) – $endHHmm ($endDay)";
    }
    return "$startHHmm – $endHHmm";
  }

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (minutes == 0) {
      return "${hours}h";
    }
    return "${hours}:${minutes.toString().padLeft(2, '0')}h";
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'isPaid': isPaid,
    };
  }

  factory WorkEntry.fromJson(Map<String, dynamic> json) {
    return WorkEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      isPaid: json['isPaid'] ?? false,
    );
  }

  WorkEntry copyWith({
    String? id,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    bool? isPaid,
  }) {
    return WorkEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}
