import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models.dart';
import '../../core/services/app_controller.dart';
import '../../core/services/calculations.dart';
import '../../core/theme/app_theme.dart';
import '../food_log/food_log_screen.dart';
import '../history/history_screen.dart';
import '../metrics/metrics_screen.dart';
import '../settings/settings_screen.dart';
import '../workouts/workouts_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider).valueOrNull;
    if (data == null) return const SizedBox.shrink();

    final today = dayKey();
    final profile = data.profile;
    final targets = CalculationsEngine.targetsFor(profile, data.weightLogs);
    final totals = CalculationsEngine.totalsForDay(data.foodLogs, today);

    final todaysWorkout = data.workoutSessions
        .where((item) => item.date == today)
        .toList();
    final burned = todaysWorkout.fold<double>(
      0,
      (sum, item) => sum + item.caloriesBurned,
    );

    final waterMl = data.waterLogs
        .where((item) => item.date == today)
        .fold<int>(0, (sum, item) => sum + item.amountMl);
    final waterLogs =
        data.waterLogs.where((item) => item.date == today).toList()
          ..sort((a, b) => b.id.compareTo(a.id));
    final waterTarget =
        CalculationsEngine.waterTargetLiters(data.workoutSessions, today) *
        1000;
    final efficiency = _calculateDailyEfficiency(
      data: data,
      today: today,
      totals: totals,
      targets: targets,
      waterMl: waterMl,
      waterTarget: waterTarget,
    );

    final meals = data.foodLogs.where((l) => l.date == today).toList()
      ..sort((a, b) => b.id.compareTo(a.id));

    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // Background Gradient (Ambient Light)
          Positioned(
            top: -150,
            left: -100,
            right: -100,
            height: 400,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context, ref, data),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                    children: [
                      _buildQuickActions(context),
                      const SizedBox(height: 32),
                      _buildGreeting(context, profile.name, efficiency),
                      const SizedBox(height: 24),
                      _buildCoreMetricCluster(context, totals, targets, burned),
                      const SizedBox(height: 16),
                      _buildMacroBars(context, totals, targets),
                      const SizedBox(height: 24),
                      _buildWaterTracker(
                        context,
                        ref,
                        waterMl,
                        waterTarget,
                        waterLogs,
                      ),
                      const SizedBox(height: 32),
                      _buildNeuralAnalysis(context, _dashboardInsight(data)),
                      const SizedBox(height: 32),
                      _buildDailyLogs(context, meals),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, AppStateData data) {
    final colors = context.colors;
    final streak = _calculateStreak(data);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.7),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceHigher,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: streak > 0 ? colors.primary : colors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$streak',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: streak > 0
                            ? colors.primary
                            : colors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: colors.surfaceHigher,
                  foregroundColor: colors.textSecondary,
                ),
                icon: const Icon(Icons.calendar_month, size: 20),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: colors.surfaceHigher,
                  foregroundColor: colors.textSecondary,
                ),
                icon: const Icon(Icons.settings, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.add_circle,
            label: 'Log Meal',
            color: context.colors.primary,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text('Food Log')),
                  body: const FoodLogScreen(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.fitness_center,
            label: 'Workout',
            color: context.colors.secondary,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text('Workouts')),
                  body: const WorkoutsScreen(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.monitor_weight,
            label: 'Weight',
            color: context.colors.accent,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text('Metrics')),
                  body: const MetricsScreen(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context, String name, int efficiency) {
    final colors = context.colors;
    final now = DateTime.now();
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final months = [
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
    final dateStr =
        '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$dateStr • SESSION ACTIVE',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
                letterSpacing: 1.5,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name.split(' ').first,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1.0,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'EFFICIENCY',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.primary,
                letterSpacing: 2.0,
                fontSize: 10,
              ),
            ),
            Text(
              '$efficiency%',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNeuralAnalysis(BuildContext context, AiInsight? insight) {
    if (insight == null) return const SizedBox.shrink();
    final badge = insight.type == 'dashboard-live'
        ? 'LIVE DATA'
        : 'AI SCHEDULED';
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colors.primary.withValues(alpha: 0.4),
                    context.colors.secondary.withValues(alpha: 0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: context.colors.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.colors.surfaceHigher.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'ANALYSIS',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.primary.withValues(
                                alpha: 0.4,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 8,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        insight.text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AiInsight? _dashboardInsight(AppStateData data) {
    final today = dayKey();
    final generated =
        data.aiInsights
            .where(
              (item) =>
                  item.date == today &&
                  item.type.startsWith('dashboard-') &&
                  item.type != 'dashboard-live',
            )
            .toList()
          ..sort(_compareInsights);
    if (generated.isNotEmpty) {
      return generated.last;
    }
    final live =
        data.aiInsights
            .where(
              (item) => item.date == today && item.type == 'dashboard-live',
            )
            .toList()
          ..sort(_compareInsights);
    if (live.isNotEmpty) {
      return live.last;
    }
    final legacy =
        data.aiInsights
            .where((item) => item.date == today && item.type == 'daily')
            .toList()
          ..sort(_compareInsights);
    return legacy.isEmpty ? null : legacy.last;
  }

  int _compareInsights(AiInsight a, AiInsight b) {
    final aTime = DateTime.tryParse(a.createdAt ?? '') ?? parseDayKey(a.date);
    final bTime = DateTime.tryParse(b.createdAt ?? '') ?? parseDayKey(b.date);
    return aTime.compareTo(bTime);
  }

  Widget _buildCoreMetricCluster(
    BuildContext context,
    DailyNutritionTotals totals,
    NutritionTargets targets,
    double burned,
  ) {
    final colors = context.colors;
    final ratio = targets.calorieGoal == 0
        ? 0.0
        : (totals.calories / targets.calorieGoal).clamp(0.0, 1.0);
    final remaining = (targets.calorieGoal - totals.calories).clamp(0, 9999);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface, // #131313
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackMetrics = constraints.maxWidth < 720;
          final chartSize = stackMetrics
              ? (constraints.maxWidth - 48).clamp(280.0, 360.0)
              : 300.0;
          final chart = SizedBox(
            width: chartSize,
            height: chartSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 14,
                    color: colors.surfaceHigher,
                  ),
                ),
                SizedBox.expand(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: ratio),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCirc,
                    builder: (context, val, _) {
                      return CircularProgressIndicator(
                        value: val,
                        strokeWidth: 14,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colors.primary,
                        ),
                      );
                    },
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'TODAY',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.textSecondary,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      totals.calories.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.0,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(ratio * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
          final summary = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CALORIES REMAINING',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                  letterSpacing: 1.5,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    remaining.toStringAsFixed(0),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '/ ${targets.calorieGoal.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _MetricReadout(
                      label: 'Burned',
                      value: burned.toStringAsFixed(0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricReadout(
                      label: 'Eaten',
                      value: totals.calories.toStringAsFixed(0),
                    ),
                  ),
                ],
              ),
            ],
          );

          if (stackMetrics) {
            return Column(
              children: [
                Align(child: chart),
                const SizedBox(height: 28),
                summary,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: summary),
              const SizedBox(width: 24),
              chart,
            ],
          );
        },
      ),
    );
  }

  Widget _buildMacroBars(
    BuildContext context,
    DailyNutritionTotals totals,
    NutritionTargets targets,
  ) {
    return Row(
      children: [
        Expanded(
          child: _CompactMacroBar(
            label: 'Protein',
            current: totals.protein,
            target: targets.proteinGoal,
            color: context.colors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CompactMacroBar(
            label: 'Carbs',
            current: totals.carbs,
            target: targets.carbGoal,
            color: context.colors.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CompactMacroBar(
            label: 'Fats',
            current: totals.fat,
            target: targets.fatGoal,
            color: context.colors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildWaterTracker(
    BuildContext context,
    WidgetRef ref,
    int waterMl,
    double waterTarget,
    List<WaterLog> waterLogs,
  ) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.water_drop,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hydration Status',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.white, fontSize: 14),
                      ),
                      Text(
                        '${(waterMl / 1000).toStringAsFixed(1)}L / ${(waterTarget / 1000).toStringAsFixed(1)}L Goal',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontSize: 10, letterSpacing: 1.5),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '${((waterMl / waterTarget) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          if (waterLogs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TODAY\'S LOGS',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const HistoryScreen(initialFocus: HistoryFocus.water),
                    ),
                  ),
                  child: const Text('History'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: waterLogs.map((log) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceHigher,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${log.amountMl}ml',
                        style: Theme.of(
                          context,
                        ).textTheme.labelMedium?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => ref
                            .read(appControllerProvider.notifier)
                            .removeWaterLog(log.id),
                        child: Icon(Icons.close, size: 14, color: colors.error),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () =>
                      ref.read(appControllerProvider.notifier).addWater(250),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.surfaceHigher,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+250ml',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () =>
                      ref.read(appControllerProvider.notifier).addWater(500),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.surfaceHigher,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+500ml',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyLogs(BuildContext context, List<FoodLogEntry> meals) {
    if (meals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DAILY LOGS',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: context.colors.textSecondary,
                letterSpacing: 2.0,
                fontSize: 12,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const HistoryScreen(initialFocus: HistoryFocus.food),
                ),
              ),
              child: Text(
                'VIEW ALL',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.colors.primary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...meals.take(4).map((entry) => _DenseMealCard(entry: entry)),
      ],
    );
  }

  int _calculateStreak(AppStateData data) {
    final activeDays = <String>{
      ...data.foodLogs.map((item) => item.date),
      ...data.waterLogs.map((item) => item.date),
      ...data.weightLogs.map((item) => item.date),
      ...data.workoutSessions
          .where((item) => item.type != WorkoutType.rest)
          .map((item) => item.date),
      ...data.bodyMeasurements.map((item) => item.date),
      ...data.progressPhotos.map((item) => item.date),
    };

    var streak = 0;
    var cursor = DateTime.now();
    while (activeDays.contains(dayKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _calculateDailyEfficiency({
    required AppStateData data,
    required String today,
    required DailyNutritionTotals totals,
    required NutritionTargets targets,
    required int waterMl,
    required double waterTarget,
  }) {
    final calorieScore = targets.calorieGoal <= 0
        ? 0.0
        : (1 -
                  ((totals.calories - targets.calorieGoal).abs() /
                      targets.calorieGoal))
              .clamp(0.0, 1.0);
    final proteinScore = targets.proteinGoal <= 0
        ? 0.0
        : (totals.protein / targets.proteinGoal).clamp(0.0, 1.0);
    final waterScore = waterTarget <= 0
        ? 0.0
        : (waterMl / waterTarget).clamp(0.0, 1.0);
    final workoutScore =
        data.workoutSessions.any(
          (item) => item.date == today && item.type != WorkoutType.rest,
        )
        ? 1.0
        : 0.0;

    final score =
        (calorieScore * 0.4) +
        (proteinScore * 0.3) +
        (waterScore * 0.2) +
        (workoutScore * 0.1);

    return (score.clamp(0.0, 1.0) * 100).round();
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: context.colors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactMacroBar extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;

  const _CompactMacroBar({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 9,
                  letterSpacing: 0,
                  color: context.colors.textSecondary,
                ),
              ),
              Text(
                '${(ratio * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontSize: 9,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.colors.surfaceHigher,
              borderRadius: BorderRadius.circular(100),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: ratio),
                builder: (context, val, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: val,
                  child: Container(color: color),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${current.toStringAsFixed(0)}/${target.toStringAsFixed(0)}g',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricReadout extends StatelessWidget {
  const _MetricReadout({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontSize: 10, letterSpacing: 1.2),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DenseMealCard extends ConsumerWidget {
  final FoodLogEntry entry;
  const _DenseMealCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.surfaceHigher,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.restaurant, color: colors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.foodName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${entry.quantityG.toStringAsFixed(0)} ${entry.quantityUnit.shortLabel}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.calories.toStringAsFixed(0)}k',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              Text(
                '${entry.proteinG.toStringAsFixed(0)}g P',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
