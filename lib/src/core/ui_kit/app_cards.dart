import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderColor, // Kept for API compatibility, but ignored in Cobalt Kinetic
    this.backgroundColor,
    this.isGlass = false,
    this.elevationLevel =
        1, // 1: Low (surface), 2: High (surfaceHigh), 3: Highest (surfaceHigher)
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final bool isGlass;
  final int elevationLevel;
  final VoidCallback? onTap;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Color getBgColor() {
      if (widget.backgroundColor != null) return widget.backgroundColor!;
      switch (widget.elevationLevel) {
        case 3:
          return colors.surfaceHigher;
        case 2:
          return colors.surfaceHigh;
        case 1:
        default:
          return colors.surface;
      }
    }

    Widget content = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isGlass
              ? getBgColor().withValues(alpha: 0.7)
              : getBgColor(),
          borderRadius: BorderRadius.circular(32), // Geometry lg (2rem)
          // No border rule applied
        ),
        child: Padding(padding: widget.padding, child: widget.child),
      ),
    );

    if (widget.isGlass) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: content,
        ),
      );
    }

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: content,
      );
    }

    return content;
  }
}

class AppSection extends StatelessWidget {
  const AppSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  title, // Removed uppercase for editorial feel
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        const SizedBox(height: 24), // Increased vertical rhythm
        child,
      ],
    );
  }
}
