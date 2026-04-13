import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/app_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/ui_kit/ui_kit.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/app_shell.dart';

class FoodTrackerApp extends ConsumerWidget {
  const FoodTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Recon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeControllerProvider),
      home: const AppBootstrap(),
    );
  }
}

class AppBootstrap extends ConsumerWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appControllerProvider);

    return appState.when(
      data: (data) =>
          data.profile.isComplete ? const AppShell() : const OnboardingScreen(),
      error: (error, stackTrace) => AppScaffold(
        title: 'BOOT FAILURE',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load local data.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      loading: () => const _LoadingScreen(),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            SizedBox(height: 16),
            Text('BOOTING FITNESS OS'),
          ],
        ),
      ),
    );
  }
}
