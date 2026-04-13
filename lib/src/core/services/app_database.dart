import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class AppSnapshots extends Table {
  IntColumn get id => integer()();
  TextColumn get stateJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [AppSnapshots])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<String?> loadSnapshot() async {
    final row = await (select(
      appSnapshots,
    )..where((tbl) => tbl.id.equals(1))).getSingleOrNull();
    return row?.stateJson;
  }

  Future<void> saveSnapshot(String json) async {
    await into(appSnapshots).insertOnConflictUpdate(
      AppSnapshotsCompanion(id: const Value(1), stateJson: Value(json)),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'fitness_os.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
