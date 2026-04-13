import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models.dart';

class CsvService {
  Future<List<File>> exportAll(AppStateData data) async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(directory.path, 'exports'));
    await exportDir.create(recursive: true);

    final files = <File>[
      await _writeCsv(exportDir, 'food_logs.csv', [
        [
          'date',
          'meal_slot',
          'food_name',
          'quantity',
          'quantity_unit',
          'calories',
          'protein_g',
          'carbs_g',
          'fat_g',
          'fiber_g',
          'source',
          'description',
          'source_title',
        ],
        ...data.foodLogs.map(
          (item) => [
            item.date,
            item.mealSlot.name,
            item.foodName,
            item.quantityG,
            item.quantityUnit.name,
            item.calories,
            item.proteinG,
            item.carbsG,
            item.fatG,
            item.fiberG,
            item.source,
            item.description ?? '',
            item.sourceTitle ?? '',
          ],
        ),
      ]),
      await _writeCsv(exportDir, 'weight_logs.csv', [
        ['date', 'weight_kg', 'notes'],
        ...data.weightLogs.map(
          (item) => [item.date, item.weightKg, item.notes ?? ''],
        ),
      ]),
      await _writeCsv(exportDir, 'workout_sets.csv', [
        [
          'session_id',
          'exercise_name',
          'muscle_group',
          'set_number',
          'reps',
          'weight_kg',
          'warmup',
          'failure',
          'pr',
        ],
        ...data.exerciseSets.map(
          (item) => [
            item.sessionId,
            item.exerciseName,
            item.muscleGroup,
            item.setNumber,
            item.reps,
            item.weightKg,
            item.isWarmup,
            item.isFailure,
            item.isPr,
          ],
        ),
      ]),
      await _writeCsv(exportDir, 'body_measurements.csv', [
        [
          'date',
          'waist_cm',
          'neck_cm',
          'chest_cm',
          'left_arm_cm',
          'right_arm_cm',
          'left_thigh_cm',
          'right_thigh_cm',
          'body_fat_pct',
          'notes',
        ],
        ...data.bodyMeasurements.map(
          (item) => [
            item.date,
            item.waistCm,
            item.neckCm,
            item.chestCm,
            item.leftArmCm,
            item.rightArmCm,
            item.leftThighCm,
            item.rightThighCm,
            item.bodyFatPct,
            item.notes ?? '',
          ],
        ),
      ]),
    ];

    return files;
  }

  Future<void> shareFiles(List<File> files) async {
    await SharePlus.instance.share(
      ShareParams(files: files.map((file) => XFile(file.path)).toList()),
    );
  }

  Future<List<FoodLogEntry>> importFoodLogs() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    final path = result?.files.single.path;
    if (path == null) {
      return const [];
    }
    final content = await File(path).readAsString();
    final rows = const CsvToListConverter().convert(content);
    if (rows.length <= 1) {
      return const [];
    }
    return rows.skip(1).map((row) {
      return FoodLogEntry(
        id: 'food-import-${DateTime.now().microsecondsSinceEpoch}-${row[0]}',
        date: row[0].toString(),
        mealSlot: MealSlot.values.firstWhere(
          (slot) => slot.name == row[1].toString(),
          orElse: () => MealSlot.breakfast,
        ),
        foodName: row[2].toString(),
        quantityG:
            (row[3] as num?)?.toDouble() ??
            double.tryParse(row[3].toString()) ??
            0,
        quantityUnit: row.length > 10
            ? FoodQuantityUnit.values.firstWhere(
                (unit) => unit.name == row[4].toString(),
                orElse: () => FoodQuantityUnit.grams,
              )
            : FoodQuantityUnit.grams,
        calories:
            (row[row.length > 10 ? 5 : 4] as num?)?.toDouble() ??
            double.tryParse(row[row.length > 10 ? 5 : 4].toString()) ??
            0,
        proteinG:
            (row[row.length > 10 ? 6 : 5] as num?)?.toDouble() ??
            double.tryParse(row[row.length > 10 ? 6 : 5].toString()) ??
            0,
        carbsG:
            (row[row.length > 10 ? 7 : 6] as num?)?.toDouble() ??
            double.tryParse(row[row.length > 10 ? 7 : 6].toString()) ??
            0,
        fatG:
            (row[row.length > 10 ? 8 : 7] as num?)?.toDouble() ??
            double.tryParse(row[row.length > 10 ? 8 : 7].toString()) ??
            0,
        fiberG:
            (row[row.length > 10 ? 9 : 8] as num?)?.toDouble() ??
            double.tryParse(row[row.length > 10 ? 9 : 8].toString()) ??
            0,
        source: row.length > 10
            ? row[10].toString()
            : row.length > 9
            ? row[9].toString()
            : 'import',
        description: row.length > 11 && row[11].toString().trim().isNotEmpty
            ? row[11].toString().trim()
            : null,
        sourceTitle: row.length > 12 && row[12].toString().trim().isNotEmpty
            ? row[12].toString().trim()
            : null,
      );
    }).toList();
  }

  Future<File> _writeCsv(
    Directory directory,
    String name,
    List<List<Object?>> rows,
  ) async {
    final file = File(p.join(directory.path, name));
    await file.writeAsString(const ListToCsvConverter().convert(rows));
    return file;
  }
}
