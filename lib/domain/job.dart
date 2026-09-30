/// How a job rounds timer start and end times when a shift is finished.
///
/// Rounds to the nearest step in local wall-clock time; exactly half a step
/// rounds up. Manual shifts are never rounded.
enum RoundingRule {
  /// No rounding.
  none(0),

  /// Nearest 5 minutes.
  nearest5(5),

  /// Nearest 15 minutes (the v1 behaviour, with the corrected 7.5 min
  /// threshold).
  nearest15(15);

  const RoundingRule(this.stepMinutes);

  /// Step size in minutes; 0 for [none].
  final int stepMinutes;
}

/// Default job colour (first entry of the light job palette, see
/// `docs/research/ux-audit.md`). The UI maps stored values to its palette.
const int kDefaultJobColorArgb = 0xFF1F6FB2;

/// An employer / job the user works for.
final class Job {
  /// Creates a job.
  const Job({
    required this.id,
    required this.uuid,
    required this.name,
    required this.colorArgb,
    this.rounding = RoundingRule.none,
    this.archived = false,
    this.sortOrder = 0,
  });

  /// Database id.
  final int id;

  /// Stable id used to merge backups.
  final String uuid;

  /// Display name (entered by the user).
  final String name;

  /// Colour as 0xAARRGGBB.
  final int colorArgb;

  /// Rounding applied to timer shifts of this job.
  final RoundingRule rounding;

  /// Archived jobs are hidden from pickers but keep their shifts.
  final bool archived;

  /// Position in job lists (ascending).
  final int sortOrder;

  /// Copy with the given fields replaced.
  Job copyWith({
    int? id,
    String? uuid,
    String? name,
    int? colorArgb,
    RoundingRule? rounding,
    bool? archived,
    int? sortOrder,
  }) => Job(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    name: name ?? this.name,
    colorArgb: colorArgb ?? this.colorArgb,
    rounding: rounding ?? this.rounding,
    archived: archived ?? this.archived,
    sortOrder: sortOrder ?? this.sortOrder,
  );

  @override
  bool operator ==(Object other) =>
      other is Job &&
      other.id == id &&
      other.uuid == uuid &&
      other.name == name &&
      other.colorArgb == colorArgb &&
      other.rounding == rounding &&
      other.archived == archived &&
      other.sortOrder == sortOrder;

  @override
  int get hashCode =>
      Object.hash(id, uuid, name, colorArgb, rounding, archived, sortOrder);

  @override
  String toString() =>
      'Job($id, $name, $rounding${archived ? ', archived' : ''})';
}
