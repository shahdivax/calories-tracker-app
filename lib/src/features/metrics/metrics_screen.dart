import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/data/models.dart';
import '../../core/services/app_controller.dart';
import '../../core/services/calculations.dart';
import '../../core/theme/app_theme.dart';

class MetricsScreen extends ConsumerStatefulWidget {
  const MetricsScreen({super.key});

  @override
  ConsumerState<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends ConsumerState<MetricsScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _neckController = TextEditingController();
  final TextEditingController _bodyFatController = TextEditingController();
  final TextEditingController _measurementNotesController =
      TextEditingController();

  bool _measurementSeeded = false;

  @override
  void dispose() {
    _weightController.dispose();
    _waistController.dispose();
    _neckController.dispose();
    _bodyFatController.dispose();
    _measurementNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appControllerProvider).valueOrNull;
    if (data == null) {
      return const SizedBox.shrink();
    }

    final targets = CalculationsEngine.targetsFor(
      data.profile,
      data.weightLogs,
    );
    final logs = [...data.weightLogs]..sort((a, b) => a.date.compareTo(b.date));
    final measurements = [...data.bodyMeasurements]
      ..sort((a, b) => b.date.compareTo(a.date));
    final photos = [...data.progressPhotos]
      ..sort((a, b) => b.date.compareTo(a.date));
    final trendLogs = logs.length > 12 ? logs.sublist(logs.length - 12) : logs;
    final trendLabels = _buildTrendLabels(trendLogs);
    final latestPhoto = photos.isEmpty ? null : photos.first;
    final latestMeasurement = measurements.isEmpty ? null : measurements.first;
    _seedMeasurementDraft(latestMeasurement, data.profile);

    final currentWeight = targets.weightKg;
    final weeklyChange = _periodChange(logs, days: 7);
    final totalChange = logs.isEmpty
        ? currentWeight - data.profile.startingWeightKg
        : currentWeight - logs.first.weightKg;
    final goalGap = currentWeight - data.profile.goalWeightKg;
    final colors = context.colors;
    final recentWeighIns = logs.reversed.take(4).toList();
    final recentMeasurements = measurements.take(3).toList();
    final weeklyMetricsInsight = _latestWeeklyMetricsInsight(data.aiInsights);
    final spanDays = trendLogs.length >= 2
        ? parseDayKey(
            trendLogs.last.date,
          ).difference(parseDayKey(trendLogs.first.date)).inDays.abs()
        : 0;

    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -60,
          right: -60,
          height: 280,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  colors.primary.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: colors.background.withValues(alpha: 0.8),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colors.surfaceHigher,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Metrics',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceHigher,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${photos.length} photos',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Weight Entry',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Row(
                            children: [
                              Icon(
                                weeklyChange <= 0
                                    ? Icons.trending_down
                                    : Icons.trending_up,
                                color: weeklyChange <= 0
                                    ? colors.primaryDim
                                    : colors.secondary,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${weeklyChange >= 0 ? '+' : ''}${weeklyChange.toStringAsFixed(1)} kg / 7d',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: weeklyChange <= 0
                                          ? colors.primaryDim
                                          : colors.secondary,
                                      letterSpacing: 1.2,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colors.surfaceHigher.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'CURRENT WEIGHT',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: colors.textSecondary,
                                              letterSpacing: 2,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            currentWeight.toStringAsFixed(1),
                                            style: Theme.of(context)
                                                .textTheme
                                                .displayLarge
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'KG',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  color: colors.primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'BODY FAT',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(letterSpacing: 1.5),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${targets.bodyFatPct?.toStringAsFixed(1) ?? '--'}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatPanel(
                                    label: 'START',
                                    value: data.profile.startingWeightKg
                                        .toStringAsFixed(1),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatPanel(
                                    label: 'GOAL',
                                    value: data.profile.goalWeightKg
                                        .toStringAsFixed(1),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatPanel(
                                    label: 'TOTAL',
                                    value:
                                        '${totalChange >= 0 ? '+' : ''}${totalChange.toStringAsFixed(1)}',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'UPDATE WEIGHT',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(letterSpacing: 1.5),
                                        ),
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller: _weightController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineLarge
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                              ),
                                          decoration: const InputDecoration(
                                            hintText: '00.0',
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                            isDense: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    height: 46,
                                    child: ElevatedButton.icon(
                                      onPressed: _logWeight,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                        ),
                                        minimumSize: const Size(0, 46),
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                      ),
                                      icon: const Icon(Icons.add, size: 14),
                                      label: const Text('LOG'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress Trends',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            trendLogs.length >= 2 ? '$spanDays DAYS' : 'RECENT',
                            style: Theme.of(
                              context,
                            ).textTheme.labelMedium?.copyWith(letterSpacing: 2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colors.surfaceHigher.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: SizedBox(
                          height: 220,
                          child: CustomPaint(
                            painter: _TrendPainter(
                              colors: colors,
                              logs: trendLogs,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    _LegendDot(
                                      color: colors.primary,
                                      label: 'Weight',
                                    ),
                                    const SizedBox(width: 16),
                                    _LegendDot(
                                      color: colors.secondary,
                                      label: 'Direction',
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    for (final label in trendLabels)
                                      _AxisLabel(label),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Measurement Check-In',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _MeasurementField(
                                    controller: _waistController,
                                    label: 'Waist',
                                    suffix: 'cm',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _MeasurementField(
                                    controller: _neckController,
                                    label: 'Neck',
                                    suffix: 'cm',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _MeasurementField(
                                    controller: _bodyFatController,
                                    label: 'Body Fat',
                                    suffix: '%',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _measurementNotesController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: 'Notes for this check-in',
                                filled: true,
                                fillColor: colors.surfaceHigher,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    latestMeasurement == null
                                        ? 'No saved measurement yet.'
                                        : 'Latest saved ${formatShortDate(latestMeasurement.date)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _saveMeasurement,
                                  icon: const Icon(Icons.straighten, size: 16),
                                  label: const Text('Save Check-In'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Body Composition',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.15,
                        children: [
                          _MetricBox(
                            label: 'BMI',
                            value: targets.bmi.toStringAsFixed(1),
                            progress: ((targets.bmi - 18) / 14).clamp(0.0, 1.0),
                            color: colors.primary,
                          ),
                          _MetricBox(
                            label: 'Lean Mass',
                            value:
                                '${targets.leanBodyMassKg?.toStringAsFixed(1) ?? '--'} kg',
                            progress:
                                ((targets.leanBodyMassKg ?? 0) / currentWeight)
                                    .clamp(0.0, 1.0),
                            color: colors.secondary,
                          ),
                          _MetricBox(
                            label: 'Fat Mass',
                            value:
                                '${targets.fatMassKg?.toStringAsFixed(1) ?? '--'} kg',
                            progress: ((targets.fatMassKg ?? 0) / currentWeight)
                                .clamp(0.0, 1.0),
                            color: colors.primaryDim,
                          ),
                          _MetricBox(
                            label: 'BMR',
                            value: '${targets.bmr.toStringAsFixed(0)} kcal',
                            progress: (targets.bmr / 2500).clamp(0.0, 1.0),
                            color: colors.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Visual Journey',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          GestureDetector(
                            onTap: () => _pickProgressPhoto(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 16,
                                    color: colors.primaryDim,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ADD PHOTO',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: colors.primaryDim,
                                          letterSpacing: 1.2,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (latestPhoto != null)
                        GestureDetector(
                          onTap: () => _previewPhoto(latestPhoto),
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Column(
                              children: [
                                AspectRatio(
                                  aspectRatio: 4 / 5,
                                  child: Image.file(
                                    File(latestPhoto.path),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        Container(color: colors.surfaceHigher),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.surfaceHigher
                                              .withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          '${formatShortDate(latestPhoto.date)} • ${latestPhoto.angle.label}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(color: Colors.white),
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        onPressed: () =>
                                            _deletePhoto(latestPhoto),
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: colors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 220,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'No progress photos yet',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      if (photos.length > 1) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 116,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: photos.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final photo = photos[index];
                              return _PhotoThumb(
                                photo: photo,
                                onTap: () => _previewPhoto(photo),
                                onDelete: () => _deletePhoto(photo),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _RecentListCard(
                              title: 'Recent Weigh-Ins',
                              emptyLabel: 'No weigh-ins yet',
                              children: recentWeighIns
                                  .map(
                                    (log) => _RecentLine(
                                      leading: formatShortDate(log.date),
                                      trailing:
                                          '${log.weightKg.toStringAsFixed(1)} kg',
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _RecentListCard(
                              title: 'Recent Check-Ins',
                              emptyLabel: 'No measurements yet',
                              children: recentMeasurements
                                  .map(
                                    (entry) => _RecentLine(
                                      leading: formatShortDate(entry.date),
                                      trailing:
                                          '${entry.waistCm?.toStringAsFixed(1) ?? '--'} cm',
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.insights,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Analysis',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    weeklyMetricsInsight == null
                                        ? 'Local weekly summary until Saturday-end AI is ready.'
                                        : 'AI weekly check-in • week ending ${formatShortDate(weeklyMetricsInsight.date)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: colors.primary,
                                          letterSpacing: 0.6,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    weeklyMetricsInsight?.text ??
                                        _analysisText(
                                          weeklyChange: weeklyChange,
                                          goalGap: goalGap,
                                          bodyFat: targets.bodyFatPct,
                                          photoCount: photos.length,
                                        ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'GOAL GAP',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(letterSpacing: 1.2),
                                ),
                                Text(
                                  goalGap.abs().toStringAsFixed(1),
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                        color: colors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _seedMeasurementDraft(
    BodyMeasurement? latestMeasurement,
    BodyProfile profile,
  ) {
    if (_measurementSeeded) {
      return;
    }
    if (latestMeasurement?.waistCm != null) {
      _waistController.text = latestMeasurement!.waistCm!.toStringAsFixed(1);
    } else if (profile.waistCm != null) {
      _waistController.text = profile.waistCm!.toStringAsFixed(1);
    }
    if (latestMeasurement?.neckCm != null) {
      _neckController.text = latestMeasurement!.neckCm!.toStringAsFixed(1);
    } else if (profile.neckCm != null) {
      _neckController.text = profile.neckCm!.toStringAsFixed(1);
    }
    if (latestMeasurement?.bodyFatPct != null) {
      _bodyFatController.text = latestMeasurement!.bodyFatPct!.toStringAsFixed(
        1,
      );
    } else if (profile.bodyFatPct != null) {
      _bodyFatController.text = profile.bodyFatPct!.toStringAsFixed(1);
    }
    _measurementSeeded = true;
  }

  List<String> _buildTrendLabels(List<WeightLog> logs) {
    if (logs.isEmpty) {
      return const ['START', '', '', '', 'NOW'];
    }
    if (logs.length == 1) {
      final label = formatShortDate(logs.first.date);
      return [label, '', '', '', label];
    }
    final indexes = [0, 1, 2, 3, 4].map((step) {
      final raw = ((logs.length - 1) * (step / 4)).round();
      return raw.clamp(0, logs.length - 1);
    }).toList();
    return indexes.map((index) => formatShortDate(logs[index].date)).toList();
  }

  double _periodChange(List<WeightLog> logs, {required int days}) {
    if (logs.length < 2) {
      return 0;
    }
    final latest = logs.last;
    final latestDate = parseDayKey(latest.date);
    WeightLog baseline = logs.first;
    for (final log in logs.reversed) {
      final logDate = parseDayKey(log.date);
      if (latestDate.difference(logDate).inDays >= days) {
        baseline = log;
        break;
      }
    }
    return latest.weightKg - baseline.weightKg;
  }

  Future<void> _logWeight() async {
    final value = double.tryParse(_weightController.text);
    if (value == null || value <= 0) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid weight first.')),
      );
      return;
    }
    await ref.read(appControllerProvider.notifier).addWeightLog(value);
    _weightController.clear();
  }

  Future<void> _saveMeasurement() async {
    final waist = double.tryParse(_waistController.text);
    final neck = double.tryParse(_neckController.text);
    final bodyFat = double.tryParse(_bodyFatController.text);
    if (waist == null && neck == null && bodyFat == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one measurement value.')),
      );
      return;
    }

    await ref
        .read(appControllerProvider.notifier)
        .addBodyMeasurement(
          BodyMeasurement(
            id: 'measure-${DateTime.now().microsecondsSinceEpoch}',
            date: dayKey(),
            waistCm: waist,
            neckCm: neck,
            bodyFatPct: bodyFat,
            notes: _measurementNotesController.text.trim().isEmpty
                ? null
                : _measurementNotesController.text.trim(),
          ),
        );
    _measurementNotesController.clear();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Measurement check-in saved.')),
    );
  }

  Future<void> _pickProgressPhoto(BuildContext context) async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null) {
        return;
      }
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) {
        return;
      }
      if (!context.mounted) {
        return;
      }
      final angle = await showModalBottomSheet<ProgressPhotoAngle>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final value in ProgressPhotoAngle.values)
                ListTile(
                  title: Text(value.label),
                  onTap: () => Navigator.of(context).pop(value),
                ),
            ],
          ),
        ),
      );
      if (angle == null) {
        return;
      }
      await ref
          .read(appControllerProvider.notifier)
          .addProgressPhoto(
            ProgressPhoto(
              id: 'photo-${DateTime.now().microsecondsSinceEpoch}',
              date: dayKey(),
              angle: angle,
              path: picked.path,
            ),
          );
    } catch (_) {}
  }

  Future<void> _deletePhoto(ProgressPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete photo?'),
        content: Text(
          'Remove ${photo.angle.label} photo from ${formatShortDate(photo.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref
        .read(appControllerProvider.notifier)
        .removeProgressPhoto(photo.id);
  }

  Future<void> _previewPhoto(ProgressPhoto photo) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Image.file(File(photo.path), fit: BoxFit.cover),
              Positioned(
                top: 12,
                right: 12,
                child: IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _analysisText({
    required double weeklyChange,
    required double goalGap,
    required double? bodyFat,
    required int photoCount,
  }) {
    final movement = weeklyChange.abs() < 0.1
        ? 'mostly flat this week'
        : weeklyChange < 0
        ? 'trending down this week'
        : 'moving up this week';
    final bodyFatText = bodyFat == null
        ? 'Body-fat estimate still needs more check-ins, because guessing in the mirror is not science.'
        : 'Body-fat estimate is sitting around ${bodyFat.toStringAsFixed(1)}%.';
    final goalText = goalGap.abs() < 0.5
        ? 'You are effectively at goal.'
        : '${goalGap.abs().toStringAsFixed(1)} kg remains to your target, so the finish line is visible but still judging your snacks.';
    final photoText = photoCount == 0
        ? 'No photo baseline yet, which is bold for someone expecting visual progress.'
        : '$photoCount photo check-ins logged, so at least the evidence department is open.';
    return 'Weight is $movement. $bodyFatText $goalText $photoText';
  }

  AiInsight? _latestWeeklyMetricsInsight(List<AiInsight> insights) {
    final weekly =
        insights.where((item) => item.type == 'metrics-weekly').toList()
          ..sort((a, b) {
            final aTime =
                DateTime.tryParse(a.createdAt ?? '') ?? parseDayKey(a.date);
            final bTime =
                DateTime.tryParse(b.createdAt ?? '') ?? parseDayKey(b.date);
            return aTime.compareTo(bTime);
          });
    return weekly.isEmpty ? null : weekly.last;
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: context.colors.textSecondary.withValues(alpha: 0.4),
          fontSize: 10,
        ),
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(letterSpacing: 1.8),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: context.colors.surfaceHigher,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementField extends StatelessWidget {
  const _MeasurementField({
    required this.controller,
    required this.label,
    required this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: context.colors.surfaceHigher,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _StatPanel extends StatelessWidget {
  const _StatPanel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.colors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
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

class _RecentListCard extends StatelessWidget {
  const _RecentListCard({
    required this.title,
    required this.emptyLabel,
    required this.children,
  });

  final String title;
  final String emptyLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (children.isEmpty)
            Text(emptyLabel, style: Theme.of(context).textTheme.bodySmall)
          else
            ...children,
        ],
      ),
    );
  }
}

class _RecentLine extends StatelessWidget {
  const _RecentLine({required this.leading, required this.trailing});

  final String leading;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(leading, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(
            trailing,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({
    required this.photo,
    required this.onTap,
    required this.onDelete,
  });

  final ProgressPhoto photo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 88,
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(photo.path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Container(color: context.colors.surfaceHigher),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              photo.angle.label.toUpperCase(),
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

class _TrendPainter extends CustomPainter {
  const _TrendPainter({required this.colors, required this.logs});

  final AppColors colors;
  final List<WeightLog> logs;

  @override
  void paint(Canvas canvas, Size size) {
    final chartBottom = size.height * 0.85;
    final chartHeight = size.height * 0.5;
    final points = logs.isEmpty
        ? [
            Offset(0, size.height * 0.8),
            Offset(size.width * 0.2, size.height * 0.72),
            Offset(size.width * 0.45, size.height * 0.75),
            Offset(size.width * 0.7, size.height * 0.52),
            Offset(size.width, size.height * 0.35),
          ]
        : List.generate(logs.length, (i) {
            final x = logs.length == 1
                ? size.width / 2
                : (size.width / (logs.length - 1)) * i;
            final min = logs
                .map((e) => e.weightKg)
                .reduce((a, b) => a < b ? a : b);
            final max = logs
                .map((e) => e.weightKg)
                .reduce((a, b) => a > b ? a : b);
            final range = (max - min).abs() < 0.01 ? 1.0 : (max - min);
            final y =
                chartBottom - ((logs[i].weightKg - min) / range) * chartHeight;
            return Offset(x, y);
          });

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.32 + (i * 0.18));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final cp = Offset((prev.dx + current.dx) / 2, prev.dy);
      path.quadraticBezierTo(cp.dx, cp.dy, current.dx, current.dy);
    }

    final trendStart = points.first;
    final trendEnd = points.last;
    final trendPath = Path()
      ..moveTo(trendStart.dx, trendStart.dy)
      ..lineTo(trendEnd.dx, trendEnd.dy);

    final primaryPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF85ADFF), Color(0xFF0070EB)],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final trendPaint = Paint()
      ..color = colors.secondary.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(trendPath, trendPaint);
    canvas.drawPath(path, primaryPaint);

    final latest = points.last;
    canvas.drawCircle(latest, 6, Paint()..color = colors.primary);
    canvas.drawCircle(
      latest,
      14,
      Paint()..color = colors.primary.withValues(alpha: 0.2),
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.logs != logs || oldDelegate.colors != colors;
  }
}
