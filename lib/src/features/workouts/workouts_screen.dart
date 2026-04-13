import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models.dart';
import '../../core/data/workout_presets.dart';
import '../../core/services/ai_runtime_service.dart';
import '../../core/services/app_controller.dart';
import '../../core/services/calculations.dart';
import '../../core/theme/app_theme.dart';
import '../history/history_screen.dart';

class WorkoutsScreen extends ConsumerStatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  ConsumerState<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends ConsumerState<WorkoutsScreen> {
  WorkoutType _type = WorkoutType.push;
  int _duration = 60;
  double _met = 5.0;
  bool _isSaving = false;
  int _selectedPresetIndex = 0;
  int? _expandedExerciseIndex = 0;
  final TextEditingController _notesController = TextEditingController();
  final List<_ExerciseDraft> _exerciseDrafts = [_ExerciseDraft()];

  static const _heroImages = <WorkoutType, String>{
    WorkoutType.pull:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCcbwCp0WC3GM_d7ZdOxWNbyFhFVJRvBlllSKjCEuNExhWOjMnCNd-rhTCDJUhfEZ581OAzdmkwhKr-Kk8_lIwwKxkNUaT6hSJuZcQMV8a5vp27c6y2JRm6e4scG-Gtv-JPOmFf0N489ylGDdXVYN5U2qr5g6BibuZgf6_U7PBY2kIVLY3PgJNX7Tp_9UFfTN2BIkUXlO7BJ-DD-GhY8acC886Jq9g17GcMfYj7CuvZAsg4ZUMJ9e8SGvX1RnSGXnrWtNLihZRy7mE',
    WorkoutType.push:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBYuNTU6CDLlOgDf0ET15KHzVFgnlB7GVqSCj0JfF_MFF0tp1Ha9xopDhajHTM7cnhKe24UzVZHbpl67jX-FPtWjEkLnUEfjk3Lny1NQYt4xOL3lViX7QeB60aebgIrDazG0eLBOMF7CToH76m2N9_XLsM7T3yLaeNAVRT2y4IGaBQuX9WJVAyurdG2zJmEHEmXM5KwTtwdf3XW65TA9zENZFW4CG3XMUp3kzUTxQuEBc_Xp6GadLikw6IUEcJwFPTRG7nOmgba8tM',
  };

  @override
  void initState() {
    super.initState();
    _applyPreset(WorkoutPresetLibrary.presets.first);
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final draft in _exerciseDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appControllerProvider).valueOrNull;
    if (data == null) {
      return const SizedBox.shrink();
    }

    final currentWeight = CalculationsEngine.currentWeight(
      data.profile,
      data.weightLogs,
    );
    final estimatedBurn = CalculationsEngine.workoutCalories(
      weightKg: currentWeight,
      durationMinutes: _duration,
      met: _met,
    );
    final sessions = [...data.workoutSessions]
      ..sort((a, b) => b.date.compareTo(a.date));
    final presets = WorkoutPresetLibrary.presets;
    final colors = context.colors;
    final recentExerciseHistory = _buildRecentExerciseHistory(
      sessions,
      data.exerciseSets,
    );
    final thisWeekSessions = _currentWeekSessions(data.workoutSessions);
    final weeklyMinutes = thisWeekSessions.fold<int>(
      0,
      (sum, session) => sum + session.durationMinutes,
    );
    final weeklyBurn = thisWeekSessions.fold<double>(
      0,
      (sum, session) => sum + session.caloriesBurned,
    );

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            right: -80,
            height: 280,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.14),
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
                      Text(
                        'Workouts',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Row(
                        children: [
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
                              '${thisWeekSessions.length} this week',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const HistoryScreen(
                                  initialFocus: HistoryFocus.workouts,
                                ),
                              ),
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: colors.surfaceHigher,
                              foregroundColor: colors.primary,
                            ),
                            icon: const Icon(Icons.calendar_month, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    children: [
                      _WeekStrip(
                        colors: colors,
                        sessions: data.workoutSessions,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _WeeklyStat(
                                label: 'Sessions',
                                value: thisWeekSessions.length.toString(),
                              ),
                            ),
                            Expanded(
                              child: _WeeklyStat(
                                label: 'Minutes',
                                value: weeklyMinutes.toString(),
                              ),
                            ),
                            Expanded(
                              child: _WeeklyStat(
                                label: 'Burn',
                                value: weeklyBurn.toStringAsFixed(0),
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
                            'Active Session',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          TextButton(
                            onPressed: () => _showPresetPicker(presets),
                            child: Text(
                              'CHANGE',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: colors.primary,
                                    letterSpacing: 2,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 192,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: presets.length.clamp(0, 6),
                          separatorBuilder: (_, _) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final preset = presets[index];
                            final selected = index == _selectedPresetIndex;
                            return _WorkoutHeroCard(
                              preset: preset,
                              selected: selected,
                              imageUrl: _heroImages[preset.type],
                              onTap: () {
                                setState(() => _selectedPresetIndex = index);
                                _applyPreset(preset);
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Exercises',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              Text(
                                '${_exerciseDrafts.length} planned • $_duration min block',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _showExercisePicker,
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
                                    Icons.add,
                                    size: 16,
                                    color: colors.primaryDim,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ADD EXERCISE',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: colors.primaryDim,
                                          letterSpacing: 1.5,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(_exerciseDrafts.length, (index) {
                        final draft = _exerciseDrafts[index];
                        final history =
                            recentExerciseHistory[draft.exerciseName
                                .trim()
                                .toLowerCase()] ??
                            const <ExerciseSetLog>[];
                        final isExpanded = index == _expandedExerciseIndex;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _WorkoutExerciseCard(
                            draft: draft,
                            expanded: isExpanded,
                            previousSets: history,
                            onTap: () => setState(
                              () => _expandedExerciseIndex = isExpanded
                                  ? null
                                  : index,
                            ),
                            onRemove: _exerciseDrafts.length == 1
                                ? null
                                : () {
                                    setState(() {
                                      _exerciseDrafts[index].dispose();
                                      _exerciseDrafts.removeAt(index);
                                      if (_exerciseDrafts.isEmpty) {
                                        _expandedExerciseIndex = null;
                                      } else if (_expandedExerciseIndex ==
                                          index) {
                                        _expandedExerciseIndex = null;
                                      } else if (_expandedExerciseIndex !=
                                              null &&
                                          _expandedExerciseIndex! > index) {
                                        _expandedExerciseIndex =
                                            _expandedExerciseIndex! - 1;
                                      }
                                    });
                                  },
                            onAddSet: () {
                              setState(() {
                                final nextSets = (draft.sets + 1).clamp(1, 6);
                                draft.setsController.text = '$nextSets';
                              });
                            },
                            onRemoveSet: draft.sets <= 1
                                ? null
                                : () {
                                    setState(() {
                                      draft.setsController.text =
                                          '${draft.sets - 1}';
                                    });
                                  },
                            onChanged: () => setState(() {}),
                          ),
                        );
                      }),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
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
                                    Icons.bolt,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Session Controls',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Intensity ${_intensityLabel(_met)} • ${currentWeight.toStringAsFixed(0)}kg profile • ${estimatedBurn.toStringAsFixed(0)} kcal est.',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: _AdjusterCard(
                                    label: 'Duration',
                                    value: '$_duration min',
                                    onDecrease: () {
                                      setState(() {
                                        _duration = (_duration - 5).clamp(
                                          10,
                                          180,
                                        );
                                      });
                                    },
                                    onIncrease: () {
                                      setState(() {
                                        _duration = (_duration + 5).clamp(
                                          10,
                                          180,
                                        );
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _AdjusterCard(
                                    label: 'MET',
                                    value: _met.toStringAsFixed(1),
                                    onDecrease: () {
                                      setState(() {
                                        _met = (_met - 0.5).clamp(2.0, 12.0);
                                      });
                                    },
                                    onIncrease: () {
                                      setState(() {
                                        _met = (_met + 0.5).clamp(2.0, 12.0);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Session Type',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(letterSpacing: 1.2),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final type in WorkoutType.values)
                                  FilterChip(
                                    label: Text(type.label.toUpperCase()),
                                    selected: _type == type,
                                    onSelected: (_) =>
                                        setState(() => _type = type),
                                    selectedColor: colors.primary,
                                    checkmarkColor: Colors.black,
                                    labelStyle: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: _type == type
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                    backgroundColor: colors.surfaceHigher,
                                    side: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText:
                                    'Session notes, cues, machine settings',
                                filled: true,
                                fillColor: colors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () => _logWorkout(data, currentWeight),
                          child: Text(_isSaving ? 'SAVING...' : 'LOG WORKOUT'),
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (sessions.isNotEmpty) ...[
                        Text(
                          'Recent Sessions',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 12),
                        ...sessions
                            .take(6)
                            .map(
                              (session) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _SessionHistoryCard(
                                  session: session,
                                  sets: data.exerciseSets
                                      .where((s) => s.sessionId == session.id)
                                      .toList(),
                                  onDelete: () => _deleteWorkout(session),
                                ),
                              ),
                            ),
                      ],
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

  List<WorkoutSession> _currentWeekSessions(List<WorkoutSession> sessions) {
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final startKey = dayKey(weekStart);
    return sessions
        .where((session) => session.date.compareTo(startKey) >= 0)
        .toList();
  }

  Map<String, List<ExerciseSetLog>> _buildRecentExerciseHistory(
    List<WorkoutSession> sessions,
    List<ExerciseSetLog> sets,
  ) {
    final history = <String, List<ExerciseSetLog>>{};
    for (final session in sessions) {
      final sessionSets =
          sets.where((item) => item.sessionId == session.id).toList()
            ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
      final grouped = <String, List<ExerciseSetLog>>{};
      for (final set in sessionSets) {
        final key = set.exerciseName.trim().toLowerCase();
        grouped.putIfAbsent(key, () => <ExerciseSetLog>[]).add(set);
      }
      grouped.forEach((key, value) {
        history.putIfAbsent(key, () => value);
      });
    }
    return history;
  }

  void _showPresetPicker(List<WorkoutPreset> presets) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colors.surfaceHigh,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Change Session',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(presets.length, (index) {
              final preset = presets[index];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(preset.name),
                subtitle: Text('${preset.type.label} • ${preset.description}'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedPresetIndex = index);
                  _applyPreset(preset);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showExercisePicker() {
    final exercisesByName = <String, WorkoutPresetExercise>{};
    for (final preset in WorkoutPresetLibrary.presets) {
      for (final exercise in preset.exercises) {
        exercisesByName.putIfAbsent(exercise.name, () => exercise);
      }
    }
    final options = exercisesByName.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colors.surfaceHigh,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Exercise',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 360,
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final ex = options[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.colors.surfaceHigher,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.fitness_center),
                    ),
                    title: Text(ex.name),
                    subtitle: Text('${ex.muscleGroup} • ${ex.sets}x${ex.reps}'),
                    onTap: () {
                      setState(() {
                        _exerciseDrafts.add(_ExerciseDraft.fromPreset(ex));
                        _expandedExerciseIndex = _exerciseDrafts.length - 1;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyPreset(WorkoutPreset preset) {
    setState(() {
      for (final draft in _exerciseDrafts) {
        draft.dispose();
      }
      _exerciseDrafts
        ..clear()
        ..addAll(preset.exercises.map(_ExerciseDraft.fromPreset));
      _expandedExerciseIndex = _exerciseDrafts.isEmpty ? null : 0;
      _type = preset.type;
      _duration = preset.durationMinutes;
      _met = preset.met;
      _notesController.text = preset.notes ?? '';
    });
  }

  Future<void> _logWorkout(AppStateData data, double currentWeight) async {
    final filledDrafts = _exerciseDrafts
        .where((draft) => draft.exerciseName.trim().isNotEmpty)
        .toList();
    if (_type != WorkoutType.rest && filledDrafts.isEmpty) {
      await _showMessageDialog(
        title: 'No exercises added',
        message: 'Add at least one exercise before logging.',
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final sessionId = 'workout-${DateTime.now().microsecondsSinceEpoch}';
      final fallbackBurn = CalculationsEngine.workoutCalories(
        weightKg: currentWeight,
        durationMinutes: _duration,
        met: _met,
      );
      final aiEstimate = await _estimateWorkoutCalories(
        data: data,
        currentWeight: currentWeight,
        filledDrafts: filledDrafts,
      );
      final resolvedCalories = aiEstimate?.caloriesBurned ?? fallbackBurn;
      final session = WorkoutSession(
        id: sessionId,
        date: dayKey(),
        type: _type,
        durationMinutes: _duration,
        caloriesBurned: resolvedCalories,
        muscleGroups: filledDrafts
            .map((item) => item.muscleGroup.trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList(),
        notes: _buildWorkoutNotes(aiEstimate),
      );

      final sets = <ExerciseSetLog>[];
      for (final draft in filledDrafts) {
        for (var setNumber = 1; setNumber <= draft.sets; setNumber++) {
          sets.add(
            ExerciseSetLog(
              id: 'set-${DateTime.now().microsecondsSinceEpoch}-${draft.exerciseName}-$setNumber',
              sessionId: sessionId,
              exerciseName: draft.exerciseName.trim(),
              muscleGroup: draft.muscleGroup.trim(),
              setNumber: setNumber,
              reps: draft.reps,
              weightKg: draft.weightKg,
              isWarmup: draft.firstSetWarmup && setNumber == 1,
              isFailure: draft.lastSetFailure && setNumber == draft.sets,
              isPr: draft.lastSetPr && setNumber == draft.sets,
            ),
          );
        }
      }

      await ref
          .read(appControllerProvider.notifier)
          .addWorkoutWithSets(session, sets);
      if (!mounted) {
        return;
      }
      _applyPreset(WorkoutPresetLibrary.presets[_selectedPresetIndex]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            aiEstimate == null
                ? '${session.type.label} session logged with ${sets.length} sets.'
                : '${session.type.label} session logged with AI-calculated burn: ${resolvedCalories.toStringAsFixed(0)} kcal.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<WorkoutCalorieEstimate?> _estimateWorkoutCalories({
    required AppStateData data,
    required double currentWeight,
    required List<_ExerciseDraft> filledDrafts,
  }) async {
    if (!data.aiSettings.enabled || data.aiSettings.apiKey.trim().isEmpty) {
      return null;
    }
    try {
      final estimate = await ref
          .read(aiRuntimeServiceProvider)
          .estimateWorkoutSession(
            data: data,
            workoutType: _type,
            durationMinutes: _duration,
            fallbackMet: _met,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            exercises: filledDrafts
                .map(
                  (draft) => {
                    'name': draft.exerciseName.trim(),
                    'muscle_group': draft.muscleGroup.trim(),
                    'sets': draft.sets,
                    'reps': draft.reps,
                    'weight_kg': draft.weightKg,
                    'first_set_warmup': draft.firstSetWarmup,
                    'last_set_failure': draft.lastSetFailure,
                    'last_set_pr': draft.lastSetPr,
                    'current_weight_kg': currentWeight,
                  },
                )
                .toList(),
          );
      return WorkoutCalorieEstimate(
        caloriesBurned: estimate.caloriesBurned.clamp(40, 2000).toDouble(),
        met: estimate.met.clamp(2.0, 14.0).toDouble(),
        summary: estimate.summary,
      );
    } catch (_) {
      return null;
    }
  }

  String? _buildWorkoutNotes(WorkoutCalorieEstimate? aiEstimate) {
    final base = _notesController.text.trim();
    final lines = <String>[
      if (base.isNotEmpty) base,
      if (aiEstimate != null) 'AI burn context: ${aiEstimate.summary}',
    ];
    return lines.isEmpty ? null : lines.join('\n');
  }

  Future<void> _deleteWorkout(WorkoutSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete session?'),
        content: Text(
          'Remove ${session.type.label} from ${formatShortDate(session.date)}?',
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
        .removeWorkoutSession(session.id);
  }

  Future<void> _showMessageDialog({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _intensityLabel(double met) {
    if (met >= 7) {
      return 'High';
    }
    if (met >= 5) {
      return 'Moderate';
    }
    return 'Light';
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.colors, required this.sessions});

  final AppColors colors;
  final List<WorkoutSession> sessions;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final days = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );
    const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_monthLabel(now.month)} ${now.year}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.textSecondary,
                letterSpacing: 2,
              ),
            ),
            Text(
              'Current Week',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.primary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(days.length, (index) {
              final day = days[index];
              final key = dayKey(day);
              final isToday = key == dayKey();
              final isFuture = day.isAfter(
                DateTime(now.year, now.month, now.day),
              );
              final completed = sessions.any((session) => session.date == key);
              return Opacity(
                opacity: isFuture ? 0.45 : 1,
                child: Column(
                  children: [
                    Text(
                      labels[index],
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isToday ? colors.primary : colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isToday
                                ? colors.primary
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: isToday
                                ? null
                                : Border.all(
                                    color: completed
                                        ? colors.primary.withValues(alpha: 0.4)
                                        : Colors.white.withValues(alpha: 0.05),
                                  ),
                          ),
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: isToday ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (completed && !isToday)
                          Positioned(
                            bottom: 2,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: colors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  String _monthLabel(int month) {
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
    return months[month - 1];
  }
}

class _WorkoutHeroCard extends StatelessWidget {
  const _WorkoutHeroCard({
    required this.preset,
    required this.selected,
    required this.onTap,
    this.imageUrl,
  });

  final WorkoutPreset preset;
  final bool selected;
  final VoidCallback onTap;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: selected ? 280 : 240,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: selected
              ? Border.all(color: context.colors.primary, width: 2)
              : Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: imageUrl == null
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            context.colors.surfaceHigher,
                            context.colors.surface,
                          ],
                        ),
                      ),
                    )
                  : Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      opacity: const AlwaysStoppedAnimation(.45),
                    ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (selected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'CURRENT',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (selected) const SizedBox(height: 8),
                  Text(
                    preset.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preset.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(
                        alpha: selected ? 0.65 : 0.4,
                      ),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutExerciseCard extends StatelessWidget {
  const _WorkoutExerciseCard({
    required this.draft,
    required this.expanded,
    required this.previousSets,
    required this.onTap,
    required this.onAddSet,
    required this.onChanged,
    this.onRemove,
    this.onRemoveSet,
  });

  final _ExerciseDraft draft;
  final bool expanded;
  final List<ExerciseSetLog> previousSets;
  final VoidCallback onTap;
  final VoidCallback onAddSet;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;
  final VoidCallback? onRemoveSet;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (!expanded) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surfaceHigher.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sports_gymnastics,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.exerciseName.isEmpty
                          ? 'Exercise'
                          : draft.exerciseName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _collapsedSummary(draft, previousSets),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_down, color: colors.primary),
            ],
          ),
        ),
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceHigher.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.fitness_center, color: colors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: draft.nameController,
                        onChanged: (_) => onChanged(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Exercise Name',
                        ),
                      ),
                      TextField(
                        controller: draft.muscleController,
                        onChanged: (_) => onChanged(),
                        style: Theme.of(context).textTheme.labelMedium,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Muscle Group',
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onTap,
                      icon: Icon(
                        Icons.keyboard_arrow_up,
                        color: colors.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: onRemove,
                      icon: Icon(Icons.delete_outline, color: colors.error),
                    ),
                  ],
                ),
              ],
            ),
            if (previousSets.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Last time: ${_formatPreviousSet(previousSets.last)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.primaryDim),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    'SET',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(fontSize: 10),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'PREVIOUS',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(fontSize: 10),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      'WEIGHT',
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(fontSize: 10),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      'REPS',
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(fontSize: 10),
                    ),
                  ),
                ),
                const Expanded(flex: 2, child: SizedBox()),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(draft.sets.clamp(1, 6), (index) {
              final previous = previousSets.isEmpty
                  ? null
                  : previousSets[index < previousSets.length
                        ? index
                        : previousSets.length - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          previous == null
                              ? '--'
                              : _formatPreviousSet(previous),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: draft.weightController,
                          onChanged: (_) => onChanged(),
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: draft.repsController,
                          onChanged: (_) => onChanged(),
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: index == draft.sets - 1
                                ? onRemoveSet
                                : null,
                            icon: Icon(
                              Icons.remove_circle_outline,
                              color:
                                  index == draft.sets - 1 && onRemoveSet != null
                                  ? colors.error
                                  : colors.textSecondary.withValues(
                                      alpha: 0.25,
                                    ),
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            GestureDetector(
              onTap: onAddSet,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ADD SET',
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ExerciseFlagChip(
                  label: 'Warm-up 1st',
                  selected: draft.firstSetWarmup,
                  onTap: () {
                    draft.firstSetWarmup = !draft.firstSetWarmup;
                    onChanged();
                  },
                ),
                _ExerciseFlagChip(
                  label: 'Failure last',
                  selected: draft.lastSetFailure,
                  onTap: () {
                    draft.lastSetFailure = !draft.lastSetFailure;
                    onChanged();
                  },
                ),
                _ExerciseFlagChip(
                  label: 'PR last',
                  selected: draft.lastSetPr,
                  onTap: () {
                    draft.lastSetPr = !draft.lastSetPr;
                    onChanged();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _collapsedSummary(
    _ExerciseDraft draft,
    List<ExerciseSetLog> previousSets,
  ) {
    final current =
        '${draft.sets} sets • ${draft.reps} reps • ${draft.weightKg.toStringAsFixed(draft.weightKg == draft.weightKg.roundToDouble() ? 0 : 1)} kg';
    if (previousSets.isEmpty) {
      return current;
    }
    return '$current • last ${_formatPreviousSet(previousSets.last)}';
  }

  String _formatPreviousSet(ExerciseSetLog set) {
    final weight = set.weightKg == set.weightKg.roundToDouble()
        ? set.weightKg.toStringAsFixed(0)
        : set.weightKg.toStringAsFixed(1);
    return '$weight x ${set.reps}';
  }
}

class _ExerciseFlagChip extends StatelessWidget {
  const _ExerciseFlagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label.toUpperCase()),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: context.colors.primary,
      checkmarkColor: Colors.black,
      backgroundColor: context.colors.surface,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: selected ? Colors.black : Colors.white,
      ),
    );
  }
}

class _SessionHistoryCard extends StatelessWidget {
  const _SessionHistoryCard({
    required this.session,
    required this.sets,
    required this.onDelete,
  });

  final WorkoutSession session;
  final List<ExerciseSetLog> sets;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = session.muscleGroups.isEmpty
        ? session.notes ?? 'No muscle groups recorded'
        : session.muscleGroups.join(', ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${session.type.label} • ${session.durationMinutes} min',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatShortDate(session.date)} • $subtitle',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${sets.length} sets • ~${session.caloriesBurned.toStringAsFixed(0)} kcal',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, color: context.colors.error),
          ),
        ],
      ),
    );
  }
}

class _WeeklyStat extends StatelessWidget {
  const _WeeklyStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.colors.textSecondary,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AdjusterCard extends StatelessWidget {
  const _AdjusterCard({
    required this.label,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final String value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.colors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _AdjusterButton(icon: Icons.remove, onTap: onDecrease),
              Expanded(
                child: Center(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              _AdjusterButton(icon: Icons.add, onTap: onIncrease),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdjusterButton extends StatelessWidget {
  const _AdjusterButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: context.colors.surfaceHigher,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _ExerciseDraft {
  _ExerciseDraft({
    String name = '',
    String muscleGroup = '',
    int sets = 3,
    int reps = 10,
    double weightKg = 0,
    this.firstSetWarmup = false,
    this.lastSetFailure = false,
    this.lastSetPr = false,
  }) : nameController = TextEditingController(text: name),
       muscleController = TextEditingController(text: muscleGroup),
       setsController = TextEditingController(text: '$sets'),
       repsController = TextEditingController(text: '$reps'),
       weightController = TextEditingController(
         text: weightKg.toStringAsFixed(
           weightKg == weightKg.roundToDouble() ? 0 : 1,
         ),
       );

  factory _ExerciseDraft.fromPreset(WorkoutPresetExercise exercise) {
    return _ExerciseDraft(
      name: exercise.name,
      muscleGroup: exercise.muscleGroup,
      sets: exercise.sets,
      reps: exercise.reps,
      weightKg: exercise.weightKg,
      firstSetWarmup: exercise.firstSetWarmup,
      lastSetFailure: exercise.lastSetFailure,
      lastSetPr: exercise.lastSetPr,
    );
  }

  final TextEditingController nameController;
  final TextEditingController muscleController;
  final TextEditingController setsController;
  final TextEditingController repsController;
  final TextEditingController weightController;
  bool firstSetWarmup;
  bool lastSetFailure;
  bool lastSetPr;

  String get exerciseName => nameController.text;
  String get muscleGroup => muscleController.text;
  int get sets => int.tryParse(setsController.text) ?? 3;
  int get reps => int.tryParse(repsController.text) ?? 10;
  double get weightKg => double.tryParse(weightController.text) ?? 0;

  void dispose() {
    nameController.dispose();
    muscleController.dispose();
    setsController.dispose();
    repsController.dispose();
    weightController.dispose();
  }
}
