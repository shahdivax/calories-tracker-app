import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models.dart';
import '../../core/services/app_controller.dart';
import '../../core/services/calculations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui_kit/ui_kit.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.standalone = false});

  final bool standalone;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _labels = [
    'Name',
    'Biological Sex',
    'Age',
    'Height',
    'Current Weight',
    'Goal Weight',
    'Body Fat',
    'Goal Type',
    'Deficit',
    'Activity',
    'Diet Type',
    'Schedule',
    'Protein',
    'Preferences',
    'AI Setup',
    'Summary',
  ];

  late BodyProfile _draft;
  late AppPreferences _preferencesDraft;
  late AiSettings _aiDraft;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    final data = ref.read(appControllerProvider).valueOrNull;
    _draft = data?.profile ?? BodyProfile.defaults();
    _preferencesDraft = data?.preferences ?? const AppPreferences();
    _aiDraft = data?.aiSettings ?? const AiSettings();
  }

  @override
  Widget build(BuildContext context) {
    final targets = CalculationsEngine.targetsFor(_draft, [
      WeightLog(
        id: 'preview',
        date: dayKey(),
        weightKg: _draft.startingWeightKg,
      ),
    ]);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_step + 1) / _labels.length,
              minHeight: 3,
              backgroundColor: context.colors.surfaceHigher,
              valueColor: AlwaysStoppedAnimation<Color>(context.colors.gold),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'STEP ${_step + 1}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _labels[_step].toUpperCase(),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildStep(context, targets),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _step == 0
                          ? null
                          : () => setState(() => _step -= 1),
                      child: Text('BACK'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _step == _labels.length - 1 ? _finish : _next,
                      child: Text(
                        _step == _labels.length - 1 ? 'CONFIRM' : 'CONTINUE',
                      ),
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

  Widget _buildStep(BuildContext context, NutritionTargets targets) {
    switch (_step) {
      case 0:
        return _textField(
          label: 'Name',
          initialValue: _draft.name,
          helper: 'Used for greetings throughout the app.',
          onChanged: (value) => _draft = _draft.copyWith(
            name: value.isEmpty ? _draft.name : value,
          ),
        );
      case 1:
        return _enumSegmented(
          title: 'Select biological sex',
          values: BiologicalSex.values,
          current: _draft.sex,
          labelFor: (value) => value.label,
          onChanged: (value) =>
              setState(() => _draft = _draft.copyWith(sex: value)),
        );
      case 2:
        return _numberField(
          label: 'Age',
          value: _draft.age.toString(),
          helper: 'The app will prompt yearly updates.',
          suffix: 'years',
          onChanged: (value) =>
              _draft = _draft.copyWith(age: int.tryParse(value) ?? _draft.age),
        );
      case 3:
        return _numberField(
          label: 'Height',
          value: _draft.heightCm.toStringAsFixed(0),
          suffix: 'cm',
          onChanged: (value) => _draft = _draft.copyWith(
            heightCm: double.tryParse(value) ?? _draft.heightCm,
          ),
        );
      case 4:
        return _numberField(
          label: 'Current Weight',
          value: _draft.startingWeightKg.toStringAsFixed(1),
          suffix: 'kg',
          helper: 'This seeds daily tracking and target calculations.',
          onChanged: (value) => _draft = _draft.copyWith(
            startingWeightKg: double.tryParse(value) ?? _draft.startingWeightKg,
          ),
        );
      case 5:
        return _numberField(
          label: 'Goal Weight',
          value: _draft.goalWeightKg.toStringAsFixed(1),
          suffix: 'kg',
          onChanged: (value) => _draft = _draft.copyWith(
            goalWeightKg: double.tryParse(value) ?? _draft.goalWeightKg,
          ),
        );
      case 6:
        return Column(
          children: [
            _numberField(
              label: 'Body Fat %',
              value: _draft.bodyFatPct?.toStringAsFixed(1) ?? '',
              suffix: '%',
              helper:
                  'Optional. If empty, Navy method will be used when measurements exist.',
              onChanged: (value) {
                final parsed = double.tryParse(value);
                if (parsed != null) {
                  _draft = _draft.copyWith(bodyFatPct: parsed);
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    label: 'Waist',
                    value: _draft.waistCm?.toStringAsFixed(1) ?? '',
                    suffix: 'cm',
                    onChanged: (value) {
                      final parsed = double.tryParse(value);
                      if (parsed != null) {
                        _draft = _draft.copyWith(waistCm: parsed);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _numberField(
                    label: 'Neck',
                    value: _draft.neckCm?.toStringAsFixed(1) ?? '',
                    suffix: 'cm',
                    onChanged: (value) {
                      final parsed = double.tryParse(value);
                      if (parsed != null) {
                        _draft = _draft.copyWith(neckCm: parsed);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      case 7:
        return _enumSegmented(
          title: 'Choose goal type',
          values: GoalType.values,
          current: _draft.goalType,
          labelFor: (value) => value.label,
          onChanged: (value) =>
              setState(() => _draft = _draft.copyWith(goalType: value)),
        );
      case 8:
        if (_draft.goalType != GoalType.fatLoss) {
          return AppCard(
            child: Text(
              _draft.goalType == GoalType.recomp
                  ? 'Recomp runs near maintenance. Deficit is not applied.'
                  : 'Muscle gain uses a small calorie surplus. Deficit is not applied.',
            ),
          );
        }
        return _enumSegmented<int>(
          title: 'Select calorie deficit',
          values: const [200, 400, 600],
          current: _draft.deficitKcal,
          labelFor: (value) => switch (value) {
            200 => 'Mild',
            400 => 'Moderate',
            _ => 'Aggressive',
          },
          onChanged: (value) =>
              setState(() => _draft = _draft.copyWith(deficitKcal: value)),
        );
      case 9:
        return _enumSegmented(
          title: 'Select activity level',
          values: ActivityLevel.values,
          current: _draft.activityLevel,
          labelFor: (value) => value.label,
          onChanged: (value) =>
              setState(() => _draft = _draft.copyWith(activityLevel: value)),
        );
      case 10:
        return _enumSegmented(
          title: 'Select diet type',
          values: DietType.values,
          current: _draft.dietType,
          labelFor: (value) => value.label,
          onChanged: (value) =>
              setState(() => _draft = _draft.copyWith(dietType: value)),
        );
      case 11:
        return Column(
          children: [
            _timeTile(
              label: 'Wake Time',
              value: formatMinutes(_draft.wakeMinutes),
              onTap: () => _pickTime(
                _draft.wakeMinutes,
                (minutes) => setState(
                  () => _draft = _draft.copyWith(wakeMinutes: minutes),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _timeTile(
              label: 'Work Start',
              value: formatMinutes(_draft.workStartMinutes),
              onTap: () => _pickTime(
                _draft.workStartMinutes,
                (minutes) => setState(
                  () => _draft = _draft.copyWith(workStartMinutes: minutes),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _timeTile(
              label: 'Work End',
              value: formatMinutes(_draft.workEndMinutes),
              onTap: () => _pickTime(
                _draft.workEndMinutes,
                (minutes) => setState(
                  () => _draft = _draft.copyWith(workEndMinutes: minutes),
                ),
              ),
            ),
          ],
        );
      case 12:
        return Column(
          children: [
            _enumSegmented(
              title: 'Protein preference',
              values: ProteinPreference.values,
              current: _draft.proteinPreference,
              labelFor: (value) => value.label,
              onChanged: (value) {
                setState(() {
                  _draft = _draft.copyWith(
                    proteinPreference: value,
                    proteinMultiplier: switch (value) {
                      ProteinPreference.standard => 1.6,
                      ProteinPreference.aggressive => 2.0,
                      ProteinPreference.custom => _draft.proteinMultiplier,
                    },
                  );
                });
              },
            ),
            const SizedBox(height: 16),
            if (_draft.proteinPreference == ProteinPreference.custom)
              _numberField(
                label: 'Protein Multiplier',
                value: _draft.proteinMultiplier.toStringAsFixed(1),
                suffix: 'g/kg',
                onChanged: (value) => _draft = _draft.copyWith(
                  proteinMultiplier:
                      double.tryParse(value) ?? _draft.proteinMultiplier,
                ),
              ),
          ],
        );
      case 13:
        return Column(
          children: [
            _enumSegmented(
              title: 'Measurement units',
              values: MeasurementSystem.values,
              current: _preferencesDraft.measurementSystem,
              labelFor: (value) => value.label,
              onChanged: (value) => setState(
                () => _preferencesDraft = _preferencesDraft.copyWith(
                  measurementSystem: value,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _enumSegmented(
              title: 'Theme mode',
              values: ThemePreference.values,
              current: _preferencesDraft.themePreference,
              labelFor: (value) => value.label,
              onChanged: (value) => setState(
                () => _preferencesDraft = _preferencesDraft.copyWith(
                  themePreference: value,
                ),
              ),
            ),
          ],
        );
      case 14:
        return Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable Gemini AI'),
              subtitle: const Text(
                'Turns on food scans, AI estimation, and adaptive targets.',
              ),
              value: _aiDraft.enabled,
              onChanged: (value) =>
                  setState(() => _aiDraft = _aiDraft.copyWith(enabled: value)),
            ),
            const SizedBox(height: 12),
            _textField(
              label: 'Gemini Model',
              initialValue: _aiDraft.model,
              helper: 'Example: gemini-3.1-flash-lite-preview',
              onChanged: (value) =>
                  _aiDraft = _aiDraft.copyWith(model: value.trim()),
            ),
            const SizedBox(height: 12),
            _textField(
              label: 'Gemini API Key',
              initialValue: _aiDraft.apiKey,
              helper: 'Optional during setup. You can add or rotate it later.',
              onChanged: (value) =>
                  _aiDraft = _aiDraft.copyWith(apiKey: value.trim()),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Adaptive Maintenance Targets'),
              subtitle: const Text(
                'Recalculates from your latest food, workout, and weight history.',
              ),
              value: _aiDraft.autoAdaptiveTargets,
              onChanged: (value) => setState(
                () => _aiDraft = _aiDraft.copyWith(autoAdaptiveTargets: value),
              ),
            ),
          ],
        );
      default:
        return Column(
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryLine('BMR', '${targets.bmr.toStringAsFixed(0)} kcal'),
                  _summaryLine(
                    'TDEE',
                    '${targets.tdee.toStringAsFixed(0)} kcal',
                  ),
                  _summaryLine(
                    'Calorie Goal',
                    '${targets.calorieGoal.toStringAsFixed(0)} kcal',
                  ),
                  _summaryLine(
                    'Protein',
                    '${targets.proteinGoal.toStringAsFixed(0)} g',
                  ),
                  _summaryLine(
                    'Fat',
                    '${targets.fatGoal.toStringAsFixed(0)} g',
                  ),
                  _summaryLine(
                    'Carbs',
                    '${targets.carbGoal.toStringAsFixed(0)} g',
                  ),
                  _summaryLine(
                    'Fiber',
                    '${targets.fiberGoal.toStringAsFixed(0)} g',
                  ),
                  _summaryLine(
                    'Units',
                    _preferencesDraft.measurementSystem.label,
                  ),
                  _summaryLine(
                    'Theme',
                    _preferencesDraft.themePreference.label,
                  ),
                  _summaryLine('AI', _aiDraft.enabled ? 'Enabled' : 'Disabled'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Text(
                'All values remain editable later from Settings. Any profile change recalculates targets immediately.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        );
    }
  }

  Widget _summaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Text(value, style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _textField({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
    String? helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          decoration: InputDecoration(labelText: label),
        ),
        if (helper != null) ...[
          const SizedBox(height: 12),
          Text(helper, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }

  Widget _numberField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    String? helper,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: ValueKey('$label-$_step'),
          initialValue: value,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          decoration: InputDecoration(labelText: label, suffixText: suffix),
        ),
        if (helper != null) ...[
          const SizedBox(height: 12),
          Text(helper, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }

  Widget _enumSegmented<T>({
    required String title,
    required List<T> values,
    required T current,
    required String Function(T) labelFor,
    required ValueChanged<T> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        SegmentedButton<T>(
          showSelectedIcon: false,
          multiSelectionEnabled: false,
          segments: values
              .map(
                (value) => ButtonSegment<T>(
                  value: value,
                  label: Text(labelFor(value)),
                ),
              )
              .toList(),
          selected: {current},
          onSelectionChanged: (selection) => onChanged(selection.first),
        ),
      ],
    );
  }

  Widget _timeTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return AppCard(
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        title: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        subtitle: Text(value),
        trailing: Icon(Icons.schedule),
      ),
    );
  }

  Future<void> _pickTime(int initialMinutes, ValueChanged<int> onPicked) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initialMinutes ~/ 60,
        minute: initialMinutes % 60,
      ),
    );
    if (selected == null) {
      return;
    }
    onPicked(selected.hour * 60 + selected.minute);
  }

  void _next() {
    if (_step < _labels.length - 1) {
      setState(() => _step += 1);
    }
  }

  Future<void> _finish() async {
    await ref
        .read(appControllerProvider.notifier)
        .completeSetup(
          _draft,
          preferences: _preferencesDraft,
          aiSettings: _aiDraft,
        );
    if (widget.standalone && mounted) {
      Navigator.of(context).pop();
    }
  }
}
