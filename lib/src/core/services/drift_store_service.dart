import 'dart:convert';

import '../data/models.dart';
import '../data/seed_data.dart';
import 'app_database.dart';
import 'local_store_service.dart';

class DriftStoreService {
  DriftStoreService(this._database, this._legacyStore);

  final AppDatabase _database;
  final LocalStoreService _legacyStore;

  Future<AppStateData> load() async {
    final json = await _database.loadSnapshot();
    if (json != null && json.trim().isNotEmpty) {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final data = AppStateData.fromJson(decoded);
      return data.copyWith(
        customFoods: SeedData.reconcileFoods(data.customFoods),
      );
    }

    final migrated = await _legacyStore.load();
    await save(migrated);
    return migrated;
  }

  Future<void> save(AppStateData data) async {
    await _database.saveSnapshot(
      const JsonEncoder.withIndent('  ').convert(data.toJson()),
    );
  }
}
