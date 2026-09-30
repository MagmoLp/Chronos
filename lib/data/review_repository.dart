import 'package:drift/drift.dart';

import '../domain/review.dart';
import 'database.dart';
import 'legacy/legacy_models.dart';
import 'mappers.dart';

/// The "please review" list of migrated shifts and the list of v1 entries
/// that could not be imported.
class ReviewRepository {
  /// Creates the repository on [db].
  ReviewRepository(this._db);

  final AppDatabase _db;

  JoinedSelectStatement<HasResultSet, dynamic> _itemsQuery() {
    final query =
        _db.select(_db.reviewItems).join([
            innerJoin(
              _db.shifts,
              _db.shifts.id.equalsExp(_db.reviewItems.shiftId),
            ),
          ])
          ..where(_db.shifts.deletedAt.isNull())
          ..orderBy([OrderingTerm.asc(_db.shifts.startUtc)]);
    return query;
  }

  List<ReviewItem> _map(List<TypedResult> rows) => [
    for (final row in rows) row.readTable(_db.reviewItems).toDomain(),
  ];

  /// Review items of non-deleted shifts, oldest shift first.
  Stream<List<ReviewItem>> watchItems() => _itemsQuery().watch().map(_map);

  /// Review items of non-deleted shifts, oldest shift first.
  Future<List<ReviewItem>> getItems() async => _map(await _itemsQuery().get());

  /// Adds or replaces [items].
  Future<void> putItems(Iterable<ReviewItem> items) => _db.batch((batch) {
    batch.insertAllOnConflictUpdate(_db.reviewItems, [
      for (final i in items) reviewItemCompanion(i),
    ]);
  });

  /// Removes the item of [shiftId] ("looks fine").
  Future<void> dismiss(int shiftId) => (_db.delete(
    _db.reviewItems,
  )..where((t) => t.shiftId.equals(shiftId))).go();

  /// Removes all review items.
  Future<void> dismissAll() => _db.delete(_db.reviewItems).go();

  SimpleSelectStatement<$LegacyErrorsTable, LegacyErrorRow> _failuresQuery() =>
      _db.select(_db.legacyErrors)..orderBy([(t) => OrderingTerm.asc(t.id)]);

  /// v1 entries that could not be imported.
  Stream<List<LegacyFailure>> watchLegacyFailures() => _failuresQuery()
      .watch()
      .map((rows) => [for (final r in rows) LegacyFailure.fromRow(r)]);

  /// v1 entries that could not be imported.
  Future<List<LegacyFailure>> getLegacyFailures() async => [
    for (final r in await _failuresQuery().get()) LegacyFailure.fromRow(r),
  ];
}
