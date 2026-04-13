import 'models.dart';

class WorkoutPreset {
  const WorkoutPreset({
    required this.id,
    required this.name,
    required this.type,
    required this.durationMinutes,
    required this.met,
    required this.description,
    required this.exercises,
    this.notes,
  });

  final String id;
  final String name;
  final WorkoutType type;
  final int durationMinutes;
  final double met;
  final String description;
  final List<WorkoutPresetExercise> exercises;
  final String? notes;
}

class WorkoutPresetExercise {
  const WorkoutPresetExercise({
    required this.name,
    required this.muscleGroup,
    this.sets = 3,
    this.reps = 10,
    this.weightKg = 0,
    this.firstSetWarmup = false,
    this.lastSetFailure = false,
    this.lastSetPr = false,
  });

  final String name;
  final String muscleGroup;
  final int sets;
  final int reps;
  final double weightKg;
  final bool firstSetWarmup;
  final bool lastSetFailure;
  final bool lastSetPr;
}

class WorkoutPresetLibrary {
  static const List<WorkoutPreset> presets = [
    WorkoutPreset(
      id: 'daily_cardio',
      name: 'Daily Cardio',
      type: WorkoutType.cardio,
      durationMinutes: 30,
      met: 5.0,
      description: '20 min treadmill incline walk + 10 min cross leg machine',
      notes:
          'Treadmill: speed 4.0-4.5. Incline blocks 4, 6, 8, 10 for 5 min each. Keep the last 5 min at incline 10.\nCross leg machine: 10 min steady cardio.',
      exercises: [
        WorkoutPresetExercise(
          name: 'Treadmill Incline Walk',
          muscleGroup: 'Cardio',
          sets: 4,
          reps: 5,
        ),
        WorkoutPresetExercise(
          name: 'Cross Leg Machine',
          muscleGroup: 'Cardio',
          sets: 1,
          reps: 10,
        ),
      ],
    ),
    WorkoutPreset(
      id: 'chest_block',
      name: 'Chest Block',
      type: WorkoutType.push,
      durationMinutes: 45,
      met: 5.0,
      description: '3 exercises, 3 sets each, 10 reps per set',
      notes: 'Standard chest block. Total 30 reps per exercise.',
      exercises: [
        WorkoutPresetExercise(
          name: 'Chest Press',
          muscleGroup: 'Chest',
          firstSetWarmup: true,
        ),
        WorkoutPresetExercise(
          name: 'Pec Delta Fly Chest',
          muscleGroup: 'Chest',
        ),
        WorkoutPresetExercise(
          name: 'Incline Chest Press',
          muscleGroup: 'Chest',
        ),
      ],
    ),
    WorkoutPreset(
      id: 'biceps_block',
      name: 'Biceps Block',
      type: WorkoutType.pull,
      durationMinutes: 40,
      met: 5.0,
      description: '3 exercises, 3 sets each, 10 reps per set',
      notes: 'Standard biceps block. Total 30 reps per exercise.',
      exercises: [
        WorkoutPresetExercise(
          name: 'Bicep Curls',
          muscleGroup: 'Biceps',
          firstSetWarmup: true,
        ),
        WorkoutPresetExercise(name: 'Hammer Curls', muscleGroup: 'Biceps'),
        WorkoutPresetExercise(name: 'Rod Bicep Curls', muscleGroup: 'Biceps'),
      ],
    ),
    WorkoutPreset(
      id: 'back_block',
      name: 'Back Block',
      type: WorkoutType.pull,
      durationMinutes: 40,
      met: 5.5,
      description: '2 exercises, 3 sets each, 10 reps per set',
      notes: 'Standard back block. Total 30 reps per exercise.',
      exercises: [
        WorkoutPresetExercise(
          name: 'Lat Pull Down',
          muscleGroup: 'Back',
          firstSetWarmup: true,
        ),
        WorkoutPresetExercise(name: 'Horizontal Rowing', muscleGroup: 'Back'),
      ],
    ),
    WorkoutPreset(
      id: 'shoulders_block',
      name: 'Shoulders Block',
      type: WorkoutType.push,
      durationMinutes: 40,
      met: 5.0,
      description: '3 exercises, 3 sets each, 10 reps per set',
      notes: 'Standard shoulder block. Total 30 reps per exercise.',
      exercises: [
        WorkoutPresetExercise(
          name: 'Shoulder Press',
          muscleGroup: 'Shoulders',
          firstSetWarmup: true,
        ),
        WorkoutPresetExercise(
          name: 'Front Hand Raise Weighted',
          muscleGroup: 'Shoulders',
        ),
        WorkoutPresetExercise(
          name: 'Horizontal Hand Raise Weighted',
          muscleGroup: 'Shoulders',
        ),
      ],
    ),
    WorkoutPreset(
      id: 'triceps_block',
      name: 'Triceps Block',
      type: WorkoutType.push,
      durationMinutes: 35,
      met: 5.0,
      description: '2 exercises, 3 sets each, 10 reps per set',
      notes: 'Standard triceps block. Total 30 reps per exercise.',
      exercises: [
        WorkoutPresetExercise(
          name: 'Tricep Pushdown with Rod',
          muscleGroup: 'Triceps',
          firstSetWarmup: true,
        ),
        WorkoutPresetExercise(
          name: 'Tricep Pushdown with Rope',
          muscleGroup: 'Triceps',
        ),
      ],
    ),
  ];
}
