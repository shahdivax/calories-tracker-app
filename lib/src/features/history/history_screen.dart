import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models.dart';
import '../../core/services/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui_kit/ui_kit.dart';

enum HistoryFocus { all, food, workouts, water, metrics }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({
    super.key,
    this.initialFocus = HistoryFocus.all,
    this.initialDay,
  });

  final HistoryFocus initialFocus;
  final String? initialDay;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  bool _isBusy = false;
  String _busyLabel = 'Working...';
  late HistoryFocus _focus;
  late DateTime _visibleMonth;
  String? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focus = widget.initialFocus;
    final seed = widget.initialDay == null
        ? DateTime.now()
        : parseDayKey(widget.initialDay!);
    _visibleMonth = DateTime(seed.year, seed.month);
    _selectedDay = widget.initialDay;
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appControllerProvider).valueOrNull;
    if (data == null) {
      return const SizedBox.shrink();
    }

    final allDays = <String>{
      ...data.foodLogs.map((item) => item.date),
      ...data.weightLogs.map((item) => item.date),
      ...data.waterLogs.map((item) => item.date),
      ...data.workoutSessions.map((item) => item.date),
      ...data.bodyMeasurements.map((item) => item.date),
      ...data.progressPhotos.map((item) => item.date),
    }.toList()..sort((a, b) => b.compareTo(a));
    final focusDays = _daysForFocus(data, _focus);
    final selectedDay = _resolveSelectedDay(focusDays, allDays);
    final monthCells = _buildMonthCells(_visibleMonth);

    return Scaffold(
      appBar: AppBar(title: Text('HISTORY & RECORDS')),
      body: AppLoadingOverlay(
        isBusy: _isBusy,
        label: _busyLabel,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _buildFocusSelector(context),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => setState(() {
                          _visibleMonth = DateTime(
                            _visibleMonth.year,
                            _visibleMonth.month - 1,
                          );
                        }),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        _monthLabel(_visibleMonth),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        onPressed: () => setState(() {
                          _visibleMonth = DateTime(
                            _visibleMonth.year,
                            _visibleMonth.month + 1,
                          );
                        }),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Expanded(child: _CalendarWeekday('MON')),
                      Expanded(child: _CalendarWeekday('TUE')),
                      Expanded(child: _CalendarWeekday('WED')),
                      Expanded(child: _CalendarWeekday('THU')),
                      Expanded(child: _CalendarWeekday('FRI')),
                      Expanded(child: _CalendarWeekday('SAT')),
                      Expanded(child: _CalendarWeekday('SUN')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: monthCells.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.9,
                        ),
                    itemBuilder: (context, index) {
                      final day = monthCells[index];
                      if (day == null) {
                        return const SizedBox.shrink();
                      }
                      final key = dayKey(day);
                      final score = _dayScore(data, key, _focus);
                      final hasData = focusDays.contains(key);
                      final isSelected = selectedDay == key;
                      final isToday = key == dayKey();
                      return _CalendarDayTile(
                        day: day.day,
                        isSelected: isSelected,
                        isToday: isToday,
                        hasData: hasData,
                        score: score,
                        onTap: () => setState(() {
                          _selectedDay = key;
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (selectedDay != null)
              _DaySummaryCard(
                day: selectedDay,
                foodCount: data.foodLogs
                    .where((item) => item.date == selectedDay)
                    .length,
                waterCount: data.waterLogs
                    .where((item) => item.date == selectedDay)
                    .length,
                workoutCount: data.workoutSessions
                    .where((item) => item.date == selectedDay)
                    .length,
                weightCount: data.weightLogs
                    .where((item) => item.date == selectedDay)
                    .length,
              ),
            const SizedBox(height: 16),
            if (allDays.isEmpty)
              const AppCard(child: Text('No historical records available yet.'))
            else if (selectedDay == null)
              const AppCard(child: Text('Pick a day to view records.'))
            else
              _DayRecordCard(
                day: selectedDay,
                focus: _focus,
                foodEntries: data.foodLogs
                    .where((item) => item.date == selectedDay)
                    .toList(),
                waterLogs: data.waterLogs
                    .where((item) => item.date == selectedDay)
                    .toList(),
                weightLogs: data.weightLogs
                    .where((item) => item.date == selectedDay)
                    .toList(),
                workoutSessions: data.workoutSessions
                    .where((item) => item.date == selectedDay)
                    .toList(),
                exerciseSets: data.exerciseSets,
                measurements: data.bodyMeasurements
                    .where((item) => item.date == selectedDay)
                    .toList(),
                progressPhotos: data.progressPhotos
                    .where((item) => item.date == selectedDay)
                    .toList(),
                onEditFood: (entry) => _editFoodEntry(data, entry),
                onDeleteFood: _deleteFoodEntry,
                onEditWater: _editWaterLog,
                onDeleteWater: _deleteWaterLog,
                onEditWeight: _editWeightLog,
                onDeleteWeight: _deleteWeightLog,
                onDeleteWorkout: _deleteWorkoutSession,
                onDeleteMeasurement: _deleteMeasurement,
                onDeletePhoto: _deletePhoto,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusSelector(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final value in HistoryFocus.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_focusLabel(value)),
                selected: _focus == value,
                onSelected: (_) => setState(() => _focus = value),
                selectedColor: context.colors.primary,
                backgroundColor: context.colors.surfaceHigher,
                labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: _focus == value ? Colors.black : Colors.white,
                ),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
        ],
      ),
    );
  }

  List<String> _daysForFocus(AppStateData data, HistoryFocus focus) {
    final days = switch (focus) {
      HistoryFocus.all => <String>{
        ...data.foodLogs.map((item) => item.date),
        ...data.weightLogs.map((item) => item.date),
        ...data.waterLogs.map((item) => item.date),
        ...data.workoutSessions.map((item) => item.date),
        ...data.bodyMeasurements.map((item) => item.date),
        ...data.progressPhotos.map((item) => item.date),
      },
      HistoryFocus.food => data.foodLogs.map((item) => item.date).toSet(),
      HistoryFocus.workouts =>
        data.workoutSessions.map((item) => item.date).toSet(),
      HistoryFocus.water => data.waterLogs.map((item) => item.date).toSet(),
      HistoryFocus.metrics => <String>{
        ...data.weightLogs.map((item) => item.date),
        ...data.bodyMeasurements.map((item) => item.date),
        ...data.progressPhotos.map((item) => item.date),
      },
    };
    final result = days.toList()..sort((a, b) => b.compareTo(a));
    return result;
  }

  String? _resolveSelectedDay(List<String> focusDays, List<String> allDays) {
    final candidate = _selectedDay ?? widget.initialDay;
    if (candidate != null) {
      return candidate;
    }
    if (focusDays.isNotEmpty) {
      return focusDays.first;
    }
    return allDays.firstOrNull;
  }

  List<DateTime?> _buildMonthCells(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingSlots = firstDay.weekday - 1;
    return [
      ...List<DateTime?>.filled(leadingSlots, null),
      ...List.generate(
        daysInMonth,
        (index) => DateTime(month.year, month.month, index + 1),
      ),
    ];
  }

  int _dayScore(AppStateData data, String day, HistoryFocus focus) {
    switch (focus) {
      case HistoryFocus.food:
        return data.foodLogs
            .where((item) => item.date == day)
            .length
            .clamp(0, 5);
      case HistoryFocus.workouts:
        return data.workoutSessions
            .where((item) => item.date == day)
            .length
            .clamp(0, 5);
      case HistoryFocus.water:
        return data.waterLogs
            .where((item) => item.date == day)
            .length
            .clamp(0, 5);
      case HistoryFocus.metrics:
        var score = 0;
        if (data.weightLogs.any((item) => item.date == day)) score++;
        if (data.bodyMeasurements.any((item) => item.date == day)) score++;
        if (data.progressPhotos.any((item) => item.date == day)) score++;
        return score;
      case HistoryFocus.all:
        var score = 0;
        if (data.foodLogs.any((item) => item.date == day)) score++;
        if (data.weightLogs.any((item) => item.date == day)) score++;
        if (data.waterLogs.any((item) => item.date == day)) score++;
        if (data.workoutSessions.any((item) => item.date == day)) score++;
        if (data.bodyMeasurements.any((item) => item.date == day)) score++;
        if (data.progressPhotos.any((item) => item.date == day)) score++;
        return score;
    }
  }

  String _focusLabel(HistoryFocus focus) {
    switch (focus) {
      case HistoryFocus.all:
        return 'Overview';
      case HistoryFocus.food:
        return 'Food';
      case HistoryFocus.workouts:
        return 'Workouts';
      case HistoryFocus.water:
        return 'Water';
      case HistoryFocus.metrics:
        return 'Metrics';
    }
  }

  String _monthLabel(DateTime value) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[value.month - 1]} ${value.year}';
  }

  Future<void> _editFoodEntry(AppStateData data, FoodLogEntry entry) async {
    final draft = await _showFoodEditDialog(entry);
    if (draft == null) {
      return;
    }
    if (draft.name.isEmpty || draft.quantity == null || draft.quantity! <= 0) {
      await _runBusyTask('Checking entry...', () async {
        throw Exception('Food name and quantity must be valid before saving.');
      });
      return;
    }
    await _runBusyTask('Updating food entry...', () async {
      final estimate = await _estimateFood(
        data: data,
        name: draft.name,
        quantity: draft.quantity!,
        quantityUnit: draft.quantityUnit,
        entryTitle: draft.sourceTitle,
        description: draft.description,
        fallbackFoods: data.customFoods,
      );
      await ref
          .read(appControllerProvider.notifier)
          .updateFoodEntry(
            FoodLogEntry(
              id: entry.id,
              date: entry.date,
              mealSlot: draft.mealSlot,
              foodName: draft.name,
              quantityG: draft.quantity!,
              quantityUnit: draft.quantityUnit,
              calories: estimate.calories,
              proteinG: estimate.proteinG,
              carbsG: estimate.carbsG,
              fatG: estimate.fatG,
              fiberG: estimate.fiberG,
              source: entry.source,
              description: draft.description,
              sourceTitle: draft.sourceTitle,
            ),
          );
    });
  }

  Future<void> _deleteFoodEntry(FoodLogEntry entry) async {
    final confirmed = await _confirmDelete(
      title: 'Delete food entry?',
      message: 'Remove ${entry.foodName} from ${formatShortDate(entry.date)}?',
    );
    if (!confirmed) {
      return;
    }
    await _runBusyTask(
      'Deleting food entry...',
      () => ref.read(appControllerProvider.notifier).removeFoodEntry(entry.id),
    );
  }

  Future<void> _editWaterLog(WaterLog log) async {
    final controller = TextEditingController(text: '${log.amountMl}');
    final amount = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit water log'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount',
            suffixText: 'ml',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(int.tryParse(controller.text)),
            child: Text('Save'),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) {
      return;
    }
    await _runBusyTask(
      'Updating water log...',
      () => ref
          .read(appControllerProvider.notifier)
          .upsertWaterLog(
            WaterLog(id: log.id, date: log.date, amountMl: amount),
          ),
    );
  }

  Future<void> _deleteWaterLog(WaterLog log) async {
    final confirmed = await _confirmDelete(
      title: 'Delete water log?',
      message: 'Remove ${log.amountMl} ml from ${formatShortDate(log.date)}?',
    );
    if (!confirmed) {
      return;
    }
    await _runBusyTask(
      'Deleting water log...',
      () => ref.read(appControllerProvider.notifier).removeWaterLog(log.id),
    );
  }

  Future<void> _editWeightLog(WeightLog log) async {
    final weightController = TextEditingController(
      text: log.weightKg.toStringAsFixed(1),
    );
    final notesController = TextEditingController(text: log.notes ?? '');
    final draft = await showDialog<_WeightEditDraft>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit weigh-in'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Weight',
                suffixText: 'kg',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              _WeightEditDraft(
                weightKg: double.tryParse(weightController.text),
                notes: notesController.text.trim(),
              ),
            ),
            child: Text('Save'),
          ),
        ],
      ),
    );
    if (draft?.weightKg == null || draft!.weightKg! <= 0) {
      return;
    }
    await _runBusyTask(
      'Updating weigh-in...',
      () => ref
          .read(appControllerProvider.notifier)
          .upsertWeightLog(
            WeightLog(
              id: log.id,
              date: log.date,
              weightKg: draft.weightKg!,
              notes: draft.notes.isEmpty ? null : draft.notes,
            ),
          ),
    );
  }

  Future<void> _deleteWeightLog(WeightLog log) async {
    final confirmed = await _confirmDelete(
      title: 'Delete weigh-in?',
      message:
          'Remove the ${log.weightKg.toStringAsFixed(1)} kg entry from ${formatShortDate(log.date)}?',
    );
    if (!confirmed) {
      return;
    }
    await _runBusyTask(
      'Deleting weigh-in...',
      () => ref.read(appControllerProvider.notifier).removeWeightLog(log.id),
    );
  }

  Future<void> _deleteWorkoutSession(WorkoutSession session) async {
    final confirmed = await _confirmDelete(
      title: 'Delete workout?',
      message:
          'Remove the ${session.type.label} workout from ${formatShortDate(session.date)}?',
    );
    if (!confirmed) {
      return;
    }
    await _runBusyTask(
      'Deleting workout...',
      () => ref
          .read(appControllerProvider.notifier)
          .removeWorkoutSession(session.id),
    );
  }

  Future<void> _deleteMeasurement(BodyMeasurement measurement) async {
    final confirmed = await _confirmDelete(
      title: 'Delete measurement?',
      message:
          'Remove this measurement record from ${formatShortDate(measurement.date)}?',
    );
    if (!confirmed) {
      return;
    }
    await _runBusyTask(
      'Deleting measurement...',
      () => ref
          .read(appControllerProvider.notifier)
          .removeBodyMeasurement(measurement.id),
    );
  }

  Future<void> _deletePhoto(ProgressPhoto photo) async {
    final confirmed = await _confirmDelete(
      title: 'Delete progress photo?',
      message:
          'Remove the ${photo.angle.label.toLowerCase()} photo from ${formatShortDate(photo.date)}?',
    );
    if (!confirmed) {
      return;
    }
    await _runBusyTask(
      'Deleting progress photo...',
      () => ref
          .read(appControllerProvider.notifier)
          .removeProgressPhoto(photo.id),
    );
  }

  Future<_FoodEditDraft?> _showFoodEditDialog(FoodLogEntry entry) async {
    final nameController = TextEditingController(text: entry.foodName);
    final quantityController = TextEditingController(
      text: entry.quantityG.toStringAsFixed(0),
    );
    final descriptionController = TextEditingController(
      text: entry.description ?? '',
    );
    final sourceTitleController = TextEditingController(
      text: entry.sourceTitle ?? '',
    );
    var mealSlot = entry.mealSlot;
    var quantityUnit = entry.quantityUnit;
    final showSourceTitle =
        entry.source == 'photo' || entry.source == 'package_label';

    return showDialog<_FoodEditDraft>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit food entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Food Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description / context (optional)',
                  ),
                ),
                if (showSourceTitle) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: sourceTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Upload title (optional)',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<FoodQuantityUnit>(
                  initialValue: quantityUnit,
                  items: FoodQuantityUnit.values
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(
                    () => quantityUnit = value ?? FoodQuantityUnit.grams,
                  ),
                  decoration: const InputDecoration(labelText: 'Quantity Unit'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<MealSlot>(
                  initialValue: mealSlot,
                  items: MealSlot.values
                      .map(
                        (slot) => DropdownMenuItem(
                          value: slot,
                          child: Text(slot.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => mealSlot = value ?? MealSlot.breakfast),
                  decoration: const InputDecoration(labelText: 'Meal Slot'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                _FoodEditDraft(
                  name: nameController.text.trim(),
                  description: _trimToNull(descriptionController.text),
                  sourceTitle: showSourceTitle
                      ? _trimToNull(sourceTitleController.text)
                      : null,
                  quantity: double.tryParse(quantityController.text),
                  quantityUnit: quantityUnit,
                  mealSlot: mealSlot,
                ),
              ),
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<ScannedFoodItem> _estimateFood({
    required AppStateData data,
    required String name,
    required double quantity,
    required FoodQuantityUnit quantityUnit,
    String? entryTitle,
    String? description,
    required List<CustomFood> fallbackFoods,
  }) async {
    try {
      return await ref
          .read(aiRuntimeServiceProvider)
          .estimateFoodFromText(
            data: data,
            foodName: name,
            quantity: quantity,
            quantityUnit: quantityUnit,
            entryTitle: entryTitle,
            foodDescription: description,
            preferHighSide: true,
          );
    } catch (_) {
      final fallback = fallbackFoods
          .where((food) => food.name.toLowerCase() == name.toLowerCase())
          .firstOrNull;
      if (fallback == null) {
        rethrow;
      }
      final scale = quantity / fallback.defaultServingUnit.referenceAmount;
      return ScannedFoodItem(
        name: name,
        estimatedPortionG: quantity,
        calories: fallback.caloriesPer100g * scale,
        proteinG: fallback.proteinPer100g * scale,
        carbsG: fallback.carbsPer100g * scale,
        fatG: fallback.fatPer100g * scale,
        fiberG: fallback.fiberPer100g * scale,
        confidence: 'fallback',
      );
    }
  }

  Future<bool> _confirmDelete({
    required String title,
    required String message,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _runBusyTask(String label, Future<void> Function() task) async {
    if (mounted) {
      setState(() {
        _isBusy = true;
        _busyLabel = label;
      });
    }
    try {
      await task();
    } catch (error) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Action failed'),
            content: Text(_formatError(error)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _busyLabel = 'Working...';
        });
      }
    }
  }

  String _formatError(Object error) {
    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    if (raw.startsWith('Bad state: ')) {
      return raw.substring('Bad state: '.length);
    }
    return raw;
  }
}

class _DayRecordCard extends StatelessWidget {
  const _DayRecordCard({
    required this.day,
    required this.focus,
    required this.foodEntries,
    required this.waterLogs,
    required this.weightLogs,
    required this.workoutSessions,
    required this.exerciseSets,
    required this.measurements,
    required this.progressPhotos,
    required this.onEditFood,
    required this.onDeleteFood,
    required this.onEditWater,
    required this.onDeleteWater,
    required this.onEditWeight,
    required this.onDeleteWeight,
    required this.onDeleteWorkout,
    required this.onDeleteMeasurement,
    required this.onDeletePhoto,
  });

  final String day;
  final HistoryFocus focus;
  final List<FoodLogEntry> foodEntries;
  final List<WaterLog> waterLogs;
  final List<WeightLog> weightLogs;
  final List<WorkoutSession> workoutSessions;
  final List<ExerciseSetLog> exerciseSets;
  final List<BodyMeasurement> measurements;
  final List<ProgressPhoto> progressPhotos;
  final ValueChanged<FoodLogEntry> onEditFood;
  final ValueChanged<FoodLogEntry> onDeleteFood;
  final ValueChanged<WaterLog> onEditWater;
  final ValueChanged<WaterLog> onDeleteWater;
  final ValueChanged<WeightLog> onEditWeight;
  final ValueChanged<WeightLog> onDeleteWeight;
  final ValueChanged<WorkoutSession> onDeleteWorkout;
  final ValueChanged<BodyMeasurement> onDeleteMeasurement;
  final ValueChanged<ProgressPhoto> onDeletePhoto;

  @override
  Widget build(BuildContext context) {
    final showFood = focus == HistoryFocus.all || focus == HistoryFocus.food;
    final showWater = focus == HistoryFocus.all || focus == HistoryFocus.water;
    final showWorkout =
        focus == HistoryFocus.all || focus == HistoryFocus.workouts;
    final showMetrics =
        focus == HistoryFocus.all || focus == HistoryFocus.metrics;

    return AppCard(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(formatShortDate(day)),
        subtitle: Text(
          '${foodEntries.length} foods • ${waterLogs.length} water • ${workoutSessions.length} workouts',
        ),
        initiallyExpanded: true,
        childrenPadding: EdgeInsets.zero,
        children: [
          if (showFood && foodEntries.isNotEmpty) ...[
            const Divider(),
            _SectionTitle('Foods'),
            ...foodEntries.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.foodName),
                subtitle: Text(_foodEntrySubtitle(entry)),
                trailing: Wrap(
                  spacing: 0,
                  children: [
                    IconButton(
                      onPressed: () => onEditFood(entry),
                      icon: Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: () => onDeleteFood(entry),
                      icon: Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (showWater && waterLogs.isNotEmpty) ...[
            const Divider(),
            _SectionTitle('Water'),
            ...waterLogs.map(
              (log) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${log.amountMl} ml'),
                subtitle: Text('Hydration entry'),
                trailing: Wrap(
                  spacing: 0,
                  children: [
                    IconButton(
                      onPressed: () => onEditWater(log),
                      icon: Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: () => onDeleteWater(log),
                      icon: Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (showMetrics && weightLogs.isNotEmpty) ...[
            const Divider(),
            _SectionTitle('Weigh-ins'),
            ...weightLogs.map(
              (log) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${log.weightKg.toStringAsFixed(1)} kg'),
                subtitle: Text(
                  log.notes?.isNotEmpty ?? false ? log.notes! : 'Weight record',
                ),
                trailing: Wrap(
                  spacing: 0,
                  children: [
                    IconButton(
                      onPressed: () => onEditWeight(log),
                      icon: Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: () => onDeleteWeight(log),
                      icon: Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (showWorkout && workoutSessions.isNotEmpty) ...[
            const Divider(),
            _SectionTitle('Workouts'),
            ...workoutSessions.map((session) {
              final sets = exerciseSets
                  .where((item) => item.sessionId == session.id)
                  .toList();
              final exerciseNames = sets
                  .map((item) => item.exerciseName)
                  .toSet()
                  .join(', ');
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${session.type.label} • ${session.durationMinutes} min',
                ),
                subtitle: Text(
                  exerciseNames.isEmpty
                      ? '${session.caloriesBurned.toStringAsFixed(0)} kcal burned'
                      : '$exerciseNames • ${sets.length} sets',
                ),
                trailing: IconButton(
                  onPressed: () => onDeleteWorkout(session),
                  icon: Icon(Icons.delete_outline),
                ),
              );
            }),
          ],
          if (showMetrics && measurements.isNotEmpty) ...[
            const Divider(),
            _SectionTitle('Measurements'),
            ...measurements.map(
              (measurement) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Waist ${measurement.waistCm?.toStringAsFixed(1) ?? '--'} • BF ${measurement.bodyFatPct?.toStringAsFixed(1) ?? '--'}',
                ),
                subtitle: Text(
                  measurement.notes?.isNotEmpty ?? false
                      ? measurement.notes!
                      : 'Body check-in',
                ),
                trailing: IconButton(
                  onPressed: () => onDeleteMeasurement(measurement),
                  icon: Icon(Icons.delete_outline),
                ),
              ),
            ),
          ],
          if (showMetrics && progressPhotos.isNotEmpty) ...[
            const Divider(),
            _SectionTitle('Progress Photos'),
            ...progressPhotos.map(
              (photo) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Image.file(
                      File(photo.path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: Color(0xFF1F1F1D),
                        child: Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                ),
                title: Text(photo.angle.label),
                subtitle: Text(photo.path.split('/').last),
                trailing: IconButton(
                  onPressed: () => onDeletePhoto(photo),
                  icon: Icon(Icons.delete_outline),
                ),
              ),
            ),
          ],
          if ((showFood && foodEntries.isEmpty) &&
              (showWater && waterLogs.isEmpty) &&
              (showWorkout && workoutSessions.isEmpty) &&
              (showMetrics &&
                  weightLogs.isEmpty &&
                  measurements.isEmpty &&
                  progressPhotos.isEmpty))
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('No records for this day in the selected view.'),
              ),
            ),
        ],
      ),
    );
  }
}

class _CalendarWeekday extends StatelessWidget {
  const _CalendarWeekday(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: context.colors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _CalendarDayTile extends StatelessWidget {
  const _CalendarDayTile({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.hasData,
    required this.score,
    required this.onTap,
  });

  final int day;
  final bool isSelected;
  final bool isToday;
  final bool hasData;
  final int score;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fill = switch (score) {
      0 => colors.surfaceHigher,
      1 => colors.primary.withValues(alpha: 0.18),
      2 => colors.primary.withValues(alpha: 0.3),
      3 => colors.secondary.withValues(alpha: 0.35),
      4 => colors.secondary.withValues(alpha: 0.5),
      _ => colors.primary,
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withValues(alpha: 0.18) : fill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : isToday
                ? colors.secondary.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.04),
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$day',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (hasData)
              Container(
                width: 10,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected ? colors.primary : colors.secondary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DaySummaryCard extends StatelessWidget {
  const _DaySummaryCard({
    required this.day,
    required this.foodCount,
    required this.waterCount,
    required this.workoutCount,
    required this.weightCount,
  });

  final String day;
  final int foodCount;
  final int waterCount;
  final int workoutCount;
  final int weightCount;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatShortDate(day),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(label: 'Food', value: '$foodCount'),
              ),
              Expanded(
                child: _SummaryMetric(label: 'Water', value: '$waterCount'),
              ),
              Expanded(
                child: _SummaryMetric(
                  label: 'Workouts',
                  value: '$workoutCount',
                ),
              ),
              Expanded(
                child: _SummaryMetric(label: 'Metrics', value: '$weightCount'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}

class _FoodEditDraft {
  const _FoodEditDraft({
    required this.name,
    required this.description,
    required this.sourceTitle,
    required this.quantity,
    required this.quantityUnit,
    required this.mealSlot,
  });

  final String name;
  final String? description;
  final String? sourceTitle;
  final double? quantity;
  final FoodQuantityUnit quantityUnit;
  final MealSlot mealSlot;
}

class _WeightEditDraft {
  const _WeightEditDraft({required this.weightKg, required this.notes});

  final double? weightKg;
  final String notes;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

String? _trimToNull(String text) {
  final trimmed = text.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _foodEntrySubtitle(FoodLogEntry entry) {
  final lines = <String>[
    '${entry.mealSlot.label} • ${entry.quantityG.toStringAsFixed(0)} ${entry.quantityUnit.shortLabel} • ${entry.calories.toStringAsFixed(0)} kcal',
  ];
  if (entry.sourceTitle != null && entry.sourceTitle!.isNotEmpty) {
    lines.add('Upload: ${entry.sourceTitle!}');
  }
  if (entry.description != null && entry.description!.isNotEmpty) {
    lines.add(entry.description!);
  }
  return lines.join('\n');
}
