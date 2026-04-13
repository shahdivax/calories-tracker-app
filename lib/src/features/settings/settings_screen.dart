import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models.dart';
import '../../core/services/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../analytics/analytics_screen.dart';
import '../diary/diary_screen.dart';
import '../history/history_screen.dart';
import '../onboarding/onboarding_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider).valueOrNull;
    if (data == null) {
      return const SizedBox.shrink();
    }
    final profile = data.profile;
    final ai = data.aiSettings;
    final preferences = data.preferences;
    final notifications = preferences.notifications;
    final deepAnalyticsInsight = _deepAnalyticsInsight(data);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: context.colors.background.withValues(alpha: 0.7),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    Icons.local_fire_department,
                    color: context.colors.primary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                children: [
                  if (data.targetUpdate != null) ...[
                    _GlassBlock(
                      child: Row(
                        children: [
                          Expanded(child: Text(data.targetUpdate!.message)),
                          IconButton(
                            onPressed: () => ref
                                .read(appControllerProvider.notifier)
                                .clearTargetUpdate(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                context.colors.primaryDim.withValues(
                                  alpha: 0.10,
                                ),
                                context.colors.secondary.withValues(
                                  alpha: 0.08,
                                ),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    profile.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge
                                        ?.copyWith(
                                          color: context.colors.textPrimary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: _ProfileStatCard(
                                    label: 'Height',
                                    value: profile.heightCm.toStringAsFixed(0),
                                    suffix: 'cm',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ProfileStatCard(
                                    label: 'Goal Weight',
                                    value: profile.goalWeightKg.toStringAsFixed(
                                      1,
                                    ),
                                    suffix: 'kg',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SettingsActionTile(
                    icon: Icons.calendar_month,
                    iconColor: context.colors.primary,
                    title: 'Training Diary',
                    subtitle: 'View full calendar & workout history',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceHigher,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.insights,
                              size: 18,
                              color: context.colors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI ANALYSIS',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: context.colors.primary,
                                    letterSpacing: 2,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Deep Analytics',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deepAnalyticsInsight?.text ??
                              (ai.enabled && ai.apiKey.trim().isNotEmpty
                                  ? 'AI is preparing a 30-day roast from your real logs. Give it a moment; apparently even sarcasm needs data.'
                                  : 'Connect Gemini in AI settings to turn your 30-day logs into a real roast instead of this polite placeholder.'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: context.colors.primary.withValues(
                                alpha: 0.18,
                              ),
                            ),
                          ),
                          child: Text(
                            deepAnalyticsInsight == null
                                ? 'Waiting for AI'
                                : 'AI generated • 30-day data',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: context.colors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SettingsGroup(
                    title: 'Body Profile',
                    children: [
                      _editableTile(
                        context,
                        label: 'Name',
                        value: profile.name,
                        onTap: () => _editText(
                          context,
                          ref,
                          profile,
                          'Name',
                          profile.name,
                          (value) => profile.copyWith(name: value),
                        ),
                      ),
                      _editableTile(
                        context,
                        label: 'Age',
                        value: '${profile.age}',
                        onTap: () => _editNumber(
                          context,
                          ref,
                          profile,
                          'Age',
                          profile.age.toString(),
                          (value) => profile.copyWith(age: value.toInt()),
                        ),
                      ),
                      _editableTile(
                        context,
                        label: 'Height',
                        value: '${profile.heightCm.toStringAsFixed(0)} cm',
                        onTap: () => _editNumber(
                          context,
                          ref,
                          profile,
                          'Height',
                          profile.heightCm.toStringAsFixed(0),
                          (value) => profile.copyWith(heightCm: value),
                        ),
                      ),
                      _editableTile(
                        context,
                        label: 'Goal Weight',
                        value: '${profile.goalWeightKg.toStringAsFixed(1)} kg',
                        onTap: () => _editNumber(
                          context,
                          ref,
                          profile,
                          'Goal Weight',
                          profile.goalWeightKg.toStringAsFixed(1),
                          (value) => profile.copyWith(goalWeightKg: value),
                        ),
                      ),
                      _editableTile(
                        context,
                        label: 'Activity',
                        value: profile.activityLevel.label,
                        onTap: () => _pickActivity(context, ref, profile),
                      ),
                      _editableTile(
                        context,
                        label: 'Goal Type',
                        value: profile.goalType.label,
                        onTap: () => _pickGoalType(context, ref, profile),
                      ),
                      _editableTile(
                        context,
                        label: 'Diet Type',
                        value: profile.dietType.label,
                        onTap: () => _pickDietType(context, ref, profile),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SettingsGroup(
                    title: 'AI Configuration',
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Personal Trainer AI'),
                        subtitle: Text(
                          ai.enabled
                              ? 'Gemini-powered food scan, insights, and target tuning are active.'
                              : 'Disabled',
                        ),
                        value: ai.enabled,
                        onChanged: (value) => ref
                            .read(appControllerProvider.notifier)
                            .updateAiSettings(ai.copyWith(enabled: value)),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Developer API'),
                        subtitle: Text(
                          ai.apiKey.isEmpty
                              ? 'No key saved yet'
                              : 'API key configured',
                        ),
                        trailing: const Icon(Icons.key),
                        onTap: () => _editApiKey(context, ref, ai),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('AI Model'),
                        subtitle: Text(ai.model),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _editAiModel(context, ref, ai),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Adaptive Maintenance'),
                        subtitle: Text(
                          ai.autoAdaptiveTargets
                              ? 'Rebalances targets from your latest 5 food, workout, and weight records.'
                              : 'Keeps the manual target model only.',
                        ),
                        value: ai.autoAdaptiveTargets,
                        onChanged: (value) => ref
                            .read(appControllerProvider.notifier)
                            .updateAiSettings(
                              ai.copyWith(autoAdaptiveTargets: value),
                            ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Test Gemini Connection'),
                        subtitle: Text(
                          ai.lastAdaptiveSummary ??
                              'Validate the saved API key and model immediately.',
                        ),
                        trailing: const Icon(Icons.network_check),
                        onTap: () => _testGeminiConnection(context, ref, ai),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Adaptive Window'),
                        subtitle: Text(
                          '${ai.adaptiveLookbackCount} recent records, every ${ai.adaptiveCadenceDays} days',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _editAdaptiveWindow(context, ref, ai),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SettingsGroup(
                    title: 'Notifications',
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Reminder Schedule'),
                        subtitle: Text(
                          notifications.enabled
                              ? 'Weigh-in, meals, two random reminders, and weekly check-in are configurable.'
                              : 'All reminders are currently disabled.',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            _editNotificationPreferences(context, ref, data),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SettingsGroup(
                    title: 'Interface',
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Theme Mode'),
                        subtitle: Text(
                          'Current: ${preferences.themePreference.label.toUpperCase()}',
                        ),
                        leading: const Icon(Icons.dark_mode),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            _pickThemePreference(context, ref, preferences),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Measurement Units'),
                        subtitle: Text(preferences.measurementSystem.label),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            _pickMeasurementSystem(context, ref, preferences),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Analytics'),
                        subtitle: const Text(
                          '30-day trends and metabolic heatmap',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AnalyticsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SettingsGroup(
                    title: 'Data Management',
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Export Data'),
                        subtitle: const Text(
                          'Download CSV workout and food history',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _exportCsv(context, ref, data),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Import External Data'),
                        subtitle: const Text('Sync food logs from CSV'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _importFoodCsv(context, ref),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Diary'),
                        subtitle: const Text('Open daily notes and records'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DiaryScreen(),
                          ),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Reconfigure Profile'),
                        subtitle: const Text('Run onboarding again'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const OnboardingScreen(standalone: true),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.colors.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Icon(
                        Icons.delete_forever,
                        color: context.colors.error,
                      ),
                      title: Text(
                        'Reset Application',
                        style: TextStyle(
                          color: context.colors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Permanently wipe all local profile data',
                        style: TextStyle(
                          color: context.colors.error.withValues(alpha: 0.65),
                        ),
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
}

extension on SettingsScreen {
  AiInsight? _deepAnalyticsInsight(AppStateData data) {
    final insights =
        data.aiInsights
            .where((item) => item.type == 'settings-deep-analytics')
            .toList()
          ..sort((a, b) {
            final aTime =
                DateTime.tryParse(a.createdAt ?? '') ?? parseDayKey(a.date);
            final bTime =
                DateTime.tryParse(b.createdAt ?? '') ?? parseDayKey(b.date);
            return aTime.compareTo(bTime);
          });
    return insights.isEmpty ? null : insights.last;
  }
}

class _GlassBlock extends StatelessWidget {
  const _GlassBlock({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.label,
    required this.value,
    required this.suffix,
  });
  final String label;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceHigher,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  suffix,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.colors.textSecondary,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

extension on SettingsScreen {
  Widget _editableTile(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium,
      ),
      subtitle: Text(value),
      trailing: Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<void> _editText(
    BuildContext context,
    WidgetRef ref,
    BodyProfile profile,
    String title,
    String initial,
    BodyProfile Function(String) update,
  ) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await ref
          .read(appControllerProvider.notifier)
          .updateProfile(update(result));
    }
  }

  Future<void> _editNumber(
    BuildContext context,
    WidgetRef ref,
    BodyProfile profile,
    String title,
    String initial,
    BodyProfile Function(double) update,
  ) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, double.tryParse(controller.text)),
            child: Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      await ref
          .read(appControllerProvider.notifier)
          .updateProfile(update(result));
    }
  }

  Future<void> _pickActivity(
    BuildContext context,
    WidgetRef ref,
    BodyProfile profile,
  ) async {
    final value = await _pickEnum<ActivityLevel>(
      context,
      title: 'Activity Level',
      values: ActivityLevel.values,
      labelFor: (item) => item.label,
    );
    if (value != null) {
      await ref
          .read(appControllerProvider.notifier)
          .updateProfile(profile.copyWith(activityLevel: value));
    }
  }

  Future<void> _pickGoalType(
    BuildContext context,
    WidgetRef ref,
    BodyProfile profile,
  ) async {
    final value = await _pickEnum<GoalType>(
      context,
      title: 'Goal Type',
      values: GoalType.values,
      labelFor: (item) => item.label,
    );
    if (value != null) {
      await ref
          .read(appControllerProvider.notifier)
          .updateProfile(profile.copyWith(goalType: value));
    }
  }

  Future<void> _pickDietType(
    BuildContext context,
    WidgetRef ref,
    BodyProfile profile,
  ) async {
    final value = await _pickEnum<DietType>(
      context,
      title: 'Diet Type',
      values: DietType.values,
      labelFor: (item) => item.label,
    );
    if (value != null) {
      await ref
          .read(appControllerProvider.notifier)
          .updateProfile(profile.copyWith(dietType: value));
    }
  }

  Future<void> _pickThemePreference(
    BuildContext context,
    WidgetRef ref,
    AppPreferences preferences,
  ) async {
    final value = await _pickEnum<ThemePreference>(
      context,
      title: 'Theme Mode',
      values: ThemePreference.values,
      labelFor: (item) => item.label,
    );
    if (value == null) {
      return;
    }
    if (context.mounted) {
      await ref
          .read(themeControllerProvider.notifier)
          .setTheme(value.themeMode);
    }
  }

  Future<void> _pickMeasurementSystem(
    BuildContext context,
    WidgetRef ref,
    AppPreferences preferences,
  ) async {
    final value = await _pickEnum<MeasurementSystem>(
      context,
      title: 'Measurement Units',
      values: MeasurementSystem.values,
      labelFor: (item) => item.label,
    );
    if (value == null) {
      return;
    }
    await ref
        .read(appControllerProvider.notifier)
        .updatePreferences(preferences.copyWith(measurementSystem: value));
  }

  Future<void> _editAiModel(
    BuildContext context,
    WidgetRef ref,
    AiSettings settings,
  ) async {
    final controller = TextEditingController(text: settings.model);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('AI Model'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await ref
          .read(appControllerProvider.notifier)
          .updateAiSettings(settings.copyWith(model: result));
    }
  }

  Future<void> _editApiKey(
    BuildContext context,
    WidgetRef ref,
    AiSettings settings,
  ) async {
    final controller = TextEditingController(text: settings.apiKey);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Gemini API Key'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      await ref
          .read(appControllerProvider.notifier)
          .updateAiSettings(settings.copyWith(apiKey: result));
    }
  }

  Future<void> _editAdaptiveWindow(
    BuildContext context,
    WidgetRef ref,
    AiSettings settings,
  ) async {
    final lookbackController = TextEditingController(
      text: settings.adaptiveLookbackCount.toString(),
    );
    final cadenceController = TextEditingController(
      text: settings.adaptiveCadenceDays.toString(),
    );
    final result = await showDialog<AiSettings>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adaptive Target Window'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: lookbackController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Recent records to inspect',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cadenceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Recalculate cadence (days)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              settings.copyWith(
                adaptiveLookbackCount:
                    int.tryParse(lookbackController.text.trim()) ??
                    settings.adaptiveLookbackCount,
                adaptiveCadenceDays:
                    int.tryParse(cadenceController.text.trim()) ??
                    settings.adaptiveCadenceDays,
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) {
      return;
    }
    await ref
        .read(appControllerProvider.notifier)
        .updateAiSettings(
          result.copyWith(
            adaptiveLookbackCount: result.adaptiveLookbackCount.clamp(3, 14),
            adaptiveCadenceDays: result.adaptiveCadenceDays.clamp(1, 7),
          ),
        );
  }

  Future<void> _testGeminiConnection(
    BuildContext context,
    WidgetRef ref,
    AiSettings settings,
  ) async {
    try {
      final message = await ref
          .read(aiRuntimeServiceProvider)
          .testConnection(settings);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _editNotificationPreferences(
    BuildContext context,
    WidgetRef ref,
    AppStateData data,
  ) async {
    var draft = data.preferences.notifications;

    Future<void> pickTime(
      StateSetter setState,
      int current,
      int Function(int) apply,
    ) async {
      final selected = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      );
      if (selected == null) {
        return;
      }
      setState(() {
        final minutes = selected.hour * 60 + selected.minute;
        apply(minutes);
      });
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
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Weigh-in Reminder'),
                  subtitle: const Text(
                    'Scheduled from your wake time + 15 min',
                  ),
                  value: draft.weighInEnabled,
                  onChanged: (value) => setState(
                    () => draft = draft.copyWith(weighInEnabled: value),
                  ),
                ),
                _notificationRow(
                  context,
                  label: 'Breakfast',
                  enabled: draft.breakfastEnabled,
                  value: formatMinutes(draft.breakfastMinutes),
                  onToggle: (value) => setState(
                    () => draft = draft.copyWith(breakfastEnabled: value),
                  ),
                  onTap: () =>
                      pickTime(setState, draft.breakfastMinutes, (minutes) {
                        draft = draft.copyWith(breakfastMinutes: minutes);
                        return minutes;
                      }),
                ),
                _notificationRow(
                  context,
                  label: 'Lunch',
                  enabled: draft.lunchEnabled,
                  value: formatMinutes(draft.lunchMinutes),
                  onToggle: (value) => setState(
                    () => draft = draft.copyWith(lunchEnabled: value),
                  ),
                  onTap: () =>
                      pickTime(setState, draft.lunchMinutes, (minutes) {
                        draft = draft.copyWith(lunchMinutes: minutes);
                        return minutes;
                      }),
                ),
                _notificationRow(
                  context,
                  label: 'Dinner',
                  enabled: draft.dinnerEnabled,
                  value: formatMinutes(draft.dinnerMinutes),
                  onToggle: (value) => setState(
                    () => draft = draft.copyWith(dinnerEnabled: value),
                  ),
                  onTap: () =>
                      pickTime(setState, draft.dinnerMinutes, (minutes) {
                        draft = draft.copyWith(dinnerMinutes: minutes);
                        return minutes;
                      }),
                ),
                _notificationRow(
                  context,
                  label: 'Random Ping 1',
                  enabled: draft.randomOneEnabled,
                  value: formatMinutes(draft.randomOneMinutes),
                  onToggle: (value) => setState(
                    () => draft = draft.copyWith(randomOneEnabled: value),
                  ),
                  onTap: () =>
                      pickTime(setState, draft.randomOneMinutes, (minutes) {
                        draft = draft.copyWith(randomOneMinutes: minutes);
                        return minutes;
                      }),
                ),
                _notificationRow(
                  context,
                  label: 'Random Ping 2',
                  enabled: draft.randomTwoEnabled,
                  value: formatMinutes(draft.randomTwoMinutes),
                  onToggle: (value) => setState(
                    () => draft = draft.copyWith(randomTwoEnabled: value),
                  ),
                  onTap: () =>
                      pickTime(setState, draft.randomTwoMinutes, (minutes) {
                        draft = draft.copyWith(randomTwoMinutes: minutes);
                        return minutes;
                      }),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Weekly Check-in'),
                  subtitle: Text(formatMinutes(draft.weeklyCheckInMinutes)),
                  value: draft.weeklyCheckInEnabled,
                  onChanged: (value) => setState(
                    () => draft = draft.copyWith(weeklyCheckInEnabled: value),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => pickTime(
                      setState,
                      draft.weeklyCheckInMinutes,
                      (minutes) {
                        draft = draft.copyWith(weeklyCheckInMinutes: minutes);
                        return minutes;
                      },
                    ),
                    child: const Text('Edit Weekly Check-in Time'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, draft),
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

  Widget _notificationRow(
    BuildContext context, {
    required String label,
    required bool enabled,
    required String value,
    required ValueChanged<bool> onToggle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value),
      trailing: Switch(value: enabled, onChanged: onToggle),
      onTap: onTap,
    );
  }

  Future<void> _exportCsv(
    BuildContext context,
    WidgetRef ref,
    AppStateData data,
  ) async {
    final csv = ref.read(csvServiceProvider);
    final files = await csv.exportAll(data);
    await csv.shareFiles(files);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported ${files.length} CSV files')),
      );
    }
  }

  Future<void> _importFoodCsv(BuildContext context, WidgetRef ref) async {
    final csv = ref.read(csvServiceProvider);
    final items = await csv.importFoodLogs();
    for (final item in items) {
      await ref.read(appControllerProvider.notifier).addFoodEntry(item);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${items.length} food log rows')),
      );
    }
  }

  Future<T?> _pickEnum<T>(
    BuildContext context, {
    required String title,
    required List<T> values,
    required String Function(T) labelFor,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: values
            .map(
              (value) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, value),
                child: Text(labelFor(value)),
              ),
            )
            .toList(),
      ),
    );
  }
}
