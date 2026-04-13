import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models.dart';
import '../../core/services/app_controller.dart';
import '../../core/services/calculations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui_kit/ui_kit.dart';
import '../diary/diary_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider).valueOrNull;
    if (data == null) {
      return const SizedBox.shrink();
    }

    final recentDays = List.generate(
      30,
      (index) => dayKey(DateTime.now().subtract(Duration(days: 29 - index))),
    );
    final nutritionByDay = {
      for (final day in recentDays)
        day: CalculationsEngine.totalsForDay(data.foodLogs, day),
    };
    final targets = CalculationsEngine.targetsFor(
      data.profile,
      data.weightLogs,
    );
    final calorieRaw = [
      for (var index = 0; index < recentDays.length; index++)
        FlSpot(index.toDouble(), nutritionByDay[recentDays[index]]!.calories),
    ];
    final calorieSmooth = _movingAverage(calorieRaw, 3);
    final weightLogs = [...data.weightLogs]
      ..sort((a, b) => a.date.compareTo(b.date));
    final recentWeightLogs = weightLogs.length > 30
        ? weightLogs.sublist(weightLogs.length - 30)
        : weightLogs;
    final weightRaw = [
      for (var index = 0; index < recentWeightLogs.length; index++)
        FlSpot(index.toDouble(), recentWeightLogs[index].weightKg),
    ];
    final weightSmooth = _movingAverage(weightRaw, 3);
    final dayScoreMap = {
      for (final day in List.generate(
        84,
        (index) => dayKey(DateTime.now().subtract(Duration(days: 83 - index))),
      ))
        day: _dayScore(data, day),
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
    final proteinHits = nutritionByDay.values
        .where((item) => item.protein >= targets.proteinGoal)
        .length;
    final activeDays = recentDays.where((day) {
      return data.foodLogs.any((item) => item.date == day) ||
          data.workoutSessions.any((item) => item.date == day) ||
          data.weightLogs.any((item) => item.date == day);
    }).length;
    final currentWeight = CalculationsEngine.currentWeight(
      data.profile,
      data.weightLogs,
    );
    final startingWeight = data.profile.startingWeightKg;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _MoreHeader(name: data.profile.name),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 148),
              children: [
                _HeroPanel(
                  currentWeight: currentWeight,
                  goalWeight: data.profile.goalWeightKg,
                  deltaWeight: currentWeight - startingWeight,
                  avgCalories: avgCalories,
                  avgProtein: avgProtein,
                  proteinHits: proteinHits,
                  activeDays: activeDays,
                ),
                const SizedBox(height: 24),
                AppSection(
                  title: 'Trend System',
                  trailing: const _LineLegend(),
                  child: Column(
                    children: [
                      _TrendCard(
                        title: 'Weight Story',
                        subtitle: recentWeightLogs.length < 2
                            ? 'Log more weigh-ins to unlock trend smoothing.'
                            : 'Raw weigh-ins are translucent. Smoothed trend is solid.',
                        chart: recentWeightLogs.length < 2
                            ? const SizedBox(
                                height: 220,
                                child: Center(
                                  child: Text('Not enough weight data yet.'),
                                ),
                              )
                            : _TrendChart(
                                raw: weightRaw,
                                smooth: weightSmooth,
                                rawColor: context.colors.sage.withValues(
                                  alpha: 0.45,
                                ),
                                smoothColor: context.colors.sage,
                                guideLineY: data.profile.goalWeightKg,
                                guideLineColor: context.colors.gold,
                                minY: _chartMin(weightRaw, padding: 2),
                                maxY: _chartMax(weightRaw, padding: 2),
                                leftLabelBuilder: (value) =>
                                    value.toStringAsFixed(0),
                                tooltipValueBuilder: (value) =>
                                    '${value.toStringAsFixed(2)} kg',
                                bottomLabelBuilder: (value) {
                                  final index = value.toInt();
                                  if (index < 0 ||
                                      index >= recentWeightLogs.length) {
                                    return '';
                                  }
                                  return formatShortDate(
                                    recentWeightLogs[index].date,
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),
                      _TrendCard(
                        title: 'Calorie Signal',
                        subtitle:
                            'Raw daily intake is translucent. 3-day moving average is solid.',
                        chart: _TrendChart(
                          raw: calorieRaw,
                          smooth: calorieSmooth,
                          rawColor: context.colors.gold.withValues(alpha: 0.45),
                          smoothColor: context.colors.gold,
                          guideLineY: targets.calorieGoal,
                          guideLineColor: context.colors.terracotta,
                          minY: 0,
                          maxY: _chartMax(calorieRaw, padding: 250),
                          leftLabelBuilder: (value) => value.toStringAsFixed(0),
                          tooltipValueBuilder: (value) =>
                              '${value.toStringAsFixed(0)} kcal',
                          bottomLabelBuilder: (value) {
                            final index = value.toInt();
                            if (index < 0 || index >= recentDays.length) {
                              return '';
                            }
                            return formatShortDate(recentDays[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppSection(
                  title: 'Consistency Map',
                  trailing: Text(
                    '$activeDays / ${recentDays.length} active days',
                  ),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '12-week signal map based on food, weight, workouts, water, and measurements.',
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: dayScoreMap.entries.map((entry) {
                            final color = _heatColor(context, entry.value);
                            return Tooltip(
                              message: '${entry.key} • score ${entry.value}/5',
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: color,
                                  border: Border.all(
                                    color: context.colors.border,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _LegendDot(
                              color: context.colors.surfaceHigher,
                              label: 'Low',
                            ),
                            const SizedBox(width: 12),
                            _LegendDot(
                              color: context.colors.goldDim,
                              label: 'Medium',
                            ),
                            const SizedBox(width: 12),
                            _LegendDot(
                              color: context.colors.gold,
                              label: 'High',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AppSection(
                  title: 'Records',
                  child: AppCard(
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('History & Records'),
                          subtitle: Text(
                            'Past-day editing, deletion, and audit trail.',
                          ),
                          trailing: Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HistoryScreen(),
                            ),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Diary'),
                          subtitle: Text('Calendar-style day log view.'),
                          trailing: Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DiaryScreen(),
                            ),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Settings'),
                          subtitle: Text(
                            'Profile, AI, exports, and system controls.',
                          ),
                          trailing: Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _dayScore(AppStateData data, String day) {
    var score = 0;
    if (data.foodLogs.any((item) => item.date == day)) {
      score += 1;
    }
    if (data.weightLogs.any((item) => item.date == day)) {
      score += 1;
    }
    if (data.workoutSessions.any((item) => item.date == day)) {
      score += 1;
    }
    if (data.waterLogs.any((item) => item.date == day)) {
      score += 1;
    }
    if (data.bodyMeasurements.any((item) => item.date == day)) {
      score += 1;
    }
    return score;
  }

  static double _chartMax(List<FlSpot> spots, {required double padding}) {
    if (spots.isEmpty) {
      return padding;
    }
    final max = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    return max + padding;
  }

  static double _chartMin(List<FlSpot> spots, {required double padding}) {
    if (spots.isEmpty) {
      return 0;
    }
    final min = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final value = min - padding;
    return value < 0 ? 0 : value;
  }

  static Color _heatColor(BuildContext context, int score) {
    switch (score) {
      case 0:
        return context.colors.surfaceHigher;
      case 1:
        return context.colors.goldDim.withValues(alpha: 0.55);
      case 2:
        return context.colors.sage.withValues(alpha: 0.65);
      case 3:
        return context.colors.gold.withValues(alpha: 0.78);
      case 4:
        return context.colors.terracotta.withValues(alpha: 0.85);
      default:
        return context.colors.gold;
    }
  }
}

class _MoreHeader extends StatelessWidget {
  const _MoreHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
      decoration: BoxDecoration(
        color: context.colors.background.withValues(alpha: 0.72),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MORE',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$name\'s trends, records, and system controls.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.currentWeight,
    required this.goalWeight,
    required this.deltaWeight,
    required this.avgCalories,
    required this.avgProtein,
    required this.proteinHits,
    required this.activeDays,
  });

  final double currentWeight;
  final double goalWeight;
  final double deltaWeight;
  final double avgCalories;
  final double avgProtein;
  final int proteinHits;
  final int activeDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.goldDim,
            context.colors.borderStrong,
            context.colors.surfaceHigher,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PROGRESS HUB',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: context.colors.gold),
              ),
              const SizedBox(height: 6),
              Text(
                'Smooth trends, raw signals, and fast access to every record.',
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wideTileWidth = ((constraints.maxWidth - 12) / 2).clamp(
                    132.0,
                    220.0,
                  );
                  final smallTileWidth = ((constraints.maxWidth - 24) / 3)
                      .clamp(100.0, 148.0);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: wideTileWidth,
                            child: AppMetricTile(
                              label: 'Current',
                              value: '${currentWeight.toStringAsFixed(1)} kg',
                              compact: true,
                            ),
                          ),
                          SizedBox(
                            width: wideTileWidth,
                            child: AppMetricTile(
                              label: 'Goal',
                              value: '${goalWeight.toStringAsFixed(1)} kg',
                              valueColor: context.colors.gold,
                              compact: true,
                            ),
                          ),
                          SizedBox(
                            width: wideTileWidth,
                            child: AppMetricTile(
                              label: 'From Start',
                              value:
                                  '${deltaWeight >= 0 ? '+' : ''}${deltaWeight.toStringAsFixed(1)} kg',
                              valueColor: deltaWeight <= 0
                                  ? context.colors.sage
                                  : context.colors.terracotta,
                              compact: true,
                            ),
                          ),
                          SizedBox(
                            width: wideTileWidth,
                            child: AppMetricTile(
                              label: 'Protein Hits',
                              value: '$proteinHits / 30',
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: smallTileWidth,
                            child: AppMetricTile(
                              label: 'Avg Calories',
                              value: avgCalories.toStringAsFixed(0),
                              compact: true,
                            ),
                          ),
                          SizedBox(
                            width: smallTileWidth,
                            child: AppMetricTile(
                              label: 'Avg Protein',
                              value: '${avgProtein.toStringAsFixed(0)} g',
                              compact: true,
                            ),
                          ),
                          SizedBox(
                            width: smallTileWidth,
                            child: AppMetricTile(
                              label: 'Active Days',
                              value: '$activeDays',
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.title,
    required this.subtitle,
    required this.chart,
  });

  final String title;
  final String subtitle;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          chart,
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.raw,
    required this.smooth,
    required this.rawColor,
    required this.smoothColor,
    required this.guideLineY,
    required this.guideLineColor,
    required this.minY,
    required this.maxY,
    required this.leftLabelBuilder,
    required this.tooltipValueBuilder,
    required this.bottomLabelBuilder,
  });

  final List<FlSpot> raw;
  final List<FlSpot> smooth;
  final Color rawColor;
  final Color smoothColor;
  final double guideLineY;
  final Color guideLineColor;
  final double minY;
  final double maxY;
  final String Function(double value) leftLabelBuilder;
  final String Function(double value) tooltipValueBuilder;
  final String Function(double value) bottomLabelBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: raw.isEmpty ? 1 : raw.last.x,
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: context.colors.border, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    leftLabelBuilder(value),
                    style: TextStyle(
                      color: context.colors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: raw.length > 10
                    ? (raw.length / 3).floorToDouble()
                    : 1,
                getTitlesWidget: (value, meta) {
                  final label = bottomLabelBuilder(value);
                  if (label.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: context.colors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => context.colors.surfaceHigh,
              getTooltipItems: (spots) => spots
                  .map(
                    (spot) => LineTooltipItem(
                      tooltipValueBuilder(spot.y),
                      TextStyle(
                        color: spot.bar.color ?? context.colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: guideLineY,
                color: guideLineColor.withValues(alpha: 0.75),
                strokeWidth: 1.2,
                dashArray: const [6, 6],
              ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: raw,
              isCurved: false,
              color: rawColor,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: rawColor.withValues(alpha: 0.1),
              ),
            ),
            LineChartBarData(
              spots: smooth,
              isCurved: true,
              color: smoothColor,
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineLegend extends StatelessWidget {
  const _LineLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendDot(color: context.colors.textTertiary, label: 'Raw'),
        SizedBox(width: 10),
        _LegendDot(color: context.colors.gold, label: 'Smooth'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

List<FlSpot> _movingAverage(List<FlSpot> spots, int window) {
  if (spots.isEmpty) {
    return const [];
  }
  final smoothed = <FlSpot>[];
  for (var index = 0; index < spots.length; index++) {
    final start = index - (window - 1);
    final clampedStart = start < 0 ? 0 : start;
    final segment = spots.sublist(clampedStart, index + 1);
    final avg =
        segment.fold<double>(0, (sum, item) => sum + item.y) / segment.length;
    smoothed.add(FlSpot(spots[index].x, avg));
  }
  return smoothed;
}
