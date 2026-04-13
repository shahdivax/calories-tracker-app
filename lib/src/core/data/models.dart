String _twoDigits(int value) => value.toString().padLeft(2, '0');

String dayKey([DateTime? date]) {
  final value = date ?? DateTime.now();
  return '${value.year}-${_twoDigits(value.month)}-${_twoDigits(value.day)}';
}

DateTime parseDayKey(String input) => DateTime.parse(input);

String formatShortDate(String input) {
  final date = parseDayKey(input);
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  return '${date.day} ${months[date.month - 1]}';
}

String formatMinutes(int totalMinutes) {
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  final suffix = hours >= 12 ? 'PM' : 'AM';
  final normalizedHour = hours == 0
      ? 12
      : hours > 12
      ? hours - 12
      : hours;
  return '$normalizedHour:${_twoDigits(minutes)} $suffix';
}

enum BiologicalSex { male, female }

enum GoalType { fatLoss, recomp, muscleGain }

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  athlete,
}

enum DietType { jainVegetarian, regularVegetarian, nonVegetarian }

enum ProteinPreference { standard, aggressive, custom }

enum MealSlot { preWorkout, breakfast, lunch, postWorkout, dinner, lateSnack }

enum WorkoutType { cardio, push, pull, legs, custom, rest }

enum ProgressPhotoAngle { front, side, back }

enum FoodQuantityUnit { grams, milliliters, count }

enum ThemePreference { system, light, dark }

enum MeasurementSystem { metric, hybrid }

extension BiologicalSexLabel on BiologicalSex {
  String get label => this == BiologicalSex.male ? 'Male' : 'Female';
}

extension GoalTypeLabel on GoalType {
  String get label {
    switch (this) {
      case GoalType.fatLoss:
        return 'Fat Loss';
      case GoalType.recomp:
        return 'Recomposition';
      case GoalType.muscleGain:
        return 'Muscle Gain';
    }
  }
}

extension ActivityLevelLabel on ActivityLevel {
  String get label {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
      case ActivityLevel.athlete:
        return 'Athlete';
    }
  }

  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.lightlyActive:
        return 1.375;
      case ActivityLevel.moderatelyActive:
        return 1.55;
      case ActivityLevel.veryActive:
        return 1.725;
      case ActivityLevel.athlete:
        return 1.9;
    }
  }
}

extension DietTypeLabel on DietType {
  String get label {
    switch (this) {
      case DietType.jainVegetarian:
        return 'Jain Vegetarian';
      case DietType.regularVegetarian:
        return 'Regular Vegetarian';
      case DietType.nonVegetarian:
        return 'Non-Vegetarian';
    }
  }
}

extension ProteinPreferenceLabel on ProteinPreference {
  String get label {
    switch (this) {
      case ProteinPreference.standard:
        return 'Standard';
      case ProteinPreference.aggressive:
        return 'Aggressive';
      case ProteinPreference.custom:
        return 'Custom';
    }
  }
}

extension MealSlotLabel on MealSlot {
  String get label {
    switch (this) {
      case MealSlot.preWorkout:
        return 'Pre-workout';
      case MealSlot.breakfast:
        return 'Breakfast';
      case MealSlot.lunch:
        return 'Lunch';
      case MealSlot.postWorkout:
        return 'Post-workout';
      case MealSlot.dinner:
        return 'Dinner';
      case MealSlot.lateSnack:
        return 'Late Snack';
    }
  }
}

extension FoodQuantityUnitLabel on FoodQuantityUnit {
  String get label {
    switch (this) {
      case FoodQuantityUnit.grams:
        return 'Grams';
      case FoodQuantityUnit.milliliters:
        return 'Milliliters';
      case FoodQuantityUnit.count:
        return 'Count';
    }
  }

  String get shortLabel {
    switch (this) {
      case FoodQuantityUnit.grams:
        return 'g';
      case FoodQuantityUnit.milliliters:
        return 'ml';
      case FoodQuantityUnit.count:
        return 'no.';
    }
  }

  String get referenceLabel {
    switch (this) {
      case FoodQuantityUnit.grams:
        return '100 g';
      case FoodQuantityUnit.milliliters:
        return '100 ml';
      case FoodQuantityUnit.count:
        return '1 item';
    }
  }

  double get referenceAmount {
    switch (this) {
      case FoodQuantityUnit.grams:
      case FoodQuantityUnit.milliliters:
        return 100;
      case FoodQuantityUnit.count:
        return 1;
    }
  }
}

extension ThemePreferenceLabel on ThemePreference {
  String get label {
    switch (this) {
      case ThemePreference.system:
        return 'System';
      case ThemePreference.light:
        return 'Light';
      case ThemePreference.dark:
        return 'Dark';
    }
  }
}

extension MeasurementSystemLabel on MeasurementSystem {
  String get label {
    switch (this) {
      case MeasurementSystem.metric:
        return 'Metric (kg, cm, km)';
      case MeasurementSystem.hybrid:
        return 'Hybrid (kg, in, km)';
    }
  }

  String get heightUnit {
    switch (this) {
      case MeasurementSystem.metric:
        return 'cm';
      case MeasurementSystem.hybrid:
        return 'in';
    }
  }
}

extension WorkoutTypeLabel on WorkoutType {
  String get label {
    switch (this) {
      case WorkoutType.cardio:
        return 'Cardio';
      case WorkoutType.push:
        return 'Push';
      case WorkoutType.pull:
        return 'Pull';
      case WorkoutType.legs:
        return 'Legs';
      case WorkoutType.custom:
        return 'Custom';
      case WorkoutType.rest:
        return 'Rest';
    }
  }
}

extension ProgressPhotoAngleLabel on ProgressPhotoAngle {
  String get label {
    switch (this) {
      case ProgressPhotoAngle.front:
        return 'Front';
      case ProgressPhotoAngle.side:
        return 'Side';
      case ProgressPhotoAngle.back:
        return 'Back';
    }
  }
}

T _enumFromName<T extends Enum>(List<T> values, String? name, T fallback) {
  if (name == null) {
    return fallback;
  }
  return values.firstWhere(
    (value) => value.name == name,
    orElse: () => fallback,
  );
}

String _jsonStringOr(dynamic value, String fallback) {
  if (value == null) {
    return fallback;
  }
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

double _jsonDoubleOr(dynamic value, double fallback) {
  if (value == null) {
    return fallback;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }
    final direct = double.tryParse(trimmed.replaceAll(',', ''));
    if (direct != null) {
      return direct;
    }
    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(trimmed);
    if (match != null) {
      return double.tryParse(match.group(0)!) ?? fallback;
    }
  }
  return fallback;
}

String _jsonConfidenceOr(dynamic value, String fallback) {
  if (value == null) {
    return fallback;
  }
  if (value is num) {
    final scaled = value <= 1 ? value * 100 : value.toDouble();
    final bounded = scaled.clamp(0, 100).round();
    return '$bounded%';
  }
  return _jsonStringOr(value, fallback);
}

List<String>? _jsonStringList(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is List) {
    final items = value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return items.isEmpty ? null : items;
  }
  if (value is String) {
    final items = value
        .split(RegExp(r'[\n,]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return items.isEmpty ? null : items;
  }
  return null;
}

class BodyProfile {
  const BodyProfile({
    required this.name,
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.startingWeightKg,
    required this.goalWeightKg,
    required this.activityLevel,
    required this.goalType,
    required this.deficitKcal,
    required this.dietType,
    required this.wakeMinutes,
    required this.workStartMinutes,
    required this.workEndMinutes,
    required this.proteinPreference,
    required this.proteinMultiplier,
    required this.fatMultiplier,
    this.bodyFatPct,
    this.waistCm,
    this.neckCm,
    this.completedAt,
  });

  factory BodyProfile.defaults() => const BodyProfile(
    name: 'Divax',
    sex: BiologicalSex.male,
    age: 23,
    heightCm: 160,
    startingWeightKg: 96,
    goalWeightKg: 80,
    activityLevel: ActivityLevel.veryActive,
    goalType: GoalType.fatLoss,
    deficitKcal: 400,
    dietType: DietType.jainVegetarian,
    wakeMinutes: 375,
    workStartMinutes: 510,
    workEndMinutes: 1080,
    proteinPreference: ProteinPreference.aggressive,
    proteinMultiplier: 2.0,
    fatMultiplier: 0.8,
  );

  final String name;
  final BiologicalSex sex;
  final int age;
  final double heightCm;
  final double startingWeightKg;
  final double goalWeightKg;
  final double? bodyFatPct;
  final double? waistCm;
  final double? neckCm;
  final ActivityLevel activityLevel;
  final GoalType goalType;
  final int deficitKcal;
  final DietType dietType;
  final int wakeMinutes;
  final int workStartMinutes;
  final int workEndMinutes;
  final ProteinPreference proteinPreference;
  final double proteinMultiplier;
  final double fatMultiplier;
  final DateTime? completedAt;

  bool get isComplete => completedAt != null;

  BodyProfile copyWith({
    String? name,
    BiologicalSex? sex,
    int? age,
    double? heightCm,
    double? startingWeightKg,
    double? goalWeightKg,
    double? bodyFatPct,
    double? waistCm,
    double? neckCm,
    ActivityLevel? activityLevel,
    GoalType? goalType,
    int? deficitKcal,
    DietType? dietType,
    int? wakeMinutes,
    int? workStartMinutes,
    int? workEndMinutes,
    ProteinPreference? proteinPreference,
    double? proteinMultiplier,
    double? fatMultiplier,
    DateTime? completedAt,
  }) {
    return BodyProfile(
      name: name ?? this.name,
      sex: sex ?? this.sex,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      startingWeightKg: startingWeightKg ?? this.startingWeightKg,
      goalWeightKg: goalWeightKg ?? this.goalWeightKg,
      bodyFatPct: bodyFatPct ?? this.bodyFatPct,
      waistCm: waistCm ?? this.waistCm,
      neckCm: neckCm ?? this.neckCm,
      activityLevel: activityLevel ?? this.activityLevel,
      goalType: goalType ?? this.goalType,
      deficitKcal: deficitKcal ?? this.deficitKcal,
      dietType: dietType ?? this.dietType,
      wakeMinutes: wakeMinutes ?? this.wakeMinutes,
      workStartMinutes: workStartMinutes ?? this.workStartMinutes,
      workEndMinutes: workEndMinutes ?? this.workEndMinutes,
      proteinPreference: proteinPreference ?? this.proteinPreference,
      proteinMultiplier: proteinMultiplier ?? this.proteinMultiplier,
      fatMultiplier: fatMultiplier ?? this.fatMultiplier,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'sex': sex.name,
    'age': age,
    'heightCm': heightCm,
    'startingWeightKg': startingWeightKg,
    'goalWeightKg': goalWeightKg,
    'bodyFatPct': bodyFatPct,
    'waistCm': waistCm,
    'neckCm': neckCm,
    'activityLevel': activityLevel.name,
    'goalType': goalType.name,
    'deficitKcal': deficitKcal,
    'dietType': dietType.name,
    'wakeMinutes': wakeMinutes,
    'workStartMinutes': workStartMinutes,
    'workEndMinutes': workEndMinutes,
    'proteinPreference': proteinPreference.name,
    'proteinMultiplier': proteinMultiplier,
    'fatMultiplier': fatMultiplier,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory BodyProfile.fromJson(Map<String, dynamic> json) {
    return BodyProfile(
      name: json['name'] as String? ?? 'Divax',
      sex: _enumFromName(
        BiologicalSex.values,
        json['sex'] as String?,
        BiologicalSex.male,
      ),
      age: json['age'] as int? ?? 23,
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 160,
      startingWeightKg: (json['startingWeightKg'] as num?)?.toDouble() ?? 96,
      goalWeightKg: (json['goalWeightKg'] as num?)?.toDouble() ?? 80,
      bodyFatPct: (json['bodyFatPct'] as num?)?.toDouble(),
      waistCm: (json['waistCm'] as num?)?.toDouble(),
      neckCm: (json['neckCm'] as num?)?.toDouble(),
      activityLevel: _enumFromName(
        ActivityLevel.values,
        json['activityLevel'] as String?,
        ActivityLevel.veryActive,
      ),
      goalType: _enumFromName(
        GoalType.values,
        json['goalType'] as String?,
        GoalType.fatLoss,
      ),
      deficitKcal: json['deficitKcal'] as int? ?? 400,
      dietType: _enumFromName(
        DietType.values,
        json['dietType'] as String?,
        DietType.jainVegetarian,
      ),
      wakeMinutes: json['wakeMinutes'] as int? ?? 375,
      workStartMinutes: json['workStartMinutes'] as int? ?? 510,
      workEndMinutes: json['workEndMinutes'] as int? ?? 1080,
      proteinPreference: _enumFromName(
        ProteinPreference.values,
        json['proteinPreference'] as String?,
        ProteinPreference.aggressive,
      ),
      proteinMultiplier: (json['proteinMultiplier'] as num?)?.toDouble() ?? 2.0,
      fatMultiplier: (json['fatMultiplier'] as num?)?.toDouble() ?? 0.8,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.tryParse(json['completedAt'] as String),
    );
  }
}

class WeightLog {
  const WeightLog({
    required this.id,
    required this.date,
    required this.weightKg,
    this.notes,
  });

  final String id;
  final String date;
  final double weightKg;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'weightKg': weightKg,
    'notes': notes,
  };

  factory WeightLog.fromJson(Map<String, dynamic> json) => WeightLog(
    id: json['id'] as String,
    date: json['date'] as String,
    weightKg: (json['weightKg'] as num).toDouble(),
    notes: json['notes'] as String?,
  );
}

class FoodLogEntry {
  const FoodLogEntry({
    required this.id,
    required this.date,
    required this.mealSlot,
    required this.foodName,
    required this.quantityG,
    this.quantityUnit = FoodQuantityUnit.grams,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.source,
    this.description,
    this.sourceTitle,
  });

  final String id;
  final String date;
  final MealSlot mealSlot;
  final String foodName;
  final double quantityG;
  final FoodQuantityUnit quantityUnit;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final String source;
  final String? description;
  final String? sourceTitle;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'mealSlot': mealSlot.name,
    'foodName': foodName,
    'quantityG': quantityG,
    'quantityUnit': quantityUnit.name,
    'calories': calories,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatG': fatG,
    'fiberG': fiberG,
    'source': source,
    'description': description,
    'sourceTitle': sourceTitle,
  };

  factory FoodLogEntry.fromJson(Map<String, dynamic> json) => FoodLogEntry(
    id: json['id'] as String,
    date: json['date'] as String,
    mealSlot: _enumFromName(
      MealSlot.values,
      json['mealSlot'] as String?,
      MealSlot.breakfast,
    ),
    foodName: json['foodName'] as String,
    quantityG: ((json['quantity'] ?? json['quantityG']) as num).toDouble(),
    quantityUnit: _enumFromName(
      FoodQuantityUnit.values,
      json['quantityUnit'] as String?,
      FoodQuantityUnit.grams,
    ),
    calories: (json['calories'] as num).toDouble(),
    proteinG: (json['proteinG'] as num).toDouble(),
    carbsG: (json['carbsG'] as num).toDouble(),
    fatG: (json['fatG'] as num).toDouble(),
    fiberG: (json['fiberG'] as num).toDouble(),
    source: json['source'] as String? ?? 'manual',
    description: json['description'] as String?,
    sourceTitle: json['sourceTitle'] as String?,
  );
}

class CustomFood {
  const CustomFood({
    required this.id,
    required this.name,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.fiberPer100g,
    this.defaultServingG = 100,
    this.defaultServingUnit = FoodQuantityUnit.grams,
    this.isJainSafe = true,
    this.isFrequent = false,
  });

  final String id;
  final String name;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double fiberPer100g;
  final double defaultServingG;
  final FoodQuantityUnit defaultServingUnit;
  final bool isJainSafe;
  final bool isFrequent;

  CustomFood copyWith({
    String? id,
    String? name,
    double? caloriesPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatPer100g,
    double? fiberPer100g,
    double? defaultServingG,
    FoodQuantityUnit? defaultServingUnit,
    bool? isJainSafe,
    bool? isFrequent,
  }) {
    return CustomFood(
      id: id ?? this.id,
      name: name ?? this.name,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      fiberPer100g: fiberPer100g ?? this.fiberPer100g,
      defaultServingG: defaultServingG ?? this.defaultServingG,
      defaultServingUnit: defaultServingUnit ?? this.defaultServingUnit,
      isJainSafe: isJainSafe ?? this.isJainSafe,
      isFrequent: isFrequent ?? this.isFrequent,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'caloriesPer100g': caloriesPer100g,
    'proteinPer100g': proteinPer100g,
    'carbsPer100g': carbsPer100g,
    'fatPer100g': fatPer100g,
    'fiberPer100g': fiberPer100g,
    'defaultServingG': defaultServingG,
    'defaultServingUnit': defaultServingUnit.name,
    'isJainSafe': isJainSafe,
    'isFrequent': isFrequent,
  };

  factory CustomFood.fromJson(Map<String, dynamic> json) => CustomFood(
    id: json['id'] as String,
    name: json['name'] as String,
    caloriesPer100g: (json['caloriesPer100g'] as num).toDouble(),
    proteinPer100g: (json['proteinPer100g'] as num).toDouble(),
    carbsPer100g: (json['carbsPer100g'] as num).toDouble(),
    fatPer100g: (json['fatPer100g'] as num).toDouble(),
    fiberPer100g: (json['fiberPer100g'] as num).toDouble(),
    defaultServingG: (json['defaultServingG'] as num?)?.toDouble() ?? 100,
    defaultServingUnit: _enumFromName(
      FoodQuantityUnit.values,
      json['defaultServingUnit'] as String?,
      FoodQuantityUnit.grams,
    ),
    isJainSafe: json['isJainSafe'] as bool? ?? true,
    isFrequent: json['isFrequent'] as bool? ?? false,
  );
}

class WaterLog {
  const WaterLog({
    required this.id,
    required this.date,
    required this.amountMl,
  });

  final String id;
  final String date;
  final int amountMl;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'amountMl': amountMl,
  };

  factory WaterLog.fromJson(Map<String, dynamic> json) => WaterLog(
    id: json['id'] as String,
    date: json['date'] as String,
    amountMl: json['amountMl'] as int,
  );
}

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.date,
    required this.type,
    required this.durationMinutes,
    required this.caloriesBurned,
    this.muscleGroups = const [],
    this.notes,
  });

  final String id;
  final String date;
  final WorkoutType type;
  final List<String> muscleGroups;
  final int durationMinutes;
  final double caloriesBurned;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'type': type.name,
    'muscleGroups': muscleGroups,
    'durationMinutes': durationMinutes,
    'caloriesBurned': caloriesBurned,
    'notes': notes,
  };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
    id: json['id'] as String,
    date: json['date'] as String,
    type: _enumFromName(
      WorkoutType.values,
      json['type'] as String?,
      WorkoutType.custom,
    ),
    muscleGroups: List<String>.from(json['muscleGroups'] as List? ?? const []),
    durationMinutes: json['durationMinutes'] as int,
    caloriesBurned: (json['caloriesBurned'] as num).toDouble(),
    notes: json['notes'] as String?,
  );
}

class ExerciseSetLog {
  const ExerciseSetLog({
    required this.id,
    required this.sessionId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.setNumber,
    required this.reps,
    required this.weightKg,
    this.isWarmup = false,
    this.isFailure = false,
    this.isPr = false,
  });

  final String id;
  final String sessionId;
  final String exerciseName;
  final String muscleGroup;
  final int setNumber;
  final int reps;
  final double weightKg;
  final bool isWarmup;
  final bool isFailure;
  final bool isPr;

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'exerciseName': exerciseName,
    'muscleGroup': muscleGroup,
    'setNumber': setNumber,
    'reps': reps,
    'weightKg': weightKg,
    'isWarmup': isWarmup,
    'isFailure': isFailure,
    'isPr': isPr,
  };

  factory ExerciseSetLog.fromJson(Map<String, dynamic> json) => ExerciseSetLog(
    id: json['id'] as String,
    sessionId: json['sessionId'] as String,
    exerciseName: json['exerciseName'] as String,
    muscleGroup: json['muscleGroup'] as String? ?? '',
    setNumber: json['setNumber'] as int,
    reps: json['reps'] as int,
    weightKg: (json['weightKg'] as num).toDouble(),
    isWarmup: json['isWarmup'] as bool? ?? false,
    isFailure: json['isFailure'] as bool? ?? false,
    isPr: json['isPr'] as bool? ?? false,
  );
}

class BodyMeasurement {
  const BodyMeasurement({
    required this.id,
    required this.date,
    this.waistCm,
    this.neckCm,
    this.chestCm,
    this.leftArmCm,
    this.rightArmCm,
    this.leftThighCm,
    this.rightThighCm,
    this.bodyFatPct,
    this.notes,
  });

  final String id;
  final String date;
  final double? waistCm;
  final double? neckCm;
  final double? chestCm;
  final double? leftArmCm;
  final double? rightArmCm;
  final double? leftThighCm;
  final double? rightThighCm;
  final double? bodyFatPct;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'waistCm': waistCm,
    'neckCm': neckCm,
    'chestCm': chestCm,
    'leftArmCm': leftArmCm,
    'rightArmCm': rightArmCm,
    'leftThighCm': leftThighCm,
    'rightThighCm': rightThighCm,
    'bodyFatPct': bodyFatPct,
    'notes': notes,
  };

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) =>
      BodyMeasurement(
        id: json['id'] as String,
        date: json['date'] as String,
        waistCm: (json['waistCm'] as num?)?.toDouble(),
        neckCm: (json['neckCm'] as num?)?.toDouble(),
        chestCm: (json['chestCm'] as num?)?.toDouble(),
        leftArmCm: (json['leftArmCm'] as num?)?.toDouble(),
        rightArmCm: (json['rightArmCm'] as num?)?.toDouble(),
        leftThighCm: (json['leftThighCm'] as num?)?.toDouble(),
        rightThighCm: (json['rightThighCm'] as num?)?.toDouble(),
        bodyFatPct: (json['bodyFatPct'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
      );
}

class TargetUpdateNotice {
  const TargetUpdateNotice({
    required this.id,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String message;
  final String createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'message': message,
    'createdAt': createdAt,
  };

  factory TargetUpdateNotice.fromJson(Map<String, dynamic> json) =>
      TargetUpdateNotice(
        id: json['id'] as String,
        message: json['message'] as String,
        createdAt: json['createdAt'] as String,
      );
}

class ProgressPhoto {
  const ProgressPhoto({
    required this.id,
    required this.date,
    required this.angle,
    required this.path,
    this.notes,
  });

  final String id;
  final String date;
  final ProgressPhotoAngle angle;
  final String path;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'angle': angle.name,
    'path': path,
    'notes': notes,
  };

  factory ProgressPhoto.fromJson(Map<String, dynamic> json) => ProgressPhoto(
    id: json['id'] as String,
    date: json['date'] as String,
    angle: _enumFromName(
      ProgressPhotoAngle.values,
      json['angle'] as String?,
      ProgressPhotoAngle.front,
    ),
    path: json['path'] as String,
    notes: json['notes'] as String?,
  );
}

class AiSettings {
  const AiSettings({
    this.enabled = false,
    this.model = 'gemini-3.1-flash-lite-preview',
    this.apiKey = '',
    this.autoAdaptiveTargets = true,
    this.adaptiveLookbackCount = 5,
    this.adaptiveCadenceDays = 2,
    this.lastAdaptiveSyncAt,
    this.lastAdaptiveSummary,
  });

  final bool enabled;
  final String model;
  final String apiKey;
  final bool autoAdaptiveTargets;
  final int adaptiveLookbackCount;
  final int adaptiveCadenceDays;
  final String? lastAdaptiveSyncAt;
  final String? lastAdaptiveSummary;

  AiSettings copyWith({
    bool? enabled,
    String? model,
    String? apiKey,
    bool? autoAdaptiveTargets,
    int? adaptiveLookbackCount,
    int? adaptiveCadenceDays,
    String? lastAdaptiveSyncAt,
    String? lastAdaptiveSummary,
  }) {
    return AiSettings(
      enabled: enabled ?? this.enabled,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
      autoAdaptiveTargets: autoAdaptiveTargets ?? this.autoAdaptiveTargets,
      adaptiveLookbackCount:
          adaptiveLookbackCount ?? this.adaptiveLookbackCount,
      adaptiveCadenceDays: adaptiveCadenceDays ?? this.adaptiveCadenceDays,
      lastAdaptiveSyncAt: lastAdaptiveSyncAt ?? this.lastAdaptiveSyncAt,
      lastAdaptiveSummary: lastAdaptiveSummary ?? this.lastAdaptiveSummary,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'model': model,
    'apiKey': apiKey,
    'autoAdaptiveTargets': autoAdaptiveTargets,
    'adaptiveLookbackCount': adaptiveLookbackCount,
    'adaptiveCadenceDays': adaptiveCadenceDays,
    'lastAdaptiveSyncAt': lastAdaptiveSyncAt,
    'lastAdaptiveSummary': lastAdaptiveSummary,
  };

  factory AiSettings.fromJson(Map<String, dynamic> json) => AiSettings(
    enabled: json['enabled'] as bool? ?? false,
    model: json['model'] as String? ?? 'gemini-3.1-flash-lite-preview',
    apiKey: json['apiKey'] as String? ?? '',
    autoAdaptiveTargets: json['autoAdaptiveTargets'] as bool? ?? true,
    adaptiveLookbackCount: json['adaptiveLookbackCount'] as int? ?? 5,
    adaptiveCadenceDays: json['adaptiveCadenceDays'] as int? ?? 2,
    lastAdaptiveSyncAt: json['lastAdaptiveSyncAt'] as String?,
    lastAdaptiveSummary: json['lastAdaptiveSummary'] as String?,
  );
}

class NotificationPreferences {
  const NotificationPreferences({
    this.enabled = true,
    this.weighInEnabled = true,
    this.breakfastEnabled = true,
    this.lunchEnabled = true,
    this.dinnerEnabled = true,
    this.randomOneEnabled = true,
    this.randomTwoEnabled = true,
    this.weeklyCheckInEnabled = true,
    this.breakfastMinutes = 8 * 60,
    this.lunchMinutes = 13 * 60,
    this.dinnerMinutes = 20 * 60,
    this.randomOneMinutes = 10 * 60 + 45,
    this.randomTwoMinutes = 17 * 60 + 20,
    this.weeklyCheckInWeekday = DateTime.sunday,
    this.weeklyCheckInMinutes = 8 * 60,
  });

  final bool enabled;
  final bool weighInEnabled;
  final bool breakfastEnabled;
  final bool lunchEnabled;
  final bool dinnerEnabled;
  final bool randomOneEnabled;
  final bool randomTwoEnabled;
  final bool weeklyCheckInEnabled;
  final int breakfastMinutes;
  final int lunchMinutes;
  final int dinnerMinutes;
  final int randomOneMinutes;
  final int randomTwoMinutes;
  final int weeklyCheckInWeekday;
  final int weeklyCheckInMinutes;

  NotificationPreferences copyWith({
    bool? enabled,
    bool? weighInEnabled,
    bool? breakfastEnabled,
    bool? lunchEnabled,
    bool? dinnerEnabled,
    bool? randomOneEnabled,
    bool? randomTwoEnabled,
    bool? weeklyCheckInEnabled,
    int? breakfastMinutes,
    int? lunchMinutes,
    int? dinnerMinutes,
    int? randomOneMinutes,
    int? randomTwoMinutes,
    int? weeklyCheckInWeekday,
    int? weeklyCheckInMinutes,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      weighInEnabled: weighInEnabled ?? this.weighInEnabled,
      breakfastEnabled: breakfastEnabled ?? this.breakfastEnabled,
      lunchEnabled: lunchEnabled ?? this.lunchEnabled,
      dinnerEnabled: dinnerEnabled ?? this.dinnerEnabled,
      randomOneEnabled: randomOneEnabled ?? this.randomOneEnabled,
      randomTwoEnabled: randomTwoEnabled ?? this.randomTwoEnabled,
      weeklyCheckInEnabled: weeklyCheckInEnabled ?? this.weeklyCheckInEnabled,
      breakfastMinutes: breakfastMinutes ?? this.breakfastMinutes,
      lunchMinutes: lunchMinutes ?? this.lunchMinutes,
      dinnerMinutes: dinnerMinutes ?? this.dinnerMinutes,
      randomOneMinutes: randomOneMinutes ?? this.randomOneMinutes,
      randomTwoMinutes: randomTwoMinutes ?? this.randomTwoMinutes,
      weeklyCheckInWeekday: weeklyCheckInWeekday ?? this.weeklyCheckInWeekday,
      weeklyCheckInMinutes: weeklyCheckInMinutes ?? this.weeklyCheckInMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'weighInEnabled': weighInEnabled,
    'breakfastEnabled': breakfastEnabled,
    'lunchEnabled': lunchEnabled,
    'dinnerEnabled': dinnerEnabled,
    'randomOneEnabled': randomOneEnabled,
    'randomTwoEnabled': randomTwoEnabled,
    'weeklyCheckInEnabled': weeklyCheckInEnabled,
    'breakfastMinutes': breakfastMinutes,
    'lunchMinutes': lunchMinutes,
    'dinnerMinutes': dinnerMinutes,
    'randomOneMinutes': randomOneMinutes,
    'randomTwoMinutes': randomTwoMinutes,
    'weeklyCheckInWeekday': weeklyCheckInWeekday,
    'weeklyCheckInMinutes': weeklyCheckInMinutes,
  };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        enabled: json['enabled'] as bool? ?? true,
        weighInEnabled: json['weighInEnabled'] as bool? ?? true,
        breakfastEnabled: json['breakfastEnabled'] as bool? ?? true,
        lunchEnabled: json['lunchEnabled'] as bool? ?? true,
        dinnerEnabled: json['dinnerEnabled'] as bool? ?? true,
        randomOneEnabled: json['randomOneEnabled'] as bool? ?? true,
        randomTwoEnabled: json['randomTwoEnabled'] as bool? ?? true,
        weeklyCheckInEnabled: json['weeklyCheckInEnabled'] as bool? ?? true,
        breakfastMinutes: json['breakfastMinutes'] as int? ?? 8 * 60,
        lunchMinutes: json['lunchMinutes'] as int? ?? 13 * 60,
        dinnerMinutes: json['dinnerMinutes'] as int? ?? 20 * 60,
        randomOneMinutes: json['randomOneMinutes'] as int? ?? 10 * 60 + 45,
        randomTwoMinutes: json['randomTwoMinutes'] as int? ?? 17 * 60 + 20,
        weeklyCheckInWeekday:
            json['weeklyCheckInWeekday'] as int? ?? DateTime.sunday,
        weeklyCheckInMinutes: json['weeklyCheckInMinutes'] as int? ?? 8 * 60,
      );
}

class AppPreferences {
  const AppPreferences({
    this.themePreference = ThemePreference.system,
    this.measurementSystem = MeasurementSystem.metric,
    this.notifications = const NotificationPreferences(),
  });

  final ThemePreference themePreference;
  final MeasurementSystem measurementSystem;
  final NotificationPreferences notifications;

  AppPreferences copyWith({
    ThemePreference? themePreference,
    MeasurementSystem? measurementSystem,
    NotificationPreferences? notifications,
  }) {
    return AppPreferences(
      themePreference: themePreference ?? this.themePreference,
      measurementSystem: measurementSystem ?? this.measurementSystem,
      notifications: notifications ?? this.notifications,
    );
  }

  Map<String, dynamic> toJson() => {
    'themePreference': themePreference.name,
    'measurementSystem': measurementSystem.name,
    'notifications': notifications.toJson(),
  };

  factory AppPreferences.fromJson(Map<String, dynamic> json) => AppPreferences(
    themePreference: _enumFromName(
      ThemePreference.values,
      json['themePreference'] as String?,
      ThemePreference.system,
    ),
    measurementSystem: _enumFromName(
      MeasurementSystem.values,
      json['measurementSystem'] as String?,
      MeasurementSystem.metric,
    ),
    notifications: json['notifications'] == null
        ? const NotificationPreferences()
        : NotificationPreferences.fromJson(
            Map<String, dynamic>.from(json['notifications'] as Map),
          ),
  );
}

class ScannedFoodItem {
  const ScannedFoodItem({
    required this.name,
    required this.estimatedPortionG,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.confidence,
  });

  final String name;
  final double estimatedPortionG;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final String confidence;

  factory ScannedFoodItem.fromJson(Map<String, dynamic> json) =>
      ScannedFoodItem(
        name: _jsonStringOr(json['name'], 'Unknown'),
        estimatedPortionG: _jsonDoubleOr(
          json['estimated_portion_grams'] ?? json['estimatedPortionG'],
          100,
        ),
        calories: _jsonDoubleOr(json['calories'], 0),
        proteinG: _jsonDoubleOr(json['protein_g'], double.nan).isNaN
            ? _jsonDoubleOr(json['proteinG'], 0)
            : _jsonDoubleOr(json['protein_g'], 0),
        carbsG: _jsonDoubleOr(json['carbs_g'], double.nan).isNaN
            ? _jsonDoubleOr(json['carbsG'], 0)
            : _jsonDoubleOr(json['carbs_g'], 0),
        fatG: _jsonDoubleOr(json['fat_g'], double.nan).isNaN
            ? _jsonDoubleOr(json['fatG'], 0)
            : _jsonDoubleOr(json['fat_g'], 0),
        fiberG: _jsonDoubleOr(json['fiber_g'], double.nan).isNaN
            ? _jsonDoubleOr(json['fiberG'], 0)
            : _jsonDoubleOr(json['fiber_g'], 0),
        confidence: _jsonConfidenceOr(json['confidence'], 'medium'),
      );
}

class PackageLabelScanResult {
  const PackageLabelScanResult({
    required this.brand,
    required this.productName,
    required this.servingSize,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    this.ingredients,
  });

  final String brand;
  final String productName;
  final String servingSize;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final List<String>? ingredients;

  factory PackageLabelScanResult.fromJson(Map<String, dynamic> json) =>
      PackageLabelScanResult(
        brand: _jsonStringOr(json['brand'], ''),
        productName: _jsonStringOr(
          json['product_name'] ?? json['productName'],
          'Unknown product',
        ),
        servingSize: _jsonStringOr(
          json['serving_size'] ?? json['servingSize'],
          '1 serving',
        ),
        calories: _jsonDoubleOr(json['calories'], 0),
        proteinG: _jsonDoubleOr(json['protein_g'], double.nan).isNaN
            ? _jsonDoubleOr(json['proteinG'], 0)
            : _jsonDoubleOr(json['protein_g'], 0),
        carbsG: _jsonDoubleOr(json['carbs_g'], double.nan).isNaN
            ? _jsonDoubleOr(json['carbsG'], 0)
            : _jsonDoubleOr(json['carbs_g'], 0),
        fatG: _jsonDoubleOr(json['fat_g'], double.nan).isNaN
            ? _jsonDoubleOr(json['fatG'], 0)
            : _jsonDoubleOr(json['fat_g'], 0),
        fiberG: _jsonDoubleOr(json['fiber_g'], double.nan).isNaN
            ? _jsonDoubleOr(json['fiberG'], 0)
            : _jsonDoubleOr(json['fiber_g'], 0),
        ingredients: _jsonStringList(json['ingredients']),
      );
}

class AiInsight {
  const AiInsight({
    required this.id,
    required this.date,
    required this.text,
    required this.type,
    this.createdAt,
    this.contextHash,
  });

  final String id;
  final String date;
  final String text;
  final String type;
  final String? createdAt;
  final String? contextHash;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'text': text,
    'type': type,
    'createdAt': createdAt,
    'contextHash': contextHash,
  };

  factory AiInsight.fromJson(Map<String, dynamic> json) => AiInsight(
    id: json['id'] as String,
    date: json['date'] as String,
    text: json['text'] as String,
    type: json['type'] as String? ?? 'daily',
    createdAt: json['createdAt'] as String?,
    contextHash: json['contextHash'] as String?,
  );
}

class AppStateData {
  const AppStateData({
    required this.profile,
    required this.weightLogs,
    required this.bodyMeasurements,
    required this.foodLogs,
    required this.customFoods,
    required this.waterLogs,
    required this.workoutSessions,
    required this.exerciseSets,
    required this.aiInsights,
    required this.progressPhotos,
    required this.aiSettings,
    required this.preferences,
    this.targetUpdate,
  });

  final BodyProfile profile;
  final List<WeightLog> weightLogs;
  final List<BodyMeasurement> bodyMeasurements;
  final List<FoodLogEntry> foodLogs;
  final List<CustomFood> customFoods;
  final List<WaterLog> waterLogs;
  final List<WorkoutSession> workoutSessions;
  final List<ExerciseSetLog> exerciseSets;
  final List<AiInsight> aiInsights;
  final List<ProgressPhoto> progressPhotos;
  final AiSettings aiSettings;
  final AppPreferences preferences;
  final TargetUpdateNotice? targetUpdate;

  factory AppStateData.initial({List<CustomFood> seedFoods = const []}) =>
      AppStateData(
        profile: BodyProfile.defaults(),
        weightLogs: const [],
        bodyMeasurements: const [],
        foodLogs: const [],
        customFoods: seedFoods,
        waterLogs: const [],
        workoutSessions: const [],
        exerciseSets: const [],
        aiInsights: const [],
        progressPhotos: const [],
        aiSettings: const AiSettings(),
        preferences: const AppPreferences(),
      );

  AppStateData copyWith({
    BodyProfile? profile,
    List<WeightLog>? weightLogs,
    List<BodyMeasurement>? bodyMeasurements,
    List<FoodLogEntry>? foodLogs,
    List<CustomFood>? customFoods,
    List<WaterLog>? waterLogs,
    List<WorkoutSession>? workoutSessions,
    List<ExerciseSetLog>? exerciseSets,
    List<AiInsight>? aiInsights,
    List<ProgressPhoto>? progressPhotos,
    AiSettings? aiSettings,
    AppPreferences? preferences,
    TargetUpdateNotice? targetUpdate,
    bool clearTargetUpdate = false,
  }) {
    return AppStateData(
      profile: profile ?? this.profile,
      weightLogs: weightLogs ?? this.weightLogs,
      bodyMeasurements: bodyMeasurements ?? this.bodyMeasurements,
      foodLogs: foodLogs ?? this.foodLogs,
      customFoods: customFoods ?? this.customFoods,
      waterLogs: waterLogs ?? this.waterLogs,
      workoutSessions: workoutSessions ?? this.workoutSessions,
      exerciseSets: exerciseSets ?? this.exerciseSets,
      aiInsights: aiInsights ?? this.aiInsights,
      progressPhotos: progressPhotos ?? this.progressPhotos,
      aiSettings: aiSettings ?? this.aiSettings,
      preferences: preferences ?? this.preferences,
      targetUpdate: clearTargetUpdate
          ? null
          : targetUpdate ?? this.targetUpdate,
    );
  }

  Map<String, dynamic> toJson() => {
    'profile': profile.toJson(),
    'weightLogs': weightLogs.map((item) => item.toJson()).toList(),
    'bodyMeasurements': bodyMeasurements.map((item) => item.toJson()).toList(),
    'foodLogs': foodLogs.map((item) => item.toJson()).toList(),
    'customFoods': customFoods.map((item) => item.toJson()).toList(),
    'waterLogs': waterLogs.map((item) => item.toJson()).toList(),
    'workoutSessions': workoutSessions.map((item) => item.toJson()).toList(),
    'exerciseSets': exerciseSets.map((item) => item.toJson()).toList(),
    'aiInsights': aiInsights.map((item) => item.toJson()).toList(),
    'progressPhotos': progressPhotos.map((item) => item.toJson()).toList(),
    'aiSettings': aiSettings.toJson(),
    'preferences': preferences.toJson(),
    'targetUpdate': targetUpdate?.toJson(),
  };

  factory AppStateData.fromJson(Map<String, dynamic> json) => AppStateData(
    profile: BodyProfile.fromJson(
      Map<String, dynamic>.from(json['profile'] as Map),
    ),
    weightLogs: ((json['weightLogs'] as List?) ?? const [])
        .map(
          (item) => WeightLog.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    bodyMeasurements: ((json['bodyMeasurements'] as List?) ?? const [])
        .map(
          (item) =>
              BodyMeasurement.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    foodLogs: ((json['foodLogs'] as List?) ?? const [])
        .map(
          (item) =>
              FoodLogEntry.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    customFoods: ((json['customFoods'] as List?) ?? const [])
        .map(
          (item) => CustomFood.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    waterLogs: ((json['waterLogs'] as List?) ?? const [])
        .map(
          (item) => WaterLog.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    workoutSessions: ((json['workoutSessions'] as List?) ?? const [])
        .map(
          (item) =>
              WorkoutSession.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    exerciseSets: ((json['exerciseSets'] as List?) ?? const [])
        .map(
          (item) =>
              ExerciseSetLog.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    aiInsights: ((json['aiInsights'] as List?) ?? const [])
        .map(
          (item) => AiInsight.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    progressPhotos: ((json['progressPhotos'] as List?) ?? const [])
        .map(
          (item) =>
              ProgressPhoto.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    aiSettings: json['aiSettings'] == null
        ? const AiSettings()
        : AiSettings.fromJson(
            Map<String, dynamic>.from(json['aiSettings'] as Map),
          ),
    preferences: json['preferences'] == null
        ? const AppPreferences()
        : AppPreferences.fromJson(
            Map<String, dynamic>.from(json['preferences'] as Map),
          ),
    targetUpdate: json['targetUpdate'] == null
        ? null
        : TargetUpdateNotice.fromJson(
            Map<String, dynamic>.from(json['targetUpdate'] as Map),
          ),
  );
}

class DailyNutritionTotals {
  const DailyNutritionTotals({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
}

class NutritionTargets {
  const NutritionTargets({
    required this.weightKg,
    required this.bmr,
    required this.tdee,
    required this.calorieGoal,
    required this.proteinGoal,
    required this.fatGoal,
    required this.carbGoal,
    required this.fiberGoal,
    required this.bmi,
    required this.bmiCategory,
    this.bodyFatPct,
    this.leanBodyMassKg,
    this.fatMassKg,
    this.ffmi,
  });

  final double weightKg;
  final double bmr;
  final double tdee;
  final double calorieGoal;
  final double proteinGoal;
  final double fatGoal;
  final double carbGoal;
  final double fiberGoal;
  final double bmi;
  final String bmiCategory;
  final double? bodyFatPct;
  final double? leanBodyMassKg;
  final double? fatMassKg;
  final double? ffmi;
}
