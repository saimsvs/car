import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Steel & Signal — cool mist atmosphere, ink navy, diagnostic teal.
abstract final class AppColors {
  static const background = Color(0xFFE8EEF4);
  static const backgroundDeep = Color(0xFFD5DEE8);
  static const surface = Color(0xFFF7FAFC);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const ink = Color(0xFF0C1B2A);
  static const inkSoft = Color(0xFF3D5166);
  static const muted = Color(0xFF7A8FA3);
  static const line = Color(0xFFC9D5E2);
  static const teal = Color(0xFF0D9488);
  static const tealDeep = Color(0xFF0F766E);
  static const tealSoft = Color(0xFFCCFBF1);
  static const amber = Color(0xFFD97706);
  static const amberSoft = Color(0xFFFEF3C7);
  static const coral = Color(0xFFE11D48);
  static const coralSoft = Color(0xFFFFE4E6);
  static const navy = Color(0xFF1E3A5F);
  static const navySoft = Color(0xFFE0E7FF);
}

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.light(
        primary: AppColors.teal,
        onPrimary: Colors.white,
        secondary: AppColors.navy,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        error: AppColors.coral,
      ),
    );

    final display = GoogleFonts.outfitTextTheme(base.textTheme);
    final body = GoogleFonts.dmSansTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: display.copyWith(
        displayLarge: display.displayLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
        ),
        displayMedium: display.displayMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        headlineLarge: display.headlineLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        headlineMedium: display.headlineMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        headlineSmall: display.headlineSmall?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: body.titleLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: body.titleMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: body.titleSmall?.copyWith(
          color: AppColors.inkSoft,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: body.bodyLarge?.copyWith(color: AppColors.inkSoft),
        bodyMedium: body.bodyMedium?.copyWith(color: AppColors.inkSoft),
        bodySmall: body.bodySmall?.copyWith(color: AppColors.muted),
        labelLarge: body.labelLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        labelMedium: body.labelMedium?.copyWith(
          color: AppColors.muted,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: body.labelSmall?.copyWith(
          color: AppColors.muted,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.92),
        indicatorColor: AppColors.tealSoft,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.tealDeep : AppColors.muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? AppColors.tealDeep : AppColors.muted,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
    );
  }
}
