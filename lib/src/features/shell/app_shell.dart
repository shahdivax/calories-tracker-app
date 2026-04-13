import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

import '../dashboard/dashboard_screen.dart';
import '../food_log/food_log_screen.dart';
import '../metrics/metrics_screen.dart';
import '../more/more_screen.dart';
import '../workouts/workouts_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  static const _screens = [
    DashboardScreen(),
    FoodLogScreen(),
    WorkoutsScreen(),
    MetricsScreen(),
    MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_index == index) return;
    setState(() => _index = index);
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          FadeTransition(
            opacity: _animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.05),
                end: Offset.zero,
              ).animate(_animation),
              child: _screens[_index],
            ),
          ),

          // Cobalt Kinetic Bottom Nav Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              decoration: BoxDecoration(
                color: const Color(0xFF0E0E0E).withValues(alpha: 0.9),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 40,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildNavItem(0, Icons.dashboard, 'Home'),
                  _buildNavItem(1, Icons.restaurant, 'Eat'),
                  _buildCenterNavItem(2, Icons.fitness_center, 'Train'),
                  _buildNavItem(3, Icons.query_stats, 'Stats'),
                  _buildNavItem(4, Icons.settings, 'More'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _index == index;
    final color = isSelected ? context.colors.primary : const Color(0xFFADAAAA);

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterNavItem(int index, IconData icon, String label) {
    final isSelected = _index == index;
    final color = isSelected ? context.colors.primary : const Color(0xFFADAAAA);

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -12),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? context.colors.primary
                    : context.colors.surfaceHigher,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: context.colors.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Transform.rotate(
                angle: isSelected
                    ? math.pi / 4
                    : 0, // Rotate 45deg when selected
                child: Icon(
                  icon,
                  color: isSelected
                      ? Colors.black
                      : Colors.white.withValues(alpha: 0.6),
                  size: 28,
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -4),
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
