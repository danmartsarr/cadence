import 'package:flutter/material.dart';

class CadenceColors {
  CadenceColors._();

  static const background = Color(0xFF050A14);
  static const surface = Color(0xFF0D1B2A);
  static const surfaceElevated = Color(0xFF1A3A5C);
  static const primary = Color(0xFF2E86C1);
  static const primaryLight = Color(0xFF5DADE2);
  static const textPrimary = Color(0xFFE8F4F8);
  static const textSecondary = Color(0xFF8DAEBE);
  static const border = Color(0xFF1E3A52);
  static const starActive = Color(0xFF5DADE2);
  static const starInactive = Color(0xFF1E3A52);
  static const error = Color(0xFFE74C3C);
  static const success = Color(0xFF27AE60);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1B2A), Color(0xFF050A14)],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xFF050A14)],
  );

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E86C1), Color(0xFF1A5276)],
  );
}
