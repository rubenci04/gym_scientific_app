import 'package:flutter/material.dart';

class AppColors {
  // Colores Base
  static const Color primary = Color(0xFF2E86C1); // Azul científico
  static const Color secondary = Color(0xFF1ABC9C); // Turquesa
  static const Color background = Color(0xFF121212); // Negro suave
  static const Color surface = Color(0xFF1E1E1E); // Gris oscuro
  static const Color error = Color(0xFFCF6679);
  static const Color onPrimary = Colors.white;
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.grey;
  static const Color cardColor = Color(0xFF1E1E1E);
  static const Color inputBackground = Color(0xFF2C2C2C);

  // --- DEFINICIÓN DE TEMAS ---

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      cardColor: Colors.white,
      dividerColor: Colors.grey[300],
      disabledColor: Colors.grey[400],
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: Colors.white,
        background: Color(0xFFF5F5F5),
        error: Colors.redAccent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: TextStyle(color: Colors.black87),
        bodySmall: TextStyle(color: Colors.black54),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      dividerColor: Colors.white24,
      disabledColor: Colors.grey[700],
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.grey),
      ),
      useMaterial3: true,
    );
  }
}
