import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.trailing,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.padding = const EdgeInsets.all(0),
    this.useHeroHeader = false,
  });

  final String? title;
  final Widget? trailing;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final EdgeInsetsGeometry padding;
  final bool useHeroHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false, // Let glassmorphism handle bottom
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  32,
                  40,
                  32,
                  24,
                ), // Extreme vertical rhythm
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        title!,
                        style: useHeroHeader
                            ? theme.textTheme.displayLarge?.copyWith(
                                color: context.colors.textPrimary,
                              )
                            : theme.textTheme.headlineLarge?.copyWith(
                                color: context.colors.textPrimary,
                              ),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            Expanded(
              child: Padding(padding: padding, child: body),
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
