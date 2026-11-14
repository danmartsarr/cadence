import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: CadenceColors.background,
      colorScheme: const ColorScheme.dark(
        primary: CadenceColors.primary,
        secondary: CadenceColors.primaryLight,
        surface: CadenceColors.surface,
        error: CadenceColors.error,
        onPrimary: CadenceColors.textPrimary,
        onSurface: CadenceColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: CadenceColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: CadenceColors.textPrimary),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: CadenceColors.textPrimary, fontWeight: FontWeight.w700, letterSpacing: -1),
        displayMedium: TextStyle(color: CadenceColors.textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineLarge: TextStyle(color: CadenceColors.textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: CadenceColors.textPrimary, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: CadenceColors.textPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: CadenceColors.textPrimary, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        titleMedium: TextStyle(color: CadenceColors.textPrimary, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: CadenceColors.textSecondary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: CadenceColors.textPrimary),
        bodyMedium: TextStyle(color: CadenceColors.textSecondary),
        bodySmall: TextStyle(color: CadenceColors.textSecondary, fontSize: 12),
        labelLarge: TextStyle(color: CadenceColors.textPrimary, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CadenceColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CadenceColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CadenceColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CadenceColors.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: CadenceColors.textSecondary),
        labelStyle: const TextStyle(color: CadenceColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CadenceColors.primary,
          foregroundColor: CadenceColors.textPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CadenceColors.primaryLight,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: CadenceColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: CadenceColors.surface,
        selectedItemColor: CadenceColors.primaryLight,
        unselectedItemColor: CadenceColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: CadenceColors.border, thickness: 1),
      cardTheme: CardThemeData(
        color: CadenceColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CadenceColors.border),
        ),
      ),
    );
  }
}
