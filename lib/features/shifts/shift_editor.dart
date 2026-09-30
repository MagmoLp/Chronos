import 'package:flutter/material.dart';

import '../../core/local_date.dart';

/// Opens the shift editor: edits shift [shiftId], or creates a new shift
/// (optionally on [date] / for [jobId]). Placeholder until the Shifts
/// feature lands.
Future<void> showShiftEditor(
  BuildContext context, {
  int? shiftId,
  LocalDate? date,
  int? jobId,
}) async {}
