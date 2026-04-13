import 'package:flutter_test/flutter_test.dart';

import 'package:food_tracker/src/core/data/models.dart';

void main() {
  test('scanned food parsing tolerates mixed primitive types', () {
    final item = ScannedFoodItem.fromJson({
      'name': 'Protein Shake',
      'estimated_portion_grams': '500 ml',
      'calories': '540 kcal',
      'protein_g': '32',
      'carbs_g': 58,
      'fat_g': '14.5',
      'fiber_g': null,
      'confidence': 0.84,
    });

    expect(item.name, 'Protein Shake');
    expect(item.estimatedPortionG, 500);
    expect(item.calories, 540);
    expect(item.proteinG, 32);
    expect(item.carbsG, 58);
    expect(item.fatG, 14.5);
    expect(item.fiberG, 0);
    expect(item.confidence, '84%');
  });

  test('package label parsing tolerates numeric and string fields', () {
    final item = PackageLabelScanResult.fromJson({
      'brand': 'Example',
      'product_name': 'Greek Yogurt',
      'serving_size': 200,
      'calories': '152 kcal',
      'protein_g': 18.5,
      'carbs_g': '7g',
      'fat_g': '4.0',
      'fiber_g': 0,
      'ingredients': 'Milk, Culture',
    });

    expect(item.brand, 'Example');
    expect(item.productName, 'Greek Yogurt');
    expect(item.servingSize, '200');
    expect(item.calories, 152);
    expect(item.proteinG, 18.5);
    expect(item.carbsG, 7);
    expect(item.fatG, 4);
    expect(item.fiberG, 0);
    expect(item.ingredients, ['Milk', 'Culture']);
  });
}
