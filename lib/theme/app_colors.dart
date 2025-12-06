import 'package:flutter/material.dart';

class AppColors {
  // Background colors
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color cardBackground = Color(0xFF252525);

  // Primary theme colors
  static const Color primary = Color(0xFF2196F3); // Azul científico
  static const Color secondary = Color(0xFF00E676); // Verde éxito/fresco
  static const Color accent = Color(0xFFFF4081); // Rosa fatiga/alerta

  // Text colors - IMPROVED CONTRAST
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(
    0xFFCCCCCC,
  ); // Was #B3B3B3, now brighter
  static const Color textDisabled = Color(0xFF888888);

  // Input/Form colors
  static const Color inputBackground = Color(0xFF2D2D2D);
  static const Color inputBorder = Color(0xFF404040);
  static const Color inputBorderFocused = Color(0xFF2196F3);

  // Success/Warning/Error
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);

  // Fatigue states
  static const Color muscleFresh = Color(0xFF00E676);
  static const Color muscleRecovering = Color(0xFFFFC107);
  static const Color muscleFatigued = Color(0xFFFF5252);

  // Button text (for elevated buttons with colored backgrounds)
  static const Color buttonTextLight = Color(0xFFFFFFFF);
  static const Color buttonTextDark = Color(0xFF000000);
}
