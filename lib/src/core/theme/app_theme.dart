import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color surfaceHigher;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color primary;
  final Color primaryDim;
  final Color secondary;
  final Color error;
  final Color accent;

  // Aliases to maintain compatibility with the old God Controller screens
  Color get gold => primary;
  Color get goldDim => primaryDim;
  Color get terracotta => secondary;
  Color get brick => error;
  Color get sage => accent;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.surfaceHigher,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.primary,
    required this.primaryDim,
    required this.secondary,
    required this.error,
    required this.accent,
  });

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceHigh,
    Color? surfaceHigher,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? primary,
    Color? primaryDim,
    Color? secondary,
    Color? error,
    Color? accent,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      surfaceHigher: surfaceHigher ?? this.surfaceHigher,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      primary: primary ?? this.primary,
      primaryDim: primaryDim ?? this.primaryDim,
      secondary: secondary ?? this.secondary,
      error: error ?? this.error,
      accent: accent ?? this.accent,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      surfaceHigher: Color.lerp(surfaceHigher, other.surfaceHigher, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDim: Color.lerp(primaryDim, other.primaryDim, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      error: Color.lerp(error, other.error, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

class AppTheme {
  // Cobalt Kinetic Design System implementation
  static const Color _primary = Color(0xFF85ADFF); // Cobalt Action
  static const Color _primaryDim = Color(0xFF0070EB); // Cobalt Deep
  static const Color _secondary = Color(0xFFFAB0FF); // Vitals Tertiary Heatmap
  static const Color _error = Color(0xFFFF5252);
  static const Color _accent = Color(0xFF00E5FF);

  // The Void
  static const _darkColors = AppColors(
    background: Color(0xFF0E0E0E), // Base Obsidian
    surface: Color(0xFF131313), // Surface Low
    surfaceHigh: Color(0xFF1A1A1A),
    surfaceHigher: Color(0xFF262626), // Surface Highest
    border: Colors.transparent, // "No-Line Rule"
    borderStrong: Color(0x26FFFFFF), // Ghost border fallback (15% white)
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFADAAAA), // On Surface Variant
    textTertiary: Color(0xFF757575),
    primary: _primary,
    primaryDim: _primaryDim,
    secondary: _secondary,
    error: _error,
    accent: _accent,
  );

  static const _lightColors = AppColors(
    background: Color(0xFFF4F7FB),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFF0F3F8),
    surfaceHigher: Color(0xFFE7ECF4),
    border: Colors.transparent,
    borderStrong: Color(0x1A16294B),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF5F6B7A),
    textTertiary: Color(0xFF7F8A99),
    primary: _primary,
    primaryDim: _primaryDim,
    secondary: _secondary,
    error: _error,
    accent: _accent,
  );

  static ThemeData get darkTheme => _buildTheme(Brightness.dark, _darkColors);
  static ThemeData get lightTheme =>
      _buildTheme(Brightness.light, _lightColors);

  static ThemeData _buildTheme(Brightness brightness, AppColors colors) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.background,
      secondary: colors.secondary,
      onSecondary: colors.background,
      error: colors.error,
      onError: colors.textPrimary,
      surface: colors.surface,
      onSurface: colors.textPrimary,
    );

    // Typography: Editorial Authority
    // Manrope for expressive display, Inter for technical body
    final baseTextTheme = TextTheme(
      displayLarge: GoogleFonts.manrope(
        fontSize: 56,
        fontWeight: FontWeight.w800,
        color: colors.textPrimary,
        letterSpacing: -1.5,
      ),
      displayMedium: GoogleFonts.manrope(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: colors.textPrimary,
        letterSpacing: -1.0,
      ),
      displaySmall: GoogleFonts.manrope(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: colors.textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        height: 1.5,
        color: colors.textSecondary, // Use on_surface_variant for body
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 1.5,
        color: colors.textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 13,
        height: 1.4,
        color: colors.textTertiary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: colors.textPrimary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: colors.textSecondary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      dividerColor: colors.border,
      disabledColor: colors.textTertiary,
      cardColor: colors.surface,
      extensions: [colors],
      textTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: colors.surface, // Low Surface
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceHigher,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface, // Use surface_container_low pill
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: _inputBorder(Colors.transparent),
        enabledBorder: _inputBorder(Colors.transparent),
        focusedBorder: _inputBorder(
          colors.primaryDim,
        ), // Focus glow alternative
        errorBorder: _inputBorder(colors.error),
        labelStyle: TextStyle(color: colors.textSecondary),
        hintStyle: TextStyle(color: colors.textTertiary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent, // Handled by glassmorphism
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.primary.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: colors.primary,
              size: 28,
            ); // Thin stroke icons preferred
          }
          return IconThemeData(color: colors.textSecondary, size: 24);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: colors.primary, // Primary fixed
              foregroundColor: colors.background, // On primary fixed
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              textStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                fontSize: 16,
              ),
            ).copyWith(
              // Simulate glass click
              overlayColor: WidgetStateProperty.all(
                Colors.white.withValues(alpha: 0.2),
              ),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          backgroundColor: colors.surfaceHigher, // Secondary background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: BorderSide.none, // No border rule
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primaryDim,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: brightness == Brightness.dark
              ? colors.background
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: color == Colors.transparent
          ? BorderSide.none
          : BorderSide(color: color, width: 1.5),
    );
  }
}
