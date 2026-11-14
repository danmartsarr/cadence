import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Editorial serif for album titles and headings, clean sans for the interface.
class CadenceType {
  CadenceType._();

  static TextStyle display(double size, {Color color = CadenceColors.textPrimary, FontStyle? style}) =>
      GoogleFonts.dmSerifDisplay(fontSize: size, color: color, height: 1.08, letterSpacing: -0.3, fontStyle: style);

  static TextStyle ui(double size, {FontWeight weight = FontWeight.w500, Color color = CadenceColors.textPrimary, double? spacing}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing);

  static TextStyle label(Color color) =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 1.4);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    final text = base.copyWith(
      displayLarge: CadenceType.display(48),
      displayMedium: CadenceType.display(40),
      headlineLarge: CadenceType.display(34),
      headlineMedium: CadenceType.display(30),
      headlineSmall: CadenceType.display(26),
      titleLarge: CadenceType.ui(19, weight: FontWeight.w700, spacing: -0.2),
      titleMedium: CadenceType.ui(15, weight: FontWeight.w600),
      titleSmall: CadenceType.ui(13, weight: FontWeight.w600, color: CadenceColors.textSecondary),
      bodyLarge: CadenceType.ui(15, weight: FontWeight.w400),
      bodyMedium: CadenceType.ui(14, weight: FontWeight.w400, color: CadenceColors.textSecondary),
      bodySmall: CadenceType.ui(12, weight: FontWeight.w400, color: CadenceColors.textSecondary),
      labelLarge: CadenceType.ui(14, weight: FontWeight.w700),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: CadenceColors.background,
      textTheme: text,
      colorScheme: const ColorScheme.dark(
        primary: CadenceColors.primary,
        secondary: CadenceColors.accent,
        surface: CadenceColors.surface,
        error: CadenceColors.error,
        onPrimary: CadenceColors.onPrimary,
        onSurface: CadenceColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: CadenceType.ui(18, weight: FontWeight.w700),
        iconTheme: const IconThemeData(color: CadenceColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CadenceColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: CadenceColors.textPrimary, width: 1.5),
        ),
        hintStyle: CadenceType.ui(14, weight: FontWeight.w400, color: CadenceColors.textSecondary),
        labelStyle: CadenceType.ui(14, weight: FontWeight.w400, color: CadenceColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CadenceColors.primary,
          foregroundColor: CadenceColors.onPrimary,
          disabledBackgroundColor: CadenceColors.surfaceElevated,
          minimumSize: const Size(double.infinity, 52),
          shape: const StadiumBorder(),
          textStyle: CadenceType.ui(15, weight: FontWeight.w700, spacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CadenceColors.textPrimary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: CadenceColors.textMuted),
          shape: const StadiumBorder(),
          textStyle: CadenceType.ui(15, weight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: CadenceColors.textPrimary, textStyle: CadenceType.ui(14, weight: FontWeight.w600)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xF20E1013),
        indicatorColor: Colors.transparent,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => CadenceType.ui(11,
            weight: FontWeight.w600, color: s.contains(WidgetState.selected) ? CadenceColors.textPrimary : CadenceColors.textMuted)),
        iconTheme: WidgetStateProperty.resolveWith((s) =>
            IconThemeData(color: s.contains(WidgetState.selected) ? CadenceColors.textPrimary : CadenceColors.textMuted, size: 24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: CadenceColors.textPrimary,
        contentTextStyle: CadenceType.ui(14, weight: FontWeight.w600, color: CadenceColors.background),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(color: CadenceColors.border, thickness: 1),
      cardTheme: CardThemeData(
        color: CadenceColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
