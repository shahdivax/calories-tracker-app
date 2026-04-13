import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

class AppMetricTile extends StatelessWidget {
  const AppMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.subtitle,
    this.isGlass = false,
    this.compact = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final String? subtitle;
  final bool isGlass;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = Container(
      padding: EdgeInsets.all(compact ? 12 : 24),
      decoration: BoxDecoration(
        color: isGlass
            ? context.colors.surfaceHigher.withValues(alpha: 0.5)
            : context.colors.surfaceHigher,
        borderRadius: BorderRadius.circular(compact ? 20 : 32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: context.colors.textSecondary,
              fontSize: compact ? 10 : null,
            ),
          ),
          SizedBox(height: compact ? 6 : 12),
          Text(
            value,
            style:
                (compact
                        ? theme.textTheme.headlineSmall
                        : theme.textTheme.displaySmall)
                    ?.copyWith(
                      color: valueColor ?? context.colors.textPrimary,
                      height: 1.0,
                    ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: compact ? 2 : 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.colors.textTertiary,
                fontSize: compact ? 10 : null,
              ),
            ),
          ],
        ],
      ),
    );

    if (isGlass) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 20 : 32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: content,
        ),
      );
    }

    return content;
  }
}

class AppMacroBar extends StatelessWidget {
  const AppMacroBar({
    super.key,
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });

  final String label;
  final double value;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = target == 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              '${value.toStringAsFixed(0)} / ${target.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 6, // Thinner lines for elegant pro look
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.colors.surfaceHigher, // High contrast track
            borderRadius: BorderRadius.circular(100),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutExpo,
              tween: Tween<double>(begin: 0, end: ratio),
              builder: (context, val, _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: val,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: Offset.zero,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class AppRingMeter extends StatelessWidget {
  const AppRingMeter({
    super.key,
    required this.current,
    required this.target,
    required this.label,
  });

  final double current;
  final double target;
  final String label;

  @override
  Widget build(BuildContext context) {
    // The Metric Shard approach
    final ratio = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    final color = ratio < 0.75
        ? context.colors.primary
        : ratio < 1
        ? context.colors.secondary
        : context.colors.error;

    return ClipRRect(
      borderRadius: BorderRadius.circular(1000), // Perfect circle
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colors.surfaceHigh.withValues(alpha: 0.4),
            border: Border.all(
              color: context.colors.borderStrong,
            ), // Ghost border
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 260,
                height: 260,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: ratio),
                  duration: const Duration(milliseconds: 1800),
                  curve: Curves.elasticOut,
                  builder: (context, val, child) {
                    return CircularProgressIndicator(
                      value: val,
                      strokeWidth: 4, // Thin, elegant stroke
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    );
                  },
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: current),
                    duration: const Duration(milliseconds: 1800),
                    curve: Curves.easeOutExpo,
                    builder: (context, val, child) {
                      return Text(
                        val.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              height: 1.0,
                              color: context.colors.textPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
