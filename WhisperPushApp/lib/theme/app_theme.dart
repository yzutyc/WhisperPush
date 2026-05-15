import 'package:flutter/material.dart';

class AppTheme {
  static const Color spaceBlue = Color(0xFF0F172A);
  static const Color spaceIndigo = Color(0xFF1E293B);
  static const Color spaceSlate = Color(0xFF334155);
  static const Color spaceLight = Color(0xFF475569);
  static const Color techPurple = Color(0xFF8B5CF6);
  static const Color techPurpleLight = Color(0xFFA78BFA);
  static const Color neonBlue = Color(0xFF06B6D4);
  static const Color neonBlueLight = Color(0xFF22D3EE);
  static const Color pulseGreen = Color(0xFF10B981);
  static const Color pulseGreenLight = Color(0xFF34D399);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFE2E8F0);
  static const Color textTertiary = Color(0xFFCBD5E1);
  static const Color textDisabled = Color(0xFF94A3B8);
  static const Color borderColor = Color(0xFF4B5563);
  static const Color borderLight = Color(0xFF6B7280);

  static const BorderRadius borderRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius borderRadiusSmall = BorderRadius.all(Radius.circular(8));
  static const BorderRadius borderRadiusLarge = BorderRadius.all(Radius.circular(24));

  static ThemeData dark() {
    return ThemeData(
      primaryColor: techPurple,
      colorScheme: ColorScheme.dark(
        primary: techPurple,
        secondary: neonBlue,
        surface: spaceIndigo,
        error: dangerRed,
      ),
      scaffoldBackgroundColor: spaceBlue,
      cardColor: spaceIndigo,
      appBarTheme: const AppBarTheme(
        backgroundColor: spaceBlue,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: borderRadius),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          backgroundColor: techPurple,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: techPurple, width: 2),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: borderColor),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: dangerRed, width: 2),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: dangerRed, width: 2),
        ),
        filled: true,
        fillColor: spaceIndigo,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: textTertiary),
        prefixIconColor: textTertiary,
        hintStyle: const TextStyle(color: textDisabled),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: textPrimary),
        headlineMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: textPrimary),
        titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: textPrimary),
        titleMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: textSecondary),
        bodyMedium: TextStyle(fontSize: 14, color: textTertiary),
        bodySmall: TextStyle(fontSize: 12, color: textDisabled),
      ),
      iconTheme: const IconThemeData(color: textSecondary),
      chipTheme: const ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: borderRadiusSmall),
        backgroundColor: spaceSlate,
        labelStyle: TextStyle(fontSize: 12, color: textSecondary),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        side: BorderSide(color: borderColor),
      ),
      cardTheme: const CardTheme(
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        elevation: 0,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: spaceIndigo,
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 0.5,
        space: 8,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.all(techPurple),
        trackColor: MaterialStateProperty.all(spaceSlate),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.all(techPurple),
        checkColor: MaterialStateProperty.all(textPrimary),
      ),
    );
  }

  static BoxDecoration glassDecoration = BoxDecoration(
    color: const Color.fromARGB(180, 30, 41, 59),
    borderRadius: borderRadius,
    border: Border.all(color: const Color.fromARGB(80, 139, 92, 246)),
    boxShadow: [
      BoxShadow(
        color: const Color.fromARGB(60, 139, 92, 246),
        blurRadius: 25,
        spreadRadius: 2,
      ),
      BoxShadow(
        color: const Color.fromARGB(30, 6, 182, 212),
        blurRadius: 15,
        spreadRadius: 1,
      ),
    ],
  );

  static BoxDecoration glassCardDecoration = BoxDecoration(
    color: const Color.fromARGB(200, 30, 41, 59),
    borderRadius: borderRadius,
    border: Border.all(color: const Color.fromARGB(100, 139, 92, 246)),
    boxShadow: [
      BoxShadow(
        color: const Color.fromARGB(40, 0, 0, 0),
        blurRadius: 20,
        spreadRadius: 5,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: const Color.fromARGB(30, 139, 92, 246),
        blurRadius: 15,
        spreadRadius: 2,
      ),
    ],
  );

  static BoxDecoration glassCardHoverDecoration = BoxDecoration(
    color: const Color.fromARGB(220, 30, 41, 59),
    borderRadius: borderRadius,
    border: Border.all(color: const Color.fromARGB(150, 139, 92, 246)),
    boxShadow: [
      BoxShadow(
        color: const Color.fromARGB(80, 139, 92, 246),
        blurRadius: 30,
        spreadRadius: 8,
      ),
      BoxShadow(
        color: const Color.fromARGB(40, 6, 182, 212),
        blurRadius: 20,
        spreadRadius: 4,
      ),
    ],
  );

  static BoxDecoration glassLightDecoration = BoxDecoration(
    color: const Color.fromARGB(240, 51, 65, 85),
    borderRadius: borderRadiusSmall,
    border: Border.all(color: const Color.fromARGB(60, 139, 92, 246)),
    boxShadow: [
      BoxShadow(
        color: const Color.fromARGB(30, 139, 92, 246),
        blurRadius: 10,
        spreadRadius: 2,
      ),
    ],
  );

  static BoxDecoration neonGlow = BoxDecoration(
    borderRadius: borderRadius,
    gradient: const LinearGradient(
      colors: [techPurple, neonBlue],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    boxShadow: [
      BoxShadow(
        color: const Color.fromARGB(150, 139, 92, 246),
        blurRadius: 20,
        spreadRadius: 5,
      ),
      BoxShadow(
        color: const Color.fromARGB(100, 6, 182, 212),
        blurRadius: 15,
        spreadRadius: 3,
      ),
    ],
  );

  static const BoxDecoration gradientBackground = BoxDecoration(
    gradient: LinearGradient(
      colors: [spaceBlue, Color(0xFF1E1B4B), Color(0xFF0F172A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static BoxDecoration cardGradientBorder = BoxDecoration(
    color: spaceIndigo,
    borderRadius: borderRadius,
    border: Border.all(
      color: const Color.fromARGB(120, 139, 92, 246),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: const Color.fromARGB(40, 139, 92, 246),
        blurRadius: 15,
        spreadRadius: 3,
      ),
    ],
  );

  static BoxDecoration neonButtonShadow = BoxDecoration(
    borderRadius: borderRadius,
    gradient: const LinearGradient(
      colors: [techPurple, Color(0xFF7C3AED)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    boxShadow: [
      BoxShadow(
        color: const Color.fromARGB(100, 139, 92, 246),
        blurRadius: 15,
        spreadRadius: 3,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration neonButtonHoverShadow = BoxDecoration(
    borderRadius: borderRadius,
    gradient: const LinearGradient(
      colors: [techPurpleLight, neonBlueLight],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    boxShadow: [
      BoxShadow(
        color: const Color.fromARGB(150, 139, 92, 246),
        blurRadius: 25,
        spreadRadius: 8,
      ),
      BoxShadow(
        color: const Color.fromARGB(100, 6, 182, 212),
        blurRadius: 15,
        spreadRadius: 4,
      ),
    ],
  );

  static BoxDecoration searchInputDecoration = BoxDecoration(
    color: const Color.fromARGB(200, 30, 41, 59),
    borderRadius: borderRadius,
    border: Border.all(color: const Color.fromARGB(60, 139, 92, 246)),
    boxShadow: [
      BoxShadow(
        color: const Color.fromARGB(20, 139, 92, 246),
        blurRadius: 10,
        spreadRadius: 1,
      ),
    ],
  );

  static BoxDecoration searchInputFocusedDecoration = BoxDecoration(
    color: const Color.fromARGB(220, 30, 41, 59),
    borderRadius: borderRadius,
    border: Border.all(color: const Color.fromARGB(150, 139, 92, 246), width: 2),
    boxShadow: [
      BoxShadow(
        color: const Color.fromARGB(60, 139, 92, 246),
        blurRadius: 20,
        spreadRadius: 5,
      ),
      BoxShadow(
        color: const Color.fromARGB(30, 6, 182, 212),
        blurRadius: 15,
        spreadRadius: 3,
      ),
    ],
  );
}