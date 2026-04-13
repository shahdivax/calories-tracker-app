import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models.dart';
import '../../core/services/app_controller.dart';
import '../../core/services/calculations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui_kit/ui_kit.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider).valueOrNull;
    if (data == null) {
      return const SizedBox.shrink();
    }
    final targets = CalculationsEngine.targetsFor(
      data.profile,
      data.weightLogs,
    );
    final recentDays = List.generate(
      14,
      (index) => dayKey(DateTime.now().subtract(Duration(days: 13 - index))),
    );
    final nutritionByDay = {
      for (final day in recentDays)
        day: CalculationsEngine.totalsForDay(data.foodLogs, day),
    };
    final burnedByDay = {
      for (final day in recentDays)
        day: data.workoutSessions
            .where((item) => item.date == day)
            .fold<double>(0, (sum, item) => sum + item.caloriesBurned),
    };
    final avgCalories =
        nutritionByDay.values.fold<double>(
          0,
          (sum, item) => sum + item.calories,
        ) /
        recentDays.length;
    final avgProtein =
        nutritionByDay.values.fold<double>(
          0,
          (sum, item) => sum + item.protein,
        ) /
        recentDays.length;
    final goalHits = nutritionByDay.values
        .where((item) => item.protein >= targets.proteinGoal)
        .length;
    final deficitDays = nutritionByDay.values
        .where((item) => item.calories <= targets.calorieGoal)
        .length;
    final prSets = data.exerciseSets.where((item) => item.isPr).toList()
      ..sort((a, b) => b.weightKg.compareTo(a.weightKg));
    final progression = <String, ExerciseSetLog>{};
    for (final set in data.exerciseSets) {
      final current = progression[set.exerciseName];
      if (current == null || set.weightKg > current.weightKg) {
        progression[set.exerciseName] = set;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('ANALYTICS')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _AnalyticsCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppMetricTile(
                        label: 'Avg Calories',
                        value: avgCalories.toStringAsFixed(0),
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppMetricTile(
                        label: 'Avg Protein',
                        value: '${avgProtein.toStringAsFixed(0)} g',
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppMetricTile(
                        label: 'Protein Hits',
                        value: '$goalHits / ${recentDays.length}',
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppMetricTile(
                        label: 'Deficit Days',
                        value: '$deficitDays / ${recentDays.length}',
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppSection(
            title: 'Calorie Trend',
            child: _AnalyticsCard(
              child: SizedBox(
                height: 170,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    gridData: const FlGridData(show: true),
                    titlesData: const FlTitlesData(
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: context.colors.gold,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        spots: [
                          for (
                            var index = 0;
                            index < recentDays.length;
                            index++
                          )
                            FlSpot(
                              index.toDouble(),
                              nutritionByDay[recentDays[index]]!.calories,
                            ),
                        ],
                      ),
                    ],
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: targets.calorieGoal,
                          color: context.colors.sage,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppSection(
            title: 'Protein & Burn',
            child: _AnalyticsCard(
              child: SizedBox(
                height: 170,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    gridData: const FlGridData(show: true),
                    titlesData: const FlTitlesData(
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      for (var index = 0; index < recentDays.length; index++)
                        BarChartGroupData(
                          x: index,
                          barsSpace: 3,
                          barRods: [
                            BarChartRodData(
                              toY: nutritionByDay[recentDays[index]]!.protein,
                              color: context.colors.sage,
                              width: 7,
                            ),
                            BarChartRodData(
                              toY: burnedByDay[recentDays[index]]!,
                              color: context.colors.terracotta,
                              width: 7,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppSection(
            title: 'Macro Split',
            child: _AnalyticsCard(
              child: SizedBox(
                height: 170,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        color: context.colors.sage,
                        value: nutritionByDay.values.fold<double>(
                          0,
                          (sum, item) => sum + item.protein * 4,
                        ),
                        title: 'P',
                      ),
                      PieChartSectionData(
                        color: context.colors.gold,
                        value: nutritionByDay.values.fold<double>(
                          0,
                          (sum, item) => sum + item.carbs * 4,
                        ),
                        title: 'C',
                      ),
                      PieChartSectionData(
                        color: context.colors.terracotta,
                        value: nutritionByDay.values.fold<double>(
                          0,
                          (sum, item) => sum + item.fat * 9,
                        ),
                        title: 'F',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppSection(
            title: 'Workout Progression',
            child: Column(
              children: progression.entries.isEmpty
                  ? [
                      const _AnalyticsCard(
                        child: Text('No exercise progression data yet.'),
                      ),
                    ]
                  : progression.entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AnalyticsCard(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(entry.key),
                                subtitle: Text(
                                  '${entry.value.reps} reps • ${entry.value.muscleGroup}',
                                ),
                                trailing: Text(
                                  '${entry.value.weightKg.toStringAsFixed(1)} kg',
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
            ),
          ),
          const SizedBox(height: 24),
          AppSection(
            title: 'PR History',
            child: Column(
              children: prSets.isEmpty
                  ? [
                      const _AnalyticsCard(
                        child: Text('No PR sets marked yet.'),
                      ),
                    ]
                  : prSets
                        .take(12)
                        .map(
                          (set) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AnalyticsCard(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(set.exerciseName),
                                subtitle: Text(
                                  '${set.reps} reps • ${set.muscleGroup}',
                                ),
                                trailing: Text(
                                  '${set.weightKg.toStringAsFixed(1)} kg',
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}
