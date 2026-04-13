import 'dart:math' as math;

import '../data/models.dart';

class CalculationsEngine {
  static double currentWeight(BodyProfile profile, List<WeightLog> logs) {
    if (logs.isEmpty) {
      return profile.startingWeightKg;
    }
    final sorted = [...logs]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.first.weightKg;
  }

  static NutritionTargets targetsFor(
    BodyProfile profile,
    List<WeightLog> weightLogs,
  ) {
    final weightKg = currentWeight(profile, weightLogs);
    final bmr = profile.sex == BiologicalSex.male
        ? (10 * weightKg) + (6.25 * profile.heightCm) - (5 * profile.age) + 5
        : (10 * weightKg) + (6.25 * profile.heightCm) - (5 * profile.age) - 161;
    final tdee = bmr * profile.activityLevel.multiplier;

    double calorieGoal = tdee;
    if (profile.goalType == GoalType.fatLoss) {
      calorieGoal -= profile.deficitKcal;
    } else if (profile.goalType == GoalType.muscleGain) {
      calorieGoal += 250;
    }

    final proteinGoal = weightKg * profile.proteinMultiplier;
    final fatGoal = weightKg * profile.fatMultiplier;
    final proteinCalories = proteinGoal * 4.0;
    final fatCalories = fatGoal * 9.0;
    final remainingCalories = calorieGoal - proteinCalories - fatCalories;
    final carbGoal = remainingCalories > 0 ? remainingCalories / 4.0 : 0.0;
    final bmi =
        weightKg / ((profile.heightCm / 100) * (profile.heightCm / 100));

    final bodyFatPct = profile.bodyFatPct ?? _navyBodyFat(profile);
    final leanBodyMass = bodyFatPct == null
        ? null
        : weightKg * (1 - bodyFatPct / 100);
    final fatMass = bodyFatPct == null ? null : weightKg * (bodyFatPct / 100);
    final ffmi = leanBodyMass == null
        ? null
        : leanBodyMass / ((profile.heightCm / 100) * (profile.heightCm / 100));

    return NutritionTargets(
      weightKg: weightKg,
      bmr: bmr,
      tdee: tdee,
      calorieGoal: calorieGoal,
      proteinGoal: proteinGoal,
      fatGoal: fatGoal,
      carbGoal: carbGoal,
      fiberGoal: 35.0,
      bmi: bmi,
      bmiCategory: _bmiCategory(bmi),
      bodyFatPct: bodyFatPct,
      leanBodyMassKg: leanBodyMass,
      fatMassKg: fatMass,
      ffmi: ffmi,
    );
  }

  static DailyNutritionTotals totalsForDay(
    List<FoodLogEntry> entries,
    String date,
  ) {
    final todayEntries = entries.where((entry) => entry.date == date);
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    double fiber = 0;
    for (final entry in todayEntries) {
      calories += entry.calories;
      protein += entry.proteinG;
      carbs += entry.carbsG;
      fat += entry.fatG;
      fiber += entry.fiberG;
    }
    return DailyNutritionTotals(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
    );
  }

  static double workoutCalories({
    required double weightKg,
    required int durationMinutes,
    required double met,
  }) {
    return met * weightKg * (durationMinutes / 60);
  }

  static double waterTargetLiters(List<WorkoutSession> sessions, String date) {
    final hasWorkout = sessions.any(
      (session) => session.date == date && session.type != WorkoutType.rest,
    );
    return hasWorkout ? 3.5 : 2.5;
  }

  static String bmiCategory(double bmi) => _bmiCategory(bmi);

  static String _bmiCategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    }
    if (bmi < 25) {
      return 'Normal';
    }
    if (bmi < 30) {
      return 'Overweight';
    }
    return 'Obese';
  }

  static double? _navyBodyFat(BodyProfile profile) {
    if (profile.sex != BiologicalSex.male) {
      return profile.bodyFatPct;
    }
    if (profile.waistCm == null || profile.neckCm == null) {
      return null;
    }
    final waist = profile.waistCm!;
    final neck = profile.neckCm!;
    if (waist <= neck || profile.heightCm <= 0) {
      return null;
    }
    final result =
        495 /
            (1.0324 -
                0.19077 * (math.log(waist - neck) / math.ln10) +
                0.15456 * (math.log(profile.heightCm) / math.ln10)) -
        450;
    if (result.isNaN || result.isInfinite) {
      return null;
    }
    return result.clamp(4, 60).toDouble();
  }
}
