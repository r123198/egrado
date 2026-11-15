import 'package:egrado/data/database/app_database.dart';
import 'package:egrado/domain/teaching_level.dart';

/// How the signed-in teacher's workspace is set up.
abstract interface class WorkspaceRepository {
  /// DepEd or college; null until the teacher has been asked. Updates live.
  Stream<TeachingLevel?> watchLevel();

  Future<void> setLevel(TeachingLevel level);
}

class DriftWorkspaceRepository implements WorkspaceRepository {
  DriftWorkspaceRepository(this._db);

  static const _levelKey = 'teaching_level';

  final AppDatabase _db;

  /// A value this version doesn't know reads as "not asked yet".
  @override
  Stream<TeachingLevel?> watchLevel() =>
      (_db.select(_db.settings)..where((s) => s.key.equals(_levelKey)))
          .watchSingleOrNull()
          .map((row) => TeachingLevel.values.asNameMap()[row?.value]);

  @override
  Future<void> setLevel(TeachingLevel level) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: _levelKey, value: level.name),
      );
}
