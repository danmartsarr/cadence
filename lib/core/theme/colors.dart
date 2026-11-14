import 'package:flutter/material.dart';

/// Palette: near-black stage (Spotify), slate cards and green stars (Letterboxd).
class CadenceColors {
  CadenceColors._();

  static const background = Color(0xFF0E1013);
  static const surface = Color(0xFF181B21);
  static const surfaceElevated = Color(0xFF232830);
  static const primary = Color(0xFF1ED760);
  static const primaryLight = Color(0xFF3FE07A);
  static const onPrimary = Color(0xFF07130B);
  static const accent = Color(0xFFFF8A3D);
  static const accentBlue = Color(0xFF4CC2F1);
  static const textPrimary = Color(0xFFF3F5F7);
  static const textSecondary = Color(0xFF98A2AE);
  static const textMuted = Color(0xFF66707C);
  static const border = Color(0xFF2A2F38);
  static const starActive = Color(0xFF1ED760);
  static const starInactive = Color(0xFF3A414C);
  static const error = Color(0xFFFF5A5F);
  static const success = Color(0xFF1ED760);

  /// Vivid tiles for genres and moods.
  static const tiles = [
    Color(0xFFE2462F), Color(0xFF2D46B9), Color(0xFF8C5BB8), Color(0xFFDC1A62),
    Color(0xFF1C8C5A), Color(0xFFC7650E), Color(0xFF2A7E92), Color(0xFF6B3E66),
    Color(0xFF477D95), Color(0xFFB0306A),
  ];

  static Color tileFor(String key) => tiles[key.codeUnits.fold<int>(0, (a, b) => a * 31 + b).abs() % tiles.length];

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, background],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, background],
  );

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1ED760), Color(0xFF12A84A)],
  );
}
