export 'app_scaffold.dart';
export 'app_cards.dart';
export 'app_metrics.dart';

// Temporarily port over AppLoadingOverlay into the new structure so things compile
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_cards.dart';

class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    required this.child,
    required this.isBusy,
    this.label = 'WORKING...',
  });

  final Widget child;
  final bool isBusy;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isBusy)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: AppCard(
                    borderColor: context.colors.gold,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.colors.gold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: context.colors.gold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
