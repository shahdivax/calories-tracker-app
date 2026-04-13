import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../data/models.dart';
import 'calculations.dart';

const _geminiRestModel = 'gemini-3.1-flash-lite-preview';
const Duration _geminiHttpTimeout = Duration(seconds: 45);
const Duration _geminiStreamFirstByteTimeout = Duration(seconds: 45);

const _assistantScopePolicy = '''
Scope policy:
- Only answer topics related to MacroCheck AI features, nutrition, food tracking, macros, calories, hydration, habits, exercise, and gym/fitness guidance.
- If the user asks anything outside this scope (for example celebrities, politics, coding, history, or general trivia), politely decline in 1 short sentence and redirect to a relevant health/fitness topic.
- Never provide off-topic answers, even if asked directly.
''';

String _formatGeminiHttpError(int statusCode, String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final err = decoded['error'];
      if (err is Map<String, dynamic>) {
        final msg = err['message'] as String?;
        final status = err['status'] as String?;
        if (msg != null && msg.isNotEmpty) {
          if (status != null && status.isNotEmpty) {
            return '$msg ($status)';
          }
          return msg;
        }
      }
    }
  } catch (_) {}
  return 'Gemini API error: HTTP $statusCode';
}

String _formatGeminiTransportError(Object error) {
  if (error is TimeoutException) {
    return 'Gemini request timed out. Check your connection and try again.';
  }
  if (error is http.ClientException) {
    final message = error.message.toLowerCase();
    if (message.contains('failed host lookup') ||
        message.contains('socketexception') ||
        message.contains('connection closed')) {
      return 'Could not reach Gemini. Check internet access and try again.';
    }
    return 'Could not connect to Gemini. Check internet access and try again.';
  }
  if (error is SocketException) {
    return 'Could not reach Gemini. Check internet access and try again.';
  }
  return 'Gemini request failed. Try again.';
}

abstract class AiRuntimeService {
  Future<String> testConnection(AiSettings settings);
  Future<String> generateInsight(
    AppStateData data, {
    String checkInLabel = 'current dashboard check-in',
  });
  Future<String> generateMetricsInsight(
    AppStateData data, {
    required String weekEnding,
  });
  Future<String> generateDeepAnalytics(AppStateData data);
  Future<AdaptiveTargetRecommendation> recommendAdaptiveTargets({
    required AppStateData data,
    required int lookbackCount,
  });
  Future<WorkoutCalorieEstimate> estimateWorkoutSession({
    required AppStateData data,
    required WorkoutType workoutType,
    required int durationMinutes,
    required double fallbackMet,
    required List<Map<String, dynamic>> exercises,
    String? notes,
  });
  Future<ScannedFoodItem> estimateFoodFromText({
    required AppStateData data,
    required String foodName,
    required double quantity,
    required FoodQuantityUnit quantityUnit,
    String? entryTitle,
    String? foodDescription,
    bool preferHighSide = false,
  });
  Future<List<ScannedFoodItem>> analyzeFoodPhoto({
    required AppStateData data,
    required Uint8List bytes,
    required String mimeType,
    String? scanTitle,
    String? foodDescription,
  });
  Future<PackageLabelScanResult> analyzePackageLabel({
    required AppStateData data,
    required Uint8List bytes,
    required String mimeType,
    String? scanTitle,
  });
}

class WorkoutCalorieEstimate {
  const WorkoutCalorieEstimate({
    required this.caloriesBurned,
    required this.met,
    required this.summary,
  });

  final double caloriesBurned;
  final double met;
  final String summary;

  factory WorkoutCalorieEstimate.fromJson(Map<String, dynamic> json) {
    final caloriesRaw = json['calories_burned'] ?? json['caloriesBurned'];
    final metRaw = json['met'] ?? json['estimated_met'];
    final summary = json['summary']?.toString().trim() ?? '';
    return WorkoutCalorieEstimate(
      caloriesBurned: caloriesRaw is num
          ? caloriesRaw.toDouble()
          : double.tryParse(caloriesRaw?.toString() ?? '') ?? 0,
      met: metRaw is num
          ? metRaw.toDouble()
          : double.tryParse(metRaw?.toString() ?? '') ?? 5.0,
      summary: summary.isEmpty
          ? 'Workout burn estimated from profile and session details.'
          : summary,
    );
  }
}

class AdaptiveTargetRecommendation {
  const AdaptiveTargetRecommendation({
    required this.activityLevel,
    required this.deficitKcal,
    required this.proteinMultiplier,
    required this.fatMultiplier,
    required this.summary,
  });

  final ActivityLevel activityLevel;
  final int deficitKcal;
  final double proteinMultiplier;
  final double fatMultiplier;
  final String summary;

  factory AdaptiveTargetRecommendation.fromJson(Map<String, dynamic> json) {
    final activityName = (json['activity_level'] ?? json['activityLevel'] ?? '')
        .toString()
        .trim();
    final activityLevel = ActivityLevel.values.firstWhere(
      (value) => value.name == activityName,
      orElse: () => ActivityLevel.moderatelyActive,
    );
    final deficitRaw = json['deficit_kcal'] ?? json['deficitKcal'];
    final proteinRaw = json['protein_multiplier'] ?? json['proteinMultiplier'];
    final fatRaw = json['fat_multiplier'] ?? json['fatMultiplier'];
    final summaryText = json['summary']?.toString().trim() ?? '';
    return AdaptiveTargetRecommendation(
      activityLevel: activityLevel,
      deficitKcal: deficitRaw is num
          ? deficitRaw.round()
          : int.tryParse(deficitRaw?.toString() ?? '') ?? 400,
      proteinMultiplier: proteinRaw is num
          ? proteinRaw.toDouble()
          : double.tryParse(proteinRaw?.toString() ?? '') ?? 2.0,
      fatMultiplier: fatRaw is num
          ? fatRaw.toDouble()
          : double.tryParse(fatRaw?.toString() ?? '') ?? 0.8,
      summary: summaryText.isEmpty
          ? 'Adaptive targets refreshed from recent training, food, and weight data.'
          : summaryText,
    );
  }
}

class GeminiRestAiRuntimeService implements AiRuntimeService {
  @override
  Future<String> testConnection(AiSettings settings) async {
    final apiKey = _apiKey(settings);
    if (apiKey == null) {
      throw StateError(
        'Gemini API key is missing or AI is disabled. Enable AI and save a key first.',
      );
    }
    final model = _resolvedModel(settings);
    final response = await _callGemini(
      apiKey,
      model,
      [
        {
          'text':
              'Reply with exactly this JSON: {"status":"ok","message":"Gemini connection verified."}',
        },
      ],
      temperature: 0,
      maxTokens: 64,
    );
    final decoded = jsonDecode(_extractJson(response));
    if (decoded is! Map<String, dynamic>) {
      return 'Gemini responded, but the payload was not structured.';
    }
    final message = decoded['message']?.toString().trim() ?? '';
    return message.isEmpty ? 'Gemini connection verified for $model.' : message;
  }

  @override
  Future<WorkoutCalorieEstimate> estimateWorkoutSession({
    required AppStateData data,
    required WorkoutType workoutType,
    required int durationMinutes,
    required double fallbackMet,
    required List<Map<String, dynamic>> exercises,
    String? notes,
  }) async {
    final apiKey = _apiKey(data.aiSettings);
    if (apiKey == null) {
      throw StateError(
        'Gemini API key is missing. Set it in Settings before using AI workout estimation.',
      );
    }
    final model = _resolvedModel(data.aiSettings);
    final currentWeight = CalculationsEngine.currentWeight(
      data.profile,
      data.weightLogs,
    );
    final recentWorkouts = [...data.workoutSessions]
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentWeightLogs = [...data.weightLogs]
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentDays = List.generate(
      5,
      (index) => dayKey(DateTime.now().subtract(Duration(days: index))),
    );
    final recentNutrition = recentDays
        .map(
          (date) => {
            'date': date,
            'totals': {
              'calories': CalculationsEngine.totalsForDay(
                data.foodLogs,
                date,
              ).calories,
              'protein': CalculationsEngine.totalsForDay(
                data.foodLogs,
                date,
              ).protein,
            },
          },
        )
        .toList();

    final prompt =
        '''
$_assistantScopePolicy

You are estimating realistic workout calorie burn for a fitness tracking app.

User profile:
- Name: ${data.profile.name}
- Sex: ${data.profile.sex.label}
- Age: ${data.profile.age}
- Height: ${data.profile.heightCm} cm
- Current weight: ${currentWeight.toStringAsFixed(1)} kg
- Goal: ${data.profile.goalType.label}
- Activity level: ${data.profile.activityLevel.label}

Recent weight logs:
${jsonEncode(recentWeightLogs.take(5).map((item) => item.toJson()).toList())}

Recent workout sessions:
${jsonEncode(recentWorkouts.take(5).map((item) => item.toJson()).toList())}

Recent nutrition days:
${jsonEncode(recentNutrition)}

Current planned session:
- Type: ${workoutType.label}
- Duration: $durationMinutes minutes
- Fallback MET: ${fallbackMet.toStringAsFixed(1)}
${_optionalPromptLine('Notes', notes)}
- Exercises: ${jsonEncode(exercises)}

Return ONLY valid JSON with:
- calories_burned
- met
- summary

Rules:
- Be realistic, not inflated.
- Consider rest periods and actual strength-training burn, not just nonstop motion.
- calories_burned must be between 40 and 2000.
- met must be between 2.0 and 14.0.
- summary must be one short sentence.
''';

    final response = await _callGemini(
      apiKey,
      model,
      [
        {'text': prompt},
      ],
      temperature: 0.1,
      maxTokens: 512,
    );
    final decoded = jsonDecode(_extractJson(response));
    return WorkoutCalorieEstimate.fromJson(
      Map<String, dynamic>.from(decoded as Map),
    );
  }

  @override
  Future<ScannedFoodItem> estimateFoodFromText({
    required AppStateData data,
    required String foodName,
    required double quantity,
    required FoodQuantityUnit quantityUnit,
    String? entryTitle,
    String? foodDescription,
    bool preferHighSide = false,
  }) async {
    final apiKey = _apiKey(data.aiSettings);
    if (apiKey == null) {
      throw StateError(
        'Gemini API key is missing. Set it in Settings before using AI nutrition estimation.',
      );
    }
    final model = _resolvedModel(data.aiSettings);

    final prompt =
        '''
$_assistantScopePolicy

You are a conservative nutrition estimator for Indian home food and gym meals.
Estimate the nutrition for exactly this food entry:
- Food: $foodName
- Quantity: ${quantity.toStringAsFixed(quantity == quantity.roundToDouble() ? 0 : 1)} ${quantityUnit.shortLabel}
${_optionalPromptLine('Entry title', entryTitle)}
${_optionalPromptLine('Description', foodDescription)}

Rules:
- Return ONLY valid JSON.
- Use realistic Indian portion assumptions.
- If the item is ambiguous, choose a mid-to-high calorie estimate, not a lowball estimate.
- If description or title adds ingredient or preparation detail, use it as strong context.
- For liquids like shakes, lassi, milk, or juices, treat quantity in ml.
- For solids, treat quantity in g unless clearly a liquid.
- If the unit is count/no., treat it as number of pieces, items, servings, or units.
- Include these keys:
  - name
  - estimated_portion_grams
  - calories
  - protein_g
  - carbs_g
  - fat_g
  - fiber_g
  - confidence
- `estimated_portion_grams` should equal the exact entered quantity as a number, even if the quantity unit is ml or count.
- Keep the estimate slightly conservative on the higher side: ${preferHighSide ? 'yes, bias to mid-high realistic calories.' : 'normal conservative estimate.'}
''';

    final response = await _callGemini(
      apiKey,
      model,
      [
        {'text': prompt},
      ],
      temperature: 0.1,
      maxTokens: 512,
    );
    final decoded = jsonDecode(_extractJson(response));
    return ScannedFoodItem.fromJson(Map<String, dynamic>.from(decoded as Map));
  }

  @override
  Future<String> generateInsight(
    AppStateData data, {
    String checkInLabel = 'current dashboard check-in',
  }) async {
    final fallback = _fallbackInsight(data);
    final apiKey = _apiKey(data.aiSettings);
    if (apiKey == null) {
      return fallback;
    }
    final model = _resolvedModel(data.aiSettings);

    final targets = CalculationsEngine.targetsFor(
      data.profile,
      data.weightLogs,
    );
    final today = dayKey();
    final todayNutrition = CalculationsEngine.totalsForDay(
      data.foodLogs,
      today,
    );
    final recentDays = List.generate(
      7,
      (index) => dayKey(DateTime.now().subtract(Duration(days: index))),
    );
    final last7 = recentDays
        .map(
          (day) => {
            'date': day,
            'calories': CalculationsEngine.totalsForDay(
              data.foodLogs,
              day,
            ).calories,
            'protein': CalculationsEngine.totalsForDay(
              data.foodLogs,
              day,
            ).protein,
            'weight': data.weightLogs
                .where((item) => item.date == day)
                .map((item) => item.weightKg)
                .cast<double?>()
                .firstWhere((value) => true, orElse: () => null),
          },
        )
        .toList();
    final workoutSummary = data.workoutSessions
        .where((item) => item.date == today)
        .map((item) => item.type.label)
        .join(', ');
    final waterMl = data.waterLogs
        .where((item) => item.date == today)
        .fold<int>(0, (sum, item) => sum + item.amountMl);
    final meals = data.foodLogs
        .where((item) => item.date == today)
        .map(
          (item) => {
            'slot': item.mealSlot.label,
            'food': item.foodName,
            'calories': item.calories.round(),
            'protein': item.proteinG.round(),
          },
        )
        .toList();

    final prompt =
        '''
$_assistantScopePolicy

You are a direct, data-driven fitness coach.
Check-in timing: $checkInLabel.
User profile:
- Name: ${data.profile.name}
- Sex: ${data.profile.sex.label}
- Height: ${data.profile.heightCm} cm
- Current weight: ${targets.weightKg.toStringAsFixed(1)} kg
- Goal weight: ${data.profile.goalWeightKg.toStringAsFixed(1)} kg
- Diet: ${data.profile.dietType.label}
- Goal: ${data.profile.goalType.label}
- Protein goal: ${targets.proteinGoal.toStringAsFixed(0)}g

Last 7 days summary:
${jsonEncode(last7)}

Today:
- Calories: ${todayNutrition.calories.toStringAsFixed(0)} / ${targets.calorieGoal.toStringAsFixed(0)}
- Protein: ${todayNutrition.protein.toStringAsFixed(0)} / ${targets.proteinGoal.toStringAsFixed(0)}
- Water: ${(waterMl / 1000).toStringAsFixed(1)} L
- Workout: ${workoutSummary.isEmpty ? 'none' : workoutSummary}
- Meals logged: ${jsonEncode(meals)}

Return exactly 2 complete sentences. Use the logged data, mention the most important next action, and make it a playful cynical roast. Be funny and blunt, not cruel, use plain text only, and do not claim live monitoring.
''';

    try {
      final response = await _callGemini(
        apiKey,
        model,
        [
          {'text': prompt},
        ],
        temperature: 0.3,
        maxTokens: 384,
      );
      return _normalizeTwoSentenceAnalysis(response, fallback);
    } catch (_) {
      return fallback;
    }
  }

  @override
  Future<String> generateMetricsInsight(
    AppStateData data, {
    required String weekEnding,
  }) async {
    final fallback = _fallbackMetricsInsight(data, weekEnding);
    final apiKey = _apiKey(data.aiSettings);
    if (apiKey == null) {
      return fallback;
    }
    final model = _resolvedModel(data.aiSettings);
    final weekEndDate = parseDayKey(weekEnding);
    final weekDays = List.generate(
      7,
      (index) => dayKey(weekEndDate.subtract(Duration(days: 6 - index))),
    );
    final targets = CalculationsEngine.targetsFor(
      data.profile,
      data.weightLogs,
    );
    final nutrition = [
      for (final day in weekDays)
        {
          'date': day,
          'calories': CalculationsEngine.totalsForDay(
            data.foodLogs,
            day,
          ).calories.round(),
          'protein': CalculationsEngine.totalsForDay(
            data.foodLogs,
            day,
          ).protein.round(),
        },
    ];
    final weights = data.weightLogs
        .where((item) => weekDays.contains(item.date))
        .map((item) => {'date': item.date, 'weightKg': item.weightKg})
        .toList();
    final measurements = data.bodyMeasurements
        .where((item) => weekDays.contains(item.date))
        .map(
          (item) => {
            'date': item.date,
            'waistCm': item.waistCm,
            'neckCm': item.neckCm,
            'bodyFatPct': item.bodyFatPct,
          },
        )
        .toList();
    final workouts = data.workoutSessions
        .where((item) => weekDays.contains(item.date))
        .map(
          (item) => {
            'date': item.date,
            'type': item.type.label,
            'minutes': item.durationMinutes,
            'caloriesBurned': item.caloriesBurned.round(),
          },
        )
        .toList();
    final photoCount = data.progressPhotos
        .where((item) => weekDays.contains(item.date))
        .length;

    final prompt =
        '''
$_assistantScopePolicy

You are a direct, data-driven fitness coach writing a weekly body-metrics check-in.
Week ending: $weekEnding (Saturday end).
User profile:
- Name: ${data.profile.name}
- Current calculated weight: ${targets.weightKg.toStringAsFixed(1)} kg
- Goal weight: ${data.profile.goalWeightKg.toStringAsFixed(1)} kg
- Goal: ${data.profile.goalType.label}
- Body-fat estimate: ${targets.bodyFatPct?.toStringAsFixed(1) ?? 'unknown'}%

Weekly nutrition:
${jsonEncode(nutrition)}

Weekly weight logs:
${jsonEncode(weights)}

Weekly measurements:
${jsonEncode(measurements)}

Weekly workouts:
${jsonEncode(workouts)}

Progress photos this week: $photoCount

Return exactly 2 complete sentences. Explain the trend and the next adjustment for the coming week in a playful cynical roast style. Be funny and blunt, not cruel, and use plain text only.
''';

    try {
      final response = await _callGemini(
        apiKey,
        model,
        [
          {'text': prompt},
        ],
        temperature: 0.25,
        maxTokens: 384,
      );
      return _normalizeTwoSentenceAnalysis(response, fallback);
    } catch (_) {
      return fallback;
    }
  }

  @override
  Future<String> generateDeepAnalytics(AppStateData data) async {
    final fallback = _fallbackDeepAnalytics(data);
    final apiKey = _apiKey(data.aiSettings);
    if (apiKey == null) {
      return fallback;
    }
    final model = _resolvedModel(data.aiSettings);
    final targets = CalculationsEngine.targetsFor(
      data.profile,
      data.weightLogs,
    );
    final recentDays = List.generate(
      30,
      (index) => dayKey(DateTime.now().subtract(Duration(days: 29 - index))),
    );
    final nutrition = [
      for (final day in recentDays)
        {
          'date': day,
          'calories': CalculationsEngine.totalsForDay(
            data.foodLogs,
            day,
          ).calories.round(),
          'protein': CalculationsEngine.totalsForDay(
            data.foodLogs,
            day,
          ).protein.round(),
        },
    ];
    final workouts = data.workoutSessions
        .where((item) => recentDays.contains(item.date))
        .map(
          (item) => {
            'date': item.date,
            'type': item.type.label,
            'minutes': item.durationMinutes,
            'burned': item.caloriesBurned.round(),
          },
        )
        .toList();
    final weights = data.weightLogs
        .where((item) => recentDays.contains(item.date))
        .map((item) => {'date': item.date, 'weightKg': item.weightKg})
        .toList();
    final water = [
      for (final day in recentDays)
        {
          'date': day,
          'ml': data.waterLogs
              .where((item) => item.date == day)
              .fold<int>(0, (sum, item) => sum + item.amountMl),
        },
    ];

    final prompt =
        '''
$_assistantScopePolicy

You are the app's deep analytics coach. Produce a premium 30-day analytics readout that is actually based on the data below.
User:
- Name: ${data.profile.name}
- Current weight: ${targets.weightKg.toStringAsFixed(1)} kg
- Goal weight: ${data.profile.goalWeightKg.toStringAsFixed(1)} kg
- Calorie goal: ${targets.calorieGoal.toStringAsFixed(0)}
- Protein goal: ${targets.proteinGoal.toStringAsFixed(0)}g
- Goal: ${data.profile.goalType.label}

30-day nutrition:
${jsonEncode(nutrition)}

30-day water:
${jsonEncode(water)}

30-day workouts:
${jsonEncode(workouts)}

30-day weights:
${jsonEncode(weights)}

Return exactly 2 complete sentences. Include one real pattern, one next action, and make it a playful cynical roast. Be funny and blunt, not cruel, and use plain text only.
''';

    try {
      final response = await _callGemini(
        apiKey,
        model,
        [
          {'text': prompt},
        ],
        temperature: 0.35,
        maxTokens: 384,
      );
      return _normalizeTwoSentenceAnalysis(response, fallback);
    } catch (_) {
      return fallback;
    }
  }

  @override
  Future<AdaptiveTargetRecommendation> recommendAdaptiveTargets({
    required AppStateData data,
    required int lookbackCount,
  }) async {
    final apiKey = _apiKey(data.aiSettings);
    if (apiKey == null) {
      throw StateError(
        'Gemini API key is missing. Set it in Settings before using adaptive targets.',
      );
    }
    final model = _resolvedModel(data.aiSettings);
    final recentWeights = [...data.weightLogs]
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentWorkouts = [...data.workoutSessions]
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentDays = List.generate(
      lookbackCount,
      (index) => dayKey(DateTime.now().subtract(Duration(days: index))),
    );
    final recentNutrition = recentDays
        .map(
          (date) => {
            'date': date,
            'totals': {
              'calories': CalculationsEngine.totalsForDay(
                data.foodLogs,
                date,
              ).calories,
              'protein': CalculationsEngine.totalsForDay(
                data.foodLogs,
                date,
              ).protein,
              'carbs': CalculationsEngine.totalsForDay(
                data.foodLogs,
                date,
              ).carbs,
              'fat': CalculationsEngine.totalsForDay(data.foodLogs, date).fat,
            },
          },
        )
        .toList();

    final prompt =
        '''
$_assistantScopePolicy

You are tuning a fitness app's daily targets from recent user data.
User profile:
- Sex: ${data.profile.sex.label}
- Age: ${data.profile.age}
- Height: ${data.profile.heightCm} cm
- Goal: ${data.profile.goalType.label}
- Diet: ${data.profile.dietType.label}
- Current activity level: ${data.profile.activityLevel.label}
- Current deficit: ${data.profile.deficitKcal}
- Current protein multiplier: ${data.profile.proteinMultiplier}
- Current fat multiplier: ${data.profile.fatMultiplier}

Recent weight logs:
${jsonEncode(recentWeights.take(lookbackCount).map((item) => item.toJson()).toList())}

Recent workout sessions:
${jsonEncode(recentWorkouts.take(lookbackCount).map((item) => item.toJson()).toList())}

Recent nutrition days:
${jsonEncode(recentNutrition)}

Return ONLY valid JSON with:
- activity_level
- deficit_kcal
- protein_multiplier
- fat_multiplier
- summary

Rules:
- Keep it conservative, practical, and realistic.
- deficit_kcal must be 0 to 900.
- protein_multiplier must be 1.2 to 2.8.
- fat_multiplier must be 0.5 to 1.2.
- activity_level must be one of: sedentary, lightlyActive, moderatelyActive, veryActive, athlete.
- summary should be one short sentence describing why the adjustment changed or stayed steady.
''';

    final response = await _callGemini(
      apiKey,
      model,
      [
        {'text': prompt},
      ],
      temperature: 0.1,
      maxTokens: 512,
    );
    final decoded = jsonDecode(_extractJson(response));
    return AdaptiveTargetRecommendation.fromJson(
      Map<String, dynamic>.from(decoded as Map),
    );
  }

  @override
  Future<List<ScannedFoodItem>> analyzeFoodPhoto({
    required AppStateData data,
    required Uint8List bytes,
    required String mimeType,
    String? scanTitle,
    String? foodDescription,
  }) async {
    final apiKey = _apiKey(data.aiSettings);
    if (apiKey == null) {
      throw StateError(
        'Gemini API key is missing. Set it in Settings before using AI scan.',
      );
    }
    final model = _resolvedModel(data.aiSettings);

    final prompt =
        '''
$_assistantScopePolicy

You are a precise nutritionist AI. Analyze this meal photo.
${_optionalPromptLine('User title', scanTitle)}
${_optionalPromptLine('User description', foodDescription)}
Identify every visible food item and return ONLY a valid JSON array.
For each item include:
- name
- estimated_portion_grams
- calories
- protein_g
- carbs_g
- fat_g
- fiber_g
- confidence
No markdown. No commentary.
''';

    final response = await _callGemini(
      apiKey,
      model,
      [
        {'text': prompt},
        {
          'inlineData': {'mimeType': mimeType, 'data': base64Encode(bytes)},
        },
      ],
      temperature: 0.1,
      maxTokens: 2048,
    );

    final decoded = jsonDecode(_extractJson(response));
    if (decoded is! List) {
      throw StateError('Gemini meal scan did not return a JSON array.');
    }
    return decoded
        .map(
          (item) =>
              ScannedFoodItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  @override
  Future<PackageLabelScanResult> analyzePackageLabel({
    required AppStateData data,
    required Uint8List bytes,
    required String mimeType,
    String? scanTitle,
  }) async {
    final apiKey = _apiKey(data.aiSettings);
    if (apiKey == null) {
      throw StateError(
        'Gemini API key is missing. Set it in Settings before using AI scan.',
      );
    }
    final model = _resolvedModel(data.aiSettings);

    final prompt =
        '''
$_assistantScopePolicy

You are reading a food package nutrition label photo.
${_optionalPromptLine('User title', scanTitle)}
Extract the product details and return ONLY valid JSON with:
- brand
- product_name
- serving_size
- calories
- protein_g
- carbs_g
- fat_g
- fiber_g
- ingredients (array of strings)
If a value is missing, estimate conservatively or leave the string empty.
No markdown. No explanation.
''';

    final response = await _callGemini(
      apiKey,
      model,
      [
        {'text': prompt},
        {
          'inlineData': {'mimeType': mimeType, 'data': base64Encode(bytes)},
        },
      ],
      temperature: 0.1,
      maxTokens: 2048,
    );

    final decoded = jsonDecode(_extractJson(response));
    return PackageLabelScanResult.fromJson(
      Map<String, dynamic>.from(decoded as Map),
    );
  }

  String _resolvedModel(AiSettings settings) {
    final trimmed = settings.model.trim();
    return trimmed.isEmpty ? _geminiRestModel : trimmed;
  }

  String? _apiKey(AiSettings settings) {
    if (!settings.enabled) {
      return null;
    }
    final trimmed = settings.apiKey.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String _optionalPromptLine(String label, String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? '' : '- $label: $trimmed';
  }

  Future<String> _callGemini(
    String apiKey,
    String model,
    List<Map<String, dynamic>> parts, {
    double temperature = 0.3,
    int maxTokens = 1024,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );
    final body = {
      'contents': [
        {'parts': parts},
      ],
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxTokens,
      },
    };
    final client = http.Client();
    try {
      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);
      final streamed = await client
          .send(request)
          .timeout(_geminiStreamFirstByteTimeout);
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(_geminiHttpTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _formatGeminiHttpError(response.statusCode, response.body),
        );
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final content =
            (candidates.first as Map<String, dynamic>?)?['content']
                as Map<String, dynamic>?;
        final candidateParts = content?['parts'] as List<dynamic>?;
        if (candidateParts != null && candidateParts.isNotEmpty) {
          for (final part in candidateParts) {
            final partMap = part as Map<String, dynamic>;
            final isThought = partMap['thought'] as bool? ?? false;
            if (!isThought) {
              final text = partMap['text'] as String? ?? '';
              if (text.isNotEmpty) {
                return text;
              }
            }
          }
        }
      }
      return '';
    } on TimeoutException catch (error) {
      throw Exception(_formatGeminiTransportError(error));
    } on http.ClientException catch (error) {
      throw Exception(_formatGeminiTransportError(error));
    } on SocketException catch (error) {
      throw Exception(_formatGeminiTransportError(error));
    } finally {
      client.close();
    }
  }

  String _extractJson(String text) {
    final start = text.indexOf(RegExp(r'[\[{]'));
    final end = text.lastIndexOf(RegExp(r'[\]}]'));
    if (start == -1 || end == -1 || end < start) {
      return text;
    }
    return text.substring(start, end + 1);
  }

  String _normalizeTwoSentenceAnalysis(String response, String fallback) {
    final cleaned = response
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[\-*\d.)\s]+'), '');
    if (cleaned.isEmpty) {
      return fallback;
    }
    final matches = RegExp(r'[^.!?]+[.!?]+').allMatches(cleaned).toList();
    if (matches.length >= 2) {
      return matches.take(2).map((match) => match.group(0)!.trim()).join(' ');
    }
    return cleaned;
  }

  String _fallbackInsight(AppStateData data) {
    final targets = CalculationsEngine.targetsFor(
      data.profile,
      data.weightLogs,
    );
    final nutrition = CalculationsEngine.totalsForDay(data.foodLogs, dayKey());
    if (nutrition.protein >= targets.proteinGoal) {
      return 'Protein is actually behaving today, which is a rare plot twist. Keep the rest simple before dinner tries to turn this into a documentary about poor choices.';
    }
    if (nutrition.calories > targets.calorieGoal) {
      return 'Calories already jumped the fence. Stop negotiating with snacks like they have legal representation and keep the next meal boring on purpose.';
    }
    return 'The day is still salvageable, somehow. Prioritize protein and log accurately before your memory starts doing fiction writing.';
  }

  String _fallbackMetricsInsight(AppStateData data, String weekEnding) {
    final targets = CalculationsEngine.targetsFor(
      data.profile,
      data.weightLogs,
    );
    final weekEnd = parseDayKey(weekEnding);
    final weekStart = weekEnd.subtract(const Duration(days: 6));
    final sortedWeights = data.weightLogs.where((item) {
      final date = parseDayKey(item.date);
      return !date.isBefore(weekStart) && !date.isAfter(weekEnd);
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
    final weeklyChange = sortedWeights.length < 2
        ? 0.0
        : sortedWeights.last.weightKg - sortedWeights.first.weightKg;
    final direction = weeklyChange.abs() < 0.1
        ? 'mostly flat'
        : weeklyChange < 0
        ? 'trending down'
        : 'moving up';
    final gap = (targets.weightKg - data.profile.goalWeightKg).abs();
    return 'Week ending $weekEnding is $direction on weight, with ${gap.toStringAsFixed(1)} kg still between current weight and goal. Keep logging measurements and photos, because vibes are not a measurement system.';
  }

  String _fallbackDeepAnalytics(AppStateData data) {
    final targets = CalculationsEngine.targetsFor(
      data.profile,
      data.weightLogs,
    );
    final recentDays = List.generate(
      30,
      (index) => dayKey(DateTime.now().subtract(Duration(days: index))),
    );
    final loggedDays = recentDays
        .where((day) => data.foodLogs.any((item) => item.date == day))
        .length;
    final avgProtein =
        recentDays.fold<double>(
          0,
          (sum, day) =>
              sum + CalculationsEngine.totalsForDay(data.foodLogs, day).protein,
        ) /
        recentDays.length;
    return 'Deep Analytics sees $loggedDays logged food days out of 30 and ${avgProtein.toStringAsFixed(0)}g average protein against a ${targets.proteinGoal.toStringAsFixed(0)}g target. Translation: the data is useful, but consistency still needs fewer guest appearances.';
  }
}
