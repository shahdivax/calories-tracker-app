import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import 'app_database.dart';
import 'app_repository.dart';
import 'ai_runtime_service.dart';
import 'calculations.dart';
import 'csv_service.dart';
import 'drift_store_service.dart';
import 'local_store_service.dart';
import 'media_service.dart';
import 'notification_service.dart';

final localStoreServiceProvider = Provider<LocalStoreService>((ref) {
  return LocalStoreService();
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final driftStoreServiceProvider = Provider<DriftStoreService>((ref) {
  return DriftStoreService(
    ref.watch(appDatabaseProvider),
    ref.watch(localStoreServiceProvider),
  );
});

final appRepositoryProvider = Provider<AppRepository>((ref) {
  return AppRepository(ref.watch(driftStoreServiceProvider));
});

final aiRuntimeServiceProvider = Provider<AiRuntimeService>((ref) {
  return GeminiRestAiRuntimeService();
});

final mediaServiceProvider = Provider<MediaService>((ref) {
  return MediaService();
});

final csvServiceProvider = Provider<CsvService>((ref) {
  return CsvService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final appControllerProvider =
    AsyncNotifierProvider<AppController, AppStateData>(AppController.new);

class AppController extends AsyncNotifier<AppStateData> {
  AppRepository get _repository => ref.read(appRepositoryProvider);
  AiRuntimeService get _ai => ref.read(aiRuntimeServiceProvider);
  NotificationService get _notifications =>
      ref.read(notificationServiceProvider);

  final Set<String> _activeInsightRefreshes = <String>{};

  @override
  Future<AppStateData> build() async {
    final data = await _repository.load();
    final next = _injectInsight(data);
    unawaited(_syncNotifications(next));
    unawaited(_maybeRefreshAdaptiveTargets(next));
    unawaited(_maybeRefreshScheduledInsights(next));
    return next;
  }

  Future<void> completeSetup(
    BodyProfile profile, {
    AppPreferences? preferences,
    AiSettings? aiSettings,
  }) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    final today = dayKey();
    final nextWeightLogs = current.weightLogs.any((item) => item.date == today)
        ? current.weightLogs
        : [
            ...current.weightLogs,
            WeightLog(
              id: _id('weight'),
              date: today,
              weightKg: profile.startingWeightKg,
            ),
          ];

    final next = current.copyWith(
      profile: profile.copyWith(completedAt: DateTime.now()),
      weightLogs: nextWeightLogs,
      preferences: preferences ?? current.preferences,
      aiSettings: aiSettings ?? current.aiSettings,
    );
    await _persist(_injectInsight(next), forceAdaptiveRefresh: true);
  }

  Future<void> updateProfile(BodyProfile profile) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    final previousTargets = CalculationsEngine.targetsFor(
      current.profile,
      current.weightLogs,
    );
    final nextTargets = CalculationsEngine.targetsFor(
      profile,
      current.weightLogs,
    );
    final next = current.copyWith(
      profile: profile,
      targetUpdate: _buildTargetUpdate(previousTargets, nextTargets),
    );
    await _persist(_injectInsight(next), forceAdaptiveRefresh: true);
  }

  Future<void> addWeightLog(double weightKg, {String? notes}) async {
    await upsertWeightLog(
      WeightLog(
        id: _id('weight'),
        date: dayKey(),
        weightKg: weightKg,
        notes: notes,
      ),
    );
  }

  Future<void> upsertWeightLog(WeightLog log) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    final nextLogs = [
      ...current.weightLogs.where(
        (item) => item.id != log.id && item.date != log.date,
      ),
      log,
    ]..sort((a, b) => a.date.compareTo(b.date));

    await _persist(_injectInsight(current.copyWith(weightLogs: nextLogs)));
  }

  Future<void> removeWeightLog(String id) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    await _persist(
      _injectInsight(
        current.copyWith(
          weightLogs: current.weightLogs
              .where((item) => item.id != id)
              .toList(),
        ),
      ),
    );
  }

  Future<void> addFoodEntry(FoodLogEntry entry) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    await _persist(
      _injectInsight(current.copyWith(foodLogs: [...current.foodLogs, entry])),
    );
  }

  Future<void> updateFoodEntry(FoodLogEntry entry) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    final nextEntries = current.foodLogs
        .map((item) => item.id == entry.id ? entry : item)
        .toList();
    await _persist(_injectInsight(current.copyWith(foodLogs: nextEntries)));
  }

  Future<void> removeFoodEntry(String id) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    await _persist(
      _injectInsight(
        current.copyWith(
          foodLogs: current.foodLogs.where((entry) => entry.id != id).toList(),
        ),
      ),
    );
  }

  Future<void> addCustomFood(CustomFood food) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    final filtered = current.customFoods
        .where((item) => item.id != food.id)
        .toList();
    await _persist(current.copyWith(customFoods: [...filtered, food]));
  }

  Future<void> removeCustomFood(String id) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    await _persist(
      current.copyWith(
        customFoods: current.customFoods
            .where((item) => item.id != id)
            .toList(),
      ),
    );
  }

  Future<void> addWater(int amountMl) async {
    await upsertWaterLog(
      WaterLog(id: _id('water'), date: dayKey(), amountMl: amountMl),
    );
  }

  Future<void> upsertWaterLog(WaterLog log) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    await _persist(
      current.copyWith(
        waterLogs: [
          ...current.waterLogs.where((item) => item.id != log.id),
          log,
        ]..sort((a, b) => a.date.compareTo(b.date)),
      ),
    );
  }

  Future<void> removeWaterLog(String id) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    await _persist(
      current.copyWith(
        waterLogs: current.waterLogs.where((item) => item.id != id).toList(),
      ),
    );
  }

  Future<void> addWorkout(WorkoutSession session) async {
    await addWorkoutWithSets(session, const []);
  }

  Future<void> addWorkoutWithSets(
    WorkoutSession session,
    List<ExerciseSetLog> sets,
  ) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    await _persist(
      _injectInsight(
        current.copyWith(
          workoutSessions: [...current.workoutSessions, session],
          exerciseSets: [...current.exerciseSets, ...sets],
        ),
      ),
    );
  }

  Future<void> removeWorkoutSession(String id) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    await _persist(
      _injectInsight(
        current.copyWith(
          workoutSessions: current.workoutSessions
              .where((item) => item.id != id)
              .toList(),
          exerciseSets: current.exerciseSets
              .where((item) => item.sessionId != id)
              .toList(),
        ),
      ),
    );
  }

  Future<void> addBodyMeasurement(BodyMeasurement measurement) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    final nextProfile = current.profile.copyWith(
      waistCm: measurement.waistCm ?? current.profile.waistCm,
      neckCm: measurement.neckCm ?? current.profile.neckCm,
      bodyFatPct: measurement.bodyFatPct ?? current.profile.bodyFatPct,
    );

    await _persist(
      _injectInsight(
        current.copyWith(
          profile: nextProfile,
          bodyMeasurements: [...current.bodyMeasurements, measurement]
            ..sort((a, b) => a.date.compareTo(b.date)),
        ),
      ),
    );
  }

  Future<void> removeBodyMeasurement(String id) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    final nextMeasurements =
        current.bodyMeasurements.where((item) => item.id != id).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final latest = nextMeasurements.isEmpty ? null : nextMeasurements.last;
    final nextProfile = current.profile.copyWith(
      waistCm: latest?.waistCm,
      neckCm: latest?.neckCm,
      bodyFatPct: latest?.bodyFatPct,
    );
    await _persist(
      _injectInsight(
        current.copyWith(
          profile: nextProfile,
          bodyMeasurements: nextMeasurements,
        ),
      ),
    );
  }

  Future<void> addProgressPhoto(ProgressPhoto photo) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    await _persist(
      current.copyWith(
        progressPhotos: [...current.progressPhotos, photo]
          ..sort((a, b) => a.date.compareTo(b.date)),
      ),
    );
  }

  Future<void> removeProgressPhoto(String id) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    await _persist(
      current.copyWith(
        progressPhotos: current.progressPhotos
            .where((item) => item.id != id)
            .toList(),
      ),
    );
  }

  Future<void> updateAiSettings(AiSettings settings) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    await _persist(
      current.copyWith(aiSettings: settings),
      forceAdaptiveRefresh: true,
    );
  }

  Future<void> updatePreferences(AppPreferences preferences) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    await _persist(current.copyWith(preferences: preferences));
  }

  Future<void> clearTargetUpdate() async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    await _persist(current.copyWith(clearTargetUpdate: true));
  }

  Future<void> refreshInsight() async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    final now = DateTime.now();
    final slot = _dashboardInsightSlot(now);
    final type = slot == null ? 'dashboard-manual' : slot.type;
    final message = await _ai.generateInsight(
      current,
      checkInLabel: slot?.label ?? 'manual dashboard refresh',
    );
    await _persist(
      _replaceInsight(
        current,
        message: message,
        date: dayKey(now),
        type: type,
        contextHash: _dashboardInsightHash(current, dayKey(now)),
      ),
    );
  }

  Future<void> _persist(
    AppStateData next, {
    bool forceAdaptiveRefresh = false,
  }) async {
    final enriched = _injectInsight(next);
    await _storeState(enriched);
    unawaited(
      _maybeRefreshAdaptiveTargets(enriched, force: forceAdaptiveRefresh),
    );
    unawaited(_maybeRefreshScheduledInsights(enriched));
  }

  Future<void> _storeState(AppStateData next) async {
    state = AsyncData(next);
    unawaited(_syncNotifications(next));
    await _repository.save(next);
  }

  Future<void> _syncNotifications(AppStateData data) async {
    try {
      await _notifications.syncProfileNotifications(
        data.profile,
        data.preferences.notifications,
      );
    } catch (_) {}
  }

  Future<void> _maybeRefreshAdaptiveTargets(
    AppStateData data, {
    bool force = false,
  }) async {
    final settings = data.aiSettings;
    if (!settings.enabled ||
        !settings.autoAdaptiveTargets ||
        settings.apiKey.trim().isEmpty) {
      return;
    }
    if (!force && !_isAdaptiveRefreshDue(settings)) {
      return;
    }

    try {
      final previousTargets = CalculationsEngine.targetsFor(
        data.profile,
        data.weightLogs,
      );
      final recommendation = await _ai.recommendAdaptiveTargets(
        data: data,
        lookbackCount: settings.adaptiveLookbackCount,
      );
      final nextProfile = data.profile.copyWith(
        activityLevel: recommendation.activityLevel,
        deficitKcal: recommendation.deficitKcal.clamp(0, 900),
        proteinMultiplier: recommendation.proteinMultiplier.clamp(1.2, 2.8),
        fatMultiplier: recommendation.fatMultiplier.clamp(0.5, 1.2),
      );
      final nextTargets = CalculationsEngine.targetsFor(
        nextProfile,
        data.weightLogs,
      );
      final nextSettings = settings.copyWith(
        lastAdaptiveSyncAt: DateTime.now().toIso8601String(),
        lastAdaptiveSummary: recommendation.summary,
      );
      final nextData = _injectInsight(
        data.copyWith(
          profile: nextProfile,
          aiSettings: nextSettings,
          targetUpdate: _buildTargetUpdate(
            previousTargets,
            nextTargets,
            summary: recommendation.summary,
          ),
        ),
      );
      await _storeState(nextData);
    } catch (_) {}
  }

  bool _isAdaptiveRefreshDue(AiSettings settings) {
    final lastSync = settings.lastAdaptiveSyncAt;
    if (lastSync == null || lastSync.isEmpty) {
      return true;
    }
    final parsed = DateTime.tryParse(lastSync);
    if (parsed == null) {
      return true;
    }
    return DateTime.now().difference(parsed).inDays >=
        settings.adaptiveCadenceDays;
  }

  AppStateData _injectInsight(AppStateData data) {
    final today = dayKey();
    final insight = AiInsight(
      id: _id('insight'),
      date: today,
      text: _fallbackInsight(data),
      type: 'dashboard-live',
      createdAt: DateTime.now().toIso8601String(),
      contextHash: _dashboardInsightHash(data, today),
    );
    final others = data.aiInsights
        .where((item) => item.date != insight.date || item.type != insight.type)
        .toList();
    return data.copyWith(aiInsights: [...others, insight]);
  }

  AppStateData _replaceInsight(
    AppStateData data, {
    required String message,
    required String date,
    required String type,
    required String contextHash,
  }) {
    final insight = AiInsight(
      id: _id('insight'),
      date: date,
      text: message,
      type: type,
      createdAt: DateTime.now().toIso8601String(),
      contextHash: contextHash,
    );
    final others = data.aiInsights
        .where((item) => item.date != insight.date || item.type != insight.type)
        .toList();
    return data.copyWith(aiInsights: [...others, insight]);
  }

  Future<void> _maybeRefreshScheduledInsights(AppStateData data) async {
    if (!_canUseAi(data)) {
      return;
    }
    final now = DateTime.now();
    await _maybeRefreshDashboardInsight(data, now);
    final latest = state.valueOrNull ?? data;
    await _maybeRefreshMetricsInsight(latest, now);
    final latestAfterMetrics = state.valueOrNull ?? latest;
    await _maybeRefreshDeepAnalyticsInsight(latestAfterMetrics, now);
  }

  Future<void> _maybeRefreshDashboardInsight(
    AppStateData data,
    DateTime now,
  ) async {
    final slot = _dashboardInsightSlot(now);
    if (slot == null) {
      return;
    }
    final today = dayKey(now);
    final contextHash = _dashboardInsightHash(data, today);
    final existing = _insightFor(data, date: today, type: slot.type);
    if (existing?.contextHash == contextHash) {
      return;
    }

    final refreshKey = '$today:${slot.type}';
    if (!_activeInsightRefreshes.add(refreshKey)) {
      return;
    }
    try {
      await Future<void>.delayed(const Duration(seconds: 2));
      final latest = state.valueOrNull ?? data;
      final latestHash = _dashboardInsightHash(latest, today);
      final latestExisting = _insightFor(latest, date: today, type: slot.type);
      if (latestExisting?.contextHash == latestHash) {
        return;
      }
      final message = await _ai.generateInsight(
        latest,
        checkInLabel: slot.label,
      );
      await _storeState(
        _replaceInsight(
          latest,
          message: message,
          date: today,
          type: slot.type,
          contextHash: latestHash,
        ),
      );
    } finally {
      _activeInsightRefreshes.remove(refreshKey);
    }
  }

  Future<void> _maybeRefreshMetricsInsight(
    AppStateData data,
    DateTime now,
  ) async {
    final weekEnding = _metricsWeekEndingDue(now);
    if (weekEnding == null) {
      return;
    }
    const type = 'metrics-weekly';
    final contextHash = _metricsInsightHash(data, weekEnding);
    final existing = _insightFor(data, date: weekEnding, type: type);
    if (existing?.contextHash == contextHash) {
      return;
    }

    final refreshKey = '$weekEnding:$type';
    if (!_activeInsightRefreshes.add(refreshKey)) {
      return;
    }
    try {
      await Future<void>.delayed(const Duration(seconds: 2));
      final latest = state.valueOrNull ?? data;
      final latestHash = _metricsInsightHash(latest, weekEnding);
      final latestExisting = _insightFor(latest, date: weekEnding, type: type);
      if (latestExisting?.contextHash == latestHash) {
        return;
      }
      final message = await _ai.generateMetricsInsight(
        latest,
        weekEnding: weekEnding,
      );
      await _storeState(
        _replaceInsight(
          latest,
          message: message,
          date: weekEnding,
          type: type,
          contextHash: latestHash,
        ),
      );
    } finally {
      _activeInsightRefreshes.remove(refreshKey);
    }
  }

  Future<void> _maybeRefreshDeepAnalyticsInsight(
    AppStateData data,
    DateTime now,
  ) async {
    const type = 'settings-deep-analytics';
    final today = dayKey(now);
    final contextHash = _deepAnalyticsHash(data);
    final existing = _latestInsightOfType(data, type);
    if (existing?.contextHash == contextHash) {
      return;
    }
    if (existing != null &&
        _insightAge(existing, now) < const Duration(hours: 6)) {
      return;
    }

    final refreshKey = '$today:$type';
    if (!_activeInsightRefreshes.add(refreshKey)) {
      return;
    }
    try {
      await Future<void>.delayed(const Duration(seconds: 2));
      final latest = state.valueOrNull ?? data;
      final latestHash = _deepAnalyticsHash(latest);
      final latestExisting = _latestInsightOfType(latest, type);
      if (latestExisting?.contextHash == latestHash) {
        return;
      }
      if (latestExisting != null &&
          _insightAge(latestExisting, DateTime.now()) <
              const Duration(hours: 6)) {
        return;
      }
      final message = await _ai.generateDeepAnalytics(latest);
      await _storeState(
        _replaceInsight(
          latest,
          message: message,
          date: today,
          type: type,
          contextHash: latestHash,
        ),
      );
    } finally {
      _activeInsightRefreshes.remove(refreshKey);
    }
  }

  bool _canUseAi(AppStateData data) {
    final settings = data.aiSettings;
    return settings.enabled && settings.apiKey.trim().isNotEmpty;
  }

  AiInsight? _insightFor(
    AppStateData data, {
    required String date,
    required String type,
  }) {
    for (final insight in data.aiInsights) {
      if (insight.date == date && insight.type == type) {
        return insight;
      }
    }
    return null;
  }

  AiInsight? _latestInsightOfType(AppStateData data, String type) {
    final matches = data.aiInsights.where((item) => item.type == type).toList()
      ..sort((a, b) {
        final aTime =
            DateTime.tryParse(a.createdAt ?? '') ?? parseDayKey(a.date);
        final bTime =
            DateTime.tryParse(b.createdAt ?? '') ?? parseDayKey(b.date);
        return aTime.compareTo(bTime);
      });
    return matches.isEmpty ? null : matches.last;
  }

  Duration _insightAge(AiInsight insight, DateTime now) {
    final createdAt = DateTime.tryParse(insight.createdAt ?? '');
    if (createdAt == null) {
      return const Duration(days: 365);
    }
    return now.difference(createdAt);
  }

  _DashboardInsightSlot? _dashboardInsightSlot(DateTime now) {
    final minutes = now.hour * 60 + now.minute;
    if (minutes >= 22 * 60) {
      return const _DashboardInsightSlot(
        type: 'dashboard-dinner',
        label: 'after dinner check-in, 10 PM or later',
      );
    }
    if (minutes >= (14 * 60) + 30) {
      return const _DashboardInsightSlot(
        type: 'dashboard-lunch',
        label: 'after lunch check-in, 2:30 PM or later',
      );
    }
    if (minutes >= 9 * 60) {
      return const _DashboardInsightSlot(
        type: 'dashboard-breakfast',
        label: 'after breakfast check-in, 9 AM or later',
      );
    }
    return null;
  }

  String? _metricsWeekEndingDue(DateTime now) {
    final minutes = now.hour * 60 + now.minute;
    if (now.weekday == DateTime.saturday && minutes < 22 * 60) {
      return null;
    }
    final daysSinceSaturday = (now.weekday - DateTime.saturday) % 7;
    final weekEnd = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: daysSinceSaturday));
    return dayKey(weekEnd);
  }

  String _dashboardInsightHash(AppStateData data, String today) {
    final totals = CalculationsEngine.totalsForDay(data.foodLogs, today);
    final waterMl = data.waterLogs
        .where((item) => item.date == today)
        .fold<int>(0, (sum, item) => sum + item.amountMl);
    final meals =
        data.foodLogs
            .where((item) => item.date == today)
            .map(
              (item) =>
                  '${item.id}:${item.mealSlot.name}:${item.calories.round()}:${item.proteinG.round()}',
            )
            .toList()
          ..sort();
    final workouts =
        data.workoutSessions
            .where((item) => item.date == today)
            .map(
              (item) =>
                  '${item.id}:${item.type.name}:${item.durationMinutes}:${item.caloriesBurned.round()}',
            )
            .toList()
          ..sort();
    return [
      today,
      totals.calories.round(),
      totals.protein.round(),
      waterMl,
      ...meals,
      ...workouts,
    ].join('|');
  }

  String _metricsInsightHash(AppStateData data, String weekEnding) {
    final weekEnd = parseDayKey(weekEnding);
    final days = List.generate(
      7,
      (index) => dayKey(weekEnd.subtract(Duration(days: 6 - index))),
    );
    final nutrition = [
      for (final day in days)
        '$day:${CalculationsEngine.totalsForDay(data.foodLogs, day).calories.round()}:${CalculationsEngine.totalsForDay(data.foodLogs, day).protein.round()}',
    ];
    final weights =
        data.weightLogs
            .where((item) => days.contains(item.date))
            .map((item) => '${item.date}:${item.weightKg.toStringAsFixed(2)}')
            .toList()
          ..sort();
    final measurements =
        data.bodyMeasurements
            .where((item) => days.contains(item.date))
            .map(
              (item) =>
                  '${item.date}:${item.waistCm}:${item.neckCm}:${item.bodyFatPct}',
            )
            .toList()
          ..sort();
    final photos =
        data.progressPhotos
            .where((item) => days.contains(item.date))
            .map((item) => '${item.date}:${item.angle.name}:${item.path}')
            .toList()
          ..sort();
    final workouts =
        data.workoutSessions
            .where((item) => days.contains(item.date))
            .map(
              (item) =>
                  '${item.date}:${item.type.name}:${item.durationMinutes}',
            )
            .toList()
          ..sort();
    return [
      weekEnding,
      ...nutrition,
      ...weights,
      ...measurements,
      ...photos,
      ...workouts,
    ].join('|');
  }

  String _deepAnalyticsHash(AppStateData data) {
    final recentDays = List.generate(
      30,
      (index) => dayKey(DateTime.now().subtract(Duration(days: 29 - index))),
    );
    final nutrition = [
      for (final day in recentDays)
        '$day:${CalculationsEngine.totalsForDay(data.foodLogs, day).calories.round()}:${CalculationsEngine.totalsForDay(data.foodLogs, day).protein.round()}',
    ];
    final water = [
      for (final day in recentDays)
        '$day:${data.waterLogs.where((item) => item.date == day).fold<int>(0, (sum, item) => sum + item.amountMl)}',
    ];
    final weights =
        data.weightLogs
            .where((item) => recentDays.contains(item.date))
            .map((item) => '${item.date}:${item.weightKg.toStringAsFixed(2)}')
            .toList()
          ..sort();
    final workouts =
        data.workoutSessions
            .where((item) => recentDays.contains(item.date))
            .map(
              (item) =>
                  '${item.date}:${item.type.name}:${item.durationMinutes}',
            )
            .toList()
          ..sort();
    final measurements =
        data.bodyMeasurements
            .where((item) => recentDays.contains(item.date))
            .map(
              (item) =>
                  '${item.date}:${item.waistCm}:${item.neckCm}:${item.bodyFatPct}',
            )
            .toList()
          ..sort();
    return [
      data.profile.goalWeightKg,
      data.profile.goalType.name,
      ...nutrition,
      ...water,
      ...weights,
      ...workouts,
      ...measurements,
    ].join('|');
  }

  TargetUpdateNotice? _buildTargetUpdate(
    NutritionTargets previous,
    NutritionTargets next, {
    String? summary,
  }) {
    final changes = <String>[];
    if (previous.calorieGoal.round() != next.calorieGoal.round()) {
      changes.add(
        'Calories ${previous.calorieGoal.round()} -> ${next.calorieGoal.round()}',
      );
    }
    if (previous.proteinGoal.round() != next.proteinGoal.round()) {
      changes.add(
        'Protein ${previous.proteinGoal.round()}g -> ${next.proteinGoal.round()}g',
      );
    }
    if (previous.carbGoal.round() != next.carbGoal.round()) {
      changes.add(
        'Carbs ${previous.carbGoal.round()}g -> ${next.carbGoal.round()}g',
      );
    }
    if (previous.fatGoal.round() != next.fatGoal.round()) {
      changes.add(
        'Fat ${previous.fatGoal.round()}g -> ${next.fatGoal.round()}g',
      );
    }

    if (changes.isEmpty) {
      if (summary == null || summary.trim().isEmpty) {
        return null;
      }
      return TargetUpdateNotice(
        id: _id('targets'),
        message: summary.trim(),
        createdAt: DateTime.now().toIso8601String(),
      );
    }

    final parts = [
      changes.join(' • '),
      if (summary != null && summary.trim().isNotEmpty) summary.trim(),
    ];

    return TargetUpdateNotice(
      id: _id('targets'),
      message: parts.join(' • '),
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  String _fallbackInsight(AppStateData data) {
    final targets = CalculationsEngine.targetsFor(
      data.profile,
      data.weightLogs,
    );
    final nutrition = CalculationsEngine.totalsForDay(data.foodLogs, dayKey());
    if (nutrition.protein >= targets.proteinGoal) {
      return 'Protein is locked in today, a shocking act of competence. Keep the rest controlled before snacks start pitching nonsense.';
    }
    if (nutrition.calories > targets.calorieGoal) {
      return 'Calories are already over target. Stop the drift before the day turns into a buffet with a fitness app attached.';
    }
    return 'The day is still open, which means there is still time to not fumble it. Hit protein and log accurately.';
  }

  String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';
}

class _DashboardInsightSlot {
  const _DashboardInsightSlot({required this.type, required this.label});

  final String type;
  final String label;
}
