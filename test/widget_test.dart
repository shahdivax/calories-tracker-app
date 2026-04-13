import 'package:flutter_test/flutter_test.dart';

import 'package:food_tracker/src/core/data/models.dart';
import 'package:food_tracker/src/core/services/calculations.dart';

void main() {
  test('calculation engine derives expected targets from profile defaults', () {
    final profile = BodyProfile.defaults();
    final targets = CalculationsEngine.targetsFor(profile, const []);

    expect(targets.weightKg, closeTo(96, 0.01));
    expect(targets.proteinGoal, closeTo(192, 0.01));
    expect(targets.fatGoal, closeTo(76.8, 0.01));
    expect(targets.calorieGoal, lessThan(targets.tdee));
  });
}
