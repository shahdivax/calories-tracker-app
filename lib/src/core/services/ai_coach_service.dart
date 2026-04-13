import '../data/models.dart';
import 'calculations.dart';

abstract class AiCoachService {
  String generateDailyInsight(AppStateData data);
}

class LocalAiCoachService implements AiCoachService {
  @override
  String generateDailyInsight(AppStateData data) {
    final today = dayKey();
    final targets = CalculationsEngine.targetsFor(
      data.profile,
      data.weightLogs,
    );
    final nutrition = CalculationsEngine.totalsForDay(data.foodLogs, today);
    final proteinRatio = targets.proteinGoal == 0
        ? 0
        : nutrition.protein / targets.proteinGoal;
    final calorieDelta = nutrition.calories - targets.calorieGoal;
    final didWorkout = data.workoutSessions.any(
      (session) => session.date == today,
    );

    if (proteinRatio >= 1) {
      return 'Protein goal is locked in today. That does more for muscle retention than chasing perfect calories.';
    }
    if (didWorkout && proteinRatio < 0.6) {
      return 'You trained today but protein is still behind. Fix recovery before the day closes.';
    }
    if (calorieDelta > 200) {
      return 'You are over target today. Keep dinner simple and stop adding hidden calories.';
    }
    if (calorieDelta < -700) {
      return 'You are far under target. An unplanned crash deficit is not discipline, it is poor control.';
    }
    if (data.weightLogs.length >= 7) {
      final recent = [...data.weightLogs]
        ..sort((a, b) => a.date.compareTo(b.date));
      final first = recent[recent.length - 7].weightKg;
      final last = recent.last.weightKg;
      if (last < first) {
        return 'Weekly weight trend is moving down. Keep execution boring and repeatable.';
      }
    }
    return 'Nothing dramatic today. Hit protein, log cleanly, and let the averages do the work.';
  }
}
