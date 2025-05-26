import 'package:flutter/material.dart';

class AppTheme {
  // Define your app colors
  static const Color primaryColor = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF8E53);
  static const Color secondaryColor = Color(0xFF6C5CE7);
  static const Color accentColor = Color(0xFF00B894);
  static const Color errorColor = Color(0xFFE17055);
  
  // Light Theme Colors
  static const Color lightBackground = Colors.white;
  static const Color lightSurface = Colors.white;
  static const Color lightCardColor = Colors.white;
  static const Color lightTextPrimary = Color(0xFF2D3436);
  static const Color lightTextSecondary = Color(0xFF636E72);
  static const Color lightDivider = Color(0xFFE0E0E0);
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCardColor = Color(0xFF2C2C2C);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkDivider = Color(0xFF404040);

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: MaterialColor(0xFFFF6B35, {
      50: Color(0xFFFFE8E0),
      100: Color(0xFFFFCBB3),
      200: Color(0xFFFFAA80),
      300: Color(0xFFFF894D),
      400: Color(0xFFFF7741),
      500: Color(0xFFFF6B35),
      600: Color(0xFFE6602F),
      700: Color(0xFFCC5429),
      800: Color(0xFFB34823),
      900: Color(0xFF993D1D),
    }),
    scaffoldBackgroundColor: lightBackground,
    cardColor: lightCardColor,
    dividerColor: lightDivider,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: lightSurface,
      background: lightBackground,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightTextPrimary,
      onBackground: lightTextPrimary,
      onError: Colors.white,
    ),
    textTheme: _buildTextTheme(lightTextPrimary, lightTextSecondary),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    fontFamily: 'Gilroy',
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: MaterialColor(0xFFFF6B35, {
      50: Color(0xFFFFE8E0),
      100: Color(0xFFFFCBB3),
      200: Color(0xFFFFAA80),
      300: Color(0xFFFF894D),
      400: Color(0xFFFF7741),
      500: Color(0xFFFF6B35),
      600: Color(0xFFE6602F),
      700: Color(0xFFCC5429),
      800: Color(0xFFB34823),
      900: Color(0xFF993D1D),
    }),
    scaffoldBackgroundColor: darkBackground,
    cardColor: darkCardColor,
    dividerColor: darkDivider,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: darkSurface,
      background: darkBackground,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkTextPrimary,
      onBackground: darkTextPrimary,
      onError: Colors.white,
    ),
    textTheme: _buildTextTheme(darkTextPrimary, darkTextSecondary),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    fontFamily: 'Gilroy',
  );

  // Build Text Theme with Gilroy font
  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Gilroy',
        color: primaryColor,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Gilroy',
        color: primaryColor,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Gilroy',
        color: primaryColor,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Gilroy',
        color: primaryColor,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Gilroy',
        color: primaryColor,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Gilroy',
        color: primaryColor,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Gilroy',
        color: primaryColor,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Gilroy',
        color: primaryColor,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Gilroy',
        color: secondaryColor,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Gilroy',
        color: primaryColor,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Gilroy',
        color: primaryColor,
        fontWeight: FontWeight.normal,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Gilroy',
        color: secondaryColor,
        fontWeight: FontWeight.normal,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Gilroy',
        color: primaryColor,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Gilroy',
        color: secondaryColor,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Gilroy',
        color: secondaryColor,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  // Helper method to get current theme colors
  static AppColors getColors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppColors(
      background: isDark ? darkBackground : lightBackground,
      surface: isDark ? darkSurface : lightSurface,
      cardColor: isDark ? darkCardColor : lightCardColor,
      textPrimary: isDark ? darkTextPrimary : lightTextPrimary,
      textSecondary: isDark ? darkTextSecondary : lightTextSecondary,
      divider: isDark ? darkDivider : lightDivider,
      primary: primaryColor,
      secondary: secondaryColor,
      accent: accentColor,
      error: errorColor,
    );
  }
}

// Color helper class
class AppColors {
  final Color background;
  final Color surface;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color error;

  AppColors({
    required this.background,
    required this.surface,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.error,
  });
}