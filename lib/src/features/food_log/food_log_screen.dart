import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/data/models.dart';
import '../../core/services/app_controller.dart';
import '../../core/services/calculations.dart';
import '../../core/theme/app_theme.dart';
import '../history/history_screen.dart';

class FoodLogScreen extends ConsumerStatefulWidget {
  const FoodLogScreen({super.key});

  @override
  ConsumerState<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends ConsumerState<FoodLogScreen> {
  final TextEditingController _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appControllerProvider).valueOrNull;
    if (data == null) return const SizedBox.shrink();

    final today = dayKey();
    final todayLogs = data.foodLogs.where((l) => l.date == today).toList()
      ..sort((a, b) => b.id.compareTo(a.id));
    final savedFoods = data.customFoods.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          // Background ambient glow
          Positioned(
            top: -100,
            right: -100,
            left: -100,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    context.colors.primary.withValues(alpha: 0.15),
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
                _buildHeader(context, data),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    children: [
                      _buildQuickEntrySection(context, data),
                      const SizedBox(height: 32),
                      _buildDailyNutritionOverview(context, data, todayLogs),
                      const SizedBox(height: 32),
                      _buildLoggedMeals(context, todayLogs),
                      const SizedBox(height: 32),
                      _buildSavedFoods(context, savedFoods),
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

  Widget _buildHeader(BuildContext context, AppStateData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'LOG NUTRITION',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: context.colors.textPrimary,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const HistoryScreen(initialFocus: HistoryFocus.food),
                  ),
                ),
                icon: const Icon(
                  Icons.calendar_month,
                  color: Colors.blueAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _editNotificationPreferences(data),
                icon: Icon(
                  Icons.notifications,
                  color: context.colors.primary,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickEntrySection(BuildContext context, AppStateData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ENTRY',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.colors.textSecondary,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 16),
        Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [context.colors.primary, context.colors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.primary.withValues(alpha: 0.2),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(2),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.colors.surfaceHigher.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a food name or describe the meal',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _startAiQuickEntry(data),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.colors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = ((constraints.maxWidth - 12) / 2).clamp(
              140.0,
              220.0,
            );
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: tileWidth,
                  child: _GlassButton(
                    icon: Icons.qr_code_scanner,
                    label: 'SCAN LABEL',
                    color: context.colors.primary,
                    onTap: () => _startPackageLabelScan(data),
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _GlassButton(
                    icon: Icons.photo_camera,
                    label: 'MEAL PHOTO',
                    color: context.colors.accent,
                    onTap: () => _startMealPhotoScan(data),
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _GlassButton(
                    icon: Icons.edit_note,
                    label: 'MANUAL ENTRY',
                    color: context.colors.secondary,
                    onTap: () => _startManualEntry(),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDailyNutritionOverview(
    BuildContext context,
    AppStateData data,
    List<FoodLogEntry> todayLogs,
  ) {
    final today = dayKey();
    final targets = CalculationsEngine.targetsFor(
      data.profile,
      data.weightLogs,
    );
    final totals = CalculationsEngine.totalsForDay(data.foodLogs, today);
    final calorieDelta = targets.calorieGoal - totals.calories;
    final hydrationMl = data.waterLogs
        .where((item) => item.date == today)
        .fold<int>(0, (sum, item) => sum + item.amountMl);
    final hydrationTargetLiters = CalculationsEngine.waterTargetLiters(
      data.workoutSessions,
      today,
    );
    final hydrationTargetMl = hydrationTargetLiters * 1000;
    final hydrationProgress = hydrationTargetMl <= 0
        ? 0.0
        : (hydrationMl / hydrationTargetMl).clamp(0.0, 1.0);
    final mealCountProgress = (todayLogs.length / 4).clamp(0.0, 1.0);
    final remainingLabel = calorieDelta >= 0 ? 'REMAINING' : 'OVER';
    final remainingColor = calorieDelta >= 0
        ? context.colors.primary
        : context.colors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DAILY NUTRITION',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const HistoryScreen(initialFocus: HistoryFocus.food),
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: context.colors.primary.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                'DETAILS',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.colors.primary,
                  letterSpacing: 1.4,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.colors.surfaceHigher.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Stack(
            children: [
              // Mock background image opacity
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Container(color: Colors.white),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: remainingColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                remainingLabel,
                                style: TextStyle(
                                  color: calorieDelta >= 0
                                      ? Colors.black
                                      : Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  calorieDelta.abs().toStringAsFixed(0),
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: context.colors.textPrimary,
                                        height: 1.0,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'KCAL',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: context.colors.textSecondary,
                                        letterSpacing: 1.0,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Mock overlapping avatar circles for P C F
                        Row(
                          children: [
                            _MacroBubble(
                              label: 'P',
                              color: context.colors.primaryDim,
                              textColor: Colors.white,
                            ),
                            Transform.translate(
                              offset: const Offset(-10, 0),
                              child: _MacroBubble(
                                label: 'C',
                                color: context.colors.secondary,
                                textColor: Colors.black,
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(-20, 0),
                              child: _MacroBubble(
                                label: 'F',
                                color: context.colors.surfaceHigher,
                                textColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HYDRATION',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      fontSize: 10,
                                      letterSpacing: 2.0,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    (hydrationMl / 1000).toStringAsFixed(1),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: context.colors.textPrimary,
                                        ),
                                  ),
                                  Text(
                                    ' / ${hydrationTargetLiters.toStringAsFixed(hydrationTargetLiters == hydrationTargetLiters.roundToDouble() ? 0 : 1)}L',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(fontSize: 10),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: hydrationProgress,
                                minHeight: 4,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.1,
                                ),
                                valueColor: AlwaysStoppedAnimation(
                                  context.colors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MEAL COUNT',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      fontSize: 10,
                                      letterSpacing: 2.0,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${todayLogs.length}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: context.colors.textPrimary,
                                        ),
                                  ),
                                  Text(
                                    ' meals',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(fontSize: 10),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: mealCountProgress,
                                minHeight: 4,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.1,
                                ),
                                valueColor: AlwaysStoppedAnimation(
                                  context.colors.primary,
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildLoggedMeals(BuildContext context, List<FoodLogEntry> todayLogs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Logged Meals',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Last updated 12:45 PM',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            GestureDetector(
              onTap: _startManualEntry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add, size: 16, color: context.colors.primaryDim),
                    const SizedBox(width: 4),
                    Text(
                      'LOG MEAL',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: context.colors.primaryDim,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (todayLogs.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No meals logged yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          ...todayLogs.map((log) => _LoggedMealCard(log: log)),
      ],
    );
  }

  Widget _buildSavedFoods(BuildContext context, List<CustomFood> savedFoods) {
    if (savedFoods.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SAVED FOODS',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.colors.textSecondary,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 16),
        ...savedFoods.map((food) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceHigher,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fastfood,
                    color: context.colors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.white, fontSize: 14),
                      ),
                      Text(
                        '${food.caloriesPer100g.toStringAsFixed(0)} kcal/100g • ${food.proteinPer100g.toStringAsFixed(0)}g P',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final entry = FoodLogEntry(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      date: dayKey(),
                      mealSlot: MealSlot.lunch,
                      foodName: food.name,
                      quantityG: food.defaultServingG,
                      quantityUnit: food.defaultServingUnit,
                      calories:
                          food.caloriesPer100g * (food.defaultServingG / 100),
                      proteinG:
                          food.proteinPer100g * (food.defaultServingG / 100),
                      carbsG: food.carbsPer100g * (food.defaultServingG / 100),
                      fatG: food.fatPer100g * (food.defaultServingG / 100),
                      fiberG: food.fiberPer100g * (food.defaultServingG / 100),
                      source: 'manual',
                    );
                    ref
                        .read(appControllerProvider.notifier)
                        .addFoodEntry(entry);
                  },
                  icon: Icon(
                    Icons.add_circle,
                    color: context.colors.primary,
                    size: 28,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Future<void> _startAiQuickEntry(AppStateData data) async {
    final draft = await _showAiEntryDialog(initialName: _queryController.text);
    if (draft == null) {
      return;
    }
    if (draft.name.isEmpty || draft.quantity == null || draft.quantity! <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a valid food name and quantity.')),
        );
      }
      return;
    }

    await _runFoodAction('Estimating food...', () async {
      final estimate = await _estimateFood(
        data: data,
        name: draft.name,
        quantity: draft.quantity!,
        quantityUnit: draft.quantityUnit,
        description: draft.description,
        fallbackFoods: data.customFoods,
      );
      await ref
          .read(appControllerProvider.notifier)
          .addFoodEntry(
            FoodLogEntry(
              id: 'food-${DateTime.now().microsecondsSinceEpoch}',
              date: dayKey(),
              mealSlot: draft.mealSlot,
              foodName: estimate.name,
              quantityG: draft.quantity!,
              quantityUnit: draft.quantityUnit,
              calories: estimate.calories,
              proteinG: estimate.proteinG,
              carbsG: estimate.carbsG,
              fatG: estimate.fatG,
              fiberG: estimate.fiberG,
              source: 'ai_text',
              description: draft.description,
            ),
          );
      _queryController.clear();
    });
  }

  Future<void> _startManualEntry() async {
    final draft = await _showManualEntryDialog();
    if (draft == null) {
      return;
    }
    if (draft.name.isEmpty ||
        draft.quantity == null ||
        draft.quantity! <= 0 ||
        draft.calories == null ||
        draft.protein == null ||
        draft.carbs == null ||
        draft.fat == null ||
        draft.fiber == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fill every required manual field.')),
        );
      }
      return;
    }

    await ref
        .read(appControllerProvider.notifier)
        .addFoodEntry(
          FoodLogEntry(
            id: 'food-${DateTime.now().microsecondsSinceEpoch}',
            date: dayKey(),
            mealSlot: draft.mealSlot,
            foodName: draft.name,
            quantityG: draft.quantity!,
            quantityUnit: draft.quantityUnit,
            calories: draft.calories!,
            proteinG: draft.protein!,
            carbsG: draft.carbs!,
            fatG: draft.fat!,
            fiberG: draft.fiber!,
            source: 'manual',
            description: draft.description,
          ),
        );
  }

  Future<void> _startPackageLabelScan(AppStateData data) async {
    final draft = await _showImageScanDialog(
      title: 'Scan Label',
      includeQuantity: true,
    );
    if (draft == null) {
      return;
    }
    if (draft.quantity == null || draft.quantity! <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid quantity first.')),
        );
      }
      return;
    }

    await _runFoodAction('Reading package label...', () async {
      final image = await ref
          .read(mediaServiceProvider)
          .pickImage(source: draft.source);
      if (image == null) {
        return;
      }
      final bytes = await image.readAsBytes();
      final result = await ref
          .read(aiRuntimeServiceProvider)
          .analyzePackageLabel(
            data: data,
            bytes: bytes,
            mimeType: _mimeTypeForPath(image.path),
            scanTitle: draft.title,
          );
      final servings = draft.quantity!;
      await ref
          .read(appControllerProvider.notifier)
          .addFoodEntry(
            FoodLogEntry(
              id: 'food-${DateTime.now().microsecondsSinceEpoch}',
              date: dayKey(),
              mealSlot: draft.mealSlot,
              foodName: result.productName,
              quantityG: servings,
              quantityUnit: draft.quantityUnit,
              calories: result.calories * servings,
              proteinG: result.proteinG * servings,
              carbsG: result.carbsG * servings,
              fatG: result.fatG * servings,
              fiberG: result.fiberG * servings,
              source: 'package_label',
              description: _joinDescription(
                draft.description,
                result.brand.isEmpty ? null : 'Brand: ${result.brand}',
                result.servingSize.isEmpty
                    ? null
                    : 'Serving: ${result.servingSize}',
              ),
              sourceTitle: draft.title,
            ),
          );
    });
  }

  Future<void> _startMealPhotoScan(AppStateData data) async {
    final draft = await _showImageScanDialog(
      title: 'Meal Photo',
      includeQuantity: false,
    );
    if (draft == null) {
      return;
    }

    await _runFoodAction('Analyzing meal photo...', () async {
      final image = await ref
          .read(mediaServiceProvider)
          .pickImage(source: draft.source);
      if (image == null) {
        return;
      }
      final bytes = await image.readAsBytes();
      final items = await ref
          .read(aiRuntimeServiceProvider)
          .analyzeFoodPhoto(
            data: data,
            bytes: bytes,
            mimeType: _mimeTypeForPath(image.path),
            scanTitle: draft.title,
            foodDescription: draft.description,
          );
      for (final item in items) {
        await ref
            .read(appControllerProvider.notifier)
            .addFoodEntry(
              FoodLogEntry(
                id: 'food-${DateTime.now().microsecondsSinceEpoch}-${item.name}',
                date: dayKey(),
                mealSlot: draft.mealSlot,
                foodName: item.name,
                quantityG: item.estimatedPortionG,
                quantityUnit: FoodQuantityUnit.grams,
                calories: item.calories,
                proteinG: item.proteinG,
                carbsG: item.carbsG,
                fatG: item.fatG,
                fiberG: item.fiberG,
                source: 'photo',
                description: draft.description,
                sourceTitle: draft.title,
              ),
            );
      }
    });
  }

  Future<_AiFoodDraft?> _showAiEntryDialog({String? initialName}) {
    final nameController = TextEditingController(
      text: initialName?.trim() ?? '',
    );
    final descriptionController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    var mealSlot = MealSlot.breakfast;
    var quantityUnit = FoodQuantityUnit.count;

    return showDialog<_AiFoodDraft>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('AI Food Entry'),
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
                    () => quantityUnit = value ?? FoodQuantityUnit.count,
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
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                _AiFoodDraft(
                  name: nameController.text.trim(),
                  description: _trimToNull(descriptionController.text),
                  quantity: double.tryParse(quantityController.text),
                  quantityUnit: quantityUnit,
                  mealSlot: mealSlot,
                ),
              ),
              child: const Text('Estimate'),
            ),
          ],
        ),
      ),
    );
  }

  Future<_ManualFoodDraft?> _showManualEntryDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();
    final fiberController = TextEditingController();
    var mealSlot = MealSlot.breakfast;
    var quantityUnit = FoodQuantityUnit.count;

    return showDialog<_ManualFoodDraft>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Manual Entry'),
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
                    labelText: 'Description (optional)',
                  ),
                ),
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
                    () => quantityUnit = value ?? FoodQuantityUnit.count,
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
                const SizedBox(height: 12),
                TextField(
                  controller: caloriesController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Calories'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: proteinController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Protein (g)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: carbsController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Carbs (g)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fatController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Fat (g)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fiberController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Fiber (g)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                _ManualFoodDraft(
                  name: nameController.text.trim(),
                  description: _trimToNull(descriptionController.text),
                  quantity: double.tryParse(quantityController.text),
                  quantityUnit: quantityUnit,
                  mealSlot: mealSlot,
                  calories: double.tryParse(caloriesController.text),
                  protein: double.tryParse(proteinController.text),
                  carbs: double.tryParse(carbsController.text),
                  fat: double.tryParse(fatController.text),
                  fiber: double.tryParse(fiberController.text),
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<_ImageScanDraft?> _showImageScanDialog({
    required String title,
    required bool includeQuantity,
  }) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    var mealSlot = MealSlot.breakfast;
    var quantityUnit = FoodQuantityUnit.count;
    var source = ImageSource.camera;

    return showDialog<_ImageScanDraft>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ImageSource>(
                  initialValue: source,
                  items: const [
                    DropdownMenuItem(
                      value: ImageSource.camera,
                      child: Text('Camera'),
                    ),
                    DropdownMenuItem(
                      value: ImageSource.gallery,
                      child: Text('Gallery'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => source = value ?? ImageSource.camera),
                  decoration: const InputDecoration(labelText: 'Image Source'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
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
                if (includeQuantity) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Servings / quantity',
                    ),
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
                      () => quantityUnit = value ?? FoodQuantityUnit.count,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Quantity Unit',
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                _ImageScanDraft(
                  source: source,
                  title: _trimToNull(titleController.text),
                  description: _trimToNull(descriptionController.text),
                  mealSlot: mealSlot,
                  quantity: includeQuantity
                      ? double.tryParse(quantityController.text)
                      : null,
                  quantityUnit: quantityUnit,
                ),
              ),
              child: const Text('Continue'),
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
            foodDescription: description,
            preferHighSide: true,
          );
    } catch (_) {
      CustomFood? fallback;
      for (final food in fallbackFoods) {
        if (food.name.toLowerCase() == name.toLowerCase()) {
          fallback = food;
          break;
        }
      }
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

  Future<void> _runFoodAction(
    String label,
    Future<void> Function() action,
  ) async {
    if (!mounted) {
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(label)),
            ],
          ),
        ),
      ),
    );
    try {
      await action();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (error) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_formatError(error))));
      }
    }
  }

  String _mimeTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }

  String? _trimToNull(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _joinDescription(String? a, String? b, String? c) {
    final lines = [a, b, c]
        .whereType<String>()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return lines.isEmpty ? null : lines.join('\n');
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

  Future<void> _editNotificationPreferences(AppStateData data) async {
    var draft = data.preferences.notifications;

    Future<void> pickTime(
      StateSetter setState,
      int current,
      void Function(int) apply,
    ) async {
      final selected = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      );
      if (selected == null) {
        return;
      }
      setState(() => apply(selected.hour * 60 + selected.minute));
    }

    final result = await showDialog<NotificationPreferences>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Notification Schedule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable All Notifications'),
                  value: draft.enabled,
                  onChanged: (value) =>
                      setState(() => draft = draft.copyWith(enabled: value)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Weigh-in Reminder'),
                  subtitle: const Text('Uses your wake time + 15 minutes'),
                  value: draft.weighInEnabled,
                  onChanged: (value) => setState(
                    () => draft = draft.copyWith(weighInEnabled: value),
                  ),
                ),
                _notificationRow(
                  label: 'Breakfast',
                  enabled: draft.breakfastEnabled,
                  time: formatMinutes(draft.breakfastMinutes),
                  onToggle: (value) => setState(
                    () => draft = draft.copyWith(breakfastEnabled: value),
                  ),
                  onTap: () =>
                      pickTime(setState, draft.breakfastMinutes, (minutes) {
                        draft = draft.copyWith(breakfastMinutes: minutes);
                      }),
                ),
                _notificationRow(
                  label: 'Lunch',
                  enabled: draft.lunchEnabled,
                  time: formatMinutes(draft.lunchMinutes),
                  onToggle: (value) => setState(
                    () => draft = draft.copyWith(lunchEnabled: value),
                  ),
                  onTap: () =>
                      pickTime(setState, draft.lunchMinutes, (minutes) {
                        draft = draft.copyWith(lunchMinutes: minutes);
                      }),
                ),
                _notificationRow(
                  label: 'Dinner',
                  enabled: draft.dinnerEnabled,
                  time: formatMinutes(draft.dinnerMinutes),
                  onToggle: (value) => setState(
                    () => draft = draft.copyWith(dinnerEnabled: value),
                  ),
                  onTap: () =>
                      pickTime(setState, draft.dinnerMinutes, (minutes) {
                        draft = draft.copyWith(dinnerMinutes: minutes);
                      }),
                ),
                _notificationRow(
                  label: 'Random Ping 1',
                  enabled: draft.randomOneEnabled,
                  time: formatMinutes(draft.randomOneMinutes),
                  onToggle: (value) => setState(
                    () => draft = draft.copyWith(randomOneEnabled: value),
                  ),
                  onTap: () =>
                      pickTime(setState, draft.randomOneMinutes, (minutes) {
                        draft = draft.copyWith(randomOneMinutes: minutes);
                      }),
                ),
                _notificationRow(
                  label: 'Random Ping 2',
                  enabled: draft.randomTwoEnabled,
                  time: formatMinutes(draft.randomTwoMinutes),
                  onToggle: (value) => setState(
                    () => draft = draft.copyWith(randomTwoEnabled: value),
                  ),
                  onTap: () =>
                      pickTime(setState, draft.randomTwoMinutes, (minutes) {
                        draft = draft.copyWith(randomTwoMinutes: minutes);
                      }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(draft),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result == null) {
      return;
    }
    await ref
        .read(appControllerProvider.notifier)
        .updatePreferences(data.preferences.copyWith(notifications: result));
  }

  Widget _notificationRow({
    required String label,
    required bool enabled,
    required String time,
    required ValueChanged<bool> onToggle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(time),
      trailing: Switch(value: enabled, onChanged: onToggle),
      onTap: onTap,
    );
  }
}

class _AiFoodDraft {
  const _AiFoodDraft({
    required this.name,
    required this.description,
    required this.quantity,
    required this.quantityUnit,
    required this.mealSlot,
  });

  final String name;
  final String? description;
  final double? quantity;
  final FoodQuantityUnit quantityUnit;
  final MealSlot mealSlot;
}

class _ManualFoodDraft {
  const _ManualFoodDraft({
    required this.name,
    required this.description,
    required this.quantity,
    required this.quantityUnit,
    required this.mealSlot,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  final String name;
  final String? description;
  final double? quantity;
  final FoodQuantityUnit quantityUnit;
  final MealSlot mealSlot;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fiber;
}

class _ImageScanDraft {
  const _ImageScanDraft({
    required this.source,
    required this.title,
    required this.description,
    required this.mealSlot,
    required this.quantity,
    required this.quantityUnit,
  });

  final ImageSource source;
  final String? title;
  final String? description;
  final MealSlot mealSlot;
  final double? quantity;
  final FoodQuantityUnit quantityUnit;
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GlassButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroBubble extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _MacroBubble({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: context.colors.background, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _LoggedMealCard extends ConsumerWidget {
  final FoodLogEntry log;
  const _LoggedMealCard({required this.log});

  Future<_ManualFoodDraft?> _showEntryDialog(
    BuildContext context, {
    required String title,
    FoodLogEntry? initial,
    MealSlot? lockedMealSlot,
  }) {
    final resolvedInitial = initial ?? log;
    final nameController = TextEditingController(
      text: resolvedInitial.foodName,
    );
    final descriptionController = TextEditingController(
      text: resolvedInitial.description ?? '',
    );
    final quantityController = TextEditingController(
      text: resolvedInitial.quantityG.toStringAsFixed(
        resolvedInitial.quantityG == resolvedInitial.quantityG.roundToDouble()
            ? 0
            : 1,
      ),
    );
    final caloriesController = TextEditingController(
      text: resolvedInitial.calories.toStringAsFixed(0),
    );
    final proteinController = TextEditingController(
      text: resolvedInitial.proteinG.toStringAsFixed(1),
    );
    final carbsController = TextEditingController(
      text: resolvedInitial.carbsG.toStringAsFixed(1),
    );
    final fatController = TextEditingController(
      text: resolvedInitial.fatG.toStringAsFixed(1),
    );
    final fiberController = TextEditingController(
      text: resolvedInitial.fiberG.toStringAsFixed(1),
    );
    var quantityUnit = resolvedInitial.quantityUnit;
    var mealSlot = lockedMealSlot ?? resolvedInitial.mealSlot;

    return showDialog<_ManualFoodDraft>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
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
                    labelText: 'Description (optional)',
                  ),
                ),
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
                    () => quantityUnit = value ?? FoodQuantityUnit.count,
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
                  onChanged: lockedMealSlot == null
                      ? (value) => setState(
                          () => mealSlot = value ?? MealSlot.breakfast,
                        )
                      : null,
                  decoration: const InputDecoration(labelText: 'Meal Slot'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: caloriesController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Calories'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: proteinController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Protein (g)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: carbsController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Carbs (g)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fatController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Fat (g)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fiberController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Fiber (g)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                _ManualFoodDraft(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  quantity: double.tryParse(quantityController.text.trim()),
                  quantityUnit: quantityUnit,
                  mealSlot: mealSlot,
                  calories: double.tryParse(caloriesController.text.trim()),
                  protein: double.tryParse(proteinController.text.trim()),
                  carbs: double.tryParse(carbsController.text.trim()),
                  fat: double.tryParse(fatController.text.trim()),
                  fiber: double.tryParse(fiberController.text.trim()),
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  bool _isValidDraft(_ManualFoodDraft draft) {
    return draft.name.isNotEmpty &&
        (draft.quantity ?? 0) > 0 &&
        draft.calories != null &&
        draft.protein != null &&
        draft.carbs != null &&
        draft.fat != null &&
        draft.fiber != null;
  }

  Future<FoodLogEntry> _resolveEditedEntry(
    WidgetRef ref,
    _ManualFoodDraft draft,
  ) async {
    final fallback = FoodLogEntry(
      id: log.id,
      date: log.date,
      mealSlot: draft.mealSlot,
      foodName: draft.name,
      quantityG: draft.quantity!,
      quantityUnit: draft.quantityUnit,
      calories: draft.calories!,
      proteinG: draft.protein!,
      carbsG: draft.carbs!,
      fatG: draft.fat!,
      fiberG: draft.fiber!,
      source: log.source,
      description: draft.description,
      sourceTitle: log.sourceTitle,
    );
    final data = ref.read(appControllerProvider).valueOrNull;
    if (data == null ||
        !data.aiSettings.enabled ||
        data.aiSettings.apiKey.trim().isEmpty) {
      return fallback;
    }
    try {
      final estimate = await ref
          .read(aiRuntimeServiceProvider)
          .estimateFoodFromText(
            data: data,
            foodName: draft.name,
            quantity: draft.quantity!,
            quantityUnit: draft.quantityUnit,
            entryTitle: log.sourceTitle,
            foodDescription: draft.description,
            preferHighSide: true,
          );
      return FoodLogEntry(
        id: log.id,
        date: log.date,
        mealSlot: draft.mealSlot,
        foodName: estimate.name,
        quantityG: draft.quantity!,
        quantityUnit: draft.quantityUnit,
        calories: estimate.calories,
        proteinG: estimate.proteinG,
        carbsG: estimate.carbsG,
        fatG: estimate.fatG,
        fiberG: estimate.fiberG,
        source: log.source,
        description: draft.description,
        sourceTitle: log.sourceTitle,
      );
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.surfaceHigher.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.fastfood, color: colors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.foodName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${log.mealSlot.label.toUpperCase()} • ${log.quantityG.toStringAsFixed(0)} ${log.quantityUnit.shortLabel}',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontSize: 10, letterSpacing: 1.0),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final draft = await _showEntryDialog(
                          context,
                          title: 'Edit Meal Entry',
                        );
                        if (draft == null || !_isValidDraft(draft)) {
                          return;
                        }
                        final entry = await _resolveEditedEntry(ref, draft);
                        await ref
                            .read(appControllerProvider.notifier)
                            .updateFoodEntry(entry);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.edit,
                          size: 20,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref
                          .read(appControllerProvider.notifier)
                          .removeFoodEntry(log.id),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.delete,
                          size: 20,
                          color: colors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        'INGREDIENT',
                        style: Theme.of(
                          context,
                        ).textTheme.labelMedium?.copyWith(fontSize: 9),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: Text(
                          'AMOUNT',
                          style: Theme.of(
                            context,
                          ).textTheme.labelMedium?.copyWith(fontSize: 9),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'KCAL',
                          style: Theme.of(
                            context,
                          ).textTheme.labelMedium?.copyWith(fontSize: 9),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
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
                        flex: 5,
                        child: Text(
                          log.foodName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 12,
                                color: colors.textPrimary,
                              ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Text(
                            '${log.quantityG.toStringAsFixed(0)} ${log.quantityUnit.shortLabel}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: 11,
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            log.calories.toStringAsFixed(0),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: 11,
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final draft = await _showEntryDialog(
                        context,
                        title: 'Add Ingredient',
                        initial: FoodLogEntry(
                          id: 'preview',
                          date: log.date,
                          mealSlot: log.mealSlot,
                          foodName: '',
                          quantityG: 1,
                          quantityUnit: FoodQuantityUnit.count,
                          calories: 0,
                          proteinG: 0,
                          carbsG: 0,
                          fatG: 0,
                          fiberG: 0,
                          source: 'manual',
                        ),
                        lockedMealSlot: log.mealSlot,
                      );
                      if (draft == null || !_isValidDraft(draft)) {
                        return;
                      }
                      await ref
                          .read(appControllerProvider.notifier)
                          .addFoodEntry(
                            FoodLogEntry(
                              id: 'food-${DateTime.now().microsecondsSinceEpoch}',
                              date: dayKey(),
                              mealSlot: log.mealSlot,
                              foodName: draft.name,
                              quantityG: draft.quantity!,
                              quantityUnit: draft.quantityUnit,
                              calories: draft.calories!,
                              proteinG: draft.protein!,
                              carbsG: draft.carbs!,
                              fatG: draft.fat!,
                              fiberG: draft.fiber!,
                              source: 'manual',
                              description: draft.description,
                            ),
                          );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                            'ADD INGREDIENT',
                            style: Theme.of(
                              context,
                            ).textTheme.labelMedium?.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
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
}
