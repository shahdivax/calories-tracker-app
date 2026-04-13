import 'models.dart';

class SeedData {
  static const Set<String> managedSeedIds = {
    'chana_dal_bhel',
    'two_banana_protein_milkshake',
    'dal_chawal',
    'vada_pav',
    'idli',
    'mendu_wada',
    'bhakhri_small',
  };

  static const List<CustomFood> foods = [
    CustomFood(
      id: 'chana_dal_bhel',
      name: 'Chana Dal Bhel',
      caloriesPer100g: 235,
      proteinPer100g: 8.5,
      carbsPer100g: 30,
      fatPer100g: 8,
      fiberPer100g: 6.5,
      defaultServingG: 150,
      isJainSafe: false,
      isFrequent: true,
    ),
    CustomFood(
      id: 'two_banana_protein_milkshake',
      name: '2 Banana Protein Milkshake',
      caloriesPer100g: 106,
      proteinPer100g: 9.5,
      carbsPer100g: 17.2,
      fatPer100g: 2.2,
      fiberPer100g: 1.6,
      defaultServingG: 512,
      defaultServingUnit: FoodQuantityUnit.milliliters,
      isFrequent: true,
    ),
    CustomFood(
      id: 'dal_chawal',
      name: 'Dal + Chawal',
      caloriesPer100g: 135,
      proteinPer100g: 4.1,
      carbsPer100g: 24.6,
      fatPer100g: 2.4,
      fiberPer100g: 2.5,
      defaultServingG: 500,
      isFrequent: true,
    ),
    CustomFood(
      id: 'vada_pav',
      name: 'Vada Pav',
      caloriesPer100g: 315,
      proteinPer100g: 6.8,
      carbsPer100g: 41,
      fatPer100g: 13,
      fiberPer100g: 3.7,
      defaultServingG: 140,
      isJainSafe: false,
      isFrequent: true,
    ),
    CustomFood(
      id: 'idli',
      name: 'Idli',
      caloriesPer100g: 160,
      proteinPer100g: 4.4,
      carbsPer100g: 30.5,
      fatPer100g: 0.9,
      fiberPer100g: 1.6,
      defaultServingG: 120,
      isFrequent: true,
    ),
    CustomFood(
      id: 'mendu_wada',
      name: 'Mendu Wada',
      caloriesPer100g: 310,
      proteinPer100g: 6.4,
      carbsPer100g: 30,
      fatPer100g: 17,
      fiberPer100g: 3,
      defaultServingG: 80,
      isFrequent: true,
    ),
    CustomFood(
      id: 'bhakhri_small',
      name: 'Bhakhri Small',
      caloriesPer100g: 345,
      proteinPer100g: 8.8,
      carbsPer100g: 56,
      fatPer100g: 9,
      fiberPer100g: 7,
      defaultServingG: 55,
      isFrequent: true,
    ),
  ];

  static List<CustomFood> reconcileFoods(List<CustomFood> existing) {
    final existingById = {for (final food in existing) food.id: food};
    final managed = foods.map((food) => existingById[food.id] ?? food).toList();
    final preserved = existing.where(_isUserManagedFood).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return [...managed, ...preserved];
  }

  static bool _isUserManagedFood(CustomFood food) {
    return !managedSeedIds.contains(food.id) &&
        (food.id.startsWith('custom-food-') ||
            food.id.startsWith('food-package-') ||
            food.id.startsWith('user-food-'));
  }
}
