import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../data/models.dart';
import '../data/seed_data.dart';

class LocalStoreService {
  Future<File> _resolveFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/fitness_os_state.json');
  }

  Future<AppStateData> load() async {
    final file = await _resolveFile();
    if (!await file.exists()) {
      return AppStateData.initial(seedFoods: SeedData.foods);
    }

    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return AppStateData.initial(seedFoods: SeedData.foods);
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final data = AppStateData.fromJson(decoded);
    return data.copyWith(
      customFoods: SeedData.reconcileFoods(data.customFoods),
    );
  }

  Future<void> save(AppStateData data) async {
    final file = await _resolveFile();
    await file.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data.toJson()),
      flush: true,
    );
  }
}
