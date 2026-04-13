import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../services/app_controller.dart';

class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final preferences = ref.watch(
      appControllerProvider.select((state) => state.valueOrNull?.preferences),
    );
    return (preferences?.themePreference ?? ThemePreference.system).themeMode;
  }

  Future<void> toggleTheme() async {
    if (state == ThemeMode.light) {
      await setTheme(ThemeMode.dark);
    } else if (state == ThemeMode.dark) {
      await setTheme(ThemeMode.system);
    } else {
      await setTheme(ThemeMode.light);
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final data = ref.read(appControllerProvider).valueOrNull;
    if (data == null) {
      return;
    }
    await ref
        .read(appControllerProvider.notifier)
        .updatePreferences(
          data.preferences.copyWith(themePreference: mode.themePreference),
        );
  }
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeMode>(
  () {
    return ThemeController();
  },
);

extension ThemePreferenceModeX on ThemePreference {
  ThemeMode get themeMode {
    switch (this) {
      case ThemePreference.system:
        return ThemeMode.system;
      case ThemePreference.light:
        return ThemeMode.light;
      case ThemePreference.dark:
        return ThemeMode.dark;
    }
  }
}

extension ThemeModePreferenceX on ThemeMode {
  ThemePreference get themePreference {
    switch (this) {
      case ThemeMode.system:
        return ThemePreference.system;
      case ThemeMode.light:
        return ThemePreference.light;
      case ThemeMode.dark:
        return ThemePreference.dark;
    }
  }
}
